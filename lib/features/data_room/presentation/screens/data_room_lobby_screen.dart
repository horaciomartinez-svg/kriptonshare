import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../../models/kripton_file.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/screenshot_service.dart';
import '../../../../utils/theme.dart';
import '../../../../widgets/video_player_screen.dart';
import '../../domain/repositories/i_folder_repository.dart';
import '../../folder_providers.dart';
import '../notifiers/folder_notifier.dart';

final folderNotifierProvider = StateNotifierProvider.family<FolderNotifier,
    FolderScreenState, IFolderRepository>((ref, repository) {
  return FolderNotifier(folderRepository: repository);
});

class DataRoomLobbyScreen extends ConsumerStatefulWidget {
  final String folderLinkId;

  const DataRoomLobbyScreen({super.key, required this.folderLinkId});

  @override
  ConsumerState<DataRoomLobbyScreen> createState() =>
      _DataRoomLobbyScreenState();
}

class _DataRoomLobbyScreenState extends ConsumerState<DataRoomLobbyScreen> {
  final _passwordController = TextEditingController();
  final _pdfController = PdfViewerController();
  Uint8List? _decryptedBytes;
  KriptonFile? _openFile;

  @override
  void initState() {
    super.initState();
    _initializeSecureView();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(folderRepositoryProvider);
      ref.read(folderNotifierProvider(repo).notifier)
        ..loadFolderByShareLink(widget.folderLinkId)
        ..logJourneyEvent(
          shareLinkId: widget.folderLinkId,
          eventType: 'lobby_enter',
        );
    });
  }

  Future<void> _initializeSecureView() async {
    await ScreenshotService.enableSecureView();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    // No deshabilitamos FLAG_SECURE: ahora es global para toda la app.
    // PdfViewerController no requiere dispose() en esta versión de pdfrx.
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
    if (mime.contains('spreadsheet') || mime.contains('excel')) {
      return Icons.table_chart;
    }
    if (mime.contains('presentation') || mime.contains('powerpoint')) {
      return Icons.slideshow;
    }
    if (mime.contains('word') || mime.contains('document')) {
      return Icons.description;
    }
    return Icons.insert_drive_file;
  }

  Future<void> _openFileInLobby(KriptonFile file) async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la contraseña del Data Room')),
      );
      return;
    }

    final repo = ref.read(folderRepositoryProvider);
    final notifier = ref.read(folderNotifierProvider(repo).notifier);

    final decrypted = await notifier.decryptSingleFile(
      file,
      _passwordController.text,
    );

    if (decrypted == null) return;

    await notifier.logJourneyEvent(
      shareLinkId: widget.folderLinkId,
      eventType: 'file_open',
      fileId: file.id,
    );

    setState(() {
      _decryptedBytes = decrypted;
      _openFile = file;
    });
  }

  void _closeFile() {
    final repo = ref.read(folderRepositoryProvider);
    ref.read(folderNotifierProvider(repo).notifier)
      ..purgeRAM()
      ..logJourneyEvent(
        shareLinkId: widget.folderLinkId,
        eventType: 'lobby_exit',
      );
    setState(() {
      _decryptedBytes = null;
      _openFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(folderRepositoryProvider);
    final state = ref.watch(folderNotifierProvider(repo));
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: Text(_openFile == null ? 'Data Room' : _openFile!.originalFilename),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_openFile != null) {
              _closeFile();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBody(state, user),
            // Watermark global diagonal
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LobbyWatermarkPainter(
                    text: '${user?.email ?? "KRIPTONSHARE"} • CONFIDENCIAL',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FolderScreenState state, KriptonUser? user) {
    if (state.isLoading && state.folder == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
        ),
      );
    }

    if (state.error != null && state.folder == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.error!,
            style: const TextStyle(color: KriptonTheme.alertRed),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final folder = state.folder;
    if (folder == null) {
      return const Center(
        child: Text('No se encontró el Data Room'),
      );
    }

    if (_openFile != null && _decryptedBytes != null) {
      return _buildFileViewer(_openFile!, _decryptedBytes!);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            folder.name,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${folder.fileCount} Archivos Cifrados · ${_formatBytes(folder.totalSizeBytes)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: const InputDecoration(
              labelText: 'Contraseña del Data Room',
              prefixIcon: Icon(Icons.vpn_key, color: KriptonTheme.silver),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona un archivo para descifrarlo en memoria RAM',
            style: Theme.of(context).textTheme.bodySmall,
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
                      color: KriptonTheme.electricLime,
                    ),
                    title: Text(
                      file.originalFilename,
                      style: const TextStyle(color: KriptonTheme.platinum),
                    ),
                    subtitle: Text(
                      '${_formatBytes(file.fileSizeBytes)} · Cifrado AES-256',
                      style: const TextStyle(color: KriptonTheme.silver),
                    ),
                    trailing: const Icon(
                      Icons.lock_open,
                      color: KriptonTheme.kryptonGreen,
                    ),
                    onTap: () => _openFileInLobby(file),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileViewer(KriptonFile file, Uint8List bytes) {
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
            color: KriptonTheme.platinum,
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
              const Icon(
                Icons.videocam,
                size: 64,
                color: KriptonTheme.electricLime,
              ),
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
          backgroundColor: KriptonTheme.charcoalBlack,
          errorBannerBuilder: (context, error, stackTrace, documentRef) => Center(
            child: Text(
              'Error al abrir PDF:\n$error',
              style: const TextStyle(color: KriptonTheme.silver),
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
          const Icon(Icons.lock_outline,
              size: 64, color: KriptonTheme.electricLime),
          const SizedBox(height: 16),
          Text(
            'Formato protegido',
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Los documentos Office no se visualizan directamente por seguridad.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LobbyWatermarkPainter extends CustomPainter {
  final String text;

  _LobbyWatermarkPainter({required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.08),
      fontSize: 18,
      fontWeight: FontWeight.w500,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 4; j++) {
        canvas.save();
        canvas.translate(
          i * size.width / 6 + 30,
          j * size.height / 4 + 40,
        );
        canvas.rotate(-45 * 3.14159265359 / 180);
        textPainter.layout(maxWidth: 300);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
