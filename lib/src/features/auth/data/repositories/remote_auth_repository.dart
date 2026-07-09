import '../../../../core/network/api_client.dart';
import '../../../../core/session/session_manager.dart';
import '../../../notifications/data/notification_service.dart';
import '../../../e2ee/data/e2ee_service.dart';
import '../../domain/repositories/auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository({
    required this.apiClient,
    required this.sessionManager,
    required this.notificationService,
    required this.e2eeService,
  });

  final ApiClient apiClient;
  final SessionManager sessionManager;
  final NotificationService notificationService;
  final E2eeService e2eeService;

  @override
  Future<void> requestOtp(String email) async {
    await apiClient.post(
      '/auth/otp',
      authenticated: false,
      body: {'email': email, ...await notificationService.publicPayload()},
    );
  }

  @override
  Future<AuthResult> verifyOtp(String email, String code) async {
    final json = await apiClient.post(
      '/auth/otp/verify',
      authenticated: false,
      body: {'email': email, 'otp': code},
    );
    final result = AuthResult(
      token: json['token']?.toString() ?? '',
      completedProfile: json['completed_profile'] as bool? ?? false,
    );
    await sessionManager.saveSession(
      token: result.token,
      completedProfile: result.completedProfile,
      email: email,
    );
    try {
      await e2eeService.ensureKeyPairUploaded();
    } catch (_) {
      // Key upload is retried on app start/profile updates and chat stays gated.
    }
    await notificationService.registerTokenIfAuthenticated();
    return result;
  }
}
