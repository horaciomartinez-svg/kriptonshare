// lib/providers/file_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Headers;
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/kripton_file.dart';
import '../models/active_links_summary.dart';
import '../services/secure_decrypt_service.dart';
import '../services/secure_encrypt_service.dart';
import '../services/r2_signature_service.dart';
import '../utils/constants.dart';

import 'auth_provider.dart';
import '../features/analytics/services/funnel_metrics_service.dart';

final fileServiceProvider = Provider<FileService>((ref) => FileService(ref));

final userLinksProvider = FutureProvider.autoDispose<List<ShareLink>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) throw Exception('Usuario no autenticado');
  return ref.watch(fileServiceProvider).getUserLinks();
});

/// Suma de bytes de los archivos con link activo y no expirado.
/// Derivado de [userLinksProvider] para que Dashboard y Analytics lean la
/// misma fuente de verdad y se actualicen automáticamente al revocar/borrar.
/// El cálculo vive en [ActiveLinksSummary.sumActiveFileBytes].
final analyticsActiveStorageProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final links = await ref.watch(userLinksProvider.future);
  return ActiveLinksSummary.sumActiveFileBytes(links);
});

final receivedFilesProvider = FutureProvider.autoDispose<List<KriptonFile>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) throw Exception('Usuario no autenticado');
  return ref.watch(fileServiceProvider).getReceivedFiles();
});

final expiredLinksProvider = FutureProvider.autoDispose<List<ExpiredLinkItem>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) throw Exception('Usuario no autenticado');
  return ref.watch(fileServiceProvider).getExpiredLinksWithMetadata();
});

/// Item resumido de un enlace expirado para la lista de Analytics.
class ExpiredLinkItem {
  final String linkId;
  final String fileName;
  final int fileSizeBytes;
  final DateTime expiredAt;

  const ExpiredLinkItem({
    required this.linkId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.expiredAt,
  });
}

/// Resultado de la validación de cuotas con código de razón.
class UploadLimitResult {
  final bool allowed;
  final String? message;
  /// `file_size`, `monthly_quota`, `active_links`, `storage`, or `null` (success).
  final String? reasonCode;

  const UploadLimitResult({
    required this.allowed,
    this.message,
    this.reasonCode,
  });
}

/// Estado de progreso de subida para la UI: 'encrypting' o 'syncing'.
typedef UploadProgressCallback = void Function(String status);

/// Resultado de la descarga + descifrado en streaming a un archivo temporal.
class DecryptedFileResult {
  final String filePath;
  final int plaintextBytes;
  final int encryptedBytes;
  final int downloadMs;
  final int decryptMs;

  const DecryptedFileResult({
    required this.filePath,
    required this.plaintextBytes,
    required this.encryptedBytes,
    required this.downloadMs,
    required this.decryptMs,
  });

  double get downloadMegabytesPerSecond {
    if (downloadMs <= 0) return 0;
    return (encryptedBytes / (1024 * 1024)) / (downloadMs / 1000);
  }

  double get decryptMegabytesPerSecond {
    if (decryptMs <= 0) return 0;
    return (plaintextBytes / (1024 * 1024)) / (decryptMs / 1000);
  }
}

class FileService {
  final Ref _ref;
  final _uuid = const Uuid();
  final _dio = Dio();
  final _secureDecrypt = SecureDecryptService();
  final _secureEncrypt = SecureEncryptService();
  late final R2SignatureService _r2Signer;

