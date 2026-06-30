import 'package:flutter/material.dart';

import 'router.dart';
import '../core/theme/app_theme.dart';

class UranusApp extends StatelessWidget {
  const UranusApp({super.key});

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
