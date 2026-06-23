import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/link_entity.dart';
import '../repositories/i_links_repository.dart';

/// Caso de uso para obtener los links compartidos de un usuario.
class GetUserLinksUseCase {
  final ILinksRepository _repository;

  GetUserLinksUseCase(this._repository);

  Future<Either<Failure, List<LinkEntity>>> call(
    String ownerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return await _repository.getUserLinks(
      ownerId,
      limit: limit,
      offset: offset,
    );
  }
}
