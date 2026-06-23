import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Caché en memoria para metadatos de thumbnails.
///
/// En una app real se cachearían aquí los bytes de imágenes previas descargadas
/// desde Supabase Storage. Para este MVP, cacheamos el icono y color derivados
/// determinísticamente del [fileId], evitando recomputarlos en cada rebuild.
class ThumbnailCacheService {
  static final ThumbnailCacheService _instance = ThumbnailCacheService._internal();
  factory ThumbnailCacheService() => _instance;
  ThumbnailCacheService._internal();

  final _cache = <String, ThumbnailMetadata>{};
  static const int _maxSize = 200;

  static const List<IconData> _fileIcons = [
    Icons.insert_drive_file,
    Icons.picture_as_pdf,
    Icons.image,
    Icons.audiotrack,
    Icons.videocam,
    Icons.description,
    Icons.table_chart,
    Icons.code,
  ];

  static const List<Color> _backgroundColors = [
    Color(0xFF1A237E),
    Color(0xFF004D40),
    Color(0xFF1B5E20),
    Color(0xFF3E2723),
    Color(0xFF4A148C),
    Color(0xFF0D47A1),
    Color(0xFF263238),
    Color(0xFF006064),
  ];

  /// Obtiene (o genera y cachea) los metadatos visuales para un thumbnail.
  ThumbnailMetadata getMetadata(String fileId) {
    if (_cache.containsKey(fileId)) {
      // Mover al final para política LRU.
      final metadata = _cache.remove(fileId)!;
      _cache[fileId] = metadata;
      return metadata;
    }

    final hash = _djb2Hash(fileId);
    final icon = _fileIcons[hash % _fileIcons.length];
    final backgroundColor = _backgroundColors[hash % _backgroundColors.length];
    final foregroundColor = _computeForegroundColor(backgroundColor);

    final metadata = ThumbnailMetadata(
      icon: icon,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );

    if (_cache.length >= _maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[fileId] = metadata;
    return metadata;
  }

  /// Limpia toda la caché.
  void clear() => _cache.clear();

  int _djb2Hash(String input) {
    var hash = 5381;
    final bytes = Uint8List.fromList(input.codeUnits);
    for (final byte in bytes) {
      hash = ((hash << 5) + hash) + byte; // hash * 33 + byte
    }
    return hash.abs();
  }

  Color _computeForegroundColor(Color background) {
    // Luminance relativa (ITU-R BT.709).
    final luminance =
        (0.299 * background.r + 0.587 * background.g + 0.114 * background.b);
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

/// Metadatos visuales cacheados de un thumbnail.
class ThumbnailMetadata {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const ThumbnailMetadata({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}
