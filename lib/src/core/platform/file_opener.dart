import 'package:flutter/services.dart';

class FileOpener {
  const FileOpener._();

  static const _channel = MethodChannel('uranus/file_opener');

  static Future<void> open(String url, {String? mimeType}) async {
    if (url.isEmpty) {
      throw const FileOpenException('File is not ready yet.');
    }
    try {
      await _channel.invokeMethod<void>('open', {
        'url': url,
        if (mimeType != null && mimeType.isNotEmpty) 'mimeType': mimeType,
      });
    } on PlatformException catch (error) {
      throw FileOpenException(
        error.message ?? 'No app is available to open this file.',
      );
    }
  }
}

class FileOpenException implements Exception {
  const FileOpenException(this.message);

  final String message;

  @override
  String toString() => message;
}
