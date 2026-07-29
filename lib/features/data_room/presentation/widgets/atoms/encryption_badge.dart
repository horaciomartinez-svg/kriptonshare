import 'package:flutter/material.dart';
import '../../../../../app/config/theme/app_theme.dart';

class EncryptionBadge extends StatelessWidget {
  const EncryptionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.mutedGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 12, color: AppTheme.mutedGreen),
          SizedBox(width: 4),
          Text(
            'AES-256-GCM',
            style: TextStyle(
              color: AppTheme.mutedGreen,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
