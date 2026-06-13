// lib/features/data_room/domain/entities/data_room_entity.dart

/// Entidad pura de Data Room (agnóstica de frameworks).
/// Representa la fuente de verdad de negocio.
class DataRoomEntity {
  final String id;
  final String ownerId;
  final String originalFilename;
  final int fileSizeBytes;
  final String status;
  final DateTime expiresAt;
  final String? storageObjectKey;
  final String? mimeType;
  final int? maxDownloads;
  final int downloadsCount;

  const DataRoomEntity({
    required this.id,
    required this.ownerId,
    required this.originalFilename,
    required this.fileSizeBytes,
    required this.status,
    required this.expiresAt,
    this.storageObjectKey,
    this.mimeType,
    this.maxDownloads,
    this.downloadsCount = 0,
  });

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isActive => status == 'active' && !isExpired;
  bool get canDownload => isActive && (maxDownloads == null || downloadsCount < maxDownloads!);

  DataRoomEntity copyWith({
    String? id,
    String? ownerId,
    String? originalFilename,
    int? fileSizeBytes,
    String? status,
    DateTime? expiresAt,
    String? storageObjectKey,
    String? mimeType,
    int? maxDownloads,
    int? downloadsCount,
  }) {
    return DataRoomEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      originalFilename: originalFilename ?? this.originalFilename,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      storageObjectKey: storageObjectKey ?? this.storageObjectKey,
      mimeType: mimeType ?? this.mimeType,
      maxDownloads: maxDownloads ?? this.maxDownloads,
      downloadsCount: downloadsCount ?? this.downloadsCount,
    );
  }
}
