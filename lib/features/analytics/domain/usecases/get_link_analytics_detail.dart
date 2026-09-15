import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/link_analytics_detail_entity.dart';
import '../repositories/i_analytics_repository.dart';

/// Caso de uso para obtener el detalle analítico de un link.
class GetLinkAnalyticsDetailUseCase {
  final IAnalyticsRepository _repository;

  GetLinkAnalyticsDetailUseCase(this._repository);

  Future<Either<Failure, LinkAnalyticsDetailEntity>> call(String linkId) async {
    return await _repository.getLinkAnalyticsDetail(linkId);
  }
}