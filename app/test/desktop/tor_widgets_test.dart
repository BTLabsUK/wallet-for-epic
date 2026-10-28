// SPDX-License-Identifier: Apache-2.0
// Tor on the mock wallet: Settings › Receiving turns it on per wallet and shows its state and
// onion; Send routes an onion (a Link send) to Tor and offers Turn on Tor while it is off. Every screen spot
// is behind DeskFeatures.tor, so these run once the flag is on.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
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


  // The switch itself (Settings › Privacy) is tested in tor_switch_desk_test.dart.

  group('Send to an onion', () {
    testWidgets('Tor off: Turn on Tor, then the send goes over Tor', (tester) async {
      // Link · Tor on in Settings › Transactions, so the one thing missing is Tor itself.
      await tester.runAsync(() async {
        final n = container.read(deskProvider.notifier);
        await n.refresh();
        final s = container.read(deskProvider).settings;
        await n.saveSettings(s.copyWith(payments: s.payments.copyWith(linkTor: true)));
      });
      await show(tester, const SendScreen(arg: SendArgs(method: TxMethod.http, recipient: _onion, amount: '1')));
      // Under Link, an onion needs Tor.
      expect(find.text('Link · Tor needs Tor'), findsOneWidget);
      expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Review')).onPressed, isNull);
      await tester.tap(find.widgetWithText(EButton, 'Turn on Tor'));
      await tester.pumpAndSettle();
      expect(find.text('Link · Tor needs Tor'), findsNothing);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.text('Link · Tor (their wallet must be open)'), findsOneWidget);
      await enterReviewPassword(tester);
      await tester.tap(find.text('Send 1.0000 EPIC'));
      await tester.pumpAndSettle();
      expect(wallet.sent.single.method, TxMethod.tor);
      expect(wallet.sent.single.to, _onion);
    }, skip: _skip);

    testWidgets('an onion pasted under Epicbox switches to Link', (tester) async {
      await show(tester, const SendScreen(arg: SendArgs(amount: '1')));
      await tester.enterText(find.byType(EditableText).first, _onion);
      await tester.pumpAndSettle();
      expect(tester.widget<ESegmented<TxMethod>>(find.byType(ESegmented<TxMethod>)).value, TxMethod.http);
      // Link · Tor is off here: that comes first, before Tor (Tor alone would not send it).
      expect(find.textContaining('Link · Tor'), findsWidgets);
      expect(find.widgetWithText(EButton, 'Turn on Tor'), findsNothing);
    }, skip: _skip);
  });
}
