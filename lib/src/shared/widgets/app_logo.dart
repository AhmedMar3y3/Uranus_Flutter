import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 92, this.showGlow = true, super.key});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * .04),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.cyan.withValues(alpha: .42)),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: .22),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(AppAssets.icon, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
