import 'package:supabase_flutter/supabase_flutter.dart';

/// Fuente de datos remota para carpetas virtuales (Data Rooms) en Supabase.
class FolderRemoteDataSource {
  final SupabaseClient _supabase;

  FolderRemoteDataSource(this._supabase);

  Future<Map<String, dynamic>> createFolder(Map<String, dynamic> data) async {
    final response = await _supabase.from('folders').insert(data).select().single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getFoldersByOwner(String ownerId) async {
    final response = await _supabase
        .from('folders')
        .select()
        .eq('owner_id', ownerId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getFolderById(String id) async {
    return await _supabase
        .from('folders')
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> getFilesByFolderId(String folderId) async {
    final response = await _supabase
        .from('files')
        .select()
        .eq('folder_id', folderId)
        .eq('is_deleted', false)
        .eq('status', 'active')
        .order('created_at', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> addFileToFolder(String folderId, String fileId) async {
    await _supabase
        .from('files')
        .update({'folder_id': folderId})
        .eq('id', fileId);
  }

  Future<Map<String, dynamic>> createShareLink(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('share_links')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>?> getShareLinkById(String shareLinkId) async {
    return await _supabase
        .from('share_links')
        .select('*, folders!inner(*)')
        .eq('id', shareLinkId)
        .eq('is_active', true)
        .maybeSingle();
  }

  Future<void> logJourneyEvent(Map<String, dynamic> data) async {
    await _supabase.from('journey_telemetry').insert(data);
  }
}
