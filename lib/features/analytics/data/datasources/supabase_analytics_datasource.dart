import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/link_analytics_detail_entity.dart';
import '../models/analytics_model.dart';

/// Fuente de datos remota de Supabase para analytics.
class SupabaseAnalyticsDataSource {
  final SupabaseClient _supabase;

  SupabaseAnalyticsDataSource(this._supabase);

  /// Obtener detalle analítico de un link (metadata + tiempo por página).
  Future<LinkAnalyticsDetailEntity> getLinkAnalyticsDetail(String linkId) async {
    // Acceso acotado a links del dueño (RLS) con metadata del archivo.
    final linkResponse = await _supabase
        .from('share_links')
        .select(
          'id, created_at, expires_at, is_active, access_count, '
          'files(original_filename)',
        )
        .eq('id', linkId)
        .maybeSingle();

    if (linkResponse == null) {
      throw StateError('Link not found: $linkId');
    }

    final link = linkResponse;
    final file = link['files'] as Map<String, dynamic>?;

    // Eventos de telemetría del link y agregación por página.
    final eventsResponse = await _supabase
        .from('telemetry_events')
        .select('event_type, page_number, duration_ms')
        .eq('link_id', linkId);

    int totalDurationMs = 0;
    final pages = <int, Map<String, int>>{};
    for (final event in (eventsResponse as List).cast<Map<String, dynamic>>()) {
      if (event['event_type'] != 'page_view') continue;
      final pageNumber = (event['page_number'] as int?) ?? 1;
      final durationMs = event['duration_ms'] as int? ?? 0;
      totalDurationMs += durationMs;

      final page = pages.putIfAbsent(pageNumber, () => {'views': 0, 'duration_ms': 0});
      page['views'] = (page['views']! + 1);
      page['duration_ms'] = (page['duration_ms']! + durationMs);
    }

    final pageEntities = pages.entries
        .map(
          (e) => PageAnalyticsEntity(
            pageNumber: e.key,
            views: e.value['views'] ?? 0,
            durationMs: e.value['duration_ms'] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    return LinkAnalyticsDetailEntity(
      linkId: link['id'] as String,
      fileName: file?['original_filename'] as String?,
      createdAt: DateTime.parse(link['created_at'] as String),
      expiresAt: DateTime.parse(link['expires_at'] as String),
      isActive: link['is_active'] as bool? ?? true,
      views: link['access_count'] as int? ?? 0,
      totalViewDurationMs: totalDurationMs,
      pages: {for (final p in pageEntities) p.pageNumber: p},
    );
  }

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

    // 2b. Duración total de visualización por link (histórico, no solo 24h).
    //     Se usa para el top de links y reemplaza la métrica de descargas.
    final durationByLink = <String, int>{};
    if (linkIds.isNotEmpty) {
      final allEventsResponse = await _supabase
          .from('telemetry_events')
          .select('event_type, duration_ms, link_id')
          .inFilter('link_id', linkIds);

      for (final event in (allEventsResponse as List).cast<Map<String, dynamic>>()) {
        if (event['event_type'] != 'page_view') continue;
        final linkId = event['link_id'] as String;
        durationByLink[linkId] =
            (durationByLink[linkId] ?? 0) + (event['duration_ms'] as int? ?? 0);
      }
    }

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
        'total_view_duration_ms': durationByLink[linkId] ?? 0,
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
