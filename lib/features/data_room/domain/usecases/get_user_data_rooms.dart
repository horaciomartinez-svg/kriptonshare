import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/data_room_entity.dart';
import '../repositories/i_data_room_repository.dart';

class GetUserDataRoomsUseCase {
  final IDataRoomRepository _repository;

  GetUserDataRoomsUseCase(this._repository);

  Future<Either<Failure, List<DataRoomEntity>>> call(String userId) async {
    return await _repository.getUserDataRooms(userId);
  }
}
