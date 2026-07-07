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
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {}
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AppDependencies.notificationService.deleteTokenIfAuthenticated();
    } catch (_) {}
    await AppDependencies.presenceService.stopForegroundSession();
    await AppDependencies.sessionManager.clear();
    if (!context.mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
  }

  Future<void> _editProfile(AppUser user) async {
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRouter.editProfile, arguments: user);
    if (result is AppUser) {
      setState(() {
        _future = Future.value(result);
      });
    } else {
      await _refresh();
    }
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
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                children: [
                  GlassPanel(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.cyan.withValues(alpha: .18),
                                AppTheme.violet.withValues(alpha: .12),
                                AppTheme.surface.withValues(alpha: .28),
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              UserAvatar(
                                initials: user.initials,
                                imageUrl: user.imageUrl,
                                isOnline: user.isOnline,
                                size: 112,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                user.fullName,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${user.username}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.cyan,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                user.bio.isEmpty ? 'No bio yet.' : user.bio,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _editProfile(user),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit profile'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton.filledTonal(
                                tooltip: 'Blocked users',
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRouter.blockedUsers),
                                icon: const Icon(Icons.block),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Friends',
                          value: '${user.friendsCount}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          label: 'Gender',
                          value: user.gender.name,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GlassPanel(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          user.isOnline
                              ? Icons.radio_button_checked
                              : Icons.timelapse,
                          color: user.isOnline ? AppTheme.teal : AppTheme.cyan,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Presence',
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.statusLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
