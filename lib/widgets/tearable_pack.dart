import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_theme.dart';

class TearablePack extends StatefulWidget {
  const TearablePack({super.key, required this.onOpened});

  final VoidCallback onOpened;

  @override
  TearablePackState createState() => TearablePackState();
}

class TearablePackState extends State<TearablePack>
    with TickerProviderStateMixin {
  static const _completionThreshold = 0.7;

  late final AnimationController _progress;
  late final AnimationController _completionLift;
  late final AnimationController _guidance;
  Offset _dragStartPosition = Offset.zero;
  double _activeTearDistance = 248;
  double _progressAtDragStart = 0;
  bool _trackingGesture = false;
  bool _gestureActivated = false;
  bool _eligibleStart = false;
  bool _opened = false;
  bool _guidanceVisible = true;

  double get progress => _progress.value;
  bool get isOpened => _opened;
  bool get isGuidanceVisible => _guidanceVisible;
  double get guidanceProgress => _guidance.value;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, value: 0);
    _completionLift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _guidance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    _completionLift.dispose();
    _guidance.dispose();
    super.dispose();
  }

  void _onPanDown(DragDownDetails details) {
    if (_opened) return;
    final position = details.localPosition;
    _eligibleStart = position.dy <= 126 && position.dx <= 168;
    _dragStartPosition = position;
    if (_eligibleStart && _guidanceVisible) {
      _guidance.stop();
      setState(() => _guidanceVisible = false);
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_opened || !_eligibleStart) return;
    _trackingGesture = true;
    _progress.stop();
    _activeTearDistance = math.max(140, 280 - _dragStartPosition.dx);
    _progressAtDragStart = _progress.value;
    _gestureActivated = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_trackingGesture || _opened) return;
    final offset = details.localPosition - _dragStartPosition;
    if (!_gestureActivated) {
      final horizontalIsPrimary = offset.dx >= offset.dy.abs() * 0.75;
      if (offset.dx < 10 || !horizontalIsPrimary) return;
      _gestureActivated = true;
    }
    final next = (_progressAtDragStart + offset.dx / _activeTearDistance).clamp(
      0.0,
      1.0,
    );
    _progress.value = next;
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (!_trackingGesture || _opened) return;
    _trackingGesture = false;
    _eligibleStart = false;
    if (!_gestureActivated) return;
    if (_progress.value < _completionThreshold) {
      await _progress.animateBack(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _progress.animateTo(
      1,
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeInCubic,
    );
    if (!mounted || _opened) return;
    _opened = true;
    HapticFeedback.mediumImpact();
    await _completionLift.forward();
    if (!mounted) return;
    widget.onOpened();
  }

  void _onPanCancel() {
    if (!_trackingGesture || _opened) return;
    _trackingGesture = false;
    _eligibleStart = false;
    _progress.animateBack(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'パック上部を左から右へ破る',
      value: '${(_progress.value * 100).round()}%',
      child: GestureDetector(
        key: const Key('tearable-pack'),
        behavior: HitTestBehavior.opaque,
        onPanDown: _onPanDown,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: _onPanCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([_progress, _completionLift, _guidance]),
          builder: (context, _) => _PackLayers(
            progress: _progress.value,
            completionLift: Curves.easeOutCubic.transform(
              _completionLift.value,
            ),
            guidanceProgress: _guidance.value,
            showGuidance: _guidanceVisible,
          ),
        ),
      ),
    );
  }
}

class _PackLayers extends StatelessWidget {
  const _PackLayers({
    required this.progress,
    required this.completionLift,
    required this.guidanceProgress,
    required this.showGuidance,
  });

  final double progress;
  final double completionLift;
  final double guidanceProgress;
  final bool showGuidance;

