import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../features/auth/data/repositories/remote_auth_repository.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/chat/data/repositories/remote_chat_repository.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/friends/data/repositories/remote_friends_repository.dart';
import '../features/friends/domain/repositories/friends_repository.dart';
import '../features/notifications/data/notification_service.dart';
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

  static final AuthRepository authRepository = RemoteAuthRepository(
    apiClient: apiClient,
    sessionManager: sessionManager,
    notificationService: notificationService,
  );
  static final ProfileRepository profileRepository = RemoteProfileRepository(
    apiClient: apiClient,
    sessionManager: sessionManager,
  );
  static final ChatRepository chatRepository = RemoteChatRepository(
    apiClient: apiClient,
    sessionManager: sessionManager,
  );
  static final FriendsRepository friendsRepository = RemoteFriendsRepository(
    apiClient: apiClient,
  );
}
