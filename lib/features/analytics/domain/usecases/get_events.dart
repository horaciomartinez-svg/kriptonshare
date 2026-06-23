import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/analytics_event_entity.dart';
import '../repositories/i_analytics_repository.dart';

/// Caso de uso para obtener eventos de analytics por link_id.
class GetEventsUseCase {
  final IAnalyticsRepository _repository;

  GetEventsUseCase(this._repository);

  Future<Either<Failure, List<AnalyticsEventEntity>>> call(String linkId) async {
    return await _repository.getEventsByLinkId(linkId);
  }
}
