import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/state_placeholder.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../data/mock_conversations.dart';
import '../../domain/entities/conversation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final conversations = MockConversations.conversations.where((item) {
      return switch (_filter) {
        'Unread' => item.unreadCount > 0,
        'Online' => item.friend.isOnline,
        _ => true,
      };
    }).toList();
    final online = MockConversations.conversations
        .where((item) => item.friend.isOnline)
        .toList();

    return Scaffold(
      body: SpaceBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Uranus'),
              leading: const Padding(
                padding: EdgeInsets.all(8),
                child: AppLogo(showGlow: false),
              ),
              actions: [
                IconButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRouter.friendRequests),
                  icon: const Icon(Icons.person_add_alt),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signal room',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Live friends, quiet chats, and unread messages in one orbit.',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          const TextField(
                            decoration: InputDecoration(
                              hintText: 'Search conversations',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final filter in ['All', 'Unread', 'Online'])
                          ChoiceChip(
                            label: Text(filter),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 94,
                      child: ListView.separated(
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
                              width: 66,
                              child: Column(
                                children: [
                                  UserAvatar(
                                    initials: friend.initials,
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
                ),
              ),
            ),
            if (conversations.isEmpty)
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                sliver: SliverList.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _ConversationTile(conversation: conversations[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final friend = conversation.friend;
    final latest = conversation.latestMessage;

    return GlassPanel(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRouter.chat, arguments: conversation),
        leading: UserAvatar(
          initials: friend.initials,
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
            Text(
              conversation.latestTimestamp,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
