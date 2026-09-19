import 'package:flutter/material.dart';

import '../core/localization/formatters.dart';
import '../l10n/app_localizations.dart';
import '../models/active_links_summary.dart';
import '../utils/theme.dart';

/// Resumen compacto de los Active Links: cantidad y almacenamiento total.
///
/// Muestra el denominador del plan solo en la dimensión que ese plan limita
/// (Free: cantidad; Premium/Business: almacenamiento) y resalta en ámbar el
/// dato cuando se alcanza el 80 % del límite.
class ActiveLinksSummaryBar extends StatelessWidget {
  final ActiveLinksSummary summary;

  const ActiveLinksSummaryBar({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final countLabel = summary.countLimit != null
        ? l10n.activeLinksSummaryCountOfMax(
            summary.activeCount,
            summary.countLimit!,
          )
        : l10n.activeLinksSummaryCount(summary.activeCount);

    final usedLabel = formatBytes(context, summary.totalSizeBytes);
    final storageLabel = summary.storageLimitBytes != null
        ? l10n.activeLinksSummaryStorageOfQuota(
            usedLabel,
            formatBytes(context, summary.storageLimitBytes!),
          )
        : l10n.activeLinksSummaryStorage(usedLabel);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(
          icon: Icons.link,
          label: countLabel,
          highlight: summary.isCountNearLimit,
        ),
        _SummaryChip(
          icon: Icons.sd_storage_outlined,
          label: storageLabel,
          highlight: summary.isStorageNearLimit,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? KriptonTheme.amber : KriptonTheme.electricLime;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KriptonTheme.ink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? KriptonTheme.amber : KriptonTheme.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: KriptonTheme.platinum,
            ),
          ),
        ],
      ),
    );
  }
}
