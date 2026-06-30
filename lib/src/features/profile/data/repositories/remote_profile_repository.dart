import '../../../../core/network/api_client.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../user_mapper.dart';

class RemoteProfileRepository implements ProfileRepository {
  const RemoteProfileRepository({
    required this.apiClient,
    required this.sessionManager,
  });

  final ApiClient apiClient;
  final SessionManager sessionManager;

  @override
  Future<AppUser> getCurrentUser() async {
    final json = await apiClient.get('/profile/me');
    return UserMapper.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<List<AppUser>> searchUsers(String query) async {
    final json = await apiClient.get(
      '/users',
      query: {'q': query, 'per_page': '30'},
    );
    final users = json['users'] as List<dynamic>? ?? const [];
    return users
        .whereType<Map<String, dynamic>>()
        .map(UserMapper.fromJson)
        .toList();
  }

  @override
  Future<AppUser> getUserProfile(String userId) async {
    final json = await apiClient.get('/users/$userId');
    return UserMapper.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> completeProfile({
    required String username,
    required String fullName,
    required Gender gender,
    required String bio,
  }) async {
    final json = await apiClient.multipart(
      '/profile/complete',
      fields: {
        'username': username,
        'full_name': fullName,
        'gender': gender.name,
        'bio': bio,
      },
    );
    await sessionManager.markProfileCompleted();
    return UserMapper.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> updateProfile({
    String? username,
    String? fullName,
    Gender? gender,
    String? bio,
    String? imagePath,
  }) async {
    final fields = <String, String>{};
    if (username != null) {
      fields['username'] = username;
    }
    if (fullName != null) {
      fields['full_name'] = fullName;
    }
    if (gender != null) {
      fields['gender'] = gender.name;
    }
    if (bio != null) {
      fields['bio'] = bio;
    }

    final json = await apiClient.multipart(
      '/profile/update',
      fields: fields,
      filePaths: imagePath == null ? null : {'image': imagePath},
    );
    return UserMapper.fromJson(json['user'] as Map<String, dynamic>);
  }
}
