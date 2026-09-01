import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/company_master.dart';

class CompanyArtworkAsset {
  const CompanyArtworkAsset({
    required this.assetPath,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
  });

  final String assetPath;
  final Alignment alignment;
  final BoxFit fit;
}

class CompanyArtworkOverride {
  const CompanyArtworkOverride({
    this.assetPath,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
  });

  final String? assetPath;
  final Alignment alignment;
  final BoxFit fit;
}

/// Resolves standard artwork from CompanyMaster and keeps only exceptional
/// paths/crops here. AssetManifest is loaded once and results are cached.
abstract final class CompanyArtworkRegistry {
  static const Map<String, CompanyArtworkOverride> _overrides =
      <String, CompanyArtworkOverride>{
        // Compatibility aliases for assets created before CompanyMaster.
        'softbank': CompanyArtworkOverride(
          assetPath: 'assets/company_art/softbank.png',
        ),
        'recruit': CompanyArtworkOverride(
          assetPath: 'assets/company_art/recruit.png',
        ),
      };

  static Future<Set<String>>? _assetKeys;
  static final Map<String, Future<CompanyArtworkAsset?>> _resolved =
      <String, Future<CompanyArtworkAsset?>>{};

  static Future<CompanyArtworkAsset?> forCompany(String companyId) =>
      _resolved.putIfAbsent(companyId, () async {
        final assetKeys = await (_assetKeys ??= _loadAssetKeys());
        return resolveFromAssetKeys(companyId, assetKeys);
      });

  static CompanyArtworkAsset? resolveFromAssetKeys(
    String companyId,
    Set<String> assetKeys, {
    Map<String, CompanyArtworkOverride>? overrides,
  }) {
    final override = (overrides ?? _overrides)[companyId];
    final standardPath = CompanyMaster.byId(companyId)?.artworkPath;
    final assetPath = override?.assetPath ?? standardPath;
    if (assetPath == null || !assetKeys.contains(assetPath)) return null;

    return CompanyArtworkAsset(
      assetPath: assetPath,
      alignment: override?.alignment ?? Alignment.center,
      fit: override?.fit ?? BoxFit.cover,
    );
  }

  static Future<Set<String>> _loadAssetKeys() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().toSet();
    } on Object {
      // A missing/malformed manifest must never turn a card into an error UI.
      return const <String>{};
    }
  }

  @visibleForTesting
  static void resetCacheForTesting() {
    _assetKeys = null;
    _resolved.clear();
  }
}
