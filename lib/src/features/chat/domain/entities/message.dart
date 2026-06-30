enum MessageKind { text, image, file, audio }

enum MessageDelivery { sending, sent, delivered, seen, failed }

class MessageAttachment {
  const MessageAttachment({
    required this.name,
    required this.type,
    this.sizeLabel,
    this.previewUrl,
    this.durationSeconds,
  });

  final String name;
  final MessageKind type;
  final String? sizeLabel;
  final String? previewUrl;
  final int? durationSeconds;
}

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.body,
    required this.sentAt,
    required this.isMine,
    required this.conversationId,
    this.kind = MessageKind.text,
    this.delivery = MessageDelivery.delivered,
    this.attachment,
    this.replyTo,
    this.isEdited = false,
  });

  final String id;
  final String senderId;
  final String conversationId;
  final String body;
  final String sentAt;
  final bool isMine;
  final MessageKind kind;
  final MessageDelivery delivery;
  final MessageAttachment? attachment;
  final Message? replyTo;
  final bool isEdited;

  Message copyWith({
    String? id,
    String? senderId,
    String? conversationId,
    String? body,
    String? sentAt,
    bool? isMine,
    MessageKind? kind,
    MessageDelivery? delivery,
    MessageAttachment? attachment,
    Message? replyTo,
    bool? isEdited,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      conversationId: conversationId ?? this.conversationId,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      isMine: isMine ?? this.isMine,
      kind: kind ?? this.kind,
      delivery: delivery ?? this.delivery,
      attachment: attachment ?? this.attachment,
      replyTo: replyTo ?? this.replyTo,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}
