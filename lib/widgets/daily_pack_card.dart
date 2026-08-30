                            import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class DailyPackCard extends StatelessWidget {
  const DailyPackCard({
    super.key,
    required this.onOpen,
    required this.packCount,
  });

  final VoidCallback? onOpen;
  final int packCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: Column(
          children: [
            Text(
              'KABUCA PACK',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '所持パック  $packCount',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            const _PackVisual(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('パックを開ける'),
              ),
            ),
            if (packCount == 0) ...[
              const SizedBox(height: 12),
              Text(
                'パックを獲得しよう',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PackVisual extends StatelessWidget {
  const _PackVisual();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'KABUCAデイリーパック',
      child: Container(
        width: 176,
        height: 264,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF08715C), Color(0xFF063B31)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8B45E), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25103E31),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _PackPainter())),
            const Positioned(left: 0, right: 0, top: 7, child: _SealLine()),
            const Positioned(left: 0, right: 0, top: 12, child: _SealLine()),
            const Positioned(left: 0, right: 0, top: 17, child: _SealLine()),
            const Positioned(left: 0, right: 0, bottom: 7, child: _SealLine()),
            const Positioned(left: 0, right: 0, bottom: 12, child: _SealLine()),
            const Positioned(left: 0, right: 0, bottom: 17, child: _SealLine()),
            const Positioned(
              top: 28,
              left: 18,
              child: Text(
                'OPEN  ›››  ─────────  ›',
                style: TextStyle(
                  color: Color(0xFFFFE4A0),
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFFFFD879),
                    size: 42,
                  ),
                  SizedBox(height: 3),
                  Text(
                    'KABUCA',
                    style: TextStyle(
                      color: Color(0xFFFFE2A0),
                      fontFamily: 'serif',
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.7,
                    ),
                  ),
                  Text(
                    'STOCK  ×  CARD',
                    style: TextStyle(
                      color: Color(0xFFFFE2A0),
                      fontSize: 6.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 36,
              left: 38,
              right: 38,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF073E34),
                  border: Border.all(color: const Color(0xFFD8B45E)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'DAILY PACK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFE2A0),
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackPainter extends CustomPainter {
  const _PackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = const Color(0xFFD8B45E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final faintGold = Paint()
      ..color = const Color(0x45D8B45E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    for (var i = 0; i < 6; i++) {
      final x = 18.0 + i * 24;
      canvas.drawLine(Offset(x, 55), Offset(x, 188), faintGold);
    }

    final chart = Path()
      ..moveTo(4, 181)
      ..cubicTo(38, 172, 50, 143, 81, 139)
      ..cubicTo(111, 135, 133, 104, 174, 90);
    canvas.drawPath(chart, gold);

    final whitePanel = Path()
      ..moveTo(0, 188)
      ..cubicTo(43, 161, 91, 174, 176, 128)
      ..lineTo(176, 222)
      ..cubicTo(121, 187, 72, 188, 0, 228)
      ..close();
    canvas.drawPath(whitePanel, Paint()..color = const Color(0xFFF6F0E2));

    final upperEdge = Path()
      ..moveTo(0, 188)
      ..cubicTo(43, 161, 91, 174, 176, 128);
    final lowerEdge = Path()
      ..moveTo(0, 228)
      ..cubicTo(72, 188, 121, 187, 176, 222);
    canvas.drawPath(upperEdge, gold..strokeWidth = 2.2);
    canvas.drawPath(lowerEdge, gold);

    final candlePaint = Paint()..color = const Color(0x789FB673);
    const heights = [24.0, 35.0, 20.0, 43.0, 29.0, 48.0];
    for (var i = 0; i < heights.length; i++) {
      final x = 13.0 + i * 17;
      final top = 178 - heights[i];
      canvas.drawLine(Offset(x + 4, top - 8), Offset(x + 4, 184), faintGold);
      canvas.drawRect(Rect.fromLTWH(x, top, 8, heights[i]), candlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SealLine extends StatelessWidget {
  const _SealLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.mutedGold.withValues(alpha: 0.7),
    );
  }
}
