import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/data_room_entity.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/repositories/i_data_room_repository.dart';
import '../datasources/local_database_datasource.dart';
import '../datasources/supabase_data_source.dart';
import '../models/data_room_model.dart';
import '../models/file_model.dart';
import '../../../../core/error/failures.dart';
import '../../../../utils/constants.dart';

/// Implementación del Repositorio de Data Rooms con Offline-First.
class DataRoomRepositoryImpl implements IDataRoomRepository {
  final LocalDatabaseDataSource _localDB;
  final SupabaseDataSource _supabase;

  DataRoomRepositoryImpl({
    required LocalDatabaseDataSource localDB,
    required SupabaseClient supabase,
  })  : _localDB = localDB,
        _supabase = SupabaseDataSource(supabase);

  @override
  Future<Either<Failure, DataRoomEntity>> createDataRoom({
    required String name,
    required DateTime expiresAt,
    required String ownerId,
    int? maxViews,
    bool? watermarkEnabled,
    bool? downloadEnabled,
    List<String>? allowedIPs,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final room = DataRoomModel(
        id: id,
        name: name,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        isActive: true,
        ownerId: ownerId,
        maxViews: maxViews ?? 0,
        currentViews: 0,
        watermarkEnabled: watermarkEnabled ?? true,
        downloadEnabled: downloadEnabled ?? false,
        allowedIPs: allowedIPs ?? const [],
      );

      await _localDB.insertRoom(room.toJson());
      await _localDB.enqueueSyncOperation(roomId: id, operation: 'create');

      // Intentar sync inmediato
      try {
        await _supabase.createRoom(room.toJson());
        await _localDB.updateSyncStatus(id, 'synced');
      } catch (_) {
        await _localDB.updateSyncStatus(id, 'pending');
      }

      return Right(room.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating data room: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DataRoomEntity>>> getUserDataRooms(String userId) async {
    try {
      final rows = await _localDB.queryRooms();
      final rooms = rows
          .where((r) => r['owner_id'] == userId)
          .map((json) => _mapToEntity(json))
          .toList();
      return Right(rooms);
    } catch (e) {
      return Left(CacheFailure('Error reading data rooms: $e'));
    }
  }

  @override
  Future<Either<Failure, DataRoomEntity>> getDataRoomById(String id) async {
    try {
      final row = await _localDB.getRoomById(id);
      if (row == null) {
        return const Left(CacheFailure('Data room not found'));
      }
      return Right(_mapToEntity(row));
    } catch (e) {
      return Left(CacheFailure('Error reading data room: $e'));
    }
  }

  @override
  Future<Either<Failure, DataRoomEntity>> updateDataRoom(DataRoomEntity dataRoom) async {
    try {
      final model = DataRoomModel(
        id: dataRoom.id,
        name: dataRoom.name,
        createdAt: dataRoom.createdAt,
        expiresAt: dataRoom.expiresAt,
        isActive: dataRoom.isActive,
        ownerId: dataRoom.ownerId,
        maxViews: dataRoom.maxViews,
        currentViews: dataRoom.currentViews,
        watermarkEnabled: dataRoom.watermarkEnabled,
        downloadEnabled: dataRoom.downloadEnabled,
        allowedIPs: dataRoom.allowedIPs,
        metadata: dataRoom.metadata,
      );

      await _localDB.updateRoomStatus(dataRoom.id, 'updated');
      await _localDB.enqueueSyncOperation(roomId: dataRoom.id, operation: 'update');

      try {
        await _supabase.updateRoom(dataRoom.id, model.toJson());
        await _localDB.updateSyncStatus(dataRoom.id, 'synced');
      } catch (_) {
        await _localDB.updateSyncStatus(dataRoom.id, 'pending');
      }

      return Right(dataRoom);
    } catch (e) {
      return Left(CacheFailure('Error updating data room: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDataRoom(String id) async {
    try {
      await _localDB.deleteRoom(id);
      await _localDB.enqueueSyncOperation(roomId: id, operation: 'delete');

      try {
        await _supabase.deleteRoom(id);
      } catch (_) {}

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error deleting data room: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> revokeDataRoom(String id) async {
    try {
      await _localDB.updateRoomStatus(id, 'revoked');
      await _localDB.enqueueSyncOperation(roomId: id, operation: 'revoke');

      try {
        await _supabase.updateRoom(id, {'is_active': false, 'status': 'revoked'});
      } catch (_) {}

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error revoking data room: $e'));
    }
  }

  @override
  Future<Either<Failure, FileEntity>> addFileToRoom({
    required String roomId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String storagePath,
    required bool isEncrypted,
    String? encryptionKeyId,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final file = FileModel(
        id: id,
        roomId: roomId,
        name: fileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: AppConstants.maxDurationHours)),
        storagePath: storagePath,
        ownerId: '',
        isEncrypted: isEncrypted,
        encryptionKeyId: encryptionKeyId,
      );

      await _localDB.insertFile(file.toJson());
      return Right(file.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error adding file: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FileEntity>>> getRoomFiles(String roomId) async {
    try {
      final rows = await _localDB.getFilesByRoomId(roomId);
      final files = rows.map((json) => FileModel.fromJson(json).toEntity()).toList();
      return Right(files);
    } catch (e) {
      return Left(CacheFailure('Error reading files: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> incrementViewCount(String roomId) async {
    try {
      final room = await _localDB.getRoomById(roomId);
      if (room == null) {
        return const Left(CacheFailure('Room not found'));
      }
      // TODO: Increment view count in local DB
      await _localDB.updateSyncStatus(roomId, 'active');
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error incrementing view count: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isRoomAccessible(String roomId) async {
    try {
      final row = await _localDB.getRoomById(roomId);
      if (row == null) {
        return const Right(false);
      }
      final isActive = (row['is_active'] as int? ?? 1) == 1;
      final expiresAt = DateTime.parse(row['expires_at'] as String);
      final maxViews = row['max_views'] as int? ?? 0;
      final currentViews = row['current_views'] as int? ?? 0;

      final isExpired = DateTime.now().isAfter(expiresAt);
      final isViewLimitReached = maxViews > 0 && currentViews >= maxViews;

      return Right(isActive && !isExpired && !isViewLimitReached);
    } catch (e) {
      return Left(CacheFailure('Error checking room accessibility: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncOfflineData() async {
    try {
      final pending = await _localDB.getPendingSyncOperations();
      for (final op in pending) {
        final roomId = op['record_id'] as String;
        final operation = op['operation_type'] as String;
        try {
          switch (operation) {
            case 'create':
            case 'update':
              final room = await _localDB.getRoomById(roomId);
              if (room != null) {
                if (operation == 'create') {
                  await _supabase.createRoom(room);
                } else {
                  await _supabase.updateRoom(roomId, room);
                }
              }
              break;
            case 'delete':
              await _supabase.deleteRoom(roomId);
              break;
            case 'revoke':
              await _supabase.updateRoom(roomId, {'is_active': false, 'status': 'revoked'});
              break;
          }
          await _localDB.deleteSyncOperation(op['id'] as int);
        } catch (e) {
          await _localDB.incrementRetryCount(op['id'] as int);
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error syncing offline data: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DataRoomEntity>>> getLocalDataRooms() async {
    return getUserDataRooms(''); // Retorna todos los rooms locales
  }

  @override
  Future<Either<Failure, void>> queueOfflineOperation(Map<String, dynamic> operation) async {
    try {
      final roomId = operation['room_id'] as String? ?? '';
      final op = operation['operation'] as String? ?? 'unknown';
      await _localDB.enqueueSyncOperation(roomId: roomId, operation: op);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error queuing operation: $e'));
    }
  }

  DataRoomEntity _mapToEntity(Map<String, dynamic> json) {
    return DataRoomEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isActive: (json['is_active'] as int? ?? 1) == 1,
      ownerId: json['owner_id'] as String,
      maxViews: json['max_views'] as int? ?? 0,
      currentViews: json['current_views'] as int? ?? 0,
      watermarkEnabled: (json['watermark_enabled'] as int? ?? 1) == 1,
      downloadEnabled: (json['download_enabled'] as int? ?? 0) == 1,
      allowedIPs: (json['allowed_ips'] as String?)?.split(',') ?? const [],
      metadata: const {},
    );
  }
}
