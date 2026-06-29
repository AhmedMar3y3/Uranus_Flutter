import '../domain/entities/app_user.dart';

class MockUsers {
  static const currentUser = AppUser(
    id: 'u-0',
    username: 'noura',
    fullName: 'Noura Salem',
    initials: 'NS',
    gender: Gender.female,
    bio: 'Designing quieter conversations under a wider sky.',
    friendsCount: 128,
    isOnline: true,
    lastSeen: 'now',
    completedProfile: true,
  );

  static const users = [
    AppUser(
      id: 'u-1',
      username: 'layla',
      fullName: 'Layla Hassan',
      initials: 'LH',
      gender: Gender.female,
      bio: 'Voice notes, late ideas, and soft launches.',
      friendsCount: 84,
      mutualFriendsCount: 12,
      isOnline: true,
      lastSeen: 'now',
      friendshipStatus: FriendshipStatus.friends,
    ),
    AppUser(
      id: 'u-2',
      username: 'omar',
      fullName: 'Omar Adel',
      initials: 'OA',
      gender: Gender.male,
      bio: 'Building tiny tools for very human days.',
      friendsCount: 41,
      mutualFriendsCount: 5,
      isOnline: false,
      lastSeen: '18m ago',
      friendshipStatus: FriendshipStatus.requestReceived,
    ),
    AppUser(
      id: 'u-3',
      username: 'sara',
      fullName: 'Sara Fouad',
      initials: 'SF',
      gender: Gender.female,
      bio: 'Currently offline, probably sketching.',
      friendsCount: 63,
      mutualFriendsCount: 3,
      isOnline: false,
      lastSeen: 'yesterday',
      friendshipStatus: FriendshipStatus.none,
    ),
    AppUser(
      id: 'u-4',
      username: 'malik',
      fullName: 'Malik Youssef',
      initials: 'MY',
      gender: Gender.male,
      bio: 'Files, photos, and all the tiny receipts.',
      friendsCount: 106,
      mutualFriendsCount: 8,
      isOnline: true,
      lastSeen: 'now',
      friendshipStatus: FriendshipStatus.requestSent,
    ),
  ];

  static const blockedUsers = [
    AppUser(
      id: 'u-5',
      username: 'blocked_user',
      fullName: 'Blocked User',
      initials: 'BU',
      gender: Gender.preferNotToSay,
      bio: '',
      friendsCount: 0,
      isOnline: false,
      lastSeen: 'last week',
      friendshipStatus: FriendshipStatus.blocked,
    ),
  ];
}
