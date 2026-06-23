import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/link_entity.dart';

/// Contrato de repositorio para gestión de links compartidos.
abstract class ILinksRepository {
  /// Obtener los links del usuario ordenados por fecha descendente.
  ///
  /// [limit] y [offset] permiten paginar los resultados desde Supabase.
  Future<Either<Failure, List<LinkEntity>>> getUserLinks(
    String ownerId, {
    int limit,
    int offset,
  });

  /// Revocar un link (marcar como inactivo).
  Future<Either<Failure, void>> revokeLink(String linkId);

  /// Eliminar un archivo, sus links y su objeto de storage.
  Future<Either<Failure, void>> deleteFile(String fileId, String ownerId);
}
