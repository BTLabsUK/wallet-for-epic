import 'dart:async';
import 'dart:math' as math;

import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  group('walletStatus', () {
    test('a running refresh is syncing, with its percent', () {
      final s = walletStatus(
        tip: AsyncData(_tip),
        syncing: true,
        percent: 40,
        summary: _summary(),
        listener: _connected,
      );
      expect(s.node.state, NodeState.syncing);
      expect(s.node.percent, 40);
      expect(s.epicbox, EpicboxState.online);
    });

    test('a failed tip is offline, even with checked balances', () {
      final s = walletStatus(
        tip: AsyncError(StateError('down'), StackTrace.empty),
        syncing: false,
        summary: _summary(),
        listener: _connecting,
      );
      expect(s.node.state, NodeState.offline);
      expect(s.node.validated, isTrue);
      expect(s.epicbox, EpicboxState.connecting);
    });

    test('balances the node did not check are offline, not validated', () {
      final s = walletStatus(
        tip: AsyncData(_tip),
        syncing: false,
        summary: _summary(validated: false),
        listener: _lost,
      );
      expect(s.node.state, NodeState.offline);
      expect(s.node.validated, isFalse);
      expect(s.epicbox, EpicboxState.offline);
    });

    test('a tip is online; the height is the checked one, else the tip', () {
      final checked = walletStatus(
        tip: AsyncData(_tip),
        syncing: false,
        summary: _summary(),
        listener: _connected,
      );
      expect(checked.node.state, NodeState.online);
      expect(checked.node.height, BigInt.from(2499990));
      final fresh = walletStatus(
        tip: AsyncData(_tip),
        syncing: false,
        summary: _summary(height: 0),
        listener: _connected,
      );
      expect(fresh.node.height, BigInt.from(2500000));
    });

    test('no answer yet is connecting; a stopped listener has no status', () {
      final s = walletStatus(
        tip: const AsyncLoading(),
        syncing: false,
        listener: _stopped,
      );
      expect(s.node.state, NodeState.connecting);
      expect(s.epicbox, isNull);
    });
  });

  group('status rows', () {
    Future<void> pump(
      WidgetTester tester, {
      required AsyncValue<NodeTip> tip,
      HomeData? home,
      int? percent,
      required ListenerState listener,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            nodeTipProvider.overrideWith(
              (ref) => switch (tip) {
                AsyncData(:final value) => Future.value(value),
                AsyncError(:final error) => Future<NodeTip>.error(error),
                _ => Completer<NodeTip>().future,
              },
            ),
            homeProvider.overrideWith(() => _Home(home)),
            syncProgressProvider.overrideWith(() => _Progress(percent)),
            listenerProvider.overrideWith(() => _Listener(listener)),
            walletConfigProvider.overrideWith(_Config.new),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: Center(child: StatusIcons())),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      // Offline and syncing show once they last (walletStatusProvider).
      await tester.pump(statusSettle);
    }

    /// What a screen reader says for the status: the icon shows no words.
    String word(WidgetTester tester, Key key) => tester
        .widget<Semantics>(
          find
              .descendant(
                of: find.byKey(key),
                matching: find.byWidgetPredicate(
                  (w) => w is Semantics && w.properties.label != null,
                ),
              )
              .first,
        )
        .properties
        .label!;

    String tip(WidgetTester tester, Key key) => tester
        .widget<Tooltip>(
          find.descendant(of: find.byKey(key), matching: find.byType(Tooltip)),
        )
        .message!;

    IconData icon(WidgetTester tester, Key key) => tester
        .widget<Icon>(
          find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
        )
        .icon!;

    final home = HomeData(summary: _summary(), transactions: const []);

    testWidgets('node online: host, block and version in the tooltip', (
      tester,
    ) async {
      await pump(
        tester,
        tip: AsyncData(_tip),
        home: home,
        listener: _connected,
      );
      expect(word(tester, nodeStatusKey), 'Node online');
      expect(icon(tester, nodeStatusKey), Icons.cloud_done_outlined);
      expect(
        tip(tester, nodeStatusKey),
        'Up to date.\nNode: node.example.org\nSynced at block 2,499,990\n'
        'Node version 3.6.0',
      );
      expect(word(tester, epicboxStatusKey), 'Epicbox online');
      expect(icon(tester, epicboxStatusKey), Icons.mark_email_read_outlined);
      expect(
        tip(tester, epicboxStatusKey),
        'Epicbox connected\nServer: epicbox.epiccash.com:443',
      );
    });

    testWidgets('node syncing with its percent', (tester) async {
      await pump(
        tester,
        tip: AsyncData(_tip),
        home: HomeData(
          summary: _summary(),
          transactions: const [],
          syncing: true,
        ),
        percent: 40,
        listener: _connected,
      );
      expect(word(tester, nodeStatusKey), 'Node syncing 40%');
      expect(icon(tester, nodeStatusKey), Icons.sync);
      expect(tip(tester, nodeStatusKey), startsWith('Syncing… 40%'));
      // The syncing node pulses; epicbox does not.
      double opacity(Key key) => tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value;
      final node = <double>{}, epicbox = <double>{};
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        node.add(opacity(nodeStatusKey));
        epicbox.add(opacity(epicboxStatusKey));
      }
      expect(node.length, greaterThan(3));
      expect(node.reduce(math.min), greaterThanOrEqualTo(0.45));
      expect(epicbox, {1.0});
    });

    testWidgets('icons only, each on a 48 dp target', (tester) async {
      await pump(
        tester,
        tip: AsyncData(_tip),
        home: home,
        listener: _connected,
      );
      expect(find.byType(Text), findsNothing);
      for (final key in [nodeStatusKey, epicboxStatusKey]) {
        expect(tester.getSize(find.byKey(key)), const Size(48, 48));
        final glyph = tester.getRect(
          find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
        );
        expect(glyph.size, const Size(statusGlyph, statusGlyph));
        expect(glyph.left - tester.getRect(find.byKey(key)).left, statusInset);
      }
    });

    testWidgets('node connecting, epicbox connecting', (tester) async {
      await pump(
        tester,
        tip: const AsyncLoading(),
        home: home,
        listener: _connecting,
      );
      expect(word(tester, nodeStatusKey), 'Node connecting');
      expect(icon(tester, nodeStatusKey), Icons.cloud_queue);
      expect(tip(tester, nodeStatusKey), startsWith('Contacting node…'));
      expect(word(tester, epicboxStatusKey), 'Epicbox connecting');
      expect(icon(tester, epicboxStatusKey), Icons.mail_outline);
      expect(
        tip(tester, epicboxStatusKey),
        startsWith('Connecting to epicbox…'),
      );
    });

    testWidgets('node offline and epicbox offline', (tester) async {
      await pump(
        tester,
        tip: AsyncError(StateError('down'), StackTrace.empty),
        home: home,
        listener: _lost,
      );
      expect(word(tester, nodeStatusKey), 'Node offline');
      expect(icon(tester, nodeStatusKey), Icons.cloud_off);
      expect(tip(tester, nodeStatusKey), startsWith('Node unreachable.'));
      expect(word(tester, epicboxStatusKey), 'Epicbox offline');
      expect(icon(tester, epicboxStatusKey), Icons.unsubscribe_outlined);
      expect(
        tip(tester, epicboxStatusKey),
        startsWith('Epicbox offline, reconnecting.'),
      );
    });

    testWidgets('a stopped listener shows no epicbox row', (tester) async {
      await pump(tester, tip: AsyncData(_tip), home: home, listener: _stopped);
      expect(find.byKey(nodeStatusKey), findsOneWidget);
      expect(find.byKey(epicboxStatusKey), findsNothing);
    });

    testWidgets('a screen reader hears the kind and the word', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, tip: AsyncData(_tip), home: home, listener: _lost);
      expect(find.bySemanticsLabel('Node online'), findsOneWidget);
      expect(find.bySemanticsLabel('Epicbox offline'), findsOneWidget);
      handle.dispose();
    });
  });
}
