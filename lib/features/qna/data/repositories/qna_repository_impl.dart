import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/i_qna_repository.dart';
import '../datasources/supabase_chat_datasource.dart';

/// Implementación del Repositorio Q&A usando Supabase Realtime.
class QnaRepositoryImpl implements IQnaRepository {
  final SupabaseChatDataSource _datasource;

  QnaRepositoryImpl(this._datasource);

  @override
  Future<void> sendMessage(ChatMessageEntity message) async {
    return await _datasource.sendMessage(message);
  }

  @override
  Future<List<ChatMessageEntity>> getMessagesByLinkId(String linkId) async {
    return await _datasource.getMessagesByLinkId(linkId);
  }

  @override
  Stream<ChatMessageEntity> watchMessages(String linkId) {
    return _datasource.watchMessages(linkId);
  }
}
