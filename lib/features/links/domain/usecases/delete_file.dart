import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/i_links_repository.dart';

/// Caso de uso para eliminar un archivo y sus links asociados.
class DeleteFileUseCase {
  final ILinksRepository _repository;

  DeleteFileUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String fileId,
    required String ownerId,
  }) async {
    return await _repository.deleteFile(fileId, ownerId);
  }
}
