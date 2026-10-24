// Advanced on the desktop: the More link on a transaction, the locked and the disabled Tor
// switch, the sidebar and Overview in Offline and Tor only, Send and Receive held by the network
// mode (File goes on), a pasted onion with Link off, Restore's start height for everyone, and
// the tour's Advanced step.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/net_mode_view.dart' show deskOfflinePeersProvider;
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _onion = 'http://pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion';

late MockDeskWallet _wallet;
late ProviderContainer _container;

Future<void> _open(
  WidgetTester tester,
  DeskRoute route, {
  Object? arg,
  AdvancedPrefs advanced = AdvancedPrefs.none,
  bool tor = false,
  String? node,
  int? peers,
}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _wallet = MockDeskWallet(delay: Duration.zero);
  _container = ProviderContainer(
    overrides: [deskApiProvider.overrideWithValue(_wallet), deskOfflinePeersProvider.overrideWith((ref) async => peers)],
    retry: (_, _) => null,
  );
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    if (tor) await _wallet.setTor(true);
    if (node != null) {
      await _wallet.addNode(NodeServer(url: node, label: 'LAN node', health: ServiceHealth.ok, own: true));
      await _wallet.useNode(node);
    }
    final n = _container.read(deskProvider.notifier);
    await n.refresh();
    await n.saveSettings(_container.read(deskProvider).settings.copyWith(advanced: advanced, tor: tor, tourSeen: true));
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

AdvancedPrefs get _advanced => _container.read(deskProvider).settings.advanced;

const _offline = AdvancedPrefs(networkMode: NetworkMode.offline);
const _torOnly = AdvancedPrefs(networkMode: NetworkMode.torOnly);

void main() {
  group('transaction details', () {
    testWidgets('Technical details off: a More link shows the rows for this view only', (tester) async {
      await _open(tester, DeskRoute.activity, arg: 36);
      expect(find.text('Kernel'), findsNothing);
      expect(find.byKey(const ValueKey('tx-more')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tx-more')));
      await _settle(tester);
      expect(find.text('Kernel'), findsOneWidget);
      expect(find.text('Slate id'), findsOneWidget);
      expect(find.text('Status'), findsWidgets);
      expect(find.text('Less'), findsOneWidget);
      expect(_advanced.has(AdvancedFeature.technicalDetails), isFalse, reason: 'the switch stays off');
      await tester.tap(find.byKey(const ValueKey('tx-more')));
      await _settle(tester);
      expect(find.text('Kernel'), findsNothing);
    });

    testWidgets('Technical details on: the fold, no More link', (tester) async {
      await _open(tester, DeskRoute.activity, arg: 36, advanced: AdvancedPrefs.all);
      expect(find.byKey(const ValueKey('tx-more')), findsNothing);
      expect(find.text('Technical details'), findsWidgets);
    });
  });

  group('Settings › Privacy', () {
    ESwitch torSwitch(WidgetTester tester) => tester.widget<ESwitch>(find.byKey(const ValueKey('privacy-tor-switch')));

    testWidgets('Standard: the switch is the user’s', (tester) async {
      await _open(tester, DeskRoute.settingsPrivacy);
      expect(torSwitch(tester).onChanged, isNotNull);
      expect(find.byKey(const ValueKey('privacy-mode-line')), findsNothing);
    });

    testWidgets('Tor only: on and locked, with a link to Advanced', (tester) async {
      await _open(tester, DeskRoute.settingsPrivacy, advanced: _torOnly);
      expect(torSwitch(tester).value, isTrue);
      expect(torSwitch(tester).onChanged, isNull);
      expect(find.text('Tor only is on in Advanced.'), findsOneWidget);
      await tester.tap(find.text('Open Advanced'));
      await _settle(tester);
      expect(_container.read(deskNavProvider).route, DeskRoute.settingsAdvanced);
    });

    testWidgets('Offline: disabled, with the reason', (tester) async {
      await _open(tester, DeskRoute.settingsPrivacy, advanced: _offline);
      expect(torSwitch(tester).onChanged, isNull);
      expect(torSwitch(tester).value, isFalse);
      expect(find.text('Offline mode is on in Advanced.'), findsOneWidget);
    });
  });

  group('sidebar and Overview', () {
    testWidgets('Offline: the rows read Offline, Overview marks the balance', (tester) async {
      await _open(tester, DeskRoute.overview, advanced: _offline);
      expect(find.text('Offline'), findsWidgets);
      expect(find.byKey(const ValueKey('overview-offline')), findsOneWidget);
      expect(find.text('Available to spend'), findsOneWidget, reason: 'the last known balance stays');
    });

    testWidgets('Tor only without Tor: Node and Epicbox read Waiting for Tor', (tester) async {
      await _open(tester, DeskRoute.overview, advanced: _torOnly);
      final rail = find.byKey(const ValueKey('rail'));
      expect(find.descendant(of: rail, matching: find.text('Epicbox')), findsOneWidget);
      // The word is in the hover card and the row's semantics; the row's own line is the host.
      expect(find.bySemanticsLabel(RegExp('Waiting for Tor')), findsWidgets);
      expect(find.byKey(const ValueKey('overview-offline')), findsNothing);
    });

    testWidgets('Standard: no Offline mark', (tester) async {
      await _open(tester, DeskRoute.overview);
      expect(find.byKey(const ValueKey('overview-offline')), findsNothing);
    });
  });

  group('Send', () {
    ESegment<TxMethod> segment(WidgetTester tester, String label) =>
        tester.widget<ESegmented<TxMethod>>(find.byType(ESegmented<TxMethod>)).segments.firstWhere((s) => s.label == label);

    testWidgets('Offline: Epicbox is disabled with the reason; File runs and its tooltip says the node is used', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com', amount: '1'), advanced: _offline);
      expect(find.byKey(const ValueKey('send-net-blocked')), findsOneWidget);
      expect(find.text('Offline mode is on in Advanced.'), findsWidgets);
      expect(segment(tester, 'Epicbox').enabled, isFalse);
      expect(segment(tester, 'File').enabled, isTrue);
      expect(segment(tester, 'File').tooltip, 'Uses the node to read the chain and post. For the most privacy, use a local node.');
    });

    testWidgets('Offline with a LAN node: Link and File run, Epicbox waits; no peers says the payment waits', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(recipient: 'http://10.0.1.30:3415', amount: '1'), advanced: _offline, node: 'http://10.100.10.20:3413', peers: 0);
      expect(segment(tester, 'Epicbox').enabled, isFalse);
      expect(segment(tester, 'Link').enabled, isTrue);
      expect(segment(tester, 'File').enabled, isTrue);
      expect(find.byKey(const ValueKey('send-net-blocked')), findsNothing);
      expect(find.byKey(const ValueKey('send-offline-no-peers')), findsOneWidget);
      expect(find.text('Your node has no peers: the payment waits in its pool until it reconnects.'), findsOneWidget);
    });

    testWidgets('Tor only without Tor: the same, with the Tor reason', (tester) async {
      await _open(tester, DeskRoute.send, advanced: _torOnly);
      expect(find.byKey(const ValueKey('send-net-blocked')), findsOneWidget);
      expect(find.text('Waiting for Tor. Tor only is on in Advanced.'), findsWidgets);
      expect(segment(tester, 'Epicbox').enabled, isFalse);
      // A file needs no connection of its own: it goes on while Tor connects.
      expect(segment(tester, 'File').enabled, isTrue);
      await tester.tap(find.text('File'));
      await _settle(tester);
      expect(find.byKey(const ValueKey('send-net-blocked')), findsNothing);
    });

    testWidgets('Standard: nothing is held', (tester) async {
      await _open(tester, DeskRoute.send);
      expect(find.byKey(const ValueKey('send-net-blocked')), findsNothing);
      expect(segment(tester, 'Epicbox').enabled, isTrue);
    });

    testWidgets('Link receiving off: a pasted onion brings the Link segment for this send', (tester) async {
      await _open(tester, DeskRoute.send, arg: const SendArgs(), tor: true);
      List<String> labels() => tester.widget<ESegmented<TxMethod>>(find.byType(ESegmented<TxMethod>)).segments.map((s) => s.label).toList();
      expect(labels(), ['Epicbox', 'File']);
      await tester.enterText(find.byType(EditableText).first, _onion);
      await _settle(tester);
      expect(labels(), ['Epicbox', 'Link', 'File']);
      expect(tester.widget<ESegmented<TxMethod>>(find.byType(ESegmented<TxMethod>)).value, TxMethod.http);
      expect(_container.read(deskProvider).settings.payments.direct, isFalse, reason: 'nothing was switched on');
    });
  });

  group('Receive', () {
    testWidgets('Offline: the address stays, a line says it can’t receive, the Files panel runs and says the node is used', (tester) async {
      await _open(tester, DeskRoute.receive, advanced: _offline);
      expect(find.byKey(const ValueKey('rx-net-blocked')), findsOneWidget);
      expect(find.text('Offline mode is on in Advanced.'), findsWidgets);
      expect(find.text('Epicbox address'), findsWidgets);
      expect(find.textContaining('Can\'t receive offline'), findsWidgets);
      expect(find.byKey(tourKey('receive-files')), findsOneWidget);
      expect(find.byKey(const ValueKey('rx-files-offline-node')), findsOneWidget);
      expect(find.text('Uses the node to read the chain and post. For the most privacy, use a local node.'), findsOneWidget);
      for (final button in tester.widgetList<EButton>(find.descendant(of: find.byKey(tourKey('receive-files')), matching: find.byType(EButton)))) {
        expect(button.onPressed, isNotNull, reason: button.label);
      }
    });

    testWidgets('Offline with a LAN node: the Files panel runs without the node line', (tester) async {
      await _open(tester, DeskRoute.receive, advanced: _offline, node: 'http://10.100.10.20:3413');
      expect(find.byKey(const ValueKey('rx-files-offline-node')), findsNothing);
    });

    testWidgets('Tor only without Tor: the Files panel works', (tester) async {
      await _open(tester, DeskRoute.receive, advanced: _torOnly);
      expect(find.byKey(const ValueKey('rx-net-blocked')), findsOneWidget);
      expect(find.byKey(const ValueKey('rx-files-offline-node')), findsNothing);
    });

    testWidgets('Standard: no notice', (tester) async {
      await _open(tester, DeskRoute.receive);
      expect(find.byKey(const ValueKey('rx-net-blocked')), findsNothing);
    });
  });

  group('Recheck balance, updates and reports', () {
    testWidgets('Offline: Recheck balance is disabled with the reason', (tester) async {
      await _open(tester, DeskRoute.settingsRescan, advanced: _offline);
      expect(find.byKey(const ValueKey('rescan-net-blocked')), findsOneWidget);
      final start = tester.widget<EButton>(find.widgetWithText(EButton, 'Start'));
      expect(start.onPressed, isNull);
    });

    testWidgets('Standard: Recheck balance starts', (tester) async {
      await _open(tester, DeskRoute.settingsRescan);
      expect(find.byKey(const ValueKey('rescan-net-blocked')), findsNothing);
      expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Start')).onPressed, isNotNull);
      expect(find.text('Delete unconfirmed'), findsNothing, reason: 'behind Recheck from a height');
    });
  });

  group('Restore', () {
    testWidgets('the start height is offered with Advanced off, and reaches the wallet', (tester) async {
      await _open(tester, DeskRoute.restore, arg: RestoreStep.account);
      expect(_advanced.has(AdvancedFeature.recheckFromHeight), isFalse);
      expect(find.byKey(const ValueKey('restore-from-link')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('restore-from-link')));
      await _settle(tester);
      await tester.enterText(find.byKey(const ValueKey('restore-from-height')), 'x12');
      await _settle(tester);
      expect(find.text('Use digits only, or leave it empty.'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('restore-from-height')), '2800000');
      await _settle(tester);
      expect(find.text('Use digits only, or leave it empty.'), findsNothing);
    });
  });

  group('the tour', () {
    test('Advanced comes just before Help', () {
      for (final invoices in [false, true]) {
        final titles = tourStepsFor(invoices: invoices).map((s) => s.title).toList();
        expect(titles[titles.length - 2], 'Advanced');
        expect(titles.last, 'Help');
      }
      final step = tourStepsFor(invoices: false).firstWhere((s) => s.title == 'Advanced');
      expect(step.route, DeskRoute.settingsAdvanced);
      expect(step.targets, ['advanced-top']);
      expect(step.subId, 'subnav-settingsAdvanced');
    });

    test('no step names a hidden part', () {
      final hidden = RegExp('Link|Outputs|Technical|Logs|local node|kernel', caseSensitive: false);
      for (final s in tourStepsFor(invoices: true)) {
        if (s.title == 'Advanced') continue;
        expect(hidden.hasMatch(s.text), isFalse, reason: '${s.title}: ${s.text}');
      }
    });

    testWidgets('with Advanced off every step’s targets exist on its page; the Advanced step switches nothing on', (tester) async {
      await _open(tester, DeskRoute.overview);
      final nav = _container.read(deskNavProvider.notifier);
      final before = _advanced;
      for (final step in tourStepsFor(invoices: true)) {
        nav.go(step.route);
        await _settle(tester);
        for (final id in [...step.targets, step.navId, ?step.subId]) {
          expect(find.byKey(tourKey(id)), findsOneWidget, reason: '${step.title}: $id');
        }
      }
      expect(_advanced, before);
    });
  });
}
