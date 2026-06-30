import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../app/router.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/entities/app_user.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({AppUser? user, super.key})
    : initialUser =
          user ??
          const AppUser(
            id: '',
            username: 'unknown',
            fullName: 'Unknown user',
            initials: 'UU',
            gender: Gender.other,
            bio: '',
            friendsCount: 0,
            isOnline: false,
            lastSeen: 'recently',
          );

  final AppUser initialUser;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<AppUser> _future = AppDependencies.profileRepository
      .getUserProfile(widget.initialUser.id);

  Future<void> _refresh() async {
    final next = AppDependencies.profileRepository.getUserProfile(
      widget.initialUser.id,
    );
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  Future<void> _friendAction(Future<void> Function() action) async {
    try {
      await action();
      setState(() {
        _future = AppDependencies.profileRepository.getUserProfile(
          widget.initialUser.id,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(readableError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('@${widget.initialUser.username}')),
      body: SpaceBackground(
        child: FutureBuilder<AppUser>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = snapshot.data ?? widget.initialUser;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  if (snapshot.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassPanel(
                        child: Text(
                          readableError(
                            snapshot.error,
                            fallback:
                                'Could not refresh this profile. Showing the last available user data.',
                          ),
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  GlassPanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        UserAvatar(
                          initials: user.initials,
                          imageUrl: user.imageUrl,
                          isOnline: user.isOnline,
                          size: 104,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          user.fullName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Metric(
                          value: '${user.friendsCount}',
                          label: 'Friends',
                        ),
                        _Metric(
                          value: '${user.mutualFriendsCount}',
                          label: 'Mutual',
                        ),
                        _Metric(value: user.gender.name, label: 'Gender'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _FriendshipActions(user: user, onAction: _friendAction),
                ],
              ),
            );
          },
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
  const _FriendshipActions({required this.user, required this.onAction});

  final AppUser user;
  final Future<void> Function(Future<void> Function() action) onAction;

  @override
  Widget build(BuildContext context) {
    return switch (user.friendshipStatus) {
      FriendshipStatus.none || FriendshipStatus.rejected => ElevatedButton.icon(
        onPressed: () => onAction(
          () => AppDependencies.friendsRepository.sendRequest(user.id),
        ),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Friend'),
      ),
      FriendshipStatus.pending => OutlinedButton.icon(
        onPressed: () =>
            onAction(() => AppDependencies.friendsRepository.cancel(user.id)),
        icon: const Icon(Icons.schedule),
        label: const Text('Cancel Request'),
      ),
      FriendshipStatus.friends => Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final conversation = await AppDependencies.chatRepository
                      .startConversation(user.id);
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(
                    context,
                  ).pushNamed(AppRouter.chat, arguments: conversation);
                } catch (error) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(readableError(error))));
                }
              },
              icon: const Icon(Icons.message),
              label: const Text('Message'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => onAction(
                () => AppDependencies.friendsRepository.remove(user.id),
              ),
              child: const Text('Remove'),
            ),
          ),
        ],
      ),
      FriendshipStatus.blocked => ElevatedButton.icon(
        onPressed: () =>
            onAction(() => AppDependencies.friendsRepository.unblock(user.id)),
        icon: const Icon(Icons.lock_open),
        label: const Text('Unblock'),
      ),
    };
  }
}
