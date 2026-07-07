import 'dart:async';

import 'package:flutter/material.dart';

import 'app_dependencies.dart';
import 'router.dart';
import '../core/theme/app_theme.dart';

class UranusApp extends StatefulWidget {
  const UranusApp({super.key});

  @override
  State<UranusApp> createState() => _UranusAppState();
}

class _UranusAppState extends State<UranusApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(AppDependencies.presenceService.startForegroundSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(AppDependencies.presenceService.stopForegroundSession());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(AppDependencies.presenceService.startForegroundSession());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(AppDependencies.presenceService.stopForegroundSession());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uranus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      navigatorKey: AppRouter.navigatorKey,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
