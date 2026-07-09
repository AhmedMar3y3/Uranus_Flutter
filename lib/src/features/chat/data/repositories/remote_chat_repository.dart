import '../../../../core/network/api_client.dart';
import '../../../../core/session/session_manager.dart';
import '../../../e2ee/data/e2ee_service.dart';
import '../../../profile/data/user_mapper.dart';
import '../../../profile/domain/entities/app_user.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_page.dart';
import '../../domain/repositories/chat_repository.dart';
import '../conversation_mapper.dart';
import '../message_mapper.dart';

class RemoteChatRepository implements ChatRepository {
  const RemoteChatRepository({
    required this.apiClient,
    required this.sessionManager,
    required this.e2eeService,
  });

  final ApiClient apiClient;
  final SessionManager sessionManager;
  final E2eeService e2eeService;

  @override
  Future<List<Conversation>> getConversations() async {
    final json = await apiClient.get('/home', query: {'per_page': '30'});
    final identity = await _currentIdentity();
    final conversations = json['conversations'] as List<dynamic>? ?? const [];
    final mapped = conversations
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => ConversationMapper.fromJson(
            item,
            currentUserId: identity.id,
            currentUsername: identity.username,
          ),
        )
        .toList();
    return Future.wait(mapped.map(_decryptConversationPreview));
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final page = await getMessagePage(
      conversationId: conversationId,
      page: 1,
      perPage: 30,
    );
    return page.messages;
  }

  @override
  Future<MessagePage> getMessagePage({
    required String conversationId,
    int page = 1,
    int perPage = 30,
  }) async {
    final json = await apiClient.get(
      '/conversations/$conversationId/messages',
      query: {'page': '$page', 'per_page': '$perPage'},
    );
    final identity = await _currentIdentity();
    final messages = json['messages'] as List<dynamic>? ?? const [];
    final mapped = messages
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => MessageMapper.fromJson(
            item,
            currentUserId: identity.id,
            currentUsername: identity.username,
          ),
        )
        .toList()
      ..sort(_compareMessages);
    final pagination =
        json['pagination'] as Map<String, dynamic>? ?? const {};
    final currentPage = _paginationInt(
      pagination,
      'i_current_page',
      fallback: page,
    );
    final pageSize = _paginationInt(
      pagination,
      'i_per_page',
      fallback: perPage,
    );
    return MessagePage(
      messages: mapped,
      currentPage: currentPage,
      perPage: pageSize,
      totalPages: _paginationInt(
        pagination,
        'i_total_pages',
        fallback: mapped.isEmpty ? currentPage : currentPage + 1,
      ),
      totalObjects: _paginationInt(
        pagination,
        'i_total_objects',
        fallback: mapped.length,
      ),
      itemsOnPage: _paginationInt(
        pagination,
        'i_items_on_page',
        fallback: mapped.length,
      ),
    );
  }

  @override
  Future<Message> sendTextMessage({
    required String conversationId,
    required AppUser receiver,
    required String body,
    String? replyToMessageId,
  }) async {
    final identity = await _currentIdentity();
    final encrypted = await e2eeService.encryptText(
      conversationId: conversationId,
      senderId: identity.id ?? '',
      receiver: receiver,
      text: body,
    );
    final payload = encrypted.toJson();
    if (replyToMessageId != null && replyToMessageId.isNotEmpty) {
      payload['reply_to_message_id'] = replyToMessageId;
    }
    final json = await apiClient.post(
      '/conversations/$conversationId/messages',
      body: payload,
    );
    final message = MessageMapper.fromJson(
      json['message'] as Map<String, dynamic>,
      currentUserId: identity.id,
      currentUsername: identity.username,
    );
    return e2eeService.decryptMessage(message: message, friend: receiver);
  }

  @override
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
  }) async {
    final identity = await _currentIdentity();
    final encrypted = await e2eeService.encryptAttachment(
      conversationId: conversationId,
      senderId: identity.id ?? '',
      receiver: receiver,
      kind: type,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      caption: body,
      durationSeconds: durationSeconds,
    );
    final fields = encrypted.message.toJson().map(
      (key, value) => MapEntry(key, value.toString()),
    );
    if (replyToMessageId != null) {
      fields['reply_to_message_id'] = replyToMessageId;
    }
    if (durationSeconds != null) {
      fields['duration_seconds'] = durationSeconds.toString();
    }
    final json = await apiClient.multipart(
      '/conversations/$conversationId/messages',
      fields: fields,
      byteFiles: {
        'attachment': MultipartBytesFile(
          bytes: encrypted.encryptedFileBytes,
          filename: encrypted.encryptedFileName,
        ),
      },
    );
    final message = MessageMapper.fromJson(
      json['message'] as Map<String, dynamic>,
      currentUserId: identity.id,
      currentUsername: identity.username,
    );
    return e2eeService.decryptMessage(message: message, friend: receiver);
  }

  @override
  Future<Message> editMessage({
    required String conversationId,
    required AppUser receiver,
    required String messageId,
    required String body,
  }) async {
    final identity = await _currentIdentity();
    final encrypted = await e2eeService.encryptText(
      conversationId: conversationId,
      senderId: identity.id ?? '',
      receiver: receiver,
      text: body,
    );
    final json = await apiClient.put(
      '/conversations/$conversationId/messages/$messageId',
      body: encrypted.toJson(),
    );
    final message = MessageMapper.fromJson(
      json['message'] as Map<String, dynamic>,
      currentUserId: identity.id,
      currentUsername: identity.username,
    );
    return e2eeService.decryptMessage(message: message, friend: receiver);
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

  Future<Conversation> _decryptConversationPreview(
    Conversation conversation,
  ) async {
    final latest = conversation.latestMessage;
    if (latest == null) {
      return conversation;
    }
    final decrypted = await e2eeService.decryptMessage(
      message: latest,
      friend: conversation.friend,
    );
    return conversation.copyWith(
      latestMessage: decrypted,
      messages: [decrypted],
    );
  }

  int _compareMessages(Message a, Message b) {
    final byTime = a.sortKey.compareTo(b.sortKey);
    if (byTime != 0) {
      return byTime;
    }
    final aId = int.tryParse(a.id);
    final bId = int.tryParse(b.id);
    if (aId != null && bId != null) {
      return aId.compareTo(bId);
    }
    return a.id.compareTo(b.id);
  }

  int _paginationInt(
    Map<String, dynamic> pagination,
    String key, {
    required int fallback,
  }) {
    final value = pagination[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}
