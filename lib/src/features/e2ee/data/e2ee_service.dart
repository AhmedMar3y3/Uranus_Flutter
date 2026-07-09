import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_manager.dart';
import '../../chat/domain/entities/message.dart';
import '../../profile/data/user_mapper.dart';
import '../../profile/domain/entities/app_user.dart';

class E2eeService {
  E2eeService({
    required this.apiClient,
    required this.sessionManager,
    FlutterSecureStorage? secureStorage,
  }) : secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const encryptionVersion = 'x25519-hkdf-aesgcm-v1';
  static const defaultKeyId = 'default';
  static const _privateKeyKey = 'uranus_e2ee_x25519_private_key';
  static const _publicKeyKey = 'uranus_e2ee_x25519_public_key';

  final ApiClient apiClient;
  final SessionManager sessionManager;
  final FlutterSecureStorage secureStorage;
  final X25519 _keyExchange = X25519();
  final AesGcm _cipher = AesGcm.with256bits();
  final Random _random = Random.secure();
  Future<String?>? _currentUserIdFuture;

  Future<String> publicKey() async {
    await _ensureKeyPair();
    return await secureStorage.read(key: _publicKeyKey) ?? '';
  }

  Future<void> ensureKeyPairUploaded() async {
    if (!await sessionManager.hasToken) {
      return;
    }
    final key = await publicKey();
    if (key.isEmpty) {
      return;
    }
    await apiClient.postVoid('/profile/public-key', body: {'public_key': key});
  }

  Future<EncryptedPayload> encryptText({
    required String conversationId,
    required String senderId,
    required AppUser receiver,
    required String text,
  }) {
    final plaintext = jsonEncode({
      'kind': 'text',
      'text': text,
      'sent_at': DateTime.now().toUtc().toIso8601String(),
    });
    return _encryptPayload(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiver.id,
      remotePublicKey: receiver.publicKey,
      keyId: receiver.keyId,
      plaintext: plaintext,
    );
  }

