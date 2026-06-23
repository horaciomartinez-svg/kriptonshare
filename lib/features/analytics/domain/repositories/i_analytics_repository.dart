import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/analytics_event_entity.dart';
import '../entities/dashboard_metrics_entity.dart';

/// Contrato de repositorio para analytics y auditoría B2B.
abstract class IAnalyticsRepository {
  /// Obtener eventos de analytics para un link específico.
  Future<Either<Failure, List<AnalyticsEventEntity>>> getEventsByLinkId(
    String linkId,
  );

  /// Obtener métricas agregadas del dashboard para un usuario.
  Future<Either<Failure, DashboardMetricsEntity>> getDashboardMetrics(
    String ownerId,
  );
}
