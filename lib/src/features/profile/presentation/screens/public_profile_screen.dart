import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../data/mock_users.dart';
import '../../domain/entities/app_user.dart';

class PublicProfileScreen extends StatelessWidget {
  PublicProfileScreen({AppUser? user, super.key})
    : user = user ?? MockUsers.users.first;

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('@${user.username}')),
      body: SpaceBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassPanel(
              child: Column(
                children: [
                  UserAvatar(
                    initials: user.initials,
                    isOnline: user.isOnline,
                    size: 104,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    user.fullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    user.statusLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 18),
                  Text(user.bio, textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassPanel(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Metric(value: '${user.friendsCount}', label: 'Friends'),
                  _Metric(value: '${user.mutualFriendsCount}', label: 'Mutual'),
                  _Metric(value: user.gender.name, label: 'Gender'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _FriendshipActions(status: user.friendshipStatus),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        Text(label, style: const TextStyle(color: AppTheme.textMuted)),
      ],
    );
  }
}

class _FriendshipActions extends StatelessWidget {
  const _FriendshipActions({required this.status});

  final FriendshipStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      FriendshipStatus.none => ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Friend'),
      ),
      FriendshipStatus.requestSent => OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.schedule),
        label: const Text('Request Sent'),
      ),
      FriendshipStatus.requestReceived => Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Accept'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Reject'),
            ),
          ),
        ],
      ),
      FriendshipStatus.friends => Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.message),
              label: const Text('Message'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Friends'),
            ),
          ),
        ],
      ),
      FriendshipStatus.blocked => ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.lock_open),
        label: const Text('Unblock'),
      ),
    };
  }
}
