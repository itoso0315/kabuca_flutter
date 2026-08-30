import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../services/backend_warmup_service.dart';

class TitleScreen<T> extends StatefulWidget {
  const TitleScreen({
    super.key,
    required this.initialize,
    required this.warmupService,
    required this.homeBuilder,
    this.minimumDuration = const Duration(seconds: 1),
    this.maximumDuration = const Duration(seconds: 3),
  });

  final Future<T> Function() initialize;
  final BackendWarmupService warmupService;
  final Widget Function(T value) homeBuilder;
  final Duration minimumDuration;
  final Duration maximumDuration;

  @override
  State<TitleScreen<T>> createState() => _TitleScreenState<T>();
}

class _TitleScreenState<T> extends State<TitleScreen<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  T? _initializedValue;
  bool _finished = false;
  BackendWarmupStatus? _warmupStatus;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _start();
  }

  Future<void> _start() async {
    final initialization = widget.initialize();
    final minimum = Future<void>.delayed(widget.minimumDuration);
    final warmup = widget.warmupService.warmUp().then((status) {
      _warmupStatus = status;
    });
    final normalGate = Future.wait<void>([minimum, warmup]);
    await Future.any<void>([
      normalGate,
      Future<void>.delayed(widget.maximumDuration),
    ]);
    final value = await initialization;
    if (!mounted || _finished) return;
    _finished = true;
    setState(() => _initializedValue = value);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _initializedValue;
    if (value != null) return widget.homeBuilder(value);
    return Scaffold(
      key: const Key('title-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _animation,
              curve: const Interval(0, 0.75, curve: Curves.easeOut),
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, 10 * (1 - Curves.easeOut.transform(_animation.value))),
                child: child,
              ),
              child: const _TitleContent(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleContent extends StatelessWidget {
  const _TitleContent();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _CardMark(),
        const SizedBox(height: 30),
        const Text(
          'KABUCA',
          key: Key('title-logo'),
          style: TextStyle(
            color: AppColors.deepGreen,
            fontSize: 44,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '企業を集めて、未来を予想する。',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            letterSpacing: 0.8,
          ),
        ),
      ],
    ),
  );
}

class _CardMark extends StatelessWidget {
  const _CardMark();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    height: 94,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(angle: -0.16, child: const _MiniCard(color: Color(0xFF789888))),
        Transform.rotate(angle: 0.16, child: const _MiniCard(color: Color(0xFFB89A58))),
        const _MiniCard(color: AppColors.deepGreen, foreground: AppColors.mutedGold),
      ],
    ),
  );
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.color, this.foreground = Colors.white70});

  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 88,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: foreground.withValues(alpha: 0.75)),
      boxShadow: const [
        BoxShadow(color: Color(0x1F002A20), blurRadius: 16, offset: Offset(0, 7)),
      ],
    ),
    child: Icon(Icons.trending_up_rounded, color: foreground, size: 28),
  );
}
