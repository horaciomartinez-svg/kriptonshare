import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_message_entity.dart';
class SupabaseChatDataSource {
  final SupabaseClient _supabase;

  SupabaseChatDataSource(this._supabase);

  Future<void> sendMessage(ChatMessageEntity message) async {
    await _supabase.from('chat_messages').insert({
      'link_id': message.linkId,
      'author_email': message.authorEmail,
      'message': message.message,
    });
  }

  Future<List<ChatMessageEntity>> getMessagesByLinkId(String linkId) async {
    final response = await _supabase
        .from('chat_messages')
        .select()
        .eq('link_id', linkId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => ChatMessageEntity.fromJson(json))
        .toList();
  }

  Stream<ChatMessageEntity> watchMessages(String linkId) {
    final controller = StreamController<ChatMessageEntity>.broadcast();

    final channel = _supabase
        .channel('chat_messages:$linkId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'link_id',
            value: linkId,
          ),
          callback: (payload) {
            final message = ChatMessageEntity.fromJson(payload.newRecord);
            controller.add(message);
          },
        )
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }
}

import 'dart:async';
