import '../../../../core/network/api_client.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../conversation_mapper.dart';
import '../message_mapper.dart';

class RemoteChatRepository implements ChatRepository {
  const RemoteChatRepository({
    required this.apiClient,
    required this.sessionManager,
  });

  final ApiClient apiClient;
  final SessionManager sessionManager;

  @override
  Future<List<Conversation>> getConversations() async {
    final json = await apiClient.get('/home', query: {'per_page': '30'});
    final currentUsername = await sessionManager.usernameFromEmail;
    final conversations = json['conversations'] as List<dynamic>? ?? const [];
    return conversations
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => ConversationMapper.fromJson(
            item,
            currentUsername: currentUsername,
          ),
        )
        .toList();
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final json = await apiClient.get(
      '/conversations/$conversationId/messages',
      query: {'per_page': '50'},
    );
    final currentUsername = await sessionManager.usernameFromEmail;
    final messages = json['messages'] as List<dynamic>? ?? const [];
    return messages
        .whereType<Map<String, dynamic>>()
        .map(
          (item) =>
              MessageMapper.fromJson(item, currentUsername: currentUsername),
        )
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Future<Message> sendTextMessage({
    required String conversationId,
    required String body,
    String? replyToMessageId,
  }) async {
    final json = await apiClient.post(
      '/conversations/$conversationId/messages',
      body: {
        'type': 'text',
        'body': body,
        'reply_to_message_id': replyToMessageId,
      },
    );
    return MessageMapper.fromJson(
      json['message'] as Map<String, dynamic>,
      currentUsername: await sessionManager.usernameFromEmail,
    );
  }

  @override
  Future<Message> sendAttachmentMessage({
    required String conversationId,
    required MessageKind type,
    required String filePath,
    String? body,
    String? replyToMessageId,
    int? durationSeconds,
  }) async {
    final fields = <String, String>{'type': type.name};
    if (body != null && body.isNotEmpty) {
      fields['body'] = body;
    }
    if (replyToMessageId != null) {
      fields['reply_to_message_id'] = replyToMessageId;
    }
    if (durationSeconds != null) {
      fields['duration_seconds'] = durationSeconds.toString();
    }
    final json = await apiClient.multipart(
      '/conversations/$conversationId/messages',
      fields: fields,
      filePaths: {'attachment': filePath},
    );
    return MessageMapper.fromJson(
      json['message'] as Map<String, dynamic>,
      currentUsername: await sessionManager.usernameFromEmail,
    );
  }

  @override
  Future<Conversation> startConversation(String userId) async {
    final json = await apiClient.post(
      '/conversations',
      body: {'user_id': userId},
    );
    return ConversationMapper.fromJson(
      json['conversation'] as Map<String, dynamic>,
      currentUsername: await sessionManager.usernameFromEmail,
    );
  }

  @override
  Future<void> sendTyping({
    required String conversationId,
    required bool isTyping,
  }) async {
    await apiClient.post(
      '/conversations/$conversationId/typing',
      body: {'is_typing': isTyping},
    );
  }
}
