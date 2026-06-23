import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/link_entity.dart';
import '../../domain/repositories/i_links_repository.dart';
import '../datasources/supabase_links_datasource.dart';

/// Implementación del repositorio de links con Supabase.
class LinksRepositoryImpl implements ILinksRepository {
  final SupabaseLinksDataSource _dataSource;

  LinksRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<LinkEntity>>> getUserLinks(
    String ownerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final models = await _dataSource.getUserLinks(
        ownerId,
        limit: limit,
        offset: offset,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Error fetching user links: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> revokeLink(String linkId) async {
    try {
      await _dataSource.revokeLink(linkId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error revoking link: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFile(String fileId, String ownerId) async {
    try {
      await _dataSource.deleteFile(fileId, ownerId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error deleting file: $e'));
    }
  }
}
