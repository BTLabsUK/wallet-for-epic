// SPDX-License-Identifier: Apache-2.0
// Settings › Transactions on the desktop (26.10.13): the renamed page and its groups, the Link
// and File switches, the method Send starts on (limited to the methods that are on), Send's
// defaults only with Advanced › Send options, and what follows from the switches on Send,
// Receive and the sidebar, with the keep rules (a pasted onion, a pending file send, a running
// listener). Outputs holds one line instead of the defaults; Advanced no longer has Link.
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart' show ReceivingShot, deskTorPayLineKey;
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

const _onion = 'http://pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion';

/// The mock wallet; [pendingFile] false drops its file send that waits for a response, so a
/// test sees the page with no file in flight.
class _Wallet extends MockDeskWallet {
  _Wallet({this.pendingFile = true, this.pendingEpicbox = false}) : super(delay: Duration.zero);

  final bool pendingFile;

  /// Adds a send over Epicbox that still waits for the recipient's reply.
  final bool pendingEpicbox;

  @override
  Future<List<Tx>> transactions() async {
    final all = await super.transactions();
    return [
      if (pendingEpicbox)
        Tx(id: 990, slateId: 'waiting-epicbox', direction: TxDirection.sent, state: TxState.waitingRecipient, method: TxMethod.epicbox, amount: 100000000, fee: 7000000, cancellable: true, created: DateTime(2026, 10, 24), counterparty: 'Anna Kowalska'),
      ...pendingFile ? all : all.where((t) => !(t.method == TxMethod.file && t.state == TxState.waitingRecipient && !t.incoming)),
    ];
  }
}

late ProviderContainer _container;

Future<void> _open(
  WidgetTester tester,
  DeskRoute route, {
  Object? arg,
  PaymentPrefs payments = PaymentPrefs.defaults,
  AdvancedPrefs advanced = AdvancedPrefs.none,
  bool pendingFile = true,
  bool pendingEpicbox = false,
}) async {
  tester.view.physicalSize = const Size(1280, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(() => NetGate.setPayments(PaymentPrefs.defaults));
  _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Wallet(pendingFile: pendingFile, pendingEpicbox: pendingEpicbox))], retry: (_, _) => null);
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    final n = _container.read(deskProvider.notifier);
    await n.refresh();
    await n.saveSettings(_container.read(deskProvider).settings.copyWith(payments: payments, advanced: advanced, tourSeen: true));
  });
  _container.read(deskNavProvider.notifier).reset(route, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

PaymentPrefs get _payments => _container.read(deskProvider).settings.payments;

/// The sidebar's Link · HTTP row.
// The HTTP status row, in its title-bar icon's popover (opened first).
Future<Finder> _railHttp(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('bar-status-http')));
  await tester.pumpAndSettle();
  return find.byKey(const ValueKey('status-row-http'));
}

Finder _offer(String m) => find.byKey(ValueKey('st-offer-$m'));

