import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/stock_prediction.dart';
import '../../services/prediction_formatters.dart';
import '../../services/prediction_resolution_service.dart';
import '../../state/prediction_store.dart';
import '../../state/point_wallet.dart';
import '../../services/prediction_reward_service.dart';
import '../../state/game_state.dart';
import '../../widgets/prediction_result_bell.dart';
import 'prediction_result_list_screen.dart';

/// The "予想中を見る" list: only waiting predictions with a future target date.
class PredictionListScreen extends StatefulWidget {
  const PredictionListScreen({
    super.key,
    required this.store,
    this.resolutionService,
    this.pointWallet,
    this.rewardService,
    this.gameState,
    this.onPredict,
    this.onOpenPack,
    this.onOpenExchange,
    this.onShowResults,
  });
  final PredictionStore store;
  final PredictionResolutionService? resolutionService;
  final PointWallet? pointWallet;
  final PredictionRewardService? rewardService;
  final GameState? gameState;
  final VoidCallback? onPredict;
  final VoidCallback? onOpenPack;
  final VoidCallback? onOpenExchange;
  final VoidCallback? onShowResults;

  @override
  State<PredictionListScreen> createState() => _PredictionListScreenState();
}

class _PredictionListScreenState extends State<PredictionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.store.refreshTime();
      widget.resolutionService?.resolveEligiblePredictions(automatic: true);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('予想中'),
      actions: [
        PredictionResultBell(
          store: widget.store,
          onPressed:
              widget.onShowResults ??
              () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => PredictionResultListScreen(
                    store: widget.store,
                    resolutionService: widget.resolutionService,
                    pointWallet: widget.pointWallet,
                    rewardService: widget.rewardService,
                    onPredictAgain: widget.onPredict,
                    onOpenExchange: widget.onOpenExchange,
                  ),
                ),
              ),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final predictions = widget.store.pendingPredictions.reversed.toList();
        if (predictions.isEmpty) {
          final hasCards = (widget.gameState?.totalOwnedCardCount ?? 0) > 0;
          return _PredictionEmptyState(
            hasCards: hasCards,
            onAction: hasCards ? widget.onPredict : widget.onOpenPack,
          );
        }
        return ListView.separated(
          key: const Key('prediction-list'),
          padding: const EdgeInsets.all(20),
          itemCount: predictions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _PredictionTile(prediction: predictions[index]),
        );
      },
    ),
  );
}

class _PredictionEmptyState extends StatelessWidget {
  const _PredictionEmptyState({required this.hasCards, required this.onAction});

  final bool hasCards;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        key: const Key('prediction-list-empty-state'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.query_stats_rounded,
            color: AppColors.mutedGold,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            '現在予想中の企業はありません',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            hasCards ? '持っている企業の未来を予想してみよう' : 'まずは企業カードを集めよう',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: Key(
              hasCards
                  ? 'prediction-list-predict-button'
                  : 'prediction-list-open-pack-button',
            ),
            onPressed: onAction,
            child: Text(hasCards ? '予想する' : 'パックを開ける'),
          ),
        ],
      ),
    ),
  );
}

class _PredictionTile extends StatelessWidget {
  const _PredictionTile({required this.prediction});
  final StockPrediction prediction;

  @override
  Widget build(BuildContext context) {
    final up = prediction.direction == PredictionDirection.up;
    return Card(
      child: ListTile(
        key: Key('prediction-${prediction.id}'),
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: AppColors.deepGreen,
          size: 34,
        ),
        title: Text(prediction.companyName),
        subtitle: Text(
          '${prediction.ticker}  ・  ${prediction.horizon.label}\n'
          '${prediction.direction.label}  ・  予想中'
          '${prediction.basePrice == null ? '' : '\n基準 ${formatYen(prediction.basePrice!)}'}'
          '\n答え合わせ予定 ${formatDate(prediction.targetDate!, includeYear: false)}',
        ),
      ),
    );
  }
}
