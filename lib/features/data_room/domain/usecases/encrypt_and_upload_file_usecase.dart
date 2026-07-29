import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/file_entity.dart';
import '../repositories/i_data_room_repository.dart';

class EncryptAndUploadFileUseCase {
  final IDataRoomRepository _repository;

  EncryptAndUploadFileUseCase(this._repository);

  Future<Either<Failure, FileEntity>> call({
    required String ownerId,
    required String? folderId,
    required String filename,
    required Uint8List fileBytes,
    required String mimeType,
    required String userPassword,
  }) async {
    return _repository.encryptAndUploadFile(
      ownerId: ownerId,
      folderId: folderId,
      filename: filename,
      fileBytes: fileBytes,
      mimeType: mimeType,
      userPassword: userPassword,
    );
  }
}
