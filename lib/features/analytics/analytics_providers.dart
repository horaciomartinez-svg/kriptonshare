import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/supabase_analytics_datasource.dart';
import 'data/repositories/analytics_repository_impl.dart';
import 'domain/repositories/i_analytics_repository.dart';
import 'domain/usecases/get_dashboard_metrics.dart';
import 'domain/usecases/get_events.dart';
import 'presentation/notifiers/analytics_notifier.dart';

/// Fuente de datos remota de Supabase para analytics.
final analyticsDataSourceProvider = Provider<SupabaseAnalyticsDataSource>((ref) {
  return SupabaseAnalyticsDataSource(Supabase.instance.client);
});

/// Repositorio de analytics.
final analyticsRepositoryProvider = Provider<IAnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(ref.watch(analyticsDataSourceProvider));
});

/// Caso de uso para obtener eventos de analytics.
final getEventsUseCaseProvider = Provider<GetEventsUseCase>((ref) {
  return GetEventsUseCase(ref.watch(analyticsRepositoryProvider));
});

/// Caso de uso para obtener métricas del dashboard.
final getDashboardMetricsUseCaseProvider = Provider<GetDashboardMetricsUseCase>((ref) {
  return GetDashboardMetricsUseCase(ref.watch(analyticsRepositoryProvider));
});

/// Notifier de estado para analytics.
final analyticsNotifierProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(
    getEvents: ref.watch(getEventsUseCaseProvider),
    getDashboardMetrics: ref.watch(getDashboardMetricsUseCaseProvider),
  );
});
