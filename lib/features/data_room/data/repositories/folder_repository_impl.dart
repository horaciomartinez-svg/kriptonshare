import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../../models/kripton_file.dart';
import '../../domain/entities/folder_entity.dart';
import '../../domain/entities/journey_telemetry_entity.dart';
import '../../domain/repositories/i_folder_repository.dart';
import '../datasources/folder_remote_datasource.dart';

class FolderRepositoryImpl implements IFolderRepository {
  final FolderRemoteDataSource _remote;
  final Uuid _uuid = const Uuid();

  FolderRepositoryImpl(SupabaseClient supabase) : _remote = FolderRemoteDataSource(supabase);

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
      return Right(_mapFolder(data, []));
    } catch (e) {
      return Left(ServerFailure('Error creando carpeta: $e'));
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
      return Left(ServerFailure('Error leyendo carpetas: $e'));
    }
  }

  @override
  Future<Either<Failure, FolderEntity>> getFolderById(String folderId) async {
    try {
      final folder = await _remote.getFolderById(folderId);
      if (folder == null) {
        return const Left(ServerFailure('Carpeta no encontrada'));
      }
      final files = await _remote.getFilesByFolderId(folderId);
      return Right(_mapFolder(folder, files));
    } catch (e) {
      return Left(ServerFailure('Error leyendo carpeta: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addFileToFolder({
    required String folderId,
    required String fileId,
  }) async {
    try {
      await _remote.addFileToFolder(folderId, fileId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error agregando archivo a carpeta: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> createFolderShareLink({
    required String folderId,
    required DateTime expiresAt,
    String? recipientEmail,
  }) async {
    try {
      final linkId = _uuid.v4();
      await _remote.createShareLink({
        'id': linkId,
        'folder_id': folderId,
        'created_by': Supabase.instance.client.auth.currentUser!.id,
        'expires_at': expiresAt.toIso8601String(),
        'recipient_email': recipientEmail,
        'is_active': true,
      });
      return Right(linkId);
    } catch (e) {
      return Left(ServerFailure('Error creando enlace de carpeta: $e'));
    }
  }

  @override
  Future<Either<Failure, FolderEntity>> getFolderByShareLinkId(String shareLinkId) async {
    try {
      final link = await _remote.getShareLinkById(shareLinkId);
      if (link == null) {
        return const Left(ServerFailure('Enlace inválido, expirado o revocado'));
      }
      final folderId = link['folder_id'] as String;
      final folder = await _remote.getFolderById(folderId);
      if (folder == null) {
        return const Left(ServerFailure('Carpeta no encontrada'));
      }
      final files = await _remote.getFilesByFolderId(folderId);
      return Right(_mapFolder(folder, files));
    } catch (e) {
      return Left(ServerFailure('Error leyendo enlace de carpeta: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logJourneyEvent(JourneyTelemetryEntity event) async {
    try {
      await _remote.logJourneyEvent(event.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error registrando telemetry: $e'));
    }
  }

  FolderEntity _mapFolder(Map<String, dynamic> folder, List<Map<String, dynamic>> files) {
    final fileList = files.map((f) => KriptonFile.fromJson(f)).toList();
    final totalSize = fileList.fold<int>(0, (sum, f) => sum + f.fileSizeBytes);
    return FolderEntity(
      id: folder['id'] as String,
      ownerId: folder['owner_id'] as String,
      name: folder['name'] as String,
      description: folder['description'] as String?,
      files: fileList,
      totalSizeBytes: totalSize,
      createdAt: DateTime.parse(folder['created_at'] as String),
      isDeleted: folder['is_deleted'] as bool? ?? false,
    );
  }
}
