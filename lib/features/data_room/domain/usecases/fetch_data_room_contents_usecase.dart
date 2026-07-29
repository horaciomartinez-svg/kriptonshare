import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/file_entity.dart';
import '../entities/folder_entity.dart';
import '../repositories/i_data_room_repository.dart';

class FetchDataRoomContentsUseCase {
  final IDataRoomRepository _repository;

  FetchDataRoomContentsUseCase(this._repository);

  Future<Either<Failure, List<FolderEntity>>> getFolders(String userId) async {
    return _repository.getUserFolders(userId);
  }

  Future<Either<Failure, List<FileEntity>>> getUnfiledDocuments(String userId) async {
    return _repository.getUnfiledDocuments(userId);
  }
}
