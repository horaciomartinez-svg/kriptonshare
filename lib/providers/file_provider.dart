// lib/providers/file_provider.dart
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../models/kripton_file.dart';
import '../services/conversion_service.dart';
import '../services/crypto_service.dart';
import '../services/r2_signature_service.dart';
import '../utils/constants.dart';
import '../utils/office_formats.dart';
import 'auth_provider.dart';

final fileServiceProvider = Provider<FileService>((ref) => FileService(ref));

final userLinksProvider = FutureProvider.autoDispose<List<ShareLink>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) throw Exception('Usuario no autenticado');
  return ref.watch(fileServiceProvider).getUserLinks();
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

class FileService {
  final Ref _ref;
  final _uuid = const Uuid();
  final _dio = Dio();
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
  Future<void> _putEncryptedObject(String storageKey, Uint8List encryptedBytes) async {
    final objectPath = _objectPath(storageKey);
    final payloadHash = sha256.convert(encryptedBytes).toString();
    final signedHeaders = _r2Signer.signRequest(
      method: 'PUT',
      path: objectPath,
      payloadHash: payloadHash,
      headers: {'Content-Type': 'application/octet-stream'},
    );
    await _dio.put(
      '${AppConstants.r2Endpoint}$objectPath',
      data: encryptedBytes,
      options: Options(headers: signedHeaders),
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

  Future<bool> canUpload(int fileSizeBytes, String userId) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return false;

    // 1. Validación autoritativa vía RPC (evita evasión desde clientes modificados)
    try {
      final result = await _client.rpc(
        'check_upload_limits',
        params: {'p_user_id': userId, 'p_file_size': fileSizeBytes},
      );
      if (result is List && result.isNotEmpty) {
        final row = result.first as Map<String, dynamic>;
        final allowed = row['can_upload'] as bool;
        final message = row['message'] as String? ?? 'Quota limit exceeded';
        if (!allowed) throw Exception(message);
        return true;
      }
    } catch (e) {
      debugPrint('[canUpload] RPC error, falling back to client-side validation: $e');
    }

    // 2. Fallback cliente si la RPC no está disponible o falla
    if (user.isPremium) {
      if (fileSizeBytes > AppConstants.premiumMaxFileSizeBytes) return false;
      if ((user.totalStorageUsedBytes + fileSizeBytes) > user.maxStoragePremiumBytes) return false;
      return true;
    }

    if (fileSizeBytes > AppConstants.freeMaxFileSizeBytes) return false;
    if (user.monthlyLinksGenerated >= AppConstants.maxLinksPerMonth) return false;

    final activeLinksRes = await _client
        .from('share_links')
        .select('id')
        .eq('created_by', userId)
        .eq('is_active', true)
        .gte('expires_at', DateTime.now().toIso8601String());

    if ((activeLinksRes as List).length >= AppConstants.maxActiveLinks) return false;

    return true;
  }

  Future<ShareLink> uploadAndCreateLink({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    required String userPassword,
    required int selectedDurationHours,
    int? maxDownloads,
    String? recipientEmail,
    void Function(String status)? onConversionStatus,
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) throw Exception('User not authenticated');

    final allowed = await canUpload(fileBytes.length, user.id);
    if (!allowed) {
      throw Exception('Upload cannot be completed. Check your plan limits.');
    }

    // Prueba temporal de conectividad R2
    await testR2Connection();

    // 1. Encriptación local Zero-Knowledge (AES-256-GCM) en Isolate
    //    para no bloquear el hilo de UI con archivos grandes.
    final encrypted = await Isolate.run(() => encryptFileInIsolate({
      'fileBytes': fileBytes,
      'password': userPassword,
    }));

    final salt = (encrypted['salt'] as Uint8List).toList();
    final nonce = (encrypted['nonce'] as Uint8List).toList();
    final ciphertext = (encrypted['ciphertext'] as Uint8List).toList();
    final authTag = (encrypted['authTag'] as Uint8List).toList();
    final key = (encrypted['key'] as Uint8List).toList();

    final storageKey = _uuid.v4();
    final fileId = _uuid.v4();
    final linkId = _uuid.v4();

    final encryptedBytes = Uint8List.fromList([
      ...salt,
      ...nonce,
      ...ciphertext,
      ...authTag,
    ]);

    // 2. SUBIDA DIRECTA A CLOUDFLARE R2 REST ENDPOINT (S3-compatible, firmada SigV4)
    await _putEncryptedObject(storageKey, encryptedBytes);

    // 3. Conversión Office → PDF (Fase 1). Se ejecuta en el emisor antes de
    //    subir el preview cifrado como segundo objeto en R2.
    String? viewerStorageKey;
    int? viewerSizeBytes;
    String conversionStatus = 'none';

    if (OfficeFormats.isConvertible(mimeType: mimeType, fileName: fileName)) {
      conversionStatus = 'pending';
      onConversionStatus?.call(conversionStatus);
      try {
        final accessToken = _client.auth.currentSession?.accessToken;
        if (accessToken == null) {
          throw const ConversionException('unauthorized', 'No active session');
        }
        final result = await ConversionService().convertOfficeToPdf(
          fileBytes: fileBytes,
          fileName: fileName,
          accessToken: accessToken,
          maxBytes: AppConstants.conversionMaxBytesFor(isPremium: user.isPremium),
        );
        // Misma contraseña del usuario → el receptor solo necesita una.
        final encPreview = await Isolate.run(() => encryptFileInIsolate({
          'fileBytes': result.pdfBytes,
          'password': userPassword,
        }));
        viewerStorageKey = _uuid.v4();
        final previewPayload = Uint8List.fromList([
          ...(encPreview['salt'] as Uint8List),
          ...(encPreview['nonce'] as Uint8List),
          ...(encPreview['ciphertext'] as Uint8List),
          ...(encPreview['authTag'] as Uint8List),
        ]);
        await _putEncryptedObject(viewerStorageKey, previewPayload);
        viewerSizeBytes = result.pdfBytes.length;
        conversionStatus = 'ready';
        onConversionStatus?.call(conversionStatus);
      } on ConversionException catch (e) {
        debugPrint('[CONVERSION] Failed (${e.code}): ${e.message}. Continuing without preview.');
        conversionStatus = 'failed';   // fallback: comportamiento actual
        viewerStorageKey = null;
        onConversionStatus?.call(conversionStatus);
      }
    }

    // 4. Temporalidad dinámica inyectada desde el Slider
    final expiresAt = DateTime.now().add(Duration(hours: selectedDurationHours));

    // 5. Inserción de metadatos estructurales (Almacenamiento liviano en Supabase)
    try {
      await _client.from('files').insert({
        'id': fileId,
        'owner_id': user.id,
        'original_filename': fileName,
        'file_size_bytes': fileBytes.length,
        'mime_type': mimeType,
        'storage_provider': 'r2',
        'bucket_name': AppConstants.bucketName,
        'storage_object_key': storageKey,
        'object_path': storageKey,
        'viewer_object_key': viewerStorageKey,
        'viewer_file_size_bytes': viewerSizeBytes,
        'conversion_status': conversionStatus,
        'aes_key_encrypted': key,
        'salt': salt,
        'encryption_salt': salt,
        'nonce': nonce,
        'mac_tag': authTag,
        'is_deleted': false,
        'expires_at': expiresAt.toIso8601String(),
        'max_downloads': maxDownloads ?? AppConstants.maxDownloadsDefault,
        'status': 'active',
      });
    } catch (e) {
      // Best-effort: si falla el insert, intentar limpiar ambos objetos R2.
      debugPrint('[UPLOAD] Metadata insert failed, cleaning up R2 objects: $e');
      await _deleteR2Object(storageKey);
      if (viewerStorageKey != null) await _deleteR2Object(viewerStorageKey);
      rethrow;
    }

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

    return ShareLink(
      id: linkId,
      fileId: fileId,
      createdBy: user.id,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
    );
  }

  Future<List<ShareLink>> getUserLinks() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) throw Exception('User not authenticated');
    final response = await _client.from('share_links').select().eq('created_by', user.id).order('created_at', ascending: false);
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
            'files!inner(id, owner_id, original_filename, file_size_bytes, mime_type, storage_provider, bucket_name, storage_object_key, viewer_object_key, viewer_file_size_bytes, conversion_status, created_at, expires_at, max_downloads, downloads_count, status)',
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

