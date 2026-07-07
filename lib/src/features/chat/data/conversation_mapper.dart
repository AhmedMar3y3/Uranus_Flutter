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
      friend: UserMapper.fromJson(
        _friendJson(
          json,
          currentUserId: currentUserId,
          currentUsername: currentUsername,
        ),
      ),
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

  static Map<String, dynamic> _friendJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    String? currentUsername,
  }) {
    for (final key in ['friend', 'other_user', 'user']) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }

    final participants = json['participants'] ?? json['users'];
    if (participants is List) {
      final mapped = participants.whereType<Map<String, dynamic>>().map((row) {
        final user = row['user'];
        return user is Map<String, dynamic> ? user : row;
      });
      for (final user in mapped) {
        final id = user['id']?.toString();
        final username = user['username']?.toString();
        if ((currentUserId == null || id != currentUserId) &&
            (currentUsername == null || username != currentUsername)) {
          return user;
        }
      }
    }

    return <String, dynamic>{};
  }
}
