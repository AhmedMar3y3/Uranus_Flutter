import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SpaceBackground extends StatelessWidget {
  const SpaceBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF02040D),
            AppTheme.space,
            Color(0xFF071635),
            Color(0xFF0D2844),
          ],
        ),
      ),
      child: CustomPaint(
        painter: const _SpacePainter(),
        child: SafeArea(child: child),
      ),
    );
  }
}

class _SpacePainter extends CustomPainter {
  const _SpacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white.withValues(alpha: .55);
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppTheme.cyan.withValues(alpha: .16);
    final violetPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppTheme.violet.withValues(alpha: .12);
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .45
      ..color = AppTheme.cyan.withValues(alpha: .045);

    final stars = <Offset>[
      Offset(size.width * .12, size.height * .08),
      Offset(size.width * .28, size.height * .16),
      Offset(size.width * .82, size.height * .13),
      Offset(size.width * .62, size.height * .24),
      Offset(size.width * .16, size.height * .36),
      Offset(size.width * .9, size.height * .39),
      Offset(size.width * .48, size.height * .52),
      Offset(size.width * .08, size.height * .72),
      Offset(size.width * .74, size.height * .76),
      Offset(size.width * .35, size.height * .88),
    ];

    for (final star in stars) {
      canvas.drawCircle(star, 1.4, starPaint);
    }

    for (double x = 0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * .82, size.height * .1),
        radius: size.width * .5,
      ),
      .45,
      2.7,
      false,
      accentPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * -.1, size.height * .82),
        radius: size.width * .62,
      ),
      5.1,
      2.2,
      false,
      violetPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
