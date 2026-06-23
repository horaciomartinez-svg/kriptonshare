import 'package:equatable/equatable.dart';
import '../../domain/entities/analytics_event_entity.dart';

/// Modelo de datos para eventos de analytics.
class AnalyticsModel extends Equatable {
  final String? id;
  final String linkId;
  final String eventType;
  final int? pageNumber;
  final int durationMs;
  final int timestampMs;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;

  const AnalyticsModel({
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

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
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

  AnalyticsEventEntity toEntity() {
    return AnalyticsEventEntity(
      id: id,
      linkId: linkId,
      eventType: eventType,
      pageNumber: pageNumber,
      durationMs: durationMs,
      timestampMs: timestampMs,
      ipAddress: ipAddress,
      userAgent: userAgent,
      createdAt: createdAt,
    );
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
