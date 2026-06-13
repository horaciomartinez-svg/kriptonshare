import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/data_room_entity.dart';
import '../entities/file_entity.dart';

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
  Future<Either<Failure, FileEntity>> addFileToRoom({
    required String roomId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String storagePath,
    required bool isEncrypted,
    String? encryptionKeyId,
  });

  // Obtener archivos de un data room
  Future<Either<Failure, List<FileEntity>>> getRoomFiles(String roomId);

  // Incrementar contador de vistas
  Future<Either<Failure, void>> incrementViewCount(String roomId);

  // Verificar si un data room está activo y dentro de límites
  Future<Either<Failure, bool>> isRoomAccessible(String roomId);

  // Sincronización offline
  Future<Either<Failure, void>> syncOfflineData();
  Future<Either<Failure, List<DataRoomEntity>>> getLocalDataRooms();
  Future<Either<Failure, void>> queueOfflineOperation(Map<String, dynamic> operation);
}