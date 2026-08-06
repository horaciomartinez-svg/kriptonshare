import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../app/config/theme/app_theme.dart';
import '../../../../../core/localization/formatters.dart';
import '../atoms/storage_progress_bar.dart';

class StorageGaugeCard extends StatelessWidget {
  final int usedBytes;
  final int maxBytes;
  final VoidCallback? onUpgrade;

  const StorageGaugeCard({
    super.key,
    required this.usedBytes,
    required this.maxBytes,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ratio = maxBytes > 0 ? (usedBytes / maxBytes).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.premiumCapacityLabel,
              style: const TextStyle(
                color: AppTheme.silver,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.storageUsedSummary(
                formatBytes(context, usedBytes),
                formatBytes(context, maxBytes),
                (ratio * 100).round(),
              ),
              style: const TextStyle(color: AppTheme.platinum, fontSize: 14),
            ),
            const SizedBox(height: 12),
            StorageProgressBar(ratio: ratio),
            const SizedBox(height: 12),
            if (onUpgrade != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onUpgrade,
                  child: Text(
                    l10n.expandVaultAddon,
                    style: const TextStyle(color: AppTheme.electricLime),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
