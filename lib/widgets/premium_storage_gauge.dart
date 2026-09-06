import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/theme.dart';

/// Gráfica circular que muestra el uso del Data Room Premium (1 GB base).
///
/// Cómo funciona:
///   1) Recibe `usedBytes` (totalStorageUsedBytes del usuario).
///   2) Calcula el ratio: usedBytes / 1 GB (1073741824).
///   3) Un Stack superpone:
///      - Un círculo de fondo (KriptonTheme.ink).
///      - Un CircularProgressIndicator animado con el ratio.
///      - Un texto centrado que muestra "X MB / 1 GB" o "X GB / 1 GB".
class PremiumStorageGauge extends StatelessWidget {
  final int usedBytes;
  final int maxBytes; // 1 GB base por defecto

  const PremiumStorageGauge({
    super.key,
    required this.usedBytes,
    this.maxBytes = 1073741824, // 1 GB
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Ratio clamp(0, 1): evita que CircularProgressIndicator reciba > 1.0
    final ratio = (usedBytes / maxBytes).clamp(0.0, 1.0);

    // Formateo legible: si < 1 GB muestra MB, si >= 1 GB muestra GB con 1 decimal.
    String usedLabel;
    if (usedBytes < 1024 * 1024 * 1024) {
      final mb = usedBytes ~/ (1024 * 1024);
      usedLabel = '$mb MB';
    } else {
      final gb = usedBytes / (1024 * 1024 * 1024);
      usedLabel = '${gb.toStringAsFixed(1)} GB';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KriptonTheme.ink,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: KriptonTheme.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dataRoomStorage,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '$usedLabel / 1 GB',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KriptonTheme.electricLime,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stack: círculo de fondo + progress + texto centrado
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Círculo de fondo (pista del progreso)
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: KriptonTheme.inkDeep,
                    valueColor: const AlwaysStoppedAnimation<Color>(KriptonTheme.ink),
                  ),
                ),
                // Progreso circular animado
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(KriptonTheme.electricLime),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Texto centrado: porcentaje
                Text(
                  '${(ratio * 100).toInt()}%',
                  style: TextStyle(
                    color: KriptonTheme.electricLime,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.premiumPlanLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KriptonTheme.graphite,
                ),
          ),
        ],
      ),
    );
  }
}
