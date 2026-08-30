import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/stock_prediction.dart';
import '../../services/prediction_formatters.dart';
import '../../services/prediction_resolution_service.dart';
import '../../state/prediction_store.dart';
import '../../state/point_wallet.dart';
import '../../services/prediction_reward_service.dart';
import '../../state/game_state.dart';
import 'prediction_result_screen.dart';

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
  });
  final PredictionStore store;
  final PredictionResolutionService? resolutionService;
  final PointWallet? pointWallet;
  final PredictionRewardService? rewardService;
  final GameState? gameState;
  final VoidCallback? onPredict;
  final VoidCallback? onOpenPack;
  final VoidCallback? onOpenExchange;

  @override
  State<PredictionListScreen> createState() => _PredictionListScreenState();
}

class _PredictionListScreenState extends State<PredictionListScreen> {
  bool _checking = false;
  bool _hadFailure = false;

  Future<void> _checkResults() async {
    final service = widget.resolutionService;
    if (service == null || _checking) return;
    setState(() => _checking = true);
    final results = await service.resolveEligiblePredictions();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _hadFailure = results.any(
        (item) =>
            item.status == PredictionResolutionStatus.failed ||
            item.status == PredictionResolutionStatus.splitDetected,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('予想'),
      actions: [
        IconButton(
          key: const Key('check-prediction-results'),
          tooltip: '結果を確認',
          onPressed: _checking ? null : _checkResults,
          icon: _checking
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final predictions = widget.store.predictions.reversed.toList();
        if (predictions.isEmpty) {
          final hasCards = (widget.gameState?.totalOwnedCardCount ?? 0) > 0;
          return _PredictionEmptyState(
            hasCards: hasCards,
            onAction: hasCards ? widget.onPredict : widget.onOpenPack,
          );
        }
        return Column(
          children: [
            if (_hadFailure)
              const Padding(
                key: Key('prediction-resolution-retry-message'),
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text('一部の結果を確認できませんでした。時間をおいて再試行できます。'),
              ),
            Expanded(
              child: ListView.separated(
                key: const Key('prediction-list'),
                padding: const EdgeInsets.all(20),
                itemCount: predictions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _PredictionTile(
                  prediction: predictions[index],
                  onTap: predictions[index].status == PredictionStatus.completed
                      ? () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => PredictionResultScreen(
                              prediction: predictions[index],
                              predictionStore: widget.store,
                              pointWallet: widget.pointWallet,
                              rewardService: widget.rewardService,
                              onPredictAgain: widget.onPredict,
                              onOpenExchange: widget.onOpenExchange,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
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
            'まだ予想はありません',
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
  const _PredictionTile({required this.prediction, this.onTap});
  final StockPrediction prediction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final up = prediction.direction == PredictionDirection.up;
    final completed = prediction.status == PredictionStatus.completed;
    return Card(
      child: ListTile(
        key: Key('prediction-${prediction.id}'),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          completed
              ? ((prediction.isCorrect ?? false)
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded)
              : (up ? Icons.trending_up_rounded : Icons.trending_down_rounded),
          color: AppColors.deepGreen,
          size: 34,
        ),
        title: Text(prediction.companyName),
        trailing: completed ? const Icon(Icons.chevron_right_rounded) : null,
        subtitle: Text(
          '${prediction.ticker}  ・  ${prediction.horizon.label}\n'
          '${prediction.direction.label}  ・  ${completed ? '結果を見る' : '結果待ち'}'
          '${prediction.basePrice == null ? '' : '\n基準 ${formatYen(prediction.basePrice!)}'}'
          '${completed
              ? '  ・  ${(prediction.changePercent ?? 0).toStringAsFixed(2)}%'
              : prediction.targetDate == null
              ? ''
              : '  ・  ${formatDate(prediction.targetDate!, includeYear: false)} 答え合わせ予定'}',
        ),
      ),
    );
  }
}
