import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

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
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _messages = <Message>[];
  StreamSubscription<void>? _audioCompleteSubscription;
  Message? _replyTo;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isRecording = false;
  bool _friendIsTyping = false;
  bool _sentTyping = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  Timer? _typingStopTimer;
  Timer? _typingAutoHideTimer;
  String? _recordingPath;
  String? _playingMessageId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _audioCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _playingMessageId = null);
      }
    });
    _messageController.addListener(_handleTypingInput);
    _loadMessages();
    unawaited(_subscribeLiveMessages());
  }

  @override
  void dispose() {
    unawaited(
      AppDependencies.pusherChatService.unsubscribeFromConversation(
        widget.conversation.id,
      ),
    );
    _recordTimer?.cancel();
    _typingStopTimer?.cancel();
    _typingAutoHideTimer?.cancel();
    _messageController.removeListener(_handleTypingInput);
    unawaited(_setTypingStatus(false, force: true));
    _recorder.dispose();
    _audioCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _subscribeLiveMessages() async {
    try {
      await AppDependencies.pusherChatService.subscribeToConversation(
        conversationId: widget.conversation.id,
        onMessageSent: _upsertLiveMessage,
        onMessageEdited: _mergeLiveMessageEdit,
        onMessageDeleted: _removeLiveMessage,
        onMessageStatusChanged: _updateMessageDelivery,
        onTypingChanged: _handleRemoteTypingChanged,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = readableError(
          error,
          fallback: 'Live chat is unavailable. Pull to refresh for updates.',
        );
      });
    }
  }

  void _upsertLiveMessage(Message message) {
    if (!mounted) {
      return;
    }
    final index = _messages.indexWhere((item) => item.id == message.id);
    setState(() {
      if (index == -1) {
        _messages.add(message);
      } else {
        _messages[index] = message.copyWith(
          isMine: _messages[index].isMine || message.isMine,
        );
      }
    });
    if (!message.isMine) {
      unawaited(_acknowledgeIncomingMessages([message]));
    }
    _scrollToLatest();
  }

  void _mergeLiveMessageEdit(Message message) {
    if (!mounted) {
      return;
    }
    final index = _messages.indexWhere((item) => item.id == message.id);
    setState(() {
      if (index == -1) {
        _messages.add(message);
      } else {
        final existing = _messages[index];
        _messages[index] = existing.copyWith(
          body: message.body.isEmpty ? existing.body : message.body,
          attachment: message.attachment ?? existing.attachment,
          replyTo: message.replyTo ?? existing.replyTo,
          isEdited: true,
        );
      }
    });
  }

  void _removeLiveMessage(String messageId) {
    if (!mounted) {
      return;
    }
    if (_playingMessageId == messageId) {
      unawaited(_audioPlayer.stop());
    }
    setState(() {
      _messages.removeWhere((message) => message.id == messageId);
      if (_replyTo?.id == messageId) {
        _replyTo = null;
      }
      if (_playingMessageId == messageId) {
        _playingMessageId = null;
      }
    });
  }

  Future<void> _acknowledgeIncomingMessages(List<Message> messages) async {
    await _markIncomingMessagesDelivered(messages);
    await _markIncomingMessagesSeen(messages);
  }

  Future<void> _markIncomingMessagesDelivered(List<Message> messages) async {
    final undeliveredIncoming = messages.where((message) {
      return !message.isMine &&
          message.id.isNotEmpty &&
          !message.id.startsWith('local-') &&
          message.delivery == MessageDelivery.sent;
    }).toList();
    if (undeliveredIncoming.isEmpty) {
      return;
    }

    for (final message in undeliveredIncoming) {
      try {
        await AppDependencies.chatRepository.markMessageDelivered(
          conversationId: widget.conversation.id,
          messageId: message.id,
        );
        if (!mounted) {
          return;
        }
        _updateMessageDelivery(message.id, MessageDelivery.delivered);
      } catch (_) {
        // Delivery receipts are best-effort and should not interrupt chat.
      }
    }
  }

  Future<void> _markIncomingMessagesSeen(List<Message> messages) async {
    final unseenIncoming = messages.where((message) {
      return !message.isMine &&
          message.id.isNotEmpty &&
          !message.id.startsWith('local-') &&
          message.delivery != MessageDelivery.seen;
    }).toList();
    if (unseenIncoming.isEmpty) {
      return;
    }

    for (final message in unseenIncoming) {
      try {
        await AppDependencies.chatRepository.markMessageSeen(
          conversationId: widget.conversation.id,
          messageId: message.id,
        );
        if (!mounted) {
          return;
        }
        _updateMessageDelivery(message.id, MessageDelivery.seen);
      } catch (_) {
        // Seen receipts should never block reading the conversation.
      }
    }
  }

  void _updateMessageDelivery(String messageId, MessageDelivery delivery) {
    if (!mounted) {
      return;
    }
    final index = _messages.indexWhere((message) => message.id == messageId);
    if (index == -1) {
      return;
    }

    final current = _messages[index].delivery;
    if (_deliveryRank(delivery) < _deliveryRank(current)) {
      return;
    }

    setState(() {
      _messages[index] = _messages[index].copyWith(delivery: delivery);
    });
  }

  int _deliveryRank(MessageDelivery delivery) {
    return switch (delivery) {
      MessageDelivery.sending => 0,
      MessageDelivery.sent => 1,
      MessageDelivery.delivered => 2,
      MessageDelivery.seen => 3,
      MessageDelivery.failed => -1,
    };
  }

  void _handleRemoteTypingChanged(String userId, bool isTyping) {
    if (!mounted || userId != widget.conversation.friend.id) {
      return;
    }

    _typingAutoHideTimer?.cancel();
    if (isTyping) {
      setState(() => _friendIsTyping = true);
      _typingAutoHideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _friendIsTyping = false);
        }
      });
      return;
    }

    setState(() => _friendIsTyping = false);
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
      unawaited(_acknowledgeIncomingMessages(messages));
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

  void _handleTypingInput() {
    if (widget.conversation.id.isEmpty || _isRecording) {
      return;
    }

    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText) {
      unawaited(_setTypingStatus(true));
      _typingStopTimer?.cancel();
      _typingStopTimer = Timer(
        const Duration(seconds: 2),
        () => unawaited(_setTypingStatus(false)),
      );
      return;
    }

    _typingStopTimer?.cancel();
    unawaited(_setTypingStatus(false));
  }

  Future<void> _setTypingStatus(bool isTyping, {bool force = false}) async {
    if (widget.conversation.id.isEmpty) {
      return;
    }
    if (!force && _sentTyping == isTyping) {
      return;
    }

    _sentTyping = isTyping;
    try {
      await AppDependencies.chatRepository.sendTyping(
        conversationId: widget.conversation.id,
        isTyping: isTyping,
      );
    } catch (_) {
      // Typing status is nice-to-have; message sending must stay unaffected.
    }
  }

  void _setReplyTarget(Message message) {
    setState(() => _replyTo = message);
  }

  void _clearReplyTarget() {
    setState(() => _replyTo = null);
  }

  Future<void> _toggleAudio(Message message) async {
    final url = message.attachment?.previewUrl;
    if (url == null || url.isEmpty) {
      _showSendError('Audio is not ready yet.');
      return;
    }

    try {
      if (_playingMessageId == message.id) {
        await _audioPlayer.stop();
        if (mounted) {
          setState(() => _playingMessageId = null);
        }
        return;
      }

      await _audioPlayer.stop();
      if (mounted) {
        setState(() => _playingMessageId = message.id);
      }
      await _audioPlayer.play(UrlSource(url));
    } catch (error) {
      if (mounted) {
        setState(() => _playingMessageId = null);
        _showSendError(
          readableError(error, fallback: 'Could not play this voice message.'),
        );
      }
    }
  }

  Future<void> _sendAttachmentFromPath({
    required MessageKind type,
    required String path,
    required String name,
    required int sizeBytes,
    int? durationSeconds,
  }) async {
    if (widget.conversation.id.isEmpty) {
      _showSendError('Open a real conversation before sending attachments.');
      return;
    }

    final replyTo = _replyTo;
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
        name: name,
        type: type,
        sizeLabel: _sizeLabel(sizeBytes),
        durationSeconds: durationSeconds,
      ),
      replyTo: replyTo,
    );

    setState(() {
      _isSending = true;
      _replyTo = null;
      _messages.add(pending);
    });
    _scrollToLatest();

    try {
      final sent = await AppDependencies.chatRepository.sendAttachmentMessage(
        conversationId: widget.conversation.id,
        type: type,
        filePath: path,
        replyToMessageId: replyTo?.id,
        durationSeconds: durationSeconds,
      );
      if (!mounted) {
        return;
      }
      final index = _messages.indexWhere((message) => message.id == localId);
      if (index != -1) {
        setState(() => _messages[index] = sent.copyWith(isMine: true));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final index = _messages.indexWhere((message) => message.id == localId);
      if (index != -1) {
        setState(() {
          _messages[index] = pending.copyWith(delivery: MessageDelivery.failed);
        });
      }
      _showSendError(readableError(error));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendPickedAttachment(MessageKind type) async {
    if (widget.conversation.id.isEmpty) {
      _showSendError('Open a real conversation before sending attachments.');
      return;
    }
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

    await _sendAttachmentFromPath(
      type: type,
      path: path,
      name: file!.name,
      sizeBytes: file.size,
    );
  }

  Future<void> _startRecording() async {
    if (_isSending || _isRecording) {
      return;
    }
    if (widget.conversation.id.isEmpty) {
      _showSendError('Open a real conversation before recording.');
      return;
    }
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _showSendError('Microphone permission is required to record audio.');
        return;
      }
      final directory = await getTemporaryDirectory();
      final nextPath =
          '${directory.path}/uranus_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: nextPath,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
        _recordingPath = nextPath;
      });
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordSeconds++);
        }
      });
    } catch (error) {
      _showSendError(readableError(error));
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    try {
      await _recorder.cancel();
    } catch (_) {
      // The recording may already be stopped by the platform.
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
      _recordingPath = null;
    });
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecording) {
      return;
    }
    _recordTimer?.cancel();
    _recordTimer = null;
    final seconds = _recordSeconds;
    final path = await _recorder.stop();
    final resolvedPath = path ?? _recordingPath;
    if (!mounted) {
      return;
    }
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
      _recordingPath = null;
    });
    if (resolvedPath == null || seconds < 1) {
      _showSendError('Recording is too short.');
      return;
    }
    await _sendAttachmentFromPath(
      type: MessageKind.audio,
      path: resolvedPath,
      name: 'voice-message.m4a',
      sizeBytes: 0,
      durationSeconds: seconds,
    );
  }

  String _sizeLabel(int size) {
    if (size <= 0) {
      return '';
    }
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(0)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _sendText() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _isSending) {
      return;
    }
    if (widget.conversation.id.isEmpty) {
      _showSendError('Open a real conversation before sending messages.');
      return;
    }

    _messageController.clear();
    _typingStopTimer?.cancel();
    unawaited(_setTypingStatus(false, force: true));
    final replyTo = _replyTo;
    final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final pending = Message(
      id: localId,
      conversationId: widget.conversation.id,
      senderId: 'me',
      body: body,
      sentAt: _timeLabel(),
      isMine: true,
      delivery: MessageDelivery.sending,
      replyTo: replyTo,
    );

    setState(() {
      _isSending = true;
      _replyTo = null;
      _messages.add(pending);
    });
    _scrollToLatest();

    try {
      final sent = await AppDependencies.chatRepository.sendTextMessage(
        conversationId: widget.conversation.id,
        body: body,
        replyToMessageId: replyTo?.id,
      );
      if (!mounted) {
        return;
      }
      final index = _messages.indexWhere((message) => message.id == localId);
      if (index != -1) {
        setState(() => _messages[index] = sent.copyWith(isMine: true));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final index = _messages.indexWhere((message) => message.id == localId);
      if (index != -1) {
        setState(() {
          _messages[index] = pending.copyWith(delivery: MessageDelivery.failed);
        });
      }
      _showSendError(
        readableError(
          error,
          fallback: 'Message could not be sent. Pull to refresh and try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showSendError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showMessageActions(Message message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.deepNavy,
      builder: (sheetContext) => MessageActionsSheet(
        message: message,
        onCopy: message.kind == MessageKind.text
            ? () {
                Navigator.of(sheetContext).pop();
                _copyMessage(message);
              }
            : null,
        onEdit:
            message.isMine &&
                message.kind == MessageKind.text &&
                !message.id.startsWith('local-')
            ? () {
                Navigator.of(sheetContext).pop();
                unawaited(_editMessage(message));
              }
            : null,
        onDelete: message.isMine
            ? () {
                Navigator.of(sheetContext).pop();
                unawaited(_deleteMessage(message));
              }
            : null,
      ),
    );
  }

  Future<void> _copyMessage(Message message) async {
    if (message.body.trim().isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: message.body));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard.')));
  }

  Future<void> _editMessage(Message message) async {
    final controller = TextEditingController(text: message.body);
    final updatedBody = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.deepNavy,
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (updatedBody == null ||
        updatedBody.isEmpty ||
        updatedBody == message.body ||
        !mounted) {
      return;
    }

    try {
      final edited = await AppDependencies.chatRepository.editMessage(
        conversationId: widget.conversation.id,
        messageId: message.id,
        body: updatedBody,
      );
      if (!mounted) {
        return;
      }
      final index = _messages.indexWhere((item) => item.id == message.id);
      if (index != -1) {
        setState(() {
          final existing = _messages[index];
          _messages[index] = existing.copyWith(
            body: edited.body.isEmpty ? updatedBody : edited.body,
            isEdited: true,
          );
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSendError(
        readableError(error, fallback: 'Could not edit this message.'),
      );
    }
  }

  Future<void> _deleteMessage(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.deepNavy,
        title: const Text('Delete message?'),
        content: const Text('This message will be removed from the chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      if (!message.id.startsWith('local-')) {
        await AppDependencies.chatRepository.deleteMessage(
          conversationId: widget.conversation.id,
          messageId: message.id,
        );
      }
      if (!mounted) {
        return;
      }
      if (_playingMessageId == message.id) {
        await _audioPlayer.stop();
      }
      setState(() {
        _messages.removeWhere((item) => item.id == message.id);
        if (_replyTo?.id == message.id) {
          _replyTo = null;
        }
        if (_playingMessageId == message.id) {
          _playingMessageId = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSendError(
        readableError(error, fallback: 'Could not delete this message.'),
      );
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
                    _friendIsTyping
                        ? '${friend.username} is typing...'
                        : friend.statusLabel,
                    style: const TextStyle(color: AppTheme.cyan, fontSize: 12),
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
                        padding: const EdgeInsets.fromLTRB(18, 96, 18, 14),
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
                                  'Live private channel',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }
                          final message = _messages[index - offset - 1];
                          return _MessageBubble(
                            message: message,
                            isAudioPlaying: _playingMessageId == message.id,
                            onAudioPressed: () => _toggleAudio(message),
                            onLongPress: () => _showMessageActions(message),
                            onSwipeReply: () => _setReplyTarget(message),
                          );
                        },
                      ),
                    ),
            ),
            _Composer(
              controller: _messageController,
              replyTo: _replyTo,
              isSending: _isSending,
              isRecording: _isRecording,
              recordSeconds: _recordSeconds,
              onSend: _sendText,
              onAttach: _showAttachmentSheet,
              onRecord: _startRecording,
              onCancelRecording: _cancelRecording,
              onSendRecording: _stopAndSendRecording,
              onCancelReply: _clearReplyTarget,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isAudioPlaying,
    required this.onAudioPressed,
    required this.onLongPress,
    required this.onSwipeReply,
  });

  final Message message;
  final bool isAudioPlaying;
  final VoidCallback onAudioPressed;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeReply;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isMine
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final gradient = message.isMine
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.teal, AppTheme.cyan],
          )
        : null;
    final color = message.isMine
        ? null
        : AppTheme.surface.withValues(alpha: .9);
    final textColor = message.isMine ? AppTheme.space : Colors.white;
    final maxWidth = MediaQuery.sizeOf(context).width * .76;

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: onLongPress,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 220) {
            onSwipeReply();
          }
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth.clamp(220, 360)),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            gradient: gradient,
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(message.isMine ? 12 : 3),
              bottomRight: Radius.circular(message.isMine ? 3 : 12),
            ),
            border: Border.all(
              color: message.isMine
                  ? Colors.white.withValues(alpha: .22)
                  : Colors.white.withValues(alpha: .08),
            ),
            boxShadow: [
              BoxShadow(
                color: (message.isMine ? AppTheme.cyan : Colors.black)
                    .withValues(alpha: message.isMine ? .12 : .18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.replyTo != null) ...[
                _ReplyPreview(message: message.replyTo!, textColor: textColor),
                const SizedBox(height: 8),
              ],
              if (message.kind == MessageKind.image)
                _ImageAttachment(message: message, textColor: textColor),
              if (message.kind == MessageKind.file)
                _FileAttachment(message: message, textColor: textColor),
              if (message.kind == MessageKind.audio)
                _AudioAttachment(
                  message: message,
                  textColor: textColor,
                  isPlaying: isAudioPlaying,
                  onPressed: onAudioPressed,
                ),
              if (message.kind == MessageKind.text)
                Text(message.body, style: TextStyle(color: textColor)),
              const SizedBox(height: 7),
              Text(
                '${message.sentAt} - ${_deliveryLabel(message.delivery)}${message.isEdited ? ' - edited' : ''}',
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

  String _deliveryLabel(MessageDelivery delivery) {
    return switch (delivery) {
      MessageDelivery.sending => 'sending',
      MessageDelivery.sent => 'sent',
      MessageDelivery.delivered => 'delivered',
      MessageDelivery.seen => 'seen',
      MessageDelivery.failed => 'failed',
    };
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.message, required this.textColor});

  final Message message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: textColor.withValues(alpha: .65), width: 3),
        ),
      ),
      child: Text(
        _messagePreview(message),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor.withValues(alpha: .82),
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
  const _AudioAttachment({
    required this.message,
    required this.textColor,
    required this.isPlaying,
    required this.onPressed,
  });

  final Message message;
  final Color textColor;
  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final duration = message.attachment?.durationSeconds;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: isPlaying ? 'Pause voice message' : 'Play voice message',
          onPressed: onPressed,
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice message',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
              ),
              Text(
                duration == null || duration == 0
                    ? message.attachment?.sizeLabel ?? 'Tap to play'
                    : _durationLabel(duration),
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

String _messagePreview(Message message) {
  if (message.kind == MessageKind.text) {
    return message.body.isEmpty ? 'Message' : message.body;
  }
  return switch (message.kind) {
    MessageKind.image => 'Image',
    MessageKind.file => message.attachment?.name ?? 'File',
    MessageKind.audio => 'Voice message',
    MessageKind.text => 'Message',
  };
}

String _durationLabel(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.replyTo,
    required this.isSending,
    required this.isRecording,
    required this.recordSeconds,
    required this.onSend,
    required this.onAttach,
    required this.onRecord,
    required this.onCancelRecording,
    required this.onSendRecording,
    required this.onCancelReply,
  });

  final TextEditingController controller;
  final Message? replyTo;
  final bool isSending;
  final bool isRecording;
  final int recordSeconds;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onRecord;
  final VoidCallback onCancelRecording;
  final VoidCallback onSendRecording;
  final VoidCallback onCancelReply;

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
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.all(10),
        child: widget.isRecording
            ? Row(
                children: [
                  IconButton(
                    tooltip: 'Cancel recording',
                    onPressed: widget.onCancelRecording,
                    icon: const Icon(Icons.delete_outline),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.mic, color: AppTheme.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _recordingLabel(widget.recordSeconds),
                      style: const TextStyle(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Send recording',
                    onPressed: widget.onSendRecording,
                    icon: const Icon(Icons.send),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.replyTo != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: .62),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.cyan.withValues(alpha: .18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _messagePreview(widget.replyTo!),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cancel reply',
                            onPressed: widget.onCancelReply,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: widget.onAttach,
                        icon: const Icon(Icons.add_rounded),
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
                            hintText: widget.isSending
                                ? 'Sending...'
                                : 'Message',
                            prefixIcon: const Icon(Icons.bolt_outlined),
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
                        onPressed: _hasText && !widget.isSending
                            ? widget.onSend
                            : null,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  String _recordingLabel(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return 'Recording $minutes:$rest';
  }
}
