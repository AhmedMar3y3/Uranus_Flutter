import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/refreshable_placeholder.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../profile/domain/entities/app_user.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late Future<List<AppUser>> _future = _loadBlocked();

  Future<List<AppUser>> _loadBlocked() {
    return AppDependencies.friendsRepository.getBlockedUsers();
  }

  Future<void> _refresh() async {
    final next = _loadBlocked();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: SpaceBackground(
        child: FutureBuilder<List<AppUser>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return RefreshablePlaceholder(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load blocked users',
                body: readableError(snapshot.error),
                onRefresh: _refresh,
              );
            }

            final users = snapshot.data ?? const <AppUser>[];
            if (users.isEmpty) {
              return RefreshablePlaceholder(
                icon: Icons.block,
                title: 'No blocked users',
                body: 'People you block will appear here.',
                onRefresh: _refresh,
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return GlassPanel(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: UserAvatar(
                        initials: user.initials,
                        imageUrl: user.imageUrl,
                      ),
                      title: Text(user.fullName),
                      subtitle: Text(
                        '@${user.username}',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          try {
                            await AppDependencies.friendsRepository.unblock(
                              user.id,
                            );
                            await _refresh();
                          } catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(readableError(error))),
                            );
                          }
                        },
                        child: const Text('Unblock'),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
