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
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart' show ReceivingDemo, deskTorPayLineKey;
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

List<String> _segments<T>(WidgetTester tester) => tester.widget<ESegmented<T>>(find.byType(ESegmented<T>).first).segments.map((s) => s.label).toList();

T _selected<T>(WidgetTester tester) => tester.widget<ESegmented<T>>(find.byType(ESegmented<T>).first).value;

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
      expect(find.text('Payments'), findsWidgets);
      expect(find.text('Methods'), findsOneWidget);
      expect(find.text('Payment methods'), findsNothing);
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
      expect(find.descendant(of: find.byKey(const ValueKey('st-method-linkHttp')), matching: find.text('HTTP')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('st-method-directFile')), matching: find.text('File Transfer')), findsOneWidget);
      expect(tester.widget<ESwitch>(_offer('linkTor')).semanticLabel, 'Link · Tor');
      // Epicbox's receiving rows sit under its switch, nothing is duplicated.
      expect(find.byKey(const ValueKey('st-details-epicbox')), findsOneWidget);
      expect(find.byKey(const ValueKey('st-switch-epicbox')), findsOneWidget);
      expect(find.text('Epicbox receiving'), findsNothing, reason: 'no group of its own at the bottom any more');
      expect(find.text('Default method'), findsOneWidget);
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
      expect(find.textContaining('Node only'), findsWidgets);
      // Item 2: Node only blocks Tor for payments: the switch is locked, its line says why.
      expect(tester.widget<ESwitch>(_offer('linkTor')).onChanged, isNull);
      expect(find.text('Off in Node only: only the node connects.'), findsOneWidget);
      expect(find.byKey(const ValueKey('st-tor-needs-tor')), findsNothing);
      expect(find.text('Turn on Tor'), findsNothing);
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
      expect(find.text('Reachable'), findsOneWidget);
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
      expect(find.widgetWithText(EButton, 'Turn on Tor'), findsNothing);
    });

    testWidgets('Link · Tor runs Tor for payments alone: Receiving at the onion with Copy, the Tor switch untouched (item 2)', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await tester.tap(_offer('linkTor'));
      await _settle(tester);
      final s = _container.read(deskProvider).settings;
      expect((s.payments.linkTor, s.tor, s.torAutostart), (true, false, false), reason: 'Network & privacy\'s Tor switch stays off');
      final line = find.byKey(deskTorPayLineKey);
      expect(line, findsOneWidget);
      expect(find.descendant(of: line, matching: find.text('Receiving', findRichText: true)), findsOneWidget);
      expect(find.descendant(of: line, matching: find.byType(EAddress)), findsOneWidget);
      expect(find.descendant(of: line, matching: find.bySemanticsLabel('Copy Tor address')), findsOneWidget);
      expect(find.descendant(of: line, matching: find.text('Tor for every connection: off (Network & privacy).')), findsOneWidget);
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
      expect(find.text('Off in Kill switch: nothing connects.'), findsOneWidget);
      expect(find.descendant(of: find.byKey(deskTorPayLineKey), matching: find.byType(EAddress)), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    }, skip: !torBuilt);

    testWidgets('Tor for payments that did not connect: the line says so, with Retry', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, arg: ReceivingDemo.torStopped, payments: const PaymentPrefs(linkTor: true));
      expect(find.text('Tor did not connect.'), findsOneWidget);
      expect(find.byKey(const ValueKey('st-torPay-retry')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('st-torPay-retry')));
      await _settle(tester);
      expect(_container.read(deskProvider).settings.tor, isFalse, reason: 'Retry leaves the Tor switch alone');
    }, skip: !torBuilt);

    testWidgets('Outputs holds one line to Payments with Send options on', (tester) async {
      await _open(tester, DeskRoute.outputs, advanced: AdvancedPrefs(features: {AdvancedFeature.outputs, AdvancedFeature.sendOptions}));
      await tester.ensureVisible(find.byKey(const ValueKey('out-defaults-moved')));
      expect(find.byKey(const ValueKey('out-defaults-moved')), findsOneWidget);
      expect(find.text('Strategy for sends'), findsNothing);
      await tester.tap(find.text('Open Payments'));
      await _settle(tester);
      expect(find.text('Payments'), findsWidgets);
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
    testWidgets('default: Epicbox, Link (listed from the start) and Direct · File', (tester) async {
      await _open(tester, DeskRoute.send);
      expect(_segments<TxMethod?>(tester), ['Epicbox', 'Link', 'Direct · File']);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
    });

    testWidgets('Link picked with its switches off: the reason, and Turn on Link · HTTP turns it on here', (tester) async {
      await _open(tester, DeskRoute.send);
      await tester.tap(find.descendant(of: find.byType(ESegmented<TxMethod?>), matching: find.text('Link')));
      await _settle(tester);
      expect(_selected<TxMethod?>(tester), TxMethod.http);
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
      expect(find.text('Link · HTTP is off in Settings\u00a0›\u00a0Transactions.'), findsWidgets);
      await tester.tap(find.widgetWithText(EButton, 'Turn on Link · HTTP'));
      await _settle(tester);
      expect(_payments.linkHttp, isTrue);
      expect(_payments.linkTor, isFalse);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
      expect(_selected<TxMethod?>(tester), TxMethod.http);
    });

    testWidgets('Link appears with either of its switches, named for the family', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(linkTor: true));
      expect(_segments<TxMethod?>(tester), ['Epicbox', 'Link', 'Direct · File']);
    });

    testWidgets('File Transfer off: the segment is gone', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(directFile: false));
      expect(_segments<TxMethod?>(tester), ['Epicbox', 'Link']);
    });

    testWidgets('a pasted onion with Link off brings Link for this send, with the reason it is off, never a silent refusal', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs());
      await tester.enterText(find.byType(EditableText).first, _onion);
      await _settle(tester);
      expect(_segments<TxMethod?>(tester), ['Epicbox', 'Link', 'Direct · File']);
      expect(_selected<TxMethod?>(tester), TxMethod.http);
      expect(_payments.offersFamily(MethodFamily.link), isFalse, reason: 'nothing was switched on');
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
      expect(find.text('Link · Tor is off in Settings\u00a0›\u00a0Transactions.'), findsWidgets);
    }, skip: !torBuilt);

    testWidgets('an http address with Link · HTTP off but Link · Tor on: the reason names Link · HTTP, the contact-only line names the contact', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'https://wallet.example.org', amount: '1'), payments: const PaymentPrefs(linkTor: true));
      expect(_selected<TxMethod?>(tester), TxMethod.http);
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
      expect(find.text('Link · HTTP is off in Settings\u00a0›\u00a0Transactions.'), findsWidgets);
      expect(find.text('Send'), findsWidgets);
    });

    testWidgets('picks by method: a contact opens Send on its address whose method is on (qa-next)', (tester) async {
      final two = Contact(id: 'c-two', name: 'Two Way', tor: _onion, http: 'https://wallet.example.org');
      await _open(tester, DeskRoute.send, arg: SendArgs(contact: two), payments: const PaymentPrefs(linkHttp: true));
      expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, 'https://wallet.example.org');
      expect(_selected<TxMethod?>(tester), TxMethod.http);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
      // LNX-9: the card under To names the address in To and its kind, not the contact's first.
      await tester.runAsync(() => _container.read(deskProvider.notifier).saveContact(Contact(id: '', name: 'Two Way', tor: _onion, http: 'https://wallet.example.org')));
      await _settle(tester);
      final kind = find.descendant(of: find.byKey(const ValueKey('send-picked')), matching: find.byType(EKindTag));
      expect(tester.widget<EKindTag>(kind).kind, AddressKind.http);
    });

    testWidgets('a pasted onion of a contact with another address stays, without "only" (qa-next)', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(linkHttp: true));
      await tester.runAsync(() => _container.read(deskProvider.notifier).saveContact(Contact(id: '', name: 'Two Way', tor: _onion, http: 'https://wallet.example.org')));
      await tester.enterText(find.byType(EditableText).first, _onion);
      await _settle(tester);
      expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, _onion);
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
      expect(find.text('Link · Tor is off in Settings\u00a0›\u00a0Transactions.'), findsWidgets);
      expect(find.textContaining('has only'), findsNothing);
    }, skip: !torBuilt);

    testWidgets('picks by method: a code with an Epicbox and an onion address fills the one that is on (qa-next)', (tester) async {
      const anna = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@box.epic.invalid';
      await _open(tester, DeskRoute.send, arg: const SendArgs(code: 'epic:$anna?method=direct&direct=$_onion'), payments: const PaymentPrefs(linkHttp: true));
      expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, anna);
      expect(_selected<TxMethod?>(tester), TxMethod.epicbox);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
    });

    testWidgets('picks by method: Epicbox off, the code\'s onion with Link · Tor on (qa-next)', (tester) async {
      const anna = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@box.epic.invalid';
      await _open(tester, DeskRoute.send, arg: const SendArgs(code: 'epic:$anna?direct=$_onion'), payments: const PaymentPrefs(epicbox: false, linkTor: true));
      expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, _onion.substring('http://'.length));
      expect(_selected<TxMethod?>(tester), TxMethod.http);
    }, skip: !torBuilt);

    testWidgets('LNX-1: Epicbox switched off is no failure, so File Transfer off stays off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(epicboxHealth: ServiceHealth.off), payments: const PaymentPrefs(epicbox: false, linkTor: true, directFile: false));
      expect(_segments<TxMethod?>(tester), isNot(contains('Direct · File')));
      expect(_segments<TxMethod?>(tester), contains('Link'));
    });

    testWidgets('LNX-1: a failed Epicbox still offers the file fallback with File Transfer off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(epicboxHealth: ServiceHealth.down), payments: const PaymentPrefs(directFile: false));
      expect(_segments<TxMethod?>(tester), contains('Direct · File'));
    });

    testWidgets('LNX-1b: Link with an empty To and only Link · Tor on names no method as off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(method: TxMethod.http), payments: const PaymentPrefs(linkTor: true));
      expect(_selected<TxMethod?>(tester), TxMethod.http);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
      expect(find.textContaining('Link · HTTP is off'), findsNothing);
      // The address decides: an http one with Link · HTTP off says so.
      await tester.enterText(find.byType(EditableText).first, 'https://wallet.example.org');
      await _settle(tester);
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
    }, skip: !torBuilt);

    testWidgets('a file send being made keeps Direct · File with the switch off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(method: TxMethod.file), payments: const PaymentPrefs(directFile: false));
      expect(_segments<TxMethod?>(tester), contains('Direct · File'));
    });

    testWidgets('Epicbox off: the segment is disabled with the reason, the notice names a contact with only that address', (tester) async {
      // Mining pool payouts has only an Epicbox address (Anna has a Link · HTTP one too).
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'esZr8mQ2pVtW5kNcY7uLfB3hJd9gA4sXeR6oTnC1vK8xHwP2b@box.net.invalid', amount: '1'), payments: const PaymentPrefs(epicbox: false));
      final epicbox = tester.widget<ESegmented<TxMethod?>>(find.byType(ESegmented<TxMethod?>).first).segments.firstWhere((s) => s.label == 'Epicbox');
      expect(epicbox.enabled, isFalse);
      expect(epicbox.tooltip, 'Epicbox is off in Settings\u00a0›\u00a0Transactions.');
      expect(find.byKey(const ValueKey('send-epicbox-off')), findsOneWidget);
      expect(find.text('Mining pool payouts has only an Epicbox address.'), findsOneWidget);
    });

    testWidgets('Epicbox not connected keeps the file fallback with the switch off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(epicboxHealth: ServiceHealth.down), payments: const PaymentPrefs(directFile: false));
      expect(_segments<TxMethod?>(tester), contains('Direct · File'));
    });
  });

  group('Receive and the sidebar follow the switches', () {
    testWidgets('Link · HTTP off: no HTTP card; the HTTP row stays, reading Off', (tester) async {
      await _open(tester, DeskRoute.receive);
      expect(find.text('Link · HTTP address'), findsNothing);
      final row = await _railHttp(tester);
      expect(row, findsOneWidget);
      expect(find.descendant(of: row, matching: find.text('Off')), findsOneWidget);
    });

    testWidgets('Link · HTTP on: the HTTP card (no switch of its own) and the HTTP row', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(linkHttp: true));
      expect(find.text('Link · HTTP address'), findsWidgets);
      expect(await _railHttp(tester), findsOneWidget);
      expect(find.byKey(const ValueKey('rx-switch-http')), findsNothing);
    });

    testWidgets('Link · Tor on with Tor off: tor for payments brings the Tor address, no Tor-off notice', (tester) async {
      // Item 2: Link · Tor starts tor for payments by itself; the Tor switch stays off.
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(linkTor: true));
      expect(find.byKey(const ValueKey('rx-tor-off-notice')), findsNothing);
      expect(find.text('Link · Tor address'), findsWidgets);
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
      expect(find.text('Epicbox is off in Settings\u00a0›\u00a0Transactions.'), findsOneWidget);
      expect(find.text('Epicbox address'), findsNothing);
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
