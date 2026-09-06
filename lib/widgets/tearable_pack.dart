import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kabuca_card_back.dart';

import '../models/pack_type.dart';

class TearablePack extends StatefulWidget {
  const TearablePack({
    super.key,
    required this.onOpened,
    this.packType = PackType.starter,
  });

  final VoidCallback onOpened;
  final PackType packType;

  @override
  TearablePackState createState() => TearablePackState();
}

class TearablePackState extends State<TearablePack>
    with TickerProviderStateMixin {
  static const _completionThreshold = 0.96;

  late final AnimationController _progress;
  late final AnimationController _completionLift;
  late final AnimationController _guidance;
  Offset _dragStartPosition = Offset.zero;
  double _activeTearDistance = 248;
  double _progressAtDragStart = 0;
  double _maxProgress = 0;
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
      duration: const Duration(milliseconds: 520),
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
    _maxProgress = _progress.value;
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
    _maxProgress = math.max(_maxProgress, next);
    _progress.value = _maxProgress;
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (!_trackingGesture || _opened) return;
    _trackingGesture = false;
    _eligibleStart = false;
    if (!_gestureActivated) return;
    if (_progress.value < _completionThreshold) {
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
            packType: widget.packType,
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
    required this.packType,
  });

  final double progress;
  final double completionLift;
  final double guidanceProgress;
  final bool showGuidance;
  final PackType packType;

  @override
  Widget build(BuildContext context) {
    const width = 280.0;
    const height = 420.0;
    const tearY = 72.0;
    final tearX = width * progress;
    final gap = progress == 0 ? 0.0 : 1.2 + progress * 1.8;
    final glow = progress == 0 ? 0.0 : 0.45 + progress * 0.55;
    final openingFlash = math.sin(completionLift * math.pi).clamp(0.0, 1.0);
    final openingGlow = math.max(openingFlash, completionLift * 0.62);
    final isPremium = packType == PackType.premium;

    if (progress == 0) {
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            _PackBody(packType: packType),
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
          if (completionLift > 0)
  Positioned(
    left: 2,
    right: 2,
    top: tearY - 62,
    height: 150,
    child: IgnorePointer(
      child: Opacity(
        opacity: openingGlow,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.08),
              radius: 0.72,
              colors: [
                const Color(0xFFFFFBE8).withValues(
                  alpha: 0.94 * openingGlow,
                ),
                (isPremium
                        ? const Color(0xFFFFD66B)
                        : const Color(0xFFFFE4A0))
                    .withValues(alpha: 0.62 * openingGlow),
                const Color(0xFFFFD66B).withValues(
                  alpha: 0.20 * openingGlow,
                ),
                Colors.transparent,
              ],
              stops: const [0.0, 0.24, 0.52, 1.0],
            ),
          ),
        ),
      ),
    ),
  ),

