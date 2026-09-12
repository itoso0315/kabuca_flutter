import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/card_catalog.dart';
import '../../models/company_card.dart';
import '../../models/company_quiz_meta.dart';
import '../../models/quiz_question.dart';
import '../../services/quiz_service.dart';
import '../../services/quiz_daily_progress_store.dart';
import '../../state/game_state.dart';
import '../../state/point_wallet.dart';
import '../../widgets/company_card_artwork.dart';
import '../../widgets/kabu_currency.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.gameState,
    this.pointWallet,
    this.quizService,
    this.dailyProgressStore,
  });

  final GameState gameState;
  final PointWallet? pointWallet;
  final QuizService? quizService;
  final QuizDailyProgressStore? dailyProgressStore;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizService _quizService;
  late final QuizDailyProgressStore _dailyProgressStore;
  Map<String, CompanyQuizMeta> _metadata = const {};
  QuizDailyProgress _dailyProgress = const QuizDailyProgress(
    answeredCount: 0,
    usedKeys: {},
  );
  QuizQuestion? _question;
  QuizSide? _selectedSide;
  bool _started = false;
  bool _completed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _quizService = widget.quizService ?? QuizService();
    _dailyProgressStore =
        widget.dailyProgressStore ?? SharedPreferencesQuizDailyProgressStore();
    widget.gameState.addListener(_handleGameStateChanged);
    _dailyProgressStore.addListener(_handleDailyProgressChanged);
    _loadMetadata();
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_handleGameStateChanged);
    _dailyProgressStore.removeListener(_handleDailyProgressChanged);
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final results = await Future.wait<Object>([
      _quizService.loadMetadata(),
      _dailyProgressStore.load(),
    ]);
    final metadata = results[0] as Map<String, CompanyQuizMeta>;
    final dailyProgress = results[1] as QuizDailyProgress;
    if (!mounted) return;
    setState(() {
      _metadata = metadata;
      _dailyProgress = dailyProgress;
      _question = dailyProgress.answeredCount >= QuizService.maxDailyQuestions
          ? null
          : _createQuestion();
      _completed = _question == null && dailyProgress.answeredCount > 0;
      _loading = false;
    });
  }

  void _handleGameStateChanged() {
    if (!mounted ||
        _loading ||
        _question != null ||
        _dailyProgress.answeredCount >= QuizService.maxDailyQuestions) {
      return;
    }
    final question = _createQuestion();
    if (question == null) return;
    setState(() {
      _question = question;
      _started = false;
      _completed = false;
    });
  }

  Future<void> _handleDailyProgressChanged() async {
    final dailyProgress = await _dailyProgressStore.load();
    if (!mounted) return;
    setState(() {
      _dailyProgress = dailyProgress;
      _question = dailyProgress.answeredCount >= QuizService.maxDailyQuestions
          ? null
          : _createQuestion();
      _started = false;
      _completed = _question == null && dailyProgress.answeredCount > 0;
    });
  }

  List<CompanyCard> get _ownedCards {
    return CardCatalog.cards
        .where((card) => widget.gameState.owns(card.id))
        .toList();
  }

  QuizQuestion? _createQuestion() => _quizService.generateQuestion(
    ownedCards: _ownedCards,
    metadata: _metadata,
    excludedQuestionKeys: _dailyProgress.usedKeys,
  );

  void _answer(QuizSide side) {
    if (_selectedSide != null || _question == null) return;
    final question = _question!;
    final questionKey = _quizService.questionKey(question);
    setState(() {
      _selectedSide = side;
      _dailyProgress = QuizDailyProgress(
        answeredCount: _dailyProgress.answeredCount + 1,
        usedKeys: {..._dailyProgress.usedKeys, questionKey},
      );
    });
    unawaited(_dailyProgressStore.record(questionKey));
    if (side == question.correctSide && widget.pointWallet != null) {
      unawaited(widget.pointWallet!.refund(question.rewardKabu));
    }
  }

  void _startQuiz() {
    if (_question == null) return;
    setState(() => _started = true);
  }

  void _nextQuestion() {
    final nextQuestion =
        _dailyProgress.answeredCount >= QuizService.maxDailyQuestions
        ? null
        : _createQuestion();
    setState(() {
      _question = nextQuestion;
      _selectedSide = null;
      _completed = nextQuestion == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('quiz-screen'),
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
      children: [
        Text('企業クイズ', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('集めたカードで、日本企業を知ろう。'),
        const SizedBox(height: 24),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_question == null)
          _completed
              ? _QuizCompleteState(
                  dailyLimitReached:
                      _dailyProgress.answeredCount >=
                      QuizService.maxDailyQuestions,
                )
              : _QuizEmptyState(hasMetadata: _metadata.isNotEmpty)
        else if (!_started)
          _QuizStartCard(onStart: _startQuiz)
        else
          _QuizQuestionView(
            question: _question!,
            selectedSide: _selectedSide,
            onAnswer: _answer,
            onNext: _nextQuestion,
          ),
      ],
    );
  }
}

