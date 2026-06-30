import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/space_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(const Duration(milliseconds: 500), () async {
      if (mounted) {
        final hasToken = await AppDependencies.sessionManager.hasToken;
        final completedProfile =
            await AppDependencies.sessionManager.completedProfile;
        if (hasToken) {
          unawaited(
            AppDependencies.notificationService.registerTokenIfAuthenticated(),
          );
        }
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacementNamed(
          hasToken
              ? completedProfile
                    ? AppRouter.shell
                    : AppRouter.completeProfile
              : AppRouter.login,
        );
      }
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 118),
              const SizedBox(height: 22),
              Text(
                'Uranus',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Private chats in a quieter orbit',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 96,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(99),
                  color: AppTheme.cyan,
                  backgroundColor: Colors.white.withValues(alpha: .08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