if (completionLift > 0)
  Positioned(
    left: 18,
    right: 18,
    top: tearY - 5,
    height: 12,
    child: IgnorePointer(
      child: Opacity(
        opacity: openingFlash,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFF2B8)
                    .withValues(alpha: 0.95),
                blurRadius: 22,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: const Color(0xFFFFD66B)
                    .withValues(alpha: 0.65),
                blurRadius: 42,
                spreadRadius: 13,
              ),
            ],
            color: const Color(0xFFFFF9DC),
          ),
        ),
      ),
    ),
  ),
          if (progress > .7)
            Positioned(
              left: 35,
              top: 56 - completionLift * 22,
              child: Opacity(
                opacity: (((progress - .7) / .3).clamp(0, 1) * .9 +
                        completionLift * .1)
                     .clamp(0.0, 1.0),
                child: const KabucaCardBack(width: 210, height: 294),
              ),
            ),
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
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: _PackBody(packType: packType),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(0, -gap - completionLift * 26),
            child: ClipPath(
              clipper: _TornUpperClipper(tearX: tearX, tearY: tearY),
              child: _PackBody(packType: packType),
            ),
          ),
          Transform.translate(
            offset: Offset(0, gap),
            child: ClipPath(
              clipper: _TornLowerClipper(tearX: tearX, tearY: tearY),
              child: _PackBody(packType: packType),
            ),
          ),
          Positioned(
            left: 0,
            top: tearY - 12,
            width: math.max(1, tearX),
            height: 27,
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
  const _PackBody({required this.packType});

  final PackType packType;

  @override
  Widget build(BuildContext context) {
    final isPremium = packType == PackType.premium;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPremium
              ? const [
                  Color(0xFF1A1D1C),
                  Color(0xFF0C0F0E),
                  Color(0xFF020303),
                ]
              : const [
                  Color(0xFF123C31),
                  Color(0xFF071B16),
                  Color(0xFF030A08),
                ],
          stops: const [0, .58, 1],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPremium
              ? const Color(0xFFD9B75E)
              : const Color(0xFF8D6C2E),
          width: isPremium ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isPremium
                ? const Color(0x7A000000)
                : const Color(0x66102C24),
            blurRadius: isPremium ? 34 : 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PackBodyPainter(isPremium: isPremium),
            ),
          ),
          if (isPremium)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.24, 0.42, 0.62, 1.0],
                      colors: [
                        Colors.white.withValues(alpha: 0.20),
                        Colors.white.withValues(alpha: 0.035),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          for (final top in [7.0, 11.0, 15.0, 19.0, 23.0])
            Positioned(
              left: 0,
              right: 0,
              top: top,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPremium
                        ? const [
                            Color(0xFF8E6A27),
                            Color(0xFFFFE8A3),
                            Color(0xFFB48730),
                          ]
                        : const [
                            Color(0xFF70501D),
                            Color(0xFFFFE8A3),
                            Color(0xFF8C6827),
                          ],
                  ),
                ),
                child: const SizedBox(height: 1.4),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            top: 42,
            child: Text(
              '‹  ‹  ─────  OPEN  ─────  ›  ›',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPremium
                    ? const Color(0xFFFFE7A8)
                    : const Color(0xFFFFE09A),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: isPremium
                            ? const Color(0xFFFFE6A3)
                            : const Color(0xFFFFD879),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: isPremium
                          ? const Color(0xFFFFE6A3)
                          : const Color(0xFFFFD879),
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'KABUCA',
                  style: TextStyle(
                    color: isPremium
                        ? const Color(0xFFFFEBC2)
                        : const Color(0xFFFFE2A0),
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6,
                  ),
                ),
                Text(
                  isPremium ? 'PREMIUM PACK' : 'START PACK',
                  style: TextStyle(
                    color: isPremium
                        ? const Color(0xFFFFE6A3)
                        : const Color(0xFFFFE2A0),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 37,
            child: Text(
              '3 CARDS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPremium
                    ? const Color(0xFFFFE6A3)
                    : const Color(0xFFFFE2A0),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          for (final bottom in [7.0, 11.0, 15.0, 19.0, 23.0])
            Positioned(
              left: 0,
              right: 0,
              bottom: bottom,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPremium
                        ? const [
                            Color(0xFF8E6A27),
                            Color(0xFFFFE8A3),
                            Color(0xFFB48730),
                          ]
                        : const [
                            Color(0xFF70501D),
                            Color(0xFFFFE8A3),
                            Color(0xFF8C6827),
                          ],
                  ),
                ),
                child: const SizedBox(height: 1.4),
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
    if (progress <= 0 || size.width <= 0) return;

    final path = Path();
    for (double x = 0; x <= size.width; x += 4) {
      final y = 12 + _tearOffset(x);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final outerGlow = Paint()
      ..color = const Color(0x99FFF1B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final innerGlow = Paint()
      ..color = const Color(0xFFFFF3CC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final fiber = Paint()
      ..color = const Color(0xFFFFE6A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, outerGlow);
    canvas.drawPath(path, innerGlow);
    canvas.drawPath(path, fiber);

    final tip = Offset(size.width - 1, 12 + _tearOffset(size.width));
    final tipGlow = Paint()
      ..color = const Color(0xFFFFF7D8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(tip, 5 + tension * 3, tipGlow);
    canvas.drawCircle(
      tip,
      2.2,
      Paint()..color = const Color(0xFFFFFDF1),
    );
  }

  @override
  bool shouldRepaint(covariant _TearEdgePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.tension != tension;
}

class _PackBodyPainter extends CustomPainter {
  const _PackBodyPainter({required this.isPremium});

  final bool isPremium;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isPremium
          ? const Color(0x26F1D28A)
          : const Color(0x20D8B45E)
      ..style = PaintingStyle.stroke;
    for (double y = 76; y < size.height - 40; y += 28) {
      for (double x = -14; x < size.width; x += 28) {
        final diamond = Path()
          ..moveTo(x, y + 14)
          ..lineTo(x + 14, y)
          ..lineTo(x + 28, y + 14)
          ..lineTo(x + 14, y + 28)
          ..close();
        canvas.drawPath(diamond, paint);
      }
    }
    final chart = Path()
      ..moveTo(0, size.height * 0.82)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.78,
        size.width * 0.46,
        size.height * 0.62,
        size.width,
        size.height * 0.38,
      );
    canvas.drawPath(
      chart,
      paint
        ..color = isPremium
            ? const Color(0xB8F1D28A)
            : const Color(0x99D8B45E)
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _PackBodyPainter oldDelegate) =>
      oldDelegate.isPremium != isPremium;
}
