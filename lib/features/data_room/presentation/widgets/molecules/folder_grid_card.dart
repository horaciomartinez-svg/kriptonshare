import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../app/config/theme/app_theme.dart';
import '../../../../../core/localization/formatters.dart';
import '../../../domain/entities/folder_entity.dart';

class FolderGridCard extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback? onTap;
  final VoidCallback? onShare;

  const FolderGridCard({
    super.key,
    required this.folder,
    this.onTap,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.folder,
                    size: 40,
                    color: AppTheme.electricLime,
                  ),
                  const Spacer(),
                  if (onShare != null)
                    IconButton(
                      icon: const Icon(Icons.share, color: AppTheme.platinum, size: 20),
                      onPressed: onShare,
                    ),
                  const Icon(Icons.more_vert, color: AppTheme.silver, size: 20),
                ],
              ),
              const Spacer(),
              Text(
                folder.name,
                style: const TextStyle(
                  color: AppTheme.platinum,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.folderCardSummary(folder.files.length, formatBytes(context, folder.totalSizeBytes)),
                style: const TextStyle(color: AppTheme.silver, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
