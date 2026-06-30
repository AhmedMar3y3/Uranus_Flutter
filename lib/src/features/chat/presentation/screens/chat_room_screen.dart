import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as picker;

import '../../../../app/app_dependencies.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/refreshable_placeholder.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import 'message_actions_sheet.dart';
import '../../../profile/domain/entities/app_user.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({Conversation? conversation, super.key})
    : conversation = conversation ?? _emptyConversation;

  factory ChatRoomScreen.fromConversationId(String conversationId) {
    return ChatRoomScreen(
      conversation: Conversation(
        id: conversationId,
        friend: _unknownUser,
        unreadCount: 0,
        latestTimestamp: '',
      ),
    );
  }

  static const _unknownUser = AppUser(
    id: '',
    username: 'unknown',
    fullName: 'Unknown user',
    initials: 'UU',
    gender: Gender.other,
    bio: '',
    friendsCount: 0,
    isOnline: false,
    lastSeen: 'recently',
  );

  static const _emptyConversation = Conversation(
    id: '',
    friend: _unknownUser,
    unreadCount: 0,
    latestTimestamp: '',
  );

  final Conversation conversation;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <Message>[];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await AppDependencies.chatRepository.getMessages(
        widget.conversation.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _isLoading = false;
      });
      _scrollToLatest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messages
          ..clear()
          ..addAll(widget.conversation.messages);
        _isLoading = false;
        _error = readableError(
          error,
          fallback:
              'Could not load messages. Showing available conversation data.',
        );
      });
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _timeLabel() => TimeOfDay.now().format(context);

  Future<void> _sendPickedAttachment(MessageKind type) async {
    final result = await picker.FilePicker.pickFiles(
      type: switch (type) {
        MessageKind.image => picker.FileType.image,
        MessageKind.audio => picker.FileType.audio,
        _ => picker.FileType.any,
      },
      allowMultiple: false,
    );
    final file = result?.files.single;
    final path = file?.path;
    if (path == null) {
      return;
    }

    final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final pending = Message(
      id: localId,
      conversationId: widget.conversation.id,
      senderId: 'me',
      body: '',
      sentAt: _timeLabel(),
      isMine: true,
      kind: type,
      delivery: MessageDelivery.sending,
      attachment: MessageAttachment(
        name: file!.name,
        type: type,
        sizeLabel: file.size < 1024 * 1024
            ? '${(file.size / 1024).toStringAsFixed(0)} KB'
            : '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB',
      ),
    );

    setState(() {
      _isSending = true;
      _messages.add(pending);
    });
    _scrollToLatest();

    try {
      final sent = await AppDependencies.chatRepository.sendAttachmentMessage(
        conversationId: widget.conversation.id,
        type: type,
        filePath: path,
        durationSeconds: type == MessageKind.audio ? 0 : null,
      );
      if (!mounted) {
        return;
      }
      final index = _messages.indexWhere((message) => message.id == localId);
      if (index != -1) {
        setState(() => _messages[index] = sent);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final index = _messages.indexWhere((message) => message.id == localId);
      if (index != -1) {
        setState(() {
          _messages[index] = Message(
            id: pending.id,
            conversationId: pending.conversationId,
            senderId: pending.senderId,
            body: pending.body,
            sentAt: pending.sentAt,
            isMine: pending.isMine,
            kind: pending.kind,
            attachment: pending.attachment,
            delivery: MessageDelivery.failed,
          );
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(readableError(error))));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendText() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _isSending) {
      return;
    }

    _messageController.clear();
    final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final pending = Message(
      id: localId,
      conversationId: widget.conversation.id,
      senderId: 'me',
      body: body,
      sentAt: _timeLabel(),
      isMine: true,
      delivery: MessageDelivery.sending,
    );

    setState(() {
      _isSending = true;
      _messages.add(pending);
    });
    _scrollToLatest();

    try {
      final sent = await AppDependencies.chatRepository.sendTextMessage(
        conversationId: widget.conversation.id,
        body: body,
      );
      if (!mounted) {
        return;
      }
      final index = _messages.indexWhere((message) => message.id == localId);
      if (index != -1) {
        setState(() => _messages[index] = sent);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final index = _messages.indexWhere((message) => message.id == localId);
      if (index != -1) {
        setState(() {
          _messages[index] = Message(
            id: pending.id,
            conversationId: pending.conversationId,
            senderId: pending.senderId,
            body: pending.body,
            sentAt: pending.sentAt,
            isMine: pending.isMine,
            delivery: MessageDelivery.failed,
          );
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            readableError(
              error,
              fallback:
                  'Message could not be sent. Pull to refresh and try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showAttachmentSheet() {
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
                title: const Text('Image'),
                onTap: () {
                  Navigator.of(context).pop();
                  _sendPickedAttachment(MessageKind.image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('File'),
                onTap: () {
                  Navigator.of(context).pop();
                  _sendPickedAttachment(MessageKind.file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic_none),
                title: const Text('Audio'),
                onTap: () {
                  Navigator.of(context).pop();
                  _sendPickedAttachment(MessageKind.audio);
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
              imageUrl: friend.imageUrl,
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
      ),
      body: SpaceBackground(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _messages.isEmpty
                  ? RefreshablePlaceholder(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load messages',
                      body: _error!,
                      onRefresh: _loadMessages,
                    )
                  : _messages.isEmpty
                  ? RefreshablePlaceholder(
                      icon: Icons.chat_bubble_outline,
                      title: 'No messages yet',
                      body:
                          'Send the first message to start this conversation.',
                      onRefresh: _loadMessages,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMessages,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 92, 16, 12),
                        itemCount: _messages.length + (_error == null ? 1 : 2),
                        itemBuilder: (context, index) {
                          if (_error != null && index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassPanel(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            );
                          }
                          final offset = _error == null ? 0 : 1;
                          if (index == offset) {
                            return Center(
                              child: GlassPanel(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                child: const Text(
                                  'Private conversation',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }
                          return _MessageBubble(
                            message: _messages[index - offset - 1],
                          );
                        },
                      ),
                    ),
            ),
            _Composer(
              controller: _messageController,
              isSending: _isSending,
              onSend: _sendText,
              onAttach: _showAttachmentSheet,
              onRecord: () => _sendPickedAttachment(MessageKind.audio),
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
    final url = message.attachment?.previewUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: url == null
              ? Container(
                  height: 170,
                  color: AppTheme.deepNavy,
                  child: const Center(child: Icon(Icons.image_outlined)),
                )
              : Image.network(url, height: 170, width: 260, fit: BoxFit.cover),
        ),
        if (message.body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(message.body, style: TextStyle(color: textColor)),
        ],
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
    final duration = message.attachment?.durationSeconds;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_arrow_rounded, color: textColor, size: 32),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.attachment?.name ?? 'Audio message',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
              ),
              Text(
                duration == null || duration == 0
                    ? message.attachment?.sizeLabel ?? 'Audio'
                    : '${duration}s',
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

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onAttach,
    required this.onRecord,
  });

  final TextEditingController controller;
  final bool isSending;
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
                  hintText: widget.isSending ? 'Sending...' : 'Message',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: widget.onRecord,
              icon: const Icon(Icons.mic_none),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _hasText && !widget.isSending ? widget.onSend : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
