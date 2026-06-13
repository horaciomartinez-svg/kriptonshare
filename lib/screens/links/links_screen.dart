import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/file_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/data_room_card.dart';

class LinksScreen extends ConsumerStatefulWidget {
  const LinksScreen({super.key});

  @override
  ConsumerState<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends ConsumerState<LinksScreen> {
  Future<void> _refreshLinks() async {
    await ref.read(authStateProvider.notifier).refreshUser();
    setState(() {});
  }

  Future<void> _revokeLink(String linkId) async {
    try {
      final fileService = ref.read(fileServiceProvider);
      await fileService.revokeLink(linkId);
      await _refreshLinks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enlace revocado'),
            backgroundColor: KriptonTheme.kryptonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: KriptonTheme.alertRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(String fileId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KriptonTheme.ink,
        title: const Text('Eliminar documento'),
        content: const Text('Esta acción es irreversible. El documento será eliminado permanentemente.'),
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
      ),
    );

    if (confirmed != true) return;

    try {
      final fileService = ref.read(fileServiceProvider);
      await fileService.deleteFile(fileId);
      await _refreshLinks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento eliminado'),
            backgroundColor: KriptonTheme.kryptonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: KriptonTheme.alertRed,
          ),
        );
      }
    }
  }

  void _shareLink(String linkId) {
    final url = 'https://kriptonshare.com/room/$linkId';
    Share.share(
      'Documento seguro via KRIPTONSHARE\n\n'
      '$url\n\n'
      'Este enlace expira en ${AppConstants.maxDurationHours}h.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileService = ref.watch(fileServiceProvider);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: const Text('Enlaces activos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder(
        future: fileService.getUserLinks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
              ),
            );
          }

          final links = snapshot.data!;
          if (links.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
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

          return RefreshIndicator(
            onRefresh: _refreshLinks,
            color: KriptonTheme.electricLime,
            backgroundColor: KriptonTheme.inkDeep,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: links.length,
              itemBuilder: (context, index) {
                final link = links[index];
                final isExpired = link.expiresAt.isBefore(DateTime.now());
                final isActive = link.isActive && !isExpired;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: DataRoomCard(
                    link: link,
                    onShare: () => _shareLink(link.id),
                    onRevoke: isActive ? () => _revokeLink(link.id) : null,
                    onDelete: () => _deleteFile(link.fileId),
                  )
                      .animate()
                      .fade(delay: Duration(milliseconds: index * 100))
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        delay: Duration(milliseconds: index * 100),
                      ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              context.push('/dashboard');
              break;
            case 1:
              break;
            case 2:
              context.push('/profile');
              break;
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
}
