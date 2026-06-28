import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../services/crypto_service.dart';
import '../../../../utils/constants.dart';
import '../../domain/entities/upload_result_entity.dart';
import '../../domain/repositories/i_upload_repository.dart';
import '../datasources/supabase_upload_datasource.dart';

/// Implementación del repositorio de subida con cifrado local y Supabase.
class UploadRepositoryImpl implements IUploadRepository {
  final SupabaseUploadDataSource _dataSource;
  final CryptoService _cryptoService;
  final NetworkInfo _networkInfo;
  final Uuid _uuid;

  UploadRepositoryImpl({
    required SupabaseUploadDataSource dataSource,
    required CryptoService cryptoService,
    required NetworkInfo networkInfo,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _cryptoService = cryptoService,
        _networkInfo = networkInfo,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Either<Failure, UploadResultEntity>> uploadFile({
    required String ownerId,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    required String password,
    DateTime? expiresAt,
    int? maxDownloads,
    String? recipientEmail,
  }) async {
    // 1. Validar conectividad antes de operaciones de red
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      // 2. Cifrar archivo localmente
      final encrypted = await _cryptoService.encryptFile(
        fileBytes: fileBytes,
        password: password,
      );

      final salt = encrypted['salt'] as List<int>;
      final nonce = encrypted['nonce'] as List<int>;
      final ciphertext = encrypted['ciphertext'] as List<int>;
      final authTag = encrypted['authTag'] as List<int>;
      final key = encrypted['key'] as List<int>;

      // 3. Preparar payload cifrado para storage
      final encryptedBytes = Uint8List.fromList([
        ...salt,
        ...nonce,
        ...ciphertext,
        ...authTag,
      ]);

      // 4. Generar identificadores
      final storageKey = _uuid.v4();
      final fileId = _uuid.v4();
      final linkId = _uuid.v4();
      final effectiveExpiresAt = expiresAt ?? DateTime.now().add(
        const Duration(hours: AppConstants.maxDurationHours),
      );

      // 5. Subir a Supabase Storage
      await _dataSource.uploadEncryptedFile(
        bucket: AppConstants.bucketName,
        storageKey: storageKey,
        encryptedBytes: encryptedBytes,
      );

      // 6. Registrar metadata en tabla 'files'
      await _dataSource.createFileRecord({
        'id': fileId,
        'owner_id': ownerId,
        'original_filename': fileName,
        'file_size_bytes': fileBytes.length,
        'mime_type': mimeType,
        'storage_provider': AppConstants.storageProvider,
        'bucket_name': AppConstants.bucketName,
        'storage_object_key': storageKey,
        'object_path': storageKey,
        'aes_key_encrypted': key,
        'encryption_salt': base64Encode(salt),
        'salt': salt,
        'nonce': nonce,
        'mac_tag': authTag,
        'is_deleted': false,
        'expires_at': effectiveExpiresAt.toIso8601String(),
        'max_downloads': maxDownloads ?? AppConstants.maxDownloadsDefault,
        'status': 'active',
      });

      // 7. Generar link temporal en tabla 'share_links'
      await _dataSource.createShareLinkRecord({
        'id': linkId,
        'file_id': fileId,
        'created_by': ownerId,
        'expires_at': effectiveExpiresAt.toIso8601String(),
        'recipient_email': recipientEmail,
        'is_active': true,
      });

      return Right(
        UploadResultEntity(
          linkId: linkId,
          fileId: fileId,
          createdBy: ownerId,
          expiresAt: effectiveExpiresAt,
          createdAt: DateTime.now(),
          shareUrl: AppConstants.shareUrl(linkId),
          recipientEmail: recipientEmail,
        ),
      );
    } on SocketException catch (e) {
      return Left(NetworkFailure('Error de red: ${e.message}'));
    } on TimeoutException catch (e) {
      return Left(NetworkFailure('Tiempo de espera agotado: ${e.message}'));
    } on PostgrestException catch (e) {
      return Left(_mapSupabaseError(e.message, e.code));
    } on StorageException catch (e) {
      return Left(_mapSupabaseError(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Error inesperado al subir archivo: $e'));
    }
  }

  Failure _mapSupabaseError(String? message, dynamic code) {
    final msg = message?.toLowerCase() ?? '';

    if (msg.contains('permission denied') ||
        msg.contains('violates row-level security') ||
        msg.contains('new row violates row-level security') ||
        code == '42501') {
      return const ServerFailure(
        'Permiso denegado. Verifica las políticas RLS en Supabase.',
      );
    }

    if (msg.contains('bucket not found') || msg.contains('object not found')) {
      return const ServerFailure(
        'Bucket o objeto de Storage no encontrado. Verifica la configuración.',
      );
    }

    if (msg.contains('jwt') || msg.contains('unauthorized')) {
      return const ServerFailure(
        'Sesión no válida. Inicia sesión nuevamente.',
      );
    }

    return ServerFailure('Error de Supabase: ${message ?? 'desconocido'}');
  }
}
