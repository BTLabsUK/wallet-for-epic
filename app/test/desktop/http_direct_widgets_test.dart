// SPDX-License-Identifier: Apache-2.0
// Link HTTP on the mock wallet: Send › Link asks before plain HTTP leaves this computer, and
// Settings › Receiving turns the HTTP listener on and makes it reachable only from the guide.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_http.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

import 'review_password.dart';

/// The mock wallet, recording each send.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<SendRequest> sent = [];

  @override
  Future<SendResult> send(SendRequest request) {
    sent.add(request);
    return super.send(request);
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

  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1280, 1500); // Transactions is a long page
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.runAsync(() => advancedOn(container));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> sendTo(WidgetTester tester, String to) async {
    await show(tester, SendScreen(arg: SendArgs(method: TxMethod.http, recipient: to, amount: '1')));
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
  }

  group('Send › Link HTTP', () {
    testWidgets('plain http to another computer goes straight to the review and sends', (tester) async {
      await sendTo(tester, 'http://203.0.113.5:3415');
      expect(find.text('Not encrypted. Send anyway?'), findsNothing);
      expect(find.text('Check and send'), findsOneWidget);
      await enterReviewPassword(tester);
      await tester.tap(find.text('Send 1.00000000\u00a0EPIC'));
      await tester.pumpAndSettle();
      expect(wallet.sent.single.method, TxMethod.http);
      expect(wallet.sent.single.allowPlainHttp, isTrue);
    });

    testWidgets('https and this computer go straight to the review', (tester) async {
      await sendTo(tester, 'https://wallet.example.org');
      expect(find.text('Not encrypted. Send anyway?'), findsNothing);
      expect(find.text('Check and send'), findsOneWidget);
    });

    testWidgets('host:port without a scheme is refused with a reason', (tester) async {
      await sendTo(tester, '203.0.113.5:3415');
      expect(find.text('Start with https:// or http://.'), findsOneWidget);
      expect(find.text('Check and send'), findsNothing);
    });
  });

  group('Settings › Transactions', () {
    // Link · HTTP is the one HTTP switch (Payment methods); its group below holds the state.
    Finder httpSwitch() => find.byKey(const ValueKey('st-offer-linkHttp'));
    String httpState(WidgetTester tester) => tester.widget<EStateLine>(find.byKey(const ValueKey('st-state-http'))).line.text;

    // `show` turns the Link methods on (advancedOn): Link · HTTP on means the listener runs.
    testWidgets("Link · HTTP on: the listener runs local only, its group shows the state and this computer's address with no second switch; off takes the group away", (tester) async {
      await show(tester, const SettingsReceivingScreen());
      expect(httpState(tester), 'Receiving\u00A0· this computer only (127.0.0.1)');
      expect(find.byKey(const ValueKey('st-switch-http')), findsNothing, reason: 'no second HTTP switch');
      expect(find.byKey(const ValueKey('st-autostart-http')), findsNothing);
      // This computer's address with Internet's under it (HttpAddresses), as on Receive.
      expect(find.descendant(of: find.byKey(const ValueKey('http-local')), matching: find.byType(EAddress)), findsOneWidget);
      await tester.tap(httpSwitch());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('st-state-http')), findsNothing);
      expect(container.read(deskProvider).status?.httpListener, ServiceHealth.off);
    });

    testWidgets('Internet: the guide behind its (?) changes nothing; its switch turns it on, the line says the port is not forwarded', (tester) async {
      await show(tester, const SettingsReceivingScreen());
      await tester.tap(find.byWidgetPredicate((w) => w is EIconButton && w.icon == EIcons.help));
      await tester.pumpAndSettle();
      expect(find.byType(InternetGuide), findsOneWidget);
      // Close leaves it local only.
      await tester.tap(find.widgetWithText(EButton, 'Close'));
      await tester.pumpAndSettle();
      expect(container.read(deskProvider).settings.publicMode, isFalse);

      await tester.tap(find.byKey(const ValueKey('http-public-switch')));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pumpAndSettle();
      }
      expect(find.byType(InternetGuide), findsNothing);
      expect(container.read(deskProvider).settings.publicMode, isTrue);
      expect(find.byKey(const ValueKey('http-public-note')), findsOneWidget);
      // The mock's reach check: the port is not forwarded, so no green internet claim.
      expect(find.text('Not reachable from the internet'), findsOneWidget);
      expect(httpState(tester), 'Receiving\u00A0· on this computer, not from the internet: forward port 3415');
    });

    testWidgets('a port outside 1 to 65535 is refused', (tester) async {
      await show(tester, const SettingsReceivingScreen());
      // The port's field: this computer's address above it is selectable text, not an input.
      final field = find.descendant(of: find.byType(HttpOptions), matching: find.descendant(of: find.byType(EInput), matching: find.byType(EditableText)));
      await tester.enterText(field, '70000');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Port must be 1 to 65535'), findsOneWidget);
      await tester.enterText(field, '3420');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(container.read(deskProvider).settings.httpPort, 3420);
    });

    testWidgets('the tour’s port-in-use state names the port', (tester) async {
      await show(tester, const SettingsReceivingScreen(arg: ReceivingDemo.httpFailed));
      expect(httpState(tester), contains('Port 3415 is in use by another program'));
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
