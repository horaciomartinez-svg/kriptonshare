import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/constants.dart';
import '../../links_providers.dart';
import '../../domain/entities/link_entity.dart';
import '../notifiers/links_notifier.dart';
import '../widgets/link_card.dart';
import '../widgets/link_thumbnail.dart';

/// Pantalla de listado de enlaces activos.
///
/// Optimizaciones aplicadas:
/// - [ListView.builder] con paginación (lazy loading) al llegar al final.
/// - Caché de thumbnails por [fileId] vía [LinkThumbnail].
/// - Debounce de 350 ms en la búsqueda para evitar rebuilds por cada tecla.
/// - Uso de widgets [const] y delegados estáticos para reducir rebuilds.
class LinksScreen extends ConsumerStatefulWidget {
  const LinksScreen({super.key});

  @override
  ConsumerState<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends ConsumerState<LinksScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        ref.read(linksNotifierProvider.notifier).loadLinks(user.id);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Detecta cuando el usuario llega al 80 % del scroll y carga más items.
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        ref.read(linksNotifierProvider.notifier).loadMore(user.id);
      }
    }
  }

  /// Aplica debounce a la búsqueda local para no reconstruir la lista
  /// en cada pulsación de tecla.
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _query = value.trim().toLowerCase());
      }
    });
  }

  Future<void> _refreshLinks() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await ref.read(linksNotifierProvider.notifier).loadLinks(user.id);
    }
  }

  Future<void> _revokeLink(String linkId) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(linksNotifierProvider.notifier).revokeLink(linkId, user.id);
      if (mounted) {
        _showSnackBar('Enlace revocado', KriptonTheme.kryptonGreen);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', KriptonTheme.alertRed);
      }
    }
  }

  Future<void> _deleteFile(String fileId) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteConfirmationDialog(),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(linksNotifierProvider.notifier)
          .deleteFile(fileId, user.id);
      if (mounted) {
        _showSnackBar('Documento eliminado', KriptonTheme.kryptonGreen);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', KriptonTheme.alertRed);
      }
    }
  }

  void _shareLink(String linkId) {
    final url = AppConstants.shareUrl(linkId);
    final appUrl = AppConstants.appLinkUrl(linkId);
    Share.share(
      'Documento seguro via KRIPTONSHARE\n\n'
      '$url\n\n'
      'Si el link no abre la app, usa:\n'
      '$appUrl\n\n'
      'Este enlace expira en ${AppConstants.maxDurationHours}h.',
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Filtra los links localmente según el query de búsqueda.
  List<LinkEntity> _filterLinks(List<LinkEntity> links) {
    if (_query.isEmpty) return links;
    return links.where((link) {
      final idMatch = link.id.toLowerCase().contains(_query);
      final emailMatch = link.recipientEmail?.toLowerCase().contains(_query) ?? false;
      return idMatch || emailMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(linksNotifierProvider);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: const Text('Enlaces activos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _SearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
        ),
      ),
      body: _buildBody(state),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              context.push('/dashboard');
            case 1:
              break;
            case 2:
              context.push('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link),
            label: 'Enlaces',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LinksState state) {
    final filteredLinks = _filterLinks(state.links);

    if (state.isLoading && state.links.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
        ),
      );
    }

    if (state.error != null && state.links.isEmpty) {
      return _ErrorBody(
        error: state.error!,
        onRetry: _refreshLinks,
      );
    }

    if (state.links.isEmpty) {
      return const _EmptyBody();
    }

    if (filteredLinks.isEmpty) {
      return const _NoSearchResultsBody();
    }

    return RefreshIndicator(
      onRefresh: _refreshLinks,
      color: KriptonTheme.electricLime,
      backgroundColor: KriptonTheme.inkDeep,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        // Conserva menos items fuera de pantalla para reducir memoria.
        cacheExtent: 200,
        itemCount: filteredLinks.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filteredLinks.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
                ),
              ),
            );
          }

          final link = filteredLinks[index];
          return _LinkListItem(
            link: link,
            onShare: () => _shareLink(link.id),
            onRevoke: link.isActiveAndNotExpired
                ? () => _revokeLink(link.id)
                : null,
            onDelete: () => _deleteFile(link.fileId),
            animationDelay: Duration(milliseconds: (index % LinksState.pageSize) * 50),
          );
        },
      ),
    );
  }
}

/// Campo de búsqueda con debounce.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: KriptonTheme.platinum),
        decoration: const InputDecoration(
          hintText: 'Buscar por ID o email',
          prefixIcon: Icon(Icons.search, color: KriptonTheme.silver),
        ),
      ),
    );
  }
}

/// Item de lista animado que envuelve a [LinkCard] y su thumbnail.
class _LinkListItem extends StatelessWidget {
  final LinkEntity link;
  final VoidCallback onShare;
  final VoidCallback? onRevoke;
  final VoidCallback onDelete;
  final Duration animationDelay;

  const _LinkListItem({
    required this.link,
    required this.onShare,
    required this.onRevoke,
    required this.onDelete,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: LinkThumbnail(fileId: link.fileId, size: 56),
          ),
          Expanded(
            child: LinkCard(
              link: link,
              onShare: onShare,
              onRevoke: onRevoke,
              onDelete: onDelete,
            )
                .animate()
                .fade(delay: animationDelay)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: animationDelay,
                ),
          ),
        ],
      ),
    );
  }
}

/// Estado de error con botón de reintentar.
class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: KriptonTheme.alertRed, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: const TextStyle(color: KriptonTheme.alertRed),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío cuando el usuario no tiene links.
class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.link_off,
            size: 64,
            color: KriptonTheme.graphite,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin enlaces activos',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer Data Room desde el dashboard',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KriptonTheme.silver,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/upload'),
            child: const Text('Crear enlace'),
          ),
        ],
      ),
    );
  }
}

/// Estado sin resultados para la búsqueda.
class _NoSearchResultsBody extends StatelessWidget {
  const _NoSearchResultsBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: KriptonTheme.silver, size: 48),
          SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(color: KriptonTheme.silver),
          ),
        ],
      ),
    );
  }
}

/// Diálogo de confirmación de eliminación.
class _DeleteConfirmationDialog extends StatelessWidget {
  const _DeleteConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KriptonTheme.ink,
      title: const Text('Eliminar documento'),
      content: const Text(
        'Esta acción es irreversible. El documento será eliminado permanentemente.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: KriptonTheme.alertRed,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
