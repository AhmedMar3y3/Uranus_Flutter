import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../profile/data/mock_users.dart';
import '../../../profile/domain/entities/app_user.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final received = MockUsers.users
        .where(
          (user) => user.friendshipStatus == FriendshipStatus.requestReceived,
        )
        .toList();
    final sent = MockUsers.users
        .where((user) => user.friendshipStatus == FriendshipStatus.requestSent)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Friend requests')),
      body: SpaceBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Received Requests',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            for (final user in received)
              _RequestTile(user: user, actions: const ['Accept', 'Reject']),
            const SizedBox(height: 24),
            const Text(
              'Sent Requests',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            for (final user in sent)
              _RequestTile(user: user, actions: const ['Cancel']),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.user, required this.actions});

  final AppUser user;
  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: UserAvatar(initials: user.initials, isOnline: user.isOnline),
        title: Text(user.fullName),
        subtitle: Text(
          '@${user.username}',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        trailing: Wrap(
          spacing: 6,
          children: [
            for (final action in actions)
              TextButton(onPressed: () {}, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
