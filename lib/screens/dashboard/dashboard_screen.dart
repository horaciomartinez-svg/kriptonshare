import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../models/kripton_file.dart';
import '../../providers/auth_provider.dart';
import '../../providers/file_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/link_gauge.dart';
import '../../widgets/data_room_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<void> _loadData() async {
    await ref.read(authStateProvider.notifier).refreshUser();
    ref.invalidate(userLinksProvider);
    ref.invalidate(receivedFilesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final linksAsync = ref.watch(userLinksProvider);
    final receivedAsync = ref.watch(receivedFilesProvider);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: const Text('KRIPTONSHARE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: KriptonTheme.silver),
            onPressed: () => context.push('/analytics'),
            tooltip: 'Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: KriptonTheme.silver),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: KriptonTheme.electricLime,
        backgroundColor: KriptonTheme.inkDeep,
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final linksUsed = user.monthlyLinksGenerated;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome
                  Text(
                    'Bienvenido',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 24,
                        ),
                  )
                      .animate()
                      .fade(duration: 300.ms)
                      .slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: KriptonTheme.silver,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Link Gauge
                  LinkGauge(
                    used: linksUsed,
                    total: AppConstants.maxLinksPerMonth,
                  )
                      .animate()
                      .fade(delay: 100.ms, duration: 400.ms)
                      .scale(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        'Capacidad',
                        '${AppConstants.maxFileSizeBytes ~/ (1024 * 1024)} MB',
                        Icons.storage,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Duración',
                        '${AppConstants.maxDurationHours}h',
                        Icons.timer,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Plan',
                        user.isPremium ? 'Premium' : 'Free',
                        Icons.verified,
                      ),
                    ],
                  )
                      .animate()
                      .fade(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 32),

                  // Received Files Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Archivos recibidos',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 18,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  receivedAsync.when(
                    data: (files) {
                      if (files.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: KriptonTheme.ink,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: KriptonTheme.cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.inbox_outlined,
                                size: 40,
                                color: KriptonTheme.graphite,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No has recibido archivos',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Los enlaces enviados a tu correo aparecerán aquí',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: KriptonTheme.silver,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: files.take(5).length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          return _ReceivedFileCard(
                            file: file,
                            onTap: () {
                              final linkId = file.linkId;
                              if (linkId != null) {
                                context.push('/room/$linkId');
                              }
                            },
                          )
                              .animate()
                              .fade(delay: Duration(milliseconds: 300 + index * 100))
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                delay: Duration(milliseconds: 300 + index * 100),
                              );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
                      ),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        'Error: $error',
                        style: const TextStyle(color: KriptonTheme.alertRed),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent Links Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Enlaces activos',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 18,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/links'),
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  linksAsync.when(
                    data: (links) {
                      if (links.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: KriptonTheme.ink,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: KriptonTheme.cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.link_off,
                                size: 48,
                                color: KriptonTheme.graphite,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sin enlaces activos',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Crea tu primer Data Room seguro',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: KriptonTheme.silver,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: links.take(5).length,
                        itemBuilder: (context, index) {
                          final link = links[index];
                          return DataRoomCard(link: link)
                              .animate()
                              .fade(delay: Duration(milliseconds: 300 + index * 100))
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                delay: Duration(milliseconds: 300 + index * 100),
                              );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
                      ),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        'Error: $error',
                        style: const TextStyle(color: KriptonTheme.alertRed),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
            ),
          ),
          error: (error, _) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: KriptonTheme.alertRed),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/upload'),
        child: const Icon(Icons.add_link),
      )
          .animate()
          .scale(delay: 500.ms, duration: 400.ms, curve: Curves.easeOutBack),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/links');
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

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KriptonTheme.ink,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: KriptonTheme.cardBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: KriptonTheme.electricLime, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 16,
                    color: KriptonTheme.electricLime,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KriptonTheme.silver,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedFileCard extends StatelessWidget {
  final KriptonFile file;
  final VoidCallback onTap;

  const _ReceivedFileCard({
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KriptonTheme.ink,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: KriptonTheme.electricLime.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: KriptonTheme.electricLime.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: KriptonTheme.electricLime,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.originalFilename,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: KriptonTheme.platinum,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(file.fileSizeBytes / 1024).toStringAsFixed(1)} KB · Expira ${_formatExpiresAt(file.linkExpiresAt ?? file.expiresAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KriptonTheme.silver,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: KriptonTheme.silver,
            ),
          ],
        ),
      ),
    );
  }

  String _formatExpiresAt(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);
    if (diff.isNegative) return 'expirado';
    if (diff.inHours < 1) return 'en ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'en ${diff.inHours}h';
    return 'en ${diff.inDays}d';
  }
}
