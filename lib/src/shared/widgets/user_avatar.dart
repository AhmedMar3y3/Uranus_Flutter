import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.initials,
    this.imageUrl,
    this.isOnline = false,
    this.size = 52,
    super.key,
  });

  final String initials;
  final String? imageUrl;
  final bool isOnline;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1D4F8F), Color(0xFF151B3B)],
                ),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: .32)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: .12),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl == null || imageUrl!.isEmpty
                    ? Center(
                        child: _Initials(initials: initials, size: size),
                      )
                    : Image.network(
                        imageUrl!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: _Initials(initials: initials, size: size),
                        ),
                      ),
              ),
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: size * .23,
                height: size * .23,
                decoration: BoxDecoration(
                  color: isOnline ? AppTheme.teal : Colors.blueGrey,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.space, width: 2),
                  boxShadow: isOnline
                      ? [
                          BoxShadow(
                            color: AppTheme.teal.withValues(alpha: .45),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: TextStyle(
        color: AppTheme.cyan,
        fontSize: size * .32,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
