enum Gender { female, male, other }

enum FriendshipStatus { none, pending, friends, rejected, blocked }

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
    this.imageUrl,
    this.mutualFriendsCount = 0,
    this.friendshipStatus = FriendshipStatus.none,
    this.completedProfile = true,
    this.publicKey,
    this.keyId = 'default',
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
  final String? imageUrl;
  final FriendshipStatus friendshipStatus;
  final bool completedProfile;
  final String? publicKey;
  final String keyId;

  String get statusLabel => isOnline ? 'Online now' : 'Last seen $lastSeen';

  AppUser copyWith({
    String? id,
    String? username,
    String? fullName,
    String? initials,
    Gender? gender,
    String? bio,
    int? friendsCount,
    int? mutualFriendsCount,
    bool? isOnline,
    String? lastSeen,
    String? imageUrl,
    FriendshipStatus? friendshipStatus,
    bool? completedProfile,
    String? publicKey,
    String? keyId,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      initials: initials ?? this.initials,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      friendsCount: friendsCount ?? this.friendsCount,
      mutualFriendsCount: mutualFriendsCount ?? this.mutualFriendsCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      imageUrl: imageUrl ?? this.imageUrl,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      completedProfile: completedProfile ?? this.completedProfile,
      publicKey: publicKey ?? this.publicKey,
      keyId: keyId ?? this.keyId,
    );
  }
}
