import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_theme.dart';
import '../../models/stock_prediction.dart';
import '../../services/prediction_formatters.dart';
import '../../services/prediction_reward_service.dart';
import '../../state/point_wallet.dart';
import '../../state/prediction_store.dart';

class PredictionResultScreen extends StatefulWidget {
  const PredictionResultScreen({
    super.key,
    required this.prediction,
    this.predictionStore,
    this.pointWallet,
    this.rewardService,
    this.onPredictAgain,
    this.onOpenExchange,
  });
  final StockPrediction prediction;
  final PredictionStore? predictionStore;
  final PointWallet? pointWallet;
  final PredictionRewardService? rewardService;
  final VoidCallback? onPredictAgain;
  final VoidCallback? onOpenExchange;

  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen> {
  bool _claiming = false;
  bool _claimedPulse = false;

  @override
  void initState() {
    super.initState();
    if (widget.prediction.isCorrect ?? false) HapticFeedback.mediumImpact();
  }

  Future<void> _claimKabu() async {
    final service = widget.rewardService;
    if (service == null || _claiming) return;
    setState(() => _claiming = true);
    final result = await service.claim(widget.prediction.id);
    if (!mounted) return;
    setState(() {
      _claiming = false;
      _claimedPulse = result == RewardClaimResult.claimed;
    });
    if (result == RewardClaimResult.claimed) {
      HapticFeedback.mediumImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _claimedPulse = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prediction =
        widget.predictionStore?.findById(widget.prediction.id) ??
        widget.prediction;
    final correct = prediction.isCorrect ?? false;
    final change = prediction.changePercent ?? 0;
    final points = prediction.awardedPoints ?? 0;
    final claimed =
        prediction.pointsClaimed == true ||
        (widget.pointWallet?.hasClaimedPrediction(prediction.id) ?? false);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('予想結果')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  key: const Key('prediction-result-hero'),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: correct
                        ? AppColors.deepGreen
                        : const Color(0xFF4A5550),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        correct
                            ? Icons.auto_awesome_rounded
                            : Icons.show_chart_rounded,
                        color: AppColors.mutedGold,
                        size: 42,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        correct ? '予想的中！' : '今回は予想が外れました',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        correct
                            ? claimed
                                  ? '$points KABU獲得済み'
                                  : '+$points KABU'
                            : '獲得KABU 0',
                        key: const Key('prediction-result-points'),
                        style: const TextStyle(
                          color: AppColors.mutedGold,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (correct && (prediction.correctStreak ?? 0) >= 2) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '${prediction.correctStreak}連続正解！',
                      key: const Key('prediction-correct-streak'),
                      style: const TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                if (correct && prediction.baseReward != null) ...[
                  const SizedBox(height: 16),
                  _RewardBreakdownCard(prediction: prediction),
                ],
                if (correct && points > 0) ...[
                  const SizedBox(height: 16),
                  if (claimed)
                    AnimatedScale(
                      key: const Key('prediction-points-claimed'),
                      scale: _claimedPulse ? 1.06 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: const Center(
                        child: Text(
                          'KABUを受け取りました',
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else if (widget.rewardService != null)
                    FilledButton.icon(
                      key: const Key('claim-prediction-points-button'),
                      onPressed: _claiming ? null : _claimKabu,
                      icon: const Icon(Icons.stars_rounded),
                      label: Text('$points KABUを受け取る'),
                    ),
                ] else if (!correct || points == 0) ...[
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      '獲得KABU 0',
                      key: Key('prediction-no-points'),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction.companyName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${prediction.ticker}  ・  ${prediction.horizon.label}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Divider(height: 30),
                        _ResultRow(
                          label: 'あなたの予想',
                          value: prediction.direction.label,
                        ),
                        _ResultRow(
                          label: '基準価格',
                          value: formatYen(prediction.basePrice ?? 0),
                        ),
                        _ResultRow(
                          label: '判定価格',
                          value: formatYen(prediction.resultPrice ?? 0),
                        ),
                        _ResultRow(
                          label: '騰落率',
                          value:
                              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                        ),
                        if (prediction.resultPriceAt != null)
                          _ResultRow(
                            label: '判定日',
                            value: formatDate(prediction.resultPriceAt!),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.onPredictAgain != null) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    key: const Key('prediction-result-next-prediction'),
                    onPressed: widget.onPredictAgain,
                    icon: const Icon(Icons.insights_rounded),
                    label: Text(correct ? '他の企業を予想する' : 'もう一度予想する'),
                  ),
                  if (correct && widget.onOpenExchange != null)
                    TextButton(
                      key: const Key('prediction-result-open-exchange'),
                      onPressed: widget.onOpenExchange,
                      child: const Text('KABU交換を見る'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardBreakdownCard extends StatelessWidget {
  const _RewardBreakdownCard({required this.prediction});

  final StockPrediction prediction;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('prediction-reward-breakdown'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _ResultRow(label: '基本報酬', value: '+${prediction.baseReward} KABU'),
          _ResultRow(
            label: '値動きボーナス',
            value: '+${prediction.movementBonus} KABU',
          ),
          _ResultRow(
            label: '連続正解ボーナス',
            value: '+${prediction.streakBonus} KABU',
          ),
          const Divider(),
          _ResultRow(
            label: '合計KABU',
            value: '+${prediction.awardedPoints ?? 0} KABU',
          ),
        ],
      ),
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
