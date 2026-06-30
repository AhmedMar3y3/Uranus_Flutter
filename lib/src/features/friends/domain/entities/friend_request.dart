import '../../../profile/domain/entities/app_user.dart';

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.user,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final AppUser user;
  final String status;
  final String createdAt;
}

class FriendRequests {
  const FriendRequests({required this.received, required this.sent});

  final List<FriendRequest> received;
  final List<FriendRequest> sent;
}
