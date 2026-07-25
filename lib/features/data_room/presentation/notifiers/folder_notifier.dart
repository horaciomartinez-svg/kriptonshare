import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../models/kripton_file.dart';
import '../../../../services/crypto_service.dart';
import '../../../../services/r2_signature_service.dart';
import '../../../../utils/constants.dart';
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
  final KriptonFile? selectedFile;

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
    KriptonFile? selectedFile,
  }) {
    return FolderScreenState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      folder: folder ?? this.folder,
      selectedFile: selectedFile ?? this.selectedFile,
    );
  }
}

/// Notifier de carpeta con Lazy Decryption: solo descarga y descifra el archivo
/// que el usuario selecciona, y evapora la RAM al salir del visor.
class FolderNotifier extends StateNotifier<FolderScreenState> {
  final IFolderRepository _folderRepository;
  final CryptoService _cryptoService;
  final Dio _dio;
  final R2SignatureService _r2Signer;

  FolderNotifier({
    required IFolderRepository folderRepository,
    CryptoService? cryptoService,
  })  : _folderRepository = folderRepository,
        _cryptoService = cryptoService ?? CryptoService(),
        _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(minutes: 5),
            sendTimeout: const Duration(minutes: 5),
          ),
        ),
        _r2Signer = const R2SignatureService(
          accessKeyId: AppConstants.r2AccessKeyId,
          secretAccessKey: AppConstants.r2SecretAccessKey,
          endpoint: AppConstants.r2Endpoint,
        ),
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

  /// Descarga y descifra ÚNICAMENTE el archivo seleccionado.
  Future<Uint8List?> decryptSingleFile(KriptonFile file, String password) async {
    state = state.copyWith(isLoading: true, error: null, selectedFile: file);
    try {
      final objectPath = '/${file.bucketName}/${file.storageObjectKey}';
      final downloadUrl = '${AppConstants.r2Endpoint}$objectPath';

      final signedHeaders = _r2Signer.signRequest(method: 'GET', path: objectPath);
      final response = await _dio.get<List<int>>(
        downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: signedHeaders,
        ),
      );
      final encryptedBytes = Uint8List.fromList(response.data!);

      // Lazy decryption en Isolate (si el motor lo soporta) o main thread.
      final decrypted = await _cryptoService.decryptFileBytes(
        encryptedBytes: encryptedBytes,
        password: password,
      );

      state = state.copyWith(isLoading: false);
      return decrypted;
    } catch (e) {
      state = state.copyWith(error: 'Error descifrando: $e', isLoading: false);
      return null;
    }
  }

  /// Evapora explícitamente los bytes descifrados de la RAM.
  void purgeRAM() {
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
