import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../mock_conversations.dart';

class MockChatRepository implements ChatRepository {
  @override
  Future<List<Conversation>> getConversations() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockConversations.conversations;
  }
}
