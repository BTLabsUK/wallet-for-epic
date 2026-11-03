// SPDX-License-Identifier: Apache-2.0
// Tor on the mock wallet: Settings › Receiving turns it on per wallet and shows its state and
// onion; Send routes an onion (a Link send) to Tor and offers Turn on Tor while it is off. Every screen spot
// is behind DeskFeatures.tor, so these run once the flag is on.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'review_password.dart';

final _l = englishStrings;

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
    testWidgets('Tor switch off: the tor Link · Tor runs for payments carries the send', (tester) async {
      // Item 2: Link · Tor on starts tor for payments; nothing asks to turn the Tor switch on.
      await tester.runAsync(() async {
        final n = container.read(deskProvider.notifier);
        await n.refresh();
        final s = container.read(deskProvider).settings;
        await n.saveSettings(s.copyWith(payments: s.payments.copyWith(linkTor: true)));
      });
      await show(tester, const SendScreen(arg: SendArgs(method: TxMethod.http, recipient: _onion, amount: '1')));
      expect(find.text(_l.deskSendNeedsTor), findsNothing);
      expect(find.widgetWithText(EButton, _l.deskSendTurnOnTor), findsNothing);
      await tester.tap(find.text(_l.deskSendReview));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byKey(const ValueKey('send-review-via')), matching: find.text(_l.methodDirectTor)), findsOneWidget);
      await enterReviewPassword(tester);
      await tester.tap(find.text('Send 1.0\u00a0EPIC'));
      await tester.pumpAndSettle();
      expect(wallet.sent.single.method, TxMethod.tor);
      // The reader sends the clean form of the address, without the scheme.
      expect(wallet.sent.single.to, _onion.substring('http://'.length));
    }, skip: _skip);

    testWidgets('an onion pasted in the To field is read as a Link · Tor address', (tester) async {
      await show(tester, const SendScreen(arg: SendArgs(amount: '1')));
      await tester.enterText(find.byType(EditableText).first, _onion);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('send-route-onion')), findsOneWidget);
      // Link · Tor is off here: that comes first, before Tor (Tor alone would not send it).
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
      expect(find.widgetWithText(EButton, _l.deskSendTurnOnTor), findsNothing);
    }, skip: _skip);
  });
}
