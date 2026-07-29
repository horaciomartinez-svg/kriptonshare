import 'package:equatable/equatable.dart';

/// Entidad legacy de archivo para Data Rooms locales efímeros.
/// Conservada para no romper el repositorio de data rooms histórico.
class LegacyFileEntity extends Equatable {
  final String id;
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

  const LegacyFileEntity({
    required this.id,
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

  @override
  List<Object?> get props => [
        id, name, mimeType, sizeBytes, createdAt, expiresAt,
        storagePath, ownerId, isEncrypted, encryptionKeyId, metadata,
      ];
}
