import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/batch_upload_to_folder_usecase.dart';
import '../../data_room_providers.dart';

export '../../domain/usecases/batch_upload_to_folder_usecase.dart' show BatchUploadItem;

class UploadBatchState {
  final List<BatchUploadItem> queue;
  final bool isProcessing;
  final int completedCount;

  const UploadBatchState({
    this.queue = const [],
    this.isProcessing = false,
    this.completedCount = 0,
  });
}

final uploadBatchProvider =
    StateNotifierProvider<UploadBatchNotifier, UploadBatchState>((ref) {
  return UploadBatchNotifier(ref.watch(batchUploadToFolderUseCaseProvider));
});

class UploadBatchNotifier extends StateNotifier<UploadBatchState> {
  final BatchUploadToFolderUseCase _batchUseCase;

  UploadBatchNotifier(this._batchUseCase) : super(const UploadBatchState());

  /// Encola N archivos y los procesa DE UNO EN UNO.
  Future<void> enqueueAndProcess({
    required String ownerId,
    required String folderId,
    required List<BatchUploadItem> items,
    required String userPassword,
  }) async {
    final valid = items.where((i) => !i.exceedsLimit).toList();
    state = UploadBatchState(queue: valid, isProcessing: true);

    int completed = 0;
    for (final item in valid) {
      await _batchUseCase.execute(
        ownerId: ownerId,
        folderId: folderId,
        item: item,
        userPassword: userPassword,
        onProgress: (p) => _updateItemProgress(item.filename, p),
      );
      completed++;
    }

    state = UploadBatchState(
      queue: state.queue,
      isProcessing: false,
      completedCount: completed,
    );
  }

  void _updateItemProgress(String filename, double progress) {
    state = UploadBatchState(
      queue: [
        for (final i in state.queue)
          i.filename == filename
              ? BatchUploadItem(
                  filename: i.filename,
                  bytes: i.bytes,
                  mimeType: i.mimeType,
                  progress: progress,
                  error: i.error,
                )
              : i,
      ],
      isProcessing: state.isProcessing,
      completedCount: state.completedCount,
    );
  }
}
