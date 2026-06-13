import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/data_room_entity.dart';
import '../repositories/i_data_room_repository.dart';

class CreateDataRoomUseCase {
  final IDataRoomRepository _repository;

  CreateDataRoomUseCase(this._repository);

  Future<Either<Failure, DataRoomEntity>> call({
    required String name,
    required DateTime expiresAt,
    required String ownerId,
    int? maxViews,
    bool? watermarkEnabled,
    bool? downloadEnabled,
    List<String>? allowedIPs,
  }) async {
    return await _repository.createDataRoom(
      name: name,
      expiresAt: expiresAt,
      ownerId: ownerId,
      maxViews: maxViews,
      watermarkEnabled: watermarkEnabled,
      downloadEnabled: downloadEnabled,
      allowedIPs: allowedIPs,
    );
  }
}
