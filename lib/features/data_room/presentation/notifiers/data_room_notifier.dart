import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/data_room_entity.dart';
import '../../domain/repositories/i_data_room_repository.dart';
import '../../domain/repositories/i_crypto_repository.dart';
import '../../../../core/network/network_info.dart';

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
  final NetworkInfo _networkInfo;

  DataRoomNotifier({
    required IDataRoomRepository dataRoomRepository,
    required ICryptoRepository cryptoRepository,
    required NetworkInfo networkInfo,
  })  : _dataRoomRepository = dataRoomRepository,
        _cryptoRepository = cryptoRepository,
        _networkInfo = networkInfo,
        super(const DataRoomState());

  /// Carga rooms desde SQLite (Offline-First) y suscribe al stream.
  Future<void> loadRooms() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rooms = await _dataRoomRepository.getLocalDataRooms();
      state = state.copyWith(rooms: rooms, isLoading: false);

      // Suscribir a cambios locales
      _dataRoomRepository.watchLocalDataRooms().listen((updatedRooms) {
        state = state.copyWith(rooms: updatedRooms);
      });
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Crear un Data Room efímero: encripta, guarda en SQLite, sincroniza con Supabase.
  Future<void> createEphemeralRoom({
    required String ownerId,
    required String filename,
    required Uint8List fileBytes,
    required String password,
    required String mimeType,
    String? storageObjectKey,
    int? maxDownloads,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Encriptar payload localmente
      final encrypted = await _cryptoRepository.encryptPayload(fileBytes, password);
      final key = encrypted['key'] as List<int>;
      final salt = encrypted['salt'] as List<int>;
      final nonce = encrypted['nonce'] as List<int>;
      final ciphertext = encrypted['ciphertext'] as List<int>;
      final authTag = encrypted['authTag'] as List<int>;

      // 2. Reconstruir payload encriptado para subir
      final encryptedPayload = Uint8List.fromList([
        ...salt,
        ...nonce,
        ...ciphertext,
        ...authTag,
      ]);

      // 3. Crear entidad
      final roomId = DateTime.now().millisecondsSinceEpoch.toString();
      final room = DataRoomEntity(
        id: roomId,
        ownerId: ownerId,
        originalFilename: filename,
        fileSizeBytes: fileBytes.length,
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(hours: 72)),
        storageObjectKey: storageObjectKey,
        mimeType: mimeType,
        maxDownloads: maxDownloads,
      );

      // 4. Persistir Offline-First (SQLite + cola de sync)
      await _dataRoomRepository.createEphemeralRoom(room, encryptedPayload);

      // 5. Generar enlace Zero-Knowledge (clave en fragmento #)
      final zkLink = _cryptoRepository.buildZeroKnowledgeLink(roomId, key);

      state = state.copyWith(
        isLoading: false,
        generatedZkLink: zkLink,
        rooms: [...state.rooms, room],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Extraer clave de enlace ZK y descifrar.
  Future<void> decryptFromZkLink({
    required Uri deepLink,
    required String password,
    required List<int> ciphertext,
    required List<int> nonce,
    required List<int> authTag,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final key = _cryptoRepository.extractKeyFromFragment(deepLink);
      final decrypted = await _cryptoRepository.decryptPayload(
        ciphertext: ciphertext,
        key: key,
        nonce: nonce,
        authTag: authTag,
      );
      state = state.copyWith(decryptedFile: decrypted, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Revocar un Data Room (revocación inmediata local + encolado).
  Future<void> revokeRoom(String roomId) async {
    try {
      await _dataRoomRepository.revokeDataRoom(roomId);
      final updatedRooms = state.rooms.map((room) {
        if (room.id == roomId) {
          return room.copyWith(status: 'revoked');
        }
        return room;
      }).toList();
      state = state.copyWith(rooms: updatedRooms);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Sincronización manual de operaciones pendientes.
  Future<void> syncPending() async {
    try {
      await _dataRoomRepository.syncPendingOperations();
      await loadRooms();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
