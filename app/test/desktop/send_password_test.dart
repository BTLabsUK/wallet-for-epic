// SPDX-License-Identifier: Apache-2.0
// Every send asks the wallet's password at Review, whether the wallet was opened with a typed
// password or with the one remembered on this computer; there is no amount below which it does
// not ask.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  int sends = 0;
  final List<String> checked = [];

  @override
  Future<SendResult> send(SendRequest request) {
    sends++;
    return super.send(request);
  }

  @override
  Future<bool> checkPassword(String password) {
    checked.add(password);
    return super.checkPassword(password);
  }
}

void main() {
  late _Wallet wallet;
  late ProviderContainer container;

  setUp(() {
    wallet = _Wallet();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
  });

  tearDown(() => container.dispose());

  Future<void> review(WidgetTester tester, {String amount = '1'}) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(
            body: SendScreen(
              arg: SendArgs(step: SendStep.review, recipient: 'esXyz1234567890abcdefghijk@epicbox.epiccash.com', amount: amount, epicboxHealth: ServiceHealth.ok),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Check and send'), findsOneWidget);
  }

  Finder sendButton() => find.widgetWithText(EButton, 'Send 1.0000 EPIC');
  Finder password() => find.descendant(of: find.widgetWithText(EField, 'Password'), matching: find.byType(TextField));

  testWidgets('a typed unlock: the send asks the password too', (tester) async {
    await review(tester);
    expect(password(), findsOneWidget);
    // windows-03: this wallet was not opened with the remembered password; the help says so.
    expect(find.textContaining('remembered'), findsNothing);
    expect(find.text('Every send asks the wallet’s password.'), findsOneWidget);
    expect(tester.widget<EButton>(sendButton()).onPressed, isNull);
    await tester.enterText(password(), 'secret-pass');
    await tester.pump();
    await tester.tap(sendButton());
    await tester.pumpAndSettle();
    expect(wallet.checked, ['secret-pass']);
    expect(wallet.sends, 1);
  });

  testWidgets('opened with the remembered password: every send asks; Enter sends only when filled', (tester) async {
    wallet.openedRemembered = true;
    await review(tester);
    expect(password(), findsOneWidget);
    expect(tester.widget<EButton>(sendButton()).onPressed, isNull);
    // Enter in the empty field sends nothing.
    await tester.showKeyboard(password());
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(wallet.checked, isEmpty);
    expect(wallet.sends, 0);

    await tester.enterText(password(), 'wrong');
    await tester.pump();
    await tester.tap(sendButton());
    await tester.pumpAndSettle();
    expect(find.text('Wrong password.'), findsOneWidget);
    expect(find.text('Check and send'), findsOneWidget);
    expect(wallet.sends, 0);

    await tester.enterText(password(), 'secret-pass');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(wallet.checked, ['wrong', 'secret-pass']);
    expect(wallet.sends, 1);
    expect(find.text('Check and send'), findsNothing);
  });

  testWidgets('remembered on this computer, a small send still asks the password', (tester) async {
    wallet.openedRemembered = true;
    // Saved by an earlier build: "Ask password above" 5 EPIC for this wallet.
    container.read(settingsPrefsProvider.notifier).set(SettingsPrefs.fromJson({'askAbove': {'legacy-mainnet': 5 * nanoPerEpic}}));
    await review(tester, amount: '1');
    expect(password(), findsOneWidget);
    await tester.tap(sendButton());
    await tester.pumpAndSettle();
    expect(wallet.sends, 0);
    expect(find.text('Check and send'), findsOneWidget);
    await tester.enterText(password(), 'secret-pass');
    await tester.pump();
    await tester.tap(sendButton());
    await tester.pumpAndSettle();
    expect(wallet.checked, ['secret-pass']);
    expect(wallet.sends, 1);
  });

  // android-15: a payment file locks the coins it pays, so it asks the password as every
  // other send does.
  testWidgets('a payment file asks the password before it is made', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: const Scaffold(body: SendScreen(arg: SendArgs(step: SendStep.review, method: TxMethod.file, amount: '1'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Check and send'), findsOneWidget);
    expect(password(), findsOneWidget);
    expect(tester.widget<EButton>(sendButton()).onPressed, isNull);
    await tester.enterText(password(), 'secret-pass');
    await tester.pump();
    await tester.tap(sendButton());
    await tester.pumpAndSettle();
    expect(wallet.checked, ['secret-pass']);
    expect(wallet.sends, 1);
  });

  test("an older 'askAbove' amount is ignored and dropped at the next save", () {
    final p = SettingsPrefs.fromJson({'askAbove': {'w1': 5 * nanoPerEpic}, 'walletLabel': 'Main'});
    expect(p.walletLabel, 'Main');
    expect(p.toJson().containsKey('askAbove'), isFalse);
  });
}
