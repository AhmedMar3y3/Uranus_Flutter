import '../../../../core/network/api_client.dart';
import '../../../../core/session/session_manager.dart';
import '../../../profile/data/user_mapper.dart';
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
    final identity = await _currentIdentity();
    final conversations = json['conversations'] as List<dynamic>? ?? const [];
    return conversations
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => ConversationMapper.fromJson(
            item,
            currentUserId: identity.id,
            currentUsername: identity.username,
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
    final identity = await _currentIdentity();
    final messages = json['messages'] as List<dynamic>? ?? const [];
    return messages
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => MessageMapper.fromJson(
            item,
            currentUserId: identity.id,
            currentUsername: identity.username,
          ),
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
    final payload = <String, dynamic>{'type': 'text', 'body': body};
    if (replyToMessageId != null && replyToMessageId.isNotEmpty) {
      payload['reply_to_message_id'] = replyToMessageId;
    }
    final json = await apiClient.post(
      '/conversations/$conversationId/messages',
      body: payload,
    );
    final identity = await _currentIdentity();
    return MessageMapper.fromJson(
      json['message'] as Map<String, dynamic>,
      currentUserId: identity.id,
      currentUsername: identity.username,
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
    final identity = await _currentIdentity();
    return MessageMapper.fromJson(
      json['message'] as Map<String, dynamic>,
      currentUserId: identity.id,
      currentUsername: identity.username,
    );
  }

  @override
  Future<Message> editMessage({
    required String conversationId,
    required String messageId,
    required String body,
  }) async {
    final json = await apiClient.put(
      '/conversations/$conversationId/messages/$messageId',
      body: {'body': body},
    );
    final identity = await _currentIdentity();
    return MessageMapper.fromJson(
      json['message'] as Map<String, dynamic>,
      currentUserId: identity.id,
      currentUsername: identity.username,
    );
  }

  @override
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await apiClient.deleteVoid(
      '/conversations/$conversationId/messages/$messageId',
    );
  }

  @override
  Future<Conversation> startConversation(String userId) async {
    final json = await apiClient.post(
      '/conversations',
      body: {'user_id': userId},
    );
    final identity = await _currentIdentity();
    return ConversationMapper.fromJson(
      json['conversation'] as Map<String, dynamic>,
      currentUserId: identity.id,
      currentUsername: identity.username,
    );
  }

  @override
  Future<void> sendTyping({
    required String conversationId,
    required bool isTyping,
  }) async {
    await apiClient.postVoid(
      '/conversations/$conversationId/typing',
      body: {'is_typing': isTyping},
    );
  }

  @override
  Future<Message> markMessageDelivered({
    required String conversationId,
    required String messageId,
  }) async {
    final json = await apiClient.post(
      '/conversations/$conversationId/messages/$messageId/delivered',
    );
    final identity = await _currentIdentity();
    return MessageMapper.fromJson(
      json['message'] as Map<String, dynamic>,
      currentUserId: identity.id,
      currentUsername: identity.username,
    );
  }

  @override
  Future<Message> markMessageSeen({
    required String conversationId,
    required String messageId,
  }) async {
    final json = await apiClient.post(
      '/conversations/$conversationId/messages/$messageId/seen',
    );
    final identity = await _currentIdentity();
    return MessageMapper.fromJson(
      json['message'] as Map<String, dynamic>,
      currentUserId: identity.id,
      currentUsername: identity.username,
    );
  }

  Future<({String? id, String? username})> _currentIdentity() async {
    var id = await sessionManager.userId;
    var username = await sessionManager.username;
    if ((id == null || id.isEmpty) || (username == null || username.isEmpty)) {
      try {
        final json = await apiClient.get('/profile/me');
        final user = UserMapper.fromJson(json['user'] as Map<String, dynamic>);
        await sessionManager.saveUserIdentity(
          id: user.id,
          username: user.username,
        );
        id = user.id;
        username = user.username;
      } catch (_) {
        username = await sessionManager.usernameFromEmail;
      }
    }
    return (id: id, username: username);
  }
}
