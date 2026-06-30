import '../../../profile/domain/entities/app_user.dart';
import 'message.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.friend,
    required this.unreadCount,
    required this.latestTimestamp,
    this.messages = const [],
    this.latestMessage,
    this.isTyping = false,
  });

  final String id;
  final AppUser friend;
  final List<Message> messages;
  final Message? latestMessage;
  final int unreadCount;
  final String latestTimestamp;
  final bool isTyping;
}
