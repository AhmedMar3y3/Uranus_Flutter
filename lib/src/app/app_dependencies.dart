import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../features/auth/data/repositories/remote_auth_repository.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/chat/data/repositories/remote_chat_repository.dart';
import '../features/chat/data/message_cache.dart';
import '../features/chat/data/pusher_chat_service.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/e2ee/data/e2ee_service.dart';
import '../features/friends/data/repositories/remote_friends_repository.dart';
import '../features/friends/domain/repositories/friends_repository.dart';
import '../features/notifications/data/notification_service.dart';
import '../features/presence/data/presence_service.dart';
import '../features/profile/data/repositories/remote_profile_repository.dart';
import '../features/profile/domain/repositories/profile_repository.dart';

class AppDependencies {
  AppDependencies._();

  static final sessionManager = SessionManager();
  static final apiClient = ApiClient(sessionManager: sessionManager);
  static final notificationService = NotificationService(
    apiClient: apiClient,
    sessionManager: sessionManager,
  );
  static final pusherChatService = PusherChatService(
    sessionManager: sessionManager,
  );
  static const messageCache = MessageCache();
  static final e2eeService = E2eeService(
    apiClient: apiClient,
    sessionManager: sessionManager,
  );
  static final presenceService = PresenceService(
    apiClient: apiClient,
    sessionManager: sessionManager,
    pusherChatService: pusherChatService,
  );

  static final AuthRepository authRepository = RemoteAuthRepository(
    apiClient: apiClient,
    sessionManager: sessionManager,
    notificationService: notificationService,
    e2eeService: e2eeService,
  );
  static final ProfileRepository profileRepository = RemoteProfileRepository(
    apiClient: apiClient,
    sessionManager: sessionManager,
    e2eeService: e2eeService,
  );
  static final ChatRepository chatRepository = RemoteChatRepository(
    apiClient: apiClient,
    sessionManager: sessionManager,
    e2eeService: e2eeService,
  );
  static final FriendsRepository friendsRepository = RemoteFriendsRepository(
    apiClient: apiClient,
  );
}
