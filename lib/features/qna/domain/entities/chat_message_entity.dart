import 'package:equatable/equatable.dart';

/// Entidad pura de mensaje de chat (Q&A Contextual).
/// Agnóstica de frameworks. Purga automática a las 48h en Supabase.
class ChatMessageEntity extends Equatable {
  final String id;
  final String linkId;
  final String authorEmail;
  final String message;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.linkId,
    required this.authorEmail,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return ChatMessageEntity(
      id: json['id'] as String,
      linkId: json['link_id'] as String,
      authorEmail: json['author_email'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'link_id': linkId,
      'author_email': authorEmail,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, linkId, authorEmail, message, createdAt];
}
