// SPDX-License-Identifier: Apache-2.0
// epic1 in person on the phone (spec D5, P3, P5, P6): a request code answered and checked
// (Matches, Different), a send code answered by paste, a scanned send code received, two
// phones with the same check code, and an expired code. The online answer: the status line
// and its sheet, the server down, Cancel online reply and the late answers, no server.
// The wallet is FakeEpic1.
import 'dart:async';
import 'dart:convert';

import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/in_person/in_person_entry.dart';
import 'package:epic_wallet/src/ui/in_person/in_person_logic.dart';
import 'package:epic_wallet/src/ui/in_person/in_person_online.dart';
import 'package:epic_wallet/src/ui/in_person/in_person_screens.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/send_pin.dart';

final _l = englishStrings;

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Mainnet extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(dataDir: '/fake/wallets/mainnet', nodeUrl: mainnetPreset.nodeUrl);
}

/// The first code FakeEpic1 makes.
const _firstSlate = '00000000-0000-4000-8000-000000000001';

void main() {
  late FakeWalletSession session;
  late FakeEpic1 fake;

  setUp(() {
    session = FakeWalletSession();
    fake = session.epic1Fake;
  });

  /// A screen with three buttons into the flows; the last opened [String] is pasted text.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    allowPinCheck(session);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          secretStoreProvider.overrideWithValue(sendPinStore()),
          sessionProvider.overrideWith(() => _Open(session)),
          walletConfigProvider.overrideWith(_Mainnet.new),
          countedConfirmationsProvider.overrideWithValue(BigInt.from(10)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  TextButton(onPressed: () => openRequestInPerson(context), child: const Text('request')),
                  TextButton(onPressed: () => openPayInPerson(context), child: const Text('pay')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Pumps [n] frames of [step]: the code screen's progress line never settles.
  Future<void> frames(WidgetTester tester, {int n = 6, Duration step = const Duration(milliseconds: 100)}) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(step);
    }
  }

  /// Opens a form, types [amount] and shows the code (answering the PIN for a send).
  Future<void> makeCode(WidgetTester tester, String entry, {String amount = '1.5'}) async {
    await tester.tap(find.text(entry));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(inPersonAmountKey), amount);
    await tester.tap(find.text(_l.deskIpMakeCode));
    await frames(tester);
    await answerPin(tester, settle: false);
    await frames(tester);
  }

  /// Ends the test with the code screen gone, so its timers stop.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  /// The clipboard holds [text] for the next Paste press.
  void clipboard(WidgetTester tester, String text) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': text};
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  }

  testWidgets('request: the code is covered until shown; the answer is checked; Matches finishes', (tester) async {
    await pump(tester);
    await makeCode(tester, 'request');
    expect(fake.calls, contains('inPersonRequest'));
    expect(find.text(_l.deskIpCodeLeadRequest), findsOneWidget);
    expect(find.byKey(inPersonQrKey), findsOneWidget);
    expect(find.text(_l.qrShow), findsOneWidget);
    await tester.tap(find.text(_l.qrShow));
    await frames(tester, n: 2);
    expect(find.text(_l.qrShow), findsNothing);

    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: inPersonPollEveryForTest);
    expect(find.text(_l.deskIpCheckPayer('4821')), findsOneWidget);
    await tester.tap(find.text(_l.deskIpMatches));
    await frames(tester);
    expect(fake.calls, contains('inPersonFinalize'));
    expect(find.text(_l.deskIpReceived), findsWidgets);
    await close(tester);
  });

  testWidgets('request: Different stops the payment, nothing is finalized', (tester) async {
    await pump(tester);
    await makeCode(tester, 'request');
    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: inPersonPollEveryForTest);
    await tester.tap(find.text(_l.deskIpDifferent));
    await frames(tester);
    expect(find.text(_l.deskE1PaymentStopped), findsOneWidget);
    expect(fake.calls, isNot(contains('inPersonFinalize')));
    await close(tester);
  });

  testWidgets('no Epicbox server: the PIN, the send code, the answer pasted back, Matches: Sent', (tester) async {
    fake.inPersonNoMailbox = true;
    await pump(tester);
    await makeCode(tester, 'pay');
    expect(fake.calls, contains('inPersonSend'));
    expect(find.text(_l.deskIpCodeLeadPay), findsOneWidget);
    expect(find.byKey(inPersonOnlineKey), findsNothing);
    expect(find.text(_l.deskIpWaiting), findsOneWidget);
    expect(find.text(_l.deskIpScanAnswer), findsOneWidget);
    clipboard(tester, 'BEGINEPICTX. answer. ENDEPICTX.');
    await tester.tap(find.text(_l.deskIpPasteAnswer));
    await frames(tester);
    expect(fake.calls, contains('inPersonTake'));
    expect(find.text(_l.deskIpCheckOther('4821')), findsOneWidget);
    await tester.tap(find.text(_l.deskIpMatches));
    await frames(tester);
    expect(find.text(_l.deskIpSent), findsWidgets);
    await close(tester);
  });

  testWidgets('a scanned send code: review, Receive, posted, the check code shows', (tester) async {
    await pump(tester);
    final code = base64Url.encode([InPersonStage.send.index, ...List.filled(32, 7)]);
    final context = tester.element(find.text('request'));
    late bool handled;
    openInPersonText(context, code).then((v) => handled = v);
    await frames(tester);
    expect(find.text(_l.deskIpReceiveTitle), findsOneWidget);
    await tester.tap(find.text(_l.deskIpReceiveButton));
    await frames(tester);
    expect(fake.calls, containsAllInOrder(['inPersonRead', 'inPersonReceive', 'inPersonPost']));
    expect(find.byKey(inPersonCheckKey), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    // Posted: no answer to show back.
    expect(find.text(_l.deskIpAnswerLead), findsNothing);
    await tester.tap(find.text(_l.commonDone));
    await frames(tester);
    expect(handled, isTrue);
    expect(await openInPersonText(context, 'hello there'), isFalse);
    await close(tester);
  });

  testWidgets('two phones with the same check code: P6, and Show a new code waits again', (tester) async {
    await pump(tester);
    await makeCode(tester, 'request');
    fake.answerCode(_firstSlate);
    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: inPersonPollEveryForTest);
    expect(find.text(_l.deskE1SameCodeTwice), findsOneWidget);
    await tester.tap(find.text(_l.deskE1ShowNewCode));
    await frames(tester);
    expect(fake.calls.where((c) => c == 'inPersonRequest'), hasLength(2));
    expect(find.byKey(inPersonOnlineKey), findsOneWidget);
    expect(find.text(_l.qrShow), findsOneWidget);
    await close(tester);
  });

  int count(String call) => fake.calls.where((c) => c == call).length;

  /// Opens the pasted send code [fill] and presses Receive.
  Future<void> receive(WidgetTester tester, {int fill = 7}) async {
    final code = base64Url.encode([InPersonStage.send.index, ...List.filled(32, fill)]);
    openInPersonText(tester.element(find.text('request')), code);
    await frames(tester);
    await tester.tap(find.text(_l.deskIpReceiveButton));
    await frames(tester);
  }

  /// Opens the status line's sheet.
  Future<void> details(WidgetTester tester) async {
    await tester.tap(find.byKey(inPersonOnlineKey));
    await frames(tester, n: 4);
    expect(find.text(_l.deskIpOnlineTitle), findsOneWidget);
  }

  testWidgets('online: one status line, no Paste or Scan; the sheet; the answer comes back', (tester) async {
    await pump(tester);
    await makeCode(tester, 'request');
    expect(find.byKey(inPersonOnlineKey), findsOneWidget);
    expect(find.text(_l.deskIpOnlineLine('relay.example.invalid')), findsOneWidget);
    expect(find.text(_l.deskIpWaiting), findsNothing);
    expect(find.text(_l.deskIpPasteAnswer), findsNothing);
    expect(find.text(_l.deskIpScanAnswer), findsNothing);
    await details(tester);
    expect(find.text('relay.example.invalid'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(inPersonOnlineStepKey)).data, _l.deskIpWaiting);
    expect(find.byKey(inPersonOnlineCancelKey), findsOneWidget);
    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: inPersonPollEveryForTest);
    // The sheet follows: received, nothing left to cancel.
    expect(tester.widget<Text>(find.byKey(inPersonOnlineStepKey)).data, _l.deskIpStepReceived);
    expect(find.byKey(inPersonOnlineCancelKey), findsNothing);
    await tester.tap(find.text(_l.commonClose).last);
    await frames(tester, n: 4);
    expect(find.text(_l.deskIpCheckPayer('4821')), findsOneWidget);
    expect(find.byKey(inPersonOnlineKey), findsNothing);
    await close(tester);
  });

  testWidgets('online: the server down twice says so and brings Paste and Scan back; it keeps asking', (tester) async {
    fake.inPersonServerDown = true;
    await pump(tester);
    await makeCode(tester, 'request');
    await frames(tester, n: 1, step: inPersonPollEveryForTest);
    expect(find.text(_l.deskIpPasteAnswer), findsNothing);
    await frames(tester, n: 1, step: inPersonPollEveryForTest);
    expect(find.text(_l.deskIpOnlineDown), findsOneWidget);
    expect(find.text(_l.deskIpPasteAnswer), findsOneWidget);
    expect(find.text(_l.deskIpScanAnswer), findsOneWidget);
    fake.inPersonServerDown = false;
    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: inPersonPollEveryForTest);
    expect(find.text(_l.deskIpCheckPayer('4821')), findsOneWidget);
    await close(tester);
  });

  testWidgets('cancel online reply: Paste and Scan come back, a late online answer is left, one finish', (tester) async {
    await pump(tester);
    await makeCode(tester, 'pay');
    await details(tester);
    expect(find.text(_l.deskIpOnlineCancelCode), findsOneWidget);
    await tester.tap(find.byKey(inPersonOnlineCancelKey));
    await frames(tester, n: 4);
    expect(find.byKey(inPersonOnlineKey), findsNothing);
    expect(find.text(_l.deskIpWaiting), findsOneWidget);
    expect(find.text(_l.deskIpPasteAnswer), findsOneWidget);
    final asks = count('inPersonAnswers');
    // The answer reaches the server after the cancel: nobody asks for it.
    fake.answerCode(_firstSlate);
    await frames(tester, n: 2, step: inPersonPollEveryForTest);
    expect(count('inPersonAnswers'), asks);
    expect(find.text(_l.deskIpCheckOther('4821')), findsNothing);
    // The same answer pasted: LEPIC's one record of it.
    fake.inPersonTakeKnown = true;
    clipboard(tester, 'BEGINEPICTX. answer. ENDEPICTX.');
    await tester.tap(find.text(_l.deskIpPasteAnswer));
    await frames(tester);
    expect(find.text(_l.deskIpCheckOther('4821')), findsOneWidget);
    await tester.tap(find.text(_l.deskIpMatches));
    await frames(tester);
    expect(find.text(_l.deskIpSent), findsWidgets);
    expect(count('inPersonFinalize'), 1);
    await close(tester);
  });

  testWidgets('an answer that lands while the cancel is pressed is left', (tester) async {
    final made = await fake.inPersonRequest(amount: BigInt.from(150000000));
    final watch = InPersonCodeWatch(wallet: fake, stage: InPersonStage.request, amount: BigInt.from(150000000), made: made);
    fake.answerCode(made.slateId);
    final asking = watch.poll();
    watch.cancelOnline();
    await asking;
    expect(watch.phase, InPersonPhase.waiting);
    expect(watch.step, InPersonOnlineStep.cancelled);
    expect(watch.manual, isTrue);
    watch.dispose();
  });

  testWidgets('a paste after the online answer is the same answer: nothing changes, one finish', (tester) async {
    final made = await fake.inPersonRequest(amount: BigInt.from(150000000));
    final watch = InPersonCodeWatch(wallet: fake, stage: InPersonStage.request, amount: BigInt.from(150000000), made: made);
    fake.answerCode(made.slateId);
    await watch.poll();
    expect(watch.phase, InPersonPhase.check);
    expect(watch.step, InPersonOnlineStep.received);
    expect(watch.manual, isTrue);
    expect(watch.online, isFalse);
    fake.inPersonTakeKnown = true;
    expect(await watch.take('BEGINEPICTX. answer. ENDEPICTX.'), isTrue);
    expect(watch.phase, InPersonPhase.check);
    expect(watch.checkCode, '4821');
    await watch.matches();
    expect(watch.phase, InPersonPhase.done);
    expect(count('inPersonFinalize'), 1);
    watch.dispose();
  });

  testWidgets('answering online: Sending in place of the QR; a failed post shows the answer; Retry posts', (tester) async {
    final hold = fake.inPersonPostHold = Completer<void>();
    await pump(tester);
    await receive(tester);
    expect(find.text(_l.deskIpOnlineSending), findsOneWidget);
    expect(find.byKey(inPersonAnswerQrKey), findsNothing);
    expect(find.text(_l.deskIpAnswerLead), findsNothing);
    fake.inPersonServerDown = true;
    hold.complete();
    await frames(tester);
    expect(find.text(_l.deskIpPostFailed), findsOneWidget);
    expect(find.text(_l.deskIpAnswerLead), findsOneWidget);
    expect(find.byKey(inPersonAnswerQrKey), findsOneWidget);
    expect(find.byKey(inPersonOnlineKey), findsNothing);
    fake.inPersonServerDown = false;
    await tester.tap(find.text(_l.commonRetry));
    await frames(tester);
    expect(find.byKey(inPersonCheckKey), findsOneWidget);
    expect(find.text(_l.deskIpAnswerLead), findsNothing);
    expect(count('inPersonPost'), 2);
    await close(tester);
  });

  testWidgets('answering online: Cancel while sending shows the answer; a late check code still shows', (tester) async {
    final hold = fake.inPersonPostHold = Completer<void>();
    await pump(tester);
    await receive(tester);
    await details(tester);
    expect(tester.widget<Text>(find.byKey(inPersonOnlineStepKey)).data, _l.deskIpStepPosting);
    expect(find.text(_l.deskIpOnlineCancelAnswer), findsOneWidget);
    await tester.tap(find.byKey(inPersonOnlineCancelKey));
    await frames(tester, n: 4);
    expect(find.text(_l.deskIpAnswerLead), findsOneWidget);
    expect(find.byKey(inPersonAnswerQrKey), findsOneWidget);
    expect(find.byKey(inPersonOnlineKey), findsNothing);
    hold.complete();
    await frames(tester);
    expect(find.byKey(inPersonCheckKey), findsOneWidget);
    expect(find.text(_l.deskIpAnswerLead), findsOneWidget);
    await close(tester);
  });

  testWidgets('answering with no Epicbox server: the answer QR at once, no post, no status line', (tester) async {
    fake.inPersonNoMailbox = true;
    await pump(tester);
    await receive(tester);
    expect(find.text(_l.deskIpAnswerLead), findsOneWidget);
    expect(find.byKey(inPersonAnswerQrKey), findsOneWidget);
    expect(find.byKey(inPersonOnlineKey), findsNothing);
    expect(fake.calls, isNot(contains('inPersonPost')));
    await close(tester);
  });

  testWidgets('an expired code says so', (tester) async {
    await pump(tester);
    final code = base64Url.encode([InPersonStage.request.index, ...List.filled(32, 9)]);
    fake.failNext = const WalletError(kind: WalletErrorKind.codeExpired, message: 'expired');
    final context = tester.element(find.text('request'));
    openInPersonText(context, code);
    await frames(tester);
    expect(find.text(_l.deskE1ErrCodeExpired), findsOneWidget);
    await close(tester);
  });
}

/// One poll interval and a little.
const inPersonPollEveryForTest = Duration(milliseconds: 3100);
