import 'package:flutter/foundation.dart';
import 'file_entity.dart';

@immutable
class FolderEntity {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final List<FileEntity> files;
  final int totalSizeBytes;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FolderEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.files = const [],
    required this.totalSizeBytes,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Capacidad usada en megabytes
  double get totalSizeInMB => totalSizeBytes / (1024 * 1024);

  /// Porcentaje consumido respecto al límite base de 1 GB
  double get storagePercentage =>
      (totalSizeBytes / 1073741824).clamp(0.0, 1.0);

  FolderEntity copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    List<FileEntity>? files,
    int? totalSizeBytes,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FolderEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      files: files ?? this.files,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
