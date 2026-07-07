import '../../../core/network/api_config.dart';
import '../domain/entities/app_user.dart';

class UserMapper {
  static AppUser fromJson(Map<String, dynamic> json) {
    final username = json['username']?.toString() ?? 'unknown';
    final fullName = json['full_name']?.toString() ?? username;

    return AppUser(
      id: json['id']?.toString() ?? '',
      username: username,
      fullName: fullName,
      initials: _initials(fullName, username),
      gender: _gender(json['gender']?.toString()),
      bio: json['bio']?.toString() ?? '',
      friendsCount: json['friends_count'] as int? ?? 0,
      mutualFriendsCount: json['mutual_friends_count'] as int? ?? 0,
      isOnline: json['online'] as bool? ?? json['is_online'] as bool? ?? false,
      lastSeen: _lastSeen(json['last_seen'] ?? json['last_seen_at']),
      imageUrl:
          _url(
            json['profile_image'] ??
                json['profile_image_url'] ??
                json['profile_photo_url'] ??
                json['avatar'] ??
                json['photo'] ??
                json['image'] ??
                json['image_url'] ??
                json['image_path'],
          ),
      friendshipStatus: _friendshipStatus(
        json['friendship_status']?.toString(),
      ),
      completedProfile: json['completed_profile'] as bool? ?? true,
    );
  }

  static Gender _gender(String? value) {
    return switch (value) {
      'male' => Gender.male,
      'other' => Gender.other,
      _ => Gender.female,
    };
  }

  static FriendshipStatus _friendshipStatus(String? value) {
    return switch (value) {
      'pending' => FriendshipStatus.pending,
      'accepted' => FriendshipStatus.friends,
      'rejected' => FriendshipStatus.rejected,
      'blocked' => FriendshipStatus.blocked,
      _ => FriendshipStatus.none,
    };
  }

  static String _initials(String fullName, String username) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    final source = parts.isNotEmpty ? parts.first : username;
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }

  static String _lastSeen(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return 'recently';
    }
    final date = DateTime.tryParse(text)?.toLocal();
    if (date == null) {
      return text;
    }
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return 'just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }

  static String? _url(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }
    final path = text.startsWith('/') ? text : '/$text';
    return '${ApiConfig.baseUrl}$path';
  }
}
