import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.gradient,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          gradient:
              gradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.surfaceGlow.withValues(alpha: .72),
                  AppTheme.surface.withValues(alpha: .94),
                ],
              ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppTheme.cyan.withValues(alpha: .04),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
