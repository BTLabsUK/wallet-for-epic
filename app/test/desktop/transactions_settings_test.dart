// Settings › Transactions on the desktop (26.10.13): the renamed page and its groups, the Link
// and File switches, the method Send starts on (limited to the methods that are on), Send's
// defaults only with Advanced › Send options, and what follows from the switches on Send,
// Receive and the sidebar, with the keep rules (a pasted onion, a pending file send, a running
// listener). Outputs holds one line instead of the defaults; Advanced no longer has Link.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
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
// The HTTP status row, in the title bar's status list (opened first).
Future<Finder> _railHttp(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('bar-status')));
  await tester.pumpAndSettle();
  return find.byKey(const ValueKey('status-row-http'));
}

Finder _offer(String m) => find.byKey(ValueKey('st-offer-$m'));

void main() {
  group('the page', () {
    testWidgets('Payment methods: one switch per method, grouped by family, Epicbox on', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      expect(find.text('Transactions'), findsWidgets);
      expect(find.text('Payment methods'), findsOneWidget);
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
      // The existing Epicbox receiving group is on the same page, nothing is duplicated.
      expect(find.byKey(const ValueKey('st-switch-epicbox')), findsOneWidget);
      expect(find.text('Send starts on'), findsOneWidget);
    });

    testWidgets('by default File Transfer is on, Link off, and Link’s receiving groups are not shown', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      expect(tester.widget<ESwitch>(_offer('directFile')).value, isTrue);
      expect(tester.widget<ESwitch>(_offer('linkHttp')).value, isFalse);
      expect(tester.widget<ESwitch>(_offer('linkTor')).value, isFalse);
      expect(find.text('Link · HTTP receiving'), findsNothing);
      expect(find.text('Link · Tor receiving'), findsNothing);
    });

    testWidgets('Offline on a public node: Link · HTTP refused stays off; Link · Tor offers no Turn on Tor (LNX-8)', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, advanced: const AdvancedPrefs(networkMode: NetworkMode.offline));
      await tester.tap(_offer('linkHttp'));
      await _settle(tester);
      expect(_payments.linkHttp, isFalse);
      expect(tester.widget<ESwitch>(_offer('linkHttp')).value, isFalse);
      expect(find.textContaining('Offline mode'), findsWidgets);
      await tester.tap(_offer('linkTor'));
      await _settle(tester);
      expect(find.byKey(const ValueKey('st-tor-needs-tor')), findsOneWidget);
      expect(find.text('Turn on Tor'), findsNothing);
      expect(find.descendant(of: find.byKey(const ValueKey('st-tor-needs-tor')), matching: find.text('Offline mode is on in Advanced.')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Link · HTTP is one switch: it saves, starts the listener and shows the HTTP group without a second switch', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await tester.tap(_offer('linkHttp'));
      await _settle(tester);
      expect(_payments.linkHttp, isTrue);
      expect(_container.read(deskProvider).status?.httpListener, ServiceHealth.ok);
      expect(find.text('Link · HTTP receiving'), findsOneWidget);
      expect(find.byKey(const ValueKey('st-switch-http')), findsNothing, reason: 'no duplicate switch for the same thing');
      expect(find.byKey(const ValueKey('st-autostart-http')), findsNothing, reason: 'on means now and at unlock');
      expect(find.byKey(const ValueKey('st-state-http')), findsOneWidget);
      expect(find.text('Reachable'), findsOneWidget);
      await tester.tap(_offer('linkHttp'));
      await _settle(tester);
      expect(_payments.linkHttp, isFalse);
      expect(_container.read(deskProvider).status?.httpListener, ServiceHealth.off);
      expect(find.text('Link · HTTP receiving'), findsNothing);
    });

    testWidgets('Link · Tor saves; with Tor off its row says what it needs, with Tor on its group shows the Tor state', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await tester.tap(_offer('linkTor'));
      await _settle(tester);
      expect(_payments.linkTor, isTrue);
      expect(find.byKey(const ValueKey('st-tor-needs-tor')), findsOneWidget);
      expect(find.text('Tor is off. Turn it on under Privacy to be paid at the Tor address.'), findsOneWidget);
      expect(find.text('Link · Tor receiving'), findsOneWidget);
      await tester.tap(find.widgetWithText(EButton, 'Turn on Tor'));
      await _settle(tester);
      expect(_container.read(deskProvider).settings.tor, isTrue);
      expect(find.byKey(const ValueKey('st-tor-needs-tor')), findsNothing);
      expect(find.byKey(const ValueKey('st-state-tor')), findsOneWidget);
      expect(find.byKey(const ValueKey('st-switch-tor')), findsNothing, reason: 'Tor itself is Privacy\'s switch');
    });

    testWidgets('the Epicbox switch saves, stops the listener, the group reads Off with the reason, and comes back on', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      expect(_container.read(deskProvider).status?.epicboxHealth, isNot(ServiceHealth.off));
      await tester.tap(_offer('epicbox'));
      await _settle(tester);
      expect(_payments.epicbox, isFalse);
      expect(NetGate.epicbox, isFalse);
      expect(_container.read(deskProvider).status?.epicboxHealth, ServiceHealth.off);
      expect(find.textContaining('Epicbox is off in Settings › Transactions.', findRichText: true), findsWidgets);
      final receiving = tester.widget<ESwitch>(find.byKey(const ValueKey('st-switch-epicbox')));
      expect(receiving.value, isFalse);
      expect(receiving.onChanged, isNull, reason: 'nothing to turn on while the method is off');
      // No confirm: nothing waited for a reply.
      expect(find.text('Turn Epicbox off?'), findsNothing);
      await tester.tap(_offer('epicbox'));
      await _settle(tester);
      expect(_payments.epicbox, isTrue);
      expect(NetGate.epicbox, isTrue);
      expect(tester.widget<ESwitch>(find.byKey(const ValueKey('st-switch-epicbox'))).onChanged, isNotNull);
    });

    testWidgets('Epicbox off while a send waits for its reply over Epicbox asks first', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, pendingEpicbox: true);
      await tester.tap(_offer('epicbox'));
      await _settle(tester);
      expect(find.text('Turn Epicbox off?'), findsOneWidget);
      expect(find.text('A payment is waiting for its reply over Epicbox. It arrives when Epicbox is on again.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(_payments.epicbox, isTrue);
      await tester.tap(_offer('epicbox'));
      await _settle(tester);
      await tester.tap(find.text('Turn off'));
      await _settle(tester);
      expect(_payments.epicbox, isFalse);
    });

    testWidgets('the File Transfer switch saves', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await tester.tap(_offer('directFile'));
      await _settle(tester);
      expect(_payments.directFile, isFalse);
      await tester.tap(_offer('directFile'));
      await _settle(tester);
      expect(_payments.directFile, isTrue);
    });

    testWidgets('the last method on stays on: the switch does not move and a toast says why', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, payments: PaymentPrefs.defaults.copyWith(directFile: false));
      expect(_payments.on, [MethodKind.epicbox]);
      await tester.tap(_offer('epicbox'));
      await _settle(tester);
      expect(_payments.epicbox, isTrue);
      expect(find.text('Keep at least one payment method on.'), findsOneWidget);
      expect(NetGate.epicbox, isTrue);
    });

    testWidgets('a listener Receive started keeps the HTTP group: it is the same switch', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await tester.runAsync(() => _container.read(deskProvider.notifier).setHttp(true));
      await _settle(tester);
      expect(_payments.linkHttp, isTrue, reason: 'Receive\'s Try again and the method switch are one setting');
      expect(tester.widget<ESwitch>(_offer('linkHttp')).value, isTrue);
      expect(find.text('Link · HTTP receiving'), findsOneWidget);
    });
  });

  group('Send starts on', () {
    testWidgets('lists the methods that are on, Link once for its family, and the choice saves', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      final start = find.descendant(of: find.byKey(const ValueKey('st-start-method')), matching: find.byType(ESegmented<MethodKind>));
      expect(tester.widget<ESegmented<MethodKind>>(start).segments.map((s) => s.label), ['Epicbox', 'Direct · File']);
      await tester.tap(find.descendant(of: start, matching: find.text('Direct · File')));
      await _settle(tester);
      expect(_payments.defaultMethod, MethodKind.directFile);
      await tester.tap(_offer('linkTor'));
      await _settle(tester);
      expect(tester.widget<ESegmented<MethodKind>>(start).segments.map((s) => s.label), ['Epicbox', 'Link', 'Direct · File']);
      await tester.tap(_offer('linkHttp'));
      await _settle(tester);
      expect(tester.widget<ESegmented<MethodKind>>(start).segments.map((s) => s.label), ['Epicbox', 'Link', 'Direct · File'], reason: 'Link once');
    });

    testWidgets('a default that is switched off falls back to Epicbox and is not offered', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, payments: const PaymentPrefs(linkHttp: true, defaultMethod: MethodKind.linkHttp));
      final start = find.descendant(of: find.byKey(const ValueKey('st-start-method')), matching: find.byType(ESegmented<MethodKind>));
      expect(tester.widget<ESegmented<MethodKind>>(start).value, MethodKind.linkHttp);
      await tester.tap(_offer('linkHttp'));
      await _settle(tester);
      expect(_payments.startMethod, MethodKind.epicbox);
      expect(tester.widget<ESegmented<MethodKind>>(start).segments.map((s) => s.label), ['Epicbox', 'Direct · File']);
      expect(tester.widget<ESegmented<MethodKind>>(start).value, MethodKind.epicbox);
    });

    testWidgets('with only Epicbox on there is nothing to choose', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, payments: const PaymentPrefs(directFile: false));
      expect(find.byKey(const ValueKey('st-start-method')), findsNothing);
    });

    testWidgets('Send opens on the chosen method', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(defaultMethod: MethodKind.directFile));
      expect(_selected<TxMethod>(tester), TxMethod.file);
    });

    testWidgets('Send opens on Link when that is the choice and a Link method is on', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(linkTor: true, defaultMethod: MethodKind.linkHttp));
      expect(_selected<TxMethod>(tester), TxMethod.http);
    });

    testWidgets('Send opens on Epicbox when the chosen method was switched off', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(directFile: false, defaultMethod: MethodKind.directFile));
      expect(_selected<TxMethod>(tester), TxMethod.epicbox);
    });

    testWidgets('Epicbox switched off while Send is open: an empty form moves to the start method (AND-4)', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(linkHttp: true));
      expect(_selected<TxMethod>(tester), TxMethod.epicbox);
      await tester.runAsync(() => _container.read(deskProvider.notifier).saveSettings(_container.read(deskProvider).settings.copyWith(payments: const PaymentPrefs(epicbox: false, linkHttp: true))));
      await _settle(tester);
      expect(_selected<TxMethod>(tester), TxMethod.http);
      expect(find.byKey(const ValueKey('send-epicbox-off')), findsNothing);
    });
  });

  group('Send defaults', () {
    testWidgets('Strategy and Split change are not shown by default', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      expect(find.byKey(const ValueKey('st-strategy')), findsNothing);
      expect(find.byKey(const ValueKey('st-split')), findsNothing);
    });

    testWidgets('Strategy and Split change show with Advanced › Send options', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, advanced: AdvancedPrefs(features: {AdvancedFeature.sendOptions}));
      expect(find.byKey(const ValueKey('st-strategy')), findsOneWidget);
      expect(find.byKey(const ValueKey('st-split')), findsOneWidget);
    });

    testWidgets('they save per wallet, as the Outputs page’s box did', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, advanced: AdvancedPrefs(features: {AdvancedFeature.sendOptions}));
      await tester.tap(find.descendant(of: find.byKey(const ValueKey('st-strategy')), matching: find.text('All')));
      await _settle(tester);
      expect(_container.read(deskOutputPrefsProvider).value!.strategy.name, 'all');
      final before = _container.read(deskOutputPrefsProvider).value!.smartOutputs;
      await tester.tap(find.descendant(of: find.byKey(const ValueKey('st-split')), matching: find.byType(ESwitch)));
      await _settle(tester);
      expect(_container.read(deskOutputPrefsProvider).value!.smartOutputs, !before);
    });

    testWidgets('linux-07: Split change says which change it splits, behind its info icon', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, advanced: AdvancedPrefs(features: {AdvancedFeature.sendOptions}));
      // The rule (smart_outputs.dart): change of at least 1 EPIC, parts of at least 0.5 EPIC.
      final hint = find.byWidgetPredicate((w) => w is EInfoHint && w.text.contains('at least 1 EPIC') && w.text.contains('0.5 EPIC'));
      expect(hint, findsOneWidget);
      expect(find.textContaining('at least 1 EPIC'), findsNothing);
    });

    testWidgets('Outputs has no defaults box and, with Send options off, no line either', (tester) async {
      await _open(tester, DeskRoute.outputs, advanced: AdvancedPrefs(features: {AdvancedFeature.outputs}));
      expect(find.text('Defaults for sends'), findsNothing);
      expect(find.text('Strategy for sends'), findsNothing);
      expect(find.byKey(const ValueKey('out-defaults-moved')), findsNothing, reason: 'Send options is off');
    });

    testWidgets('Outputs holds one line to Transactions with Send options on', (tester) async {
      await _open(tester, DeskRoute.outputs, advanced: AdvancedPrefs(features: {AdvancedFeature.outputs, AdvancedFeature.sendOptions}));
      await tester.ensureVisible(find.byKey(const ValueKey('out-defaults-moved')));
      expect(find.byKey(const ValueKey('out-defaults-moved')), findsOneWidget);
      expect(find.text('Strategy for sends'), findsNothing);
      await tester.tap(find.text('Open Transactions'));
      await _settle(tester);
      expect(find.text('Payment methods'), findsOneWidget);
      expect(find.byKey(const ValueKey('st-strategy')), findsOneWidget);
    });
  });

  group('Advanced', () {
    testWidgets('no Link switch; the others and the network modes stay', (tester) async {
      await _open(tester, DeskRoute.settingsAdvanced);
      expect(find.byKey(const ValueKey('adv-directReceiving')), findsNothing);
      expect(find.text('Link receiving'), findsNothing);
      expect(find.byKey(const ValueKey('adv-sendOptions')), findsOneWidget);
      expect(find.byKey(const ValueKey('adv-mode-offline')), findsOneWidget);
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
    });
  });

  group('Send follows the switches', () {
    testWidgets('default: Epicbox, Link (listed from the start, #16) and Direct · File', (tester) async {
      await _open(tester, DeskRoute.send);
      expect(_segments<TxMethod>(tester), ['Epicbox', 'Link', 'Direct · File']);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
    });

    testWidgets('Link picked with its switches off: the reason, and Turn on Link · HTTP turns it on here', (tester) async {
      await _open(tester, DeskRoute.send);
      await tester.tap(find.descendant(of: find.byType(ESegmented<TxMethod>), matching: find.text('Link')));
      await _settle(tester);
      expect(_selected<TxMethod>(tester), TxMethod.http);
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
      expect(find.text('Link · HTTP is off in Settings › Transactions.'), findsWidgets);
      await tester.tap(find.widgetWithText(EButton, 'Turn on Link · HTTP'));
      await _settle(tester);
      expect(_payments.linkHttp, isTrue);
      expect(_payments.linkTor, isFalse);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
      expect(_selected<TxMethod>(tester), TxMethod.http);
    });

    testWidgets('Link appears with either of its switches, named for the family', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(linkTor: true));
      expect(_segments<TxMethod>(tester), ['Epicbox', 'Link', 'Direct · File']);
    });

    testWidgets('File Transfer off: the segment is gone', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(directFile: false));
      expect(_segments<TxMethod>(tester), ['Epicbox', 'Link']);
    });

    testWidgets('a pasted onion with Link off brings Link for this send, with the reason it is off, never a silent refusal', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs());
      await tester.enterText(find.byType(EditableText).first, _onion);
      await _settle(tester);
      expect(_segments<TxMethod>(tester), ['Epicbox', 'Link', 'Direct · File']);
      expect(_selected<TxMethod>(tester), TxMethod.http);
      expect(_payments.offersFamily(MethodFamily.link), isFalse, reason: 'nothing was switched on');
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsWidgets);
    });

    testWidgets('an http address with Link · HTTP off but Link · Tor on: the reason names Link · HTTP, the contact-only line names the contact', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'https://wallet.example.org', amount: '1'), payments: const PaymentPrefs(linkTor: true));
      expect(_selected<TxMethod>(tester), TxMethod.http);
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
      expect(find.text('Link · HTTP is off in Settings › Transactions.'), findsWidgets);
      expect(find.text('Send'), findsWidgets);
    });

    testWidgets('picks by method: a contact opens Send on its address whose method is on (qa-next)', (tester) async {
      final two = Contact(id: 'c-two', name: 'Two Way', tor: _onion, http: 'https://wallet.example.org');
      await _open(tester, DeskRoute.send, arg: SendArgs(contact: two), payments: const PaymentPrefs(linkHttp: true));
      expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, 'https://wallet.example.org');
      expect(_selected<TxMethod>(tester), TxMethod.http);
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
      expect(find.text('Link · Tor is off in Settings › Transactions.'), findsWidgets);
      expect(find.textContaining('has only'), findsNothing);
    });

    testWidgets('picks by method: a code with an Epicbox and an onion address fills the one that is on (qa-next)', (tester) async {
      const anna = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';
      await _open(tester, DeskRoute.send, arg: const SendArgs(code: 'epic:$anna?method=direct&direct=$_onion'), payments: const PaymentPrefs(linkHttp: true));
      expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, anna);
      expect(_selected<TxMethod>(tester), TxMethod.epicbox);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
    });

    testWidgets('picks by method: Epicbox off, the code\'s onion with Link · Tor on (qa-next)', (tester) async {
      const anna = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';
      await _open(tester, DeskRoute.send, arg: const SendArgs(code: 'epic:$anna?direct=$_onion'), payments: const PaymentPrefs(epicbox: false, linkTor: true));
      expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, _onion.substring('http://'.length));
      expect(_selected<TxMethod>(tester), TxMethod.http);
    });

    testWidgets('LNX-1: Epicbox switched off is no failure, so File Transfer off stays off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(epicboxHealth: ServiceHealth.off), payments: const PaymentPrefs(epicbox: false, linkTor: true, directFile: false));
      expect(_segments<TxMethod>(tester), isNot(contains('Direct · File')));
      expect(_segments<TxMethod>(tester), contains('Link'));
    });

    testWidgets('LNX-1: a failed Epicbox still offers the file fallback with File Transfer off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(epicboxHealth: ServiceHealth.down), payments: const PaymentPrefs(directFile: false));
      expect(_segments<TxMethod>(tester), contains('Direct · File'));
    });

    testWidgets('LNX-1b: Link with an empty To and only Link · Tor on names no method as off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(method: TxMethod.http), payments: const PaymentPrefs(linkTor: true));
      expect(_selected<TxMethod>(tester), TxMethod.http);
      expect(find.byKey(const ValueKey('send-method-off')), findsNothing);
      expect(find.textContaining('Link · HTTP is off'), findsNothing);
      // The address decides: an http one with Link · HTTP off says so.
      await tester.enterText(find.byType(EditableText).first, 'https://wallet.example.org');
      await _settle(tester);
      expect(find.byKey(const ValueKey('send-method-off')), findsOneWidget);
    });

    testWidgets('a file send being made keeps Direct · File with the switch off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(method: TxMethod.file), payments: const PaymentPrefs(directFile: false));
      expect(_segments<TxMethod>(tester), contains('Direct · File'));
    });

    testWidgets('Epicbox off: the segment is disabled with the reason, the notice names a contact with only that address', (tester) async {
      // Mining pool payouts has only an Epicbox address (Anna has a Link · HTTP one too).
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'esZr8mQ2pVtW5kNcY7uLfB3hJd9gA4sXeR6oTnC1vK8xHwP2b@epicbox.epicnet.us', amount: '1'), payments: const PaymentPrefs(epicbox: false));
      final epicbox = tester.widget<ESegmented<TxMethod>>(find.byType(ESegmented<TxMethod>).first).segments.firstWhere((s) => s.label == 'Epicbox');
      expect(epicbox.enabled, isFalse);
      expect(epicbox.tooltip, 'Epicbox is off in Settings › Transactions.');
      expect(find.byKey(const ValueKey('send-epicbox-off')), findsOneWidget);
      expect(find.text('Mining pool payouts has only an Epicbox address.'), findsOneWidget);
    });

    testWidgets('Epicbox not connected keeps the file fallback with the switch off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(epicboxHealth: ServiceHealth.down), payments: const PaymentPrefs(directFile: false));
      expect(_segments<TxMethod>(tester), contains('Direct · File'));
    });
  });

  group('Receive and the sidebar follow the switches', () {
    testWidgets('Link · HTTP off: no HTTP card and no HTTP row', (tester) async {
      await _open(tester, DeskRoute.receive);
      expect(find.text('Link · HTTP address'), findsNothing);
      expect(await _railHttp(tester), findsNothing);
    });

    testWidgets('Link · HTTP on: the HTTP card (no switch of its own) and the HTTP row', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(linkHttp: true));
      expect(find.text('Link · HTTP address'), findsWidgets);
      expect(await _railHttp(tester), findsOneWidget);
      expect(find.byKey(const ValueKey('rx-switch-http')), findsNothing);
    });

    testWidgets('Link · Tor on with Tor off: the notice that it needs Tor, no Tor address; Turn on Tor brings the address', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(linkTor: true));
      expect(find.byKey(const ValueKey('rx-tor-off-notice')), findsOneWidget);
      expect(find.text('Link · Tor address'), findsNothing);
      await tester.tap(find.descendant(of: find.byKey(const ValueKey('rx-tor-off-notice')), matching: find.text('Turn on Tor')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('rx-tor-off-notice')), findsNothing);
      expect(find.text('Link · Tor address'), findsWidgets);
    });

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
      expect(find.text('Epicbox is off in Settings › Transactions.'), findsOneWidget);
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
