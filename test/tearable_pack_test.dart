import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/widgets/tearable_pack.dart';

void main() {
  Widget subject(GlobalKey<TearablePackState> key, VoidCallback onOpened) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: TearablePack(key: key, onOpened: onOpened),
        ),
      ),
    );
  }

  testWidgets('progressは0〜1に収まり、70%未満で0に戻る', (tester) async {
    final key = GlobalKey<TearablePackState>();
    await tester.pumpWidget(subject(key, () {}));
    final topLeft = tester.getTopLeft(find.byKey(const Key('tearable-pack')));

    final gesture = await tester.startGesture(topLeft + const Offset(20, 40));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();
    expect(key.currentState!.progress, inInclusiveRange(0, 1));
    expect(key.currentState!.progress, lessThan(0.7));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(key.currentState!.progress, 0);
    expect(key.currentState!.isOpened, isFalse);
  });

  testWidgets('70%以上で1になり、完了後は再ドラッグできない', (tester) async {
    final key = GlobalKey<TearablePackState>();
    var openCount = 0;
    await tester.pumpWidget(subject(key, () => openCount++));
    final topLeft = tester.getTopLeft(find.byKey(const Key('tearable-pack')));

    await tester.dragFrom(topLeft + const Offset(20, 40), const Offset(230, 0));
    await tester.pumpAndSettle();

    expect(key.currentState!.progress, 1);
    expect(key.currentState!.isOpened, isTrue);
    expect(openCount, 1);

    await tester.dragFrom(
      topLeft + const Offset(20, 40),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();
    expect(key.currentState!.progress, 1);
    expect(openCount, 1);
  });

  testWidgets('上部の広い範囲と左端より内側から開始できる', (tester) async {
    final key = GlobalKey<TearablePackState>();
    await tester.pumpWidget(subject(key, () {}));
    final topLeft = tester.getTopLeft(find.byKey(const Key('tearable-pack')));

    final gesture = await tester.startGesture(topLeft + const Offset(112, 98));
    await gesture.moveBy(const Offset(55, 0));
    await tester.pump();
    expect(key.currentState!.progress, greaterThan(0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(key.currentState!.progress, 0);
  });

  testWidgets('上下にずれても横移動が優勢なら完全開封できる', (tester) async {
    final key = GlobalKey<TearablePackState>();
    var opened = false;
    await tester.pumpWidget(subject(key, () => opened = true));
    final topLeft = tester.getTopLeft(find.byKey(const Key('tearable-pack')));

    final gesture = await tester.startGesture(topLeft + const Offset(80, 70));
    await gesture.moveBy(const Offset(175, 34));
    await tester.pump();
    expect(key.currentState!.progress, greaterThanOrEqualTo(0.7));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(key.currentState!.progress, 1);
    expect(opened, isTrue);
  });

  testWidgets('パック中央から下では開封操作を開始しない', (tester) async {
    final key = GlobalKey<TearablePackState>();
    await tester.pumpWidget(subject(key, () {}));
    final topLeft = tester.getTopLeft(find.byKey(const Key('tearable-pack')));

    await tester.dragFrom(
      topLeft + const Offset(40, 230),
      const Offset(230, 0),
    );
    await tester.pumpAndSettle();
    expect(key.currentState!.progress, 0);
    expect(key.currentState!.isOpened, isFalse);
  });
}
