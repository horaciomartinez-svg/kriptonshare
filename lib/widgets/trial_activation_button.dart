import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/trial_start_outcome.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// Botón de activación del trial Premium.
///
/// Ejecuta la activación (RPC `start_premium_trial`), muestra un indicador de
/// carga mientras espera y da feedback con SnackBar: éxito o el error
/// localizado según el `code` del servidor. Nunca falla en silencio.
class TrialActivationButton extends StatefulWidget {
  final Future<TrialStartOutcome> Function() onActivate;
  final String label;

  const TrialActivationButton({
    super.key,
    required this.onActivate,
    required this.label,
  });

  @override
  State<TrialActivationButton> createState() => _TrialActivationButtonState();
}

class _TrialActivationButtonState extends State<TrialActivationButton> {
  bool _loading = false;

  String _messageFor(AppLocalizations l10n, TrialStartOutcome outcome) {
    if (outcome.started) {
      return l10n.trialBanner(PremiumLimits.trialDurationDays);
    }
    switch (outcome.code) {
      case 'already_used':
        return l10n.trialAlreadyUsed;
      case 'not_eligible':
        return l10n.trialNotEligible;
      default:
        return outcome.message ?? l10n.unknownError;
    }
  }

  Future<void> _handle() async {
    if (_loading) return;
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    final outcome = await widget.onActivate();
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_messageFor(l10n, outcome)),
        backgroundColor: outcome.started
            ? KriptonTheme.kryptonGreen
            : KriptonTheme.alertRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _handle,
        style: ElevatedButton.styleFrom(
          backgroundColor: KriptonTheme.electricLime,
          foregroundColor: KriptonTheme.charcoalBlack,
        ),
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: KriptonTheme.charcoalBlack,
                ),
              )
            : Text(widget.label),
      ),
    );
  }
}
