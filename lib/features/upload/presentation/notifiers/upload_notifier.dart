import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/upload_result_entity.dart';
import '../../domain/usecases/upload_file.dart';

/// Estados del proceso de subida.
enum UploadStep { idle, encrypting, uploading, success, error }

/// Estado de subida para la capa de presentación.
class UploadState {
  final UploadStep step;
  final double progress;
  final UploadResultEntity? result;
  final String? errorMessage;

  const UploadState({
    this.step = UploadStep.idle,
    this.progress = 0.0,
    this.result,
    this.errorMessage,
  });

  UploadState copyWith({
    UploadStep? step,
    double? progress,
    UploadResultEntity? result,
    String? errorMessage,
  }) {
    return UploadState(
      step: step ?? this.step,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading =>
      step == UploadStep.encrypting || step == UploadStep.uploading;
  bool get isSuccess => step == UploadStep.success;
  bool get isError => step == UploadStep.error;
}

/// Notifier de subida de archivos cifrados.
class UploadNotifier extends StateNotifier<UploadState> {
  final UploadFileUseCase _uploadFile;

  UploadNotifier(this._uploadFile) : super(const UploadState());

  /// Reinicia el estado a idle.
  void reset() {
    state = const UploadState();
  }

  /// Registra un error desde la UI.
  void setError(String message) {
    state = state.copyWith(
      step: UploadStep.error,
      errorMessage: message,
      progress: 0.0,
    );
  }

  /// Sube un archivo cifrado y genera el link compartible.
  Future<void> uploadFile({
    required String ownerId,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    required String password,
    int? maxDownloads,
    String? recipientEmail,
  }) async {
    state = state.copyWith(
      step: UploadStep.encrypting,
      progress: 0.2,
      errorMessage: null,
      result: null,
    );

    // Pequeña pausa UX para que el usuario perciba el cifrado
    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(
      step: UploadStep.uploading,
      progress: 0.6,
    );

    final result = await _uploadFile(
      ownerId: ownerId,
      fileBytes: fileBytes,
      fileName: fileName,
      mimeType: mimeType,
      password: password,
      maxDownloads: maxDownloads,
      recipientEmail: recipientEmail,
    );

    result.fold(
      (failure) => state = state.copyWith(
        step: UploadStep.error,
        progress: 0.0,
        errorMessage: failure.message,
      ),
      (uploadResult) => state = state.copyWith(
        step: UploadStep.success,
        progress: 1.0,
        result: uploadResult,
      ),
    );
  }
}
