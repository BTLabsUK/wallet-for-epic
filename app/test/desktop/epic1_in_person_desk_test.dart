// SPDX-License-Identifier: Apache-2.0
// epic1 in person on the desktop (spec D5, P3, P5, P6): a request code answered and checked
// (Matches, Different), a send code answered by paste, a pasted send code received, two
// phones with the same check code, and an expired code. The online answer: the status line
// and its dialog, the server down, Cancel online reply and the late answers, no server.
// The wallet is the mock's FakeEpic1.
import 'dart:async';
import 'dart:convert';

import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/in_person/in_person_dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/in_person/in_person_entry.dart';
import 'package:epic_wallet/src/desktop/screens/in_person/in_person_online.dart';
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

  testWidgets('no Epicbox server: the password, the send code, the answer pasted back, Matches: Sent', (tester) async {
    await pump(tester);
    fake.inPersonNoMailbox = true;
    await makeCode(tester, 'pay');
    expect(fake.calls, contains('inPersonSend'));
    expect(find.text(_l.deskIpCodeLeadPay), findsOneWidget);
    expect(find.byKey(deskInPersonOnlineKey), findsNothing);
    expect(find.text(_l.deskIpWaiting), findsOneWidget);
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
    expect(find.byKey(deskInPersonOnlineKey), findsOneWidget);
    expect(find.text(_l.qrShow), findsOneWidget);
    await close(tester);
  });

  int count(String call) => fake.calls.where((c) => c == call).length;

  /// Opens the pasted send code [fill] and presses Receive.
  Future<void> receive(WidgetTester tester, {int fill = 7}) async {
    final code = base64Url.encode([InPersonStage.send.index, ...List.filled(32, fill)]);
    openDeskInPersonText(page(tester), code);
    await frames(tester);
    await tester.tap(find.text(_l.deskIpReceiveButton));
    await frames(tester);
  }

  /// Opens the status line's dialog.
  Future<void> details(WidgetTester tester) async {
    await tester.tap(find.byKey(deskInPersonOnlineKey));
    await frames(tester, n: 4);
    expect(find.text(_l.deskIpOnlineTitle), findsOneWidget);
  }

  String step(WidgetTester tester) => tester.widget<Text>(find.byKey(deskInPersonOnlineStepKey)).data!;

  testWidgets('online: one status line, no Paste; the dialog; the answer comes back', (tester) async {
    await pump(tester);
    await makeCode(tester, 'request');
    expect(find.byKey(deskInPersonOnlineKey), findsOneWidget);
    expect(find.text(_l.deskIpOnlineLine('relay.example.invalid')), findsOneWidget);
    expect(find.text(_l.deskIpWaiting), findsNothing);
    expect(find.text(_l.deskIpPasteAnswer), findsNothing);
    await details(tester);
    expect(find.text('relay.example.invalid'), findsOneWidget);
    expect(step(tester), _l.deskIpWaiting);
    expect(find.byKey(deskInPersonOnlineCancelKey), findsOneWidget);
    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: _poll);
    expect(step(tester), _l.deskIpStepReceived);
    expect(find.byKey(deskInPersonOnlineCancelKey), findsNothing);
    await tester.tap(find.text(_l.commonClose).last);
    await frames(tester, n: 4);
    expect(find.text(_l.deskIpCheckPayer('4821')), findsOneWidget);
    expect(find.byKey(deskInPersonOnlineKey), findsNothing);
    await close(tester);
  });

  testWidgets('online: the server down twice says so and brings Paste back; it keeps asking', (tester) async {
    await pump(tester);
    fake.inPersonServerDown = true;
    await makeCode(tester, 'request');
    await frames(tester, n: 1, step: _poll);
    expect(find.text(_l.deskIpPasteAnswer), findsNothing);
    await frames(tester, n: 1, step: _poll);
    expect(find.text(_l.deskIpOnlineDown), findsOneWidget);
    expect(find.text(_l.deskIpPasteAnswer), findsOneWidget);
    fake.inPersonServerDown = false;
    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: _poll);
    expect(find.text(_l.deskIpCheckPayer('4821')), findsOneWidget);
    await close(tester);
  });

  testWidgets('cancel online reply: Paste comes back, a late online answer is left, one finish', (tester) async {
    await pump(tester);
    await makeCode(tester, 'pay');
    await details(tester);
    expect(find.text(_l.deskIpOnlineCancelCode), findsOneWidget);
    await tester.tap(find.byKey(deskInPersonOnlineCancelKey));
    await frames(tester, n: 4);
    expect(find.byKey(deskInPersonOnlineKey), findsNothing);
    expect(find.text(_l.deskIpWaiting), findsOneWidget);
    expect(find.text(_l.deskIpPasteAnswer), findsOneWidget);
    final asks = count('inPersonAnswers');
    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: _poll);
    expect(count('inPersonAnswers'), asks);
    expect(find.text(_l.deskIpCheckOther('4821')), findsNothing);
    fake.inPersonTakeKnown = true;
    clipboard(tester, 'BEGINEPICTX. answer. ENDEPICTX.');
    await tester.tap(find.text(_l.deskIpPasteAnswer));
    await frames(tester);
    expect(find.text(_l.deskIpCheckOther('4821')), findsOneWidget);
    await tester.tap(find.text(_l.deskIpMatches));
    await frames(tester);
    expect(find.text(_l.deskIpSent), findsOneWidget);
    expect(count('inPersonFinalize'), 1);
    await close(tester);
  });

  testWidgets('answering online: Sending in place of the QR; a failed post shows the answer; Retry posts', (tester) async {
    await pump(tester);
    final hold = fake.inPersonPostHold = Completer<void>();
    await receive(tester);
    expect(find.text(_l.deskIpOnlineSending), findsOneWidget);
    expect(find.byKey(deskInPersonQrKey), findsNothing);
    expect(find.text(_l.deskIpAnswerLead), findsNothing);
    fake.inPersonServerDown = true;
    hold.complete();
    await frames(tester);
    expect(find.text(_l.deskIpPostFailed), findsOneWidget);
    expect(find.text(_l.deskIpAnswerLead), findsOneWidget);
    expect(find.byKey(deskInPersonQrKey), findsOneWidget);
    expect(find.byKey(deskInPersonOnlineKey), findsNothing);
    fake.inPersonServerDown = false;
    await tester.tap(find.text(_l.commonRetry));
    await frames(tester);
    expect(find.byKey(deskInPersonCheckKey), findsOneWidget);
    expect(find.text(_l.deskIpAnswerLead), findsNothing);
    expect(count('inPersonPost'), 2);
    await close(tester);
  });

  testWidgets('answering online: Cancel while sending shows the answer; a late check code still shows', (tester) async {
    await pump(tester);
    final hold = fake.inPersonPostHold = Completer<void>();
    await receive(tester);
    await details(tester);
    expect(step(tester), _l.deskIpStepPosting);
    expect(find.text(_l.deskIpOnlineCancelAnswer), findsOneWidget);
    await tester.tap(find.byKey(deskInPersonOnlineCancelKey));
    await frames(tester, n: 4);
    expect(find.text(_l.deskIpAnswerLead), findsOneWidget);
    expect(find.byKey(deskInPersonQrKey), findsOneWidget);
    expect(find.byKey(deskInPersonOnlineKey), findsNothing);
    hold.complete();
    await frames(tester);
    expect(find.byKey(deskInPersonCheckKey), findsOneWidget);
    expect(find.text(_l.deskIpAnswerLead), findsOneWidget);
    await close(tester);
  });

  testWidgets('answering with no Epicbox server: the answer QR at once, no post, no status line', (tester) async {
    await pump(tester);
    fake.inPersonNoMailbox = true;
    await receive(tester);
    expect(find.text(_l.deskIpAnswerLead), findsOneWidget);
    expect(find.byKey(deskInPersonQrKey), findsOneWidget);
    expect(find.byKey(deskInPersonOnlineKey), findsNothing);
    expect(fake.calls, isNot(contains('inPersonPost')));
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
