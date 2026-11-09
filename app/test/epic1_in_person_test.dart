// SPDX-License-Identifier: Apache-2.0
// epic1 in person on the phone (spec D5, P3, P5, P6): a request code answered and checked
// (Matches, Different), a send code answered by paste, a scanned send code received, two
// phones with the same check code, and an expired code. The wallet is FakeEpic1.
import 'dart:convert';

import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/in_person/in_person_entry.dart';
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

  testWidgets('pay: the PIN, the send code, the answer pasted back, Matches: Sent', (tester) async {
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
    expect(find.text(_l.deskIpWaiting), findsOneWidget);
    expect(find.text(_l.qrShow), findsOneWidget);
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
