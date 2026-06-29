enum Gender { female, male, preferNotToSay }

enum FriendshipStatus { none, requestSent, requestReceived, friends, blocked }

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.initials,
    required this.gender,
    required this.bio,
    required this.friendsCount,
    required this.isOnline,
    required this.lastSeen,
    this.mutualFriendsCount = 0,
    this.friendshipStatus = FriendshipStatus.none,
    this.completedProfile = true,
  });

  final String id;
  final String username;
  final String fullName;
  final String initials;
  final Gender gender;
  final String bio;
  final int friendsCount;
  final int mutualFriendsCount;
  final bool isOnline;
  final String lastSeen;
  final FriendshipStatus friendshipStatus;
  final bool completedProfile;

  String get statusLabel => isOnline ? 'Online now' : 'Last seen $lastSeen';
}
