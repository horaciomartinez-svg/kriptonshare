import 'package:equatable/equatable.dart';

/// Entidad de evento de telemetría (auditoría B2B).
/// Rastrea interacción del inversor: páginas escrutadas, tiempo de lectura.
class TelemetryEventEntity extends Equatable {
  final String? id;
  final String linkId;
  final String eventType; // page_view, download_start, download_complete, screenshot_blocked
  final int? pageNumber;
  final int durationMs;
  final int timestampMs;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? geolocation;
  final DateTime? createdAt;

  const TelemetryEventEntity({
    this.id,
    required this.linkId,
    required this.eventType,
    this.pageNumber,
    required this.durationMs,
    required this.timestampMs,
    this.ipAddress,
    this.userAgent,
    this.geolocation,
    this.createdAt,
  });

  factory TelemetryEventEntity.fromJson(Map<String, dynamic> json) {
    return TelemetryEventEntity(
      id: json['id']?.toString(),
      linkId: json['link_id'] as String,
      eventType: json['event_type'] as String,
      pageNumber: json['page_number'] as int?,
      durationMs: json['duration_ms'] as int,
      timestampMs: json['timestamp_ms'] as int,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      geolocation: json['geolocation'] as Map<String, dynamic>?,
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
      'geolocation': geolocation,
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
      ];
}
