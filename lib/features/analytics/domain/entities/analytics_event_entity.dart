import 'package:equatable/equatable.dart';

/// Entidad de evento de analytics para auditoría B2B.
/// Rastrea interacciones de los receptores con los links compartidos.
class AnalyticsEventEntity extends Equatable {
  final String? id;
  final String linkId;
  final String eventType; // page_view, download_start, download_complete, screenshot_blocked
  final int? pageNumber;
  final int durationMs;
  final int timestampMs;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;

  const AnalyticsEventEntity({
    this.id,
    required this.linkId,
    required this.eventType,
    this.pageNumber,
    required this.durationMs,
    required this.timestampMs,
    this.ipAddress,
    this.userAgent,
    this.createdAt,
  });

  factory AnalyticsEventEntity.fromJson(Map<String, dynamic> json) {
    return AnalyticsEventEntity(
      id: json['id']?.toString(),
      linkId: json['link_id'] as String,
      eventType: json['event_type'] as String,
      pageNumber: json['page_number'] as int?,
      durationMs: json['duration_ms'] as int,
      timestampMs: json['timestamp_ms'] as int,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'link_id': linkId,
      'event_type': eventType,
      'page_number': pageNumber,
      'duration_ms': durationMs,
      'timestamp_ms': timestampMs,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        linkId,
        eventType,
        pageNumber,
        durationMs,
        timestampMs,
        ipAddress,
        userAgent,
        createdAt,
      ];
}
