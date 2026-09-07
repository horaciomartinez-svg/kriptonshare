import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/formatters.dart';
import '../../core/localization/language_selector_modal.dart';
import '../../models/kripton_file.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/file_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/link_gauge.dart';
import '../../features/analytics/services/funnel_metrics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _trialExpiredDialogShown = false;

  Future<void> _loadData() async {
    await ref.read(authStateProvider.notifier).refreshUser();
    ref.invalidate(userLinksProvider);
    ref.invalidate(receivedFilesProvider);
  }

  String _linkStatusLabel(AppLocalizations l10n, ShareLink link) {
    final now = DateTime.now();
    final isExpired = !link.isActive || link.expiresAt.isBefore(now);
    if (isExpired) return l10n.expiredTag;
    final remaining = link.expiresAt.difference(now);
    final remainingHours = remaining.inHours;
    if (remainingHours < 24) {
      return l10n.hoursRemaining(remainingHours.clamp(1, 23));
    }
    return l10n.daysRemaining(remainingHours ~/ 24);
  }

  /// Banner de cuenta regresiva del trial (visible mientras el trial esté
  /// activo). Al tocarlo lleva a /plans para renovar antes de que expire.
  Widget? _buildTrialBanner(AppLocalizations l10n, KriptonUser user) {
    final trialEndsAt = user.trialEndsAt;
    if (user.subscriptionTier != 'free' || trialEndsAt == null) return null;
    if (!trialEndsAt.isAfter(DateTime.now())) return null;

    final daysLeft = (trialEndsAt.difference(DateTime.now()).inHours / 24).ceil();
    return GestureDetector(
      onTap: () => context.push('/plans'),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KriptonTheme.electricLime.withOpacity(0.14),
              KriptonTheme.kryptonGreen.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: KriptonTheme.electricLime.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: KriptonTheme.electricLime,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.trialBanner(daysLeft),
                style: const TextStyle(
                  color: KriptonTheme.platinum,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: KriptonTheme.silver,
              size: 20,
            ),
          ],
        ),
      ).animate().fade(delay: 200.ms, duration: 300.ms),
    );
  }

  /// Diálogo "tu trial terminó": se muestra una única vez (persistente) el
  /// primer día tras la expiración del trial (§13.4). Registra `trial_expired`.
  void _maybeShowTrialExpiredDialog(KriptonUser user) {
    if (_trialExpiredDialogShown) return;
    if (user.subscriptionTier != 'free' || user.trialEndsAt == null) return;
    if (user.trialEndsAt!.isAfter(DateTime.now())) return;

    _trialExpiredDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('trial_expired_dialog_shown') ?? false) return;
      await prefs.setBool('trial_expired_dialog_shown', true);
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      FunnelMetricsService().logEvent('trial_expired');
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: KriptonTheme.inkDeep,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: KriptonTheme.cardBorder, width: 1),
            ),
            title: Text(
              l10n.trialExpiredTitle,
              style: const TextStyle(color: KriptonTheme.platinum),
            ),
            content: Text(
              l10n.trialExpiredBody,
              style: const TextStyle(color: KriptonTheme.platinumGrey, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  l10n.paywallNotNow,
                  style: const TextStyle(color: KriptonTheme.silver),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.push('/plans');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: KriptonTheme.electricLime,
                  foregroundColor: KriptonTheme.charcoalBlack,
                ),
                child: Text(l10n.paywallViewPlans),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(authStateProvider);
    final linksAsync = ref.watch(userLinksProvider);
    final receivedAsync = ref.watch(receivedFilesProvider);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: KriptonTheme.silver),
            tooltip: l10n.selectLanguage,
            onPressed: () => LanguageSelectorModal.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: KriptonTheme.silver),
            onPressed: () => context.push('/analytics'),
            tooltip: l10n.analyticsTooltip,
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

            _maybeShowTrialExpiredDialog(user);
            final linksUsed = user.monthlyLinksGenerated;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTrialBanner(l10n, user) ?? const SizedBox.shrink(),
                  // Welcome
                  Text(
                    l10n.welcome,
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

                  // Gauge: solo free (cuota mensual de links). El storage se
                  // gestiona desde /plans (§6.4).
                  if (!user.isPremium)
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
                        l10n.capacity,
                        '${user.maxFileSizeBytes ~/ (1024 * 1024)} MB',
                        Icons.storage,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        l10n.duration,
                        user.isPremium
                            ? '${user.maxDurationHours ~/ 24}d'
                            : '${user.maxDurationHours}h',
                        Icons.timer,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        l10n.plan,
                        switch (user.effectiveTier) {
                          'business' => l10n.businessBadge,
                          'premium' => l10n.premium,
                          _ => l10n.free,
                        },
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
                        l10n.receivedFiles,
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
                                l10n.noReceivedFiles,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.receivedFilesHint,
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
                        l10n.errorWithMessage(error.toString()),
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
                        l10n.activeLinks,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 18,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/links'),
                        child: Text(l10n.viewAll),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  linksAsync.when(
                    data: (links) {
                      final now = DateTime.now();
                      final activeLinks = links
                          .where((l) => l.isActive && l.expiresAt.isAfter(now))
                          .toList();

                      if (activeLinks.isEmpty) {
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
                                l10n.noActiveLinks,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeLinks.take(5).length,
                        itemBuilder: (context, index) {
                          final link = activeLinks[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: KriptonTheme.ink,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: KriptonTheme.cardBorder,
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
                                    Icons.link,
                                    color: KriptonTheme.electricLime,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        link.id.substring(0, 8).toUpperCase(),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: KriptonTheme.platinum,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _linkStatusLabel(l10n, link),
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
                        l10n.errorWithMessage(error.toString()),
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            label: l10n.dashboardTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.link),
            label: l10n.linksTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: l10n.profileTab,
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
    final l10n = AppLocalizations.of(context);
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
                    '${formatBytes(context, file.fileSizeBytes)} · ${l10n.expiresLabel} ${_formatExpiresAt(context, l10n, file.linkExpiresAt ?? file.expiresAt)}',
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

  String _formatExpiresAt(BuildContext context, AppLocalizations l10n, DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);
    if (diff.isNegative) return l10n.expiredTag;
    if (diff.inHours < 1) return l10n.expiresInMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.expiresInHours(diff.inHours);
    return l10n.expiresInDays(diff.inDays);
  }
}
