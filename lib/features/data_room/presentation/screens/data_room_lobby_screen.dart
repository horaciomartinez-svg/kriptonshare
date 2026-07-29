import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/theme/app_theme.dart';
import '../../../../services/screenshot_service.dart';
import '../../../../utils/constants.dart';
import '../../../../widgets/video_player_screen.dart';
import '../../data_room_providers.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/entities/folder_entity.dart';
import '../notifiers/folder_notifier.dart';
import '../notifiers/lazy_decryption_notifier.dart';
import '../widgets/atoms/dynamic_watermark_text.dart';
import '../widgets/organisms/recipient_email_modal.dart';
import '../widgets/templates/viewer_secure_layout.dart';

final folderNotifierProvider = StateNotifierProvider<FolderNotifier, FolderScreenState>((ref) {
  return FolderNotifier(folderRepository: ref.watch(folderRepositoryProvider));
});

class DataRoomLobbyScreen extends ConsumerStatefulWidget {
  final String folderLinkId;

  const DataRoomLobbyScreen({super.key, required this.folderLinkId});

  @override
  ConsumerState<DataRoomLobbyScreen> createState() => _DataRoomLobbyScreenState();
}

class _DataRoomLobbyScreenState extends ConsumerState<DataRoomLobbyScreen> {
  final _passwordController = TextEditingController();
  final _pdfController = PdfViewerController();
  final _pageStopwatch = Stopwatch();
  String? _recipientEmail;
  bool _emailRequired = true;
  bool _watermarkEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeSecureView();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(folderNotifierProvider.notifier).loadFolderByShareLink(widget.folderLinkId);
      _maybeLogLobbyEnter();
    });
  }

  Future<void> _initializeSecureView() async {
    await ScreenshotService.enableSecureView();
  }

  Future<void> _maybeLogLobbyEnter() async {
    final link = await _getShareLinkMeta();
    if (link == null) return;
    _emailRequired = link['require_recipient_email'] as bool? ?? true;
    _watermarkEnabled = link['enable_watermark'] as bool? ?? true;
    setState(() {});

    if (_recipientEmail != null || !_emailRequired) {
      _logJourneyEvent('lobby_enter');
    }
  }

  Future<Map<String, dynamic>?> _getShareLinkMeta() async {
    try {
      final response = await Supabase.instance.client
          .from('share_links')
          .select('require_recipient_email, enable_watermark')
          .eq('id', widget.folderLinkId)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  Future<void> _logJourneyEvent(String eventType, {String? fileId, int? pageNumber, int durationMs = 0}) async {
    final email = _recipientEmail ?? 'anon@kriptonshare.com';
    await ref.read(folderNotifierProvider.notifier).logJourneyEvent(
          shareLinkId: widget.folderLinkId,
          eventType: eventType,
          fileId: fileId,
          pageNumber: pageNumber,
          durationMs: durationMs,
        );
    // También al repositorio VDR para redundancia
    try {
      await ref.read(dataRoomRepositoryProvider).recordJourneyEvent(
            shareLinkId: widget.folderLinkId,
            fileId: fileId,
            recipientEmail: email,
            eventType: eventType,
            pageNumber: pageNumber,
            durationMs: durationMs,
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _pageStopwatch.stop();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  IconData _iconForMime(String mime) {
    if (mime.startsWith('image/')) return Icons.image;
    if (mime.startsWith('video/')) return Icons.videocam;
    if (mime == 'application/pdf') return Icons.picture_as_pdf;
    if (mime.contains('spreadsheet') || mime.contains('excel')) return Icons.table_chart;
    if (mime.contains('presentation') || mime.contains('powerpoint')) return Icons.slideshow;
    if (mime.contains('word') || mime.contains('document')) return Icons.description;
    return Icons.insert_drive_file;
  }

  Future<void> _openFileInLobby(FileEntity file) async {
    if (_passwordController.text.isEmpty) {
      _showError('Ingresa la contraseña del Data Room');
      return;
    }

    _pageStopwatch.reset();
    _pageStopwatch.start();

    await ref.read(lazyDecryptionProvider.notifier).decryptSingleFile(
          file: file,
          password: _passwordController.text,
        );

    ref.read(folderNotifierProvider.notifier).selectFile(file);
    await _logJourneyEvent('file_open', fileId: file.id);
  }

  void _closeFile() {
    final selectedFile = ref.read(folderNotifierProvider).selectedFile;
    if (selectedFile != null) {
      _logJourneyEvent('lobby_exit', fileId: selectedFile.id, durationMs: _pageStopwatch.elapsedMilliseconds);
    }
    _pageStopwatch.stop();
    ref.read(lazyDecryptionProvider.notifier).purgeRAM();
    ref.read(folderNotifierProvider.notifier).clearSelectedFile();
  }

  void _onPdfPageChanged(int page) {
    final selectedFile = ref.read(folderNotifierProvider).selectedFile;
    if (selectedFile != null) {
      _logJourneyEvent(
        'page_view',
        fileId: selectedFile.id,
        pageNumber: page,
        durationMs: _pageStopwatch.elapsedMilliseconds,
      );
      _pageStopwatch.reset();
      _pageStopwatch.start();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.crimsonRed),
    );
  }

  void _onEmailSubmitted(String email) {
    setState(() => _recipientEmail = email);
    _logJourneyEvent('lobby_enter');
  }

  @override
  Widget build(BuildContext context) {
    final folderState = ref.watch(folderNotifierProvider);
    final decryptedState = ref.watch(lazyDecryptionProvider);
    final folder = folderState.folder;
    final selectedFile = folderState.selectedFile;

    if (folder == null && folderState.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.charcoalDeep,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (folder == null) {
      return Scaffold(
        backgroundColor: AppTheme.charcoalDeep,
        appBar: AppBar(title: const Text('Data Room')),
        body: Center(
          child: Text(
            folderState.error ?? 'No se encontró el Data Room',
            style: const TextStyle(color: AppTheme.silver),
          ),
        ),
      );
    }

    if (_emailRequired && _recipientEmail == null) {
      return Scaffold(
        backgroundColor: AppTheme.charcoalDeep,
        appBar: AppBar(title: Text(folder.name)),
        body: SafeArea(
          child: RecipientEmailModal(onSubmit: _onEmailSubmitted),
        ),
      );
    }

    if (selectedFile != null) {
      return decryptedState.when(
        data: (bytes) {
          if (bytes == null) {
            return _buildLobby(folder);
          }
          return ViewerSecureLayout(
            title: selectedFile.originalFilename,
            onClose: _closeFile,
            content: _buildFileViewer(selectedFile, bytes),
            overlays: _watermarkEnabled
                ? [
                    Positioned.fill(
                      child: DynamicWatermarkText(
                        recipientEmail: _recipientEmail ?? 'anon@kriptonshare.com',
                        recipientIp: '0.0.0.0',
                      ),
                    ),
                  ]
                : null,
          );
        },
        loading: () => Scaffold(
          backgroundColor: AppTheme.charcoalDeep,
          appBar: AppBar(title: Text(selectedFile.originalFilename)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          backgroundColor: AppTheme.charcoalDeep,
          appBar: AppBar(title: Text(selectedFile.originalFilename)),
          body: Center(
            child: Text('Error: $err', style: const TextStyle(color: AppTheme.silver)),
          ),
        ),
      );
    }

    return _buildLobby(folder);
  }

  Widget _buildLobby(FolderEntity folder) {
    return ViewerSecureLayout(
      title: folder.name,
      onClose: () => context.go('/dashboard'),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              folder.name,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.platinum),
            ),
            const SizedBox(height: 4),
            Text(
              '${folder.files.length} Archivos Cifrados · ${_formatBytes(folder.totalSizeBytes)}',
              style: const TextStyle(color: AppTheme.silver),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: AppTheme.platinum),
              decoration: const InputDecoration(
                labelText: 'Contraseña del Data Room',
                prefixIcon: Icon(Icons.vpn_key, color: AppTheme.silver),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona un archivo para descifrarlo en memoria RAM',
              style: TextStyle(color: AppTheme.silver),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: folder.files.length,
                itemBuilder: (context, index) {
                  final file = folder.files[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        _iconForMime(file.mimeType),
                        color: AppTheme.electricLime,
                      ),
                      title: Text(
                        file.originalFilename,
                        style: const TextStyle(color: AppTheme.platinum),
                      ),
                      subtitle: Text(
                        '${_formatBytes(file.fileSizeBytes)} · Cifrado AES-256',
                        style: const TextStyle(color: AppTheme.silver),
                      ),
                      trailing: const Icon(
                        Icons.lock_open,
                        color: AppTheme.mutedGreen,
                      ),
                      onTap: () => _openFileInLobby(file),
                    ),
                  );
                },
              ),
            ),
            const Text(
              'Los documentos se descifran exclusivamente en RAM volátil y cuentan con auditoría de lectura activa.',
              style: TextStyle(color: AppTheme.silver, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      overlays: _watermarkEnabled && _recipientEmail != null
          ? [
              Positioned.fill(
                child: DynamicWatermarkText(
                  recipientEmail: _recipientEmail!,
                  recipientIp: '0.0.0.0',
                ),
              ),
            ]
          : null,
    );
  }

  Widget _buildFileViewer(FileEntity file, Uint8List bytes) {
    final mime = file.mimeType;

    if (mime.startsWith('image/')) {
      return InteractiveViewer(
        child: GestureDetector(
          onLongPressStart: (_) {},
          behavior: HitTestBehavior.opaque,
          child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
        ),
      );
    }

    if (mime.startsWith('text/')) {
      final text = utf8.decode(bytes);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.platinum,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      );
    }

    if (mime.startsWith('video/')) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam, size: 64, color: AppTheme.electricLime),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SecureVideoPlayerScreen(
                        videoBytes: bytes,
                        fileName: file.originalFilename,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Reproducir video'),
              ),
            ],
          ),
        ),
      );
    }

    if (mime == 'application/pdf') {
      return PdfViewer.data(
        bytes,
        sourceName: file.originalFilename,
        controller: _pdfController,
        params: PdfViewerParams(
          backgroundColor: AppTheme.charcoalDeep,
          onPageChanged: _onPdfPageChanged,
          errorBannerBuilder: (context, error, stackTrace, documentRef) => Center(
            child: Text(
              'Error al abrir PDF:\n$error',
              style: const TextStyle(color: AppTheme.silver),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: AppTheme.electricLime),
          const SizedBox(height: 16),
          Text(
            'Formato protegido',
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
