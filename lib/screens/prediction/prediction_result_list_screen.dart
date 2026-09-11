import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/stock_prediction.dart';
import '../../services/prediction_formatters.dart';
import '../../services/prediction_resolution_service.dart';
import '../../services/prediction_reward_service.dart';
import '../../state/point_wallet.dart';
import '../../state/prediction_store.dart';
import 'prediction_result_screen.dart';

class PredictionResultListScreen extends StatefulWidget {
  const PredictionResultListScreen({
    super.key,
    required this.store,
    this.resolutionService,
    this.pointWallet,
    this.rewardService,
    this.onPredictAgain,
    this.onOpenExchange,
    this.onShowNotifications,
  });

  final PredictionStore store;
  final PredictionResolutionService? resolutionService;
  final PointWallet? pointWallet;
  final PredictionRewardService? rewardService;
  final VoidCallback? onPredictAgain;
  final VoidCallback? onOpenExchange;
  final VoidCallback? onShowNotifications;

  @override
  State<PredictionResultListScreen> createState() =>
      _PredictionResultListScreenState();
}

class _PredictionResultListScreenState
    extends State<PredictionResultListScreen> {
  bool _seenSaveFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      widget.store.refreshTime();
      // Acknowledge the initial list. Results completed later remain new until
      // their detail is opened or the user opens this list again.
      _markSeen(widget.store.resultPredictions);
      widget.resolutionService?.resolveEligiblePredictions(automatic: true);
    });
  }

  Future<void> _markSeen(List<StockPrediction> predictions) async {
    try {
      await widget.store.markResultsSeen(predictions);
      if (mounted && _seenSaveFailed) setState(() => _seenSaveFailed = false);
    } catch (_) {
      if (mounted) setState(() => _seenSaveFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: const Text('予想結果'),
      actions: [
        if (widget.onShowNotifications != null)
          TextButton(
            key: const Key('prediction-result-notifications'),
            onPressed: widget.onShowNotifications,
            child: const Text('お知らせ'),
          ),
        ListenableBuilder(
          listenable: widget.resolutionService ?? widget.store,
          builder: (context, _) => IconButton(
            key: const Key('check-prediction-results'),
            tooltip: '結果を再確認',
            onPressed:
                widget.resolutionService == null ||
                    widget.resolutionService!.isChecking
                ? null
                : () => widget.resolutionService!.resolveEligiblePredictions(),
            icon: widget.resolutionService?.isChecking == true
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: Listenable.merge([widget.store, ?widget.resolutionService]),
      builder: (context, _) {
        final predictions = widget.store.resultPredictions.reversed.toList();
        if (predictions.isEmpty) {
          return const Center(
            key: Key('prediction-result-empty-state'),
            child: Text('新しい結果はありません'),
          );
        }
        return Column(
          children: [
            if (_seenSaveFailed)
              TextButton(
                onPressed: () => _markSeen(predictions),
                child: const Text('確認状態を保存できませんでした。再試行'),
              ),
            Expanded(
              child: ListView.separated(
                key: const Key('prediction-result-list'),
                padding: const EdgeInsets.all(20),
                itemCount: predictions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final prediction = predictions[index];
                  final completed =
                      prediction.status == PredictionStatus.completed;
                  final status = widget.resolutionService?.lastStatus(
                    prediction.id,
                  );
                  final missingData =
                      prediction.basePrice == null ||
                      prediction.basePriceAt == null ||
                      prediction.targetDate == null;
                  final message = missingData
                      ? '旧形式の予想のため、価格・予定日の情報がありません'
                      : status == PredictionResolutionStatus.failed
                      ? '結果を確認できませんでした\nあとで再確認します'
                      : status == PredictionResolutionStatus.splitDetected
                      ? '株式分割の影響を確認中です'
                      : '終値の更新を待っています';
                  final cardColor = !completed
                      ? Colors.white
                      : prediction.isCorrect == true
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE);
                  final resultColor = !completed
                      ? AppColors.deepGreen
                      : prediction.isCorrect == true
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828);
                  return Card(
                    color: cardColor,
                    child: ListTile(
                      key: Key('prediction-result-${prediction.id}'),
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(
                        completed
                            ? (prediction.isCorrect == true
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded)
                            : Icons.schedule_rounded,
                        color: resultColor,
                      ),
                      title: Text(prediction.companyName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${prediction.ticker} ・ ${prediction.horizon.label} ・ ${prediction.direction.label}',
                          ),
                          const SizedBox(height: 6),
                          if (completed) ...[
                            Text(
                              '${prediction.isCorrect == true ? '正解' : '不正解'} ・ '
                              '${(prediction.changePercent ?? 0) >= 0 ? '+' : ''}'
                              '${(prediction.changePercent ?? 0).toStringAsFixed(2)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '獲得ポイント ${prediction.awardedPoints ?? 0} KABU',
                            ),
                            const Text(
                              '結果を見る',
                              style: TextStyle(
                                color: AppColors.deepGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              '結果確認中',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            for (final line in message.split('\n')) Text(line),
                          ],
                          if (prediction.targetDate case final target?)
                            Text(
                              '答え合わせ予定 ${formatDate(target, includeYear: false)}',
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!prediction.resultSeen)
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: AppColors.gold,
                            ),
                          if (completed)
                            const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      onTap: completed
                          ? () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => PredictionResultScreen(
                                  prediction: prediction,
                                  predictionStore: widget.store,
                                  pointWallet: widget.pointWallet,
                                  rewardService: widget.rewardService,
                                  onPredictAgain: widget.onPredictAgain,
                                  onOpenExchange: widget.onOpenExchange,
                                ),
                              ),
                            )
                          : () => _markSeen([prediction]),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}
