import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_theme.dart';
import '../../models/company_card.dart';
import '../../screens/card/card_detail_screen.dart';
import '../../state/game_state.dart';
import '../../widgets/tearable_pack.dart';
import '../../widgets/company_card_artwork.dart';
import '../../widgets/kabuca_card_back.dart';

enum PackOpeningDestination { home, collection }

class PackOpeningResult {
  const PackOpeningResult({required this.cards, required this.destination});

  final List<CompanyCard> cards;
  final PackOpeningDestination destination;
}

class PackOpeningRoute extends MaterialPageRoute<PackOpeningResult> {
  PackOpeningRoute({
    required List<CompanyCard> cards,
    required VoidCallback onPackOpened,
    required GameState gameState,
  }) : super(
         builder: (_) => PackOpeningScreen(
           cards: cards,
           onPackOpened: onPackOpened,
           gameState: gameState,
         ),
       );

  @override
  bool get popGestureEnabled => false;
}

class PackOpeningScreen extends StatefulWidget {
  const PackOpeningScreen({
    super.key,
    required this.cards,
    required this.onPackOpened,
    required this.gameState,
  });

  final List<CompanyCard> cards;
  final VoidCallback onPackOpened;
  final GameState gameState;

  @override
  State<PackOpeningScreen> createState() => _PackOpeningScreenState();
}

class _PackOpeningScreenState extends State<PackOpeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showCard = false;
  bool _packFinished = false;
  bool _packConsumed = false;
  bool _showCompletion = false;
  bool _inputEnabled = false;
  bool _transitioning = false;
  int _cardIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reveal = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    return Scaffold(
      backgroundColor: AppColors.deepGreen,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _GlowBackground()),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showCompletion
                  ? _PackComplete(
                      key: const ValueKey('complete'),
                      cardCount: widget.cards.length,
                      onShowCollection: () => Navigator.pop(
                        context,
                        PackOpeningResult(
                          cards: widget.cards,
                          destination: PackOpeningDestination.collection,
                        ),
                      ),
                      onShowHome: () => Navigator.pop(
                        context,
                        PackOpeningResult(
                          cards: widget.cards,
                          destination: PackOpeningDestination.home,
                        ),
                      ),
                    )
                  : _showCard
                  ? Center(
                      key: const ValueKey('card'),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CARD ${_cardIndex + 1} / ${widget.cards.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'NEW CARD!',
                              style: TextStyle(
                                color: AppColors.mutedGold,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 26),
                            GestureDetector(
                              key: const Key('card-confirmation-gesture'),
                              behavior: HitTestBehavior.opaque,
                              onTap: _handleCardTap,
                              onLongPress: _openCardDetail,
                              child: _CardFlipReveal(
                                key: ValueKey(widget.cards[_cardIndex].id),
                                animation: _controller,
                                card: widget.cards[_cardIndex],
                              ),
                            ),
                            const SizedBox(height: 22),
                            FadeTransition(
                              opacity: reveal,
                              child: const Text(
                                'タップで次へ  ・  長押しで詳細',
                                key: Key('card-operation-hint'),
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _packFinished
                  ? _RarityPrelude(
                      key: ValueKey(
                        'prelude-${widget.cards[_cardIndex].rarity.name}',
                      ),
                      rarity: widget.cards[_cardIndex].rarity,
                    )
                  : Center(
                      key: const ValueKey('pack'),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [TearablePack(onOpened: _handleOpened)],
                        ),
                      ),
                    ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: IconButton(
                key: const Key('pack-back-button'),
                tooltip: '戻る',
                onPressed: () => Navigator.maybePop(context),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0x44000000),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleOpened() async {
    if (!_packConsumed) {
      _packConsumed = true;
      widget.onPackOpened();
    }
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;
    setState(() => _packFinished = true);
    await _revealCurrentCard();
  }

  Future<void> _handleCardTap() async {
    if (!_inputEnabled || _transitioning) return;
    _inputEnabled = false;
    _transitioning = true;
    if (_cardIndex == widget.cards.length - 1) {
      setState(() {
        _showCard = false;
        _showCompletion = true;
      });
      _transitioning = false;
      return;
    }
    await _controller.reverse();
    if (!mounted) return;
    setState(() {
      _cardIndex++;
      _showCard = false;
    });
    await _revealCurrentCard();
  }

  Future<void> _openCardDetail() async {
    if (!_inputEnabled || _transitioning) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(
          card: widget.cards[_cardIndex],
          gameState: widget.gameState,
          pendingCards: widget.cards,
        ),
      ),
    );
  }

  Future<void> _revealCurrentCard() async {
    _inputEnabled = false;
    final rarity = widget.cards[_cardIndex].rarity;
    final delay = switch (rarity) {
      CardRarity.sr => const Duration(milliseconds: 450),
      CardRarity.ur => const Duration(milliseconds: 800),
      _ => Duration.zero,
    };
    if (rarity == CardRarity.sr) HapticFeedback.lightImpact();
    if (rarity == CardRarity.ur) HapticFeedback.heavyImpact();
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (!mounted) return;
    setState(() => _showCard = true);
    await _controller.forward(from: 0);
    if (!mounted) return;
    _inputEnabled = true;
    _transitioning = false;
  }
}

