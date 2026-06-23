import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_metrics_entity.dart';
import '../repositories/i_analytics_repository.dart';

/// Caso de uso para obtener métricas agregadas del dashboard.
class GetDashboardMetricsUseCase {
  final IAnalyticsRepository _repository;

  GetDashboardMetricsUseCase(this._repository);

  Future<Either<Failure, DashboardMetricsEntity>> call(String ownerId) async {
    return await _repository.getDashboardMetrics(ownerId);
  }
}
