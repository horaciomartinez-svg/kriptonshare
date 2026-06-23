import 'package:equatable/equatable.dart';

/// Entidad de un link compartido (share_link) en KRIPTONSHARE.
class LinkEntity extends Equatable {
  final String id;
  final String fileId;
  final String createdBy;
  final String? preSignedUrlHash;
  final DateTime expiresAt;
  final int accessCount;
  final DateTime? lastAccessedAt;
  final String? recipientEmail;
  final bool isActive;
  final DateTime createdAt;

  const LinkEntity({
    required this.id,
    required this.fileId,
    required this.createdBy,
    this.preSignedUrlHash,
    required this.expiresAt,
    this.accessCount = 0,
    this.lastAccessedAt,
    this.recipientEmail,
    this.isActive = true,
    required this.createdAt,
  });

  factory LinkEntity.fromJson(Map<String, dynamic> json) {
    return LinkEntity(
      id: json['id'] as String,
      fileId: json['file_id'] as String,
      createdBy: json['created_by'] as String,
      preSignedUrlHash: json['pre_signed_url_hash'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      accessCount: json['access_count'] as int? ?? 0,
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(json['last_accessed_at'] as String)
          : null,
      recipientEmail: json['recipient_email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_id': fileId,
      'created_by': createdBy,
      'pre_signed_url_hash': preSignedUrlHash,
      'expires_at': expiresAt.toIso8601String(),
      'access_count': accessCount,
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
      'recipient_email': recipientEmail,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LinkEntity copyWith({
    String? id,
    String? fileId,
    String? createdBy,
    String? preSignedUrlHash,
    DateTime? expiresAt,
    int? accessCount,
    DateTime? lastAccessedAt,
    String? recipientEmail,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return LinkEntity(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      createdBy: createdBy ?? this.createdBy,
      preSignedUrlHash: preSignedUrlHash ?? this.preSignedUrlHash,
      expiresAt: expiresAt ?? this.expiresAt,
      accessCount: accessCount ?? this.accessCount,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  bool get isActiveAndNotExpired => isActive && !isExpired;

  @override
  List<Object?> get props => [
        id,
        fileId,
        createdBy,
        preSignedUrlHash,
        expiresAt,
        accessCount,
        lastAccessedAt,
        recipientEmail,
        isActive,
        createdAt,
      ];
}
