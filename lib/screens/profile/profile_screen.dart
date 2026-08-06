import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/formatters.dart';
import '../../core/localization/language_selector_modal.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/supported_locales.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: Text(l10n.profileTitle),
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
                    user.isPremium ? l10n.premium.toUpperCase() : l10n.free.toUpperCase(),
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
                        l10n.yourCurrentPlan,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildPlanRow(
                        context,
                        l10n.maxFileSize,
                        '${AppConstants.maxFileSizeBytes ~/ (1024 * 1024)} MB',
                        Icons.file_present,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanRow(
                        context,
                        l10n.dataRoomStorage,
                        user.isPremium
                            ? formatBytes(context, user.maxStorageBytes)
                            : l10n.notAvailable,
                        Icons.storage,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanRow(
                        context,
                        l10n.monthlyLinks,
                        '${AppConstants.maxLinksPerMonth}',
                        Icons.link,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanRow(
                        context,
                        l10n.maxDuration,
                        l10n.hoursValue(AppConstants.maxDurationHours),
                        Icons.timer,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanRow(
                        context,
                        l10n.encryptionLabel,
                        'AES-256-GCM',
                        Icons.security,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanRow(
                        context,
                        l10n.watermarkLabel,
                        l10n.institutionalPassiveWatermark,
                        Icons.branding_watermark,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fade(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),

                // Security
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
                        l10n.securityTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: KriptonTheme.electricLime.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.language,
                            color: KriptonTheme.electricLime,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          l10n.language,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: KriptonTheme.platinum,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        subtitle: Text(
                          kSupportedLocales
                              .firstWhere((s) =>
                                  s.locale.languageCode ==
                                  ref.watch(localeProvider).languageCode)
                              .nativeName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: KriptonTheme.electricLime,
                              ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: KriptonTheme.silver,
                        ),
                        onTap: () => LanguageSelectorModal.show(context),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: KriptonTheme.electricLime.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.fingerprint,
                            color: KriptonTheme.electricLime,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          l10n.biometricsLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: KriptonTheme.platinum,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        subtitle: Text(
                          l10n.configureBiometrics,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: KriptonTheme.silver,
                              ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: KriptonTheme.silver,
                        ),
                        onTap: () => context.push('/biometric'),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fade(delay: 300.ms, duration: 400.ms)
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
                        l10n.unlockFullCapacity,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: KriptonTheme.platinum,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.premiumBenefits,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: KriptonTheme.platinum.withOpacity(0.8),
                            ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/storage-management'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KriptonTheme.platinum,
                          foregroundColor: KriptonTheme.charcoalBlack,
                        ),
                        child: Text(l10n.managePremiumVault),
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
                  label: Text(l10n.signOut),
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
            l10n.errorWithMessage(error.toString()),
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
