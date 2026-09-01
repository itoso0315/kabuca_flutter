import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/company_card.dart';
import '../theme/company_artwork_registry.dart';
import '../theme/company_theme.dart';
import 'card_rarity_style.dart';

class CompanyCardArtwork extends StatelessWidget {
  const CompanyCardArtwork({
    super.key,
    required this.card,
    this.width = 286,
    this.height = 400,
    this.compact = false,
  });

  final CompanyCard card;
  final double width;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CompanyArtworkAsset?>(
      future: CompanyArtworkRegistry.forCompany(card.companyId),
      builder: (context, snapshot) => _buildCard(context, snapshot.data),
    );
  }

  Widget _buildCard(BuildContext context, CompanyArtworkAsset? artwork) {
    final company = CompanyTheme.forCompany(card.companyId);
    final rarity = CardRarityStyle.of(card.rarity);
    final radius = compact ? 10.0 : 15.0;
    return RepaintBoundary(
      child: Semantics(
        label: '${card.companyName} ${card.ticker} ${card.rarity.label}',
        image: true,
        child: Container(
          key: const Key('card-artwork-surface'),
          width: width,
          height: height,
          padding: EdgeInsets.all(compact ? 4 : 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [rarity.accent, rarity.border, const Color(0xFF604820)],
            ),
            border: Border.all(color: rarity.border, width: 2),
            borderRadius: BorderRadius.circular(radius + 4),
            boxShadow: [
              BoxShadow(
                color: rarity.border.withValues(alpha: rarity.glowAlpha),
                blurRadius: card.rarity == CardRarity.ur ? 28 : 15,
                spreadRadius: card.rarity.index >= CardRarity.sr.index ? 2 : 0,
              ),
              const BoxShadow(
                color: Color(0x66000000),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    company.secondaryColor,
                    const Color(0xFF141817),
                    .58,
                  )!,
                  Color.lerp(company.baseColor, const Color(0xFF050B09), .48)!,
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: rarity.border.withValues(alpha: .85)),
            ),
            child: Stack(
              children: [
                if (artwork == null)
                  Positioned.fill(
                    child: CustomPaint(
                      key: const Key('company-artwork-fallback'),
                      painter: CompanyArtworkPainter(
                        theme: company,
                        rarity: card.rarity,
                      ),
                    ),
                  ),
                if (card.rarity.index >= CardRarity.sr.index)
                  Positioned.fill(child: _CardSheen(rarity: card.rarity)),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 9 : 15,
                    compact ? 8 : 13,
                    compact ? 9 : 15,
                    compact ? 7 : 11,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CardHeader(card: card, compact: compact, rarity: rarity),
                      SizedBox(height: compact ? 5 : 8),
                      Expanded(
                        flex: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(compact ? 5 : 8),
                          child: artwork == null
                              ? _FallbackSymbol(
                                  company: company,
                                  compact: compact,
                                )
                              : _CompanyArtworkImage(
                                  companyId: card.companyId,
                                  artwork: artwork,
                                  accent: company.accentColor,
                                  fallback: _FallbackSymbol(
                                    company: company,
                                    compact: compact,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: compact ? 5 : 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 7 : 11,
                          vertical: compact ? 7 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xB8070D0B),
                          border: Border(
                            top: BorderSide(
                              color: rarity.border.withValues(alpha: .8),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.title,
                              key: const Key('card-title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: rarity.accent,
                                fontSize: compact ? 9 : 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!compact) ...[
                              const SizedBox(height: 4),
                              Text(
                                card.industry,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .7),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                            SizedBox(height: compact ? 2 : 4),
                            Text(
                              'K A B U C A',
                              style: TextStyle(
                                color: rarity.accent.withValues(alpha: .8),
                                fontSize: compact ? 5.5 : 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: compact ? .8 : 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox.shrink(key: Key('card-description')),
                    ],
                  ),
                ),
                if (card.rarity == CardRarity.ur)
                  const Positioned.fill(child: _UltraFrame()),
                Positioned(
                  width: 0,
                  height: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [company.secondaryColor, company.baseColor],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.card,
    required this.compact,
    required this.rarity,
  });

  final CompanyCard card;
  final bool compact;
  final CardRarityStyle rarity;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Text(
            card.ticker,
            key: const Key('card-metadata'),
            style: TextStyle(
              color: rarity.accent,
              fontSize: compact ? 8 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 7,
              vertical: compact ? 2 : 3,
            ),
            decoration: BoxDecoration(
              color: const Color(0x99050A08),
              border: Border.all(color: rarity.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              card.rarity.label,
              key: const Key('card-rarity'),
              style: TextStyle(
                color: rarity.accent,
                fontSize: compact ? 8 : 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: compact ? 3 : 5),
      Text(
        card.companyName,
        key: const Key('card-company-name'),
        maxLines: compact ? 1 : 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 10 : 16,
          fontWeight: FontWeight.w700,
          height: 1.08,
        ),
      ),
    ],
  );
}

class _CompanyArtworkImage extends StatelessWidget {
  const _CompanyArtworkImage({
    required this.companyId,
    required this.artwork,
    required this.accent,
    required this.fallback,
  });

  final String companyId;
  final CompanyArtworkAsset artwork;
  final Color accent;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        artwork.assetPath,
        key: Key('company-artwork-image-$companyId'),
        fit: artwork.fit,
        alignment: artwork.alignment,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: accent.withValues(alpha: .35)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xB0000000),
              Color(0x00000000),
              Color(0x00000000),
              Color(0xC8000000),
            ],
            stops: [0, .2, .72, 1],
          ),
        ),
      ),
    ],
  );
}

