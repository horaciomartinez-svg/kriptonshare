import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/data_room_entity.dart';
import '../entities/file_entity.dart';
import '../entities/folder_entity.dart';
import '../entities/legacy_file_entity.dart';
import '../entities/share_link_entity.dart';

abstract class IDataRoomRepository {
  // Crear un nuevo data room
  Future<Either<Failure, DataRoomEntity>> createDataRoom({
    required String name,
    required DateTime expiresAt,
    required String ownerId,
    int? maxViews,
    bool? watermarkEnabled,
    bool? downloadEnabled,
    List<String>? allowedIPs,
  });

  // Obtener todos los data rooms del usuario
  Future<Either<Failure, List<DataRoomEntity>>> getUserDataRooms(String userId);

  // Obtener un data room por ID
  Future<Either<Failure, DataRoomEntity>> getDataRoomById(String id);

  // Actualizar un data room
  Future<Either<Failure, DataRoomEntity>> updateDataRoom(DataRoomEntity dataRoom);

  // Eliminar un data room
  Future<Either<Failure, void>> deleteDataRoom(String id);

  // Revocar un data room (desactivar)
  Future<Either<Failure, void>> revokeDataRoom(String id);

  // Agregar archivo a data room
  Future<Either<Failure, LegacyFileEntity>> addFileToRoom({
    required String roomId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String storagePath,
    required bool isEncrypted,
    String? encryptionKeyId,
  });

  // Obtener archivos de un data room
  Future<Either<Failure, List<LegacyFileEntity>>> getRoomFiles(String roomId);

  // Incrementar contador de vistas
  Future<Either<Failure, void>> incrementViewCount(String roomId);

  // Verificar si un data room está activo y dentro de límites
  Future<Either<Failure, bool>> isRoomAccessible(String roomId);

  // Sincronización offline
  Future<Either<Failure, void>> syncOfflineData();
  Future<Either<Failure, List<DataRoomEntity>>> getLocalDataRooms();
  Future<Either<Failure, void>> queueOfflineOperation(Map<String, dynamic> operation);

  // === Virtual Data Room (VDR) ===

  /// Estructura completa de carpetas + archivos sueltos del usuario (Drive-like)
  Future<Either<Failure, List<FolderEntity>>> getUserFolders(String userId);
  Future<Either<Failure, List<FileEntity>>> getUnfiledDocuments(String userId);

  /// Crear carpeta Virtual Data Room (solo Premium — validado en servidor)
  Future<Either<Failure, FolderEntity>> createFolder({
    required String ownerId,
    required String name,
    String? description,
  });

  /// Carga INDIVIDUAL: cifra en Isolate y sube directo a R2
  Future<Either<Failure, FileEntity>> encryptAndUploadFile({
    required String ownerId,
    required String? folderId, // null = envío individual 1 a 1
    required String filename,
    required Uint8List fileBytes,
    required String mimeType,
    required String userPassword,
  });

  /// Enlace compartido para UN ARCHIVO o UNA CARPETA (máximo 30 días Premium)
  Future<Either<Failure, ShareLinkEntity>> createShareLink({
    required String createdBy,
    String? fileId,
    String? folderId,
    required ShareLinkType linkType,
    required bool requireRecipientEmail,
    required bool enableWatermark,
    required DateTime expiresAt,
  });

  /// Lazy Decryption: descarga de R2 y descifra UN solo archivo en RAM
  Future<Either<Failure, Uint8List>> downloadAndDecryptFile({
    required FileEntity file,
    required String userPassword,
  });

  /// Telemetría de lectura (Journey Analytics)
  Future<Either<Failure, void>> recordJourneyEvent({
    required String shareLinkId,
    String? fileId,
    required String recipientEmail,
    required String eventType, // lobby_enter | file_open | page_view | lobby_exit
    int? pageNumber,
    int durationMs = 0,
  });
}