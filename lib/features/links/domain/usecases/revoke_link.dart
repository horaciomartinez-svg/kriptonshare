import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/i_links_repository.dart';

/// Caso de uso para revocar un link compartido.
class RevokeLinkUseCase {
  final ILinksRepository _repository;

  RevokeLinkUseCase(this._repository);

  Future<Either<Failure, void>> call(String linkId) async {
    return await _repository.revokeLink(linkId);
  }
}
