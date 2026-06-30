import '../../../profile/domain/entities/app_user.dart';
import '../entities/friend_request.dart';

abstract interface class FriendsRepository {
  Future<List<AppUser>> getFriends();
  Future<FriendRequests> getRequests();
  Future<List<AppUser>> getBlockedUsers();
  Future<void> sendRequest(String userId);
  Future<void> accept(String userId);
  Future<void> reject(String userId);
  Future<void> cancel(String userId);
  Future<void> remove(String userId);
  Future<void> block(String userId);
  Future<void> unblock(String userId);
}
