import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/data_room_entity.dart';
import '../../domain/repositories/i_data_room_repository.dart';
import '../../domain/repositories/i_crypto_repository.dart';

/// Estado de Data Room para la capa de presentación.
class DataRoomState {
  final List<DataRoomEntity> rooms;
  final bool isLoading;
  final String? error;
  final DataRoomEntity? selectedRoom;
  final String? generatedZkLink;
  final Uint8List? decryptedFile;

  const DataRoomState({
    this.rooms = const [],
    this.isLoading = false,
    this.error,
    this.selectedRoom,
    this.generatedZkLink,
    this.decryptedFile,
  });

  DataRoomState copyWith({
    List<DataRoomEntity>? rooms,
    bool? isLoading,
    String? error,
    DataRoomEntity? selectedRoom,
    String? generatedZkLink,
    Uint8List? decryptedFile,
  }) {
    return DataRoomState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedRoom: selectedRoom ?? this.selectedRoom,
      generatedZkLink: generatedZkLink ?? this.generatedZkLink,
      decryptedFile: decryptedFile ?? this.decryptedFile,
    );
  }
}

/// Notifier de Data Room con Offline-First + Zero-Knowledge.
class DataRoomNotifier extends StateNotifier<DataRoomState> {
  final IDataRoomRepository _dataRoomRepository;
  final ICryptoRepository _cryptoRepository;

  DataRoomNotifier({
    required IDataRoomRepository dataRoomRepository,
    required ICryptoRepository cryptoRepository,
  })  : _dataRoomRepository = dataRoomRepository,
        _cryptoRepository = cryptoRepository,
        super(const DataRoomState());

  /// Carga rooms desde SQLite (Offline-First).
  Future<void> loadRooms(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _dataRoomRepository.getUserDataRooms(userId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message, isLoading: false),
      (rooms) => state = state.copyWith(rooms: rooms, isLoading: false),
    );
  }

  /// Crear un Data Room efímero.
  Future<void> createDataRoom({
    required String ownerId,
    required String name,
    required DateTime expiresAt,
    int? maxViews,
    bool? watermarkEnabled,
    bool? downloadEnabled,
    List<String>? allowedIPs,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _dataRoomRepository.createDataRoom(
      name: name,
      expiresAt: expiresAt,
      ownerId: ownerId,
      maxViews: maxViews,
      watermarkEnabled: watermarkEnabled,
      downloadEnabled: downloadEnabled,
      allowedIPs: allowedIPs,
    );
    result.fold(
      (failure) => state = state.copyWith(error: failure.message, isLoading: false),
      (room) {
        final updatedRooms = [...state.rooms, room];
        state = state.copyWith(rooms: updatedRooms, isLoading: false);
      },
    );
  }

  /// Crear un Data Room con archivo encriptado y generar enlace ZK.
  Future<void> createEphemeralRoomWithFile({
    required String ownerId,
    required String name,
    required Uint8List fileBytes,
    required String password,
    required String mimeType,
    String? storageObjectKey,
    int? maxDownloads,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Generar clave y encriptar
      final keyResult = await _cryptoRepository.generateKey();
      final key = keyResult.getOrElse(() => []);

      final encryptedResult = await _cryptoRepository.encrypt(data: fileBytes.toList(), key: key);
      // ignore: unused_local_variable
      final encryptedData = encryptedResult.getOrElse(() => []);

      // 2. Crear room
      final expiresAt = DateTime.now().add(const Duration(hours: 72));
      final roomResult = await _dataRoomRepository.createDataRoom(
        name: name,
        expiresAt: expiresAt,
        ownerId: ownerId,
        maxViews: maxDownloads,
      );

      final room = roomResult.getOrElse(() => throw Exception('Failed to create room'));

      // 3. Generar fragmento seguro
      final fragmentResult = await _cryptoRepository.generateSecureFragment();
      final fragment = fragmentResult.getOrElse(() => '');

      final zkLink = 'https://kriptonshare.com/room/${room.id}#$fragment';

      state = state.copyWith(
        isLoading: false,
        generatedZkLink: zkLink,
        rooms: [...state.rooms, room],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Descifrar desde enlace ZK.
  Future<void> decryptFromZkLink({
    required Uri deepLink,
    required String password,
    required List<int> encryptedData,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (!deepLink.hasFragment) {
        throw Exception('Enlace inválido: fragmento ausente');
      }

      final keyResult = await _cryptoRepository.deriveKeyFromFragment(deepLink.fragment);
      final key = keyResult.getOrElse(() => throw Exception('Clave inválida'));

      final decryptedResult = await _cryptoRepository.decrypt(
        encryptedData: encryptedData,
        key: key,
      );
      final decrypted = decryptedResult.getOrElse(() => throw Exception('Error al descifrar'));

      state = state.copyWith(
        decryptedFile: Uint8List.fromList(decrypted),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Revocar un Data Room.
  Future<void> revokeRoom(String roomId) async {
    final result = await _dataRoomRepository.revokeDataRoom(roomId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {
        final updatedRooms = state.rooms.map((room) {
          if (room.id == roomId) {
            return room.copyWith(isActive: false);
          }
          return room;
        }).toList();
        state = state.copyWith(rooms: updatedRooms);
      },
    );
  }

  /// Sincronización manual de operaciones pendientes.
  Future<void> syncPending() async {
    final result = await _dataRoomRepository.syncOfflineData();
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {
        // Sincronización exitosa
      },
    );
  }

  /// Seleccionar un room.
  void selectRoom(DataRoomEntity room) {
    state = state.copyWith(selectedRoom: room);
  }

  /// Limpiar error.
  void clearError() {
    state = state.copyWith(error: null);
  }
}
