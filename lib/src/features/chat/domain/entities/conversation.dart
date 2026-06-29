import '../../../profile/domain/entities/app_user.dart';
import 'message.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.friend,
    required this.messages,
    required this.unreadCount,
    required this.latestTimestamp,
    this.isTyping = false,
  });

  final String id;
  final AppUser friend;
  final List<Message> messages;
  final int unreadCount;
  final String latestTimestamp;
  final bool isTyping;

  Message? get latestMessage => messages.isEmpty ? null : messages.last;
}
