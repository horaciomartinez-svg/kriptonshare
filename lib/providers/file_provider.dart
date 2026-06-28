// lib/providers/file_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../models/kripton_file.dart';
import '../services/crypto_service.dart';
import '../services/r2_signature_service.dart';
import '../utils/constants.dart';
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
  }

  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  String _objectPath(String storageKey) => '/${AppConstants.bucketName}/$storageKey';

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
    if (user.isPremium) return true;

    if (fileSizeBytes > AppConstants.maxFileSizeBytes) return false;
    if (user.monthlyLinksGenerated >= AppConstants.maxLinksPerMonth) return false;

    // Evaluar la regla de concurrencia freemium (máximo 3 activos)
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
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) throw Exception('Usuario no autenticado');

    if (!await canUpload(fileBytes.length, user.id)) {
      throw Exception('Límites excedidos: Máx 10MB, 20 links/mes, 3 links activos.');
    }

    // Prueba temporal de conectividad R2
    await testR2Connection();

    // 1. Encriptación local Zero-Knowledge (AES-256-GCM)
    final cryptoService = CryptoService();
    final encrypted = await cryptoService.encryptFile(
      fileBytes: fileBytes,
      password: userPassword,
    );

    final storageKey = _uuid.v4();
    final fileId = _uuid.v4();
    final linkId = _uuid.v4();

    final encryptedBytes = Uint8List.fromList([
      ...(encrypted['salt'] as List<int>),
      ...(encrypted['nonce'] as List<int>),
      ...(encrypted['ciphertext'] as List<int>),
      ...(encrypted['authTag'] as List<int>),
    ]);

    // 2. SUBIDA DIRECTA A CLOUDFLARE R2 REST ENDPOINT (S3-compatible, firmada SigV4)
    final objectPath = _objectPath(storageKey);
    final uploadUrl = '${AppConstants.r2Endpoint}$objectPath';
    final payloadHash = sha256.convert(encryptedBytes).toString();
    debugPrint('[R2 UPLOAD] URL: $uploadUrl');
    debugPrint('[R2 UPLOAD] Payload size: ${encryptedBytes.length} bytes');
    debugPrint('[R2 UPLOAD] Payload hash: $payloadHash');

    final signedHeaders = _r2Signer.signRequest(
      method: 'PUT',
      path: objectPath,
      payloadHash: payloadHash,
      headers: {'Content-Type': 'application/octet-stream'},
    );
    debugPrint('[R2 UPLOAD] Authorization header: ${signedHeaders['Authorization']?.substring(0, signedHeaders['Authorization']!.length > 80 ? 80 : signedHeaders['Authorization']!.length)}...');

    await _dio.put(
      uploadUrl,
      data: encryptedBytes,
      options: Options(headers: signedHeaders),
    );

    // 3. Temporalidad dinámica inyectada desde el Slider
    final expiresAt = DateTime.now().add(Duration(hours: selectedDurationHours));

    // 4. Inserción de metadatos estructurales (Almacenamiento liviano en Supabase)
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
      'aes_key_encrypted': encrypted['key'] as List<dynamic>,
      'salt': encrypted['salt'] as List<dynamic>,
      'encryption_salt': encrypted['salt'] as List<dynamic>,
      'nonce': encrypted['nonce'] as List<dynamic>,
      'mac_tag': encrypted['authTag'] as List<dynamic>,
      'is_deleted': false,
      'expires_at': expiresAt.toIso8601String(),
      'max_downloads': maxDownloads ?? AppConstants.maxDownloadsDefault,
      'status': 'active',
    });

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
    if (user == null) throw Exception('Usuario no autenticado');
    final response = await _client.from('share_links').select().eq('created_by', user.id).order('created_at', ascending: false);
    return (response as List).map((json) => ShareLink.fromJson(json)).toList();
  }

  Future<List<KriptonFile>> getReceivedFiles() async {
    final response = await _client.rpc('get_received_files');
    if (response == null) return [];
    return (response as List<dynamic>).map((row) => KriptonFile.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<KriptonFile?> getFileByLinkId(String linkId) async {
    final response = await _client.rpc('get_shared_file_metadata', params: {'p_link_id': linkId});
    if (response == null || (response as List).isEmpty) return null;
    return KriptonFile.fromJson(response.first as Map<String, dynamic>);
  }

  Future<Uint8List> downloadAndDecryptFile(KriptonFile file, String password, {String? linkId}) async {
    // DESCARGA FLUIDA DESDE CLOUDFLARE R2 (S3-compatible, firmada SigV4)
    final objectPath = '/${file.bucketName}/${file.storageObjectKey}';
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

    try {
      final objectPath = _objectPath(file['storage_object_key'] as String);
      final deleteUrl = '${AppConstants.r2Endpoint}$objectPath';
      debugPrint('[R2 DELETE] URL: $deleteUrl');
      final signedHeaders = _r2Signer.signRequest(
        method: 'DELETE',
        path: objectPath,
      );
      await _dio.delete(deleteUrl, options: Options(headers: signedHeaders));
    } catch (e) {
      debugPrint('[R2 DELETE] Error: $e');
    }

    await _client.from('share_links').delete().eq('file_id', fileId);
    await _client.from('files').delete().eq('id', fileId);
  }
}
