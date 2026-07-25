import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/folder_entity.dart';
import '../entities/journey_telemetry_entity.dart';

abstract class IFolderRepository {
  /// Crea una carpeta virtual (Data Room) para un usuario Premium.
  Future<Either<Failure, FolderEntity>> createFolder({
    required String ownerId,
    required String name,
    String? description,
  });

  /// Lista las carpetas del usuario autenticado.
  Future<Either<Failure, List<FolderEntity>>> getUserFolders(String userId);

  /// Obtiene una carpeta con sus archivos.
  Future<Either<Failure, FolderEntity>> getFolderById(String folderId);

  /// Agrega un archivo existente a una carpeta.
  Future<Either<Failure, void>> addFileToFolder({
    required String folderId,
    required String fileId,
  });

  /// Crea un share_link para una carpeta completa.
  Future<Either<Failure, String>> createFolderShareLink({
    required String folderId,
    required DateTime expiresAt,
    String? recipientEmail,
  });

  /// Obtiene una carpeta por el ID de su share_link (para receptores).
  Future<Either<Failure, FolderEntity>> getFolderByShareLinkId(String shareLinkId);

  /// Registra un evento de Journey Telemetry.
  Future<Either<Failure, void>> logJourneyEvent(JourneyTelemetryEntity event);
}
