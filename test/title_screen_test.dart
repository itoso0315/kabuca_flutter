import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/screens/splash/title_screen.dart';
import 'package:kabuca_flutter/services/backend_warmup_service.dart';

void main() {
  Widget subject({
    required BackendWarmupService warmup,
    Future<String> Function()? initialize,
    Duration minimum = const Duration(milliseconds: 100),
    Duration maximum = const Duration(milliseconds: 300),
    void Function()? onHomeBuilt,
  }) => MaterialApp(
    home: TitleScreen<String>(
      initialize: initialize ?? () async => 'ready',
      warmupService: warmup,
      minimumDuration: minimum,
      maximumDuration: maximum,
      homeBuilder: (_) {
        onHomeBuilt?.call();
        return const Scaffold(key: Key('home-screen'));
      },
    ),
  );

  testWidgets('API即成功でも最短表示時間はタイトルを表示する', (tester) async {
    await tester.pumpWidget(subject(warmup: _ImmediateWarmup()));
    expect(find.byKey(const Key('title-screen')), findsOneWidget);
    expect(find.text('KABUCA'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 99));
    expect(find.byKey(const Key('home-screen')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('遅いAPIは最大表示時間で打ち切り、二重遷移しない', (tester) async {
    final warmup = _ControlledWarmup();
    var builds = 0;
    await tester.pumpWidget(
      subject(warmup: warmup, onHomeBuilt: () => builds++),
    );
    await tester.pump(const Duration(milliseconds: 299));
    expect(find.byKey(const Key('title-screen')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
    warmup.complete(BackendWarmupStatus.ready);
    await tester.pump();
    expect(builds, 1);
  });

  testWidgets('API失敗でも最短時間後にホームへ進む', (tester) async {
    await tester.pumpWidget(subject(warmup: _ThrowingWarmup()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('初期化・ウォームアップはタイトル表示と同時に開始する', (tester) async {
    var initializationStarted = false;
    final warmup = _ImmediateWarmup();
    await tester.pumpWidget(
      subject(
        warmup: warmup,
        initialize: () async {
          initializationStarted = true;
          return 'ready';
        },
      ),
    );
    expect(initializationStarted, isTrue);
    expect(warmup.called, isTrue);
    expect(find.byKey(const Key('title-screen')), findsOneWidget);
  });
}

class _ImmediateWarmup implements BackendWarmupService {
  bool called = false;

  @override
  Future<BackendWarmupStatus> warmUp() async {
    called = true;
    return BackendWarmupStatus.ready;
  }
}

class _ControlledWarmup implements BackendWarmupService {
  final _completer = Completer<BackendWarmupStatus>();

  @override
  Future<BackendWarmupStatus> warmUp() => _completer.future;

  void complete(BackendWarmupStatus status) => _completer.complete(status);
}

class _ThrowingWarmup implements BackendWarmupService {
  @override
  Future<BackendWarmupStatus> warmUp() => Future.error(Exception('offline'));
}
