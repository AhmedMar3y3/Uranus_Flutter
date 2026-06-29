import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../data/mock_users.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const user = MockUsers.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.blockedUsers),
            icon: const Icon(Icons.block),
          ),
        ],
      ),
      body: SpaceBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassPanel(
              child: Column(
                children: [
                  const AppLogo(size: 92, showGlow: false),
                  const SizedBox(height: 16),
                  UserAvatar(
                    initials: user.initials,
                    isOnline: user.isOnline,
                    size: 104,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    user.fullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '@${user.username}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.cyan),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    user.bio,
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
                  _InfoRow(label: 'Friends', value: '${user.friendsCount}'),
                  _InfoRow(label: 'Presence', value: user.statusLabel),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile'),
            ),
          ],
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
