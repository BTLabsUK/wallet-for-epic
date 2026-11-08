// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:math' as math;

import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/levels/level_providers.dart' show currentLevelProvider;
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/message_checks.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show appConfig;
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart' as dir;
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart' show networkModeProvider;
import 'package:epic_wallet/src/ui/home_status.dart';
import 'package:epic_wallet/src/ui/message_check_panel.dart' show messageCheckRowKey;
import 'package:epic_wallet/src/ui/receive_screen.dart'
    show ReceiveTab, receiveTabProvider;
import 'package:epic_wallet/src/ui/server_list_sheet.dart' show ServerListSheet;
import 'package:epic_wallet/src/ui/network_mode_phone.dart' show networkModeChangeKey, networkModeMarkKey, networkModeRowKey, networkSectionKey;
import 'package:epic_wallet/src/ui/shell_header.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/ui/tor_ui.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/ui/status_icons.dart';
import 'package:epic_wallet/src/tor_build.dart';

final _l = englishStrings;

WalletSummary _summary({bool validated = true, int height = 2499990, BigInt? spendable}) =>
    WalletSummary(
      lastConfirmedHeight: BigInt.from(height),
      minimumConfirmations: BigInt.from(3),
      total: BigInt.from(100),
      spendable: spendable ?? BigInt.from(100),
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: validated,
    );

final NodeTip _tip = NodeTip(
  height: BigInt.from(2500000),
  nodeVersion: '3.6.0',
);

const ListenerState _connected = ListenerState(connected: true);
const ListenerState _lost = ListenerState(lost: true);
const ListenerState _connecting = ListenerState();
const ListenerState _stopped = ListenerState(stopped: true);

const String _onion =
    'wfetestk3nq7vmh2xq4cbe6ta5s3l7xw2z5pyp6uh2l3xfi3yk4qdaaaaaaa.onion';
const PhoneTorState _torOff = PhoneTorState(
  phase: PhoneTorPhase.off,
  onion: _onion,
);
const PhoneTorState _torStarting = PhoneTorState(
  phase: PhoneTorPhase.starting,
  progress: 40,
  onion: _onion,
  receiving: true,
);
const PhoneTorState _torReady = PhoneTorState(
  phase: PhoneTorPhase.ready,
  onion: _onion,
  receiving: true,
  socksPort: 9050,
);
const PhoneTorState _torPublishing = PhoneTorState(
  phase: PhoneTorPhase.connected,
  onion: _onion,
  receiving: true,
  socksPort: 9050,
);
const PhoneTorState _torUnpublished = PhoneTorState(
  phase: PhoneTorPhase.connected,
  onion: _onion,
  receiving: true,
  socksPort: 9050,
  failure: TorFailure.publish,
);
const PhoneTorState _torFailed = PhoneTorState(
  phase: PhoneTorPhase.failed,
  onion: _onion,
  receiving: true,
  failure: TorFailure.network,
);

class _Home extends HomeNotifier {
  _Home(this.data);

  final HomeData? data;

  @override
  Future<HomeData> build() async =>
      data ?? Future<HomeData>.error(StateError('no data'));
}

class _Listener extends ListenerNotifier {
  _Listener(this.value);

  final ListenerState value;

  @override
  ListenerState build() => value;
}

class _Progress extends SyncProgressNotifier {
  _Progress(this.value);

  final int? value;

  @override
  int? build() => value;
}

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(
    dataDir: '/fake',
    nodeUrl: 'https://node.example.org',
  );
}

class _Tor extends PhoneTor {
  _Tor(this.value);

  final PhoneTorState value;

  @override
  PhoneTorState build() => value;
}

class _Price implements PriceSource {
  @override
  Future<double?> price(String currency) async => 0.5;
}

/// status.lab.invalid down: no network tip, so a node that answers reads Synced.
class _Directory
    implements dir.RelayDirectory, dir.NodeDirectory, dir.NetworkDirectory {
  @override
  Future<dir.NetworkStatus> network(String chain) async =>
      throw const NetError('down');

  @override
  Future<List<dir.NodeStatus>> nodes(String chain) async =>
      throw const NetError('down');

  @override
  Future<List<dir.RelayStatus>> relays(String chain) async =>
      throw const NetError('down');
}

final HomeData _home = HomeData(summary: _summary(), transactions: const []);

