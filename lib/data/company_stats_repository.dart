import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/company_stats.dart';

abstract interface class CompanyStatsRepository {
  Future<Map<String, CompanyStats>> load();
}

class AssetCompanyStatsRepository implements CompanyStatsRepository {
  AssetCompanyStatsRepository({Future<String> Function()? loadJson})
    : _loadJson = loadJson ?? (() => rootBundle.loadString(_assetPath));

  static const _assetPath = 'assets/data/company_stats.json';

  final Future<String> Function() _loadJson;

  @override
  Future<Map<String, CompanyStats>> load() async {
    try {
      final decoded = jsonDecode(await _loadJson());
      if (decoded is! Map<String, dynamic>) return {};
      final companies = decoded['companies'];
      if (companies is! Map<String, dynamic>) return {};
      final result = <String, CompanyStats>{};
      for (final entry in companies.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        try {
          result[entry.key] = CompanyStats.fromJson(entry.key, value);
        } on FormatException {
          continue;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }
}
