import '../models/app_notification.dart';
import '../models/stock_prediction.dart';
import '../state/notification_store.dart';
import '../state/prediction_store.dart';
import 'prediction_point_calculator.dart';
import 'stock_price_service.dart';
import 'trading_calendar_service.dart';

enum PredictionResolutionStatus {
  completed,
  notEligible,
  legacyData,
  splitDetected,
  failed,
}

class PredictionResolutionResult {
  const PredictionResolutionResult(this.predictionId, this.status);
  final String predictionId;
  final PredictionResolutionStatus status;
}

class PredictionResolutionService {
  PredictionResolutionService({
    required this.predictionStore,
    required this.stockPriceService,
    required this.notificationStore,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PredictionStore predictionStore;
  final StockPriceService stockPriceService;
  final NotificationStore notificationStore;
  final DateTime Function() _now;
  final Set<String> _resolving = {};

  Future<List<PredictionResolutionResult>> resolveEligiblePredictions() async {
    final candidates = List<StockPrediction>.of(
      predictionStore.waitingPredictions,
    );
    return Future.wait(candidates.map(_resolve));
  }

  Future<PredictionResolutionResult> _resolve(
    StockPrediction prediction,
  ) async {
    final basePrice = prediction.basePrice;
    final basePriceAt = prediction.basePriceAt;
    final targetDate = prediction.targetDate;
    if (basePrice == null || basePriceAt == null || targetDate == null) {
      return PredictionResolutionResult(
        prediction.id,
        PredictionResolutionStatus.legacyData,
      );
    }
    final today = JapanTime.dateOf(_now());
    if (targetDate.isAfter(today) || !_resolving.add(prediction.id)) {
      return PredictionResolutionResult(
        prediction.id,
        PredictionResolutionStatus.notEligible,
      );
    }
    try {
      final historical = await stockPriceService.fetchClosingPrice(
        ticker: prediction.ticker,
        tradingDate: targetDate,
        sinceDate: JapanTime.dateOf(basePriceAt),
      );
      if (historical.splitDetected) {
        return PredictionResolutionResult(
          prediction.id,
          PredictionResolutionStatus.splitDetected,
        );
      }
      final change = ((historical.close - basePrice) / basePrice) * 100;
      if (!change.isFinite) {
        return PredictionResolutionResult(
          prediction.id,
          PredictionResolutionStatus.failed,
        );
      }
      final correct = switch (prediction.direction) {
        PredictionDirection.up => historical.close > basePrice,
        PredictionDirection.down => historical.close < basePrice,
      };
      final points = PredictionPointCalculator.calculate(
        changePercent: change,
        isCorrect: correct,
      );
      final completed = await predictionStore.complete(
        id: prediction.id,
        resultPrice: historical.close,
        resultPriceAt: historical.tradingDate,
        changePercent: change,
        isCorrect: correct,
        awardedPoints: points,
      );
      if (completed == null) {
        return PredictionResolutionResult(
          prediction.id,
          PredictionResolutionStatus.notEligible,
        );
      }
      await notificationStore.add(
        AppNotification(
          id: 'prediction-result-${prediction.id}',
          type: NotificationType.predictionResult,
          title: '予想結果が出ました',
          message:
              '${prediction.companyName}・${prediction.horizon.label} '
              '${prediction.direction.label}の答え合わせができます',
          createdAt: _now().toUtc(),
          isRead: false,
          relatedPredictionId: prediction.id,
          relatedCompanyId: prediction.companyId,
        ),
      );
      return PredictionResolutionResult(
        prediction.id,
        PredictionResolutionStatus.completed,
      );
    } catch (_) {
      return PredictionResolutionResult(
        prediction.id,
        PredictionResolutionStatus.failed,
      );
    } finally {
      _resolving.remove(prediction.id);
    }
  }
}
