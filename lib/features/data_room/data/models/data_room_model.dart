import 'package:equatable/equatable.dart';
import '../../domain/entities/data_room_entity.dart';

class DataRoomModel extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final String ownerId;
  final int maxViews;
  final int currentViews;
  final bool watermarkEnabled;
  final bool downloadEnabled;
  final List<String> allowedIPs;
  final Map<String, dynamic> metadata;

  const DataRoomModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.ownerId,
    this.maxViews = 0,
    this.currentViews = 0,
    this.watermarkEnabled = true,
    this.downloadEnabled = false,
    this.allowedIPs = const [],
    this.metadata = const {},
  });

  factory DataRoomModel.fromJson(Map<String, dynamic> json) {
    return DataRoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      ownerId: json['owner_id'] as String,
      maxViews: json['max_views'] as int? ?? 0,
      currentViews: json['current_views'] as int? ?? 0,
      watermarkEnabled: json['watermark_enabled'] as bool? ?? true,
      downloadEnabled: json['download_enabled'] as bool? ?? false,
      allowedIPs: (json['allowed_ips'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
      'owner_id': ownerId,
      'max_views': maxViews,
      'current_views': currentViews,
      'watermark_enabled': watermarkEnabled,
      'download_enabled': downloadEnabled,
      'allowed_ips': allowedIPs,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id, name, createdAt, expiresAt, isActive, ownerId,
        maxViews, currentViews, watermarkEnabled, downloadEnabled,
        allowedIPs, metadata,
      ];

  DataRoomEntity toEntity() {
    return DataRoomEntity(
      id: id,
      name: name,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isActive: isActive,
      ownerId: ownerId,
      maxViews: maxViews,
      currentViews: currentViews,
      watermarkEnabled: watermarkEnabled,
      downloadEnabled: downloadEnabled,
      allowedIPs: allowedIPs,
      metadata: metadata,
    );
  }
}
