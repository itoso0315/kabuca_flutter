import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/company_card.dart';
import '../../models/stock_prediction.dart';
import '../../services/owned_company_service.dart';
import '../../services/prediction_formatters.dart';
import '../../services/stock_price_service.dart';
import '../../services/trading_calendar_service.dart';
import '../../state/prediction_store.dart';
import '../../theme/company_theme.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({
    super.key,
    required this.company,
    required this.predictionStore,
    this.stockPriceService,
    this.tradingCalendarService,
  });

  final OwnedCompanySummary company;
  final PredictionStore predictionStore;
  final StockPriceService? stockPriceService;
  final TradingCalendarService? tradingCalendarService;

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  PredictionHorizon _horizon = PredictionHorizon.nextTradingDay;
  PredictionDirection? _direction;
  StockPrediction? _saved;
  String? _error;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    if (_saved case final prediction?) {
      return _Completion(prediction: prediction);
    }
    final card = widget.company.representative;
    final companyTheme = CompanyTheme.forCompany(widget.company.companyId);
    return Scaffold(
      appBar: AppBar(title: const Text('株価予想')),
      body: ListView(
        key: const Key('prediction-screen'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [companyTheme.secondaryColor, companyTheme.baseColor],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  companyTheme.abstractSymbol,
                  color: companyTheme.accentColor,
                  size: 44,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.companyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${card.ticker} ・ ${card.industry}',
                        style: TextStyle(color: companyTheme.accentColor),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '最高レアリティ ${widget.company.highestRarity.label}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('カードから分かること', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final ownedCard in widget.company.cards)
            _OwnedInsight(card: ownedCard),
          const SizedBox(height: 24),
          Text('予想期間', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final horizon in PredictionHorizon.values)
                ChoiceChip(
                  key: Key('horizon-${horizon.name}'),
                  label: Text(horizon.label),
                  selected: _horizon == horizon,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() {
                          _horizon = horizon;
                          _error = null;
                        }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'この株、${_horizon.label}に今より上がる？下がる？',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DirectionButton(
                  direction: PredictionDirection.up,
                  selected: _direction == PredictionDirection.up,
                  onTap: _saving
                      ? null
                      : () =>
                            setState(() => _direction = PredictionDirection.up),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DirectionButton(
                  direction: PredictionDirection.down,
                  selected: _direction == PredictionDirection.down,
                  onTap: _saving
                      ? null
                      : () => setState(
                          () => _direction = PredictionDirection.down,
                        ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const Key('prediction-error'),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 24),
          if (_saving) ...[
            const Row(
              key: Key('stock-price-loading'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('現在の株価を取得中…'),
              ],
            ),
            const SizedBox(height: 14),
          ],
          FilledButton(
            key: const Key('save-prediction-button'),
            onPressed: _direction == null || _saving ? null : _save,
            child: const Text('この予想で決定'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final card = widget.company.representative;
    if (widget.predictionStore.hasWaiting(widget.company.companyId, _horizon)) {
      setState(() => _error = 'この企業・期間の予想はすでに結果待ちです');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final priceService =
          widget.stockPriceService ?? StockPriceService.production();
      final quote = await priceService.fetchCurrentPrice(
        ticker: card.ticker,
        companyId: widget.company.companyId,
      );
      final calendar =
          widget.tradingCalendarService ?? TradingCalendarService();
      final prediction = await widget.predictionStore.addWaiting(
        companyId: widget.company.companyId,
        companyName: card.companyName,
        ticker: card.ticker,
        direction: _direction!,
        horizon: _horizon,
        createdAt: quote.fetchedAt,
        basePrice: quote.price,
        basePriceAt: quote.fetchedAt,
        targetDate: calendar.resolveTargetTradingDay(quote.fetchedAt, _horizon),
      );
      if (!mounted) return;
      if (prediction == null) {
        setState(() => _error = 'この企業・期間の予想はすでに結果待ちです');
      } else {
        setState(() => _saved = prediction);
      }
    } on StockPriceException catch (error) {
      if (mounted) setState(() => _error = '${error.message}\n時間をおいて再試行してください');
    } catch (_) {
      if (mounted) {
        setState(() => _error = '現在の株価を取得できませんでした\n再試行してください');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _OwnedInsight extends StatelessWidget {
  const _OwnedInsight({required this.card});
  final CompanyCard card;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('owned-insight-${card.rarity.name}'),
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${card.rarity.label}  ${card.title}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          card.description,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ],
    ),
  );
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.direction,
    required this.selected,
    required this.onTap,
  });
  final PredictionDirection direction;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final up = direction == PredictionDirection.up;
    return OutlinedButton.icon(
      key: Key('direction-${direction.name}'),
      onPressed: onTap,
      icon: Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded),
      label: Text(direction.label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        backgroundColor: selected ? AppColors.softGreen : AppColors.surface,
        side: BorderSide(
          color: selected ? AppColors.deepGreen : AppColors.outline,
          width: selected ? 2 : 1,
        ),
      ),
    );
  }
}

class _Completion extends StatelessWidget {
  const _Completion({required this.prediction});
  final StockPrediction prediction;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        key: const Key('prediction-complete'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: AppColors.deepGreen,
                size: 58,
              ),
              const SizedBox(height: 18),
              Text(
                '予想を記録しました',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              Text(
                prediction.companyName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${prediction.horizon.label}  ${prediction.direction.label}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              if (prediction.basePrice case final price?) ...[
                Text(
                  '基準株価  ${formatYen(price)}',
                  key: const Key('completion-base-price'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
              ],
              if (prediction.targetDate case final target?)
                Text(
                  '答え合わせ予定  ${formatDate(target)}',
                  key: const Key('completion-target-date'),
                ),
              const SizedBox(height: 8),
              const Text('結果を待とう'),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('企業一覧へ戻る'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
