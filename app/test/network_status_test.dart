import 'dart:async';

import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart' as dir;
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/info_hint.dart';
import 'package:epic_wallet/src/ui/network_status.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/ui/tor_ui.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

WalletSummary _summary() => WalletSummary(
  lastConfirmedHeight: BigInt.from(2500000),
  minimumConfirmations: BigInt.from(3),
  total: BigInt.from(100),
  spendable: BigInt.from(100),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
);

final NodeTip _tip = NodeTip(
  height: BigInt.from(2500000),
  nodeVersion: '4.1.1',
);

class _Home extends HomeNotifier {
  _Home(this.data);

  final HomeData data;

  @override
  Future<HomeData> build() async => data;
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
  _Config(this.preset, this.nodeUrl);

  final NetworkPreset preset;
  final String nodeUrl;

  @override
  WalletConfig? build() => preset.config(dataDir: '/fake', nodeUrl: nodeUrl);
}

class _Tor extends PhoneTor {
  _Tor(this.value);

  final PhoneTorState value;

  @override
  PhoneTorState build() => value;
}

/// status.btlabs.uk: the network tip when given, else no answer.
class _Directory
    implements dir.RelayDirectory, dir.NodeDirectory, dir.NetworkDirectory {
  _Directory({this.tip});

  final int? tip;

  @override
  Future<dir.NetworkStatus> network(String chain) async => tip == null
      ? throw const NetError('down')
      : dir.NetworkStatus(tipHeight: tip);

  @override
  Future<List<dir.NodeStatus>> nodes(String chain) async =>
      throw const NetError('down');

  @override
  Future<List<dir.RelayStatus>> relays(String chain) async =>
      throw const NetError('down');
}

