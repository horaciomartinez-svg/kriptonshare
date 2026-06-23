import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/network_info.dart';
import '../../services/crypto_service.dart';
import 'data/datasources/supabase_upload_datasource.dart';
import 'data/repositories/upload_repository_impl.dart';
import 'domain/repositories/i_upload_repository.dart';
import 'domain/usecases/upload_file.dart';
import 'presentation/notifiers/upload_notifier.dart';

/// Fuente de datos remota de Supabase para subida de archivos.
final uploadDataSourceProvider = Provider<SupabaseUploadDataSource>((ref) {
  return SupabaseUploadDataSource(Supabase.instance.client);
});

/// Repositorio de subida de archivos cifrados.
final uploadRepositoryProvider = Provider<IUploadRepository>((ref) {
  return UploadRepositoryImpl(
    dataSource: ref.watch(uploadDataSourceProvider),
    cryptoService: CryptoService(),
    networkInfo: NetworkInfoImpl(),
  );
});

/// Caso de uso para subir archivos cifrados.
final uploadFileUseCaseProvider = Provider<UploadFileUseCase>((ref) {
  return UploadFileUseCase(ref.watch(uploadRepositoryProvider));
});

/// Notifier de estado del proceso de subida.
final uploadNotifierProvider = StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref.watch(uploadFileUseCaseProvider));
});
