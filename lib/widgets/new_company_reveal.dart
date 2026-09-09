import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_theme.dart';
import '../data/card_catalog.dart';
import '../models/company_card.dart';
import 'company_card_artwork.dart';

/// A presentation-only interlude. Ownership and pack consumption stay with the
/// opening flow; this widget only returns the user to card confirmation.
class NewCompanyReveal extends StatefulWidget {
  const NewCompanyReveal({
    super.key,
    required this.card,
    required this.ownedRarityCount,
    required this.onViewCard,
  }) : assert(ownedRarityCount >= 1 && ownedRarityCount <= 4);

  final CompanyCard card;
  final int ownedRarityCount;
  final VoidCallback onViewCard;

  @override
  State<NewCompanyReveal> createState() => _NewCompanyRevealState();
}

class _NewCompanyRevealState extends State<NewCompanyReveal>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1600);
  late final AnimationController _controller;
  bool _hapticPlayed = false;
  bool _viewingCard = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addListener(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  void _onTick() {
    if (!_hapticPlayed && _controller.value >= 500 / 1600) {
      _hapticPlayed = true;
      if (!_reduceMotion) HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _entrance(int start, int end) => _controller.drive(
    CurveTween(
      curve: Interval(start / 1600, end / 1600, curve: Curves.easeOutCubic),
    ),
  );

  String get _introduction {
    final overview =
        CardCatalog.companyOverview(widget.card.companyId) ??
        (widget.card.rarity == CardRarity.n
            ? widget.card.description
            : '${widget.card.industry}分野で事業を展開する企業。');
    final normalized = overview.replaceAll(RegExp(r'\s+'), ' ').trim();
    final sentenceEnd = normalized.indexOf('。');
    final sentence = sentenceEnd < 0
        ? normalized
        : normalized.substring(0, sentenceEnd + 1);
    // Bound the copy itself as well as the visual line count.
    return sentence.characters.length <= 72
        ? sentence
        : '${sentence.characters.take(71)}…';
  }

  @override
  Widget build(BuildContext context) {
    final cardEntrance = _entrance(400, 1000);
    final titleEntrance = _entrance(600, 1050);
    final introEntrance = _entrance(750, 1250);
    final registrationEntrance = _entrance(1000, 1400);
    final buttonEntrance = _entrance(1200, 1600);

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.35),
                radius: 1.1,
                colors: [
                  Color.lerp(
                    AppColors.deepGreen,
                    const Color(0xFF263024),
                    (_controller.value * 4).clamp(0, 1),
                  )!,
                  const Color(0xFF030B08),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;
              final cardHeight =
                  (constraints.maxHeight * (compact ? 0.4 : 0.44)).clamp(
                    210.0,
                    350.0,
                  );
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: compact ? 12 : 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: titleEntrance,
                          child: ScaleTransition(
                            scale: titleEntrance.drive(
                              Tween(begin: 0.88, end: 1.0),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'NEW COMPANY',
                                  style: TextStyle(
                                    color: Color(0xFFFFEBC0),
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.gold,
                                        blurRadius: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: cardHeight + (compact ? 40 : 56),
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _DiscoveryLightPainter(
                                        animation: _controller,
                                        reduceMotion: _reduceMotion,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              FadeTransition(
                                opacity: cardEntrance,
                                child: ScaleTransition(
                                  scale: cardEntrance.drive(
                                    Tween(begin: 0.75, end: 1.0),
                                  ),
                                  child: Container(
                                    width: cardHeight / 1.4,
                                    height: cardHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x66E9BD62),
                                          blurRadius: 40,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: FittedBox(
                                      child: CompanyCardArtwork(
                                        card: widget.card,
                                        width: 250,
                                        height: 350,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Column(
                              children: [
                                FadeTransition(
                                  opacity: introEntrance,
                                  child: Column(
                                    children: [
                                      Text(
                                        widget.card.companyName,
                                        key: const Key('new-company-name'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.cream,
                                          fontSize: 21,
                                          fontWeight: FontWeight.w700,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        widget.card.industry,
                                        style: const TextStyle(
                                          color: AppColors.mutedGold,
                                          fontSize: 12,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      SizedBox(height: compact ? 10 : 14),
                                      Text(
                                        _introduction,
                                        key: const Key(
                                          'new-company-introduction',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.65,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: compact ? 14 : 22),
                                FadeTransition(
                                  opacity: registrationEntrance,
                                  child: Column(
                                    children: [
                                      const Text(
                                        '図鑑に新しい企業が登録されました',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11,
                                        ),
                                      ),
                                      SizedBox(height: compact ? 8 : 10),
                                      Text(
                                        '${widget.ownedRarityCount} / 4 CARDS',
                                        style: const TextStyle(
                                          color: Color(0xFFE9D4A1),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: compact ? 14 : 20),
                                FadeTransition(
                                  opacity: buttonEntrance,
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, _) => OutlinedButton(
                                      key: const Key('new-company-view-card'),
                                      onPressed:
                                          !_controller.isCompleted ||
                                              _viewingCard
                                          ? null
                                          : () {
                                              if (_viewingCard) return;
                                              setState(
                                                () => _viewingCard = true,
                                              );
                                              widget.onViewCard();
                                            },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.cream,
                                        disabledForegroundColor: Colors.white38,
                                        side: const BorderSide(
                                          color: Color(0x887F754F),
                                        ),
                                        minimumSize: const Size(190, 48),
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: const Text('カードを見る'),
                                    ),
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
            },
          ),
        ),
        if (!_reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final ms = _controller.value * 1600;
                  final flash = math.exp(-math.pow((ms - 500) / 55, 2));
                  return ColoredBox(
                    color: Colors.white.withValues(alpha: flash * 0.78),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _DiscoveryLightPainter extends CustomPainter {
  _DiscoveryLightPainter({required this.animation, required this.reduceMotion})
    : super(repaint: animation);

  final Animation<double> animation;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final gathering = Curves.easeInCubic.transform((t / 0.25).clamp(0, 1));
    final burst = Curves.easeOutCubic.transform(((t - 0.25) / 0.4).clamp(0, 1));
    final center = size.center(Offset.zero);
    final radius = size.height * 0.48;
    final paint = Paint();

    canvas.drawCircle(
      center,
      radius * (0.5 + burst * 0.7),
      paint
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF0C2).withValues(alpha: 0.42 * gathering),
            const Color(0xFFE5AD48).withValues(alpha: 0.18 * gathering),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.2)),
    );
    paint.shader = null;

    // A luminous ring forms before the card, then expands behind its edges.
    final ringRadius = radius * (0.26 + gathering * 0.12 + burst * 0.56);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(
        0xFFFFE3A0,
      ).withValues(alpha: gathering * (0.7 - burst * 0.5))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, ringRadius, paint);
    paint
      ..style = PaintingStyle.fill
      ..maskFilter = null;

    // Broad, soft rays stay behind the artwork and within its stage.
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 + 0.18 + burst * 0.12;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final normal = Offset(-direction.dy, direction.dx);
      final tip = center + direction * radius * 1.28;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo((tip + normal * 9).dx, (tip + normal * 9).dy)
        ..lineTo((tip - normal * 9).dx, (tip - normal * 9).dy)
        ..close();
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFFFFD680).withValues(alpha: 0.22 * burst),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.28));
      canvas.drawPath(path, paint);
    }
    paint.shader = null;

    for (var i = 0; i < 32; i++) {
      final angle = i * 2.39996;
      final distance = t < 0.25
          ? radius * (0.2 + (i % 7) / 8) * (1 - gathering)
          : radius * (0.78 + (i % 5) * 0.075) * burst;
      final position =
          center +
          Offset(math.cos(angle) * distance * 0.85, math.sin(angle) * distance);
      final twinkle = reduceMotion
          ? 0.65
          : 0.55 + 0.45 * math.sin(i * 1.7 + t * 14).abs();
      final alpha = (t < 0.25 ? (t * 12).clamp(0.0, 1.0) : burst) * twinkle;
      paint.color = const Color(0xFFFFEBC1).withValues(alpha: alpha * 0.85);
      canvas.drawCircle(position, i.isEven ? 1.6 : 1, paint);
      if (i % 4 == 0) {
        final arm = 2 + 3 * twinkle;
        paint.strokeWidth = 0.8;
        canvas.drawLine(
          position.translate(-arm, 0),
          position.translate(arm, 0),
          paint,
        );
        canvas.drawLine(
          position.translate(0, -arm),
          position.translate(0, arm),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DiscoveryLightPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.reduceMotion != reduceMotion;
}
