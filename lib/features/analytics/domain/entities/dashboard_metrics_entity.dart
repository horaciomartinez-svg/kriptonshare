import 'package:equatable/equatable.dart';

/// Entidad de métricas agregadas para el dashboard de analytics.
class DashboardMetricsEntity extends Equatable {
  final int totalLinks;
  final int activeLinks;
  final int expiredLinks;
  final int totalViews;
  final int totalDownloads;
  final double averageViewDurationMs;
  final int eventsLast24h;
  final int storageUsedBytes;
  final List<LinkMetric> topLinks;
  final DateTime generatedAt;

  const DashboardMetricsEntity({
    required this.totalLinks,
    required this.activeLinks,
    required this.expiredLinks,
    required this.totalViews,
    required this.totalDownloads,
    required this.averageViewDurationMs,
    required this.eventsLast24h,
    required this.storageUsedBytes,
    required this.topLinks,
    required this.generatedAt,
  });

  factory DashboardMetricsEntity.empty() {
    return DashboardMetricsEntity(
      totalLinks: 0,
      activeLinks: 0,
      expiredLinks: 0,
      totalViews: 0,
      totalDownloads: 0,
      averageViewDurationMs: 0.0,
      eventsLast24h: 0,
      storageUsedBytes: 0,
      topLinks: const [],
      generatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        totalLinks,
        activeLinks,
        expiredLinks,
        totalViews,
        totalDownloads,
        averageViewDurationMs,
        eventsLast24h,
        storageUsedBytes,
        topLinks,
        generatedAt,
      ];
}

/// Métrica individual por link.
class LinkMetric extends Equatable {
  final String linkId;
  final String? fileName;
  final int views;
  final int downloads;
  final DateTime? lastAccessedAt;

  const LinkMetric({
    required this.linkId,
    this.fileName,
    required this.views,
    required this.downloads,
    this.lastAccessedAt,
  });

  factory LinkMetric.fromJson(Map<String, dynamic> json) {
    return LinkMetric(
      linkId: json['link_id'] as String,
      fileName: json['file_name'] as String?,
      views: json['views'] as int? ?? 0,
      downloads: json['downloads'] as int? ?? 0,
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(json['last_accessed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'link_id': linkId,
      'file_name': fileName,
      'views': views,
      'downloads': downloads,
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [linkId, fileName, views, downloads, lastAccessedAt];
}
