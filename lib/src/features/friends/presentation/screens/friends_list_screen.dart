import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/state_placeholder.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../profile/data/mock_users.dart';
import '../../../profile/domain/entities/app_user.dart';

class FriendsListScreen extends StatelessWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final friends = MockUsers.users
        .where((user) => user.friendshipStatus == FriendshipStatus.friends)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.friendRequests),
            icon: const Icon(Icons.pending_actions_outlined),
          ),
        ],
      ),
      body: SpaceBackground(
        child: friends.isEmpty
            ? const StatePlaceholder(
                icon: Icons.group_outlined,
                title: 'No friends yet',
                body:
                    'Accepted friends will show here with message and remove actions.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
                itemCount: friends.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return GlassPanel(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: UserAvatar(
                        initials: friend.initials,
                        isOnline: friend.isOnline,
                      ),
                      title: Text(
                        friend.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        friend.statusLabel,
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.message_outlined),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.person_remove_outlined),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
