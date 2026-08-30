import 'package:world_holidays/world_holidays.dart';

import '../models/stock_prediction.dart';

abstract interface class TradingHolidayProvider {
  bool isHoliday(DateTime japanDate);
}

class JapanExchangeHolidayProvider implements TradingHolidayProvider {
  JapanExchangeHolidayProvider({WorldHolidays? holidays})
    : _holidays = holidays ?? WorldHolidays();

  final WorldHolidays _holidays;

  @override
  bool isHoliday(DateTime japanDate) {
    final exchangeHoliday =
        (japanDate.month == 1 && japanDate.day <= 3) ||
        (japanDate.month == 12 && japanDate.day == 31);
    return exchangeHoliday || _holidays.isHoliday('JP', japanDate);
  }
}

class TradingCalendarService {
  TradingCalendarService({TradingHolidayProvider? holidayProvider})
    : holidayProvider = holidayProvider ?? JapanExchangeHolidayProvider();

  final TradingHolidayProvider holidayProvider;

  bool isTradingDay(DateTime japanDate) {
    final weekday = japanDate.weekday;
    return weekday != DateTime.saturday &&
        weekday != DateTime.sunday &&
        !holidayProvider.isHoliday(japanDate);
  }

  DateTime nextTradingDay(DateTime japanDate) {
    var candidate = _dateOnly(japanDate).add(const Duration(days: 1));
    while (!isTradingDay(candidate)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  DateTime resolveTargetTradingDay(
    DateTime createdAt,
    PredictionHorizon horizon,
  ) {
    final createdDate = JapanTime.dateOf(createdAt);
    if (horizon == PredictionHorizon.nextTradingDay) {
      return nextTradingDay(createdDate);
    }
    final baseDate = switch (horizon) {
      PredictionHorizon.oneWeek => createdDate.add(const Duration(days: 7)),
      PredictionHorizon.oneMonth => _addCalendarMonth(createdDate),
      PredictionHorizon.nextTradingDay => throw StateError('unreachable'),
    };
    if (isTradingDay(baseDate)) return baseDate;
    var candidate = baseDate;
    while (!isTradingDay(candidate)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  DateTime _addCalendarMonth(DateTime date) {
    final targetYear = date.month == 12 ? date.year + 1 : date.year;
    final targetMonth = date.month == 12 ? 1 : date.month + 1;
    final lastDay = DateTime.utc(targetYear, targetMonth + 1, 0).day;
    return DateTime.utc(
      targetYear,
      targetMonth,
      date.day > lastDay ? lastDay : date.day,
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
}

class JapanTime {
  static const offset = Duration(hours: 9);

  static DateTime dateOf(DateTime instant) {
    final japan = instant.toUtc().add(offset);
    return DateTime.utc(japan.year, japan.month, japan.day);
  }
}
