import '../state/game_state.dart';
import '../state/point_wallet.dart';

abstract final class PackExchangeRules {
  static const standardPackCost = 100;
}

enum PackExchangeResult { exchanged, insufficientPoints, busy }

class PackExchangeService {
  PackExchangeService({required this.pointWallet, required this.gameState});

  final PointWallet pointWallet;
  final GameState gameState;
  bool _exchanging = false;

  Future<PackExchangeResult> exchangeStandardPack() async {
    if (_exchanging) return PackExchangeResult.busy;
    if (pointWallet.currentPoints < PackExchangeRules.standardPackCost) {
      return PackExchangeResult.insufficientPoints;
    }
    _exchanging = true;
    try {
      final spent = await pointWallet.spend(PackExchangeRules.standardPackCost);
      if (!spent) return PackExchangeResult.insufficientPoints;
      try {
        await gameState.addPacks();
      } catch (_) {
        await pointWallet.refund(PackExchangeRules.standardPackCost);
        rethrow;
      }
      return PackExchangeResult.exchanged;
    } finally {
      _exchanging = false;
    }
  }
}
