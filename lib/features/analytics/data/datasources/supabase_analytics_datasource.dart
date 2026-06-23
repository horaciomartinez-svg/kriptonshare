import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics_model.dart';

/// Fuente de datos remota de Supabase para analytics.
class SupabaseAnalyticsDataSource {
  final SupabaseClient _supabase;

  SupabaseAnalyticsDataSource(this._supabase);

  /// Obtener eventos de telemetry_events por link_id.
  Future<List<AnalyticsModel>> getEventsByLinkId(String linkId) async {
    final response = await _supabase
        .from('telemetry_events')
        .select()
        .eq('link_id', linkId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => AnalyticsModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtener métricas agregadas del dashboard para un usuario.
  Future<Map<String, dynamic>> getDashboardMetrics(String ownerId) async {
    final now = DateTime.now().toUtc();
    final last24h = now.subtract(const Duration(hours: 24)).toIso8601String();

    // 1. Links del usuario con metadata de archivos
    final linksResponse = await _supabase
        .from('share_links')
        .select('*, files(original_filename, file_size_bytes, expires_at, status)')
        .eq('created_by', ownerId)
        .order('access_count', ascending: false);

    final links = (linksResponse as List).cast<Map<String, dynamic>>();

    // 2. Eventos de telemetry para los links del usuario en las últimas 24h
    final linkIds = links.map((l) => l['id'] as String).toList();
    int eventsLast24h = 0;
    int totalPageViews = 0;
    int totalDownloads = 0;
    int totalDurationMs = 0;
    final downloadsByLink = <String, int>{};

    if (linkIds.isNotEmpty) {
      final eventsResponse = await _supabase
          .from('telemetry_events')
          .select('event_type, duration_ms, created_at, link_id')
          .inFilter('link_id', linkIds)
          .gte('created_at', last24h);

      final events = (eventsResponse as List).cast<Map<String, dynamic>>();
      eventsLast24h = events.length;

      for (final event in events) {
        final type = event['event_type'] as String;
        final linkId = event['link_id'] as String;
        if (type == 'page_view') {
          totalPageViews++;
          totalDurationMs += (event['duration_ms'] as int? ?? 0);
        } else if (type == 'download_complete') {
          totalDownloads++;
          downloadsByLink[linkId] = (downloadsByLink[linkId] ?? 0) + 1;
        }
      }
    }

    // 3. Calcular métricas
    var totalLinks = 0;
    var activeLinks = 0;
    var expiredLinks = 0;
    var totalViews = 0;
    var storageUsedBytes = 0;
    final topLinks = <Map<String, dynamic>>[];

    for (final link in links) {
      totalLinks++;

      final file = link['files'] as Map<String, dynamic>?;
      final linkExpiresAt = DateTime.parse(link['expires_at'] as String);
      final isActive = (link['is_active'] as bool? ?? true) && linkExpiresAt.isAfter(now);

      if (isActive) {
        activeLinks++;
      } else {
        expiredLinks++;
      }

      totalViews += (link['access_count'] as int? ?? 0);
      storageUsedBytes += (file?['file_size_bytes'] as int? ?? 0);

      final linkId = link['id'] as String;
      topLinks.add({
        'link_id': linkId,
        'file_name': file?['original_filename'] as String?,
        'views': link['access_count'] as int? ?? 0,
        'downloads': downloadsByLink[linkId] ?? 0,
        'last_accessed_at': link['last_accessed_at'],
      });
    }

    final averageViewDurationMs = totalPageViews > 0
        ? totalDurationMs / totalPageViews
        : 0.0;

    return {
      'total_links': totalLinks,
      'active_links': activeLinks,
      'expired_links': expiredLinks,
      'total_views': totalViews,
      'total_downloads': totalDownloads,
      'average_view_duration_ms': averageViewDurationMs,
      'events_last_24h': eventsLast24h,
      'storage_used_bytes': storageUsedBytes,
      'top_links': topLinks.take(5).toList(),
      'generated_at': now.toIso8601String(),
    };
  }
}
