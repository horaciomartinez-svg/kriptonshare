import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/supabase_links_datasource.dart';
import 'data/repositories/links_repository_impl.dart';
import 'domain/repositories/i_links_repository.dart';
import 'domain/usecases/delete_file.dart';
import 'domain/usecases/get_user_links.dart';
import 'domain/usecases/revoke_link.dart';
import 'presentation/notifiers/links_notifier.dart';

/// Fuente de datos remota de Supabase para links.
final linksDataSourceProvider = Provider<SupabaseLinksDataSource>((ref) {
  return SupabaseLinksDataSource(Supabase.instance.client);
});

/// Repositorio de links.
final linksRepositoryProvider = Provider<ILinksRepository>((ref) {
  return LinksRepositoryImpl(ref.watch(linksDataSourceProvider));
});

/// Caso de uso para obtener links del usuario.
final getUserLinksUseCaseProvider = Provider<GetUserLinksUseCase>((ref) {
  return GetUserLinksUseCase(ref.watch(linksRepositoryProvider));
});

/// Caso de uso para revocar un link.
final revokeLinkUseCaseProvider = Provider<RevokeLinkUseCase>((ref) {
  return RevokeLinkUseCase(ref.watch(linksRepositoryProvider));
});

/// Caso de uso para eliminar un archivo.
final deleteFileUseCaseProvider = Provider<DeleteFileUseCase>((ref) {
  return DeleteFileUseCase(ref.watch(linksRepositoryProvider));
});

/// Notifier de estado para gestión de links.
final linksNotifierProvider = StateNotifierProvider<LinksNotifier, LinksState>((ref) {
  return LinksNotifier(
    getUserLinks: ref.watch(getUserLinksUseCaseProvider),
    revokeLink: ref.watch(revokeLinkUseCaseProvider),
    deleteFile: ref.watch(deleteFileUseCaseProvider),
  );
});
