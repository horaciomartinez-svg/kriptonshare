import 'package:flutter/foundation.dart';

enum ShareLinkType { singleFile, fullFolder }

@immutable
class ShareLinkEntity {
  final String id;
  final String createdBy;
  final String? fileId;    // XOR con folderId
  final String? folderId;  // XOR con fileId
  final ShareLinkType linkType;
  final bool isActive;
  final bool requireRecipientEmail;
  final bool enableWatermark;
  final DateTime expiresAt; // Premium: máximo now + 30 días
  final int accessCount;
  final DateTime createdAt;

  const ShareLinkEntity({
    required this.id,
    required this.createdBy,
    this.fileId,
    this.folderId,
    required this.linkType,
    required this.isActive,
    required this.requireRecipientEmail,
    required this.enableWatermark,
    required this.expiresAt,
    required this.accessCount,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// URL pública del enlace (la clave viaja en el fragmento #, nunca al servidor)
  String publicUrl(String secureFragment) =>
      linkType == ShareLinkType.fullFolder
          ? 'https://kriptonshare.com/f/$id#$secureFragment'
          : 'https://kriptonshare.com/d/$id#$secureFragment';
}
