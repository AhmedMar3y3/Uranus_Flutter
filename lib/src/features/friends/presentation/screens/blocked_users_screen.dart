import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/state_placeholder.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../profile/data/mock_users.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final blocked = MockUsers.blockedUsers;

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: SpaceBackground(
        child: blocked.isEmpty
            ? const StatePlaceholder(
                icon: Icons.block,
                title: 'No blocked users',
                body: 'People you block will appear here.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: blocked.length,
                itemBuilder: (context, index) {
                  final user = blocked[index];
                  return GlassPanel(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: UserAvatar(initials: user.initials),
                      title: Text(user.fullName),
                      subtitle: Text(
                        '@${user.username}',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      trailing: TextButton(
                        onPressed: () {},
                        child: const Text('Unblock'),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
