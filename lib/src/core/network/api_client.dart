import 'dart:convert';

import 'package:http/http.dart' as http;

import '../session/session_manager.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({required this.sessionManager, http.Client? httpClient})
    : httpClient = httpClient ?? http.Client();

  final SessionManager sessionManager;
  final http.Client httpClient;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) {
    final uri = _uri(path, query);
    return _send(
      () async => httpClient.get(uri, headers: await _headers(authenticated)),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    final uri = _uri(path);
    return _send(
      () async => httpClient.post(
        uri,
        headers: await _headers(authenticated, json: true),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    final uri = _uri(path);
    return _send(
      () async => httpClient.put(
        uri,
        headers: await _headers(authenticated, json: true),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    final uri = _uri(path);
    return _send(
      () async => httpClient.delete(
        uri,
        headers: await _headers(authenticated, json: true),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  Future<Map<String, dynamic>> multipart(
    String path, {
    required Map<String, String> fields,
    Map<String, String>? filePaths,
    String method = 'POST',
  }) async {
    final request = http.MultipartRequest(method, _uri(path));
    request.headers.addAll(await _headers(true));
    request.fields.addAll(fields);
    if (filePaths != null) {
      for (final entry in filePaths.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value),
        );
      }
    }

    final response = await request.send();
    final text = await response.stream.bytesToString();
    return _parseResponse(response.statusCode, text);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.apiBaseUrl}$cleanPath').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, value)),
    );
  }

  Future<Map<String, String>> _headers(
    bool authenticated, {
    bool json = false,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (authenticated) {
      final token = await sessionManager.token;
      if (token == null || token.isEmpty) {
        throw const ApiException('Please login again.');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();
      return _parseResponse(response.statusCode, response.body);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Network error. Please check your connection.');
    }
  }

  Map<String, dynamic> _parseResponse(int statusCode, String body) {
    final Map<String, dynamic> decoded;
    try {
      decoded = body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        statusCode >= 500
            ? 'Server error. Please try again shortly.'
            : 'Unexpected response from the server.',
        code: statusCode,
      );
    }
    final status = decoded['status'] as Map<String, dynamic>?;
    final success = status?['success'] as bool? ?? statusCode < 400;

    if (!success || statusCode >= 400) {
      throw ApiException(
        status?['message']?.toString() ?? 'Request failed.',
        code: status?['code'] as int?,
        errors: decoded['errors'] as Map<String, dynamic>?,
      );
    }

    return decoded;
  }
}
