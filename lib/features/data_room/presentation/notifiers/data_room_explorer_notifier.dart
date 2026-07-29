import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/entities/folder_entity.dart';
import '../../domain/usecases/fetch_data_room_contents_usecase.dart';
import '../../data_room_providers.dart';

class DataRoomExplorerState {
  final List<FolderEntity> folders;
  final List<FileEntity> unfiledDocuments;
  final bool isLoading;
  final String? error;

  const DataRoomExplorerState({
    this.folders = const [],
    this.unfiledDocuments = const [],
    this.isLoading = false,
    this.error,
  });

  DataRoomExplorerState copyWith({
    List<FolderEntity>? folders,
    List<FileEntity>? unfiledDocuments,
    bool? isLoading,
    String? error,
  }) {
    return DataRoomExplorerState(
      folders: folders ?? this.folders,
      unfiledDocuments: unfiledDocuments ?? this.unfiledDocuments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final dataRoomExplorerProvider =
    StateNotifierProvider<DataRoomExplorerNotifier, DataRoomExplorerState>((ref) {
  return DataRoomExplorerNotifier(ref.watch(fetchDataRoomContentsUseCaseProvider));
});

class DataRoomExplorerNotifier extends StateNotifier<DataRoomExplorerState> {
  final FetchDataRoomContentsUseCase _fetchUseCase;

  DataRoomExplorerNotifier(this._fetchUseCase) : super(const DataRoomExplorerState());

  Future<void> loadContents(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    final foldersResult = await _fetchUseCase.getFolders(userId);
    final unfiledResult = await _fetchUseCase.getUnfiledDocuments(userId);

    foldersResult.fold(
      (failure) => state = state.copyWith(error: failure.message, isLoading: false),
      (folders) {
        unfiledResult.fold(
          (failure) => state = state.copyWith(error: failure.message, isLoading: false),
          (unfiled) => state = state.copyWith(
            folders: folders,
            unfiledDocuments: unfiled,
            isLoading: false,
          ),
        );
      },
    );
  }
}
