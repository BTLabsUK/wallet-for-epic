import 'dart:async';
import 'dart:math' as math;

import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart' as dir;
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/home_status.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart'
    show ReceiveTab, receiveTabProvider;
import 'package:epic_wallet/src/ui/server_list_sheet.dart' show ServerListSheet;
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

WalletSummary _summary({bool validated = true, int height = 2499990}) =>
    WalletSummary(
      lastConfirmedHeight: BigInt.from(height),
      minimumConfirmations: BigInt.from(3),
      total: BigInt.from(100),
      spendable: BigInt.from(100),
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

/// status.btlabs.uk down: no network tip, so a node that answers reads Synced.
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
        dir.relayDirectoryProvider.overrideWithValue(_Directory()),
        priceSourceProvider.overrideWithValue(_Price()),
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

String _tip_(WidgetTester tester, Key key) => tester
    .widget<Tooltip>(
      find.descendant(of: find.byKey(key), matching: find.byType(Tooltip)),
    )
    .message!;

IconData _icon(WidgetTester tester, Key key) => tester
    .widget<Icon>(
      find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
    )
    .icon!;

/// The colour of the state dot at the glyph's bottom right.
Color _dot(WidgetTester tester, Key key) {
  final box = tester.widget<Container>(
    find.descendant(of: find.byKey(key), matching: find.byType(Container)),
  );
  return (box.decoration! as BoxDecoration).color!;
}

WalletTokens _tokens2(WidgetTester tester) =>
    tester.element(find.byKey(netModeStatusKey)).tokens;

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
        '${_tip_(tester, nodeStatusKey)}\nShows the servers',
      );
      expect(_label(tester, epicboxStatusKey), 'Epicbox, Online');
      expect(_icon(tester, epicboxStatusKey), Icons.mark_email_read_outlined);
      expect(_dot(tester, epicboxStatusKey), t.ok);
      expect(
        _tip_(tester, epicboxStatusKey),
        'Epicbox connected\nServer: epicbox.epiccash.com:443',
      );
      // Tor off: no Tor, no Direct, and no Tor words on the two.
      expect(find.byKey(torIconKey), findsNothing);
      expect(find.byKey(directIconKey), findsNothing);
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
      expect(_label(tester, nodeStatusKey), 'Node, Syncing 40 %');
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
        // The glyph carries no state colour: the dot does, and the words.
        expect(tester.widget<Icon>(glyph).color, t.dim);
        final dot = tester.getRect(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(Container),
          ),
        );
        expect(dot.size, const Size(statusDotSize, statusDotSize));
        expect(dot.right, greaterThan(tester.getRect(glyph).right));
        expect(dot.bottom, greaterThan(tester.getRect(glyph).bottom));
      }
      // In order: Node, Epicbox, Tor, Direct.
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
        startsWith('Connecting to epicbox…'),
      );
    });

    testWidgets('offline: red', (tester) async {
      await _pump(
        tester,
        tip: AsyncError(StateError('down'), StackTrace.empty),
        listener: _lost,
      );
      final t = _tokens(tester);
      expect(_label(tester, nodeStatusKey), 'Node, Offline');
      expect(_icon(tester, nodeStatusKey), Icons.cloud_off);
      expect(_dot(tester, nodeStatusKey), t.risk);
      expect(_tip_(tester, nodeStatusKey), startsWith('Node unreachable.'));
      expect(_label(tester, epicboxStatusKey), 'Epicbox, Offline');
      expect(_icon(tester, epicboxStatusKey), Icons.unsubscribe_outlined);
      expect(_dot(tester, epicboxStatusKey), t.risk);
      expect(
        _tip_(tester, epicboxStatusKey),
        startsWith('Epicbox offline, reconnecting.'),
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
        'Off\nServer: epicbox.epiccash.com:443',
      );
    });

    testWidgets('a screen reader hears the service and the word', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, listener: _lost);
      expect(find.bySemanticsLabel('Node, Synced'), findsOneWidget);
      expect(find.bySemanticsLabel('Epicbox, Offline'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a tap opens the picker; a long press the tooltip', (
      tester,
    ) async {
      await _pump(tester);
      await tester.longPress(find.byKey(nodeStatusKey));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_tip_(tester, nodeStatusKey)), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      await tester.tap(find.byKey(nodeStatusKey));
      await tester.pumpAndSettle();
      expect(find.byType(ServerListSheet), findsOneWidget);
      expect(find.text('Node'), findsWidgets);
    });
  });

  group('Tor and Direct', () {
    testWidgets('starting: Tor blue and pulsing, the two wait for it, still', (
      tester,
    ) async {
      await _pump(tester, tor: _torStarting);
      final t = _tokens(tester);
      expect(_label(tester, torIconKey), 'Tor, Starting…');
      expect(_icon(tester, torIconKey), torIcon);
      expect(_dot(tester, torIconKey), t.info);
      expect(_tip_(tester, torIconKey), 'Connecting to Tor… 40%');
      expect(_hint(tester, torIconKey), endsWith('\nOpens the privacy settings'));
      expect(find.byKey(directIconKey), findsNothing);
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

    testWidgets('on and published: Tor and Direct green, the two over Tor', (
      tester,
    ) async {
      await _pump(tester, tor: _torReady);
      final t = _tokens(tester);
      expect(_label(tester, torIconKey), 'Tor, On');
      expect(_dot(tester, torIconKey), t.ok);
      expect(_tip_(tester, torIconKey), 'On');
      expect(_label(tester, directIconKey), 'Direct, Reachable');
      expect(_icon(tester, directIconKey), EpicGlyphs.http);
      expect(_dot(tester, directIconKey), t.ok);
      expect(_tip_(tester, directIconKey), 'Tor receiving is on');
      expect(
        _hint(tester, directIconKey),
        'Tor receiving is on\nOpens the Direct receive address',
      );
      expect(_label(tester, nodeStatusKey), 'Node, Synced, Over Tor');
      expect(_dot(tester, nodeStatusKey), t.ok);
      expect(_tip_(tester, nodeStatusKey), endsWith('\nOver Tor'));
      expect(_label(tester, epicboxStatusKey), 'Epicbox, Online, Over Tor');
      expect(_opacity(tester, torIconKey), 1);
    });

    testWidgets('publishing: Direct blue; unpublished: red', (tester) async {
      await _pump(tester, tor: _torPublishing);
      expect(_label(tester, directIconKey), 'Direct, Publishing…');
      expect(_dot(tester, directIconKey), _tokens(tester).info);
      // A new scope: a ProviderScope keeps the overrides it was built with.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, tor: _torUnpublished);
      expect(_label(tester, directIconKey), 'Direct, Not reachable');
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
      expect(find.byKey(directIconKey), findsNothing);
      for (final key in [nodeStatusKey, epicboxStatusKey]) {
        expect(_label(tester, key), endsWith(', Waiting for Tor'));
        expect(_dot(tester, key), t.risk);
        expect(_hint(tester, key), contains('Tor is not connected.'));
      }
    });

    testWidgets('no Tor on this phone: nothing of it', (tester) async {
      await _pump(
        tester,
        tor: const PhoneTorState(
          phase: PhoneTorPhase.unavailable,
          receiving: true,
        ),
      );
      expect(find.byKey(torIconKey), findsNothing);
      expect(find.byKey(directIconKey), findsNothing);
      expect(_label(tester, nodeStatusKey), 'Node, Synced');
    });

    testWidgets('a tap on Direct goes to Receive, Direct tab', (tester) async {
      await _pump(tester, tor: _torReady);
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(directIconKey)),
      );
      expect(container.read(shellTabProvider), ShellTab.wallet);
      await tester.tap(find.byKey(directIconKey));
      await tester.pump();
      expect(container.read(shellTabProvider), ShellTab.receive);
      expect(container.read(receiveTabProvider), ReceiveTab.direct);
    });
  });

  group('network mode', () {
    const offline = AdvancedPrefs(networkMode: NetworkMode.offline);
    const torOnly = AdvancedPrefs(networkMode: NetworkMode.torOnly);

    testWidgets('Standard: the icons, no mode word', (tester) async {
      await _pump(tester);
      expect(find.byKey(netModeStatusKey), findsNothing);
      expect(find.byKey(nodeStatusKey), findsOneWidget);
      expect(find.byKey(epicboxStatusKey), findsOneWidget);
    });

    testWidgets('Offline: the word in a neutral colour, still, in place of the icons', (
      tester,
    ) async {
      await _pump(tester, advanced: offline, tor: _torOff);
      final t = _tokens2(tester);
      expect(find.byKey(nodeStatusKey), findsNothing);
      expect(find.byKey(epicboxStatusKey), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(netModeStatusKey),
          matching: find.text('Offline'),
        ),
        findsOneWidget,
      );
      final word = tester.widget<Text>(
        find.descendant(
          of: find.byKey(netModeStatusKey),
          matching: find.text('Offline'),
        ),
      );
      expect(word.style?.color, t.dim);
      // No pulse: nothing animates, so the tree settles.
      await tester.pumpAndSettle();
      expect(_label(tester, netModeStatusKey), 'Offline');
      expect(_hint(tester, netModeStatusKey), contains('Offline mode is on in Advanced.'));
    });

    testWidgets('Tor only without Tor: Waiting for Tor in the in-progress colour', (
      tester,
    ) async {
      await _pump(tester, advanced: torOnly, tor: _torStarting);
      final t = _tokens2(tester);
      final word = tester.widget<Text>(
        find.descendant(
          of: find.byKey(netModeStatusKey),
          matching: find.text('Waiting for Tor'),
        ),
      );
      expect(word.style?.color, t.info);
      expect(find.byKey(nodeStatusKey), findsNothing);
      // Tor's own icon stays: it is how the user sees Tor start.
      expect(find.byKey(torIconKey), findsOneWidget);
    });

    testWidgets('Tor only with Tor connected: the icons are back', (
      tester,
    ) async {
      await _pump(tester, advanced: torOnly, tor: _torReady);
      expect(find.byKey(netModeStatusKey), findsNothing);
      expect(find.byKey(nodeStatusKey), findsOneWidget);
    });

    testWidgets('Offline keeps the last balance and marks the caption', (
      tester,
    ) async {
      await _pump(
        tester,
        child: const WalletBalance(),
        advanced: offline,
        tor: _torOff,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(balanceFigureKey), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(balanceCaptionKey)).data,
        'Available to spend · Offline',
      );
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
        expect(find.byKey(torIconKey), findsNothing);
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
        final eye = tester.getRect(find.byTooltip('Hide balances'));
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
}
