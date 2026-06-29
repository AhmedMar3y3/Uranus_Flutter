import '../../profile/data/mock_users.dart';
import '../domain/entities/conversation.dart';
import '../domain/entities/message.dart';

class MockConversations {
  static final conversations = [
    Conversation(
      id: 'c-1',
      friend: MockUsers.users[0],
      unreadCount: 2,
      latestTimestamp: '2m',
      isTyping: true,
      messages: [
        const Message(
          id: 'm-1',
          senderId: 'u-1',
          body: 'Are we still testing the static flow tonight?',
          sentAt: '8:18 PM',
          isMine: false,
        ),
        const Message(
          id: 'm-2',
          senderId: 'u-0',
          body: 'Yes. I am polishing the chat states first.',
          sentAt: '8:20 PM',
          isMine: true,
          delivery: MessageDelivery.seen,
        ),
      ],
    ),
    Conversation(
      id: 'c-2',
      friend: MockUsers.users[3],
      unreadCount: 0,
      latestTimestamp: '14m',
      messages: [
        const Message(
          id: 'm-3',
          senderId: 'u-4',
          body: 'Shared the onboarding draft.',
          sentAt: '7:56 PM',
          isMine: false,
          kind: MessageKind.file,
          attachment: MessageAttachment(
            name: 'uranus-onboarding.pdf',
            type: MessageKind.file,
            sizeLabel: '1.8 MB',
          ),
        ),
      ],
    ),
    Conversation(
      id: 'c-3',
      friend: MockUsers.users[1],
      unreadCount: 0,
      latestTimestamp: '1h',
      messages: [
        const Message(
          id: 'm-4',
          senderId: 'u-0',
          body: 'This image bubble should stay roomy.',
          sentAt: '7:01 PM',
          isMine: true,
          kind: MessageKind.image,
          delivery: MessageDelivery.delivered,
          attachment: MessageAttachment(
            name: 'orbit-preview.png',
            type: MessageKind.image,
          ),
        ),
      ],
    ),
  ];
}
