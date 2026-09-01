import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/data/company_master.dart';

void main() {
  const legacyCompanyIds = <String>{
    'toyota',
    'nintendo',
    'sony',
    'mufg',
    'ntt',
    'keyence',
    'fast_retailing',
    'itochu',
    'nyk',
    'tel',
    'advantest',
    'ajinomoto',
    'kagome',
    'nitori',
    'saizeriya',
    'oriental_land',
    'shiseido',
    'takeda',
    'mhi',
    'inpex',
  };

  test('日経225企業マスターが基準日付きで225社ちょうど', () {
    expect(nikkei225ConstituentAsOf, '2026-09-01');
    expect(CompanyMaster.nikkei225Companies, hasLength(225));
    expect(
      CompanyMaster.nikkei225Companies.every((company) => company.isNikkei225),
      isTrue,
    );
  });

  test('companyIdとtickerが一意で必須項目が埋まっている', () {
    final companies = CompanyMaster.companies;
    expect(
      companies.map((company) => company.companyId).toSet(),
      hasLength(companies.length),
    );
    expect(
      companies.map((company) => company.ticker).toSet(),
      hasLength(companies.length),
    );

    final tickerPattern = RegExp(r'^(?:[0-9]{4}|[0-9]{3}[A-Z])$');
    for (final company in companies) {
      expect(company.companyId, matches(RegExp(r'^[a-z0-9]+(?:_[a-z0-9]+)*$')));
      expect(company.companyName.trim(), isNotEmpty);
      expect(company.industry.trim(), isNotEmpty);
      expect(company.ticker, matches(tickerPattern));
      expect(
        company.artworkPath,
        'assets/company_art/${company.companyId}.png',
      );
    }
  });

  test('byIdとbyTickerで既存主要企業を取得できる', () {
    const expected = <String, (String, String)>{
      'toyota': ('7203', 'トヨタ自動車'),
      'nintendo': ('7974', '任天堂'),
      'sony': ('6758', 'ソニーグループ'),
      'mufg': ('8306', '三菱UFJフィナンシャル・グループ'),
      'ntt': ('9432', 'NTT'),
    };

    for (final entry in expected.entries) {
      final company = CompanyMaster.byId(entry.key);
      expect(company, isNotNull);
      expect(company!.ticker, entry.value.$1);
      expect(company.companyName, entry.value.$2);
      expect(CompanyMaster.byTicker(entry.value.$1), same(company));
    }
    expect(CompanyMaster.byId('unknown'), isNull);
    expect(CompanyMaster.byTicker('0000'), isNull);
  });

  test('既存20社IDを維持し非採用企業はlegacyとして残す', () {
    expect(
      legacyCompanyIds.every((id) => CompanyMaster.byId(id) != null),
      isTrue,
    );
    expect(CompanyMaster.byId('kagome')!.isNikkei225, isFalse);
    expect(CompanyMaster.byId('saizeriya')!.isNikkei225, isFalse);
  });

  test('既存CardCatalogの企業基本情報はCompanyMaster由来', () {
    expect(CardCatalog.companyCount, 20);
    expect(CardCatalog.cards, hasLength(80));
    for (final card in CardCatalog.cards) {
      final company = CompanyMaster.byId(card.companyId);
      expect(company, isNotNull);
      expect(card.companyName, company!.companyName);
      expect(card.ticker, company.ticker);
      expect(card.industry, company.industry);
    }
  });
}
