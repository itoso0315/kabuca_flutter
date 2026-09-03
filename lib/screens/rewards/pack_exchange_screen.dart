import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../services/pack_exchange_service.dart';
import '../../state/game_state.dart';
import '../../state/point_wallet.dart';

class PackExchangeScreen extends StatefulWidget {
  const PackExchangeScreen({
    super.key,
    required this.pointWallet,
    required this.gameState,
    required this.exchangeService,
  });

  final PointWallet pointWallet;
  final GameState gameState;
  final PackExchangeService exchangeService;

  @override
  State<PackExchangeScreen> createState() => _PackExchangeScreenState();
}

class _PackExchangeScreenState extends State<PackExchangeScreen> {
  bool _exchanging = false;

  Future<void> _exchange() async {
    if (_exchanging) return;
    setState(() => _exchanging = true);
    final result = await widget.exchangeService.exchangeStandardPack();
    if (!mounted) return;
    setState(() => _exchanging = false);
    if (result == PackExchangeResult.exchanged) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: const Text('KABU交換')),
    body: ListenableBuilder(
      listenable: Listenable.merge([widget.pointWallet, widget.gameState]),
      builder: (context, _) {
        final points = widget.pointWallet.currentPoints;
        final shortage = PackExchangeRules.standardPackCost - points;
        final canExchange = shortage <= 0 && !_exchanging;
        return ListView(
          key: const Key('pack-exchange-screen'),
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.deepGreen,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.mutedGold),
              ),
              child: Column(
                children: [
                  const Text('所持KABU', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(
                    '$points KABU',
                    key: const Key('exchange-point-balance'),
                    style: const TextStyle(
                      color: AppColors.mutedGold,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (points == 0) ...[
              const Row(
                key: Key('pack-exchange-earning-hint'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 19,
                    color: AppColors.deepGreen,
                  ),
                  SizedBox(width: 8),
                  Flexible(child: Text('株価予想を当てるとKABUが貯まります')),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.mutedGold,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'スタートパック',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '${PackExchangeRules.standardPackCost} KABUで1パック',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '現在の所持パック ${widget.gameState.packCount}個',
                      textAlign: TextAlign.center,
                    ),
                    if (shortage > 0) ...[
                      const SizedBox(height: 14),
                      Text(
                        'あと$shortage KABUで交換できます',
                        key: const Key('pack-exchange-shortage'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const Key('exchange-standard-pack-button'),
                      onPressed: canExchange ? _exchange : null,
                      child: _exchanging
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('交換する'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
