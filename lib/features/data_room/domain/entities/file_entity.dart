import 'package:flutter/foundation.dart';

@immutable
class FileEntity {
  final String id;
  final String ownerId;
  final String? folderId; // null = archivo individual suelto
  final String originalFilename;
  final int fileSizeBytes;
  final String mimeType;
  final String storageObjectKey;
  final Map<String, dynamic> salt;
  final Map<String, dynamic> nonce;
  final Map<String, dynamic> macTag;
  final Map<String, dynamic> aesKeyEncrypted;
  final DateTime createdAt;

  const FileEntity({
    required this.id,
    required this.ownerId,
    this.folderId,
    required this.originalFilename,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.storageObjectKey,
    required this.salt,
    required this.nonce,
    required this.macTag,
    required this.aesKeyEncrypted,
    required this.createdAt,
  });

  /// Validación cliente del límite por archivo Premium (100 MB)
  bool get isWithinPremiumLimit => fileSizeBytes <= (100 * 1024 * 1024);

  double get sizeInMB => fileSizeBytes / (1024 * 1024);
}
