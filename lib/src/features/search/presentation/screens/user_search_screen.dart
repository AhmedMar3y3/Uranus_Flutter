import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/state_placeholder.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../profile/data/mock_users.dart';

class UserSearchScreen extends StatelessWidget {
  const UserSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = MockUsers.users;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SpaceBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find your orbit',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search username or full name',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? const StatePlaceholder(
                      icon: Icons.manage_search,
                      title: 'No users found',
                      body: 'Try a different username or full name.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return GlassPanel(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRouter.publicProfile,
                              arguments: user,
                            ),
                            leading: UserAvatar(
                              initials: user.initials,
                              isOnline: user.isOnline,
                            ),
                            title: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '@${user.username}',
                              style: const TextStyle(color: AppTheme.textMuted),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
