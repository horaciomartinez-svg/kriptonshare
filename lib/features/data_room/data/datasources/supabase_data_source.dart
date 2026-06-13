import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fuente de datos remota Supabase para Data Rooms.
class SupabaseDataSource {
  final SupabaseClient _supabase;

  SupabaseDataSource(this._supabase);

  // ─── Data Rooms ───

  Future<Map<String, dynamic>> createRoom(Map<String, dynamic> data) async {
    final response = await _supabase.from('data_rooms').insert(data).select().single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getRoomsByOwner(String ownerId) async {
    final response = await _supabase
        .from('data_rooms')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getRoomById(String id) async {
    final response = await _supabase.from('data_rooms').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return response;
  }

  Future<void> updateRoom(String id, Map<String, dynamic> data) async {
    await _supabase.from('data_rooms').update(data).eq('id', id);
  }

  Future<void> deleteRoom(String id) async {
    await _supabase.from('data_rooms').delete().eq('id', id);
  }

  // ─── Files ───

  Future<Map<String, dynamic>> createFile(Map<String, dynamic> data) async {
    final response = await _supabase.from('files').insert(data).select().single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getFilesByRoomId(String roomId) async {
    final response = await _supabase
        .from('files')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }

  // ─── Storage ───

  Future<String> uploadFile(String bucket, String path, Uint8List bytes, {String? contentType}) async {
    await _supabase.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType ?? 'application/octet-stream',
        upsert: false,
      ),
    );
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> deleteFile(String bucket, String path) async {
    await _supabase.storage.from(bucket).remove([path]);
  }

  // ─── Share Links ───

  Future<void> createShareLink(Map<String, dynamic> data) async {
    await _supabase.from('share_links').insert(data);
  }

  Future<void> updateShareLinkStatus(String fileId, bool isActive) async {
    await _supabase.from('share_links').update({'is_active': isActive}).eq('file_id', fileId);
  }
}
