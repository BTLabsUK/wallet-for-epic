// The one Tor switch on the desktop (Settings › Privacy): its state everywhere it shows, the
// clearnet HTTP listener off while it is on, and Epicbox waiting for it, never going around it.
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/desktop/app/rail.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/tor_view.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart' show SettingsJump;
import 'package:epic_wallet/src/desktop/screens/settings/settings_privacy.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/receive_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _skip = !DeskFeatures.tor;

/// The mock wallet with tor's health set by the test; [included] false is a build without it.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  bool included = true;
  ServiceHealth? torHealth;
  bool canSend = true;

  @override
  Future<ServiceStatus> status() async {
    final s = await super.status();
    final tor = !included ? ServiceHealth.off : (s.tor == ServiceHealth.off ? ServiceHealth.off : torHealth ?? s.tor);
    return ServiceStatus(
      node: s.node,
      nodeHealth: s.nodeHealth,
      nodeHeight: s.nodeHeight,
      epicbox: s.epicbox,
      epicboxHealth: s.epicboxHealth,
      httpListener: s.httpListener,
      tor: tor,
      torCanSend: included && tor != ServiceHealth.off && tor != ServiceHealth.down && canSend,
      torIncluded: included,
      torProblem: tor == ServiceHealth.down ? 'Tor could not connect to the network' : null,
      lastUpdate: s.lastUpdate,
    );
  }
}

ServiceStatus _status({ServiceHealth tor = ServiceHealth.off, bool canSend = false, ServiceHealth epicbox = ServiceHealth.ok}) => ServiceStatus(
  node: const NodeServer(url: 'https://node.example', label: 'Example'),
  nodeHealth: ServiceHealth.ok,
  nodeHeight: 100,
  httpListener: ServiceHealth.off,
  epicbox: const EpicboxServer(domain: 'epicbox.example'),
  epicboxHealth: epicbox,
  tor: tor,
  torCanSend: canSend,
);

