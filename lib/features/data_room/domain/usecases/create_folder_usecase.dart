import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/folder_entity.dart';
import '../repositories/i_data_room_repository.dart';

class CreateFolderUseCase {
  final IDataRoomRepository _repository;

  CreateFolderUseCase(this._repository);

  Future<Either<Failure, FolderEntity>> call({
    required String ownerId,
    required String name,
    String? description,
  }) async {
    return _repository.createFolder(
      ownerId: ownerId,
      name: name,
      description: description,
    );
  }
}
