import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/analytics_event_entity.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../../domain/repositories/i_analytics_repository.dart';
import '../datasources/supabase_analytics_datasource.dart';

/// Implementación del repositorio de analytics con Supabase.
class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  final SupabaseAnalyticsDataSource _dataSource;

  AnalyticsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<AnalyticsEventEntity>>> getEventsByLinkId(
    String linkId,
  ) async {
    try {
      final models = await _dataSource.getEventsByLinkId(linkId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Error fetching analytics events: $e'));
    }
  }

  @override
  Future<Either<Failure, DashboardMetricsEntity>> getDashboardMetrics(
    String ownerId,
  ) async {
    try {
      final data = await _dataSource.getDashboardMetrics(ownerId);

      final topLinks = (data['top_links'] as List)
          .map((json) => LinkMetric.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(
        DashboardMetricsEntity(
          totalLinks: data['total_links'] as int,
          activeLinks: data['active_links'] as int,
          expiredLinks: data['expired_links'] as int,
          totalViews: data['total_views'] as int,
          totalDownloads: data['total_downloads'] as int,
          averageViewDurationMs:
              (data['average_view_duration_ms'] as num).toDouble(),
          eventsLast24h: data['events_last_24h'] as int,
          storageUsedBytes: data['storage_used_bytes'] as int,
          topLinks: topLinks,
          generatedAt: DateTime.parse(data['generated_at'] as String),
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Error fetching dashboard metrics: $e'));
    }
  }
}