class _FallbackSymbol extends StatelessWidget {
  const _FallbackSymbol({required this.company, required this.compact});

  final CompanyTheme company;
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      key: const Key('company-artwork-fallback-symbol'),
      width: compact ? 48 : 82,
      height: compact ? 48 : 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x44000000),
        border: Border.all(color: company.accentColor.withValues(alpha: .72)),
      ),
      child: Icon(
        company.abstractSymbol,
        color: company.accentColor,
        size: compact ? 27 : 45,
      ),
    ),
  );
}

class _CardSheen extends StatelessWidget {
  const _CardSheen({required this.rarity});
  final CardRarity rarity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1.2, -1),
          end: const Alignment(1.1, 1),
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: rarity == CardRarity.ur ? .13 : .07),
            Colors.transparent,
          ],
          stops: const [.32, .5, .68],
        ),
      ),
    ),
  );
}

class _UltraFrame extends StatelessWidget {
  const _UltraFrame();
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xAAFFE39B)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );
}

class CompanyArtworkPainter extends CustomPainter {
  const CompanyArtworkPainter({required this.theme, required this.rarity});
  final CompanyTheme theme;
  final CardRarity rarity;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = theme.accentColor.withValues(alpha: .14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()..color = theme.secondaryColor.withValues(alpha: .12);
    switch (theme.artworkKind) {
      case CompanyArtworkKind.city:
        for (var i = 0; i < 8; i++) {
          final w = size.width / 10;
          final h = size.height * (.13 + (i % 4) * .045);
          canvas.drawRect(
            Rect.fromLTWH(i * w * 1.35, size.height * .67 - h, w, h),
            fill,
          );
        }
      case CompanyArtworkKind.network:
        final nodes = List.generate(
          9,
          (i) => Offset(
            size.width * (.12 + (i % 3) * .37),
            size.height * (.24 + (i ~/ 3) * .2),
          ),
        );
        for (var i = 0; i < nodes.length - 1; i++) {
          canvas.drawLine(nodes[i], nodes[i + 1], line);
        }
        for (final node in nodes) {
          canvas.drawCircle(node, 2.3, fill);
        }
      case CompanyArtworkKind.wave:
        for (var i = 0; i < 5; i++) {
          final path = Path()..moveTo(0, size.height * (.3 + i * .09));
          for (double x = 0; x <= size.width; x += 8) {
            path.lineTo(
              x,
              size.height * (.3 + i * .09) + math.sin(x * .05 + i) * 10,
            );
          }
          canvas.drawPath(path, line);
        }
      case CompanyArtworkKind.motion:
        for (var i = 0; i < 8; i++) {
          canvas.drawLine(
            Offset(-20, size.height * (.35 + i * .055)),
            Offset(size.width * .9, size.height * (.13 + i * .04)),
            line,
          );
        }
      case CompanyArtworkKind.layers:
        for (var i = 0; i < 7; i++) {
          final path = Path()
            ..moveTo(0, size.height * (.38 + i * .06))
            ..quadraticBezierTo(
              size.width * .5,
              size.height * (.32 + i * .07),
              size.width,
              size.height * (.4 + i * .055),
            );
          canvas.drawPath(path, line);
        }
      case CompanyArtworkKind.flow:
        for (var i = 0; i < 5; i++) {
          final path = Path()
            ..moveTo(size.width * (.1 + i * .18), size.height)
            ..cubicTo(
              size.width * (.35 + i * .08),
              size.height * .68,
              size.width * (.05 + i * .2),
              size.height * .38,
              size.width * (.2 + i * .15),
              0,
            );
          canvas.drawPath(path, line);
        }
      case CompanyArtworkKind.play:
        for (var i = 0; i < 6; i++) {
          final rect = Rect.fromCenter(
            center: Offset(
              size.width * (.2 + (i % 3) * .3),
              size.height * (.32 + (i ~/ 3) * .24),
            ),
            width: 28 + i * 2,
            height: 28 + i * 2,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(7)),
            line,
          );
        }
      case CompanyArtworkKind.geometry:
        for (var i = 0; i < 7; i++) {
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: 45 + i * 25,
              height: 45 + i * 25,
            ),
            line,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant CompanyArtworkPainter oldDelegate) =>
      oldDelegate.theme != theme || oldDelegate.rarity != rarity;
}
