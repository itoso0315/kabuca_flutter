import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizDailyProgress {
  const QuizDailyProgress({
    required this.answeredCount,
    required this.usedKeys,
  });

  final int answeredCount;
  final Set<String> usedKeys;
}

abstract interface class QuizDailyProgressStore implements Listenable {
  Future<QuizDailyProgress> load();
  Future<void> record(String questionKey);
  Future<void> reset();
}

class SharedPreferencesQuizDailyProgressStore extends ChangeNotifier
    implements QuizDailyProgressStore {
  static const _dateKey = 'quiz.daily.date';
  static const _countKey = 'quiz.daily.answeredCount';
  static const _usedKeysKey = 'quiz.daily.usedKeys';

  @override
  Future<QuizDailyProgress> load() async {
    final preferences = await SharedPreferences.getInstance();
    final today = _dateKeyFor(DateTime.now());
    if (preferences.getString(_dateKey) != today) {
      return const QuizDailyProgress(answeredCount: 0, usedKeys: {});
    }
    return QuizDailyProgress(
      answeredCount: preferences.getInt(_countKey) ?? 0,
      usedKeys: (preferences.getStringList(_usedKeysKey) ?? const []).toSet(),
    );
  }

  @override
  Future<void> record(String questionKey) async {
    final preferences = await SharedPreferences.getInstance();
    final today = _dateKeyFor(DateTime.now());
    final sameDay = preferences.getString(_dateKey) == today;
    final usedKeys = sameDay
        ? (preferences.getStringList(_usedKeysKey) ?? const []).toSet()
        : <String>{};
    usedKeys.add(questionKey);
    await preferences.setString(_dateKey, today);
    await preferences.setInt(
      _countKey,
      (sameDay ? preferences.getInt(_countKey) ?? 0 : 0) + 1,
    );
    await preferences.setStringList(_usedKeysKey, usedKeys.toList());
  }

  @override
  Future<void> reset() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_dateKey);
    await preferences.remove(_countKey);
    await preferences.remove(_usedKeysKey);
    notifyListeners();
  }

  static String _dateKeyFor(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

class MemoryQuizDailyProgressStore extends ChangeNotifier
    implements QuizDailyProgressStore {
  QuizDailyProgress _progress = const QuizDailyProgress(
    answeredCount: 0,
    usedKeys: {},
  );

  @override
  Future<QuizDailyProgress> load() async => _progress;

  @override
  Future<void> record(String questionKey) async {
    _progress = QuizDailyProgress(
      answeredCount: _progress.answeredCount + 1,
      usedKeys: {..._progress.usedKeys, questionKey},
    );
  }

  @override
  Future<void> reset() async {
    _progress = const QuizDailyProgress(answeredCount: 0, usedKeys: {});
    notifyListeners();
  }
}
