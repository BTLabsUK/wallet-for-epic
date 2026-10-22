// Tor on the mock wallet: Settings › Receiving turns it on per wallet and shows its state and
// onion; Send routes an onion to Tor and offers Turn on Tor while it is off. Every screen spot
// is behind DeskFeatures.tor, so these run once the flag is on.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'review_password.dart';

const _onion = 'http://pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion';
// testWidgets takes a bool only.
const _skip = !DeskFeatures.tor;

/// The mock wallet, recording each send; [included] false is a build without the bundle.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<SendRequest> sent = [];
  bool included = true;

  @override
  Future<SendResult> send(SendRequest request) {
    sent.add(request);
    return super.send(request);
  }

  @override
  Future<ServiceStatus> status() async {
    final s = await super.status();
    return ServiceStatus(
      node: s.node,
      nodeHealth: s.nodeHealth,
      nodeHeight: s.nodeHeight,
      epicbox: s.epicbox,
      epicboxHealth: s.epicboxHealth,
      httpListener: s.httpListener,
      tor: included ? s.tor : ServiceHealth.off,
      torCanSend: included && s.torCanSend,
      torIncluded: included,
      lastUpdate: s.lastUpdate,
    );
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
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder torSwitch() => find.byKey(const ValueKey('st-switch-tor'));
  String torState(WidgetTester tester) => tester.widget<EStateLine>(find.byKey(const ValueKey('st-state-tor'))).line.text;

  group('Settings › Receiving › Tor', () {
    testWidgets('off by default; the switch turns it on and shows the state', (tester) async {
      await show(tester, const SettingsReceivingScreen());
      expect(tester.widget<ESwitch>(torSwitch()).value, isFalse);
      await tester.ensureVisible(torSwitch());
      await tester.tap(torSwitch());
      await tester.pumpAndSettle();
      expect(container.read(deskProvider).settings.tor, isTrue);
      expect(torState(tester), 'On · reachable at the Tor address');
      expect(find.byType(EAddress), findsNothing, reason: 'the address lives on Receive');
    }, skip: _skip);

    testWidgets('without the bundle the switch is disabled and says so', (tester) async {
      wallet.included = false;
      await show(tester, const SettingsReceivingScreen());
      expect(tester.widget<ESwitch>(torSwitch()).onChanged, isNull);
      expect(torState(tester), 'Not in this build');
    }, skip: _skip);
  });

  group('Send to an onion', () {
    testWidgets('Tor off: Turn on Tor, then the send goes over Tor', (tester) async {
      await show(tester, const SendScreen(arg: SendArgs(method: TxMethod.http, recipient: _onion, amount: '1')));
      // Given under HTTP, the method follows the onion to Tor.
      expect(find.text('Tor is off'), findsOneWidget);
      expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Review send')).onPressed, isNull);
      await tester.tap(find.widgetWithText(EButton, 'Turn on Tor receiving'));
      await tester.pumpAndSettle();
      expect(find.text('Tor is off'), findsNothing);
      await tester.tap(find.text('Review send'));
      await tester.pumpAndSettle();
      expect(find.text('Tor (their wallet must be open)'), findsOneWidget);
      await enterReviewPassword(tester);
      await tester.tap(find.text('Send 1.0000 EPIC'));
      await tester.pumpAndSettle();
      expect(wallet.sent.single.method, TxMethod.tor);
      expect(wallet.sent.single.to, _onion);
    }, skip: _skip);

    testWidgets('an onion pasted under Epicbox switches to Tor', (tester) async {
      await show(tester, const SendScreen(arg: SendArgs(amount: '1')));
      await tester.enterText(find.byType(EditableText).first, _onion);
      await tester.pumpAndSettle();
      expect(find.text('Straight to their wallet, over Tor.'), findsOneWidget);
      expect(find.widgetWithText(EButton, 'Turn on Tor receiving'), findsOneWidget);
    }, skip: _skip);
  });
}
