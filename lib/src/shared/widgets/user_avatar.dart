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
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.transparent,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF183A75), Color(0xFF132246)],
                ),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: .28)),
              ),
              child: imageUrl == null || imageUrl!.isEmpty
                  ? Text(
                      initials,
                      style: TextStyle(
                        color: AppTheme.cyan,
                        fontSize: size * .32,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : ClipOval(
                      child: Image.network(
                        imageUrl!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Text(
                          initials,
                          style: TextStyle(
                            color: AppTheme.cyan,
                            fontSize: size * .32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: size * .22,
              height: size * .22,
              decoration: BoxDecoration(
                color: isOnline ? Colors.greenAccent : Colors.blueGrey,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.space, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
