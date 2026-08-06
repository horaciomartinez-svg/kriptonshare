import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/entities/folder_entity.dart';
import '../../domain/entities/journey_telemetry_entity.dart';
import '../../domain/entities/share_link_entity.dart';
import '../../domain/repositories/i_folder_repository.dart';
import '../datasources/folder_remote_datasource.dart';

class FolderRepositoryImpl implements IFolderRepository {
  final FolderRemoteDataSource _remote;
  final Uuid _uuid;

  FolderRepositoryImpl(SupabaseClient supabase, {Uuid? uuid})
      : _remote = FolderRemoteDataSource(supabase),
        _uuid = uuid ?? const Uuid();

  @override
  Future<Either<Failure, FolderEntity>> createFolder({
    required String ownerId,
    required String name,
    String? description,
  }) async {
    try {
      final data = await _remote.createFolder({
        'owner_id': ownerId,
        'name': name.trim(),
        'description': description,
        'is_deleted': false,
      });
      return Right(_mapFolder(data, const []));
    } catch (e) {
      return Left(ServerFailure('Error creating folder: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FolderEntity>>> getUserFolders(String userId) async {
    try {
      final rows = await _remote.getFoldersByOwner(userId);
      final folders = <FolderEntity>[];
      for (final row in rows) {
        final files = await _remote.getFilesByFolderId(row['id'] as String);
        folders.add(_mapFolder(row, files));
      }
      return Right(folders);
    } catch (e) {
      return Left(ServerFailure('Error reading folders: $e'));
    }
  }

  @override
  Future<Either<Failure, FolderEntity>> getFolderById(String folderId) async {
    try {
      final folder = await _remote.getFolderById(folderId);
      if (folder == null) {
        return const Left(ServerFailure('Folder not found'));
      }
      final files = await _remote.getFilesByFolderId(folderId);
      return Right(_mapFolder(folder, files));
    } catch (e) {
      return Left(ServerFailure('Error reading folder: $e'));
    }
  }

  @override
  Future<Either<Failure, FolderEntity>> getFolderByShareLinkId(String shareLinkId) async {
    try {
      final link = await _remote.getShareLinkById(shareLinkId);
      if (link == null) {
        return const Left(ServerFailure('Invalid, expired or revoked link'));
      }
      final folderId = link['folder_id'] as String;
      final folder = await _remote.getFolderById(folderId);
      if (folder == null) {
        return const Left(ServerFailure('Folder not found'));
      }
      final files = await _remote.getFilesByFolderId(folderId);
      return Right(_mapFolder(folder, files));
    } catch (e) {
      return Left(ServerFailure('Error reading folder link: $e'));
    }
  }

  @override
  Future<Either<Failure, ShareLinkEntity>> createFolderShareLink({
    required String folderId,
    required DateTime expiresAt,
    String? recipientEmail,
    bool requireRecipientEmail = true,
    bool enableWatermark = true,
  }) async {
    try {
      final validation = await _remote.validateShareLinkExpiration(
        userId: Supabase.instance.client.auth.currentUser!.id,
        expiresAt: expiresAt.toIso8601String(),
      );
      final isValid = validation['is_valid'] as bool? ?? false;
      if (!isValid) {
        return Left(ValidationFailure(validation['message'] as String? ?? 'Invalid expiration'));
      }

      final linkId = _uuid.v4();
      final data = await _remote.createShareLink({
        'id': linkId,
        'folder_id': folderId,
        'created_by': Supabase.instance.client.auth.currentUser!.id,
        'link_type': 'full_folder',
        'recipient_email': recipientEmail,
        'require_recipient_email': requireRecipientEmail,
        'enable_watermark': enableWatermark,
        'expires_at': expiresAt.toIso8601String(),
        'is_active': true,
      });
      return Right(_mapShareLink(data));
    } on ValidationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Error creating folder link: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logJourneyEvent(JourneyTelemetryEntity event) async {
    try {
      await _remote.logJourneyEvent(event.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error logging telemetry: $e'));
    }
  }

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
}
