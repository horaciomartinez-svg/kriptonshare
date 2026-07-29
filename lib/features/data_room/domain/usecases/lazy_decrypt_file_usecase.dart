import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/file_entity.dart';
import '../repositories/i_data_room_repository.dart';

class LazyDecryptFileUseCase {
  final IDataRoomRepository _repository;

  LazyDecryptFileUseCase(this._repository);

  Future<Either<Failure, Uint8List>> execute({
    required FileEntity file,
    required String userPassword,
  }) async {
    return _repository.downloadAndDecryptFile(
      file: file,
      userPassword: userPassword,
    );
  }
}
