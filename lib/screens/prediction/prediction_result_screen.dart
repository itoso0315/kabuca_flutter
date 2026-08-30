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
  });
  final StockPrediction prediction;
  final PredictionStore? predictionStore;
  final PointWallet? pointWallet;
  final PredictionRewardService? rewardService;

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

  Future<void> _claimPoints() async {
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
                        correct ? '予想的中！' : '今回は不的中',
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
                                  ? '${points}pt獲得済み'
                                  : '+${points}pt'
                            : '0pt',
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
                if (correct && points > 0) ...[
                  const SizedBox(height: 16),
                  if (claimed)
                    AnimatedScale(
                      key: const Key('prediction-points-claimed'),
                      scale: _claimedPulse ? 1.06 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: const Center(
                        child: Text(
                          'ポイントを受け取りました',
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
                      onPressed: _claiming ? null : _claimPoints,
                      icon: const Icon(Icons.stars_rounded),
                      label: Text('$points ptを受け取る'),
                    ),
                ] else if (!correct || points == 0) ...[
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      '今回はポイントなし',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
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
