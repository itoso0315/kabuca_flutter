import 'package:flutter/material.dart';

import '../models/company_card.dart';
import '../theme/company_theme.dart';
import 'card_rarity_style.dart';

class CompanyCardArtwork extends StatelessWidget {
  const CompanyCardArtwork({
    super.key,
    required this.card,
    this.width = 286,
    this.height = 402,
  });

  final CompanyCard card;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final company = CompanyTheme.forCompany(card.companyId);
    final rarity = CardRarityStyle.of(card.rarity);
    return Container(
      key: const Key('card-artwork-surface'),
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1DF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: rarity.border, width: 3),
        boxShadow: [
          BoxShadow(
            color: rarity.border.withValues(alpha: rarity.glowAlpha),
            blurRadius: card.rarity == CardRarity.ur ? 34 : 24,
            spreadRadius: card.rarity.index >= CardRarity.sr.index ? 3 : 0,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [company.secondaryColor, company.baseColor],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: rarity.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              card.rarity.label,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: rarity.accent,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
              ),
            ),
            const Spacer(),
            Icon(company.abstractSymbol, color: company.accentColor, size: 72),
            const Spacer(),
            Text(
              card.companyName,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${card.ticker}  |  ${card.industry}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: company.accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              card.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: rarity.accent,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
