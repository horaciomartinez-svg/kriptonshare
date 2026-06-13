import '../../domain/entities/chat_message_entity.dart';

/// Interfaz de Repositorio Q&A (Capa de Dominio).
/// Define contrato para comunicación contextual en Data Rooms.
abstract class IQnaRepository {
  /// Enviar un mensaje a un hilo de discusión.
  Future<void> sendMessage(ChatMessageEntity message);

  /// Obtener historial de mensajes por link_id.
  Future<List<ChatMessageEntity>> getMessagesByLinkId(String linkId);

  /// Suscribirse a nuevos mensajes en tiempo real (Supabase Realtime).
  Stream<ChatMessageEntity> watchMessages(String linkId);
}