  @override
  Widget build(BuildContext context) {
    const width = 280.0;
    const height = 420.0;
    const tearY = 72.0;
    final tearX = width * progress;
    final gap = progress == 0 ? 0.0 : 1.2 + progress * 1.8;
    final glow = ((progress - 0.18) / 0.82).clamp(0.0, 1.0);

    if (progress == 0) {
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            const _PackBody(),
            if (showGuidance)
              Positioned(
                key: const Key('pack-open-guidance'),
                left: 28,
                right: 20,
                top: 31,
                height: 45,
                child: _OpenGuidance(progress: guidanceProgress),
              ),
          ],
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (progress < 1)
            Positioned(
              left: tearX,
              top: 0,
              width: width - tearX,
              height: height,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: width,
                  maxWidth: width,
                  minHeight: height,
                  maxHeight: height,
                  child: Transform.translate(
                    offset: Offset(-tearX, 0),
                    child: const SizedBox(
                      width: width,
                      height: height,
                      child: _PackBody(),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(0, -gap - completionLift * 16),
            child: ClipPath(
              clipper: _TornUpperClipper(tearX: tearX, tearY: tearY),
              child: const _PackBody(),
            ),
          ),
          Transform.translate(
            offset: Offset(0, gap),
            child: ClipPath(
              clipper: _TornLowerClipper(tearX: tearX, tearY: tearY),
              child: const _PackBody(),
            ),
          ),
          Positioned(
            left: 0,
            top: tearY - 11,
            width: math.max(1, tearX),
            height: 25,
            child: Opacity(
              opacity: glow,
              child: CustomPaint(
                painter: _TearEdgePainter(
                  progress: progress,
                  tension: progress > 0.72 ? (progress - 0.72) / 0.28 : 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenGuidance extends StatelessWidget {
  const _OpenGuidance({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + math.sin(progress * math.pi * 2) * 0.12;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: 4,
          top: 3,
          width: 72,
          height: 27,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFFFE3A1,
                  ).withValues(alpha: pulse * 0.42),
                  blurRadius: 13,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment(-1 + progress * 2, 0),
          child: Transform.rotate(
            angle: -0.18,
            child: Container(
              key: const Key('pack-open-guidance-sheen'),
              width: 42,
              height: 52,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x00FFE7AA),
                    Color(0x99FFE7AA),
                    Color(0x00FFE7AA),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PackBody extends StatelessWidget {
  const _PackBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF08715C), Color(0xFF032F27)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mutedGold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66102C24),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _PackBodyPainter()),
          ),
          for (final top in [10.0, 17.0, 24.0])
            Positioned(
              left: 8,
              right: 8,
              top: top,
              child: const Divider(height: 1, color: Color(0x779AD8C8)),
            ),
          const Positioned(
            left: 40,
            right: 18,
            top: 42,
            child: Text(
              'OPEN  ›››  ─────────────  ›',
              style: TextStyle(
                color: Color(0xFFFFE09A),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFFFFD879),
                  size: 68,
                ),
                SizedBox(height: 8),
                Text(
                  'KABUCA',
                  style: TextStyle(
                    color: Color(0xFFFFE2A0),
                    fontFamily: 'serif',
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
                Text(
                  'STOCK  ×  CARD',
                  style: TextStyle(
                    color: Color(0xFFFFE2A0),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 52,
            right: 52,
            bottom: 31,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.mutedGold),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'START PACK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFE2A0),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _tearOffset(double x) =>
    math.sin(x * 0.43) * 3.2 + math.sin(x * 0.17) * 1.8;

class _TornUpperClipper extends CustomClipper<Path> {
  const _TornUpperClipper({required this.tearX, required this.tearY});

  final double tearX;
  final double tearY;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(tearX, 0)
      ..lineTo(tearX, tearY + _tearOffset(tearX));
    for (double x = tearX; x >= 0; x -= 5) {
      path.lineTo(x, tearY + _tearOffset(x));
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant _TornUpperClipper oldClipper) =>
      oldClipper.tearX != tearX || oldClipper.tearY != tearY;
}

class _TornLowerClipper extends CustomClipper<Path> {
  const _TornLowerClipper({required this.tearX, required this.tearY});

  final double tearX;
  final double tearY;

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, tearY + _tearOffset(0));
    for (double x = 0; x <= tearX; x += 5) {
      path.lineTo(x, tearY + _tearOffset(x));
    }
    return path
      ..lineTo(tearX, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _TornLowerClipper oldClipper) =>
      oldClipper.tearX != tearX || oldClipper.tearY != tearY;
}

class _TearEdgePainter extends CustomPainter {
  const _TearEdgePainter({required this.progress, required this.tension});

  final double progress;
  final double tension;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final shadow = Paint()
      ..color = const Color(0xCC021A15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final glow = Paint()
      ..color = Color.lerp(
        const Color(0xAAFFE6A5),
        const Color(0xFFFFF3CC),
        progress,
      )!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final fiber = Paint()
      ..color = const Color(0xFFFFE6A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final path = Path();
    for (double x = 0; x <= size.width; x += 5) {
      final y = 11 + _tearOffset(x);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, glow);
    canvas.drawPath(path, shadow);
    canvas.drawPath(path, fiber);
    if (tension > 0) {
      final tip = Offset(size.width - 1, 11 + _tearOffset(size.width));
      canvas.drawCircle(
        tip,
        3 + tension * 3,
        Paint()
          ..color = const Color(0xFFFFE6A5).withValues(alpha: tension)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TearEdgePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.tension != tension;
}

class _PackBodyPainter extends CustomPainter {
  const _PackBodyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x35D8B45E)
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < 7; i++) {
      final x = size.width * i / 7;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final chart = Path()
      ..moveTo(0, size.height * 0.77)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.72,
        size.width * 0.46,
        size.height * 0.5,
        size.width,
        size.height * 0.24,
      );
    canvas.drawPath(
      chart,
      paint
        ..color = const Color(0x99D8B45E)
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
