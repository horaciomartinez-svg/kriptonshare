import 'dart:typed_data';
import '../entities/data_room_entity.dart';

/// Interfaz de Repositorio de Data Rooms (Capa de Dominio).
/// Define el contrato de negocio sin conocer implementaciones externas.
/// Fuente de verdad: SQLite local (Offline-First).
abstract class IDataRoomRepository {
  /// Guarda metadatos en SQLite (Offline-First) e inicia sincronización con Supabase.
  /// El payload encriptado se sube a Cloudflare R2 de forma asíncrona.
  Future<DataRoomEntity> createEphemeralRoom(
    DataRoomEntity room,
    Uint8List encryptedPayload,
  );

  /// Recupera los Data Rooms desde la caché local (SQLite) como Stream reactivo.
  Stream<List<DataRoomEntity>> watchLocalDataRooms();

  /// Recupera los Data Rooms de forma puntual (lista snapshot).
  Future<List<DataRoomEntity>> getLocalDataRooms();

  /// Elimina un archivo lógicamente (Revocación inmediata local y encolado asíncrono).
  Future<void> revokeDataRoom(String roomId);

  /// Sincroniza manualmente la cola de operaciones pendientes con Supabase.
  Future<void> syncPendingOperations();

  /// Obtiene un Data Room por ID desde la caché local.
  Future<DataRoomEntity?> getDataRoomById(String roomId);
}
