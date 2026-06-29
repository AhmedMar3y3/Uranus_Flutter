import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class StatePlaceholder extends StatelessWidget {
  const StatePlaceholder({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.cyan, size: 40),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
