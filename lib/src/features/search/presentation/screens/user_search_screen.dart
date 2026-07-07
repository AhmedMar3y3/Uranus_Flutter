import 'dart:async';

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

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<AppUser>> _future = AppDependencies.profileRepository.searchUsers(
    '',
  );

  Future<List<AppUser>> _loadCurrentQuery() {
    return AppDependencies.profileRepository.searchUsers(
      _controller.text.trim(),
    );
  }

  Future<void> _refresh() async {
    final next = _loadCurrentQuery();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _future = AppDependencies.profileRepository.searchUsers(value.trim());
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SpaceBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: GlassPanel(
                padding: const EdgeInsets.all(18),
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
                    TextField(
                      controller: _controller,
                      onChanged: _search,
                      decoration: const InputDecoration(
                        hintText: 'Search username or full name',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<AppUser>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return RefreshablePlaceholder(
                        icon: Icons.cloud_off_outlined,
                        title: 'Search unavailable',
                        body: readableError(
                          snapshot.error,
                          fallback: 'Check your connection and try again.',
                        ),
                        onRefresh: _refresh,
                      );
                    }

                    final users = snapshot.data ?? const <AppUser>[];
                    if (users.isEmpty) {
                      return RefreshablePlaceholder(
                        icon: Icons.manage_search,
                        title: 'No users found',
                        body: 'Try a different username or full name.',
                        onRefresh: _refresh,
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return GlassPanel(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            minVerticalPadding: 14,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRouter.publicProfile,
                              arguments: user,
                            ),
                            leading: UserAvatar(
                              initials: user.initials,
                              imageUrl: user.imageUrl,
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
