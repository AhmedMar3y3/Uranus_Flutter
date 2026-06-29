import 'dart:async';

import 'package:flutter/material.dart';

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
    _redirectTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.login);
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
