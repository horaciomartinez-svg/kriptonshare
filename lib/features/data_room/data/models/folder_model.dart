import '../../domain/entities/folder_entity.dart';
import '../../domain/entities/file_entity.dart';

class FolderModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FileEntity> files;

  FolderModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.files = const [],
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FolderEntity toEntity() {
    return FolderEntity(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      files: files,
      totalSizeBytes: files.fold<int>(0, (sum, f) => sum + f.fileSizeBytes),
      isDeleted: isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
