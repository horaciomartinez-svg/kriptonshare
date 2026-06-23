import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/core/error/failures.dart';
import 'package:kriptonshare/features/data_room/domain/entities/data_room_entity.dart';
import 'package:kriptonshare/features/data_room/domain/repositories/i_crypto_repository.dart';
import 'package:kriptonshare/features/data_room/domain/repositories/i_data_room_repository.dart';
import 'package:kriptonshare/features/data_room/presentation/notifiers/data_room_notifier.dart';
import 'package:mocktail/mocktail.dart';

class MockDataRoomRepository extends Mock implements IDataRoomRepository {}

class MockCryptoRepository extends Mock implements ICryptoRepository {}

void main() {
  late MockDataRoomRepository mockDataRoomRepository;
  late MockCryptoRepository mockCryptoRepository;
  late DataRoomNotifier notifier;

  setUp(() {
    mockDataRoomRepository = MockDataRoomRepository();
    mockCryptoRepository = MockCryptoRepository();
    notifier = DataRoomNotifier(
      dataRoomRepository: mockDataRoomRepository,
      cryptoRepository: mockCryptoRepository,
    );
  });

  tearDown(() {
    notifier.dispose();
  });

  group('DataRoomNotifier', () {
    final createdRoom = DataRoomEntity(
      id: 'room-123',
      name: 'Due Diligence Q3',
      createdAt: DateTime(2026, 6, 1),
      expiresAt: DateTime(2026, 6, 4),
      isActive: true,
      ownerId: 'user-123',
      maxViews: 5,
    );

    test('should create a data room and update state', () async {
      // Arrange
      when(() => mockDataRoomRepository.createDataRoom(
            name: any(named: 'name'),
            expiresAt: any(named: 'expiresAt'),
            ownerId: any(named: 'ownerId'),
            maxViews: any(named: 'maxViews'),
            watermarkEnabled: any(named: 'watermarkEnabled'),
            downloadEnabled: any(named: 'downloadEnabled'),
            allowedIPs: any(named: 'allowedIPs'),
          )).thenAnswer((_) async => Right(createdRoom));

      // Act
      await notifier.createDataRoom(
        ownerId: 'user-123',
        name: 'Due Diligence Q3',
        expiresAt: DateTime(2026, 6, 4),
        maxViews: 5,
      );

      // Assert
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.rooms.length, 1);
      expect(notifier.state.rooms.first.id, 'room-123');
      expect(notifier.state.rooms.first.name, 'Due Diligence Q3');
    });

    test('should set error when createDataRoom fails', () async {
      // Arrange
      const failure = CacheFailure('Error creating data room');
      when(() => mockDataRoomRepository.createDataRoom(
            name: any(named: 'name'),
            expiresAt: any(named: 'expiresAt'),
            ownerId: any(named: 'ownerId'),
            maxViews: any(named: 'maxViews'),
            watermarkEnabled: any(named: 'watermarkEnabled'),
            downloadEnabled: any(named: 'downloadEnabled'),
            allowedIPs: any(named: 'allowedIPs'),
          )).thenAnswer((_) async => const Left(failure));

      // Act
      await notifier.createDataRoom(
        ownerId: 'user-123',
        name: 'Failed Room',
        expiresAt: DateTime(2026, 6, 4),
      );

      // Assert
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, failure.message);
      expect(notifier.state.rooms, isEmpty);
    });

    test('should load rooms successfully', () async {
      // Arrange
      final rooms = [createdRoom];
      when(() => mockDataRoomRepository.getUserDataRooms('user-123'))
          .thenAnswer((_) async => Right(rooms));

      // Act
      await notifier.loadRooms('user-123');

      // Assert
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.rooms, rooms);
    });

    test('should set error when loadRooms fails', () async {
      // Arrange
      const failure = CacheFailure('Error reading data rooms');
      when(() => mockDataRoomRepository.getUserDataRooms('user-123'))
          .thenAnswer((_) async => const Left(failure));

      // Act
      await notifier.loadRooms('user-123');

      // Assert
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, failure.message);
      expect(notifier.state.rooms, isEmpty);
    });
  });
}
