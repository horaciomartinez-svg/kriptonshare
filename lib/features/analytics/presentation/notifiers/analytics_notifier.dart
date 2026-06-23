import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/analytics_event_entity.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../../domain/usecases/get_dashboard_metrics.dart';
import '../../domain/usecases/get_events.dart';

/// Estado de analytics para la capa de presentación.
class AnalyticsState {
  final DashboardMetricsEntity? metrics;
  final List<AnalyticsEventEntity> events;
  final bool isLoading;
  final String? error;
  final String? selectedLinkId;

  const AnalyticsState({
    this.metrics,
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.selectedLinkId,
  });

  AnalyticsState copyWith({
    DashboardMetricsEntity? metrics,
    List<AnalyticsEventEntity>? events,
    bool? isLoading,
    String? error,
    String? selectedLinkId,
  }) {
    return AnalyticsState(
      metrics: metrics ?? this.metrics,
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedLinkId: selectedLinkId ?? this.selectedLinkId,
    );
  }
}

/// Notifier de analytics para el dashboard y auditoría de eventos.
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final GetEventsUseCase _getEvents;
  final GetDashboardMetricsUseCase _getDashboardMetrics;

  AnalyticsNotifier({
    required GetEventsUseCase getEvents,
    required GetDashboardMetricsUseCase getDashboardMetrics,
  })  : _getEvents = getEvents,
        _getDashboardMetrics = getDashboardMetrics,
        super(const AnalyticsState());

  /// Cargar métricas agregadas del dashboard.
  Future<void> loadDashboardMetrics(String ownerId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getDashboardMetrics(ownerId);
    result.fold(
      (failure) => state = state.copyWith(
        error: failure.message,
        isLoading: false,
      ),
      (metrics) => state = state.copyWith(
        metrics: metrics,
        isLoading: false,
      ),
    );
  }

  /// Cargar eventos de analytics para un link específico.
  Future<void> loadEvents(String linkId) async {
    state = state.copyWith(isLoading: true, error: null, selectedLinkId: linkId);

    final result = await _getEvents(linkId);
    result.fold(
      (failure) => state = state.copyWith(
        error: failure.message,
        isLoading: false,
      ),
      (events) => state = state.copyWith(
        events: events,
        isLoading: false,
      ),
    );
  }

  /// Seleccionar un link sin cargar eventos.
  void selectLink(String linkId) {
    state = state.copyWith(selectedLinkId: linkId);
  }

  /// Limpiar errores.
  void clearError() {
    state = state.copyWith(error: null);
  }
}
