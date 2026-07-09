import '../../../core/network/api_config.dart';
import '../../profile/data/user_mapper.dart';
import '../domain/entities/message.dart';

class MessageMapper {
  static Message fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    String? currentUsername,
  }) {
    final sender = json['sender'] is Map<String, dynamic>
        ? json['sender'] as Map<String, dynamic>
        : <String, dynamic>{};
    final senderId =
        sender['id']?.toString() ?? json['sender_id']?.toString() ?? '';
    final receiver = json['receiver'] is Map<String, dynamic>
        ? json['receiver'] as Map<String, dynamic>
        : <String, dynamic>{};
    final receiverId =
        receiver['id']?.toString() ?? json['receiver_id']?.toString() ?? '';
    final delivered = json['delivered_at'] != null;
    final seen = json['seen_at'] != null;

    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: senderId,
      receiverId: receiverId,
      body: json['body']?.toString() ?? '',
      sentAt: UserMapper.fromJson({
        'username': 'time',
        'full_name': 'time',
        'last_seen': json['created_at'],
      }).lastSeen,
      sortKey: _sortKey(json),
      isMine:
          (currentUserId != null && senderId == currentUserId) ||
          (currentUsername != null && sender['username'] == currentUsername),
      kind: _kind(json['type']?.toString()),
      delivery: seen
          ? MessageDelivery.seen
          : delivered
          ? MessageDelivery.delivered
          : MessageDelivery.sent,
      attachment: _attachment(json['attachment'], json['type']?.toString()),
      replyTo: json['reply_to'] is Map<String, dynamic>
          ? fromJson(
              json['reply_to'] as Map<String, dynamic>,
              currentUserId: currentUserId,
              currentUsername: currentUsername,
            )
          : null,
      isEdited: json['edited_at'] != null,
      ciphertext: _nonEmpty(json['ciphertext']),
      nonce: _nonEmpty(json['nonce']),
      keyId: _nonEmpty(json['key_id']) ?? 'default',
      encryptionVersion: _nonEmpty(json['encryption_version']),
      senderPublicKey: _nonEmpty(sender['public_key']),
      receiverPublicKey: _nonEmpty(receiver['public_key']),
    );
  }

  static MessageKind _kind(String? value) {
    return switch (value) {
      'image' => MessageKind.image,
      'file' => MessageKind.file,
      'audio' => MessageKind.audio,
      _ => MessageKind.text,
    };
  }

  static MessageAttachment? _attachment(dynamic value, String? type) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    return MessageAttachment(
      name: value['name']?.toString() ?? 'Attachment',
      type: _kind(type),
      sizeLabel: _sizeLabel(value['size']),
      previewUrl: _url(
        value['url'] ?? value['file_url'] ?? value['path'] ?? value['file_path'],
      ),
      durationSeconds: value['duration_seconds'] is int
          ? value['duration_seconds'] as int
          : int.tryParse(value['duration_seconds']?.toString() ?? ''),
      encryptedUrl: _url(
        value['url'] ?? value['file_url'] ?? value['path'] ?? value['file_path'],
      ),
      fileNonce: _nonEmpty(value['file_nonce']),
    );
  }

  static String? _sizeLabel(dynamic value) {
    final size = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (size == null) {
      return null;
    }
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(0)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String? _url(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }
    final path = text.startsWith('/') ? text : '/$text';
    return '${ApiConfig.baseUrl}$path';
  }

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static int _sortKey(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    if (createdAt != null) {
      return createdAt.toUtc().millisecondsSinceEpoch;
    }
    final id = int.tryParse(json['id']?.toString() ?? '');
    if (id != null) {
      return id;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }
}
