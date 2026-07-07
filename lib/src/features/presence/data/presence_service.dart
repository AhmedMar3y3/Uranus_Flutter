import 'dart:async';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_manager.dart';
import '../../chat/data/pusher_chat_service.dart';

class PresenceUpdate {
  const PresenceUpdate({
    required this.userId,
    required this.online,
    required this.lastSeen,
  });

  final String userId;
  final bool online;
  final String lastSeen;
}

class PresenceService {
  PresenceService({
    required this.apiClient,
    required this.sessionManager,
    required this.pusherChatService,
  });

  final ApiClient apiClient;
  final SessionManager sessionManager;
  final PusherChatService pusherChatService;

  final _updates = StreamController<PresenceUpdate>.broadcast();
  Timer? _heartbeatTimer;
  bool _presenceSubscribed = false;

  Stream<PresenceUpdate> get updates => _updates.stream;

  Future<void> startForegroundSession() async {
    if (!await sessionManager.hasToken) {
      return;
    }
    try {
      await _subscribeToRealtimePresence();
    } catch (_) {
      // Heartbeats should continue even if realtime presence cannot connect.
    }
    await goOnline();
    _startHeartbeat();
  }

  Future<void> stopForegroundSession({bool markOffline = true}) async {
    _stopHeartbeat();
    if (markOffline) {
      await goOffline();
    }
  }

  Future<void> goOnline() async {
    if (!await sessionManager.hasToken) {
      return;
    }
    try {
      await apiClient.postVoid('/presence/online');
    } catch (_) {
      // Presence is self-healing through the backend sweep job.
    }
  }

  Future<void> goOffline() async {
    if (!await sessionManager.hasToken) {
      return;
    }
    try {
      await apiClient.postVoid('/presence/offline');
    } catch (_) {
      // Best-effort; the backend sweep marks stale users offline.
    }
  }

  Future<void> _subscribeToRealtimePresence() async {
    if (_presenceSubscribed) {
      return;
    }
    await pusherChatService.subscribeToPresence(_handlePresenceChanged);
    _presenceSubscribed = true;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => unawaited(goOnline()),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _handlePresenceChanged(
    String userId,
    bool online,
    String? lastSeen,
  ) {
    _updates.add(
      PresenceUpdate(
        userId: userId,
        online: online,
        lastSeen: _lastSeenLabel(lastSeen),
      ),
    );
  }

  String _lastSeenLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'recently';
    }
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) {
      return value;
    }
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return 'just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}
