import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/services/trading_calendar_service.dart';

void main() {
  final holiday = DateTime.utc(2026, 9, 21);
  final calendar = TradingCalendarService(
    holidayProvider: _FakeHolidays({holiday}),
  );

  test('翌営業日は当日ではなく次の取引日', () {
    final mondayMorningJst = DateTime.utc(2026, 8, 31, 1);
    expect(
      calendar.resolveTargetTradingDay(
        mondayMorningJst,
        PredictionHorizon.nextTradingDay,
      ),
      DateTime.utc(2026, 9, 1),
    );
  });

  test('1週間後の休日は次の取引日へ送る', () {
    final created = DateTime.utc(2026, 9, 14, 3);
    expect(
      calendar.resolveTargetTradingDay(created, PredictionHorizon.oneWeek),
      DateTime.utc(2026, 9, 22),
    );
  });

  test('1か月後は月末にクランプし土日を避ける', () {
    expect(
      calendar.resolveTargetTradingDay(
        DateTime.utc(2026, 1, 31, 3),
        PredictionHorizon.oneMonth,
      ),
      DateTime.utc(2026, 3, 2),
    );
  });

  test('祝日Providerと取引所休場日の差し替え構造がある', () {
    expect(calendar.isTradingDay(holiday), isFalse);
    expect(
      JapanExchangeHolidayProvider().isHoliday(DateTime.utc(2026, 1, 2)),
      isTrue,
    );
  });
}

class _FakeHolidays implements TradingHolidayProvider {
  _FakeHolidays(this.days);
  final Set<DateTime> days;

  @override
  bool isHoliday(DateTime japanDate) => days.contains(japanDate);
}