class _QuizStartCard extends StatelessWidget {
  const _QuizStartCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
      child: Column(
        children: [
          Icon(
            Icons.compare_arrows_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            '集めたカードで企業を比べよう',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text('2枚のカードを比べて、どちらの数値が大きいか当てよう。'),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('quiz-start-button'),
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('クイズを始める'),
          ),
        ],
      ),
    ),
  );
}

class _QuizEmptyState extends StatelessWidget {
  const _QuizEmptyState({required this.hasMetadata});

  final bool hasMetadata;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
      child: Column(
        children: [
          Icon(
            hasMetadata ? Icons.style_outlined : Icons.cloud_off_rounded,
            size: 44,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            hasMetadata ? 'クイズに挑戦するには、まず2社以上の企業カードを集めよう' : 'クイズデータを読み込めませんでした',
            key: const Key('quiz-empty-message'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (hasMetadata) ...[
            const SizedBox(height: 8),
            const Text('ホームでパックを開けて、企業カードを集めよう。', textAlign: TextAlign.center),
          ],
        ],
      ),
    ),
  );
}

class _QuizCompleteState extends StatelessWidget {
  const _QuizCompleteState({required this.dailyLimitReached});

  final bool dailyLimitReached;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
      child: Column(
        children: [
          Icon(
            dailyLimitReached
                ? Icons.calendar_today_rounded
                : Icons.check_circle_outline_rounded,
            size: 44,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            dailyLimitReached
                ? '今日は10問までです。明日また挑戦しよう。'
                : 'このカードでできる問題はすべて終了しました。',
            key: const Key('quiz-complete-message'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('新しいカードを集めると、挑戦できる問題が増えます。', textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _QuizQuestionView extends StatelessWidget {
  const _QuizQuestionView({
    required this.question,
    required this.selectedSide,
    required this.onAnswer,
    required this.onNext,
  });

  final QuizQuestion question;
  final QuizSide? selectedSide;
  final ValueChanged<QuizSide> onAnswer;
  final VoidCallback onNext;

  bool get answered => selectedSide != null;

  @override
  Widget build(BuildContext context) {
    final correctSide = question.correctSide;
    return Column(
      children: [
        Text(
          '「${question.fact}」に当てはまる企業はどっち？',
          key: const Key('quiz-question-text'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _QuizChoiceCard(
                card: question.leftCard,
                side: QuizSide.left,
                selectedSide: selectedSide,
                correctSide: correctSide,
                onTap: () => onAnswer(QuizSide.left),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 92),
              child: Text(
                'VS',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
            Expanded(
              child: _QuizChoiceCard(
                card: question.rightCard,
                side: QuizSide.right,
                selectedSide: selectedSide,
                correctSide: correctSide,
                onTap: () => onAnswer(QuizSide.right),
              ),
            ),
          ],
        ),
        if (answered) ...[
          const SizedBox(height: 20),
          _QuizAnswerSummary(
            question: question,
            selectedSide: selectedSide!,
            rewardKabu: question.rewardKabu,
            onNext: onNext,
          ),
        ],
      ],
    );
  }
}

class _QuizChoiceCard extends StatelessWidget {
  const _QuizChoiceCard({
    required this.card,
    required this.side,
    required this.selectedSide,
    required this.correctSide,
    required this.onTap,
  });

  final CompanyCard card;
  final QuizSide side;
  final QuizSide? selectedSide;
  final QuizSide correctSide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final answered = selectedSide != null;
    final selected = selectedSide == side;
    final correct = correctSide == side;
    final borderColor = !answered
        ? const Color(0xFFD8D2C4)
        : correct
        ? Colors.green.shade600
        : selected
        ? Colors.red.shade600
        : const Color(0xFFD8D2C4);
    return Semantics(
      button: true,
      label: '${card.companyName}を選ぶ',
      child: GestureDetector(
        key: Key('quiz-choice-${card.companyId}'),
        onTap: answered ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: CompanyCardArtwork(
            card: card,
            width: 128,
            height: 180,
            compact: true,
          ),
        ),
      ),
    );
  }
}

class _QuizAnswerSummary extends StatelessWidget {
  const _QuizAnswerSummary({
    required this.question,
    required this.selectedSide,
    required this.rewardKabu,
    required this.onNext,
  });

  final QuizQuestion question;
  final QuizSide selectedSide;
  final int rewardKabu;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final correct = selectedSide == question.correctSide;
    return Card(
      key: const Key('quiz-answer-summary'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              correct ? '正解！' : '不正解',
              key: const Key('quiz-result'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: correct ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (correct) ...[
              const SizedBox(height: 4),
              KabuCurrencyText(
                text: '+$rewardKabu KABU',
                key: const Key('quiz-reward'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              '正解：${question.correctSide == QuizSide.left ? question.leftCard.companyName : question.rightCard.companyName}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              question.explanation,
              key: const Key('quiz-explanation'),
              style: const TextStyle(height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('quiz-next-button'),
              onPressed: onNext,
              child: const Text('次の問題'),
            ),
          ],
        ),
      ),
    );
  }
}
