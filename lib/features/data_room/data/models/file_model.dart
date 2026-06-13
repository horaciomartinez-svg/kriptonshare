import 'package:equatable/equatable.dart';
import '../../domain/entities/file_entity.dart';

class FileModel extends Equatable {
  final String id;
  final String roomId;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String storagePath;
  final String ownerId;
  final bool isEncrypted;
  final String? encryptionKeyId;
  final Map<String, dynamic> metadata;

  const FileModel({
    required this.id,
    required this.roomId,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    required this.expiresAt,
    required this.storagePath,
    required this.ownerId,
    required this.isEncrypted,
    this.encryptionKeyId,
    this.metadata = const {},
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      name: json['name'] as String,
      mimeType: json['mime_type'] as String,
      sizeBytes: json['size_bytes'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      storagePath: json['storage_path'] as String,
      ownerId: json['owner_id'] as String,
      isEncrypted: json['is_encrypted'] as bool? ?? true,
      encryptionKeyId: json['encryption_key_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'name': name,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'storage_path': storagePath,
      'owner_id': ownerId,
      'is_encrypted': isEncrypted,
      'encryption_key_id': encryptionKeyId,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id, roomId, name, mimeType, sizeBytes, createdAt, expiresAt,
        storagePath, ownerId, isEncrypted, encryptionKeyId, metadata,
      ];

  FileEntity toEntity() {
    return FileEntity(
      id: id,
      name: name,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
      expiresAt: expiresAt,
      storagePath: storagePath,
      ownerId: ownerId,
      isEncrypted: isEncrypted,
      encryptionKeyId: encryptionKeyId,
      metadata: metadata,
    );
  }
}
