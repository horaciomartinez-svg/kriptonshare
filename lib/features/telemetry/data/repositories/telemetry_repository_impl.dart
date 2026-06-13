import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/telemetry_event_entity.dart';
import '../../../data_room/data/datasources/local_database_datasource.dart';
import '../../domain/repositories/i_telemetry_repository.dart';

/// Implementación de Telemetría: SQLite offline + Supabase eventual.
class TelemetryRepositoryImpl implements ITelemetryRepository {
  final SupabaseClient _supabase;
  final LocalDatabaseDataSource _localDB;

  TelemetryRepositoryImpl({
    required SupabaseClient supabase,
    required LocalDatabaseDataSource localDB,
  })  : _supabase = supabase,
        _localDB = localDB;

  @override
  Future<void> logEvent(TelemetryEventEntity event) async {
    // 1. Guardar localmente inmediatamente (offline-first)
    await _localDB.insertTelemetry({
      'link_id': event.linkId,
      'event_type': event.eventType,
      'page_number': event.pageNumber,
      'duration_ms': event.durationMs,
      'timestamp_ms': event.timestampMs,
      'sync_status': 'pending',
    });

    // 2. Intentar sync inmediato si hay red
    try {
      await _supabase.from('telemetry_events').insert({
        'link_id': event.linkId,
        'event_type': event.eventType,
        'page_number': event.pageNumber,
        'duration_ms': event.durationMs,
        'timestamp_ms': event.timestampMs,
        'ip_address': event.ipAddress,
        'user_agent': event.userAgent,
        'geolocation': event.geolocation,
      });
      // Marcar como sync si tuviéramos tracking de IDs (simplificado)
    } catch (e) {
      // Queda en cola para sync futuro
    }
  }

  @override
  Future<List<TelemetryEventEntity>> getEventsByLinkId(String linkId) async {
    try {
      final response = await _supabase
          .from('telemetry_events')
          .select()
          .eq('link_id', linkId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => TelemetryEventEntity.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback: leer desde local
      final local = await _localDB.getPendingTelemetry();
      return local
          .map((json) => TelemetryEventEntity.fromJson(json))
          .toList();
    }
  }

  @override
  Future<Map<int, int>> getPageHeatmap(String linkId) async {
    final events = await getEventsByLinkId(linkId);
    final heatmap = <int, int>{};

    for (final event in events) {
      if (event.eventType == 'page_view' && event.pageNumber != null) {
        heatmap[event.pageNumber!] = (heatmap[event.pageNumber!] ?? 0) + event.durationMs;
      }
    }

    return heatmap;
  }

  @override
  Future<void> syncPendingEvents() async {
    final pending = await _localDB.getPendingTelemetry();
    for (final row in pending) {
      try {
        await _supabase.from('telemetry_events').insert({
          'link_id': row['link_id'],
          'event_type': row['event_type'],
          'page_number': row['page_number'],
          'duration_ms': row['duration_ms'],
          'timestamp_ms': row['timestamp_ms'],
        });
        await _localDB.markTelemetrySynced(row['id'] as int);
      } catch (e) {
        // Mantener en cola para reintento
      }
    }
  }
}
