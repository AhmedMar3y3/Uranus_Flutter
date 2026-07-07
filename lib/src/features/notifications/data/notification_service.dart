import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../app/router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_manager.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      return;
    }
  }
}

class NotificationService {
  NotificationService({required this.apiClient, required this.sessionManager});

  final ApiClient apiClient;
  final SessionManager sessionManager;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _firebaseAvailable = false;

  static const _messageChannel = AndroidNotificationChannel(
    'uranus_messages',
    'Messages',
    description: 'New messages and friendship updates',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (kIsWeb) {
      return;
    }

    try {
      await Firebase.initializeApp();
      _firebaseAvailable = true;
    } catch (_) {
      _firebaseAvailable = false;
      return;
    }

    try {
      await _initializeLocalNotifications();
    } catch (_) {
      // Push handling should continue even if local notifications fail.
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      unawaited(registerTokenIfAuthenticated());
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMessageTap(initialMessage);
      });
    }
  }

  Future<Map<String, String>> publicPayload() async {
    final currentToken = await token;
    return {
      if (currentToken != null && currentToken.isNotEmpty)
        'fcm_token': currentToken,
      'platform': _platform,
      'device_name': await _safeDeviceName(),
    };
  }

  Future<String?> get token async {
    if (!_firebaseAvailable) {
      return null;
    }
    try {
      return FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> registerTokenIfAuthenticated() async {
    if (!await sessionManager.hasToken) {
      return;
    }
    final payload = await publicPayload();
    final fcmToken = payload['fcm_token'];
    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }
    try {
      await apiClient.post('/devices/fcm-token', body: payload);
    } catch (_) {
      return;
    }
  }

  Future<void> deleteTokenIfAuthenticated() async {
    if (!await sessionManager.hasToken) {
      return;
    }
    final fcmToken = await token;
    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }
    try {
      await apiClient.delete(
        '/devices/fcm-token',
        body: {'fcm_token': fcmToken},
      );
    } catch (_) {
      return;
    }
  }

  void _handleForegroundMessage(RemoteMessage _) {
    // Realtime in-app updates are handled by the active screens. While the app
    // is open, push messages should stay silent instead of surfacing alerts.
  }

  void _handleMessageTap(RemoteMessage message) {
    AppRouter.openNotification(message.data);
  }

  Future<void> _initializeLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          AppRouter.openNotification(decoded);
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_messageChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  String get _platform {
    if (kIsWeb) {
      return 'web';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'android',
    };
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<String> _safeDeviceName() async {
    try {
      return await _deviceName();
    } catch (_) {
      return 'Uranus device';
    }
  }

  Future<String> _deviceName() async {
    if (kIsWeb) {
      final info = await DeviceInfoPlugin().webBrowserInfo;
      return info.browserName.name;
    }
    if (_isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      return '${info.manufacturer} ${info.model}'.trim();
    }
    if (_isIos) {
      final info = await DeviceInfoPlugin().iosInfo;
      return info.name.isEmpty ? info.model : info.name;
    }
    return 'Uranus device';
  }
}
