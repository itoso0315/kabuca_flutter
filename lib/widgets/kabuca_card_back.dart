import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class KabucaCardBack extends StatelessWidget {
  const KabucaCardBack({super.key, this.width = 250, this.height = 350});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Container(
      key: const Key('kabuca-card-back'),
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE6A4), Color(0xFFA77A2B), Color(0xFFFFE8A9)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [Color(0xFF123C31), Color(0xFF06130F)],
            radius: 1.05,
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.mutedGold),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _BackPatternPainter()),
            ),
            Center(
              child: Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.mutedGold, width: 1.5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFFFFD978),
                      size: 43,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'KABUCA',
                      style: TextStyle(
                        color: Color(0xFFFFE6A4),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BackPatternPainter extends CustomPainter {
  const _BackPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x22D6B870)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    const step = 28.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        final path = Path()
          ..moveTo(x, y + step / 2)
          ..lineTo(x + step / 2, y)
          ..lineTo(x + step, y + step / 2)
          ..lineTo(x + step / 2, y + step)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
