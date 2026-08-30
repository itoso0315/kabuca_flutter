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
    'toyota': CompanyArtworkAsset(assetPath: 'assets/company_art/toyota.png'),
    'nintendo': CompanyArtworkAsset(
      assetPath: 'assets/company_art/nintendo.png',
    ),
    'ntt': CompanyArtworkAsset(assetPath: 'assets/company_art/ntt.png'),
    'mufg': CompanyArtworkAsset(assetPath: 'assets/company_art/mufg.png'),
    'sony': CompanyArtworkAsset(assetPath: 'assets/company_art/sony.png'),
    'inpex': CompanyArtworkAsset(assetPath: 'assets/company_art/inpex.png'),
    'keyence': CompanyArtworkAsset(assetPath: 'assets/company_art/keyence.png'),
    'fast_retailing': CompanyArtworkAsset(
      assetPath: 'assets/company_art/fast_retailing.png',
    ),
    'itochu': CompanyArtworkAsset(assetPath: 'assets/company_art/itochu.png'),
    'nyk': CompanyArtworkAsset(assetPath: 'assets/company_art/nyk.png'),
    'tel': CompanyArtworkAsset(assetPath: 'assets/company_art/tel.png'),
    'softbank': CompanyArtworkAsset(
      assetPath: 'assets/company_art/softbank.png',
    ),
    'recruit': CompanyArtworkAsset(assetPath: 'assets/company_art/recruit.png'),
  };

  static CompanyArtworkAsset? forCompany(String companyId) =>
      _assets[companyId];
}
