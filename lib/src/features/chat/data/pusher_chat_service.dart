import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_manager.dart';
import '../domain/entities/message.dart';
import 'message_mapper.dart';

typedef ChatMessageHandler = void Function(Message message);
typedef ChatMessageDeleteHandler = void Function(String messageId);
typedef ChatMessageStatusHandler =
    void Function(String messageId, MessageDelivery delivery);
typedef ChatTypingHandler = void Function(String userId, bool isTyping);

class PusherChatService {
  PusherChatService({required this.sessionManager, http.Client? httpClient})
    : httpClient = httpClient ?? http.Client();

  static const _apiKey = '534559ac5ee7c164b2a9';
  static const _cluster = 'eu';
  static const _authEndpoint = '${ApiConfig.baseUrl}/broadcasting/auth';

  final SessionManager sessionManager;
  final http.Client httpClient;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  bool _initialized = false;
  bool _connected = false;
  final Set<String> _channels = {};
  final Map<String, _ConversationHandlers> _handlers = {};

  Future<void> subscribeToConversation({
    required String conversationId,
    required ChatMessageHandler onMessageSent,
    required ChatMessageHandler onMessageEdited,
    required ChatMessageDeleteHandler onMessageDeleted,
    required ChatMessageStatusHandler onMessageStatusChanged,
    required ChatTypingHandler onTypingChanged,
  }) async {
    if (conversationId.isEmpty || !await sessionManager.hasToken) {
      return;
    }

    await _initialize();
    final channelName = 'private-conversations.$conversationId';
    _handlers[channelName] = _ConversationHandlers(
      onMessageSent: onMessageSent,
      onMessageEdited: onMessageEdited,
      onMessageDeleted: onMessageDeleted,
      onMessageStatusChanged: onMessageStatusChanged,
      onTypingChanged: onTypingChanged,
    );

    if (!_channels.contains(channelName)) {
      await _pusher.subscribe(channelName: channelName);
      _channels.add(channelName);
    }

    if (!_connected) {
      await _pusher.connect();
      _connected = true;
    }
  }

  Future<void> unsubscribeFromConversation(String conversationId) async {
    final channelName = 'private-conversations.$conversationId';
    _handlers.remove(channelName);
    if (!_channels.remove(channelName)) {
      return;
    }
    await _pusher.unsubscribe(channelName: channelName);
  }

  Future<void> _initialize() async {
    if (_initialized) {
      return;
    }
    await _pusher.init(
      apiKey: _apiKey,
      cluster: _cluster,
      useTLS: true,
      onAuthorizer: _authorize,
      onEvent: _handleEvent,
    );
    _initialized = true;
  }

  Future<void> _handleEvent(PusherEvent event) async {
    final handlers = _handlers[event.channelName];
    if (handlers == null) {
      return;
    }

    final payload = _payload(event.data);

    switch (event.eventName) {
      case 'message.sent':
        final message = await _messageFromPayload(payload);
        if (message == null) {
          return;
        }
        handlers.onMessageSent(message);
      case 'message.edited':
        final message = await _messageFromPayload(payload);
        if (message == null) {
          return;
        }
        handlers.onMessageEdited(message);
      case 'message.delivered':
        final messageId = _messageId(payload);
        if (messageId.isNotEmpty) {
          handlers.onMessageStatusChanged(messageId, MessageDelivery.delivered);
        }
      case 'message.seen':
        final messageId = _messageId(payload);
        if (messageId.isNotEmpty) {
          handlers.onMessageStatusChanged(messageId, MessageDelivery.seen);
        }
      case 'message.deleted':
        final messageId = _messageId(payload);
        if (messageId.isNotEmpty) {
          handlers.onMessageDeleted(messageId);
        }
      case 'typing.changed':
        final userId = payload['user_id']?.toString() ?? '';
        if (userId.isNotEmpty) {
          handlers.onTypingChanged(userId, payload['is_typing'] == true);
        }
    }
  }

  Future<Message?> _messageFromPayload(Map<String, dynamic> payload) async {
    final messageJson = payload['message'];
    if (messageJson is! Map<String, dynamic>) {
      return null;
    }

    return MessageMapper.fromJson(
      messageJson,
      currentUserId: await sessionManager.userId,
      currentUsername:
          await sessionManager.username ??
          await sessionManager.usernameFromEmail,
    );
  }

  String _messageId(Map<String, dynamic> payload) {
    final messageJson = payload['message'];
    if (messageJson is Map<String, dynamic>) {
      return messageJson['id']?.toString() ?? '';
    }
    return '';
  }

  Future<Map<String, dynamic>> _authorize(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    final token = await sessionManager.token;
    if (token == null || token.isEmpty) {
      throw const ApiException('Please login again.');
    }

    final response = await httpClient
        .post(
          Uri.parse(_authEndpoint),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {'socket_id': socketId, 'channel_name': channelName},
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode >= 400) {
      throw ApiException(
        'Could not authorize live chat.',
        code: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const ApiException('Unexpected Pusher auth response.');
  }

  Map<String, dynamic> _payload(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return <String, dynamic>{};
  }
}

class _ConversationHandlers {
  const _ConversationHandlers({
    required this.onMessageSent,
    required this.onMessageEdited,
    required this.onMessageDeleted,
    required this.onMessageStatusChanged,
    required this.onTypingChanged,
  });

  final ChatMessageHandler onMessageSent;
  final ChatMessageHandler onMessageEdited;
  final ChatMessageDeleteHandler onMessageDeleted;
  final ChatMessageStatusHandler onMessageStatusChanged;
  final ChatTypingHandler onTypingChanged;
}
