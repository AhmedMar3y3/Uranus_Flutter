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
    final delivered = json['delivered_at'] != null;
    final seen = json['seen_at'] != null;

    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: senderId,
      body: json['body']?.toString() ?? '',
      sentAt: UserMapper.fromJson({
        'username': 'time',
        'full_name': 'time',
        'last_seen': json['created_at'],
      }).lastSeen,
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
      previewUrl: value['url']?.toString(),
      durationSeconds: value['duration_seconds'] is int
          ? value['duration_seconds'] as int
          : int.tryParse(value['duration_seconds']?.toString() ?? ''),
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
}
