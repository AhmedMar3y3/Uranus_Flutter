import '../../profile/data/user_mapper.dart';
import '../domain/entities/conversation.dart';
import 'message_mapper.dart';

class ConversationMapper {
  static Conversation fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    String? currentUsername,
  }) {
    final lastMessage = json['last_message'] is Map<String, dynamic>
        ? MessageMapper.fromJson(
            json['last_message'] as Map<String, dynamic>,
            currentUserId: currentUserId,
            currentUsername: currentUsername,
          )
        : null;

    return Conversation(
      id: json['id']?.toString() ?? '',
      friend: UserMapper.fromJson(json['friend'] as Map<String, dynamic>),
      unreadCount: json['unread_messages_count'] as int? ?? 0,
      latestTimestamp: UserMapper.fromJson({
        'username': 'time',
        'full_name': 'time',
        'last_seen': json['last_message_timestamp'],
      }).lastSeen,
      latestMessage: lastMessage,
      messages: lastMessage == null ? const [] : [lastMessage],
    );
  }
}
