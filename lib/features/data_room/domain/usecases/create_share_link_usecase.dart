import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/share_link_entity.dart';
import '../repositories/i_data_room_repository.dart';

class CreateShareLinkUseCase {
  final IDataRoomRepository _repository;

  CreateShareLinkUseCase(this._repository);

  Future<Either<Failure, ShareLinkEntity>> call({
    required String createdBy,
    String? fileId,
    String? folderId,
    required ShareLinkType linkType,
    required bool requireRecipientEmail,
    required bool enableWatermark,
    required DateTime expiresAt,
  }) async {
    return _repository.createShareLink(
      createdBy: createdBy,
      fileId: fileId,
      folderId: folderId,
      linkType: linkType,
      requireRecipientEmail: requireRecipientEmail,
      enableWatermark: enableWatermark,
      expiresAt: expiresAt,
    );
  }
}
