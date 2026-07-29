import 'package:flutter/material.dart';
import '../../../../../app/config/theme/app_theme.dart';
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

  String _formatBytes(int bytes) {
    if (bytes >= 1073741824) return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = maxBytes > 0 ? (usedBytes / maxBytes).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'CAPACIDAD DATA ROOM PREMIUM',
              style: TextStyle(
                color: AppTheme.silver,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatBytes(usedBytes)} de ${_formatBytes(maxBytes)} usados (${(ratio * 100).toStringAsFixed(0)}%)',
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
                  child: const Text(
                    'Expandir +1 GB - \$5/mes',
                    style: TextStyle(color: AppTheme.electricLime),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
