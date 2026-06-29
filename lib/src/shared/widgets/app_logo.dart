import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 92, this.showGlow = true, super.key});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF112B5F), Color(0xFF091021), Color(0xFF1C3E72)],
        ),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: .55)),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppTheme.cyan.withValues(alpha: .28),
                  blurRadius: 36,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: Image.asset(AppAssets.icon, fit: BoxFit.contain),
    );
  }
}
