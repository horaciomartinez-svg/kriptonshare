import '../../domain/entities/telemetry_event_entity.dart';

/// Interfaz de Repositorio de Telemetría (Capa de Dominio).
/// Define contrato para auditoría e inteligencia de negociación.
abstract class ITelemetryRepository {
  /// Registrar un evento de telemetría (offline-first, sync posterior).
  Future<void> logEvent(TelemetryEventEntity event);

  /// Obtener eventos por link_id (heatmap de interacción).
  Future<List<TelemetryEventEntity>> getEventsByLinkId(String linkId);

  /// Obtener mapa de calor: páginas más escrutadas y tiempo de lectura.
  Future<Map<int, int>> getPageHeatmap(String linkId);

  /// Sincronizar eventos offline pendientes a Supabase.
  Future<void> syncPendingEvents();
}