  FileService(this._ref) {
    _r2Signer = const R2SignatureService(
      accessKeyId: AppConstants.r2AccessKeyId,
      secretAccessKey: AppConstants.r2SecretAccessKey,
      endpoint: AppConstants.r2Endpoint,
    );
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 5);
    _dio.options.sendTimeout = const Duration(minutes: 5);
  }

  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  String _objectPath(String storageKey) => '/${AppConstants.bucketName}/$storageKey';

  /// Sube un objeto cifrado a Cloudflare R2 con firma SigV4.
  ///
  /// El cuerpo se envía como stream (`File.openRead()`) para que un archivo
  /// grande nunca tenga que caber completo en memoria.
  Future<void> _putEncryptedObject({
    required String storageKey,
    required String encryptedPath,
    required String payloadHash,
    required int contentLength,
  }) async {
    final objectPath = _objectPath(storageKey);
    final signedHeaders = _r2Signer.signRequest(
      method: 'PUT',
      path: objectPath,
      payloadHash: payloadHash,
      headers: {'Content-Type': 'application/octet-stream'},
    );
    final headers = <String, dynamic>{
      ...signedHeaders,
      Headers.contentLengthHeader: '$contentLength',
    };
    await _dio.put(
      '${AppConstants.r2Endpoint}$objectPath',
      data: File(encryptedPath).openRead(),
      options: Options(headers: headers),
    );
  }

  /// Elimina un objeto de Cloudflare R2 (best-effort, no falla).
  Future<void> _deleteR2Object(String storageKey) async {
    try {
      final objectPath = _objectPath(storageKey);
      final signedHeaders = _r2Signer.signRequest(
        method: 'DELETE',
        path: objectPath,
      );
      await _dio.delete(
        '${AppConstants.r2Endpoint}$objectPath',
        options: Options(headers: signedHeaders),
      );
    } catch (e) {
      debugPrint('[R2 DELETE] Error eliminando $storageKey: $e');
    }
  }

  /// Prueba temporal de conectividad contra R2. Devuelve el status code o relanza el error.
  Future<int> testR2Connection() async {
    final testPath = '/${AppConstants.bucketName}/test-connection-${DateTime.now().millisecondsSinceEpoch}';
    final testUrl = '${AppConstants.r2Endpoint}$testPath';
    debugPrint('[R2 DIAGNOSTIC] Test URL: $testUrl');
    debugPrint('[R2 DIAGNOSTIC] Endpoint constant: ${AppConstants.r2Endpoint}');
    debugPrint('[R2 DIAGNOSTIC] Bucket: ${AppConstants.bucketName}');

    final signedHeaders = _r2Signer.signRequest(
      method: 'PUT',
      path: testPath,
      payloadHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      headers: {'Content-Type': 'application/octet-stream'},
    );
    debugPrint('[R2 DIAGNOSTIC] Signed headers: ${signedHeaders.keys.toList()}');

    final response = await _dio.put(
      testUrl,
      data: Uint8List(0),
      options: Options(headers: signedHeaders),
    );
    debugPrint('[R2 DIAGNOSTIC] Test response status: ${response.statusCode}');
    return response.statusCode ?? 0;
  }

  Future<UploadLimitResult> canUpload(int fileSizeBytes, String userId) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return const UploadLimitResult(allowed: false);

    // 1. Validación autoritativa vía RPC (evita evasión desde clientes modificados)
    try {
      final result = await _client.rpc(
        'check_upload_limits',
        params: {'p_user_id': userId, 'p_file_size': fileSizeBytes},
      );
      if (result is List && result.isNotEmpty) {
        final row = result.first as Map<String, dynamic>;
        final allowed = row['can_upload'] as bool;
        final message = row['message'] as String?;
        final reasonCode = row['reason_code'] as String?;
        if (!allowed) {
          return UploadLimitResult(
            allowed: false,
            message: message ?? 'Quota limit exceeded',
            reasonCode: reasonCode,
          );
        }
        return const UploadLimitResult(allowed: true);
      }
    } catch (e) {
      debugPrint('[canUpload] RPC error, falling back to client-side validation: $e');
    }

    // 2. Fallback cliente si la RPC no está disponible o falla (tier-aware)
    if (user.isPremium) {
      if (fileSizeBytes > user.maxFileSizeBytes) {
        return const UploadLimitResult(allowed: false, reasonCode: 'file_size');
      }
      if ((user.totalStorageUsedBytes + fileSizeBytes) > user.maxStorageBytes) {
        return const UploadLimitResult(allowed: false, reasonCode: 'storage');
      }
      return const UploadLimitResult(allowed: true);
    }

    if (fileSizeBytes > AppConstants.freeMaxFileSizeBytes) {
      return const UploadLimitResult(allowed: false, reasonCode: 'file_size');
    }
    if (user.monthlyLinksGenerated >= AppConstants.maxLinksPerMonth) {
      return const UploadLimitResult(allowed: false, reasonCode: 'monthly_quota');
    }

    final activeLinksRes = await _client
        .from('share_links')
        .select('id')
        .eq('created_by', userId)
        .eq('is_active', true)
        .gte('expires_at', DateTime.now().toIso8601String());

    if ((activeLinksRes as List).length >= AppConstants.maxActiveLinks) {
      return const UploadLimitResult(allowed: false, reasonCode: 'active_links');
    }

    return const UploadLimitResult(allowed: true);
  }

  /// Cifra [filePath] en streaming y sube el resultado a R2 sin cargarlo nunca
  /// completo en memoria.
  Future<ShareLink> uploadAndCreateLink({
    required String filePath,
    required int fileSizeBytes,
    required String fileName,
    required String mimeType,
    required String userPassword,
    required int selectedDurationHours,
    int? maxDownloads,
    String? recipientEmail,
    UploadProgressCallback? onProgress,
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) throw Exception('User not authenticated');

    debugPrint(
        '[UPLOAD_START] Iniciando subida de $fileName ($fileSizeBytes bytes)');

    final limitResult = await canUpload(fileSizeBytes, user.id);
    if (!limitResult.allowed) {
      throw Exception(limitResult.message ??
          'Upload cannot be completed. Check your plan limits.');
    }

    final tempDir = await getTemporaryDirectory();
    final encryptedPath = p.join(
      tempDir.path,
      'ks_upload_${DateTime.now().microsecondsSinceEpoch}.enc',
    );

    try {
      // 1. Cifrado local Zero-Knowledge (AES-256-GCM) en Isolate, disco -> disco.
      onProgress?.call('encrypting');
      final encrypted = await _secureEncrypt.encryptPayloadFileToFile(
        plaintextPath: filePath,
        outputPath: encryptedPath,
        password: userPassword,
      );
      debugPrint(
          '[UPLOAD-PERF] encrypt: ${encrypted.plaintextBytes} bytes in ${encrypted.elapsedMs}ms '
          '(${encrypted.megabytesPerSecond.toStringAsFixed(1)} MB/s)');

      final storageKey = _uuid.v4();
      final fileId = _uuid.v4();
      final linkId = _uuid.v4();

      // 2. SUBIDA DIRECTA A CLOUDFLARE R2 REST ENDPOINT (stream + SigV4).
      onProgress?.call('syncing');
      final uploadStopwatch = Stopwatch()..start();
      await _putEncryptedObject(
        storageKey: storageKey,
        encryptedPath: encryptedPath,
        payloadHash: encrypted.payloadHash,
        contentLength: encrypted.encryptedBytes,
      );
      uploadStopwatch.stop();
      debugPrint(
          '[UPLOAD-PERF] upload: ${encrypted.encryptedBytes} bytes in ${uploadStopwatch.elapsedMilliseconds}ms');

      // 3. Temporalidad dinámica inyectada desde el Slider
      final expiresAt =
          DateTime.now().add(Duration(hours: selectedDurationHours));

      // 4. Inserción de metadatos estructurales (Almacenamiento liviano en Supabase)
      try {
        await _client.from('files').insert({
          'id': fileId,
          'owner_id': user.id,
          'original_filename': fileName,
          'file_size_bytes': fileSizeBytes,
          'mime_type': mimeType,
          'storage_provider': 'r2',
          'bucket_name': AppConstants.bucketName,
          'storage_object_key': storageKey,
          'object_path': storageKey,
          'aes_key_encrypted': encrypted.key,
          'salt': encrypted.salt,
          'encryption_salt': encrypted.salt,
          'nonce': encrypted.nonce,
          'mac_tag': encrypted.authTag,
          'is_deleted': false,
          'expires_at': expiresAt.toIso8601String(),
          'max_downloads': maxDownloads ?? AppConstants.maxDownloadsDefault,
          'status': 'active',
        });
      } catch (e) {
        // Best-effort: si falla el insert, intentar limpiar el objeto R2.
        debugPrint('[UPLOAD] Metadata insert failed, cleaning up R2 object: $e');
        await _deleteR2Object(storageKey);
        rethrow;
      }

      final firstLinkEver = user.monthlyLinksGenerated == 0;
      await _client.from('share_links').insert({
        'id': linkId,
        'file_id': fileId,
        'created_by': user.id,
        'expires_at': expiresAt.toIso8601String(),
        'recipient_email': recipientEmail,
        'is_active': true,
      });

      await _client.from('users').update({
        'monthly_links_generated': user.monthlyLinksGenerated + 1,
      }).eq('id', user.id);

      await _ref.read(authStateProvider.notifier).refreshUser();

      if (firstLinkEver) {
        await FunnelMetricsService().logEvent('first_link_created');
      }

      return ShareLink(
        id: linkId,
        fileId: fileId,
        createdBy: user.id,
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
      );
    } finally {
      // El ciphertext temporal nunca debe quedar en disco.
      try {
        final encFile = File(encryptedPath);
        if (await encFile.exists()) await encFile.delete();
      } catch (_) {}
    }
  }

  Future<List<ShareLink>> getUserLinks() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) throw Exception('User not authenticated');
    // El embed `files(file_size_bytes)` trae el tamaño del archivo en la misma
    // consulta que alimenta la lista de Active Links (sin queries extra).
    final response = await _client
        .from('share_links')
        .select('*, files(file_size_bytes)')
        .eq('created_by', user.id)
        .order('created_at', ascending: false);
    return (response as List).map((json) => ShareLink.fromJson(json)).toList();
  }

  /// Obtiene los enlaces expirados o revocados del usuario con metadata
  /// básica del archivo (nombre, tamaño y fecha de expiración).
  Future<List<ExpiredLinkItem>> getExpiredLinksWithMetadata() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) throw Exception('User not authenticated');

    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from('share_links')
        .select(
          'id, expires_at, is_active, created_at, '
          'files(original_filename, file_size_bytes)',
        )
        .eq('created_by', user.id)
        .or('expires_at.lt.$now, is_active.eq.false')
        .order('expires_at', ascending: false);

    return (response as List).map((row) {
      final file = row['files'] as Map<String, dynamic>?;
      return ExpiredLinkItem(
        linkId: row['id'] as String,
        fileName: (file?['original_filename'] as String?)?.isNotEmpty == true
            ? file!['original_filename'] as String
            : 'Unnamed document',
        fileSizeBytes: file?['file_size_bytes'] as int? ?? 0,
        expiredAt: DateTime.parse(row['expires_at'] as String),
      );
    }).toList();
  }

  Future<List<KriptonFile>> getReceivedFiles() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) throw Exception('User not authenticated');
    debugPrint('[getReceivedFiles] Current user email: ${user.email}');

    // 1. Intentar la RPC preferida (SECURITY DEFINER, case-insensitive)
    try {
      final response = await _client.rpc('get_received_files');
      debugPrint('[getReceivedFiles] RPC response: ${response ?? "null"}');
      if (response != null) {
        final list = (response as List<dynamic>)
            .map((row) => KriptonFile.fromJson(row as Map<String, dynamic>))
            .toList();
        debugPrint('[getReceivedFiles] RPC returned ${list.length} files');
        if (list.isNotEmpty) return list;
      }
    } catch (e, st) {
      debugPrint('[getReceivedFiles] RPC failed: $e\n$st');
    }

    // 2. Fallback directo a tablas (requiere políticas RLS de receptor)
    debugPrint('[getReceivedFiles] Falling back to direct table query');
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('share_links')
          .select(
            'id, '
            'expires_at, '
            'recipient_email, '
            'is_active, '
            'files!inner(id, owner_id, original_filename, file_size_bytes, mime_type, storage_provider, bucket_name, storage_object_key, created_at, expires_at, max_downloads, downloads_count, status)',
          )
          .filter('recipient_email', 'ilike', user.email)
          .eq('is_active', true)
          .gte('expires_at', now)
          .filter('files.status', 'eq', 'active')
          .filter('files.expires_at', 'gte', now)
          .order('created_at', ascending: false);

      debugPrint('[getReceivedFiles] Fallback response: ${(response as List).length} rows');
      return (response as List).cast<Map<String, dynamic>>().map((link) {
        final filesValue = link['files'];
        final Map<String, dynamic> file;
        if (filesValue is List && filesValue.isNotEmpty) {
          file = filesValue.first as Map<String, dynamic>;
        } else if (filesValue is Map<String, dynamic>) {
          file = filesValue;
        } else {
          file = {};
        }
        return KriptonFile.fromJson({
          ...file,
          'link_id': link['id'],
          'link_expires_at': link['expires_at'],
          'recipient_email': link['recipient_email'],
          'is_active': link['is_active'],
        });
      }).toList();
    } catch (e, st) {
      debugPrint('[getReceivedFiles] Fallback failed: $e\n$st');
    }

    return [];
  }

  Future<KriptonFile?> getFileByLinkId(String linkId) async {
    final response = await _client.rpc('get_shared_file_metadata', params: {'p_link_id': linkId});
    if (response == null || (response as List).isEmpty) return null;
    return KriptonFile.fromJson(response.first as Map<String, dynamic>);
  }

  /// Descarga el objeto cifrado desde R2 **en streaming a un archivo temporal**
  /// (nunca completo en memoria) y lo descifra en un isolate por chunks hacia
  /// un segundo archivo temporal con la extensión original.
  ///
  /// Es el pipeline que usa el visor para **todos** los formatos. Las imágenes
  /// y el texto leen el archivo resultante y lo borran; el video y el PDF
  /// conservan el archivo para reproducción/vista previa nativas.
  Future<DecryptedFileResult> downloadAndDecryptToFile(
    KriptonFile file,
    String password, {
    String? linkId,
    void Function(SecureTransferProgress progress)? onProgress,
  }) async {
    final objectPath = '/${file.bucketName}/${file.storageObjectKey}';
    final downloadUrl = '${AppConstants.r2Endpoint}$objectPath';
    debugPrint('[R2 DOWNLOAD] URL: $downloadUrl');

    final signedHeaders = _r2Signer.signRequest(method: 'GET', path: objectPath);

    final tempDir = await getTemporaryDirectory();
    final extension = p.extension(file.originalFilename);
    final baseName = 'ks_${DateTime.now().microsecondsSinceEpoch}';
    final encryptedPath = p.join(tempDir.path, '$baseName.enc');
    final outputPath = p.join(tempDir.path, '$baseName$extension');
    final encryptedFile = File(encryptedPath);

    // Tamaño cifrado = plaintext + salt + nonce + authTag.
    final expectedEncryptedBytes = file.fileSizeBytes +
        AppConstants.saltSize +
        AppConstants.aesNonceSize +
        AppConstants.aesTagSize;

    final downloadStopwatch = Stopwatch()..start();
    IOSink? sink;
    try {
      final response = await _dio.get<ResponseBody>(
        downloadUrl,
        options: Options(
          responseType: ResponseType.stream,
          headers: signedHeaders,
        ),
      );
      final body = response.data;
      if (body == null) {
        throw Exception('Empty response body from R2');
      }

      sink = encryptedFile.openWrite();
      var received = 0;
      await for (final chunk in body.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(SecureTransferProgress(
          phase: SecureTransferPhase.downloading,
          processedBytes: received,
          totalBytes: expectedEncryptedBytes,
        ));
      }
      await sink.flush();
      await sink.close();
      sink = null;
      downloadStopwatch.stop();

      final downloadMs = downloadStopwatch.elapsedMilliseconds;
      debugPrint('[VIEWER-PERF] download: $received bytes in ${downloadMs}ms '
          '(${_megabytesPerSecond(received, downloadMs)} MB/s)');

      final decryptResult = await _secureDecrypt.decryptPayloadFileToFile(
        encryptedPath: encryptedPath,
        outputPath: outputPath,
        password: password,
        onProgress: (processed, total) => onProgress?.call(SecureTransferProgress(
          phase: SecureTransferPhase.decrypting,
          processedBytes: processed,
          totalBytes: total,
        )),
      );
      debugPrint('[VIEWER-PERF] decrypt: ${decryptResult.plaintextBytes} bytes in '
          '${decryptResult.elapsedMs}ms '
          '(${decryptResult.megabytesPerSecond.toStringAsFixed(1)} MB/s) '
          'isolate=ks-decrypt');

      if (linkId != null) {
        try {
          await _client.rpc('increment_link_access_count', params: {'p_link_id': linkId});
        } catch (_) {}
      }
      try {
        await _client.rpc('increment_file_download_count', params: {'p_file_id': file.id});
      } catch (_) {}

      return DecryptedFileResult(
        filePath: outputPath,
        plaintextBytes: decryptResult.plaintextBytes,
        encryptedBytes: received,
        downloadMs: downloadMs,
        decryptMs: decryptResult.elapsedMs,
      );
    } finally {
      // El ciphertext temporal nunca debe quedar en disco.
      await _safeCloseSink(sink);
      try {
        if (await encryptedFile.exists()) await encryptedFile.delete();
      } catch (_) {}
    }
  }

  static String _megabytesPerSecond(int bytes, int ms) {
    if (ms <= 0) return '0';
    return ((bytes / (1024 * 1024)) / (ms / 1000)).toStringAsFixed(1);
  }

  Future<void> revokeLink(String linkId) async {
    await _client.from('share_links').update({'is_active': false}).eq('id', linkId);
  }

  Future<void> deleteFile(String fileId) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final file = await _client.from('files').select().eq('id', fileId).eq('owner_id', user.id).maybeSingle();
    if (file == null) return;

    // Borrar objeto principal (original cifrado)
    await _deleteR2Object(file['storage_object_key'] as String);

    await _client.from('share_links').delete().eq('file_id', fileId);
    await _client.from('files').delete().eq('id', fileId);
  }
}

Future<void> _safeCloseSink(IOSink? sink) async {
  try {
    await sink?.close();
  } catch (_) {}
}
