import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../app/router.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/refreshable_placeholder.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../profile/domain/entities/app_user.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  late Future<List<AppUser>> _future = _loadFriends();

  Future<List<AppUser>> _loadFriends() {
    return AppDependencies.friendsRepository.getFriends();
  }

  Future<void> _refresh() async {
    final next = _loadFriends();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
        child: FutureBuilder<List<AppUser>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return RefreshablePlaceholder(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load friends',
                body: readableError(
                  snapshot.error,
                  fallback:
                      'Pull down to refresh after checking your connection.',
                ),
                onRefresh: _refresh,
              );
            }

            final friends = snapshot.data ?? const <AppUser>[];
            if (friends.isEmpty) {
              return RefreshablePlaceholder(
                icon: Icons.group_outlined,
                title: 'No friends yet',
                body:
                    'Accepted friends will show here with message and remove actions.',
                onRefresh: _refresh,
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: friends.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return GlassPanel(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: UserAvatar(
                        initials: friend.initials,
                        imageUrl: friend.imageUrl,
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
                            onPressed: () async {
                              try {
                                final conversation = await AppDependencies
                                    .chatRepository
                                    .startConversation(friend.id);
                                if (!context.mounted) {
                                  return;
                                }
                                Navigator.of(context).pushNamed(
                                  AppRouter.chat,
                                  arguments: conversation,
                                );
                              } catch (error) {
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(readableError(error))),
                                );
                              }
                            },
                            icon: const Icon(Icons.message_outlined),
                          ),
                          IconButton(
                            onPressed: () async {
                              try {
                                await AppDependencies.friendsRepository.remove(
                                  friend.id,
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
                            icon: const Icon(Icons.person_remove_outlined),
                          ),
                        ],
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
