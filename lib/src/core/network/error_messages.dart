import 'api_exception.dart';

const friendOnlyChatMessage =
    'You can only chat with friends. Add this person as a friend first, or wait for them to accept your request.';

String readableError(
  Object? error, {
  String fallback = 'Something went wrong.',
}) {
  if (error is ApiException) {
    if (isFriendOnlyChatError(error)) {
      return friendOnlyChatMessage;
    }
    return error.message;
  }
  if (error is FormatException) {
    return 'The server returned unreadable data. Please try again.';
  }
  if (error == null) {
    return fallback;
  }
  return fallback;
}

bool isFriendOnlyChatError(Object? error) {
  if (error is! ApiException) {
    return false;
  }
  final lower = error.message.toLowerCase();
  return lower.contains('only friends') &&
      (lower.contains('chat') ||
          lower.contains('message') ||
          lower.contains('conversation'));
}
