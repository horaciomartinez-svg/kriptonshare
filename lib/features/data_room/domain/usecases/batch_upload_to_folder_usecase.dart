import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/file_entity.dart';
import '../repositories/i_data_room_repository.dart';

/// Item de un lote de archivos a subir al Data Room.
class BatchUploadItem {
  final String filename;
  final Uint8List bytes;
  final String mimeType;
  final double progress;
  final String? error;

  const BatchUploadItem({
    required this.filename,
    required this.bytes,
    required this.mimeType,
    this.progress = 0.0,
    this.error,
  });

  bool get exceedsLimit => bytes.length > 100 * 1024 * 1024; // 100 MB
}

class BatchUploadToFolderUseCase {
  final IDataRoomRepository _repository;

  BatchUploadToFolderUseCase(this._repository);

  Future<Either<Failure, FileEntity>> execute({
    required String ownerId,
    required String folderId,
    required BatchUploadItem item,
    required String userPassword,
    required void Function(double) onProgress,
  }) async {
    // Simulamos progreso 0..50 durante cifrado y 50..100 durante subida.
    onProgress(0.1);
    final result = await _repository.encryptAndUploadFile(
      ownerId: ownerId,
      folderId: folderId,
      filename: item.filename,
      fileBytes: item.bytes,
      mimeType: item.mimeType,
      userPassword: userPassword,
    );
    onProgress(1.0);
    return result;
  }
}
