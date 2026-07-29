import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../services/conversion_service.dart';
import '../../../../services/crypto_service.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/office_formats.dart';

import '../../domain/entities/upload_result_entity.dart';
import '../../domain/repositories/i_upload_repository.dart';
import '../datasources/supabase_upload_datasource.dart';

/// Implementación del repositorio de subida con cifrado local y Supabase.
class UploadRepositoryImpl implements IUploadRepository {
  final SupabaseUploadDataSource _dataSource;
  final NetworkInfo _networkInfo;
  final Uuid _uuid;
  final SupabaseClient _supabase;

  UploadRepositoryImpl({
    required SupabaseUploadDataSource dataSource,
    required NetworkInfo networkInfo,
    required SupabaseClient supabase,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _networkInfo = networkInfo,
        _supabase = supabase,
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
      // 2. Cifrar archivo localmente en un Isolate para no bloquear la UI
      //    con archivos grandes (p. ej. video).
      final encrypted = await Isolate.run(() => encryptFileInIsolate({
        'fileBytes': fileBytes,
        'password': password,
      }));

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

      // 6. Conversión Office → PDF (Fase 1). Paridad funcional con FileService.
      // TODO(Fase1): en producción el preview debe subirse a R2 (igual que el original
      // en FileService). Mientras el flujo Clean Architecture use Supabase Storage,
      // se almacena aquí para no romper la inyección de datasource.
      String? viewerStorageKey;
      int? viewerSizeBytes;
      String conversionStatus = 'none';

      if (OfficeFormats.isConvertible(mimeType: mimeType, fileName: fileName)) {
        conversionStatus = 'pending';
        try {
          final accessToken = _supabase.auth.currentSession?.accessToken;
          if (accessToken == null) {
            throw const ConversionException('unauthorized', 'Sin sesión');
          }
          final user = _supabase.auth.currentUser!;
          final isPremium = user.appMetadata['subscription_tier'] == 'premium' ||
              user.appMetadata['subscription_tier'] == 'enterprise';
          final result = await ConversionService().convertOfficeToPdf(
            fileBytes: fileBytes,
            fileName: fileName,
            accessToken: accessToken,
            maxBytes: AppConstants.conversionMaxBytesFor(isPremium: isPremium),
          );
          final encPreview = await Isolate.run(() => encryptFileInIsolate({
            'fileBytes': result.pdfBytes,
            'password': password,
          }));
          viewerStorageKey = _uuid.v4();
          final previewPayload = Uint8List.fromList([
            ...(encPreview['salt'] as Uint8List),
            ...(encPreview['nonce'] as Uint8List),
            ...(encPreview['ciphertext'] as Uint8List),
            ...(encPreview['authTag'] as Uint8List),
          ]);
          await _dataSource.uploadEncryptedFile(
            bucket: AppConstants.bucketName,
            storageKey: viewerStorageKey,
            encryptedBytes: previewPayload,
          );
          viewerSizeBytes = result.pdfBytes.length;
          conversionStatus = 'ready';
        } on ConversionException catch (e) {
          debugPrint('[CONVERSION clean] Falló (${e.code}): ${e.message}. Continúa sin preview.');
          conversionStatus = 'failed';
          viewerStorageKey = null;
        }
      }

      // 7. Registrar metadata en tabla 'files'
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
        'viewer_object_key': viewerStorageKey,
        'viewer_file_size_bytes': viewerSizeBytes,
        'conversion_status': conversionStatus,
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

      // 8. Generar link temporal en tabla 'share_links'
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
