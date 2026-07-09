import '../entities/conversation.dart';
import '../entities/message.dart';
import '../entities/message_page.dart';
import '../../../profile/domain/entities/app_user.dart';

abstract interface class ChatRepository {
  Future<List<Conversation>> getConversations();
  Future<List<Message>> getMessages(String conversationId);
  Future<MessagePage> getMessagePage({
    required String conversationId,
    int page = 1,
    int perPage = 30,
  });
  Future<Message> sendTextMessage({
    required String conversationId,
    required AppUser receiver,
    required String body,
    String? replyToMessageId,
  });
  Future<Message> sendAttachmentMessage({
    required String conversationId,
    required AppUser receiver,
    required MessageKind type,
    required String filePath,
    required String fileName,
    required int fileSize,
    String? body,
    String? replyToMessageId,
    int? durationSeconds,
  });
  Future<Message> editMessage({
    required String conversationId,
    required AppUser receiver,
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
