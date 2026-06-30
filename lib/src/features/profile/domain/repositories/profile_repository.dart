import '../entities/app_user.dart';

abstract interface class ProfileRepository {
  Future<AppUser> getCurrentUser();
  Future<List<AppUser>> searchUsers(String query);
  Future<AppUser> getUserProfile(String userId);
  Future<AppUser> completeProfile({
    required String username,
    required String fullName,
    required Gender gender,
    required String bio,
  });
  Future<AppUser> updateProfile({
    String? username,
    String? fullName,
    Gender? gender,
    String? bio,
    String? imagePath,
  });
}
