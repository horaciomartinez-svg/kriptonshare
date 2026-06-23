import 'package:equatable/equatable.dart';

/// Resultado de una subida exitosa de archivo cifrado.
class UploadResultEntity extends Equatable {
  final String linkId;
  final String fileId;
  final String createdBy;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String shareUrl;
  final String? recipientEmail;

  const UploadResultEntity({
    required this.linkId,
    required this.fileId,
    required this.createdBy,
    required this.expiresAt,
    required this.createdAt,
    required this.shareUrl,
    this.recipientEmail,
  });

  factory UploadResultEntity.fromJson(Map<String, dynamic> json) {
    return UploadResultEntity(
      linkId: json['link_id'] as String,
      fileId: json['file_id'] as String,
      createdBy: json['created_by'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      shareUrl: json['share_url'] as String,
      recipientEmail: json['recipient_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'link_id': linkId,
      'file_id': fileId,
      'created_by': createdBy,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'share_url': shareUrl,
      'recipient_email': recipientEmail,
    };
  }

  @override
  List<Object?> get props => [
        linkId,
        fileId,
        createdBy,
        expiresAt,
        createdAt,
        shareUrl,
        recipientEmail,
      ];
}
