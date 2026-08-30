import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_theme.dart';
import '../../models/company_card.dart';
import '../../theme/company_theme.dart';
import '../../widgets/tearable_pack.dart';
import '../../widgets/card_rarity_style.dart';

class PackOpeningRoute extends MaterialPageRoute<List<CompanyCard>> {
  PackOpeningRoute({
    required List<CompanyCard> cards,
    required VoidCallback onPackOpened,
  }) : super(
         builder: (_) =>
             PackOpeningScreen(cards: cards, onPackOpened: onPackOpened),
       );

  @override
  bool get popGestureEnabled => false;
}

class PackOpeningScreen extends StatefulWidget {
  const PackOpeningScreen({
    super.key,
    required this.cards,
    required this.onPackOpened,
  });

  final List<CompanyCard> cards;
  final VoidCallback onPackOpened;

  @override
  State<PackOpeningScreen> createState() => _PackOpeningScreenState();
}

class _PackOpeningScreenState extends State<PackOpeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showCard = false;
  bool _packFinished = false;
  bool _packConsumed = false;
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
              child: _showCard
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
                            ScaleTransition(
                              scale: reveal,
                              child: FadeTransition(
                                opacity: reveal,
                                child: _CompanyCardView(
                                  key: ValueKey(widget.cards[_cardIndex].id),
                                  card: widget.cards[_cardIndex],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            FadeTransition(
                              opacity: reveal,
                              child: SizedBox(
                                width: 260,
                                child: FilledButton(
                                  key: const Key('card-action-button'),
                                  onPressed: _advanceCard,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.mutedGold,
                                    foregroundColor: AppColors.deepGreen,
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  child: Text(
                                    _cardIndex == widget.cards.length - 1
                                        ? '${widget.cards.length}枚獲得！'
                                        : '次へ',
                                  ),
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
                          children: [
                            const Text(
                              '左から右へ、封を破ろう',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'パック上部を指でなぞってください',
                              style: TextStyle(color: Color(0xBFFFFFFF)),
                            ),
                            const SizedBox(height: 24),
                            TearablePack(onOpened: _handleOpened),
                          ],
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

  Future<void> _advanceCard() async {
    if (_cardIndex == widget.cards.length - 1) {
      Navigator.pop(context, widget.cards);
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

  Future<void> _revealCurrentCard() async {
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
    _controller.forward(from: 0);
  }
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

class _CompanyCardView extends StatelessWidget {
  const _CompanyCardView({super.key, required this.card});

  final CompanyCard card;

  @override
  Widget build(BuildContext context) {
    final style = CardRarityStyle.of(card.rarity);
    final company = CompanyTheme.forCompany(card.companyId);
    return Semantics(
      label: '${card.companyName} ${card.ticker} ${card.rarity.label}',
      child: Container(
        width: 250,
        height: 350,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F1DF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: style.border, width: 3),
          boxShadow: [
            BoxShadow(
              color: style.border.withValues(alpha: style.glowAlpha),
              blurRadius: 36,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [company.secondaryColor, company.baseColor],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: style.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                card.rarity.label,
                key: const Key('card-rarity'),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: style.accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                company.abstractSymbol,
                color: company.accentColor,
                size: 54,
              ),
              const SizedBox(height: 12),
              Text(
                card.companyName,
                key: const Key('card-company-name'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${card.ticker}  |  ${card.industry}',
                key: const Key('card-metadata'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: style.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                card.title,
                key: const Key('card-title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: style.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                card.description,
                key: const Key('card-description'),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBackground extends StatelessWidget {
  const _GlowBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF3E8069), AppColors.deepGreen],
          radius: 0.8,
        ),
      ),
    );
  }
}
