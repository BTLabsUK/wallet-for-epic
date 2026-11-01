// SPDX-License-Identifier: Apache-2.0
// Review is off whenever the line under it names a block (#24), and keeps its name then (#31):
// pressed with a field wrong, it waits for that field to change.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _epicbox = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';

void main() {
  testWidgets('a blocked Review is off, named Review, until the field changes', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SendScreen())),
      ),
    );
    await tester.pumpAndSettle();
    EButton review() => tester.widget<EButton>(find.byWidgetPredicate((w) => w is EButton && w.kind == EBtnKind.primary));

    await tester.enterText(find.byType(EditableText).first, _epicbox);
    await tester.enterText(find.byType(EditableText).at(1), '99999999');
    await tester.pumpAndSettle();
    expect(review().onPressed, isNotNull);

    await tester.tap(find.byWidgetPredicate((w) => w is EButton && w.kind == EBtnKind.primary));
    await tester.pumpAndSettle();
    expect(find.text('Fix the marked fields.'), findsOneWidget);
    expect(review().label, 'Review', reason: 'the name stays; the reason is the line under it');
    expect(review().onPressed, isNull, reason: 'the line names a block');

    await tester.enterText(find.byType(EditableText).at(1), '1');
    await tester.pumpAndSettle();
    expect(find.text('Fix the marked fields.'), findsNothing);
    expect(review().onPressed, isNotNull);
  });
}
