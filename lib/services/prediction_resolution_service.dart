import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/stock_prediction.dart';
import '../state/notification_store.dart';
import '../state/prediction_store.dart';
import 'prediction_reward_service.dart';
import 'stock_price_service.dart';
import 'trading_calendar_service.dart';

enum PredictionResolutionStatus {
  completed,
  notEligible,
  legacyData,
  splitDetected,
  awaitingClose,
  failed,
}

class PredictionResolutionResult {
  const PredictionResolutionResult(this.predictionId, this.status);
  final String predictionId;
  final PredictionResolutionStatus status;
}

class PredictionResolutionService extends ChangeNotifier {
  PredictionResolutionService({
    required this.predictionStore,
    required this.stockPriceService,
    required this.notificationStore,
    TradingCalendarService? tradingCalendarService,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _tradingCalendar = tradingCalendarService ?? TradingCalendarService();

  final PredictionStore predictionStore;
  final StockPriceService stockPriceService;
  final NotificationStore notificationStore;
  final DateTime Function() _now;
  final TradingCalendarService _tradingCalendar;
  final Set<String> _resolving = {};
  final Map<String, DateTime> _lastAttemptAt = {};
  final Map<String, PredictionResolutionStatus> _lastStatuses = {};
  Future<List<PredictionResolutionResult>>? _activeCheck;

  bool get isChecking => _activeCheck != null;
  PredictionResolutionStatus? lastStatus(String id) => _lastStatuses[id];

  Future<List<PredictionResolutionResult>> resolveEligiblePredictions({
    bool automatic = false,
  }) {
    // Share the whole ordered batch, so concurrent screen/lifecycle checks
    // cannot fetch the same cards twice or calculate streaks out of order.
    if (_activeCheck case final active?) return active;
    final check = _resolveEligiblePredictions(automatic: automatic);
    final active = check.whenComplete(() {
      _activeCheck = null;
      notifyListeners();
    });
    _activeCheck = active;
    notifyListeners();
    return active;
  }

  Future<List<PredictionResolutionResult>> _resolveEligiblePredictions({
    required bool automatic,
  }) async {
    final candidates = List<StockPrediction>.of(
      predictionStore.waitingPredictions,
    );
    candidates.sort((a, b) {
      final targetOrder = (a.targetDate ?? a.createdAt).compareTo(
        b.targetDate ?? b.createdAt,
      );
      return targetOrder != 0
          ? targetOrder
          : a.createdAt.compareTo(b.createdAt);
    });
    final results = <PredictionResolutionResult>[];
    for (final prediction in candidates) {
      final lastAttempt = _lastAttemptAt[prediction.id];
      if (automatic &&
          lastAttempt != null &&
          _now().difference(lastAttempt) < const Duration(minutes: 1)) {
        continue;
      }
      // A snapshot may be stale after a prior awaited resolution.
      if (predictionStore.findById(prediction.id)?.status !=
          PredictionStatus.waiting) {
        continue;
      }
      final result = await _resolve(prediction);
      results.add(result);
      if (result.status != PredictionResolutionStatus.notEligible) {
        _lastStatuses[prediction.id] = result.status;
      }
    }
    return results;
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
    if (targetDate.isAfter(today)) {
      return PredictionResolutionResult(
        prediction.id,
        PredictionResolutionStatus.notEligible,
      );
    }
    final closeAt = _tradingCalendar.closingTime(targetDate);
    if (!_tradingCalendar.isTradingDay(targetDate) ||
        _now().isBefore(closeAt)) {
      return PredictionResolutionResult(
        prediction.id,
        PredictionResolutionStatus.awaitingClose,
      );
    }
    if (!_resolving.add(prediction.id)) {
      return PredictionResolutionResult(
        prediction.id,
        PredictionResolutionStatus.notEligible,
      );
    }
    try {
      _lastAttemptAt[prediction.id] = _now();
      final historical = await stockPriceService.fetchClosingPrice(
        ticker: prediction.ticker,
        tradingDate: targetDate,
        sinceDate:
            prediction.basePriceDate?.add(const Duration(days: 1)) ??
            JapanTime.dateOf(basePriceAt),
      );
      if (historical.fetchedAt.isBefore(closeAt) ||
          historical.tradingDate.year != targetDate.year ||
          historical.tradingDate.month != targetDate.month ||
          historical.tradingDate.day != targetDate.day) {
        return PredictionResolutionResult(
          prediction.id,
          PredictionResolutionStatus.awaitingClose,
        );
      }
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
      final reward = PredictionRewardService.calculate(
        changePercent: change,
        isCorrect: correct,
        previousCorrectStreak: predictionStore.currentCorrectStreak,
      );
      final completed = await predictionStore.complete(
        id: prediction.id,
        resultPrice: historical.close,
        resultPriceAt: historical.tradingDate,
        changePercent: change,
        isCorrect: correct,
        awardedPoints: reward.totalReward,
        baseReward: reward.baseReward,
        movementBonus: reward.movementBonus,
        streakBonus: reward.streakBonus,
        correctStreak: reward.correctStreak,
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
    } on StockPriceException catch (error) {
      return PredictionResolutionResult(
        prediction.id,
        error.kind == StockPriceErrorKind.dataNotFound
            ? PredictionResolutionStatus.awaitingClose
            : PredictionResolutionStatus.failed,
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
