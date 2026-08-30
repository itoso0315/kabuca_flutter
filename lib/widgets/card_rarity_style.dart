import 'package:flutter/material.dart';

import '../models/company_card.dart';

class CardRarityStyle {
  const CardRarityStyle({
    required this.background,
    required this.border,
    required this.accent,
    required this.symbol,
    required this.glowAlpha,
  });

  final Color background;
  final Color border;
  final Color accent;
  final IconData symbol;
  final double glowAlpha;

  static CardRarityStyle of(CardRarity rarity) => switch (rarity) {
    CardRarity.n => const CardRarityStyle(
      background: Color(0xFF385348),
      border: Color(0xFFB8C1BA),
      accent: Color(0xFFE8ECE8),
      symbol: Icons.business_rounded,
      glowAlpha: 0.08,
    ),
    CardRarity.r => const CardRarityStyle(
      background: Color(0xFF174A3A),
      border: Color(0xFFC6A15B),
      accent: Color(0xFFFFE2A0),
      symbol: Icons.insights_rounded,
      glowAlpha: 0.20,
    ),
    CardRarity.sr => const CardRarityStyle(
      background: Color(0xFF123D36),
      border: Color(0xFFE1BF70),
      accent: Color(0xFFFFEDB9),
      symbol: Icons.auto_awesome_rounded,
      glowAlpha: 0.34,
    ),
    CardRarity.ur => const CardRarityStyle(
      background: Color(0xFF0B312B),
      border: Color(0xFFFFD978),
      accent: Color(0xFFFFF1C4),
      symbol: Icons.diamond_rounded,
      glowAlpha: 0.52,
    ),
  };
}
