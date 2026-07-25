import 'package:flutter/foundation.dart';
import '../../../../models/kripton_file.dart';

@immutable
class FolderEntity {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final List<KriptonFile> files;
  final int totalSizeBytes;
  final DateTime createdAt;
  final bool isDeleted;

  const FolderEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.files = const [],
    this.totalSizeBytes = 0,
    required this.createdAt,
    this.isDeleted = false,
  });

  FolderEntity copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    List<KriptonFile>? files,
    int? totalSizeBytes,
    DateTime? createdAt,
    bool? isDeleted,
  }) {
    return FolderEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      files: files ?? this.files,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  bool get isOverLimit => totalSizeBytes > (1024 * 1024 * 1024); // > 1 GB base
  int get fileCount => files.length;
}
