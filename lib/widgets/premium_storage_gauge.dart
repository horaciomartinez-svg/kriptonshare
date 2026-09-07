import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/localization/formatters.dart';
import '../utils/theme.dart';

/// Gráfica circular del almacenamiento efímero total del usuario
/// (suma de archivos con links activos: `total_storage_used_bytes` /
/// `max_storage_bytes`). Vive en la pantalla de planes (§6.4).
class PremiumStorageGauge extends StatelessWidget {
  final int usedBytes;
  final int maxBytes;

  const PremiumStorageGauge({
    super.key,
    required this.usedBytes,
    required this.maxBytes,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Ratio clamp(0, 1): evita que CircularProgressIndicator reciba > 1.0
    final ratio = (usedBytes / maxBytes).clamp(0.0, 1.0);

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
              Expanded(
                child: Text(
                  l10n.ephemeralStorageLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${formatBytes(context, usedBytes)} / ${formatBytes(context, maxBytes)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KriptonTheme.electricLime,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: KriptonTheme.inkDeep,
                    valueColor: AlwaysStoppedAnimation<Color>(KriptonTheme.ink),
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        KriptonTheme.electricLime),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${(ratio * 100).toInt()}%',
                  style: const TextStyle(
                    color: KriptonTheme.electricLime,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
