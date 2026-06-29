import '../entities/app_user.dart';

abstract interface class ProfileRepository {
  Future<AppUser> getCurrentUser();
  Future<List<AppUser>> searchUsers(String query);
}
