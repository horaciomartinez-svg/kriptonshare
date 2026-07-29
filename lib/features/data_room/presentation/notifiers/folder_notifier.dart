import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/entities/folder_entity.dart';
import '../../domain/entities/journey_telemetry_entity.dart';
import '../../domain/repositories/i_folder_repository.dart';

/// Bytes descifrados actualmente en memoria RAM (estado volátil).
final activeDecryptedFileBytesProvider =
    StateProvider.autoDispose<Uint8List?>((ref) => null);

/// Estado del Lobby y visor de carpeta.
class FolderScreenState {
  final bool isLoading;
  final String? error;
  final FolderEntity? folder;
  final FileEntity? selectedFile;

  const FolderScreenState({
    this.isLoading = false,
    this.error,
    this.folder,
    this.selectedFile,
  });

  FolderScreenState copyWith({
    bool? isLoading,
    String? error,
    FolderEntity? folder,
    FileEntity? selectedFile,
  }) {
    return FolderScreenState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      folder: folder ?? this.folder,
      selectedFile: selectedFile ?? this.selectedFile,
    );
  }
}

/// Notifier de carpeta: carga metadatos, selecciona archivo y registra telemetría.
/// El descifrado perezoso vive en LazyDecryptionNotifier.
class FolderNotifier extends StateNotifier<FolderScreenState> {
  final IFolderRepository _folderRepository;

  FolderNotifier({
    required IFolderRepository folderRepository,
  })  : _folderRepository = folderRepository,
        super(const FolderScreenState());

  Future<void> loadFolderByShareLink(String shareLinkId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _folderRepository.getFolderByShareLinkId(shareLinkId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message, isLoading: false),
      (folder) => state = state.copyWith(folder: folder, isLoading: false),
    );
  }

  Future<void> loadFolderById(String folderId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _folderRepository.getFolderById(folderId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message, isLoading: false),
      (folder) => state = state.copyWith(folder: folder, isLoading: false),
    );
  }

  void selectFile(FileEntity file) {
    state = state.copyWith(selectedFile: file);
  }

  void clearSelectedFile() {
    state = state.copyWith(selectedFile: null);
  }

  /// Registra un evento de Journey Telemetry.
  Future<void> logJourneyEvent({
    required String shareLinkId,
    required String eventType,
    String? fileId,
    int? pageNumber,
    int durationMs = 0,
  }) async {
    final event = JourneyTelemetryEntity(
      shareLinkId: shareLinkId,
      fileId: fileId,
      eventType: eventType,
      pageNumber: pageNumber,
      durationMs: durationMs,
      createdAt: DateTime.now(),
    );
    await _folderRepository.logJourneyEvent(event);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
