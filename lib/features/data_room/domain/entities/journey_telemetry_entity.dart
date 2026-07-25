import 'package:flutter/foundation.dart';

@immutable
class JourneyTelemetryEntity {
  final String? id;
  final String shareLinkId;
  final String? fileId;
  final String? recipientEmail;
  final String? recipientIp;
  final String eventType;
  final int? pageNumber;
  final int durationMs;
  final DateTime createdAt;

  const JourneyTelemetryEntity({
    this.id,
    required this.shareLinkId,
    this.fileId,
    this.recipientEmail,
    this.recipientIp,
    required this.eventType,
    this.pageNumber,
    this.durationMs = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'share_link_id': shareLinkId,
      'file_id': fileId,
      'recipient_email': recipientEmail,
      'recipient_ip': recipientIp,
      'event_type': eventType,
      'page_number': pageNumber,
      'duration_ms': durationMs,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory JourneyTelemetryEntity.fromJson(Map<String, dynamic> json) {
    return JourneyTelemetryEntity(
      id: json['id'] as String?,
      shareLinkId: json['share_link_id'] as String,
      fileId: json['file_id'] as String?,
      recipientEmail: json['recipient_email'] as String?,
      recipientIp: json['recipient_ip'] as String?,
      eventType: json['event_type'] as String,
      pageNumber: json['page_number'] as int?,
      durationMs: json['duration_ms'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
