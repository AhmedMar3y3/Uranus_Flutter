import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../app/router.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/refreshable_placeholder.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/entities/app_user.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late Future<AppUser> _future = _loadProfile();

  Future<AppUser> _loadProfile() {
    return AppDependencies.profileRepository.getCurrentUser();
  }

  Future<void> _refresh() async {
    final next = _loadProfile();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AppDependencies.notificationService.deleteTokenIfAuthenticated();
    } catch (_) {
      // Logout should still clear the local session if token cleanup fails.
    }
    await AppDependencies.sessionManager.clear();
    if (!context.mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SpaceBackground(
        child: FutureBuilder<AppUser>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return RefreshablePlaceholder(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load profile',
                body: readableError(snapshot.error),
                onRefresh: _refresh,
              );
            }

            final user = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  GlassPanel(
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
                          '@${user.username}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.cyan),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          user.bio.isEmpty ? 'No bio yet.' : user.bio,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassPanel(
                    child: Column(
                      children: [
                        _InfoRow(label: 'Gender', value: user.gender.name),
                        _InfoRow(
                          label: 'Friends',
                          value: '${user.friendsCount}',
                        ),
                        _InfoRow(label: 'Presence', value: user.statusLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
