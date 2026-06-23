import 'package:dartz/dartz.dart';
import 'dart:typed_data';
import '../../../../core/error/failures.dart';
import '../entities/upload_result_entity.dart';

/// Contrato de repositorio para subida segura de archivos.
abstract class IUploadRepository {
  /// Cifra y sube un archivo a Supabase Storage, registrando metadata
  /// y generando un link temporal compartible.
  Future<Either<Failure, UploadResultEntity>> uploadFile({
    required String ownerId,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    required String password,
    int? maxDownloads,
    String? recipientEmail,
  });
}
