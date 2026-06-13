import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/i_qna_repository.dart';

/// Estado del Q&A Contextual por link_id.
class QnaState {
  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final String? error;

  const QnaState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  QnaState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    String? error,
  }) {
    return QnaState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier de Q&A con Supabase Realtime (WebSockets).
class QnaNotifier extends StateNotifier<QnaState> {
  final SupabaseClient _supabase;
  final String _linkId;
  RealtimeChannel? _channel;

  QnaNotifier({
    required SupabaseClient supabase,
    required String linkId,
  })  : _supabase = supabase,
        _linkId = linkId,
        super(const QnaState(isLoading: true));

  /// Inicializa el stream de mensajes y suscripción Realtime.
  Future<void> initialize() async {
    await _loadMessages();
    _subscribeToRealtime();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('link_id', _linkId)
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((json) => ChatMessageEntity.fromJson(json))
          .toList();

      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void _subscribeToRealtime() {
    _channel = _supabase
        .channel('chat_messages:$_linkId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'link_id',
            value: _linkId,
          ),
          callback: (payload) {
            final newMessage = ChatMessageEntity.fromJson(payload.newRecord);
            state = state.copyWith(
              messages: [...state.messages, newMessage],
            );
          },
        )
        .subscribe();
  }

  Future<void> sendMessage(String message, String authorEmail) async {
    try {
      await _supabase.from('chat_messages').insert({
        'link_id': _linkId,
        'author_email': authorEmail,
        'message': message,
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
