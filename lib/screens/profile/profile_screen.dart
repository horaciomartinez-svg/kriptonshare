import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: KriptonTheme.brandGradient,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(
                    child: Text(
                      user.email.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        color: KriptonTheme.platinum,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(duration: 400.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 16),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isPremium
                        ? KriptonTheme.electricLime.withOpacity(0.1)
                        : KriptonTheme.inkDeep,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: user.isPremium
                          ? KriptonTheme.electricLime
                          : KriptonTheme.cardBorder,
                    ),
                  ),
                  child: Text(
                    user.isPremium ? 'PREMIUM' : 'FREE',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: user.isPremium
                              ? KriptonTheme.electricLime
                              : KriptonTheme.silver,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 32),

                // Plan details
                Container(
                  padding: const EdgeInsets.all(20),
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
                      Text(
                        'Tu plan actual',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildPlanRow(
                        context,
                        'Almacenamiento máximo',
                        '${AppConstants.maxFileSizeBytes ~/ (1024 * 1024)} MB',
                        Icons.storage,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanRow(
                        context,
                        'Enlaces mensuales',
                        '${AppConstants.maxLinksPerMonth}',
                        Icons.link,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanRow(
                        context,
                        'Duración máxima',
                        '${AppConstants.maxDurationHours} horas',
                        Icons.timer,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanRow(
                        context,
                        'Cifrado',
                        'AES-256-GCM',
                        Icons.security,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanRow(
                        context,
                        'Marca de agua',
                        'Institucional pasiva',
                        Icons.branding_watermark,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fade(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),

                // Upgrade CTA
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: KriptonTheme.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Desbloquea capacidad total',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: KriptonTheme.platinum,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '100 MB por archivo, enlaces ilimitados, caducidad personalizable, marca de agua forense dinámica.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: KriptonTheme.platinum.withOpacity(0.8),
                            ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement IAP
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KriptonTheme.platinum,
                          foregroundColor: KriptonTheme.charcoalBlack,
                        ),
                        child: const Text('Upgrade a Premium'),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fade(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: 32),

                // Logout
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KriptonTheme.alertRed,
                    side: const BorderSide(color: KriptonTheme.alertRed),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.push('/dashboard');
              break;
            case 1:
              context.push('/links');
              break;
            case 2:
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

  Widget _buildPlanRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: KriptonTheme.silver),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KriptonTheme.silver,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KriptonTheme.electricLime,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
