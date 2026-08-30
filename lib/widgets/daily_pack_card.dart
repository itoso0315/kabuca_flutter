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
              'スタートパック',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.deepGreen,
                fontWeight: FontWeight.w600,
              ),
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
      label: 'KABUCAスタートパック',
      child: Container(
        width: 176,
        height: 264,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF123C31), Color(0xFF071A15), Color(0xFF030A08)],
          ),
          borderRadius: BorderRadius.circular(8),
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
                '‹ ─── OPEN ─── ›',
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
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Color(0xFFFFD879)),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: Color(0xFFFFD879),
                        size: 30,
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'KABUCA',
                    style: TextStyle(
                      color: Color(0xFFFFE2A0),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    'START PACK',
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
                  '3 CARDS',
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

    for (double y = 52; y < 226; y += 22) {
      for (double x = -11; x < size.width; x += 22) {
        final diamond = Path()
          ..moveTo(x, y + 11)
          ..lineTo(x + 11, y)
          ..lineTo(x + 22, y + 11)
          ..lineTo(x + 11, y + 22)
          ..close();
        canvas.drawPath(diamond, faintGold);
      }
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
