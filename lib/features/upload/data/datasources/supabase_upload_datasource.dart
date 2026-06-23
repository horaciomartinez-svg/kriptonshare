import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fuente de datos remota de Supabase para subida de archivos cifrados.
class SupabaseUploadDataSource {
  final SupabaseClient _supabase;

  SupabaseUploadDataSource(this._supabase);

  /// Subir bytes cifrados a Supabase Storage.
  Future<void> uploadEncryptedFile({
    required String bucket,
    required String storageKey,
    required Uint8List encryptedBytes,
  }) async {
    await _supabase.storage.from(bucket).uploadBinary(
      storageKey,
      encryptedBytes,
      fileOptions: const FileOptions(
        contentType: 'application/octet-stream',
        upsert: false,
      ),
    );
  }

  /// Crear registro de archivo en tabla 'files'.
  Future<void> createFileRecord(Map<String, dynamic> data) async {
    await _supabase.from('files').insert(data);
  }

  /// Crear registro de link compartido en tabla 'share_links'.
  Future<void> createShareLinkRecord(Map<String, dynamic> data) async {
    await _supabase.from('share_links').insert(data);
  }

  /// Incrementar contador de links mensuales del usuario.
  Future<void> incrementMonthlyLinksCount({
    required String userId,
    required int currentCount,
  }) async {
    await _supabase.from('users').update({
      'monthly_links_generated': currentCount + 1,
    }).eq('id', userId);
  }
}
