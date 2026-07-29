import 'package:flutter/material.dart';
import '../../../../../app/config/theme/app_theme.dart';

class StorageProgressBar extends StatelessWidget {
  final double ratio; // 0.0 - 1.0

  const StorageProgressBar({super.key, required this.ratio});

  @override
  Widget build(BuildContext context) {
    final color = ratio > 0.9 ? AppTheme.crimsonRed : AppTheme.electricLime;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: ratio.clamp(0.0, 1.0),
        minHeight: 12,
        backgroundColor: AppTheme.ink,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
