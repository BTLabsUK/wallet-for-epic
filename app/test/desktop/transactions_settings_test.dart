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
  addTearDown(() => NetGate.setEpicbox(true));
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

/// The sidebar's Link Payment · HTTP row.
final _railHttp = find.descendant(of: find.byKey(const ValueKey('rail')), matching: find.text('Link Payment · HTTP'));

Finder _offer(String m) => find.byKey(ValueKey('st-offer-$m'));

void main() {
  group('the page', () {
    testWidgets('Receiving became Transactions: the entry, the groups, Epicbox a switch that is on', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      expect(find.text('Transactions'), findsWidgets);
      expect(find.text('Payment methods'), findsOneWidget);
      expect(find.text('Always on'), findsNothing);
      expect(tester.widget<ESwitch>(_offer('epicbox')).value, isTrue);
      expect(_offer('direct'), findsOneWidget);
      expect(_offer('file'), findsOneWidget);
      // The existing Epicbox receiving group is on the same page, nothing is duplicated.
      expect(find.byKey(const ValueKey('st-switch-epicbox')), findsOneWidget);
      expect(find.text('Send starts on'), findsOneWidget);
    });

    testWidgets('by default File is on, Link off, and Link’s receiving rows are not shown', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      expect(tester.widget<ESwitch>(_offer('file')).value, isTrue);
      expect(tester.widget<ESwitch>(_offer('direct')).value, isFalse);
      expect(find.byKey(const ValueKey('st-switch-http')), findsNothing);
    });

    testWidgets('the Link switch saves and shows the HTTP receiving rows under the methods', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await tester.tap(_offer('direct'));
      await _settle(tester);
      expect(_payments.direct, isTrue);
      expect(find.byKey(const ValueKey('st-switch-http')), findsOneWidget);
      expect(find.text('Start with the wallet'), findsWidgets);
      await tester.tap(_offer('direct'));
      await _settle(tester);
      expect(_payments.direct, isFalse);
      expect(find.byKey(const ValueKey('st-switch-http')), findsNothing);
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

    testWidgets('the File switch saves', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await tester.tap(_offer('file'));
      await _settle(tester);
      expect(_payments.file, isFalse);
      await tester.tap(_offer('file'));
      await _settle(tester);
      expect(_payments.file, isTrue);
    });

    testWidgets('a running listener keeps the HTTP rows although Link is off', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      await tester.runAsync(() => _container.read(deskProvider.notifier).setHttp(true));
      await _settle(tester);
      expect(_payments.direct, isFalse);
      expect(find.byKey(const ValueKey('st-switch-http')), findsOneWidget);
    });
  });

  group('Send starts on', () {
    testWidgets('lists the methods that are on, and the choice saves', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving);
      final start = find.descendant(of: find.byKey(const ValueKey('st-start-method')), matching: find.byType(ESegmented<PayMethod>));
      expect(tester.widget<ESegmented<PayMethod>>(start).segments.map((s) => s.label), ['Epicbox', 'File']);
      await tester.tap(find.descendant(of: start, matching: find.text('File')));
      await _settle(tester);
      expect(_payments.defaultMethod, PayMethod.file);
      await tester.tap(_offer('direct'));
      await _settle(tester);
      expect(tester.widget<ESegmented<PayMethod>>(start).segments.map((s) => s.label), ['Epicbox', 'Link Payment', 'File']);
    });

    testWidgets('a default that is switched off falls back to Epicbox and is not offered', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, payments: const PaymentPrefs(direct: true, defaultMethod: PayMethod.direct));
      final start = find.descendant(of: find.byKey(const ValueKey('st-start-method')), matching: find.byType(ESegmented<PayMethod>));
      expect(tester.widget<ESegmented<PayMethod>>(start).value, PayMethod.direct);
      await tester.tap(_offer('direct'));
      await _settle(tester);
      expect(_payments.startMethod, PayMethod.epicbox);
      expect(tester.widget<ESegmented<PayMethod>>(start).segments.map((s) => s.label), ['Epicbox', 'File']);
      expect(tester.widget<ESegmented<PayMethod>>(start).value, PayMethod.epicbox);
    });

    testWidgets('with only Epicbox on there is nothing to choose', (tester) async {
      await _open(tester, DeskRoute.settingsReceiving, payments: const PaymentPrefs(file: false));
      expect(find.byKey(const ValueKey('st-start-method')), findsNothing);
    });

    testWidgets('Send opens on the chosen method', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(defaultMethod: PayMethod.file));
      expect(_selected<TxMethod>(tester), TxMethod.file);
    });

    testWidgets('Send opens on Link when that is the choice and Link is on', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(direct: true, defaultMethod: PayMethod.direct));
      expect(_selected<TxMethod>(tester), TxMethod.http);
    });

    testWidgets('Send opens on Epicbox when the chosen method was switched off', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(file: false, defaultMethod: PayMethod.file));
      expect(_selected<TxMethod>(tester), TxMethod.epicbox);
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

    test('the old Link receiving switch is taken over as Link on', () {
      final s = deskSettingsFromJson({
        'advanced': {'features': ['directReceiving', 'outputs'], 'networkMode': 'standard'},
      });
      expect(s.payments.direct, isTrue);
      expect(s.advanced.has(AdvancedFeature.outputs), isTrue);
      expect(deskSettingsFromJson({'advanced': {'features': ['outputs']}}).payments.direct, isFalse);
      // A saved choice wins over the old switch.
      expect(
        deskSettingsFromJson({
          'advanced': {'features': ['directReceiving']},
          'payments': {'direct': false, 'file': true, 'default': 'epicbox'},
        }).payments.direct,
        isFalse,
      );
    });
  });

  group('Send follows the switches', () {
    testWidgets('default: Epicbox and File', (tester) async {
      await _open(tester, DeskRoute.send);
      expect(_segments<TxMethod>(tester), ['Epicbox', 'File']);
    });

    testWidgets('Link appears with its switch', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(direct: true));
      expect(_segments<TxMethod>(tester), ['Epicbox', 'Link', 'File']);
    });

    testWidgets('File off: the segment is gone', (tester) async {
      await _open(tester, DeskRoute.send, payments: const PaymentPrefs(file: false));
      expect(_segments<TxMethod>(tester), ['Epicbox']);
    });

    testWidgets('a pasted onion with Link off brings Link for this send, never a refusal', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs());
      await tester.enterText(find.byType(EditableText).first, _onion);
      await _settle(tester);
      expect(_segments<TxMethod>(tester), ['Epicbox', 'Link', 'File']);
      expect(_selected<TxMethod>(tester), TxMethod.http);
      expect(_payments.direct, isFalse, reason: 'nothing was switched on');
    });

    testWidgets('a file send being made keeps File with the switch off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(method: TxMethod.file), payments: const PaymentPrefs(file: false));
      expect(_segments<TxMethod>(tester), contains('File'));
    });

    testWidgets('Epicbox off: the segment is disabled with the reason, the notice names a contact with only that address', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com', amount: '1'), payments: const PaymentPrefs(epicbox: false));
      final epicbox = tester.widget<ESegmented<TxMethod>>(find.byType(ESegmented<TxMethod>).first).segments.firstWhere((s) => s.label == 'Epicbox');
      expect(epicbox.enabled, isFalse);
      expect(epicbox.tooltip, 'Epicbox is off in Settings › Transactions.');
      expect(find.byKey(const ValueKey('send-epicbox-off')), findsOneWidget);
      expect(find.text('Anna Kowalska has only an Epicbox address.'), findsOneWidget);
    });

    testWidgets('Epicbox not connected keeps the file fallback with the switch off', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(epicboxHealth: ServiceHealth.down), payments: const PaymentPrefs(file: false));
      expect(_segments<TxMethod>(tester), contains('File'));
    });
  });

  group('Receive and the sidebar follow the switches', () {
    testWidgets('Link off: no HTTP card and no HTTP row', (tester) async {
      await _open(tester, DeskRoute.receive);
      expect(find.text('Link Payment · HTTP address'), findsNothing);
      expect(_railHttp, findsNothing);
    });

    testWidgets('Link on: the HTTP card and the HTTP row', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(direct: true));
      expect(find.text('Link Payment · HTTP address'), findsWidgets);
      expect(_railHttp, findsOneWidget);
    });

    testWidgets('a running listener keeps the card and the sidebar row with Link off', (tester) async {
      await _open(tester, DeskRoute.receive);
      await tester.runAsync(() => _container.read(deskProvider.notifier).setHttp(true));
      await _settle(tester);
      expect(_payments.direct, isFalse);
      expect(find.text('Link Payment · HTTP address'), findsWidgets);
      expect(_railHttp, findsOneWidget);
    });

    testWidgets('Epicbox off: the notice stands in the address panel\'s place', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(epicbox: false));
      expect(find.byKey(const ValueKey('rx-epicbox-off')), findsOneWidget);
      expect(find.text('Epicbox is off in Settings › Transactions.'), findsOneWidget);
      expect(find.text('Epicbox address'), findsNothing);
    });

    testWidgets('File off: the Files panel is gone', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(file: false), pendingFile: false);
      expect(find.byKey(tourKey('receive-files')), findsNothing);
    });

    testWidgets('File off but a file send waits for its response: the panel stays (Finalize)', (tester) async {
      await _open(tester, DeskRoute.receive, payments: const PaymentPrefs(file: false));
      expect(_container.read(deskProvider).pendingFiles, greaterThan(0));
      expect(find.byKey(tourKey('receive-files')), findsOneWidget);
    });

    testWidgets('File on: the panel shows with nothing waiting', (tester) async {
      await _open(tester, DeskRoute.receive, pendingFile: false);
      expect(find.byKey(tourKey('receive-files')), findsOneWidget);
    });
  });
}
