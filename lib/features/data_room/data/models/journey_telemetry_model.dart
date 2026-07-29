import '../../domain/entities/journey_telemetry_entity.dart';

class JourneyTelemetryModel {
  final String? id;
  final String shareLinkId;
  final String? fileId;
  final String? recipientEmail;
  final String? recipientIp;
  final String eventType;
  final int? pageNumber;
  final int durationMs;
  final DateTime createdAt;

  JourneyTelemetryModel({
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

  factory JourneyTelemetryModel.fromJson(Map<String, dynamic> json) {
    return JourneyTelemetryModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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

  JourneyTelemetryEntity toEntity() {
    return JourneyTelemetryEntity(
      id: id,
      shareLinkId: shareLinkId,
      fileId: fileId,
      recipientEmail: recipientEmail,
      recipientIp: recipientIp,
      eventType: eventType,
      pageNumber: pageNumber,
      durationMs: durationMs,
      createdAt: createdAt,
    );
  }
}
