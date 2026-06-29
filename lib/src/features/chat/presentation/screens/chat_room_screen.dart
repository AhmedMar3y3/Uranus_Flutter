import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../data/mock_conversations.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import 'message_actions_sheet.dart';

class ChatRoomScreen extends StatefulWidget {
  ChatRoomScreen({Conversation? conversation, super.key})
    : conversation = conversation ?? MockConversations.conversations.first;

  final Conversation conversation;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final List<Message> _messages = [...widget.conversation.messages];
  bool _isRecording = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _timeLabel() {
    final now = TimeOfDay.now();
    return now.format(context);
  }

  void _sendText() {
    final body = _messageController.text.trim();
    if (body.isEmpty) {
      return;
    }
    _messageController.clear();
    final messageId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    _appendMessage(
      Message(
        id: messageId,
        senderId: 'u-0',
        body: body,
        sentAt: _timeLabel(),
        isMine: true,
        delivery: MessageDelivery.sending,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }
      final index = _messages.indexWhere((message) => message.id == messageId);
      if (index == -1) {
        return;
      }
      final sent = _messages[index];
      setState(() {
        _messages[index] = Message(
          id: sent.id,
          senderId: sent.senderId,
          body: sent.body,
          sentAt: sent.sentAt,
          isMine: sent.isMine,
          delivery: MessageDelivery.delivered,
          kind: sent.kind,
          attachment: sent.attachment,
          replyTo: sent.replyTo,
          isEdited: sent.isEdited,
        );
      });
    });
  }

  void _appendMessage(Message message) {
    setState(() => _messages.add(message));
    _scrollToLatest();
  }

  void _sendMockAttachment(MessageKind kind) {
    final isImage = kind == MessageKind.image;
    _appendMessage(
      Message(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'u-0',
        body: isImage ? 'Image preview attached.' : 'File attached.',
        sentAt: _timeLabel(),
        isMine: true,
        kind: kind,
        delivery: MessageDelivery.delivered,
        attachment: MessageAttachment(
          name: isImage ? 'uranus-orbit.png' : 'project-notes.pdf',
          type: kind,
          sizeLabel: isImage ? '842 KB' : '1.8 MB',
        ),
      ),
    );
  }

  void _toggleRecording() {
    if (!_isRecording) {
      setState(() => _isRecording = true);
      return;
    }

    setState(() => _isRecording = false);
    _appendMessage(
      Message(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'u-0',
        body: 'Voice recording',
        sentAt: _timeLabel(),
        isMine: true,
        kind: MessageKind.audio,
        delivery: MessageDelivery.delivered,
        attachment: const MessageAttachment(
          name: 'voice-note.m4a',
          type: MessageKind.audio,
          sizeLabel: '0:08',
        ),
      ),
    );
  }

  void _showAttachSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.deepNavy,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Send image'),
                subtitle: const Text('Adds a mock image message'),
                onTap: () {
                  Navigator.of(context).pop();
                  _sendMockAttachment(MessageKind.image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('Send file'),
                subtitle: const Text('Adds a mock file card'),
                onTap: () {
                  Navigator.of(context).pop();
                  _sendMockAttachment(MessageKind.file);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.conversation.friend;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              initials: friend.initials,
              isOnline: friend.isOnline,
              size: 42,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    friend.statusLabel,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: SpaceBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 92, 16, 12),
                itemCount: _messages.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Center(
                      child: GlassPanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: const Text(
                          'Encrypted private room preview',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }
                  if (index == _messages.length + 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 10),
                      child: Text(
                        '${friend.username} is typing...',
                        style: const TextStyle(color: AppTheme.cyan),
                      ),
                    );
                  }
                  return _MessageBubble(message: _messages[index - 1]);
                },
              ),
            ),
            _Composer(
              controller: _messageController,
              isRecording: _isRecording,
              onSend: _sendText,
              onAttach: _showAttachSheet,
              onRecord: _toggleRecording,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isMine
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final gradient = message.isMine
        ? const LinearGradient(colors: [AppTheme.cyan, AppTheme.blue])
        : null;
    final color = message.isMine
        ? null
        : AppTheme.surface.withValues(alpha: .9);
    final textColor = message.isMine ? AppTheme.space : Colors.white;

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: () => showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppTheme.deepNavy,
          builder: (_) => MessageActionsSheet(message: message),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 314),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: gradient,
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.replyTo != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message.replyTo!.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (message.kind == MessageKind.image)
                _ImageAttachment(message: message, textColor: textColor),
              if (message.kind == MessageKind.file)
                _FileAttachment(message: message, textColor: textColor),
              if (message.kind == MessageKind.audio)
                _AudioAttachment(message: message, textColor: textColor),
              if (message.kind == MessageKind.text)
                Text(message.body, style: TextStyle(color: textColor)),
              const SizedBox(height: 7),
              Text(
                '${message.sentAt} - ${message.delivery.name}${message.isEdited ? ' - edited' : ''}',
                style: TextStyle(
                  color: textColor.withValues(alpha: .72),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({required this.message, required this.textColor});

  final Message message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 170,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF122B5A), Color(0xFF1B6C8C)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.image_outlined, size: 56, color: Colors.white),
          ),
        ),
        Text(message.body, style: TextStyle(color: textColor)),
      ],
    );
  }
}

class _FileAttachment extends StatelessWidget {
  const _FileAttachment({required this.message, required this.textColor});

  final Message message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file_outlined, color: textColor),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.attachment?.name ?? 'Attachment',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
              ),
              Text(
                message.attachment?.sizeLabel ?? '',
                style: TextStyle(
                  color: textColor.withValues(alpha: .7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AudioAttachment extends StatelessWidget {
  const _AudioAttachment({required this.message, required this.textColor});

  final Message message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_arrow_rounded, color: textColor, size: 32),
        const SizedBox(width: 8),
        ...List.generate(
          12,
          (index) => Container(
            width: 3,
            height: 10 + (index % 4) * 5,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          message.attachment?.sizeLabel ?? '0:08',
          style: TextStyle(color: textColor),
        ),
      ],
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.isRecording,
    required this.onSend,
    required this.onAttach,
    required this.onRecord,
  });

  final TextEditingController controller;
  final bool isRecording;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onRecord;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncText);
  }

  @override
  void didUpdateWidget(covariant _Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncText);
      widget.controller.addListener(_syncText);
      _syncText();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncText);
    super.dispose();
  }

  void _syncText() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GlassPanel(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            IconButton.filledTonal(
              onPressed: widget.onAttach,
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
                decoration: InputDecoration(
                  hintText: widget.isRecording
                      ? 'Recording... tap mic to send'
                      : 'Message',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: widget.onRecord,
              style: IconButton.styleFrom(
                backgroundColor: widget.isRecording
                    ? AppTheme.danger
                    : AppTheme.surfaceSoft,
              ),
              icon: Icon(widget.isRecording ? Icons.stop : Icons.mic),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _hasText ? widget.onSend : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
