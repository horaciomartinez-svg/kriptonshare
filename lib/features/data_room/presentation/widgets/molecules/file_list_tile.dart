import 'package:flutter/material.dart';
import '../../../../../app/config/theme/app_theme.dart';
import '../../../domain/entities/file_entity.dart';
import '../atoms/encryption_badge.dart';

class FileListTile extends StatelessWidget {
  final FileEntity file;
  final VoidCallback? onTap;
  final VoidCallback? onShare;

  const FileListTile({
    super.key,
    required this.file,
    this.onTap,
    this.onShare,
  });

  String _formatBytes(int bytes) {
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  IconData _iconForMime(String mime) {
    if (mime.startsWith('image/')) return Icons.image;
    if (mime.startsWith('video/')) return Icons.videocam;
    if (mime == 'application/pdf') return Icons.picture_as_pdf;
    if (mime.contains('spreadsheet') || mime.contains('excel')) return Icons.table_chart;
    if (mime.contains('presentation') || mime.contains('powerpoint')) return Icons.slideshow;
    if (mime.contains('word') || mime.contains('document')) return Icons.description;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          _iconForMime(file.mimeType),
          color: AppTheme.electricLime,
        ),
        title: Text(
          file.originalFilename,
          style: const TextStyle(color: AppTheme.platinum),
        ),
        subtitle: Row(
          children: [
            Text(
              '${_formatBytes(file.fileSizeBytes)}',
              style: const TextStyle(color: AppTheme.silver),
            ),
            const SizedBox(width: 8),
            const EncryptionBadge(),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onShare != null)
              IconButton(
                icon: const Icon(Icons.share, color: AppTheme.platinum),
                onPressed: onShare,
              ),
            const Icon(Icons.more_vert, color: AppTheme.silver),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
