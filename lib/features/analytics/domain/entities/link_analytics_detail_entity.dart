import 'package:equatable/equatable.dart';

/// Detalle analítico de un link para el dashboard de "Active Links".
class LinkAnalyticsDetailEntity extends Equatable {
  final String linkId;
  final String? fileName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final int views;
  final int totalViewDurationMs;
  final Map<int, PageAnalyticsEntity> pages;

  const LinkAnalyticsDetailEntity({
    required this.linkId,
    this.fileName,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.views,
    required this.totalViewDurationMs,
    this.pages = const {},
  });

  @override
  List<Object?> get props => [
        linkId,
        fileName,
        createdAt,
        expiresAt,
        isActive,
        views,
        totalViewDurationMs,
        pages,
      ];
}

/// Métricas de una página individual dentro de un link (PDF/data room).
class PageAnalyticsEntity extends Equatable {
  final int pageNumber;
  final int views;
  final int durationMs;

  const PageAnalyticsEntity({
    required this.pageNumber,
    required this.views,
    required this.durationMs,
  });

  @override
  List<Object?> get props => [pageNumber, views, durationMs];
}