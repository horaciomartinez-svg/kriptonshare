import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/telemetry_event_entity.dart';
import '../../domain/repositories/i_telemetry_repository.dart';

/// Estado de Telemetría para la capa de presentación.
class TelemetryState {
  final List<TelemetryEventEntity> events;
  final Map<int, int> pageHeatmap;
  final bool isLoading;
  final String? error;

  const TelemetryState({
    this.events = const [],
    this.pageHeatmap = const {},
    this.isLoading = false,
    this.error,
  });

  TelemetryState copyWith({
    List<TelemetryEventEntity>? events,
    Map<int, int>? pageHeatmap,
    bool? isLoading,
    String? error,
  }) {
    return TelemetryState(
      events: events ?? this.events,
      pageHeatmap: pageHeatmap ?? this.pageHeatmap,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier de Telemetría para auditoría B2B.
class TelemetryNotifier extends StateNotifier<TelemetryState> {
  final ITelemetryRepository _repository;

  TelemetryNotifier(this._repository) : super(const TelemetryState());

  /// Cargar eventos por link_id.
  Future<void> loadEvents(String linkId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final events = await _repository.getEventsByLinkId(linkId);
      final heatmap = await _repository.getPageHeatmap(linkId);
      state = state.copyWith(
        events: events,
        pageHeatmap: heatmap,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Registrar un evento de interacción.
  Future<void> logEvent({
    required String linkId,
    required String eventType,
    int? pageNumber,
    required int durationMs,
    String? ipAddress,
    String? userAgent,
  }) async {
    final event = TelemetryEventEntity(
      linkId: linkId,
      eventType: eventType,
      pageNumber: pageNumber,
      durationMs: durationMs,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
    try {
      await _repository.logEvent(event);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Sincronizar eventos offline pendientes.
  Future<void> syncPending() async {
    try {
      await _repository.syncPendingEvents();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
