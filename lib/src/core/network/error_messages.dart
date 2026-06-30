import 'api_exception.dart';

String readableError(
  Object? error, {
  String fallback = 'Something went wrong.',
}) {
  if (error is ApiException) {
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