void main() {
  group('the Tor state', () {
    test('off, starting, on and failed from the switch and tor', () {
      const off = DeskSettings();
      const on = DeskSettings(tor: true);
      expect(torStateOf(off, _status(tor: ServiceHealth.ok, canSend: true)), TorState.off);
      expect(torStateOf(on, null), TorState.starting);
      expect(torStateOf(on, _status()), TorState.starting, reason: 'on, not started yet');
      expect(torStateOf(on, _status(tor: ServiceHealth.checking)), TorState.starting);
      expect(torStateOf(on, _status(tor: ServiceHealth.checking, canSend: true)), TorState.on, reason: 'publishing the onion');
      expect(torStateOf(on, _status(tor: ServiceHealth.slow, canSend: true)), TorState.on, reason: 'sends work');
      expect(torStateOf(on, _status(tor: ServiceHealth.ok, canSend: true)), TorState.on);
      expect(torStateOf(on, _status(tor: ServiceHealth.down)), TorState.failed);
    });

    test('the status card shows the Tor row in every state and opens Privacy', () {
      RailItem torRow(DeskSettings s, ServiceStatus st) => receivingRailItems(englishStrings, st, s).singleWhere((i) => i.name == 'Tor');
      expect(torRow(const DeskSettings(), _status()).word, 'Off');
      expect(torRow(const DeskSettings(tor: true), _status(tor: ServiceHealth.checking)).word, 'Starting…');
      expect(torRow(const DeskSettings(tor: true), _status(tor: ServiceHealth.ok, canSend: true)).word, 'On');
      final failed = torRow(const DeskSettings(tor: true), _status(tor: ServiceHealth.down));
      expect(failed.word, 'Not connected');
      expect(failed.state, EState.risk);
      expect(failed.jump, SettingsJump.tor);
    }, skip: _skip);

    test('Epicbox waits for Tor while it starts or failed, and says over Tor once on', () {
      RailItem ebRow(DeskSettings s, ServiceStatus st) => receivingRailItems(englishStrings, st, s).singleWhere((i) => i.name == 'Epicbox');
      const on = DeskSettings(tor: true);
      expect(ebRow(on, _status(tor: ServiceHealth.checking, epicbox: ServiceHealth.checking)).word, 'Waiting for Tor');
      expect(ebRow(on, _status(tor: ServiceHealth.down, epicbox: ServiceHealth.down)).word, 'Waiting for Tor');
      expect(ebRow(on, _status(tor: ServiceHealth.ok, canSend: true)).lines, contains('Over Tor'));
      expect(ebRow(const DeskSettings(), _status()).lines, isNot(contains('Over Tor')));
      final line = methodStateLine(englishStrings, TxMethod.epicbox, _status(tor: ServiceHealth.down, epicbox: ServiceHealth.down), on);
      expect(line.word, 'Waiting for Tor');
    }, skip: _skip);

    test('the coverage text names only what goes over Tor', () {
      final text = torCoverageText(englishStrings);
      expect(text, 'Over Tor: Epicbox, the node, status, price, updates, support and Tor addresses.');
      expect(text, isNot(contains('Not over Tor')));
      expect(text, isNot(contains('Link to http(s)')));
    });
  });

  group('Settings › Privacy', () {
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

    Finder torSwitch() => find.byKey(const ValueKey('privacy-tor-switch'));
    String torLine(WidgetTester tester) => tester.widget<EStateLine>(find.byKey(const ValueKey('privacy-tor-state'))).line.text;

    testWidgets('off by default; the switch turns Tor on now and at every unlock', (tester) async {
      await show(tester, const SettingsPrivacyScreen());
      expect(tester.widget<ESwitch>(torSwitch()).value, isFalse);
      expect(torLine(tester), startsWith('Off'));
      await tester.tap(torSwitch());
      await tester.pumpAndSettle();
      final s = container.read(deskProvider).settings;
      expect(s.tor, isTrue);
      expect(s.torAutostart, isTrue, reason: 'one switch: remembered');
      expect(torLine(tester), startsWith('On'));
      await tester.tap(torSwitch());
      await tester.pumpAndSettle();
      expect(container.read(deskProvider).settings.torAutostart, isFalse);
    }, skip: _skip);

    testWidgets('not connected: Retry and Turn Tor off', (tester) async {
      wallet.torHealth = ServiceHealth.down;
      await show(tester, const SettingsPrivacyScreen());
      await tester.tap(torSwitch());
      await tester.pumpAndSettle();
      expect(torLine(tester), startsWith('Not connected'));
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Turn Tor off'));
      await tester.pumpAndSettle();
      expect(container.read(deskProvider).settings.tor, isFalse);
    }, skip: _skip);

    testWidgets('without the bundle the switch is disabled and says so', (tester) async {
      wallet.included = false;
      await show(tester, const SettingsPrivacyScreen());
      expect(tester.widget<ESwitch>(torSwitch()).onChanged, isNull);
      expect(torLine(tester), 'Not in this build');
    }, skip: _skip);

    testWidgets('the clearnet HTTP listener stops while Tor is on and comes back after', (tester) async {
      await show(tester, const SettingsPrivacyScreen());
      final n = container.read(deskProvider.notifier);
      await tester.runAsync(() => n.setHttp(true));
      expect((await tester.runAsync(wallet.status))!.httpListener, isNot(ServiceHealth.off));
      await tester.runAsync(() => n.setTor(true));
      expect((await tester.runAsync(wallet.status))!.httpListener, ServiceHealth.off);
      await tester.runAsync(() => n.setHttp(true));
      expect((await tester.runAsync(wallet.status))!.httpListener, ServiceHealth.off, reason: 'no start while Tor is on');
      await tester.runAsync(() => n.setTor(false));
      expect((await tester.runAsync(wallet.status))!.httpListener, isNot(ServiceHealth.off));
    }, skip: _skip);

    testWidgets('Receive: Link is the Tor address with Tor on, with no switch of its own', (tester) async {
      await tester.runAsync(() => container.read(deskProvider.notifier).setTor(true));
      await show(tester, const ReceiveScreen());
      expect(find.text('Link Payment · Tor address'), findsOneWidget);
      expect(find.text('Link Payment · HTTP address'), findsNothing);
      expect(find.byKey(const ValueKey('rx-switch-tor')), findsNothing);
      expect(find.text('Over Tor'), findsOneWidget, reason: 'the chip beside the title');
    }, skip: _skip);

    testWidgets('Receive: Tor not connected shows Retry and Turn Tor off', (tester) async {
      wallet.torHealth = ServiceHealth.down;
      await tester.runAsync(() => container.read(deskProvider.notifier).setTor(true));
      await show(tester, const ReceiveScreen());
      expect(find.byKey(const ValueKey('rx-tor-notice')), findsOneWidget);
      expect(find.text('Turn Tor off'), findsOneWidget);
    }, skip: _skip);
  });
}
