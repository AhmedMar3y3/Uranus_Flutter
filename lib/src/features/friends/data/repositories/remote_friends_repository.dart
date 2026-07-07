import '../../../../core/network/api_client.dart';
import '../../../profile/data/user_mapper.dart';
import '../../../profile/domain/entities/app_user.dart';
import '../../domain/entities/friend_request.dart';
import '../../domain/repositories/friends_repository.dart';

class RemoteFriendsRepository implements FriendsRepository {
  const RemoteFriendsRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<AppUser>> getFriends() async {
    final json = await apiClient.get('/friends', query: {'per_page': '30'});
    final friends = json['friends'] as List<dynamic>? ?? const [];
    return friends
        .whereType<Map<String, dynamic>>()
        .map(UserMapper.fromJson)
        .toList();
  }

  @override
  Future<FriendRequests> getRequests() async {
    final json = await apiClient.get(
      '/friends/requests',
      query: {'per_page': '30'},
    );
    return FriendRequests(
      received: _requests(json['received_requests'], 'requester'),
      sent: _requests(json['sent_requests'], 'addressee'),
    );
  }

  @override
  Future<List<AppUser>> getBlockedUsers() async {
    final json = await apiClient.get(
      '/friends/blocked',
      query: {'per_page': '30'},
    );
    final users = json['blocked_users'] as List<dynamic>? ?? const [];
    return users
        .whereType<Map<String, dynamic>>()
        .map(UserMapper.fromJson)
        .toList();
  }

  @override
  Future<void> sendRequest(String userId) => _post('/friends/request', userId);

  @override
  Future<void> accept(String userId) => _post('/friends/accept', userId);

  @override
  Future<void> reject(String userId) => _post('/friends/reject', userId);

  @override
  Future<void> cancel(String userId) => _post('/friends/cancel', userId);

  @override
  Future<void> remove(String userId) =>
      apiClient.deleteVoid('/friends/remove', body: {'user_id': userId});

  @override
  Future<void> block(String userId) => _post('/friends/block', userId);

  @override
  Future<void> unblock(String userId) => _post('/friends/unblock', userId);

  Future<void> _post(String path, String userId) async {
    await apiClient.postVoid(path, body: {'user_id': userId});
  }

  List<FriendRequest> _requests(dynamic value, String userKey) {
    final rows = value as List<dynamic>? ?? const [];
    return rows.whereType<Map<String, dynamic>>().map((row) {
      final userJson = row[userKey] as Map<String, dynamic>? ?? row;
      return FriendRequest(
        id: row['id']?.toString() ?? '',
        user: UserMapper.fromJson(userJson),
        status: row['status']?.toString() ?? 'pending',
        createdAt: row['created_at']?.toString() ?? '',
      );
    }).toList();
  }
}
