import 'package:flutter/material.dart';
import '../../../../../app/config/theme/app_theme.dart';
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

  String _formatBytes(int bytes) {
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
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
                '${folder.files.length} archivos · ${_formatBytes(folder.totalSizeBytes)}',
                style: const TextStyle(color: AppTheme.silver, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