  Future<EncryptedAttachmentPayload> encryptAttachment({
    required String conversationId,
    required String senderId,
    required AppUser receiver,
    required MessageKind kind,
    required String filePath,
    required String fileName,
    required int fileSize,
    String? caption,
    int? durationSeconds,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final fileKey = await _messageKey(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiver.id,
      remotePublicKey: receiver.publicKey,
      keyId: receiver.keyId,
      purpose: 'attachment',
    );
    final fileNonceBytes = _nonceBytes();
    final fileBox = await _cipher.encrypt(
      bytes,
      secretKey: fileKey,
      nonce: fileNonceBytes,
    );
    final fileNonce = base64Encode(fileNonceBytes);
    final metadata = jsonEncode({
      'kind': kind.name,
      'caption': caption,
      'file_name': fileName,
      'mime_type': _mimeType(fileName, kind),
      'file_size': fileSize,
      'file_nonce': fileNonce,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });
    final messagePayload = await _encryptPayload(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiver.id,
      remotePublicKey: receiver.publicKey,
      keyId: receiver.keyId,
      plaintext: metadata,
    );
    return EncryptedAttachmentPayload(
      message: messagePayload,
      encryptedFileBytes: [...fileBox.cipherText, ...fileBox.mac.bytes],
      encryptedFileName: 'encrypted-$fileName',
    );
  }

  Future<Message> decryptMessage({
    required Message message,
    required AppUser friend,
  }) async {
    if (message.ciphertext == null || message.nonce == null) {
      return message;
    }
    try {
      final ids = await _effectiveParticipants(message, friend);
      final remotePublicKey = ids.isMine
          ? friend.publicKey
          : message.senderPublicKey ?? friend.publicKey;
      final plaintext = await _decryptPayload(
        conversationId: message.conversationId,
        senderId: ids.senderId,
        receiverId: ids.receiverId,
        remotePublicKey: remotePublicKey,
        keyId: message.keyId,
        ciphertext: message.ciphertext!,
        nonce: message.nonce!,
      );
      final decoded = jsonDecode(plaintext);
      if (decoded is! Map<String, dynamic>) {
        return message;
      }
      final kind = _kind(decoded['kind']?.toString()) ?? message.kind;
      final reply = message.replyTo == null
          ? null
          : await decryptMessage(message: message.replyTo!, friend: friend);
      if (kind == MessageKind.text) {
        return message.copyWith(
          body: decoded['text']?.toString() ?? '',
          kind: MessageKind.text,
          replyTo: reply,
        );
      }
      return message.copyWith(
        body: decoded['caption']?.toString() ?? '',
        kind: kind,
        attachment: MessageAttachment(
          name: decoded['file_name']?.toString() ?? 'Attachment',
          type: kind,
          sizeLabel: _sizeLabel(decoded['file_size']),
          previewUrl: message.attachment?.previewUrl,
          encryptedUrl: message.attachment?.encryptedUrl,
          fileNonce: decoded['file_nonce']?.toString(),
          durationSeconds:
              _intValue(decoded['duration_seconds']) ??
              message.attachment?.durationSeconds,
        ),
        replyTo: reply,
      );
    } catch (_) {
      return message.copyWith(
        body: 'Unable to decrypt message',
        decryptionFailed: true,
      );
    }
  }

  Future<List<Message>> decryptMessages({
    required List<Message> messages,
    required AppUser friend,
  }) async {
    return Future.wait(
      messages.map(
        (message) => decryptMessage(message: message, friend: friend),
      ),
    );
  }

  Future<String> decryptAttachmentToTemporaryFile({
    required Message message,
    required AppUser friend,
  }) async {
    final clear = await decryptAttachmentBytes(message: message, friend: friend);
    final directory = await getTemporaryDirectory();
    final safeName = _safeFileName(message.attachment?.name ?? 'attachment');
    final output = File(
      '${directory.path}/uranus_${message.id}_${DateTime.now().millisecondsSinceEpoch}_$safeName',
    );
    await output.writeAsBytes(clear, flush: true);
    return output.path;
  }

  Future<List<int>> decryptAttachmentBytes({
    required Message message,
    required AppUser friend,
  }) async {
    final attachment = message.attachment;
    final url = attachment?.encryptedUrl ?? attachment?.previewUrl;
    final fileNonce = attachment?.fileNonce;
    if (url == null || url.isEmpty || fileNonce == null || fileNonce.isEmpty) {
      throw const ApiException('File is not ready yet.');
    }
    final response = await apiClient.httpClient
        .get(Uri.parse(url), headers: await _downloadHeaders())
        .timeout(const Duration(seconds: 30));
    if (response.statusCode >= 400) {
      throw const ApiException('Could not download this file.');
    }
    final ids = await _effectiveParticipants(message, friend);
    final remotePublicKey = ids.isMine
        ? friend.publicKey
        : message.senderPublicKey ?? friend.publicKey;
    final fileKey = await _messageKey(
      conversationId: message.conversationId,
      senderId: ids.senderId,
      receiverId: ids.receiverId,
      remotePublicKey: remotePublicKey,
      keyId: message.keyId,
      purpose: 'attachment',
    );
    final bytes = response.bodyBytes;
    if (bytes.length <= 16) {
      throw const ApiException('Invalid encrypted file.');
    }
    final clear = await _cipher.decrypt(
      SecretBox(
        bytes.sublist(0, bytes.length - 16),
        nonce: base64Decode(fileNonce),
        mac: Mac(bytes.sublist(bytes.length - 16)),
      ),
      secretKey: fileKey,
    );
    return clear;
  }

  Future<EncryptedPayload> _encryptPayload({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String? remotePublicKey,
    required String keyId,
    required String plaintext,
  }) async {
    final messageKey = await _messageKey(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      remotePublicKey: remotePublicKey,
      keyId: keyId,
    );
    final nonceBytes = _nonceBytes();
    final box = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: messageKey,
      nonce: nonceBytes,
    );
    return EncryptedPayload(
      ciphertext: base64Encode([...box.cipherText, ...box.mac.bytes]),
      nonce: base64Encode(nonceBytes),
      keyId: keyId,
      encryptionVersion: encryptionVersion,
    );
  }

  Future<String> _decryptPayload({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String? remotePublicKey,
    required String keyId,
    required String ciphertext,
    required String nonce,
  }) async {
    final bytes = base64Decode(ciphertext);
    if (bytes.length <= 16) {
      throw const ApiException('Invalid encrypted message.');
    }
    final messageKey = await _messageKey(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      remotePublicKey: remotePublicKey,
      keyId: keyId,
    );
    final clear = await _cipher.decrypt(
      SecretBox(
        bytes.sublist(0, bytes.length - 16),
        nonce: base64Decode(nonce),
        mac: Mac(bytes.sublist(bytes.length - 16)),
      ),
      secretKey: messageKey,
    );
    return utf8.decode(clear);
  }

