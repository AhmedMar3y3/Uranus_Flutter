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

  Conversation copyWith({
    String? id,
    AppUser? friend,
    List<Message>? messages,
    Message? latestMessage,
    int? unreadCount,
    String? latestTimestamp,
    bool? isTyping,
  }) {
    return Conversation(
      id: id ?? this.id,
      friend: friend ?? this.friend,
      messages: messages ?? this.messages,
      latestMessage: latestMessage ?? this.latestMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      latestTimestamp: latestTimestamp ?? this.latestTimestamp,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}
