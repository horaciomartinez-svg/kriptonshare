import 'package:dartz/dartz.dart';
import 'dart:typed_data';
import '../../../../core/error/failures.dart';
import '../entities/upload_result_entity.dart';
import '../repositories/i_upload_repository.dart';

/// Caso de uso para subir un archivo cifrado y generar link temporal.
class UploadFileUseCase {
  final IUploadRepository _repository;

  UploadFileUseCase(this._repository);

  Future<Either<Failure, UploadResultEntity>> call({
    required String ownerId,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    required String password,
    int? maxDownloads,
    String? recipientEmail,
  }) async {
    return await _repository.uploadFile(
      ownerId: ownerId,
      fileBytes: fileBytes,
      fileName: fileName,
      mimeType: mimeType,
      password: password,
      maxDownloads: maxDownloads,
      recipientEmail: recipientEmail,
    );
  }
}