  Future<SecretKey> _messageKey({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String? remotePublicKey,
    required String keyId,
    String? purpose,
  }) async {
    if (remotePublicKey == null || remotePublicKey.isEmpty) {
      throw const ApiException(
        'This user needs to update the app before encrypted chat is available.',
      );
    }
    final privateKey = await _privateKeyPair();
    final shared = await _keyExchange.sharedSecretKey(
      keyPair: privateKey,
      remotePublicKey: SimplePublicKey(
        base64Decode(remotePublicKey),
        type: KeyPairType.x25519,
      ),
    );
    final info =
        'uranus:e2ee:v1:conversation:$conversationId:sender:$senderId:receiver:$receiverId:key:$keyId${purpose == null ? '' : ':$purpose'}';
    return Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    ).deriveKey(
      secretKey: shared,
      nonce: utf8.encode('uranus:e2ee:v1'),
      info: utf8.encode(info),
    );
  }

  Future<_Participants> _effectiveParticipants(
    Message message,
    AppUser friend,
  ) async {
    final currentUserId = await _currentUserId();
    final isMine =
        message.isMine ||
        (currentUserId != null &&
            currentUserId.isNotEmpty &&
            message.senderId == currentUserId);
    final senderId = _firstNonEmpty([
      message.senderId,
      isMine ? currentUserId : friend.id,
    ]);
    final receiverId = _firstNonEmpty([
      message.receiverId,
      isMine ? friend.id : currentUserId,
    ]);
    return _Participants(
      senderId: senderId,
      receiverId: receiverId,
      isMine: isMine,
    );
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  Future<String?> _currentUserId() async {
    final stored = await sessionManager.userId;
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return _currentUserIdFuture ??= _loadCurrentUserId();
  }

  Future<String?> _loadCurrentUserId() async {
    try {
      final json = await apiClient.get('/profile/me');
      final user = UserMapper.fromJson(json['user'] as Map<String, dynamic>);
      await sessionManager.saveUserIdentity(
        id: user.id,
        username: user.username,
      );
      return user.id;
    } catch (_) {
      return null;
    }
  }

  Future<SimpleKeyPair> _privateKeyPair() async {
    await _ensureKeyPair();
    final privateBytes = await secureStorage.read(key: _privateKeyKey);
    final publicBytes = await secureStorage.read(key: _publicKeyKey);
    if (privateBytes == null || publicBytes == null) {
      throw const ApiException('Encrypted chat keys are not available.');
    }
    return SimpleKeyPairData(
      base64Decode(privateBytes),
      publicKey: SimplePublicKey(
        base64Decode(publicBytes),
        type: KeyPairType.x25519,
      ),
      type: KeyPairType.x25519,
    );
  }

  Future<void> _ensureKeyPair() async {
    final privateBytes = await secureStorage.read(key: _privateKeyKey);
    final publicBytes = await secureStorage.read(key: _publicKeyKey);
    if (privateBytes != null && publicBytes != null) {
      return;
    }
    final keyPair = await _keyExchange.newKeyPair();
    final data = await keyPair.extract();
    final publicKey = await keyPair.extractPublicKey();
    await secureStorage.write(
      key: _privateKeyKey,
      value: base64Encode(data.bytes),
    );
    await secureStorage.write(
      key: _publicKeyKey,
      value: base64Encode(publicKey.bytes),
    );
  }

  List<int> _nonceBytes() {
    return List<int>.generate(12, (_) => _random.nextInt(256));
  }

  MessageKind? _kind(String? value) {
    return switch (value) {
      'image' => MessageKind.image,
      'file' => MessageKind.file,
      'audio' => MessageKind.audio,
      'text' => MessageKind.text,
      _ => null,
    };
  }

  String _sizeLabel(dynamic value) {
    final size = _intValue(value);
    if (size == null || size <= 0) {
      return '';
    }
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(0)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  int? _intValue(dynamic value) {
    return value is int ? value : int.tryParse(value?.toString() ?? '');
  }

  String _mimeType(String filename, MessageKind kind) {
    final lower = filename.toLowerCase();
    if (kind == MessageKind.image) {
      if (lower.endsWith('.png')) return 'image/png';
      if (lower.endsWith('.webp')) return 'image/webp';
      return 'image/jpeg';
    }
    if (kind == MessageKind.audio) {
      if (lower.endsWith('.mp3')) return 'audio/mpeg';
      return 'audio/mp4';
    }
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  Future<Map<String, String>> _downloadHeaders() async {
    return const <String, String>{'Accept': 'application/octet-stream'};
  }

  String _safeFileName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'attachment' : cleaned;
  }
}

class EncryptedPayload {
  const EncryptedPayload({
    required this.ciphertext,
    required this.nonce,
    required this.keyId,
    required this.encryptionVersion,
  });

  final String ciphertext;
  final String nonce;
  final String keyId;
  final String encryptionVersion;

  Map<String, dynamic> toJson() {
    return {
      'ciphertext': ciphertext,
      'nonce': nonce,
      'key_id': keyId,
      'encryption_version': encryptionVersion,
    };
  }
}

class EncryptedAttachmentPayload {
  const EncryptedAttachmentPayload({
    required this.message,
    required this.encryptedFileBytes,
    required this.encryptedFileName,
  });

  final EncryptedPayload message;
  final List<int> encryptedFileBytes;
  final String encryptedFileName;
}

class _Participants {
  const _Participants({
    required this.senderId,
    required this.receiverId,
    required this.isMine,
  });

  final String senderId;
  final String receiverId;
  final bool isMine;
}
