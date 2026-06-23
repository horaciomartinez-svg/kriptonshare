import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/kripton_file.dart';
import '../services/crypto_service.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';

final fileServiceProvider = Provider<FileService>((ref) => FileService(ref));

/// Provider para listar los links del usuario autenticado.
/// Se auto-descarta cuando ya no se usa.
final userLinksProvider = FutureProvider.autoDispose<List<ShareLink>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) throw Exception('Usuario no autenticado');

  final fileService = ref.watch(fileServiceProvider);
  return fileService.getUserLinks();
});

/// Provider para listar los archivos recibidos por el usuario autenticado.
final receivedFilesProvider = FutureProvider.autoDispose<List<KriptonFile>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) throw Exception('Usuario no autenticado');

  final fileService = ref.watch(fileServiceProvider);
  return fileService.getReceivedFiles();
});

class FileService {
  final Ref _ref;
  final _uuid = const Uuid();
  
  FileService(this._ref);
  
  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  
  /// Check if user can upload (free tier limits)
  Future<bool> canUpload(int fileSizeBytes) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return false;
    
    if (user.isPremium) return true;
    if (fileSizeBytes > AppConstants.maxFileSizeBytes) return false;
    if (user.monthlyLinksGenerated >= AppConstants.maxLinksPerMonth) return false;
    
