// SPDX-License-Identifier: Apache-2.0
// Review waits for the reach check of the Link address in To: pressed right after To changed,
// it does not open while the wallet has not answered, and not at all when none answers.
import 'dart:async';

import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/send_reach.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

const _link = 'https://onetime.us/7s626632';

Future<void> _open(WidgetTester tester) async {
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
  addTearDown(() => reachCheckForTest = null);
}

Future<void> _typeAndPressReview(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).first, _link);
  await tester.enterText(find.byType(EditableText).at(1), '1');
  await tester.pump();
  await tester.tap(find.byWidgetPredicate((w) => w is EButton && w.kind == EBtnKind.primary));
  await tester.pump();
}

void main() {
  testWidgets('Review right after To: it waits for the wallet to answer', (tester) async {
    final answer = Completer<ReachResult>();
    reachCheckForTest = (_) => answer.future;
    await _open(tester);
    await _typeAndPressReview(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_l.deskSendReviewTitle), findsNothing, reason: 'the check has not ended');

    answer.complete(ReachResult.answers);
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSendReviewTitle), findsOneWidget);
  });

  testWidgets('Review right after To: no wallet answers, no review, the notice says so', (tester) async {
    final answer = Completer<ReachResult>();
    reachCheckForTest = (_) => answer.future;
    await _open(tester);
    await _typeAndPressReview(tester);
    await tester.pump(const Duration(seconds: 1));

    answer.complete(ReachResult.noAnswer);
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSendReviewTitle), findsNothing);
    expect(find.byKey(const ValueKey('send-reach')), findsOneWidget);
    expect(find.byKey(const ValueKey('send-reach-retry')), findsOneWidget);
  });
}