  Future<Uint8List> downloadAndDecryptFile(
    KriptonFile file,
    String password, {
    String? linkId,
    bool useViewerObject = false,
  }) async {
    // DESCARGA FLUIDA DESDE CLOUDFLARE R2 (S3-compatible, firmada SigV4)
    final objectKey = useViewerObject && file.viewerObjectKey != null
        ? file.viewerObjectKey!
        : file.storageObjectKey;
    final objectPath = '/${file.bucketName}/$objectKey';
    final downloadUrl = '${AppConstants.r2Endpoint}$objectPath';
    debugPrint('[R2 DOWNLOAD] URL: $downloadUrl');

    final signedHeaders = _r2Signer.signRequest(
      method: 'GET',
      path: objectPath,
    );

    final response = await _dio.get<List<int>>(
      downloadUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: signedHeaders,
      ),
    );
    debugPrint('[R2 DOWNLOAD] Response size: ${response.data?.length ?? 0} bytes');

    final encryptedBytes = Uint8List.fromList(response.data!);
    final salt = encryptedBytes.sublist(0, AppConstants.saltSize);
    final nonce = encryptedBytes.sublist(AppConstants.saltSize, AppConstants.saltSize + AppConstants.aesNonceSize);
    final ciphertext = encryptedBytes.sublist(AppConstants.saltSize + AppConstants.aesNonceSize, encryptedBytes.length - AppConstants.aesTagSize);
    final authTag = encryptedBytes.sublist(encryptedBytes.length - AppConstants.aesTagSize);

    final cryptoService = CryptoService();
    final key = cryptoService.deriveKey(password, salt.toList());
    final decrypted = cryptoService.decrypt(
      ciphertext: ciphertext.toList(),
      key: key,
      nonce: nonce.toList(),
      authTag: authTag.toList(),
    );

    if (linkId != null) {
      try { await _client.rpc('increment_link_access_count', params: {'p_link_id': linkId}); } catch (_) {}
    }
    try { await _client.rpc('increment_file_download_count', params: {'p_file_id': file.id}); } catch (_) {}

    return decrypted;
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

    // Borrar preview PDF cifrado si existe
    final viewerKey = file['viewer_object_key'] as String?;
    if (viewerKey != null && viewerKey.isNotEmpty) {
      await _deleteR2Object(viewerKey);
    }

    await _client.from('share_links').delete().eq('file_id', fileId);
    await _client.from('files').delete().eq('id', fileId);
  }
}
