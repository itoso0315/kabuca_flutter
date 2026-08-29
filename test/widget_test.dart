import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/app/app.dart';

void main() {
  testWidgets('KABUCAのホームと3タブを表示・切り替えできる', (tester) async {
    await tester.pumpWidget(const KabucaApp());

    expect(find.text('KABUCA'), findsNWidgets(2));
    expect(find.text('今日も、1パック。'), findsOneWidget);
    expect(find.text('今日の無料パック'), findsOneWidget);
    expect(find.text('KABUCA DAILY PACK'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'パックを開ける'), findsOneWidget);
    expect(find.text('所持カード'), findsOneWidget);
    expect(find.text('0枚'), findsOneWidget);
    expect(find.text('図鑑コンプリート率'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'パックを開ける'));
    await tester.pump();
    expect(find.text('パック開封はTask003で実装予定です'), findsOneWidget);

    await tester.tap(find.text('図鑑'));
    await tester.pumpAndSettle();
    expect(find.text('図鑑'), findsNWidgets(2));

    await tester.tap(find.text('マイページ'));
    await tester.pumpAndSettle();
    expect(find.text('マイページ'), findsNWidgets(2));

    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    expect(find.text('今日も、1パック。'), findsOneWidget);
  });
}
