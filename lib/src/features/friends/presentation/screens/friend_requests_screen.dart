import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/refreshable_placeholder.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/entities/friend_request.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  late Future<FriendRequests> _future = _loadRequests();

  Future<FriendRequests> _loadRequests() {
    return AppDependencies.friendsRepository.getRequests();
  }

  Future<void> _refresh() async {
    final next = _loadRequests();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {}
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      await _refresh();
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
      appBar: AppBar(title: const Text('Friend requests')),
      body: SpaceBackground(
        child: FutureBuilder<FriendRequests>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return RefreshablePlaceholder(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load requests',
                body: readableError(snapshot.error),
                onRefresh: _refresh,
              );
            }

            final requests = snapshot.data!;
            if (requests.received.isEmpty && requests.sent.isEmpty) {
              return RefreshablePlaceholder(
                icon: Icons.pending_actions_outlined,
                title: 'No pending requests',
                body: 'Received and sent friend requests will appear here.',
                onRefresh: _refresh,
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  _SectionTitle(
                    title: 'Received Requests',
                    count: requests.received.length,
                  ),
                  const SizedBox(height: 8),
                  for (final request in requests.received)
                    _RequestTile(
                      request: request,
                      actions: [
                        IconButton.filledTonal(
                          tooltip: 'Accept',
                          onPressed: () => _runAction(
                            () => AppDependencies.friendsRepository.accept(
                              request.user.id,
                            ),
                          ),
                          icon: const Icon(Icons.check),
                        ),
                        IconButton(
                          tooltip: 'Reject',
                          onPressed: () => _runAction(
                            () => AppDependencies.friendsRepository.reject(
                              request.user.id,
                            ),
                          ),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    title: 'Sent Requests',
                    count: requests.sent.length,
                  ),
                  const SizedBox(height: 8),
                  for (final request in requests.sent)
                    _RequestTile(
                      request: request,
                      actions: [
                        IconButton(
                          tooltip: 'Cancel',
                          onPressed: () => _runAction(
                            () => AppDependencies.friendsRepository.cancel(
                              request.user.id,
                            ),
                          ),
                          icon: const Icon(Icons.undo),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$title ($count)',
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.actions});

  final FriendRequest request;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final user = request.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        child: ListTile(
          minVerticalPadding: 14,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: UserAvatar(
            initials: user.initials,
            imageUrl: user.imageUrl,
            isOnline: user.isOnline,
          ),
          title: Text(
            user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '@${user.username}',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          trailing: SizedBox(
            width: (actions.length * 48).toDouble(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ),
        ),
      ),
    );
  }
}