Future<void> _pump(
  WidgetTester tester, {
  AsyncValue<NodeTip>? tip,
  HomeData? home,
  int? percent,
  ListenerState listener = _connected,
  PhoneTorState tor = _torOff,
  Widget child = const StatusIcons(key: walletStatusesKey),
  double width = 412,
  double scale = 1,
  AdvancedPrefs advanced = AdvancedPrefs.none,
  MessageChecks? checks,
}) async {
  final t = tip ?? AsyncData(_tip);
  tester.view.physicalSize = Size(width * 3, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        nodeTipProvider.overrideWith(
          (ref) => switch (t) {
            AsyncData(:final value) => Future.value(value),
            AsyncError(:final error) => Future<NodeTip>.error(error),
            _ => Completer<NodeTip>().future,
          },
        ),
        homeProvider.overrideWith(() => _Home(home ?? _home)),
        syncProgressProvider.overrideWith(() => _Progress(percent)),
        listenerProvider.overrideWith(() => _Listener(listener)),
        walletConfigProvider.overrideWith(_Config.new),
        secretStoreProvider.overrideWithValue(
          MemorySecretStore({'app.network': 'mainnet'}),
        ),
        phoneTorProvider.overrideWith(() => _Tor(tor)),
        networkModeProvider.overrideWithValue(advanced.networkMode),
        dir.relayDirectoryProvider.overrideWithValue(_Directory()),
        priceSourceProvider.overrideWithValue(_Price()),
        // Deep end: the footer is on the connections sheet (Shallow has it on the Epicbox sheet).
        if (checks != null) currentLevelProvider.overrideWithValue(WalletLevel.everything),
        if (checks != null) messageCheckProvider.overrideWith((ref) => messageCheckStream(checks)),
      ],
      child: MaterialApp(
        theme: buildWalletTheme(protocolDark, Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AdvancedOptions(
          prefs: advanced,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
        ),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  // Offline and syncing show once they last (walletStatusProvider).
  await tester.pump(statusSettle);
}

/// What a screen reader says for the status: the icon shows no words.
String _label(WidgetTester tester, Key key) =>
    _semantics(tester, key).properties.label!;

String _hint(WidgetTester tester, Key key) =>
    _semantics(tester, key).properties.hint!;

Semantics _semantics(WidgetTester tester, Key key) => tester.widget<Semantics>(
  find
      .descendant(
        of: find.byKey(key),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label != null,
        ),
      )
      .first,
);

/// The status's detail: what the connections sheet's row says under the service, and a
/// screen reader's hint (the icon has no tooltip: its long press opens the sheet).
String _tip_(WidgetTester tester, Key key) =>
    tester.widget<StatusIcon>(find.byKey(key)).detail;

IconData _icon(WidgetTester tester, Key key) => tester
    .widget<Icon>(
      find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
    )
    .icon!;

/// The colour of the state dot at the glyph's bottom right.
Color _dot(WidgetTester tester, Key key) {
  final t = tester.element(find.byKey(key)).tokens;
  final dots = find.descendant(of: find.byKey(key), matching: find.byType(StateDot));
  // Off draws no dot: the glyph is faded with a slash instead.
  if (dots.evaluate().isEmpty) return t.faint;
  return tester.widget<StateDot>(dots).dot.color(t);
}

WalletTokens _tokens(WidgetTester tester) =>
    tester.element(find.byKey(nodeStatusKey)).tokens;

double _opacity(WidgetTester tester, Key key) => tester
    .widget<FadeTransition>(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

void main() {
  group('node and epicbox', () {
    testWidgets('online: the service and its word, the detail in the tooltip', (
      tester,
    ) async {
      await _pump(tester);
      final t = _tokens(tester);
      expect(_label(tester, nodeStatusKey), 'Node, Synced');
      expect(_icon(tester, nodeStatusKey), EpicGlyphs.node);
      expect(_dot(tester, nodeStatusKey), t.ok);
      expect(
        _tip_(tester, nodeStatusKey),
        'Up to date.\nNode: node.example.org\nSynced at block 2,499,990\n'
        'Node version 3.6.0',
      );
      // A screen reader hears the detail, then what a tap does.
      expect(
        _hint(tester, nodeStatusKey),
        '${_tip_(tester, nodeStatusKey)}\nShows details',
      );
      expect(_label(tester, epicboxStatusKey), 'Epicbox, Connected');
      expect(_icon(tester, epicboxStatusKey), EpicGlyphs.epicbox);
      expect(_dot(tester, epicboxStatusKey), t.ok);
      expect(
        _tip_(tester, epicboxStatusKey),
        'Connected · box.epic.invalid\nServer: box.epic.invalid:443',
      );
      // Tor and Link off: both stay, faint and without a dot, their labels say Off and a
      // tap opens the switch; no Tor words on the two.
      expect(find.byKey(torIconKey), findsOneWidget);
      expect(_label(tester, torIconKey), 'Tor, Off');
      expect(_dot(tester, torIconKey), t.faint);
      expect(find.byKey(directIconKey), findsOneWidget);
      expect(_label(tester, directIconKey), 'Link, Off');
      expect(_hint(tester, directIconKey), contains('Turn on in Settings\u00a0›\u00a0Transactions'));
      expect(_label(tester, nodeStatusKey), isNot(contains('Tor')));
    });

    testWidgets('syncing with its percent: blue, pulsing', (tester) async {
      await _pump(
        tester,
        home: HomeData(
          summary: _summary(),
          transactions: const [],
          syncing: true,
        ),
        percent: 40,
      );
      expect(_label(tester, nodeStatusKey), 'Node, Syncing 40%');
      expect(_icon(tester, nodeStatusKey), Icons.sync);
      expect(_dot(tester, nodeStatusKey), _tokens(tester).info);
      expect(_tip_(tester, nodeStatusKey), startsWith('Syncing… 40%'));
      // The syncing node pulses; epicbox does not.
      final node = <double>{}, epicbox = <double>{};
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        node.add(_opacity(tester, nodeStatusKey));
        epicbox.add(_opacity(tester, epicboxStatusKey));
      }
      expect(node.length, greaterThan(3));
      expect(node.reduce(math.min), greaterThanOrEqualTo(0.45));
      expect(epicbox, {1.0});
    });

    testWidgets('icons only, each on a 48 dp target, the glyph dim', (
      tester,
    ) async {
      await _pump(tester, tor: _torReady);
      expect(find.byType(Text), findsNothing);
      final t = _tokens(tester);
      for (final key in [
        nodeStatusKey,
        epicboxStatusKey,
        torIconKey,
        directIconKey,
      ]) {
        expect(tester.getSize(find.byKey(key)), const Size(48, 48));
        final glyph = find.descendant(
          of: find.byKey(key),
          matching: find.byType(Icon),
        );
        expect(tester.getRect(glyph).size, const Size(statusGlyph, statusGlyph));
        expect(
          tester.getRect(glyph).left - tester.getRect(find.byKey(key)).left,
          statusInset,
        );
        // An enabled service's glyph is neutral; only the mark (and the words) say its
        // connection.
        expect(tester.widget<Icon>(glyph).color, t.dim);
        final dot = tester.getRect(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(StateDot),
          ),
        );
        expect(dot.size, const Size(statusDotSize, statusDotSize));
        expect(dot.right, greaterThan(tester.getRect(glyph).right));
        expect(dot.bottom, greaterThan(tester.getRect(glyph).bottom));
      }
      // In order: Node, Epicbox, Tor, Link.
      final lefts = [
        for (final key in [
          nodeStatusKey,
          epicboxStatusKey,
          torIconKey,
          directIconKey,
        ])
          tester.getRect(find.byKey(key)).left,
      ];
      expect(lefts, [0, 48, 96, 144].map((x) => lefts.first + x).toList());
    });

    testWidgets('connecting: blue, still', (tester) async {
      await _pump(tester, tip: const AsyncLoading(), listener: _connecting);
      final t = _tokens(tester);
      expect(_label(tester, nodeStatusKey), 'Node, Connecting');
      expect(_icon(tester, nodeStatusKey), Icons.cloud_queue);
      expect(_dot(tester, nodeStatusKey), t.info);
      expect(_tip_(tester, nodeStatusKey), startsWith('Contacting node…'));
      expect(_label(tester, epicboxStatusKey), 'Epicbox, Connecting');
      expect(_icon(tester, epicboxStatusKey), EpicGlyphs.epicbox);
      expect(_dot(tester, epicboxStatusKey), t.info);
      // Connecting sits still: only a sync in progress pulses, so Home settles.
      await tester.pump(const Duration(milliseconds: 400));
      expect(_opacity(tester, nodeStatusKey), 1);
      expect(_opacity(tester, epicboxStatusKey), 1);
      expect(
        _tip_(tester, epicboxStatusKey),
        startsWith('Connecting to Epicbox…'),
      );
    });

    testWidgets('offline: red', (tester) async {
      await _pump(
        tester,
        tip: AsyncError(StateError('down'), StackTrace.empty),
        listener: _lost,
      );
      final t = _tokens(tester);
      expect(_label(tester, nodeStatusKey), 'Node, Not answering');
      expect(_icon(tester, nodeStatusKey), Icons.cloud_off);
      expect(_dot(tester, nodeStatusKey), t.risk);
      expect(_tip_(tester, nodeStatusKey), startsWith('Node unreachable.'));
      expect(_label(tester, epicboxStatusKey), 'Epicbox, Not connected');
      expect(_icon(tester, epicboxStatusKey), EpicGlyphs.epicbox);
      expect(_dot(tester, epicboxStatusKey), t.risk);
      expect(
        _tip_(tester, epicboxStatusKey),
        startsWith('Your wallet is not connected to its Epicbox server and keeps trying.'),
      );
    });

    testWidgets('a stopped listener: Epicbox stays, Off, faint', (
      tester,
    ) async {
      await _pump(tester, listener: _stopped);
      expect(find.byKey(nodeStatusKey), findsOneWidget);
      expect(_label(tester, epicboxStatusKey), 'Epicbox, Off');
      expect(_dot(tester, epicboxStatusKey), _tokens(tester).faint);
      expect(
        _tip_(tester, epicboxStatusKey),
        'Off. Turn on in Settings\u00a0›\u00a0Transactions.',
      );
    });

    testWidgets('a screen reader hears the service and the word', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, listener: _lost);
      expect(find.bySemanticsLabel('Node, Synced'), findsOneWidget);
      expect(find.bySemanticsLabel('Epicbox, Not connected'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a screen reader opens a connections row as a tap does', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await tester.tap(find.byKey(nodeStatusKey));
      await tester.pumpAndSettle();
      final row = find.descendant(
        of: find.byKey(connectionsSheetKey),
        matching: find.bySemanticsLabel('Node, Synced'),
      );
      expect(row, findsOneWidget);
      expect(
        tester.getSemantics(row),
        isSemantics(label: 'Node, Synced', isButton: true, hasTapAction: true),
      );
      tester.semantics.tap(find.semantics.byLabel('Node, Synced'));
      await tester.pumpAndSettle();
      expect(find.byKey(connectionsSheetKey), findsNothing);
      expect(find.byType(ServerListSheet), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a long press opens the connections sheet with one line per row; a tap too', (
      tester,
    ) async {
      await _pump(tester);
      await tester.longPress(find.byKey(nodeStatusKey));
      await tester.pumpAndSettle();
      // Every connection as a row, the service and its state word, the detail under it.
      final sheet = find.byKey(connectionsSheetKey);
      expect(sheet, findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text(_l.connectionsSheetTitle)), findsOneWidget);
      for (final key in [nodeStatusKey, epicboxStatusKey, torIconKey, directIconKey]) {
        final label = _label(tester, key);
        expect(find.descendant(of: sheet, matching: find.text(label)), findsOneWidget, reason: label);
      }
      // One line per row: the first line of the tip with the host, never the whole tooltip.
      expect(find.descendant(of: sheet, matching: find.text('Up to date\u00A0· node.example.org')), findsOneWidget);
      // A row closes the sheet and opens the service as its icon does.
      await tester.tap(find.descendant(of: sheet, matching: find.text('Node, Synced')));
      await tester.pumpAndSettle();
      expect(find.byKey(connectionsSheetKey), findsNothing);
      expect(find.byType(ServerListSheet), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(ServerListSheet), findsNothing);
      // A tap on an icon opens the connections sheet too: the one entry point at every View.
      await tester.tap(find.byKey(nodeStatusKey));
      await tester.pumpAndSettle();
      expect(find.byKey(connectionsSheetKey), findsOneWidget);
      expect(find.byType(ServerListSheet), findsNothing);
    });
  });

  group('Tor and Link', () {
    testWidgets('starting: Tor blue and pulsing, the two wait for it, still', (
      tester,
    ) async {
      await _pump(tester, tor: _torStarting);
      final t = _tokens(tester);
      expect(_label(tester, torIconKey), 'Tor, Starting');
      expect(_icon(tester, torIconKey), torIcon);
      expect(_dot(tester, torIconKey), t.info);
      expect(_tip_(tester, torIconKey), 'Connecting to Tor… 40%');
      expect(_hint(tester, torIconKey), endsWith('\nShows details'));
      // Link waits for Tor too: on, with a blue ring, publishing.
      expect(find.byKey(directIconKey), findsOneWidget);
      for (final key in [nodeStatusKey, epicboxStatusKey]) {
        expect(_label(tester, key), endsWith(', Waiting for Tor'));
        expect(_dot(tester, key), t.info);
        expect(_tip_(tester, key), endsWith('\nWaiting for Tor'));
      }
      final tor = <double>{}, node = <double>{};
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        tor.add(_opacity(tester, torIconKey));
        node.add(_opacity(tester, nodeStatusKey));
      }
      expect(tor.length, greaterThan(3));
      expect(node, {1.0});
    });

    testWidgets('on and published: Tor and Link green, the two over Tor', (
      tester,
    ) async {
      await _pump(tester, tor: _torReady);
      final t = _tokens(tester);
      expect(_label(tester, torIconKey), 'Tor, Connected');
      expect(_dot(tester, torIconKey), t.ok);
      expect(_tip_(tester, torIconKey), 'Connected');
      expect(_label(tester, directIconKey), 'Link, Reachable');
      expect(_icon(tester, directIconKey), EpicGlyphs.link);
      expect(_dot(tester, directIconKey), t.ok);
      expect(_tip_(tester, directIconKey), 'Tor receiving is on');
      expect(
        _hint(tester, directIconKey),
        'Tor receiving is on\nShows details',
      );
      expect(_label(tester, nodeStatusKey), 'Node, Synced, Over Tor');
      expect(_dot(tester, nodeStatusKey), t.ok);
      expect(_tip_(tester, nodeStatusKey), endsWith('\nOver Tor'));
      expect(_label(tester, epicboxStatusKey), 'Epicbox, Connected, Over Tor');
      expect(_opacity(tester, torIconKey), 1);
    });

    testWidgets('publishing: Link blue; unpublished: red', (tester) async {
      await _pump(tester, tor: _torPublishing);
      expect(_label(tester, directIconKey), 'Link, Publishing…');
      expect(_dot(tester, directIconKey), _tokens(tester).info);
      // A new scope: a ProviderScope keeps the overrides it was built with.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, tor: _torUnpublished);
      expect(_label(tester, directIconKey), 'Link, Not reachable');
      expect(_dot(tester, directIconKey), _tokens(tester).risk);
      expect(_tip_(tester, directIconKey), startsWith('Your Tor address is not reachable yet.'));
    });

    testWidgets('not connected: Tor red, the two blocked and say why', (
      tester,
    ) async {
      await _pump(tester, tor: _torFailed);
      final t = _tokens(tester);
      expect(_label(tester, torIconKey), 'Tor, Not connected');
      expect(_dot(tester, torIconKey), t.risk);
      expect(find.byKey(directIconKey), findsOneWidget);
      for (final key in [nodeStatusKey, epicboxStatusKey]) {
        expect(_label(tester, key), endsWith(', Waiting for Tor'));
        expect(_dot(tester, key), t.risk);
        expect(_hint(tester, key), contains('Tor is not connected.'));
      }
    });

    testWidgets('no Tor on this phone: nothing of it, and no Link', (tester) async {
      // As PhoneTor.build gives it in the build without Tor: unavailable, the switch never on.
      // (Unavailable with the switch on is a missing tor bundle: blocked, Waiting for Tor.)
      await _pump(tester, tor: const PhoneTorState(phase: PhoneTorPhase.unavailable));
      expect(find.byKey(torIconKey), findsNothing, reason: 'no Tor on this phone: nothing to switch on');
      expect(find.byKey(directIconKey), findsNothing, reason: 'Link · HTTP only sends: nothing to receive, not shown as off');
      expect(_label(tester, nodeStatusKey), 'Node, Synced');
    });

    testWidgets('a tap on Link goes to Receive, Link tab', (tester) async {
      await _pump(tester, tor: _torReady);
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(directIconKey)),
      );
      expect(container.read(shellTabProvider), ShellTab.wallet);
      await tester.tap(find.byKey(directIconKey));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byKey(connectionsSheetKey), matching: find.text(_label(tester, directIconKey))));
      await tester.pumpAndSettle();
      expect(container.read(shellTabProvider), ShellTab.receive);
      expect(container.read(receiveTabProvider), ReceiveTab.direct);
    });
  });

  group('network mode', () {
    const nodeOnly = AdvancedPrefs(networkMode: NetworkMode.nodeOnly);
    const kill = AdvancedPrefs(networkMode: NetworkMode.killSwitch);
    const torOnly = AdvancedPrefs(networkMode: NetworkMode.torOnly);

    testWidgets('Normal: the icons, no mode line in the sheet', (tester) async {
      await _pump(tester);
      expect(find.byKey(networkModeMarkKey), findsNothing);
      expect(find.byKey(nodeStatusKey), findsOneWidget);
      expect(find.byKey(epicboxStatusKey), findsOneWidget);
      await tester.tap(find.byKey(nodeStatusKey));
      await tester.pumpAndSettle();
      expect(find.byKey(connectionsSheetKey), findsOneWidget);
      expect(find.byKey(networkModeMarkKey), findsNothing);
    });

    testWidgets('Node only: the strip is the icons alone, Epicbox and Link read Off (Node only), the node stays on; the sheet names the mode', (
      tester,
    ) async {
      await _pump(tester, advanced: nodeOnly, tor: _torOff);
      expect(find.byKey(networkModeMarkKey), findsNothing);
      expect(_label(tester, nodeStatusKey), 'Node, Synced');
      expect(_label(tester, epicboxStatusKey), 'Epicbox, Off (Node only)');
      expect(_label(tester, directIconKey), 'Link, Off (Node only)');
      // Calm: faint with a slash, no problem colour.
      expect(_dot(tester, epicboxStatusKey), _tokens(tester).faint);
      expect(_tip_(tester, epicboxStatusKey), 'Turned off by the network mode. Change it in Settings\u00a0›\u00a0Network & privacy.');
      await tester.tap(find.byKey(nodeStatusKey));
      await tester.pumpAndSettle();
      final line = find.descendant(of: find.byKey(connectionsSheetKey), matching: find.byKey(networkModeMarkKey));
      expect(line, findsOneWidget);
      expect(find.descendant(of: line, matching: find.text('Network mode: Node only')), findsOneWidget);
      expect(_label(tester, networkModeMarkKey), 'Network mode: Node only');
      expect(_hint(tester, networkModeMarkKey), 'Only the node in use. Epicbox, Link, updates and price are off.');
      expect(find.descendant(of: line, matching: find.text(_l.netMarkChange)), findsOneWidget);
      // Quiet: one line under the title, above the first service row.
      expect(tester.getRect(line).height, lessThanOrEqualTo(40));
      expect(tester.getRect(line).bottom, lessThanOrEqualTo(tester.getTopLeft(find.descendant(of: find.byKey(connectionsSheetKey), matching: find.text('Node, Synced'))).dy));
    });

    testWidgets('Kill switch: every service reads Off (Kill switch); a tap opens the Network section', (
      tester,
    ) async {
      await _pump(tester, advanced: kill, tor: _torOff);
      expect(_label(tester, nodeStatusKey), 'Node, Off (Kill switch)');
      expect(_label(tester, epicboxStatusKey), 'Epicbox, Off (Kill switch)');
      expect(_label(tester, directIconKey), 'Link, Off (Kill switch)');
      await tester.tap(find.byKey(epicboxStatusKey));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byKey(networkModeMarkKey), matching: find.text('Network mode: Kill switch')), findsOneWidget);
      await tester.tap(find.descendant(of: find.byKey(connectionsSheetKey), matching: find.text('Epicbox, Off (Kill switch)')));
      await tester.pumpAndSettle();
      expect(find.byKey(networkSectionKey), findsOneWidget);
      expect(find.byKey(networkModeRowKey(NetworkMode.killSwitch)), findsOneWidget);
    });

    testWidgets("the sheet's Change link closes the sheet and opens the Network section", (tester) async {
      await _pump(tester, advanced: nodeOnly, tor: _torOff);
      await tester.tap(find.byKey(nodeStatusKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(networkModeChangeKey));
      await tester.pumpAndSettle();
      expect(find.byKey(connectionsSheetKey), findsNothing);
      expect(find.byKey(networkSectionKey), findsOneWidget);
    });

    testWidgets('Tor only without Tor: the node and Epicbox wait for Tor; the sheet names the mode and says so', (
      tester,
    ) async {
      await _pump(tester, advanced: torOnly, tor: _torStarting);
      expect(_label(tester, nodeStatusKey), contains('Waiting for Tor'));
      expect(_label(tester, epicboxStatusKey), contains('Waiting for Tor'));
      // Tor's own icon stays: it is how the user sees Tor start.
      expect(find.byKey(torIconKey), findsOneWidget);
      await tester.tap(find.byKey(nodeStatusKey));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byKey(networkModeMarkKey), matching: find.text(_l.netMarkRowLabel(_l.advModeTorOnly))), findsOneWidget);
      expect(_hint(tester, networkModeMarkKey), 'Waiting for Tor. Nothing connects until it is ready.');
    }, skip: !torBuilt);

    testWidgets('Kill switch keeps the last balance, marks the caption, and shows no fiat value', (
      tester,
    ) async {
      await _pump(
        tester,
        child: const WalletBalance(),
        advanced: kill,
        tor: _torOff,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(balanceFigureKey), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(balanceCaptionKey)).data,
        'Available to spend · last known',
      );
      expect(find.byKey(fiatValueKey), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, child: const WalletBalance(), tor: _torOff);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(balanceCaptionKey)).data,
        'Available to spend',
      );
    });
  });

  group('in the balance area', () {
    for (final (width, scale) in [(360.0, 1.0), (360.0, 1.3), (412.0, 1.3)]) {
      testWidgets('$width dp at $scale: four icons, the fiat value, the eye fit', (
        tester,
      ) async {
        await _pump(
          tester,
          child: const WalletBalance(),
          tor: _torOff,
          width: width,
          scale: scale,
        );
        await tester.pumpAndSettle();
        final height = tester.getSize(find.byKey(walletBalanceKey)).height;
        final two = tester.getRect(find.byKey(fiatValueKey));
        // Tor off is still on the row, faint.
        expect(find.byKey(torIconKey), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await _pump(
          tester,
          child: const WalletBalance(),
          tor: _torReady,
          width: width,
          scale: scale,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Nothing jumps: the area is as tall with four icons as with two.
        expect(tester.getSize(find.byKey(walletBalanceKey)).height, height);
        final area = tester.getRect(find.byKey(walletBalanceKey));
        final direct = tester.getRect(find.byKey(directIconKey));
        final fiat = tester.getRect(find.byKey(fiatValueKey));
        final eye = tester.getRect(find.byTooltip(_l.homeHideBalances));
        // Icons at the start, then the fiat value, then the eye at the end, on one line.
        expect(fiat.left, greaterThanOrEqualTo(direct.right));
        expect(eye.left, greaterThanOrEqualTo(fiat.right - 0.5));
        expect(eye.right, lessThanOrEqualTo(area.right));
        expect(fiat.center.dy, closeTo(eye.center.dy, 1));
        expect(fiat.center.dy, closeTo(direct.center.dy, 1));
        expect(fiat.height, greaterThan(8), reason: 'the fiat value is legible');
        // The eye stays put when icons come and go; the value shrinks instead.
        expect(fiat.right, closeTo(two.right, 0.5));
        // The first glyph lines up with the text gutter (18 dp), as the eye's does.
        final nodeGlyph = tester.getRect(
          find.descendant(
            of: find.byKey(nodeStatusKey),
            matching: find.byType(Icon),
          ),
        );
        expect(nodeGlyph.left - area.left, closeTo(18, 0.5));
        expect(area.right - eye.right, closeTo(3, 0.5));
      });
    }
  });

  group("in Send's and Receive's balance header", () {
    // The header under the shell's bar: the figure with its details, then the icons.
    Widget header() => const BalanceHeader();

    WalletTokens tokens(WidgetTester tester) =>
        tester.element(find.byKey(barNodeIconKey)).tokens;

    testWidgets('all fine: every icon on the header, after the figure', (
      tester,
    ) async {
      await _pump(tester, child: header());
      final t = tokens(tester);
      expect(find.byKey(barStatusesKey), findsOneWidget);
      expect(_label(tester, barNodeIconKey), 'Node, Synced');
      expect(_label(tester, barEpicboxIconKey), 'Epicbox, Connected');
      expect(_dot(tester, barNodeIconKey), t.ok);
      expect(_dot(tester, barEpicboxIconKey), t.ok);
      // Off services show too, faint: the header has the room the bar had not.
      expect(_label(tester, barTorIconKey), 'Tor, Off');
      expect(_label(tester, barLinkIconKey), 'Link, Off');
      // Right after the figure, on its line, each a full target.
      final figure = tester.getRect(find.byKey(titleFigureKey));
      final node = tester.getRect(find.byKey(barNodeIconKey));
      expect(node.left, greaterThanOrEqualTo(figure.right));
      expect(node.center.dy, closeTo(tester.getRect(find.byKey(balanceHeaderKey)).center.dy, 12));
      for (final key in [barNodeIconKey, barEpicboxIconKey, barTorIconKey, barLinkIconKey]) {
        final r = tester.getRect(find.byKey(key));
        expect(r.width, statusTarget, reason: '$key target');
        expect(r.height, statusTarget, reason: '$key target');
      }
      // Wallet's row is not on the header.
      expect(find.byKey(nodeStatusKey), findsNothing);
    });

    testWidgets('node down and Epicbox lost show the problem colour', (
      tester,
    ) async {
      await _pump(
        tester,
        child: header(),
        tip: AsyncError(StateError('down'), StackTrace.empty),
        listener: _lost,
      );
      final t = tokens(tester);
      expect(_label(tester, barNodeIconKey), 'Node, Not answering');
      expect(_dot(tester, barNodeIconKey), t.risk);
      expect(_label(tester, barEpicboxIconKey), 'Epicbox, Not connected');
      expect(_dot(tester, barEpicboxIconKey), t.risk);
    });

    testWidgets('Tor on: its icon lights up', (tester) async {
      await _pump(tester, child: header(), tor: _torReady);
      expect(_label(tester, barTorIconKey), 'Tor, Connected');
      expect(_dot(tester, barTorIconKey), tokens(tester).ok);
    });

    testWidgets('no Tor on this phone (the build without Tor): the header never names Tor, not even to a screen reader', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        child: header(),
        tor: const PhoneTorState(phase: PhoneTorPhase.unavailable),
      );
      expect(find.byKey(barTorIconKey), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Tor')), findsNothing);
      expect(_label(tester, barNodeIconKey), 'Node, Synced');
      handle.dispose();
    });

    testWidgets('a tap opens the connections sheet, its Node row the picker; a long press the sheet too', (tester) async {
      await _pump(tester, child: header());
      await tester.tap(find.byKey(barNodeIconKey));
      await tester.pumpAndSettle();
      expect(find.byKey(connectionsSheetKey), findsOneWidget);
      await tester.tap(find.descendant(of: find.byKey(connectionsSheetKey), matching: find.text('Node, Synced')));
      await tester.pumpAndSettle();
      expect(find.byType(ServerListSheet), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(barEpicboxIconKey));
      await tester.pumpAndSettle();
      expect(find.byKey(connectionsSheetKey), findsOneWidget);
    });

    for (final (width, scale, big) in [
      (360.0, 1.0, false),
      (360.0, 1.0, true),
      (360.0, 1.3, true),
      (320.0, 1.0, true),
    ]) {
      testWidgets('$width dp at $scale${big ? ', big balance' : ''}: icons and figure fit, the figure clear of them', (
        tester,
      ) async {
        final home = HomeData(
          summary: _summary(
            spendable: BigInt.parse(big ? '2100000000000000' : '3347000000'),
          ),
          transactions: const [],
        );
        await _pump(
          tester,
          child: header(),
          home: home,
          tor: _torReady,
          width: width,
          scale: scale,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final header_ = tester.getRect(find.byKey(balanceHeaderKey));
        final figure = tester.getRect(find.byKey(titleFigureKey));
        for (final key in [barNodeIconKey, barEpicboxIconKey, barTorIconKey, barLinkIconKey]) {
          final r = tester.getRect(find.byKey(key));
          expect(r.width, statusTarget, reason: '$key target');
          expect(r.right, lessThanOrEqualTo(header_.right + 0.5), reason: '$key');
          // Beside the figure, or on a row of their own when it takes the whole width.
          expect(
            r.left >= figure.right - 0.5 || r.top >= figure.bottom - 0.5 || r.bottom <= figure.top + 0.5,
            isTrue,
            reason: '$key clear of the figure',
          );
        }
        // The figure keeps its size while it fits, then shrinks to the floor at the least
        // (UP-002); it never runs past the header.
        final size = (tester.widget<Text>(find.byKey(titleFigureKey)).textSpan! as TextSpan).style?.fontSize;
        expect(size, inInclusiveRange(titleFigureFloor, titleFigureSize));
        expect(figure.right, lessThanOrEqualTo(header_.right + 0.5));
        expect(figure.height, greaterThan(0));
      });
    }
  });

  group('message checks on the connections sheet footer', () {
    final delay = appConfig.checkShowAfter;
    final lines = {
      '3 messages read': const CheckOutcome(messages: 3),
      '1 pairing did not complete': const CheckOutcome(failed: 1),
      '2 messages left for the next check': const CheckOutcome(held: 2),
      '3 messages turned away': const CheckOutcome(rejected: 1, dropped: 2),
      '1 message could not be read': const CheckOutcome(unreadable: 1),
      'More messages wait for the next check': const CheckOutcome(capped: 1),
    };

    Future<void> openSheet(WidgetTester tester, MessageChecks checks) async {
      await _pump(tester, checks: checks);
      await tester.tap(find.byKey(nodeStatusKey));
      await tester.pumpAndSettle();
      expect(find.byKey(connectionsSheetKey), findsOneWidget);
    }

    Finder inSheet(String text) => find.descendant(of: find.byKey(connectionsSheetKey), matching: find.textContaining(text));

    // The stream's event and the digest's zero timer need a frame or two to land.
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    MessageChecks make() {
      final c = MessageChecks(showAfter: delay, digestGrace: Duration.zero);
      addTearDown(c.dispose);
      return c;
    }

    testWidgets('no check yet: the footer says nothing', (tester) async {
      await openSheet(tester, make());
      for (final t in ['Checking messages', 'Checked', 'messages', 'could not be read', 'More messages']) {
        expect(inSheet(t), findsNothing, reason: t);
      }
    });

    testWidgets('"Checking messages" shows only after notices.check_show_after_ms, then "Checked just now" replaces it', (tester) async {
      final checks = make();
      await openSheet(tester, checks);
      final done = Completer<int>();
      final run = checks.run(CheckSource.collect, () => done.future, outcomeOf: (_) => const CheckOutcome());
      await tester.pump(delay - const Duration(milliseconds: 100));
      expect(inSheet('Checking messages'), findsNothing, reason: 'a quick check never shows');
      await tester.pump(const Duration(milliseconds: 150));
      expect(inSheet('Checking messages'), findsOneWidget);
      expect(inSheet('Checked just now'), findsNothing);
      done.complete(1);
      await run;
      await settle(tester);
      expect(inSheet('Checking messages'), findsNothing);
      expect(inSheet('Checked just now'), findsOneWidget);
    });

    testWidgets('a failed check says so', (tester) async {
      final checks = make();
      await openSheet(tester, checks);
      await expectLater(checks.run<int>(CheckSource.collect, () async => throw StateError('x'), outcomeOf: (_) => const CheckOutcome()), throwsStateError);
      await settle(tester);
      expect(inSheet('The last message check failed'), findsOneWidget);
      expect(inSheet('Checked just now'), findsNothing);
    });

    for (final MapEntry(key: line, value: outcome) in lines.entries) {
      testWidgets('"$line" shows for a report that has it and no other outcome line does', (tester) async {
        final checks = make();
        await openSheet(tester, checks);
        await checks.run(CheckSource.collect, () async => 1, outcomeOf: (_) => outcome);
        await settle(tester);
        expect(inSheet('Checked just now'), findsOneWidget);
        await tester.ensureVisible(find.byKey(messageCheckRowKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(messageCheckRowKey));
        await tester.pump(const Duration(milliseconds: 500));
        expect(inSheet(line), findsOneWidget);
        for (final other in lines.keys.where((k) => k != line)) {
          expect(inSheet(other), findsNothing, reason: other);
        }
      });
    }

    testWidgets('buffered and received counts add no line', (tester) async {
      final checks = make();
      await openSheet(tester, checks);
      await checks.run(CheckSource.drain, () async => 1, outcomeOf: (_) => const CheckOutcome(received: 4, buffered: 2));
      await settle(tester);
      expect(inSheet('Checked just now'), findsOneWidget);
      for (final other in lines.keys) {
        expect(inSheet(other), findsNothing, reason: other);
      }
    });
  });
}