class _PackComplete extends StatelessWidget {
  const _PackComplete({
    super.key,
    required this.cardCount,
    required this.onShowCollection,
    required this.onShowHome,
  });

  final int cardCount;
  final VoidCallback onShowCollection;
  final VoidCallback onShowHome;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.mutedGold,
          size: 52,
        ),
        const SizedBox(height: 18),
        Text(
          '$cardCount枚獲得！',
          key: const Key('pack-complete-title'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          key: const Key('collect-cards-button'),
          onPressed: onShowCollection,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.mutedGold,
            foregroundColor: AppColors.deepGreen,
          ),
          child: const Text('図鑑を見る'),
        ),
        TextButton(
          key: const Key('pack-complete-home-button'),
          onPressed: onShowHome,
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('ホームへ'),
        ),
      ],
    ),
  );
}

class _RarityPrelude extends StatelessWidget {
  const _RarityPrelude({super.key, required this.rarity});
  final CardRarity rarity;

  @override
  Widget build(BuildContext context) {
    if (rarity == CardRarity.sr) {
      return const ColoredBox(
        key: Key('sr-reveal-prelude'),
        color: Color(0x66010D0A),
        child: Center(child: _PreludeLine(color: Color(0xFFE8D7A6))),
      );
    }
    if (rarity == CardRarity.ur) {
      return const DecoratedBox(
        key: Key('ur-reveal-prelude'),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF9B7834), Color(0xFF173F34)],
            radius: 0.9,
          ),
        ),
        child: Center(
          child: _PreludeLine(color: Color(0xFFFFE6A1), doubleLine: true),
        ),
      );
    }
    return const SizedBox(key: Key('standard-reveal-prelude'));
  }
}

class _PreludeLine extends StatelessWidget {
  const _PreludeLine({required this.color, this.doubleLine = false});
  final Color color;
  final bool doubleLine;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 230,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(color: color, thickness: 2),
        if (doubleLine) ...[
          const SizedBox(height: 12),
          Divider(color: color, thickness: 1),
        ],
      ],
    ),
  );
}

class _CardFlipReveal extends StatelessWidget {
  const _CardFlipReveal({
    super.key,
    required this.animation,
    required this.card,
  });

  final Animation<double> animation;
  final CompanyCard card;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final eased = Curves.easeOutCubic.transform(animation.value);
      final angle = math.pi * (1 - eased);
      final showFront = angle <= math.pi / 2;
      final transform = Matrix4.identity()
        ..setEntry(3, 2, .0014)
        ..translateByDouble(0, 28 * (1 - eased), 0, 1)
        ..rotateY(showFront ? angle : angle + math.pi);
      return Opacity(
        opacity: (.2 + eased * .8).clamp(0, 1),
        child: Transform(
          alignment: Alignment.center,
          transform: transform,
          child: showFront
              ? CompanyCardArtwork(card: card, width: 250, height: 350)
              : const KabucaCardBack(),
        ),
      );
    },
  );
}

class _GlowBackground extends StatelessWidget {
  const _GlowBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF21483C), Color(0xFF06110E)],
          radius: 0.8,
        ),
      ),
    );
  }
}
