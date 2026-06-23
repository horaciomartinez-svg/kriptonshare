import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/link_entity.dart';
import '../../domain/usecases/delete_file.dart';
import '../../domain/usecases/get_user_links.dart';
import '../../domain/usecases/revoke_link.dart';

/// Estado de links para la capa de presentación.
class LinksState {
  final List<LinkEntity> links;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const LinksState({
    this.links = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  static const int pageSize = 20;

  LinksState copyWith({
    List<LinkEntity>? links,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return LinksState(
      links: links ?? this.links,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

/// Notifier de gestión de links compartidos.
class LinksNotifier extends StateNotifier<LinksState> {
  final GetUserLinksUseCase _getUserLinks;
  final RevokeLinkUseCase _revokeLink;
  final DeleteFileUseCase _deleteFile;

  LinksNotifier({
    required GetUserLinksUseCase getUserLinks,
    required RevokeLinkUseCase revokeLink,
    required DeleteFileUseCase deleteFile,
  })  : _getUserLinks = getUserLinks,
        _revokeLink = revokeLink,
        _deleteFile = deleteFile,
        super(const LinksState());

  /// Cargar la primera página de links del usuario.
  Future<void> loadLinks(String ownerId) async {
    state = const LinksState(isLoading: true);

    final result = await _getUserLinks(
      ownerId,
      limit: LinksState.pageSize,
      offset: 0,
    );
    result.fold(
      (failure) => state = state.copyWith(
        error: failure.message,
        isLoading: false,
      ),
      (links) => state = state.copyWith(
        links: links,
        isLoading: false,
        hasMore: links.length >= LinksState.pageSize,
        currentPage: 1,
      ),
    );
  }

  /// Cargar la siguiente página de links (lazy loading).
  Future<void> loadMore(String ownerId) async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    final offset = state.currentPage * LinksState.pageSize;
    final result = await _getUserLinks(
      ownerId,
      limit: LinksState.pageSize,
      offset: offset,
    );
    result.fold(
      (failure) => state = state.copyWith(
        error: failure.message,
        isLoadingMore: false,
      ),
      (newLinks) {
        final merged = [...state.links, ...newLinks];
        state = state.copyWith(
          links: merged,
          isLoadingMore: false,
          hasMore: newLinks.length >= LinksState.pageSize,
          currentPage: state.currentPage + 1,
        );
      },
    );
  }

  /// Revocar un link y recargar la lista.
  Future<void> revokeLink(String linkId, String ownerId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _revokeLink(linkId);
    await result.fold(
      (failure) async {
        state = state.copyWith(
          error: failure.message,
          isLoading: false,
        );
      },
      (_) async {
        await loadLinks(ownerId);
      },
    );
  }

  /// Eliminar un archivo y recargar la lista.
  Future<void> deleteFile(String fileId, String ownerId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deleteFile(fileId: fileId, ownerId: ownerId);
    await result.fold(
      (failure) async {
        state = state.copyWith(
          error: failure.message,
          isLoading: false,
        );
      },
      (_) async {
        await loadLinks(ownerId);
      },
    );
  }

  /// Limpiar errores.
  void clearError() {
    state = state.copyWith(error: null);
  }
}
