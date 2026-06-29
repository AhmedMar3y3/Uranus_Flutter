import '../entities/conversation.dart';

abstract interface class ChatRepository {
  Future<List<Conversation>> getConversations();
}
