import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/stock_prediction.dart';
import '../../state/prediction_store.dart';

class PredictionListScreen extends StatelessWidget {
  const PredictionListScreen({super.key, required this.store});
  final PredictionStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('予想中')),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final predictions = store.waitingPredictions.reversed.toList();
        if (predictions.isEmpty) {
          return const Center(child: Text('結果待ちの予想はありません'));
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

class _PredictionTile extends StatelessWidget {
  const _PredictionTile({required this.prediction});
  final StockPrediction prediction;

  @override
  Widget build(BuildContext context) {
    final up = prediction.direction == PredictionDirection.up;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: AppColors.deepGreen,
          size: 34,
        ),
        title: Text(prediction.companyName),
        subtitle: Text(
          '${prediction.ticker}  ・  ${prediction.horizon.label}\n${prediction.direction.label}  ・  結果待ち',
        ),
      ),
    );
  }
}
