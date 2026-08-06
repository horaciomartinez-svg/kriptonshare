import 'dart:async';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/constants/storage_constants.dart';
import '../../../../core/crypto/crypto_isolate_engine.dart';
import '../../../../core/network/r2_client.dart';
import '../../domain/entities/data_room_entity.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/entities/folder_entity.dart';
import '../../domain/entities/legacy_file_entity.dart';
import '../../domain/entities/share_link_entity.dart';
import '../../domain/repositories/i_data_room_repository.dart';
import '../datasources/folder_remote_datasource.dart';
import '../datasources/local_database_datasource.dart';
import '../datasources/r2_storage_datasource.dart';
import '../datasources/supabase_data_source.dart';
import '../models/data_room_model.dart';
import '../models/file_model.dart';
import '../../../../core/error/failures.dart';
import '../../../../utils/constants.dart';

/// Implementación del Repositorio de Data Rooms con Offline-First.
class DataRoomRepositoryImpl implements IDataRoomRepository {
  final LocalDatabaseDataSource _localDB;
  final SupabaseDataSource _supabase;
  final FolderRemoteDataSource _folderRemote;
  final R2StorageDataSource _r2;
  final Uuid _uuid;

  DataRoomRepositoryImpl({
    required LocalDatabaseDataSource localDB,
    required SupabaseClient supabase,
    FolderRemoteDataSource? folderRemote,
    R2StorageDataSource? r2,
    Uuid? uuid,
  })  : _localDB = localDB,
        _supabase = SupabaseDataSource(supabase),
        _folderRemote = folderRemote ?? FolderRemoteDataSource(supabase),
        _r2 = r2 ?? R2StorageDataSource(client: R2Client()),
        _uuid = uuid ?? const Uuid();

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
  Future<Either<Failure, LegacyFileEntity>> addFileToRoom({
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
  Future<Either<Failure, List<LegacyFileEntity>>> getRoomFiles(String roomId) async {
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

  // ─── Virtual Data Room (VDR) — Nuevos métodos ───

  @override
  Future<Either<Failure, List<FolderEntity>>> getUserFolders(String userId) async {
    try {
      final rows = await _folderRemote.getFoldersByOwner(userId);
      final folders = <FolderEntity>[];
      for (final row in rows) {
        final fileRows = await _folderRemote.getFilesByFolderId(row['id'] as String);
        folders.add(_mapFolder(row, fileRows));
      }
      return Right(folders);
    } catch (e) {
      return Left(ServerFailure('Error leyendo carpetas: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FileEntity>>> getUnfiledDocuments(String userId) async {
    try {
      final rows = await _folderRemote.getUnfiledDocuments(userId);
      return Right(rows.map((r) => _mapFile(r)).toList());
    } catch (e) {
      return Left(ServerFailure('Error leyendo archivos sueltos: $e'));
    }
  }

  @override
  Future<Either<Failure, FolderEntity>> createFolder({
    required String ownerId,
    required String name,
    String? description,
  }) async {
    try {
      final data = await _folderRemote.createFolder({
        'owner_id': ownerId,
        'name': name.trim(),
        'description': description,
        'is_deleted': false,
      });
      return Right(_mapFolder(data, const []));
    } catch (e) {
      return Left(ServerFailure('Error creando carpeta: $e'));
    }
  }

  @override
  Future<Either<Failure, FileEntity>> encryptAndUploadFile({
    required String ownerId,
    required String? folderId,
    required String filename,
    required Uint8List fileBytes,
    required String mimeType,
    required String userPassword,
  }) async {
    try {
      // 1. Validar límites en servidor
      final limitResult = await _folderRemote.checkUploadLimits(
        userId: ownerId,
        fileSize: fileBytes.length,
      );
      final canUpload = limitResult['can_upload'] as bool? ?? false;
      if (!canUpload) {
        return Left(ValidationFailure(limitResult['message'] as String? ?? 'Limit exceeded'));
      }

      // 2. Cifrar en Isolate
      final encrypted = await encryptFileInIsolate(
        fileBytes: fileBytes,
        password: userPassword,
      );
      final salt = encrypted['salt']!;
      final nonce = encrypted['nonce']!;
      final ciphertext = encrypted['ciphertext']!;
      final authTag = encrypted['authTag']!;
      final key = encrypted['key']!;

      // 3. Construir payload completo: salt || nonce || ciphertext || authTag
      final payload = Uint8List(salt.length + nonce.length + ciphertext.length + authTag.length);
      payload.setAll(0, salt);
      payload.setAll(salt.length, nonce);
      payload.setAll(salt.length + nonce.length, ciphertext);
      payload.setAll(salt.length + nonce.length + ciphertext.length, authTag);

      // 4. Subir a R2
      final objectKey = _uuid.v4();
      await _r2.uploadEncryptedObject(objectKey: objectKey, encryptedBytes: payload);

      // 5. Registrar metadata en Supabase
      final fileId = _uuid.v4();
      await _folderRemote.insertFile({
        'id': fileId,
        'owner_id': ownerId,
        'folder_id': folderId,
        'original_filename': filename,
        'file_size_bytes': fileBytes.length,
        'mime_type': mimeType,
        'storage_provider': 'r2',
        'bucket_name': AppConstants.bucketName,
        'storage_object_key': objectKey,
        'aes_key_encrypted': key.toList(),
        'salt': salt.toList(),
        'nonce': nonce.toList(),
        'mac_tag': authTag.toList(),
        'encryption_salt': salt.toList(),
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(days: StorageConstants.premiumMaxLinkDays)).toIso8601String(),
        'status': 'active',
      });

      return Right(FileEntity(
        id: fileId,
        ownerId: ownerId,
        folderId: folderId,
        originalFilename: filename,
        fileSizeBytes: fileBytes.length,
        mimeType: mimeType,
        storageObjectKey: objectKey,
        salt: {'bytes': salt.toList()},
        nonce: {'bytes': nonce.toList()},
        macTag: {'bytes': authTag.toList()},
        aesKeyEncrypted: {'bytes': key.toList()},
        createdAt: DateTime.now(),
      ));
    } on ValidationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Error cifrando/subiendo archivo: $e'));
    }
  }

  @override
  Future<Either<Failure, ShareLinkEntity>> createShareLink({
    required String createdBy,
    String? fileId,
    String? folderId,
    required ShareLinkType linkType,
    required bool requireRecipientEmail,
    required bool enableWatermark,
    required DateTime expiresAt,
  }) async {
    try {
      // Validar expiración por tier
      final validation = await _folderRemote.validateShareLinkExpiration(
        userId: createdBy,
        expiresAt: expiresAt.toIso8601String(),
      );
      final isValid = validation['is_valid'] as bool? ?? false;
      if (!isValid) {
        return Left(ValidationFailure(validation['message'] as String? ?? 'Invalid expiration'));
      }

      final linkId = _uuid.v4();
      final data = await _folderRemote.createShareLink({
        'id': linkId,
        'created_by': createdBy,
        'file_id': fileId,
        'folder_id': folderId,
        'link_type': linkType == ShareLinkType.singleFile ? 'single_file' : 'full_folder',
        'require_recipient_email': requireRecipientEmail,
        'enable_watermark': enableWatermark,
        'expires_at': expiresAt.toIso8601String(),
        'is_active': true,
      });

      return Right(_mapShareLink(data));
    } on ValidationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Error creando enlace: $e'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> downloadAndDecryptFile({
    required FileEntity file,
    required String userPassword,
  }) async {
    try {
      final encrypted = await _r2.downloadEncryptedObject(file.storageObjectKey);
      final decrypted = await decryptFileInIsolate(
        encryptedBytes: encrypted,
        password: userPassword,
      );
      return Right(decrypted);
    } catch (e) {
      return Left(CryptoFailure('Error descifrando archivo: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> recordJourneyEvent({
    required String shareLinkId,
    String? fileId,
    required String recipientEmail,
    required String eventType,
    int? pageNumber,
    int durationMs = 0,
  }) async {
    try {
      await _folderRemote.logJourneyEvent({
        'share_link_id': shareLinkId,
        'file_id': fileId,
        'recipient_email': recipientEmail,
        'event_type': eventType,
        'page_number': pageNumber,
        'duration_ms': durationMs,
        'created_at': DateTime.now().toIso8601String(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error registrando telemetry: $e'));
    }
  }

  // ─── Mappers ───

  FolderEntity _mapFolder(Map<String, dynamic> folder, List<Map<String, dynamic>> files) {
    final fileList = files.map((f) => _mapFile(f)).toList();
    final totalSize = fileList.fold<int>(0, (sum, f) => sum + f.fileSizeBytes);
    return FolderEntity(
      id: folder['id'] as String,
      ownerId: folder['owner_id'] as String,
      name: folder['name'] as String,
      description: folder['description'] as String?,
      files: fileList,
      totalSizeBytes: totalSize,
      isDeleted: folder['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(folder['created_at'] as String),
      updatedAt: folder['updated_at'] != null
          ? DateTime.parse(folder['updated_at'] as String)
          : DateTime.parse(folder['created_at'] as String),
    );
  }

  FileEntity _mapFile(Map<String, dynamic> json) {
    return FileEntity(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      folderId: json['folder_id'] as String?,
      originalFilename: json['original_filename'] as String,
      fileSizeBytes: json['file_size_bytes'] as int,
      mimeType: json['mime_type'] as String,
      storageObjectKey: json['storage_object_key'] as String,
      salt: _cryptoField(json['salt']),
      nonce: _cryptoField(json['nonce']),
      macTag: _cryptoField(json['mac_tag']),
      aesKeyEncrypted: _cryptoField(json['aes_key_encrypted']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> _cryptoField(dynamic value) {
    if (value == null) return {'bytes': <int>[]};
    if (value is Map<String, dynamic>) return value;
    if (value is List<dynamic>) return {'bytes': value.cast<int>()};
    if (value is List<int>) return {'bytes': value};
    return {'bytes': <int>[]};
  }

  ShareLinkEntity _mapShareLink(Map<String, dynamic> json) {
    return ShareLinkEntity(
      id: json['id'] as String,
      createdBy: json['created_by'] as String,
      fileId: json['file_id'] as String?,
      folderId: json['folder_id'] as String?,
      linkType: json['link_type'] == 'full_folder'
          ? ShareLinkType.fullFolder
          : ShareLinkType.singleFile,
      isActive: json['is_active'] as bool? ?? true,
      requireRecipientEmail: json['require_recipient_email'] as bool? ?? true,
      enableWatermark: json['enable_watermark'] as bool? ?? true,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      accessCount: json['access_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
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