void main() {
  group('the page', () {
    testWidgets('Payment methods: one switch per method, grouped by family, Epicbox on', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      // The page's header is the nav item's name (polish #88): the nav and the header.
      expect(find.text(_l.deskSetFrameTransactions), findsWidgets);
      expect(find.text(_l.deskSetTxMethods), findsOneWidget);
      expect(find.text(_l.txMethodsHeader), findsNothing);
      expect(find.text('Always on'), findsNothing);
      expect(tester.widget<ESwitch>(_offer('epicbox')).value, isTrue);
      // The families: Epicbox stands alone; Link and Direct carry a subhead over their methods.
      expect(find.byKey(const ValueKey('st-family-link')), findsOneWidget);
      expect(find.byKey(const ValueKey('st-family-direct')), findsOneWidget);
      expect(find.byKey(const ValueKey('st-family-epicbox')), findsNothing);
      expect(_offer('linkHttp'), findsOneWidget);
      expect(_offer('linkTor'), findsOneWidget);
      expect(_offer('directFile'), findsOneWidget);
      expect(_offer('directQr'), findsNothing, reason: 'the phone\'s method');
      // Under the family's subhead the method keeps its short word; the full name is the
      // switch's label for a screen reader.
      expect(find.descendant(of: find.byKey(const ValueKey('st-method-linkHttp')), matching: find.text(_l.methodGroupHttp)), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('st-method-directFile')), matching: find.text(_l.methodFile)), findsOneWidget);
      expect(tester.widget<ESwitch>(_offer('linkTor')).semanticLabel, _l.methodDirectTor);
      // Epicbox's receiving rows sit under its switch, nothing is duplicated.
      expect(find.byKey(const ValueKey('st-details-epicbox')), findsOneWidget);
      expect(find.byKey(const ValueKey('st-switch-epicbox')), findsOneWidget);
      expect(find.text('Epicbox receiving'), findsNothing, reason: 'no group of its own at the bottom any more');
      expect(find.text(_l.deskSetTxStart), findsOneWidget);
    }, skip: !torBuilt);

    testWidgets('by default File Transfer is on, Link off, and Link’s receiving rows are not shown', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      expect(tester.widget<ESwitch>(_offer('directFile')).value, isTrue);
      expect(tester.widget<ESwitch>(_offer('linkHttp')).value, isFalse);
      expect(tester.widget<ESwitch>(_offer('linkTor')).value, isFalse);
      expect(find.byKey(const ValueKey('st-details-linkHttp')), findsNothing);
      expect(find.byKey(const ValueKey('st-details-linkTor')), findsNothing);
      expect(find.text('Link · HTTP receiving'), findsNothing);
      expect(find.text('Link · Tor receiving'), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Node only on a public node: Link · HTTP refused stays off; Link · Tor offers no Turn on Tor (LNX-8)', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, advanced: const AdvancedPrefs(networkMode: NetworkMode.nodeOnly));
      await tester.tap(_offer('linkHttp'));
      await _settle(tester);
      expect(_payments.linkHttp, isFalse);
      expect(tester.widget<ESwitch>(_offer('linkHttp')).value, isFalse);
      expect(find.textContaining(_l.advModeNodeOnly), findsWidgets);
      // Item 2: Node only blocks Tor for payments: the switch is locked, its line says why.
      expect(tester.widget<ESwitch>(_offer('linkTor')).onChanged, isNull);
      expect(find.text('Off in Node only: only the node connects.'), findsOneWidget);
      expect(find.byKey(const ValueKey('st-tor-needs-tor')), findsNothing);
      expect(find.text(_l.deskSendTurnOnTor), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    }, skip: !torBuilt);

    testWidgets('Link · HTTP is one switch: it saves, starts the listener and shows the HTTP rows under it without a second switch', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await tester.tap(_offer('linkHttp'));
      await _settle(tester);
      expect(_payments.linkHttp, isTrue);
      expect(_container.read(deskProvider).status?.httpListener, ServiceHealth.ok);
      expect(find.byKey(const ValueKey('st-details-linkHttp')), findsOneWidget);
      // Right under the switch, before the Tor row: no scrolling to the bottom for the state.
      expect(tester.getTopLeft(find.byKey(const ValueKey('st-details-linkHttp'))).dy, greaterThan(tester.getTopLeft(find.byKey(const ValueKey('st-method-linkHttp'))).dy));
      expect(tester.getTopLeft(find.byKey(const ValueKey('st-details-linkHttp'))).dy, lessThan(tester.getTopLeft(find.byKey(const ValueKey('st-method-linkTor'))).dy));
      expect(find.byKey(const ValueKey('st-switch-http')), findsNothing, reason: 'no duplicate switch for the same thing');
      expect(find.byKey(const ValueKey('st-autostart-http')), findsNothing, reason: 'on means now and at unlock');
      expect(find.byKey(const ValueKey('st-state-http')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('st-state-http')), matching: find.textContaining(_l.deskSetRecvReceiving)), findsOneWidget);
      await tester.tap(_offer('linkHttp'));
      await _settle(tester);
      expect(_payments.linkHttp, isFalse);
      expect(_container.read(deskProvider).status?.httpListener, ServiceHealth.off);
      expect(find.byKey(const ValueKey('st-details-linkHttp')), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Link · Tor saves; no Tor-is-off card (item 2); its ⓘ says what Tor covers', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await tester.tap(_offer('linkTor'));
      await _settle(tester);
      expect(_payments.linkTor, isTrue);
      expect(find.byKey(const ValueKey('st-tor-needs-tor')), findsNothing);
      expect(find.text('Tor is off. Turn it on under Network & privacy to be paid at the Tor address.'), findsNothing);
      expect(find.byKey(const ValueKey('st-details-linkTor')), findsNothing, reason: 'the state is under the switch, no second row');
      expect(find.widgetWithText(EButton, _l.deskSendTurnOnTor), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Link · Tor runs Tor for payments alone: Receiving at the onion with Copy, the Tor switch untouched (item 2)', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await tester.tap(_offer('linkTor'));
      await _settle(tester);
      final s = _container.read(deskProvider).settings;
      expect((s.payments.linkTor, s.tor, s.torAutostart), (true, false, false), reason: 'Network & privacy\'s Tor switch stays off');
      final line = find.byKey(deskTorPayLineKey);
      expect(line, findsOneWidget);
      expect(find.descendant(of: line, matching: find.text(_l.deskTorPayReady, findRichText: true)), findsOneWidget);
      expect(find.descendant(of: line, matching: find.byType(EAddress)), findsOneWidget);
      expect(find.descendant(of: line, matching: find.bySemanticsLabel(_l.deskRecvCopyTor)), findsOneWidget);
      expect(find.descendant(of: line, matching: find.text(_l.deskTorPayRestOff)), findsOneWidget);
      expect(find.byKey(const ValueKey('st-torPay-retry')), findsNothing);
      // Off again: tor for payments stops, the line goes.
      await tester.tap(_offer('linkTor'));
      await _settle(tester);
      expect(_payments.linkTor, isFalse);
      expect(_container.read(deskProvider).settings.tor, isFalse);
      expect(find.byKey(deskTorPayLineKey), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Kill switch locks Link · Tor on with the reason; Tor stopped offers Retry', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, payments: const PaymentPrefs(linkTor: true), advanced: const AdvancedPrefs(networkMode: NetworkMode.killSwitch));
      expect(tester.widget<ESwitch>(_offer('linkTor')).value, isTrue);
      expect(tester.widget<ESwitch>(_offer('linkTor')).onChanged, isNull, reason: 'the mode decides, not the switch');
      expect(find.text(_l.netBlockKillSwitch), findsOneWidget);
      expect(find.descendant(of: find.byKey(deskTorPayLineKey), matching: find.byType(EAddress)), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    }, skip: !torBuilt);

    testWidgets('Tor for payments that did not connect: the line says so, with Retry', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, arg: ReceivingShot.torStopped, payments: const PaymentPrefs(linkTor: true));
      expect(find.text(_l.deskTorPayFailed), findsOneWidget);
      expect(find.byKey(const ValueKey('st-torPay-retry')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('st-torPay-retry')));
      await _settle(tester);
      expect(_container.read(deskProvider).settings.tor, isFalse, reason: 'Retry leaves the Tor switch alone');
    }, skip: !torBuilt);

    testWidgets('Outputs holds one line to Transactions with Send options on', (tester) async {
      await _open(tester, DeskRoute.outputs, advanced: AdvancedPrefs(features: {AdvancedFeature.outputs, AdvancedFeature.sendOptions}));
      await tester.ensureVisible(find.byKey(const ValueKey('out-defaults-moved')));
      expect(find.byKey(const ValueKey('out-defaults-moved')), findsOneWidget);
      expect(find.text(_l.deskOutStrategyTitle), findsNothing);
      await tester.tap(find.text(_l.deskOutDefaultsOpen));
      await _settle(tester);
      expect(find.text(_l.deskSetFrameTransactions), findsWidgets);
      expect(find.byKey(const ValueKey('st-strategy')), findsOneWidget);
    });
  });

  group('Advanced', () {
    testWidgets('no Link switch and no network mode (on Network & privacy); the others stay', (tester) async {
      await _open(tester, DeskRoute.settingsAdvanced);
      expect(find.byKey(const ValueKey('adv-directReceiving')), findsNothing);
      expect(find.text('Link receiving'), findsNothing);
      expect(find.byKey(const ValueKey('adv-sendOptions')), findsOneWidget);
      expect(find.byKey(const ValueKey('adv-mode-nodeOnly')), findsNothing);
      expect(find.byKey(const ValueKey('adv-nodeFailover')), findsNothing);
    });

    test('the old Link receiving switch is taken over as Link · HTTP and Link · Tor on', () {
      final s = deskSettingsFromJson({
        'advanced': {'features': ['directReceiving', 'outputs'], 'networkMode': 'standard'},
      });
      expect((s.payments.linkHttp, s.payments.linkTor), (true, true));
      expect(s.advanced.has(AdvancedFeature.outputs), isTrue);
      expect(deskSettingsFromJson({'advanced': {'features': ['outputs']}}).payments.offersFamily(MethodFamily.link), isFalse);
      // A saved choice wins over the old switch.
      expect(
        deskSettingsFromJson({
          'advanced': {'features': ['directReceiving']},
          'payments': {'direct': false, 'file': true, 'default': 'epicbox'},
        }).payments.offersFamily(MethodFamily.link),
        isFalse,
      );
    }, skip: torBuilt ? null : 'no Tor in this build');
  });

  group('Send follows the switches', () {
    // The address in To decides the method (08897d39a): the method line names it, and a switch
    // that is off holds the send with its reason.
    String routeHost(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('send-route-host'))).textSpan!.toPlainText();

    testWidgets('default: no address, nothing named as off', (tester) async {
      await _open(tester, DeskRoute.send);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
      expect(find.byKey(const ValueKey('send-epicbox-off')), findsNothing);
      expect(find.byKey(const ValueKey('send-route-host')), findsNothing);
    });

    testWidgets('an onion with Link · Tor off: the reason, and Turn on Link · Tor turns it on here', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs());
      await tester.enterText(find.byType(EditableText).first, _onion);
      await _settle(tester);
      expect(_payments.offersFamily(MethodFamily.link), isFalse, reason: 'nothing was switched on');
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsWidgets);
      await tester.tap(find.widgetWithText(EButton, 'Turn on Link · Tor'));
      await _settle(tester);
      expect(_payments.linkTor, isTrue);
      expect(_payments.linkHttp, isFalse);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
    }, skip: !torBuilt);

    testWidgets('Link · Tor on: an onion is not held by a switch', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: _onion, amount: '1'), payments: const PaymentPrefs(linkTor: true));
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
      expect(find.byKey(const ValueKey('send-route-host')), findsOneWidget);
    }, skip: !torBuilt);

    testWidgets('an http address is never held by Link · HTTP, the listener\'s own switch', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'https://wallet.example.org', amount: '1'));
      expect(_payments.linkHttp, isFalse);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
      expect(routeHost(tester), startsWith('https://wallet.example.org'));
    });

    testWidgets('picks by method: a contact opens Send on its address whose method is on (qa-next)', (tester) async {
      final two = Contact(id: 'c-two', name: 'Two Way', tor: _onion, http: 'https://wallet.example.org');
      await _open(tester, DeskRoute.send, arg: SendArgs(contact: two), payments: const PaymentPrefs(linkHttp: true));
      expect(routeHost(tester), startsWith('https://wallet.example.org'));
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
    });

    testWidgets('a pasted onion of a contact with another address stays, with the reason Link · Tor is off, without "only" (qa-next)', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(linkHttp: true));
      await tester.runAsync(() => _container.read(deskProvider.notifier).saveContact(Contact(id: '', name: 'Two Way', tor: _onion, http: 'https://wallet.example.org')));
      await tester.enterText(find.byType(EditableText).first, _onion);
      await _settle(tester);
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsWidgets);
      expect(find.textContaining('has only'), findsNothing);
    }, skip: !torBuilt);

    testWidgets('picks by method: a code with an Epicbox and an onion address fills the Epicbox (qa-next)', (tester) async {
      const anna = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@box.epic.invalid';
      await _open(tester, DeskRoute.send, arg: const SendArgs(code: 'epic:$anna?method=direct&direct=$_onion'), payments: const PaymentPrefs(linkHttp: true));
      expect(routeHost(tester), 'box.epic.invalid');
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
    });

    testWidgets('picks by method: Epicbox off, the code\'s onion with Link · Tor on (qa-next)', (tester) async {
      const anna = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@box.epic.invalid';
      await _open(tester, DeskRoute.send, arg: const SendArgs(code: 'epic:$anna?direct=$_onion'), payments: const PaymentPrefs(epicbox: false, linkTor: true));
      expect(routeHost(tester), contains(_onion.substring('http://'.length)));
    }, skip: !torBuilt);

    testWidgets('LNX-1b: Link with an empty To and only Link · Tor on names no method as off', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(linkTor: true));
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
      expect(find.textContaining('Link · HTTP is off'), findsNothing);
      // An http address needs no switch (the listener's own).
      await tester.enterText(find.byType(EditableText).first, 'https://wallet.example.org');
      await _settle(tester);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
    }, skip: !torBuilt);

    testWidgets('a file send being made (Pay with a file) is never held by File Transfer\'s switch', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(method: TxMethod.file), payments: const PaymentPrefs(directFile: false));
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
      expect(find.byKey(const ValueKey('send-net-blocked')), findsNothing);
    });

    testWidgets('Epicbox off: an Epicbox address is held with the reason, the notice names a contact with only that address', (tester) async {
      // Mining pool payouts has only an Epicbox address (Anna has a Link · HTTP one too).
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'esZr8mQ2pVtW5kNcY7uLfB3hJd9gA4sXeR6oTnC1vK8xHwP2b@box.net.invalid', amount: '1'), payments: const PaymentPrefs(epicbox: false));
      expect(find.byKey(const ValueKey('send-epicbox-off')), findsOneWidget);
      expect(find.text(_l.netBlockEpicboxOff), findsWidgets);
      expect(find.text('Mining pool payouts has only an Epicbox address.'), findsOneWidget);
    });
  });

  group('Receive and the sidebar follow the switches', () {
    testWidgets('Link · HTTP off: the HTTP card is one line with its own switch; the HTTP row stays, reading Off', (tester) async {
      await _open(tester, DeskRoute.receive);
      expect(find.text(_l.deskRecvHttpAddress), findsWidgets);
      expect(find.byKey(const ValueKey('rx-switch-http')), findsOneWidget);
      expect(tester.widget<ESwitch>(find.byKey(const ValueKey('rx-switch-http'))).value, isFalse);
      final row = await _railHttp(tester);
      expect(row, findsOneWidget);
      expect(find.descendant(of: row, matching: find.text(_l.deskKitMethodOff)), findsOneWidget);
    });

    testWidgets('Link · HTTP on: the HTTP card (no switch of its own) and the HTTP row', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(linkHttp: true));
      expect(find.text(_l.deskRecvHttpAddress), findsWidgets);
      expect(await _railHttp(tester), findsOneWidget);
      expect(find.byKey(const ValueKey('rx-switch-http')), findsNothing);
    });

    testWidgets('Link · Tor on with Tor off: tor for payments brings the Tor address, no Tor-off notice', (tester) async {
      // Item 2: Link · Tor starts tor for payments by itself; the Tor switch stays off.
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(linkTor: true));
      expect(find.byKey(const ValueKey('rx-tor-off-notice')), findsNothing);
      expect(find.text(_l.deskRecvDirectTor), findsWidgets);
      expect(_container.read(deskProvider).settings.tor, isFalse);
    }, skip: !torBuilt);

    testWidgets('Tor on with Link · Tor off: no Tor address on Receive', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(linkHttp: true));
      await tester.runAsync(() => _container.read(deskProvider.notifier).setTor(true));
      await _settle(tester);
      expect(find.text('Link · Tor address'), findsNothing);
      expect(find.byKey(const ValueKey('rx-tor-off-notice')), findsNothing);
    });

    testWidgets('Epicbox off: the notice stands in the address panel\'s place', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(epicbox: false));
      expect(find.byKey(const ValueKey('rx-epicbox-off')), findsOneWidget);
      expect(find.text(_l.netBlockEpicboxOff), findsOneWidget);
      expect(find.text(_l.deskRecvEpicboxAddress), findsNothing);
    });

    testWidgets('File Transfer off: the Files panel is gone', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(directFile: false), pendingFile: false);
      expect(find.byKey(tourKey('receive-files')), findsNothing);
    });

    testWidgets('File Transfer off but a file send waits for its response: the panel stays (Finalize)', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(directFile: false));
      expect(_container.read(deskProvider).pendingFiles, greaterThan(0));
      expect(find.byKey(tourKey('receive-files')), findsOneWidget);
    });

    testWidgets('File Transfer on: the panel shows with nothing waiting', (tester) async {
      await _open(tester, DeskRoute.receive, pendingFile: false);
      expect(find.byKey(tourKey('receive-files')), findsOneWidget);
    });
  });
}
