import 'package:flutter/material.dart';

class CompanyTheme {
  const CompanyTheme({
    required this.baseColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.abstractSymbol,
    required this.artworkKind,
  });

  final Color baseColor;
  final Color secondaryColor;
  final Color accentColor;
  final IconData abstractSymbol;
  final CompanyArtworkKind artworkKind;

  static CompanyTheme forCompany(String companyId) {
    final base = _baseColors[companyId] ?? const Color(0xFF174A3A);
    return CompanyTheme(
      baseColor: base,
      secondaryColor: Color.lerp(base, Colors.white, 0.24)!,
      accentColor: Color.lerp(base, const Color(0xFFFFEDC0), 0.72)!,
      abstractSymbol: _symbols[companyId] ?? Icons.business_rounded,
      artworkKind: _artworkKinds[companyId] ?? CompanyArtworkKind.geometry,
    );
  }

  static const _baseColors = <String, Color>{
    'toyota': Color(0xFF681F2A),
    'nintendo': Color(0xFF8A2931),
    'sony': Color(0xFF17283E),
    'mufg': Color(0xFF66243F),
    'ntt': Color(0xFF174A70),
    'keyence': Color(0xFF603327),
    'fast_retailing': Color(0xFF75322D),
    'itochu': Color(0xFF174E47),
    'nyk': Color(0xFF254A64),
    'tel': Color(0xFF493866),
    'advantest': Color(0xFF31506A),
    'ajinomoto': Color(0xFF7A3D35),
    'kagome': Color(0xFF6A332C),
    'nitori': Color(0xFF2C5A58),
    'saizeriya': Color(0xFF526136),
    'oriental_land': Color(0xFF473A72),
    'shiseido': Color(0xFF713D55),
    'takeda': Color(0xFF4F385D),
    'mhi': Color(0xFF3E4B55),
    'inpex': Color(0xFF195B5B),
  };

  static const _symbols = <String, IconData>{
    'toyota': Icons.motion_photos_on_rounded,
    'nintendo': Icons.grid_view_rounded,
    'sony': Icons.graphic_eq_rounded,
    'mufg': Icons.account_balance_rounded,
    'ntt': Icons.hub_rounded,
    'keyence': Icons.sensors_rounded,
    'fast_retailing': Icons.checkroom_rounded,
    'itochu': Icons.public_rounded,
    'nyk': Icons.sailing_rounded,
    'tel': Icons.memory_rounded,
    'advantest': Icons.fact_check_rounded,
    'ajinomoto': Icons.science_rounded,
    'kagome': Icons.eco_rounded,
    'nitori': Icons.chair_rounded,
    'saizeriya': Icons.restaurant_rounded,
    'oriental_land': Icons.castle_rounded,
    'shiseido': Icons.spa_rounded,
    'takeda': Icons.biotech_rounded,
    'mhi': Icons.rocket_launch_rounded,
    'inpex': Icons.energy_savings_leaf_rounded,
  };

  static const _artworkKinds = <String, CompanyArtworkKind>{
    'toyota': CompanyArtworkKind.motion,
    'nintendo': CompanyArtworkKind.play,
    'sony': CompanyArtworkKind.wave,
    'mufg': CompanyArtworkKind.city,
    'ntt': CompanyArtworkKind.network,
    'keyence': CompanyArtworkKind.network,
    'fast_retailing': CompanyArtworkKind.geometry,
    'itochu': CompanyArtworkKind.city,
    'nyk': CompanyArtworkKind.wave,
    'tel': CompanyArtworkKind.network,
    'advantest': CompanyArtworkKind.network,
    'ajinomoto': CompanyArtworkKind.flow,
    'kagome': CompanyArtworkKind.flow,
    'nitori': CompanyArtworkKind.geometry,
    'saizeriya': CompanyArtworkKind.flow,
    'oriental_land': CompanyArtworkKind.play,
    'shiseido': CompanyArtworkKind.flow,
    'takeda': CompanyArtworkKind.network,
    'mhi': CompanyArtworkKind.motion,
    'inpex': CompanyArtworkKind.layers,
  };
}

enum CompanyArtworkKind {
  motion,
  play,
  wave,
  city,
  network,
  flow,
  layers,
  geometry,
}
