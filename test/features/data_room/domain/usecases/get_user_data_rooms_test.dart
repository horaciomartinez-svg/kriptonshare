import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/core/error/failures.dart';
import 'package:kriptonshare/features/data_room/domain/entities/data_room_entity.dart';
import 'package:kriptonshare/features/data_room/domain/repositories/i_data_room_repository.dart';
import 'package:kriptonshare/features/data_room/domain/usecases/get_user_data_rooms.dart';
import 'package:mocktail/mocktail.dart';

class MockDataRoomRepository extends Mock implements IDataRoomRepository {}

void main() {
  late MockDataRoomRepository mockRepository;
  late GetUserDataRoomsUseCase useCase;

  setUp(() {
    mockRepository = MockDataRoomRepository();
    useCase = GetUserDataRoomsUseCase(mockRepository);
  });

  group('GetUserDataRoomsUseCase', () {
    final rooms = [
      DataRoomEntity(
        id: 'room-1',
        name: 'Due Diligence Q3',
        createdAt: DateTime(2026, 6, 1),
        expiresAt: DateTime(2026, 6, 4),
        isActive: true,
        ownerId: 'user-123',
      ),
      DataRoomEntity(
        id: 'room-2',
        name: 'Contratos Legales',
        createdAt: DateTime(2026, 6, 2),
        expiresAt: DateTime(2026, 6, 5),
        isActive: true,
        ownerId: 'user-123',
      ),
    ];

    test('should return list of data rooms from repository', () async {
      // Arrange
      when(() => mockRepository.getUserDataRooms('user-123'))
          .thenAnswer((_) async => Right(rooms));

      // Act
      final result = await useCase('user-123');

      // Assert
      expect(result.isRight(), true);
      expect(result.getOrElse(() => []), rooms);
      verify(() => mockRepository.getUserDataRooms('user-123')).called(1);
    });

    test('should return empty list when user has no rooms', () async {
      // Arrange
      when(() => mockRepository.getUserDataRooms('user-empty'))
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase('user-empty');

      // Assert
      expect(result.isRight(), true);
      expect(result.getOrElse(() => []), isEmpty);
      verify(() => mockRepository.getUserDataRooms('user-empty')).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = CacheFailure('Error reading data rooms');
      when(() => mockRepository.getUserDataRooms('user-fail'))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase('user-fail');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.message, failure.message),
        (_) => fail('Expected Left, got Right'),
      );
      verify(() => mockRepository.getUserDataRooms('user-fail')).called(1);
    });
  });
}
