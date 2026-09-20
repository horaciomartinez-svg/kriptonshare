import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
import '../models/trial_start_outcome.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import 'trial_activation_button.dart';

/// Banner del trial Premium en el Dashboard.
///
/// Resuelve su visibilidad a partir del estado real del usuario
/// (`subscription_tier` + `trial_ends_at`):
///
///  - Trial activo            → cuenta regresiva "X días restantes".
///  - Free sin trial usado    → invitación a activar la prueba (trial_ends_at
///    NULL, es decir, nunca la consumió).
///  - Premium / Business      → oculto.
///  - Free con trial ya usado → oculto (no se vuelve a ofrecer).
class DashboardTrialBanner extends StatelessWidget {
  final KriptonUser user;

  /// Trial activo: lleva a /plans para renovar antes de que expire.
  final VoidCallback onViewPlans;

  /// Invitación: activa la prueba vía RPC start_premium_trial.
  final Future<TrialStartOutcome> Function() onStartTrial;

  const DashboardTrialBanner({
    super.key,
    required this.user,
    required this.onViewPlans,
    required this.onStartTrial,
  });

  @override
  Widget build(BuildContext context) {
    switch (resolveTrialBannerMode(user)) {
      case TrialBannerMode.countdown:
        return _buildCountdown(context);
      case TrialBannerMode.invite:
        return _buildInvite(context);
      case TrialBannerMode.hidden:
        return const SizedBox.shrink();
    }
  }

  BoxDecoration _decoration() => BoxDecoration(
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
      );

  Widget _buildCountdown(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trialEndsAt = user.trialEndsAt!;
    final daysLeft = (trialEndsAt.difference(DateTime.now()).inHours / 24).ceil();

    return GestureDetector(
      onTap: onViewPlans,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: _decoration(),
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

  Widget _buildInvite(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                color: KriptonTheme.electricLime,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.trialPromo,
                  style: const TextStyle(
                    color: KriptonTheme.electricLime,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TrialActivationButton(
            onActivate: onStartTrial,
            label: l10n.trialCta,
          ),
        ],
      ).animate().fade(delay: 200.ms, duration: 300.ms),
    );
  }
}

/// Resuelve el modo del banner para un usuario dado. Expuesto para pruebas.
enum TrialBannerMode { hidden, countdown, invite }

TrialBannerMode resolveTrialBannerMode(KriptonUser user) {
  if (user.isInTrial) return TrialBannerMode.countdown;
  if (user.isFree && user.trialEndsAt == null) return TrialBannerMode.invite;
  return TrialBannerMode.hidden;
}
