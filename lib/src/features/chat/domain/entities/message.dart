enum MessageKind { text, image, file, audio }

enum MessageDelivery { sending, sent, delivered, seen, failed }

class MessageAttachment {
  const MessageAttachment({
    required this.name,
    required this.type,
    this.sizeLabel,
    this.previewUrl,
    this.durationSeconds,
    this.encryptedUrl,
    this.fileNonce,
  });

  final String name;
  final MessageKind type;
  final String? sizeLabel;
  final String? previewUrl;
  final int? durationSeconds;
  final String? encryptedUrl;
  final String? fileNonce;
}

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.sentAt,
    required this.isMine,
    required this.conversationId,
    required this.sortKey,
    this.kind = MessageKind.text,
    this.delivery = MessageDelivery.delivered,
    this.attachment,
    this.replyTo,
    this.isEdited = false,
    this.ciphertext,
    this.nonce,
    this.keyId = 'default',
    this.encryptionVersion,
    this.senderPublicKey,
    this.receiverPublicKey,
    this.decryptionFailed = false,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String conversationId;
  final String body;
  final String sentAt;
  final bool isMine;
  final int sortKey;
  final MessageKind kind;
  final MessageDelivery delivery;
  final MessageAttachment? attachment;
  final Message? replyTo;
  final bool isEdited;
  final String? ciphertext;
  final String? nonce;
  final String keyId;
  final String? encryptionVersion;
  final String? senderPublicKey;
  final String? receiverPublicKey;
  final bool decryptionFailed;

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? conversationId,
    String? body,
    String? sentAt,
    bool? isMine,
    int? sortKey,
    MessageKind? kind,
    MessageDelivery? delivery,
    MessageAttachment? attachment,
    Message? replyTo,
    bool? isEdited,
    String? ciphertext,
    String? nonce,
    String? keyId,
    String? encryptionVersion,
    String? senderPublicKey,
    String? receiverPublicKey,
    bool? decryptionFailed,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      conversationId: conversationId ?? this.conversationId,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      isMine: isMine ?? this.isMine,
      sortKey: sortKey ?? this.sortKey,
      kind: kind ?? this.kind,
      delivery: delivery ?? this.delivery,
      attachment: attachment ?? this.attachment,
      replyTo: replyTo ?? this.replyTo,
      isEdited: isEdited ?? this.isEdited,
      ciphertext: ciphertext ?? this.ciphertext,
      nonce: nonce ?? this.nonce,
      keyId: keyId ?? this.keyId,
      encryptionVersion: encryptionVersion ?? this.encryptionVersion,
      senderPublicKey: senderPublicKey ?? this.senderPublicKey,
      receiverPublicKey: receiverPublicKey ?? this.receiverPublicKey,
      decryptionFailed: decryptionFailed ?? this.decryptionFailed,
    );
  }
}
