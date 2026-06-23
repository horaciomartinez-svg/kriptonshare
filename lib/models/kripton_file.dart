import 'dart:convert';

class KriptonFile {
  final String id;
  final String ownerId;
  final String originalFilename;
  final int fileSizeBytes;
  final String mimeType;
  final String storageProvider;
  final String bucketName;
  final String storageObjectKey;
  final List<int> aesKeyEncrypted;
  final List<int> salt;
  final List<int> nonce;
  final List<int> macTag;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int? maxDownloads;
  final int downloadsCount;
  final String status;

  // Campos opcionales del share_link (contexto de recepción)
  final String? linkId;
  final DateTime? linkExpiresAt;
  final String? recipientEmail;
  final bool? linkIsActive;

  KriptonFile({
    required this.id,
    required this.ownerId,
    required this.originalFilename,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.storageProvider,
    required this.bucketName,
    required this.storageObjectKey,
    this.aesKeyEncrypted = const [],
    this.salt = const [],
    this.nonce = const [],
    this.macTag = const [],
    required this.createdAt,
    required this.expiresAt,
    this.maxDownloads,
    this.downloadsCount = 0,
    this.status = 'active',
    this.linkId,
    this.linkExpiresAt,
    this.recipientEmail,
    this.linkIsActive,
  });

  factory KriptonFile.fromJson(Map<String, dynamic> json) {
    return KriptonFile(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      originalFilename: json['original_filename'] as String,
      fileSizeBytes: json['file_size_bytes'] as int,
      mimeType: json['mime_type'] as String,
      storageProvider: json['storage_provider'] as String,
      bucketName: json['bucket_name'] as String,
      storageObjectKey: json['storage_object_key'] as String,
      aesKeyEncrypted: _parseBytea(json['aes_key_encrypted']),
      salt: _parseBytea(json['salt']),
      nonce: _parseBytea(json['nonce']),
      macTag: _parseBytea(json['mac_tag']),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      maxDownloads: json['max_downloads'] as int?,
      downloadsCount: json['downloads_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      linkId: json['link_id'] as String?,
      linkExpiresAt: json['link_expires_at'] != null
          ? DateTime.parse(json['link_expires_at'] as String)
          : null,
      recipientEmail: json['recipient_email'] as String?,
      linkIsActive: json['is_active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'original_filename': originalFilename,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'storage_provider': storageProvider,
      'bucket_name': bucketName,
      'storage_object_key': storageObjectKey,
      'aes_key_encrypted': aesKeyEncrypted,
      'salt': salt,
      'nonce': nonce,
      'mac_tag': macTag,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'max_downloads': maxDownloads,
      'downloads_count': downloadsCount,
      'status': status,
      'link_id': linkId,
      'link_expires_at': linkExpiresAt?.toIso8601String(),
      'recipient_email': recipientEmail,
      'is_active': linkIsActive,
    };
  }

  /// Interpreta un campo BYTEA de Supabase que puede llegar en varios formatos:
  /// - `List<dynamic>` de enteros (JSON nativo)
  /// - `String` con un array JSON (ej. "[76, ...]")
  /// - `String` con hex `"\\x..."`
  /// - `String` base64
  static List<int> _parseBytea(dynamic value) {
    if (value == null) return const <int>[];
    if (value is List<dynamic>) return value.cast<int>();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const <int>[];

      // Formato JSON array literal: "[76, ...]"
      if (trimmed.startsWith('[')) {
        final parsed = jsonDecode(trimmed) as List<dynamic>;
        return parsed.cast<int>();
      }

      // Formato hex PostgreSQL: "\\xDEADBEEF"
      if (trimmed.startsWith(r'\x')) {
        final hex = trimmed.substring(2);
        if (hex.length.isOdd) {
          throw FormatException('Hex BYTEA con longitud impar: $trimmed');
        }
        final bytes = <int>[];
        for (var i = 0; i < hex.length; i += 2) {
          bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
        }
        return bytes;
      }

      // Base64
      try {
        return base64Decode(trimmed);
      } catch (_) {
        // Fall through to descriptive exception.
      }
    }
    throw FormatException('Formato BYTEA no soportado: $value (${value.runtimeType})');
  }
}

class ShareLink {
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

  ShareLink({
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

  factory ShareLink.fromJson(Map<String, dynamic> json) {
    return ShareLink(
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
}

class EncryptedPayload {
  final List<int> salt;
  final List<int> nonce;
  final List<int> ciphertext;
  final List<int> authTag;
  final List<int> aesKeyEncrypted;

  EncryptedPayload({
    required this.salt,
    required this.nonce,
    required this.ciphertext,
    required this.authTag,
    required this.aesKeyEncrypted,
  });

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) {
    return EncryptedPayload(
      salt: (json['salt'] as List<dynamic>).cast<int>(),
      nonce: (json['nonce'] as List<dynamic>).cast<int>(),
      ciphertext: (json['ciphertext'] as List<dynamic>).cast<int>(),
      authTag: (json['auth_tag'] as List<dynamic>).cast<int>(),
      aesKeyEncrypted: (json['aes_key_encrypted'] as List<dynamic>).cast<int>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salt': salt,
      'nonce': nonce,
      'ciphertext': ciphertext,
      'auth_tag': authTag,
      'aes_key_encrypted': aesKeyEncrypted,
    };
  }
}
