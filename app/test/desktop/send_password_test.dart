// F6: a wallet opened with the remembered password asks the password for sends above the amount
// set in Settings › This wallet (0, the default: every send). A typed unlock asks nothing.
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

  testWidgets('a typed unlock: no password asked', (tester) async {
    await review(tester);
    expect(find.widgetWithText(EField, 'Password'), findsNothing);
    await tester.tap(sendButton());
    await tester.pumpAndSettle();
    expect(wallet.sends, 1);
    expect(wallet.checked, isEmpty);
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

  testWidgets('opened with the remembered password: a send up to the set amount asks nothing', (tester) async {
    wallet.openedRemembered = true;
    final prefs = container.read(settingsPrefsProvider);
    container.read(settingsPrefsProvider.notifier).set(prefs.copyWith(askAbove: {'legacy-mainnet': nanoPerEpic}));
    await review(tester);
    expect(find.widgetWithText(EField, 'Password'), findsNothing);
    await tester.tap(sendButton());
    await tester.pumpAndSettle();
    expect(wallet.sends, 1);
    expect(wallet.checked, isEmpty);
  });

  test('the amount is saved per wallet and comes back', () {
    const p = SettingsPrefs(askAbove: {'w1': 5 * nanoPerEpic});
    final back = SettingsPrefs.fromJson(p.toJson());
    expect(back.askAboveOf('w1'), 5 * nanoPerEpic);
    expect(back.askAboveOf('w2'), 0);
    expect(back.askAboveOf(null), 0);
  });
}
