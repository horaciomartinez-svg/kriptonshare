import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/link_model.dart';

/// Fuente de datos remota de Supabase para gestión de links.
class SupabaseLinksDataSource {
  final SupabaseClient _supabase;

  SupabaseLinksDataSource(this._supabase);

  /// Obtener los links de un usuario con paginación.
  Future<List<LinkModel>> getUserLinks(
    String ownerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('share_links')
        .select()
        .eq('created_by', ownerId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => LinkModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Revocar un link marcándolo como inactivo.
  Future<void> revokeLink(String linkId) async {
    await _supabase.from('share_links').update({
      'is_active': false,
    }).eq('id', linkId);
  }

  /// Eliminar un archivo, sus links y su objeto de storage.
  Future<void> deleteFile(String fileId, String ownerId) async {
    // 1. Obtener información del archivo verificando ownership
    final file = await _supabase
        .from('files')
        .select()
        .eq('id', fileId)
        .eq('owner_id', ownerId)
        .maybeSingle();

    if (file == null) {
      throw Exception('Archivo no encontrado o sin permisos');
    }

    // 2. Eliminar del storage si existe el objeto
    try {
      final bucketName = file['bucket_name'] as String?;
      final storageKey = file['storage_object_key'] as String?;
      if (bucketName != null && storageKey != null) {
        await _supabase.storage.from(bucketName).remove([storageKey]);
      }
    } catch (e) {
      // El objeto puede ya estar limpiado o no existir
    }

    // 3. Eliminar links asociados
    await _supabase.from('share_links').delete().eq('file_id', fileId);

    // 4. Eliminar registro del archivo
    await _supabase.from('files').delete().eq('id', fileId);
  }
}
