import 'package:flutter/material.dart';

class CompanyArtworkAsset {
  const CompanyArtworkAsset({
    required this.assetPath,
    this.alignment = Alignment.center,
  });

  final String assetPath;
  final Alignment alignment;
}

/// Keeps company artwork independent from card rarity and card metadata.
///
/// Add one entry here when a new company artwork asset becomes available.
abstract final class CompanyArtworkRegistry {
  static const _assets = <String, CompanyArtworkAsset>{
    'toyota': CompanyArtworkAsset(assetPath: 'assets/toyota_card.png'),
    'ntt': CompanyArtworkAsset(assetPath: 'assets/ntt_card.png'),
    'mufg': CompanyArtworkAsset(assetPath: 'assets/mufg_card.png'),
    'sony': CompanyArtworkAsset(assetPath: 'assets/sony_card.png'),
    'inpex': CompanyArtworkAsset(assetPath: 'assets/inpex_card.png'),
    'keyence': CompanyArtworkAsset(assetPath: 'assets/keyence_card.png'),
    'softbank': CompanyArtworkAsset(assetPath: 'assets/softbank_card.png'),
    'recruit': CompanyArtworkAsset(assetPath: 'assets/recruit_card.png'),
  };

  static CompanyArtworkAsset? forCompany(String companyId) =>
      _assets[companyId];
}
