import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/entities/message.dart';

class MessageCache {
  const MessageCache({this.maxMessagesPerConversation = 120});

  final int maxMessagesPerConversation;

  Future<List<Message>> getMessages(String conversationId) async {
    if (conversationId.isEmpty) {
      return const [];
    }
    try {
      final file = await _cacheFile(conversationId);
      if (!await file.exists()) {
        return const [];
      }
      final json = jsonDecode(await file.readAsString());
      final items = json is Map<String, dynamic>
          ? json['messages'] as List<dynamic>? ?? const []
          : const [];
      final messages = items
          .whereType<Map<String, dynamic>>()
          .map(_messageFromJson)
          .where((message) => !message.id.startsWith('local-'))
          .toList()
        ..sort(_compareMessages);
      return messages;
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveMessages(
    String conversationId,
    Iterable<Message> messages,
  ) async {
    if (conversationId.isEmpty) {
      return;
    }
    try {
      final sorted = messages
          .where((message) => !message.id.startsWith('local-'))
          .where((message) => message.delivery != MessageDelivery.sending)
          .where((message) => message.delivery != MessageDelivery.failed)
          .toList()
        ..sort(_compareMessages);
      final recent = sorted.length > maxMessagesPerConversation
          ? sorted.sublist(sorted.length - maxMessagesPerConversation)
          : sorted;
      final file = await _cacheFile(conversationId);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'conversation_id': conversationId,
          'updated_at': DateTime.now().toIso8601String(),
          'messages': recent.map(_messageToJson).toList(),
        }),
        flush: true,
      );
    } catch (_) {
      // Cache writes must never block chat usage.
    }
  }

  Future<File> _cacheFile(String conversationId) async {
    final directory = await getApplicationSupportDirectory();
    final safeId = base64Url.encode(utf8.encode(conversationId));
    return File('${directory.path}/message_cache/$safeId.json');
  }

  Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'sender_id': message.senderId,
      'receiver_id': message.receiverId,
      'conversation_id': message.conversationId,
      'body': message.body,
      'sent_at': message.sentAt,
      'is_mine': message.isMine,
      'sort_key': message.sortKey,
      'kind': message.kind.name,
      'delivery': message.delivery.name,
      'attachment': message.attachment == null
          ? null
          : _attachmentToJson(message.attachment!),
      'reply_to': message.replyTo == null
          ? null
          : _messageToJson(message.replyTo!),
      'is_edited': message.isEdited,
      'ciphertext': message.ciphertext,
      'nonce': message.nonce,
      'key_id': message.keyId,
      'encryption_version': message.encryptionVersion,
      'sender_public_key': message.senderPublicKey,
      'receiver_public_key': message.receiverPublicKey,
      'decryption_failed': message.decryptionFailed,
    };
  }

  Map<String, dynamic> _attachmentToJson(MessageAttachment attachment) {
    return {
      'name': attachment.name,
      'type': attachment.type.name,
      'size_label': attachment.sizeLabel,
      'preview_url': attachment.previewUrl,
      'duration_seconds': attachment.durationSeconds,
      'encrypted_url': attachment.encryptedUrl,
      'file_nonce': attachment.fileNonce,
    };
  }

  Message _messageFromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      sentAt: json['sent_at']?.toString() ?? '',
      isMine: json['is_mine'] as bool? ?? false,
      sortKey: _intValue(json['sort_key']),
      kind: _kindValue(json['kind']?.toString()),
      delivery: _deliveryValue(json['delivery']?.toString()),
      attachment: json['attachment'] is Map<String, dynamic>
          ? _attachmentFromJson(json['attachment'] as Map<String, dynamic>)
          : null,
      replyTo: json['reply_to'] is Map<String, dynamic>
          ? _messageFromJson(json['reply_to'] as Map<String, dynamic>)
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
      ciphertext: json['ciphertext']?.toString(),
      nonce: json['nonce']?.toString(),
      keyId: json['key_id']?.toString() ?? 'default',
      encryptionVersion: json['encryption_version']?.toString(),
      senderPublicKey: json['sender_public_key']?.toString(),
      receiverPublicKey: json['receiver_public_key']?.toString(),
      decryptionFailed: json['decryption_failed'] as bool? ?? false,
    );
  }

  MessageAttachment _attachmentFromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      name: json['name']?.toString() ?? '',
      type: _kindValue(json['type']?.toString()),
      sizeLabel: json['size_label']?.toString(),
      previewUrl: json['preview_url']?.toString(),
      durationSeconds: _nullableIntValue(json['duration_seconds']),
      encryptedUrl: json['encrypted_url']?.toString(),
      fileNonce: json['file_nonce']?.toString(),
    );
  }

  MessageKind _kindValue(String? value) {
    return MessageKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => MessageKind.text,
    );
  }

  MessageDelivery _deliveryValue(String? value) {
    return MessageDelivery.values.firstWhere(
      (delivery) => delivery.name == value,
      orElse: () => MessageDelivery.delivered,
    );
  }

  int _intValue(Object? value) => _nullableIntValue(value) ?? 0;

  int? _nullableIntValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  int _compareMessages(Message a, Message b) {
    final byTime = a.sortKey.compareTo(b.sortKey);
    if (byTime != 0) {
      return byTime;
    }
    final aId = int.tryParse(a.id);
    final bId = int.tryParse(b.id);
    if (aId != null && bId != null) {
      return aId.compareTo(bId);
    }
    return a.id.compareTo(b.id);
  }
}
