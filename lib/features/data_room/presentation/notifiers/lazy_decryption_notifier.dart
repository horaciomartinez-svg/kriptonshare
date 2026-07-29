import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/usecases/lazy_decrypt_file_usecase.dart';
import '../../data_room_providers.dart';

/// Provider del archivo activo en RAM. autoDispose => liberación al salir del visor.
final lazyDecryptionProvider =
    StateNotifierProvider.autoDispose<LazyDecryptionNotifier, AsyncValue<Uint8List?>>((ref) {
  final useCase = ref.watch(lazyDecryptFileUseCaseProvider);
  return LazyDecryptionNotifier(useCase);
});

class LazyDecryptionNotifier extends StateNotifier<AsyncValue<Uint8List?>> {
  final LazyDecryptFileUseCase _lazyDecryptUseCase;

  LazyDecryptionNotifier(this._lazyDecryptUseCase)
      : super(const AsyncValue.data(null));

  /// Descarga y descifra ÚNICAMENTE el archivo seleccionado por el usuario.
  Future<void> decryptSingleFile({
    required FileEntity file,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    final result = await _lazyDecryptUseCase.execute(
      file: file,
      userPassword: password,
    );

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (decryptedBytes) => state = AsyncValue.data(decryptedBytes),
    );
  }

  /// PURGA EXPLÍCITA DE RAM: evapora el buffer Uint8List.
  void purgeRAM() {
    state = const AsyncValue.data(null);
  }
}