    return true;
  }
  
  /// Upload and encrypt a file, then create share link
  Future<ShareLink> uploadAndCreateLink({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    required String userPassword,
    int? maxDownloads,
    String? recipientEmail,
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) throw Exception('Usuario no autenticado');
    
    // Validate limits
    if (!await canUpload(fileBytes.length)) {
      throw Exception('Límite de plan gratuito excedido: máximo 10MB, 50 links/mes');
    }
    
    // 1. Encrypt file locally
    final cryptoService = CryptoService();
    final encrypted = await cryptoService.encryptFile(
      fileBytes: fileBytes,
      password: userPassword,
    );
    
    // 2. Generate storage key
    final storageKey = _uuid.v4();
    
    // 3. Upload to Supabase Storage (encrypted payload)
    final encryptedBytes = Uint8List.fromList([
      ...(encrypted['salt'] as List<int>),
      ...(encrypted['nonce'] as List<int>),
      ...(encrypted['ciphertext'] as List<int>),
      ...(encrypted['authTag'] as List<int>),
    ]);
    
    await _client.storage.from(AppConstants.bucketName).uploadBinary(
      storageKey,
      encryptedBytes,
      fileOptions: const FileOptions(
        contentType: 'application/octet-stream',
        upsert: false,
      ),
    );
    
    // 4. Calculate expiration (max 72h for free)
    final expiresAt = DateTime.now().add(
      const Duration(hours: AppConstants.maxDurationHours),
    );
    
    // 5. Create file record in database
    final fileId = _uuid.v4();
    await _client.from('files').insert({
      'id': fileId,
      'owner_id': user.id,
      'original_filename': fileName,
      'file_size_bytes': fileBytes.length,
      'mime_type': mimeType,
      'storage_provider': AppConstants.storageProvider,
      'bucket_name': AppConstants.bucketName,
      'storage_object_key': storageKey,
      'object_path': storageKey,
      'aes_key_encrypted': encrypted['key'] as List<dynamic>,
      'encryption_salt': base64Encode(encrypted['salt'] as List<int>),
      'salt': encrypted['salt'] as List<dynamic>,
      'nonce': encrypted['nonce'] as List<dynamic>,
      'mac_tag': encrypted['authTag'] as List<dynamic>,
      'is_deleted': false,
      'expires_at': expiresAt.toIso8601String(),
      'max_downloads': maxDownloads ?? AppConstants.maxDownloadsDefault,
      'status': 'active',
    });
    
    // 6. Create share link
    final linkId = _uuid.v4();
    await _client.from('share_links').insert({
      'id': linkId,
      'file_id': fileId,
      'created_by': user.id,
      'expires_at': expiresAt.toIso8601String(),
      'recipient_email': recipientEmail,
      'is_active': true,
    });
    
    // 7. Increment monthly links count
    await _client.from('users').update({
      'monthly_links_generated': user.monthlyLinksGenerated + 1,
    }).eq('id', user.id);
    
    // 8. Refresh user data
    await _ref.read(authStateProvider.notifier).refreshUser();
    
    return ShareLink(
      id: linkId,
      fileId: fileId,
      createdBy: user.id,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
    );
  }
  
  /// Get user's files
  Future<List<KriptonFile>> getUserFiles() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) throw Exception('Usuario no autenticado');
    
    final response = await _client
        .from('files')
        .select()
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => KriptonFile.fromJson(json))
        .toList();
  }
  
  /// Get user's share links
  Future<List<ShareLink>> getUserLinks() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) throw Exception('Usuario no autenticado');
    
    final response = await _client
        .from('share_links')
        .select()
        .eq('created_by', user.id)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => ShareLink.fromJson(json))
        .toList();
  }

  /// Get files received by the authenticated user via secure RPC.
  Future<List<KriptonFile>> getReceivedFiles() async {
    final response = await _client.rpc('get_received_files');

    if (response == null) return [];

    final rows = response as List<dynamic>;
    return rows
        .map((row) => KriptonFile.fromJson(row as Map<String, dynamic>))
        .toList();
  }
  
  /// Get file by share link ID via secure RPC (works for recipients too).
  Future<KriptonFile?> getFileByLinkId(String linkId) async {
    final response = await _client.rpc(
      'get_shared_file_metadata',
      params: {'p_link_id': linkId},
    );

    if (response == null) return null;

    final rows = response as List<dynamic>;
    if (rows.isEmpty) return null;

    return KriptonFile.fromJson(rows.first as Map<String, dynamic>);
  }

  /// Download and decrypt file. Optionally records access metrics for a share link.
  Future<Uint8List> downloadAndDecryptFile(
    KriptonFile file,
    String password, {
    String? linkId,
  }) async {
    // Download encrypted file from storage
    final encryptedBytes = await _client.storage
        .from(file.bucketName)
        .download(file.storageObjectKey);
    
    // Parse encrypted payload
    final salt = encryptedBytes.sublist(0, AppConstants.saltSize);
    final nonce = encryptedBytes.sublist(
      AppConstants.saltSize,
      AppConstants.saltSize + AppConstants.aesNonceSize,
    );
    final ciphertext = encryptedBytes.sublist(
      AppConstants.saltSize + AppConstants.aesNonceSize,
      encryptedBytes.length - AppConstants.aesTagSize,
    );
    final authTag = encryptedBytes.sublist(
      encryptedBytes.length - AppConstants.aesTagSize,
    );
    
    // Derive key from password + salt
    final cryptoService = CryptoService();
    final key = cryptoService.deriveKey(password, salt.toList());

    // Decrypt
    final decrypted = cryptoService.decrypt(
      ciphertext: ciphertext.toList(),
      key: key,
      nonce: nonce.toList(),
      authTag: authTag.toList(),
    );

    // Record successful access
    if (linkId != null) {
      try {
        await _client.rpc('increment_link_access_count', params: {
          'p_link_id': linkId,
        });
      } catch (_) {
        // Non-critical: do not fail decryption if metrics fail
      }
    }
    try {
      await _client.rpc('increment_file_download_count', params: {
        'p_file_id': file.id,
      });
    } catch (_) {
      // Non-critical
    }

    return decrypted;
  }
  
  /// Revoke a link
  Future<void> revokeLink(String linkId) async {
    await _client.from('share_links').update({
      'is_active': false,
    }).eq('id', linkId);
  }
  
  /// Delete a file and its links
  Future<void> deleteFile(String fileId) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    
    // Get file info
    final file = await _client
        .from('files')
        .select()
        .eq('id', fileId)
        .eq('owner_id', user.id)
        .maybeSingle();
    
    if (file == null) return;
    
    // Delete from storage
    try {
      await _client.storage
          .from(AppConstants.bucketName)
          .remove([file['storage_object_key'] as String]);
    } catch (e) {
      // Storage may already be cleaned up
    }
    
    // Delete links
    await _client.from('share_links').delete().eq('file_id', fileId);
    
    // Delete file record
    await _client.from('files').delete().eq('id', fileId);
  }
}
