import '../../domain/entities/app_user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../mock_users.dart';

class MockProfileRepository implements ProfileRepository {
  @override
  Future<AppUser> getCurrentUser() async => MockUsers.currentUser;

  @override
  Future<List<AppUser>> searchUsers(String query) async {
    final lowerQuery = query.toLowerCase();
    return MockUsers.users
        .where(
          (user) =>
              user.username.contains(lowerQuery) ||
              user.fullName.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }
}
