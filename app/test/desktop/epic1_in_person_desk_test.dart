// SPDX-License-Identifier: Apache-2.0
// epic1 in person on the desktop (spec D5, P3, P5, P6): a request code answered and checked
// (Matches, Different), a send code answered by paste, a pasted send code received, two
// phones with the same check code, and an expired code. The wallet is the mock's FakeEpic1.
import 'dart:convert';

import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/in_person/in_person_dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/in_person/in_person_entry.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

/// The first code FakeEpic1 makes.
const _firstSlate = '00000000-0000-4000-8000-000000000001';

/// One poll interval and a little.
const _poll = Duration(milliseconds: 3100);

void main() {
  late ProviderContainer container;
  late FakeEpic1 fake;

  /// A page with two buttons into the flows.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    fake = (container.read(deskApiProvider) as MockDeskWallet).epic1Fake;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(onPressed: () => openDeskRequestInPerson(context), child: const Text('request')),
                  TextButton(onPressed: () => openDeskPayInPerson(context), child: const Text('pay')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Pumps [n] frames of [step]: the mock wallet waits on timers.
  Future<void> frames(WidgetTester tester, {int n = 10, Duration step = const Duration(milliseconds: 100)}) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(step);
    }
  }

  /// Opens a form, types [amount] (and the password for a send) and shows the code.
  Future<void> makeCode(WidgetTester tester, String entry, {String amount = '1.5'}) async {
    await tester.tap(find.text(entry));
    await frames(tester);
    await tester.enterText(find.byKey(deskInPersonAmountKey), amount);
    if (entry == 'pay') await tester.enterText(find.byKey(deskInPersonPasswordKey), 'secret');
    await tester.pump();
    await tester.tap(find.text(_l.deskIpMakeCode));
    await frames(tester);
  }

  /// Ends the test with the dialog gone, so its timers stop.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  void clipboard(WidgetTester tester, String text) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': text};
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  }

  BuildContext page(WidgetTester tester) => tester.element(find.text('request'));

  testWidgets('request: the code is covered until shown; the answer is checked; Matches finishes', (tester) async {
    await pump(tester);
    await makeCode(tester, 'request');
    expect(fake.calls, contains('inPersonRequest'));
    expect(find.text(_l.deskIpCodeLeadRequest), findsOneWidget);
    expect(find.byKey(deskInPersonQrKey), findsOneWidget);
    expect(find.byKey(deskInPersonCodeTextKey), findsOneWidget);
    expect(find.text(_l.qrShow), findsOneWidget);
    await tester.tap(find.text(_l.qrShow));
    await frames(tester, n: 2);
    expect(find.text(_l.qrShow), findsNothing);

    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: _poll);
    expect(find.text(_l.deskIpCheckPayer('4821')), findsOneWidget);
    await tester.tap(find.text(_l.deskIpMatches));
    await frames(tester);
    expect(fake.calls, contains('inPersonFinalize'));
    expect(find.text(_l.deskIpReceived), findsOneWidget);
    await close(tester);
  });

  testWidgets('request: Different stops the payment, nothing is finalized', (tester) async {
    await pump(tester);
    await makeCode(tester, 'request');
    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: _poll);
    await tester.tap(find.text(_l.deskIpDifferent));
    await frames(tester);
    expect(find.text(_l.deskE1PaymentStopped), findsWidgets);
    expect(fake.calls, isNot(contains('inPersonFinalize')));
    await close(tester);
  });

  testWidgets('pay: the password, the send code, the answer pasted back, Matches: Sent', (tester) async {
    await pump(tester);
    await makeCode(tester, 'pay');
    expect(fake.calls, contains('inPersonSend'));
    expect(find.text(_l.deskIpCodeLeadPay), findsOneWidget);
    clipboard(tester, 'BEGINEPICTX. answer. ENDEPICTX.');
    await tester.tap(find.text(_l.deskIpPasteAnswer));
    await frames(tester);
    expect(fake.calls, contains('inPersonTake'));
    expect(find.text(_l.deskIpCheckOther('4821')), findsOneWidget);
    await tester.tap(find.text(_l.deskIpMatches));
    await frames(tester);
    expect(find.text(_l.deskIpSent), findsOneWidget);
    await close(tester);
  });

  testWidgets('a pasted send code: review, Receive, posted, the check code shows', (tester) async {
    await pump(tester);
    final code = base64Url.encode([InPersonStage.send.index, ...List.filled(32, 7)]);
    bool? handled;
    openDeskInPersonText(page(tester), code).then((v) => handled = v);
    await frames(tester);
    expect(find.text(_l.deskIpReceiveTitle), findsOneWidget);
    await tester.tap(find.text(_l.deskIpReceiveButton));
    await frames(tester);
    expect(fake.calls, containsAllInOrder(['inPersonRead', 'inPersonReceive', 'inPersonPost']));
    expect(find.byKey(deskInPersonCheckKey), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    expect(find.text(_l.deskIpAnswerLead), findsNothing);
    await tester.tap(find.text(_l.commonDone));
    await frames(tester);
    expect(handled, isTrue);
    late bool other;
    openDeskInPersonText(page(tester), 'hello there').then((v) => other = v);
    await frames(tester, n: 2);
    expect(other, isFalse);
    await close(tester);
  });

  testWidgets('two phones with the same check code: P6, and Show a new code waits again', (tester) async {
    await pump(tester);
    await makeCode(tester, 'request');
    fake.answerCode(_firstSlate);
    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: _poll);
    expect(find.text(_l.deskE1SameCodeTwice), findsOneWidget);
    await tester.tap(find.text(_l.deskE1ShowNewCode));
    await frames(tester);
    expect(fake.calls.where((c) => c == 'inPersonRequest'), hasLength(2));
    expect(find.text(_l.deskIpWaiting), findsOneWidget);
    expect(find.text(_l.qrShow), findsOneWidget);
    await close(tester);
  });

  testWidgets('an expired code says so', (tester) async {
    await pump(tester);
    final code = base64Url.encode([InPersonStage.request.index, ...List.filled(32, 9)]);
    fake.failNext = const WalletError(kind: WalletErrorKind.codeExpired, message: 'expired');
    openDeskInPersonText(page(tester), code);
    await frames(tester);
    expect(find.text(_l.deskE1ErrCodeExpired), findsOneWidget);
    await close(tester);
  });
}