Future<void> _pump(
  WidgetTester tester, {
  AsyncValue<NodeTip>? tip,
  bool syncing = false,
  int? percent,
  ListenerState listener = const ListenerState(connected: true),
  PhoneTorState tor = const PhoneTorState(phase: PhoneTorPhase.off),
  NetworkPreset preset = mainnetPreset,
  String nodeUrl = 'https://node.example.org',
  int? networkTip,
  Locale? locale,
  double scale = 1,
}) async {
  final t = tip ?? AsyncData(_tip);
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
        homeProvider.overrideWith(
          () => _Home(
            HomeData(
              summary: _summary(),
              transactions: const [],
              syncing: syncing,
            ),
          ),
        ),
        syncProgressProvider.overrideWith(() => _Progress(percent)),
        listenerProvider.overrideWith(() => _Listener(listener)),
        walletConfigProvider.overrideWith(() => _Config(preset, nodeUrl)),
        secretStoreProvider.overrideWithValue(
          MemorySecretStore({'app.network': preset.chain.name}),
        ),
        phoneTorProvider.overrideWith(() => _Tor(tor)),
        dir.relayDirectoryProvider.overrideWithValue(
          _Directory(tip: networkTip),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: NetworkStatusCard(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  // Offline and syncing show once they last (walletStatusProvider).
  await tester.pump(statusSettle);
}

Finder _in(Key row, String text) =>
    find.descendant(of: find.byKey(row), matching: find.text(text));

void main() {
  group('node row', () {
    testWidgets('synced: the host and the word', (tester) async {
      await _pump(tester);
      expect(_in(netStatusNodeKey, 'Node'), findsOneWidget);
      expect(_in(netStatusNodeKey, 'node.example.org'), findsOneWidget);
      expect(_in(netStatusNodeKey, 'Synced'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(netStatusNodeKey)).label,
        'Node online, node.example.org, Synced',
      );
      expect(
        tester.getSemantics(find.byKey(netStatusNodeKey)).hint,
        contains('Node: node.example.org'),
      );
      expect(tester.getSize(find.byKey(netStatusNodeKey)).height, 56);
    });

    testWidgets('syncing with a percent', (tester) async {
      await _pump(tester, syncing: true, percent: 42);
      expect(_in(netStatusNodeKey, 'Syncing 42 %'), findsOneWidget);
    });

    testWidgets('syncing without a percent, while the wallet is behind the tip', (tester) async {
      await _pump(tester, syncing: true, tip: AsyncData(NodeTip(height: BigInt.from(2500020), nodeVersion: '3.6.0')));
      expect(_in(netStatusNodeKey, 'Syncing'), findsOneWidget);
    });

    testWidgets('android-04: a refresh at the tip reads synced, not syncing', (tester) async {
      await _pump(tester, syncing: true);
      expect(_in(netStatusNodeKey, 'Syncing'), findsNothing);
    });

    testWidgets('connecting while the node has not answered', (tester) async {
      await _pump(tester, tip: const AsyncLoading());
      expect(_in(netStatusNodeKey, 'Connecting'), findsOneWidget);
    });

    testWidgets('offline when the node fails', (tester) async {
      await _pump(tester, tip: AsyncError(StateError('no'), StackTrace.empty));
      expect(_in(netStatusNodeKey, 'Offline'), findsOneWidget);
    });

    testWidgets('behind when the network is ahead', (tester) async {
      await _pump(tester, networkTip: 2500012);
      expect(_in(netStatusNodeKey, 'Behind 12'), findsOneWidget);
    });

    testWidgets('a block or two behind still reads synced', (tester) async {
      await _pump(tester, networkTip: 2500002);
      expect(_in(netStatusNodeKey, 'Synced'), findsOneWidget);
    });

    testWidgets('a port that is not the default stays; the scheme goes', (
      tester,
    ) async {
      await _pump(tester, nodeUrl: 'https://node.epicnet.us:3413');
      expect(_in(netStatusNodeKey, 'node.epicnet.us:3413'), findsOneWidget);
    });

    testWidgets('a test network names itself before the host', (tester) async {
      await _pump(
        tester,
        preset: floonetPreset,
        nodeUrl: 'https://floo-node.btlabs.uk',
      );
      expect(
        _in(netStatusNodeKey, 'Floonet · floo-node.btlabs.uk'),
        findsOneWidget,
      );
    });
  });

  group('epicbox row', () {
    for (final (listener, word) in [
      (const ListenerState(connected: true), 'Connected'),
      (const ListenerState(), 'Connecting'),
      (const ListenerState(lost: true), 'Not connected'),
      (const ListenerState(stopped: true), 'Off'),
    ]) {
      testWidgets(word, (tester) async {
        await _pump(tester, listener: listener);
        expect(_in(netStatusEpicboxKey, word), findsOneWidget);
        expect(
          _in(netStatusEpicboxKey, 'epicbox.epiccash.com'),
          findsOneWidget,
        );
      });
    }
  });

  group('tor row', () {
    testWidgets('shown while Tor is off: Off, faint', (tester) async {
      await _pump(tester);
      expect(find.byKey(netStatusTorKey), findsOneWidget);
      expect(_in(netStatusTorKey, 'Tor network'), findsOneWidget);
      // The explanation is the info icon's tooltip, not a line of the row.
      expect(find.descendant(of: find.byKey(netStatusTorKey), matching: find.byType(InfoHint)), findsOneWidget);
      expect(find.textContaining('go through Tor'), findsNothing);
      final word = tester.widget<Text>(_in(netStatusTorKey, 'Off'));
      final t = tester.element(find.byKey(netStatusTorKey)).tokens;
      expect(word.style?.color, t.faint);
    });

    testWidgets('hidden where there is no Tor', (tester) async {
      await _pump(
        tester,
        tor: const PhoneTorState(phase: PhoneTorPhase.unavailable),
      );
      expect(find.byKey(netStatusTorKey), findsNothing);
    });

    for (final (state, word) in [
      (
        const PhoneTorState(receiving: true, phase: PhoneTorPhase.starting, progress: 40),
        'Starting…',
      ),
      (const PhoneTorState(receiving: true, phase: PhoneTorPhase.connected), 'On'),
      (const PhoneTorState(receiving: true, phase: PhoneTorPhase.ready), 'On'),
      (
        const PhoneTorState(receiving: true, phase: PhoneTorPhase.failed,
          failure: TorFailure.network,
        ),
        'Not connected',
      ),
    ]) {
      testWidgets('shown while ${state.phase.name}: $word', (tester) async {
        await _pump(tester, tor: state);
        expect(_in(netStatusTorKey, word), findsOneWidget);
      });
    }

    for (final (state, word, ok) in [
      (const PhoneTorState(receiving: true, phase: PhoneTorPhase.ready), 'On', true),
      (
        const PhoneTorState(receiving: true, phase: PhoneTorPhase.failed),
        'Not connected',
        false,
      ),
    ]) {
      testWidgets('$word in the ${ok ? 'ok' : 'risk'} colour', (tester) async {
        await _pump(tester, tor: state);
        final t = tester.element(find.byKey(netStatusTorKey)).tokens;
        expect(
          tester.widget<Text>(_in(netStatusTorKey, word)).style?.color,
          ok ? t.ok : t.risk,
        );
      });
    }

    testWidgets('Tor on: the Epicbox and node rows are marked over Tor', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, tor: const PhoneTorState(receiving: true, phase: PhoneTorPhase.ready));
      final t = tester.element(find.byKey(netStatusTorKey)).tokens;
      for (final row in [netStatusEpicboxKey, netStatusNodeKey]) {
        expect(tester.widget<Text>(_in(row, 'Over Tor')).style?.color, t.ok);
        expect(
          find.descendant(of: find.byKey(row), matching: find.byIcon(torIcon)),
          findsOneWidget,
        );
      }
      expect(_in(netStatusEpicboxKey, 'Connected'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Epicbox.*, Connected, over Tor$')),
        findsOneWidget,
      );
      // The node goes over Tor too (LEPIC E-12).
      expect(_in(netStatusNodeKey, 'Synced'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Node.*over Tor$')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Tor on while it connects (sends only): still over Tor', (tester) async {
      await _pump(
        tester,
        tor: const PhoneTorState(receiving: true, phase: PhoneTorPhase.connected),
      );
      expect(_in(netStatusEpicboxKey, 'Over Tor'), findsOneWidget);
      expect(_in(netStatusNodeKey, 'Over Tor'), findsOneWidget);
    });

    testWidgets('Tor off: no Tor line on the Epicbox and node rows', (tester) async {
      await _pump(tester);
      expect(find.text('Over Tor'), findsNothing);
      expect(find.text('Waiting for Tor'), findsNothing);
      expect(
        find.descendant(of: find.byKey(netStatusEpicboxKey), matching: find.byIcon(torIcon)),
        findsNothing,
      );
    });

    testWidgets('Tor starting: waiting for Tor, warn', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        tor: const PhoneTorState(receiving: true, phase: PhoneTorPhase.starting),
      );
      final t = tester.element(find.byKey(netStatusTorKey)).tokens;
      for (final row in [netStatusEpicboxKey, netStatusNodeKey]) {
        expect(
          tester.widget<Text>(_in(row, 'Waiting for Tor')).style?.color,
          t.warn,
        );
      }
      expect(_in(netStatusEpicboxKey, 'Connected'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Epicbox.*, Connected, Waiting for Tor$')),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byKey(netStatusEpicboxKey)).hint,
        isNot(contains('Tor is not connected')),
      );
      handle.dispose();
    });

    testWidgets('Tor failed: waiting for Tor, risk, Tor is not connected', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        tor: const PhoneTorState(
          receiving: true,
          phase: PhoneTorPhase.failed,
          failure: TorFailure.network,
        ),
      );
      final t = tester.element(find.byKey(netStatusTorKey)).tokens;
      for (final row in [netStatusEpicboxKey, netStatusNodeKey]) {
        expect(
          tester.widget<Text>(_in(row, 'Waiting for Tor')).style?.color,
          t.risk,
        );
        expect(
          tester.getSemantics(find.byKey(row)).hint,
          startsWith('Tor is not connected.'),
        );
      }
      expect(
        find.bySemanticsLabel(RegExp(r'^Node.*, Waiting for Tor$')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a node on this computer stays direct: no Tor line', (tester) async {
      await _pump(
        tester,
        nodeUrl: 'http://127.0.0.1:3413',
        tor: const PhoneTorState(receiving: true, phase: PhoneTorPhase.ready),
      );
      expect(_in(netStatusNodeKey, 'Over Tor'), findsNothing);
      expect(_in(netStatusEpicboxKey, 'Over Tor'), findsOneWidget);
    });

    // The owner saw no mark: a long state word in a large font cut " · Tor" off its end. The
    // icon now leads a line of its own.
    for (final (locale, word) in [
      (const Locale('pl'), 'Przez Tor'),
      (const Locale('de'), 'Über Tor'),
      (const Locale('ru'), 'Через Tor'),
    ]) {
      testWidgets('the mark stays at 130 % in ${locale.languageCode}', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pump(
          tester,
          locale: locale,
          scale: 1.3,
          networkTip: 2500012,
          tor: const PhoneTorState(receiving: true, phase: PhoneTorPhase.ready),
        );
        expect(tester.takeException(), isNull);
        for (final row in [netStatusEpicboxKey, netStatusNodeKey]) {
          expect(
            find.descendant(of: find.byKey(row), matching: find.byIcon(torIcon)),
            findsOneWidget,
          );
          final text = _in(row, word);
          expect(text, findsOneWidget);
          final para = tester.renderObject<RenderParagraph>(text);
          expect(para.didExceedMaxLines, isFalse, reason: '$word cut off');
        }
      });
    }
  });

  testWidgets('every row meets the tap target guideline', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, tor: const PhoneTorState(receiving: true, phase: PhoneTorPhase.ready));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
