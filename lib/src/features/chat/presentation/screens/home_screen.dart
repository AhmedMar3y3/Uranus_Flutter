import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../app/router.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/state_placeholder.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/entities/conversation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filter = 'All';
  late Future<List<Conversation>> _future = _loadConversations();

  Future<List<Conversation>> _loadConversations() {
    return AppDependencies.chatRepository.getConversations();
  }

  Future<void> _refresh() async {
    final next = _loadConversations();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // FutureBuilder renders the error state; refresh should still finish.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        child: FutureBuilder<List<Conversation>>(
          future: _future,
          builder: (context, snapshot) {
            final allConversations = snapshot.data ?? const <Conversation>[];
            final conversations = allConversations.where((item) {
              return switch (_filter) {
                'Unread' => item.unreadCount > 0,
                'Online' => item.friend.isOnline,
                _ => true,
              };
            }).toList();
            final online = allConversations
                .where((item) => item.friend.isOnline)
                .toList();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: const Text('Uranus'),
                    leading: const Padding(
                      padding: EdgeInsets.all(8),
                      child: AppLogo(size: 40, showGlow: false),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRouter.friendRequests),
                        icon: const Icon(Icons.person_add_alt),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: _HomeHeader(
                        filter: _filter,
                        online: online,
                        onFilterChanged: (filter) =>
                            setState(() => _filter = filter),
                      ),
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      child: StatePlaceholder(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load conversations',
                        body: readableError(
                          snapshot.error,
                          fallback: 'Pull down to refresh or login again.',
                        ),
                      ),
                    )
                  else if (conversations.isEmpty)
                    const SliverFillRemaining(
                      child: StatePlaceholder(
                        icon: Icons.forum_outlined,
                        title: 'No conversations yet',
                        body:
                            'When friends message you, their latest chats appear here.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                      sliver: SliverList.separated(
                        itemCount: conversations.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _ConversationTile(
                          conversation: conversations[index],
                          onChanged: _refresh,
                        ),
                      ),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.filter,
    required this.online,
    required this.onFilterChanged,
  });

  final String filter;
  final List<Conversation> online;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Command deck',
                style: TextStyle(color: AppTheme.cyan, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                'Signal room',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Live friends, quiet chats, and unread messages in one orbit.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'All', label: Text('All')),
              ButtonSegment(value: 'Unread', label: Text('Unread')),
              ButtonSegment(value: 'Online', label: Text('Online')),
            ],
            selected: {filter},
            onSelectionChanged: (selection) => onFilterChanged(selection.first),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 94,
          child: online.isEmpty
              ? const GlassPanel(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.radar_outlined, color: AppTheme.cyan),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No friends are online right now.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: online.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final friend = online[index].friend;
                    return GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: SizedBox(
                        width: 68,
                        child: Column(
                          children: [
                            UserAvatar(
                              initials: friend.initials,
                              imageUrl: friend.imageUrl,
                              isOnline: true,
                              size: 48,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              friend.username,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onChanged,
  });

  final Conversation conversation;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final friend = conversation.friend;
    final latest = conversation.latestMessage;

    return GlassPanel(
      padding: EdgeInsets.zero,
      child: ListTile(
        minVerticalPadding: 14,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () async {
          await Navigator.of(
            context,
          ).pushNamed(AppRouter.chat, arguments: conversation);
          await onChanged();
        },
        leading: UserAvatar(
          initials: friend.initials,
          imageUrl: friend.imageUrl,
          isOnline: friend.isOnline,
        ),
        title: Text(
          friend.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          conversation.isTyping
              ? '${friend.username} is typing...'
              : latest?.body ?? 'No messages yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: conversation.isTyping ? AppTheme.cyan : AppTheme.textMuted,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 70,
              child: Text(
                conversation.latestTimestamp,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
            if (conversation.unreadCount > 0) ...[
              const SizedBox(height: 6),
              Badge(label: Text('${conversation.unreadCount}')),
            ],
          ],
        ),
      ),
    );
  }
}
