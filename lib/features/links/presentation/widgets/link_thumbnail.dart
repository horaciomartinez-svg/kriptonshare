import 'package:flutter/material.dart';
import '../../../../core/services/thumbnail_cache_service.dart';

/// Widget que muestra un thumbnail cacheado para un archivo.
class LinkThumbnail extends StatelessWidget {
  final String fileId;
  final double size;

  const LinkThumbnail({
    super.key,
    required this.fileId,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = ThumbnailCacheService().getMetadata(fileId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: metadata.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        metadata.icon,
        color: metadata.foregroundColor,
        size: size * 0.5,
      ),
    );
  }
}
