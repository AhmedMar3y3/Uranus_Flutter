import 'message.dart';

class MessagePage {
  const MessagePage({
    required this.messages,
    required this.currentPage,
    required this.perPage,
    required this.totalPages,
    required this.totalObjects,
    required this.itemsOnPage,
  });

  final List<Message> messages;
  final int currentPage;
  final int perPage;
  final int totalPages;
  final int totalObjects;
  final int itemsOnPage;

  bool get hasMore => currentPage < totalPages && messages.isNotEmpty;
  int? get nextPage => hasMore ? currentPage + 1 : null;
}
