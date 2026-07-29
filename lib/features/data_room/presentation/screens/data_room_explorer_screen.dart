import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';
import '../../../../app/config/theme/app_theme.dart';
import '../../../../app/constants/storage_constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../data_room_providers.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/entities/folder_entity.dart';
import '../../domain/entities/share_link_entity.dart';
import '../../domain/usecases/batch_upload_to_folder_usecase.dart';
import '../notifiers/data_room_explorer_notifier.dart';
import '../notifiers/upload_batch_notifier.dart';
import '../widgets/organisms/drive_explorer_view.dart';
import '../widgets/templates/data_room_layout.dart';

class DataRoomExplorerScreen extends ConsumerStatefulWidget {
  const DataRoomExplorerScreen({super.key});

  @override
  ConsumerState<DataRoomExplorerScreen> createState() => _DataRoomExplorerScreenState();
}

class _DataRoomExplorerScreenState extends ConsumerState<DataRoomExplorerScreen> {
  ExplorerViewMode _viewMode = ExplorerViewMode.list;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await ref.read(dataRoomExplorerProvider.notifier).loadContents(user.id);
    }
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.ink,
        title: const Text('Nueva carpeta virtual', style: TextStyle(color: AppTheme.platinum)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.platinum),
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final result = await ref.read(createFolderUseCaseProvider).call(
      ownerId: user.id,
      name: name,
    );
    result.fold(
      (failure) => _showError(failure.message),
      (_) => _load(),
    );
  }

  Future<void> _uploadFile({String? folderId, bool multiple = false}) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    String? targetFolderId = folderId;

    // Si es carga múltiple sin carpeta destino, pedimos que elija una.
    if (multiple && targetFolderId == null) {
      final explorer = ref.read(dataRoomExplorerProvider);
      if (explorer.folders.isEmpty) {
        _showError('Crea una carpeta primero para la subida múltiple');
        return;
      }
      targetFolderId = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.ink,
          title: const Text('Subir a carpeta', style: TextStyle(color: AppTheme.platinum)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: explorer.folders.length,
              itemBuilder: (context, index) {
                final folder = explorer.folders[index];
                return ListTile(
                  title: Text(folder.name, style: const TextStyle(color: AppTheme.platinum)),
                  subtitle: Text('${folder.files.length} archivos',
                      style: const TextStyle(color: AppTheme.silver)),
                  onTap: () => Navigator.pop(context, folder.id),
                );
              },
            ),
          ),
        ),
      );
      if (targetFolderId == null) return;
    }

    final XFile? single = multiple ? null : await openFile();
    final List<XFile> files = multiple ? await openFiles() : [];
    final selected = single != null ? [single] : files;
    if (selected.isEmpty) return;

    setState(() => _isUploading = true);

    final password = _generatePassword();
    final items = <BatchUploadItem>[];
    for (final xfile in selected) {
      final bytes = await xfile.readAsBytes();
      final mime = lookupMimeType(xfile.name) ?? 'application/octet-stream';
      if (bytes.length > StorageConstants.premiumMaxFileBytes) {
        _showError('${xfile.name} excede 100 MB');
        continue;
      }
      items.add(BatchUploadItem(filename: xfile.name, bytes: bytes, mimeType: mime));
    }

    if (targetFolderId != null) {
      await ref.read(uploadBatchProvider.notifier).enqueueAndProcess(
            ownerId: user.id,
            folderId: targetFolderId,
            items: items,
            userPassword: password,
          );
    } else {
      for (final item in items) {
        await ref.read(encryptAndUploadFileUseCaseProvider).call(
              ownerId: user.id,
              folderId: null,
              filename: item.filename,
              fileBytes: item.bytes,
              mimeType: item.mimeType,
              userPassword: password,
            );
      }
    }

    setState(() => _isUploading = false);
    await _load();
  }

  Future<void> _shareFolder(FolderEntity folder) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final result = await ref.read(createShareLinkUseCaseProvider).call(
          createdBy: user.id,
          folderId: folder.id,
          linkType: ShareLinkType.fullFolder,
          requireRecipientEmail: true,
          enableWatermark: true,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );
    result.fold(
      (failure) => _showError(failure.message),
      (link) => _showMessage('Enlace: ${link.publicUrl(_generatePassword())}'),
    );
  }

  Future<void> _shareFile(FileEntity file) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final result = await ref.read(createShareLinkUseCaseProvider).call(
          createdBy: user.id,
          fileId: file.id,
          linkType: ShareLinkType.singleFile,
          requireRecipientEmail: true,
          enableWatermark: true,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );
    result.fold(
      (failure) => _showError(failure.message),
      (link) => _showMessage('Enlace: ${link.publicUrl(_generatePassword())}'),
    );
  }

  String _generatePassword() {
    // En producción se deriva de input del usuario o se genera segura.
    return 'kriptonshare-secure';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.crimsonRed),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final explorer = ref.watch(dataRoomExplorerProvider);

    return DataRoomLayout(
      title: 'Mi Bóveda Data Room',
      usedBytes: user?.totalStorageUsedBytes ?? 0,
      maxBytes: user?.maxStorageBytes ?? StorageConstants.premiumBaseStorageBytes,
      onUpgradeStorage: () => context.go('/storage-management'),
      actions: [
        IconButton(
          icon: Icon(_viewMode == ExplorerViewMode.list ? Icons.grid_view : Icons.view_list,
              color: AppTheme.platinum),
          onPressed: () => setState(() {
            _viewMode = _viewMode == ExplorerViewMode.list
                ? ExplorerViewMode.grid
                : ExplorerViewMode.list;
          }),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : () => _uploadFile(),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Subir archivo'),
                ),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : () => _uploadFile(multiple: true),
                  icon: const Icon(Icons.drive_folder_upload),
                  label: const Text('Subida múltiple'),
                ),
                OutlinedButton.icon(
                  onPressed: _createFolder,
                  icon: const Icon(Icons.create_new_folder, color: AppTheme.platinum),
                  label: const Text('Nueva carpeta', style: TextStyle(color: AppTheme.platinum)),
                ),
              ],
            ),
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          Expanded(
            child: explorer.isLoading && explorer.folders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : DriveExplorerView(
                    folders: explorer.folders,
                    unfiledDocuments: explorer.unfiledDocuments,
                    viewMode: _viewMode,
                    onFolderShare: _shareFolder,
                    onFileShare: _shareFile,
                  ),
          ),
        ],
      ),
    );
  }
}
