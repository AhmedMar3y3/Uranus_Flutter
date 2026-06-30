import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/complete_profile_screen.dart';
import '../features/auth/presentation/screens/email_login_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/chat/domain/entities/conversation.dart';
import '../features/chat/domain/entities/message.dart';
import '../features/chat/presentation/screens/attachment_preview_screen.dart';
import '../features/chat/presentation/screens/chat_room_screen.dart';
import '../features/chat/presentation/screens/image_viewer_screen.dart';
import '../features/friends/presentation/screens/blocked_users_screen.dart';
import '../features/friends/presentation/screens/friend_requests_screen.dart';
import '../features/profile/domain/entities/app_user.dart';
import '../features/profile/presentation/screens/public_profile_screen.dart';
import '../features/shell/presentation/main_shell.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';
  static const completeProfile = '/complete-profile';
  static const shell = '/home';
  static const chat = '/chat';
  static const publicProfile = '/profile/public';
  static const friendRequests = '/friends/requests';
  static const blockedUsers = '/friends/blocked';
  static const attachmentPreview = '/chat/attachment-preview';
  static const imageViewer = '/chat/image-viewer';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final Widget screen = switch (settings.name) {
      splash => const SplashScreen(),
      login => const EmailLoginScreen(),
      otp => OtpVerificationScreen(email: settings.arguments?.toString() ?? ''),
      completeProfile => const CompleteProfileScreen(),
      shell => const MainShell(),
      chat =>
        settings.arguments is String
            ? ChatRoomScreen.fromConversationId(settings.arguments! as String)
            : ChatRoomScreen(conversation: settings.arguments as Conversation?),
      publicProfile => PublicProfileScreen(
        user: settings.arguments as AppUser?,
      ),
      friendRequests => const FriendRequestsScreen(),
      blockedUsers => const BlockedUsersScreen(),
      attachmentPreview => const AttachmentPreviewScreen(),
      imageViewer => ImageViewerScreen(message: settings.arguments as Message?),
      _ => const MainShell(),
    };

    return MaterialPageRoute(builder: (_) => screen, settings: settings);
  }

  static void openNotification(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    switch (data['type']?.toString()) {
      case 'message.sent':
      case 'message.edited':
      case 'message.deleted':
        final conversationId = data['conversation_id']?.toString();
        if (conversationId != null && conversationId.isNotEmpty) {
          navigator.pushNamed(chat, arguments: conversationId);
        }
      case 'friend.requested':
      case 'friend.rejected':
        navigator.pushNamed(friendRequests);
      case 'friend.accepted':
      case 'friend.blocked':
        navigator.pushNamed(shell);
    }
  }
}
