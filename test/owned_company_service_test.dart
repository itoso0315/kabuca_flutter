import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/services/owned_company_service.dart';
import 'package:kabuca_flutter/state/game_state.dart';

void main() {
  test('所持カードを企業単位に集約し最高レアリティを判定する', () {
    CompanyCard find(String company, CardRarity rarity) =>
        CardCatalog.cards.firstWhere(
          (card) => card.companyId == company && card.rarity == rarity,
        );
    final toyotaN = find('toyota', CardRarity.n);
    final toyotaSr = find('toyota', CardRarity.sr);
    final nintendoR = find('nintendo', CardRarity.r);
    final state = GameState.memory(
      cardCounts: {toyotaN.id: 2, toyotaSr.id: 1, nintendoR.id: 1},
    );

    final companies = OwnedCompanyService.from(state);
    expect(companies, hasLength(2));
    final toyota = companies.firstWhere((item) => item.companyId == 'toyota');
    expect(toyota.ownedRarityCount, 2);
    expect(toyota.highestRarity, CardRarity.sr);
    expect(companies.any((item) => item.companyId == 'sony'), isFalse);
  });
}
