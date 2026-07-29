import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/r2_client.dart';
import '../../providers/local_database_provider.dart';
import 'data/datasources/folder_remote_datasource.dart';
import 'data/datasources/r2_storage_datasource.dart';
import 'data/repositories/data_room_repository_impl.dart';
import 'data/repositories/folder_repository_impl.dart';
import 'domain/repositories/i_data_room_repository.dart';
import 'domain/repositories/i_folder_repository.dart';
import 'domain/usecases/batch_upload_to_folder_usecase.dart';
import 'domain/usecases/create_folder_usecase.dart';
import 'domain/usecases/create_share_link_usecase.dart';
import 'domain/usecases/encrypt_and_upload_file_usecase.dart';
import 'domain/usecases/fetch_data_room_contents_usecase.dart';
import 'domain/usecases/lazy_decrypt_file_usecase.dart';

// ─── Repositorios ───

final folderRepositoryProvider = Provider<IFolderRepository>((ref) {
  return FolderRepositoryImpl(Supabase.instance.client);
});

final dataRoomRepositoryProvider = Provider<IDataRoomRepository>((ref) {
  return DataRoomRepositoryImpl(
    localDB: ref.watch(localDatabaseProvider),
    supabase: Supabase.instance.client,
    folderRemote: FolderRemoteDataSource(Supabase.instance.client),
    r2: R2StorageDataSource(client: R2Client()),
  );
});

// ─── Casos de uso ───

final createFolderUseCaseProvider = Provider<CreateFolderUseCase>((ref) {
  return CreateFolderUseCase(ref.watch(dataRoomRepositoryProvider));
});

final encryptAndUploadFileUseCaseProvider = Provider<EncryptAndUploadFileUseCase>((ref) {
  return EncryptAndUploadFileUseCase(ref.watch(dataRoomRepositoryProvider));
});

final batchUploadToFolderUseCaseProvider = Provider<BatchUploadToFolderUseCase>((ref) {
  return BatchUploadToFolderUseCase(ref.watch(dataRoomRepositoryProvider));
});

final fetchDataRoomContentsUseCaseProvider = Provider<FetchDataRoomContentsUseCase>((ref) {
  return FetchDataRoomContentsUseCase(ref.watch(dataRoomRepositoryProvider));
});

final createShareLinkUseCaseProvider = Provider<CreateShareLinkUseCase>((ref) {
  return CreateShareLinkUseCase(ref.watch(dataRoomRepositoryProvider));
});

final lazyDecryptFileUseCaseProvider = Provider<LazyDecryptFileUseCase>((ref) {
  return LazyDecryptFileUseCase(ref.watch(dataRoomRepositoryProvider));
});
