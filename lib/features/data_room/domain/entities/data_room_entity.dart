import 'package:equatable/equatable.dart';

class DataRoomEntity extends Equatable {
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

  const DataRoomEntity({
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

  DataRoomEntity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    String? ownerId,
    int? maxViews,
    int? currentViews,
    bool? watermarkEnabled,
    bool? downloadEnabled,
    List<String>? allowedIPs,
    Map<String, dynamic>? metadata,
  }) {
    return DataRoomEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      ownerId: ownerId ?? this.ownerId,
      maxViews: maxViews ?? this.maxViews,
      currentViews: currentViews ?? this.currentViews,
      watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
      downloadEnabled: downloadEnabled ?? this.downloadEnabled,
      allowedIPs: allowedIPs ?? this.allowedIPs,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id, name, createdAt, expiresAt, isActive, ownerId,
        maxViews, currentViews, watermarkEnabled, downloadEnabled,
        allowedIPs, metadata,
      ];
}
