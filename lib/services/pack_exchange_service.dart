import '../models/pack_type.dart';
import '../state/game_state.dart';
import '../state/point_wallet.dart';

abstract final class PackExchangeRules {
  static const starterPackCost = 100;
  static const premiumPackCost = 300;
  static const superPremiumPackCost = 500;

  @Deprecated('Use starterPackCost instead.')
  static const standardPackCost = starterPackCost;
}

enum PackExchangeResult { exchanged, insufficientPoints, busy }

class PackExchangeService {
  PackExchangeService({required this.pointWallet, required this.gameState});

  final PointWallet pointWallet;
  final GameState gameState;
  bool _exchanging = false;

  Future<PackExchangeResult> exchangeStarterPack() {
    return _exchangePack(
      type: PackType.starter,
      cost: PackExchangeRules.starterPackCost,
    );
  }

  Future<PackExchangeResult> exchangePremiumPack() {
    return _exchangePack(
      type: PackType.premium,
      cost: PackExchangeRules.premiumPackCost,
    );
  }

  Future<PackExchangeResult> exchangeSuperPremiumPack() {
    return _exchangePack(
      type: PackType.superPremium,
      cost: PackExchangeRules.superPremiumPackCost,
    );
  }

  @Deprecated('Use exchangeStarterPack instead.')
  Future<PackExchangeResult> exchangeStandardPack() {
    return exchangeStarterPack();
  }

  Future<PackExchangeResult> _exchangePack({
    required PackType type,
    required int cost,
  }) async {
    if (_exchanging) return PackExchangeResult.busy;
    if (pointWallet.currentPoints < cost) {
      return PackExchangeResult.insufficientPoints;
    }

    _exchanging = true;
    try {
      final spent = await pointWallet.spend(cost);
      if (!spent) return PackExchangeResult.insufficientPoints;

      try {
        await gameState.addPacks(1, type);
      } catch (_) {
        await pointWallet.refund(cost);
        rethrow;
      }

      return PackExchangeResult.exchanged;
    } finally {
      _exchanging = false;
    }
  }
}
