import '../entities/conversation.dart';
import '../entities/message.dart';

abstract interface class ChatRepository {
  Future<List<Conversation>> getConversations();
  Future<List<Message>> getMessages(String conversationId);
  Future<Message> sendTextMessage({
    required String conversationId,
    required String body,
    String? replyToMessageId,
  });
  Future<Message> sendAttachmentMessage({
    required String conversationId,
    required MessageKind type,
    required String filePath,
    String? body,
    String? replyToMessageId,
    int? durationSeconds,
  });
  Future<Message> editMessage({
    required String conversationId,
    required String messageId,
    required String body,
  });
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  });
  Future<Conversation> startConversation(String userId);
  Future<void> sendTyping({
    required String conversationId,
    required bool isTyping,
  });
  Future<Message> markMessageDelivered({
    required String conversationId,
    required String messageId,
  });
  Future<Message> markMessageSeen({
    required String conversationId,
    required String messageId,
  });
}
