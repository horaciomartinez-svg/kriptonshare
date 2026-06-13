import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/data_room_entity.dart';
import '../../domain/repositories/i_data_room_repository.dart';
import '../datasources/local_database_datasource.dart';
import '../../../../utils/constants.dart';
import '../../../../core/error/failures.dart';

/// Implementación del Repositorio de Data Rooms con Offline-First.
/// SQLite es la fuente primaria de verdad.
/// Supabase es la réplica eventual sincronizada vía cola asíncrona.
class DataRoomRepositoryImpl implements IDataRoomRepository {
  final LocalDatabaseDataSource _localDB;
  final SupabaseClient _supabase;

  DataRoomRepositoryImpl({
    required LocalDatabaseDataSource localDB,
    required SupabaseClient supabase,
  })  : _localDB = localDB,
        _supabase = supabase;

  @override
  Future<DataRoomEntity> createEphemeralRoom(
    DataRoomEntity room,
    Uint8List encryptedPayload,
  ) async {
    // 1. Persistir localmente INMEDIATAMENTE (Offline-First)
    await _localDB.insertRoom({
      'id': room.id,
      'owner_id': room.ownerId,
      'original_filename': room.originalFilename,
      'file_size_bytes': room.fileSizeBytes,
      'status': room.status,
      'expires_at': room.expiresAt.toIso8601String(),
      'storage_object_key': room.storageObjectKey,
      'mime_type': room.mimeType,
      'max_downloads': room.maxDownloads,
      'downloads_count': room.downloadsCount,
      'sync_status': 'pending',
    });

    // 2. Encolar sincronización asíncrona con Supabase
    await _localDB.enqueueSyncOperation(
      roomId: room.id,
      operation: 'create',
      payload: room.mimeType,
    );

    // 3. Intentar sincronización inmediata si hay red
    try {
      await _syncRoomToSupabase(room, encryptedPayload);
      await _localDB.updateSyncStatus(room.id, 'synced');
    } catch (e) {
      // Si falla, permanece en cola para Workmanager
      await _localDB.updateSyncStatus(room.id, 'error');
    }

    return room;
  }

  /// Sincroniza un room a Supabase + Storage
  Future<void> _syncRoomToSupabase(
    DataRoomEntity room,
    Uint8List encryptedPayload,
  ) async {
    if (room.storageObjectKey == null) {
      throw const ServerFailure('storage_object_key no puede ser nulo para sincronización');
    }

    // Subir payload encriptado a Supabase Storage
    await _supabase.storage.from(AppConstants.bucketName).uploadBinary(
      room.storageObjectKey!,
      encryptedPayload,
      fileOptions: const FileOptions(
        contentType: 'application/octet-stream',
        upsert: false,
      ),
    );

    // Crear registro en tabla files
    await _supabase.from('files').insert({
      'id': room.id,
      'owner_id': room.ownerId,
      'original_filename': room.originalFilename,
      'file_size_bytes': room.fileSizeBytes,
      'mime_type': room.mimeType ?? 'application/octet-stream',
      'storage_provider': AppConstants.storageProvider,
      'bucket_name': AppConstants.bucketName,
      'storage_object_key': room.storageObjectKey,
      'expires_at': room.expiresAt.toIso8601String(),
      'status': room.status,
      'max_downloads': room.maxDownloads ?? AppConstants.maxDownloadsDefault,
    });
  }

  @override
  Stream<List<DataRoomEntity>> watchLocalDataRooms() {
    // Retorna un stream que emite cada vez que cambia la DB local
    final controller = StreamController<List<DataRoomEntity>>.broadcast();

    Future<void> emitRooms() async {
      final rooms = await getLocalDataRooms();
      controller.add(rooms);
    }

    emitRooms();

    // Polling simple cada 2 segundos (SQLite no tiene streams nativos)
    final timer = Timer.periodic(const Duration(seconds: 2), (_) {
      emitRooms();
    });

    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<List<DataRoomEntity>> getLocalDataRooms() async {
    final rows = await _localDB.queryRooms();
    return rows.map((json) => _mapToEntity(json)).toList();
  }

  @override
  Future<DataRoomEntity?> getDataRoomById(String roomId) async {
    final row = await _localDB.getRoomById(roomId);
    if (row == null) return null;
    return _mapToEntity(row);
  }

  @override
  Future<void> revokeDataRoom(String roomId) async {
    // 1. Revocación inmediata local
    await _localDB.updateRoomStatus(roomId, 'revoked');

    // 2. Encolar revocación para sincronización
    await _localDB.enqueueSyncOperation(
      roomId: roomId,
      operation: 'revoke',
    );

    // 3. Intentar sincronización inmediata
    try {
      await _supabase.from('share_links').update({
        'is_active': false,
      }).eq('file_id', roomId);
      await _supabase.from('files').update({
        'status': 'revoked',
      }).eq('id', roomId);
    } catch (e) {
      // Queda en cola para sincronización futura
    }
  }

  @override
  Future<void> syncPendingOperations() async {
    final pending = await _localDB.getPendingSyncOperations();

    for (final op in pending) {
      final roomId = op['room_id'] as String;
      final operation = op['operation'] as String;

      try {
        switch (operation) {
          case 'create':
            final room = await _localDB.getRoomById(roomId);
            if (room != null) {
              // Re-subir el payload si es necesario
              // Nota: en un flujo real, el payload encriptado debe estar
              // disponible en caché local o reprocesarse
            }
            break;
          case 'revoke':
            await _supabase.from('files').update({
              'status': 'revoked',
            }).eq('id', roomId);
            break;
          case 'delete':
            await _supabase.from('files').delete().eq('id', roomId);
            break;
        }
        await _localDB.deleteSyncOperation(op['id'] as int);
      } catch (e) {
        // Mantener en cola para reintento
      }
    }
  }

  DataRoomEntity _mapToEntity(Map<String, dynamic> json) {
    return DataRoomEntity(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      originalFilename: json['original_filename'] as String,
      fileSizeBytes: json['file_size_bytes'] as int,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      storageObjectKey: json['storage_object_key'] as String?,
      mimeType: json['mime_type'] as String?,
      maxDownloads: json['max_downloads'] as int?,
      downloadsCount: json['downloads_count'] as int? ?? 0,
    );
  }
}
