// SPDX-License-Identifier: Apache-2.0
// The balance and the rows under it tell one story: coins on hold are said plainly beside a
// spendable 0 (design review F-05), and a payment's row never says Received while the balance
// still counts it as confirming (one of the F-06 disagreements; Send's re-estimate is another,
// in send_test.dart).

import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/home_parts.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/shell_header.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations l = englishStrings;

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// The fake node's tip ([FakeWalletService.nodeTip]).
final BigInt _tip = BigInt.from(2500000);

final DateTime _now = DateTime(2026, 10, 13, 23);

int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  _Config(this.config);

  final WalletConfig config;

  @override
  WalletConfig? build() => config;
}

/// A summary as LEPIC reports it: it counts 3 confirmations whatever the app asks for, at
/// the height of its last refresh.
WalletSummary _summary({
  num spendable = 0,
  num confirming = 0,
  num waiting = 0,
  num locked = 0,
  num immature = 0,
  BigInt? height,
}) => WalletSummary(
  lastConfirmedHeight: height ?? _tip,
  minimumConfirmations: BigInt.from(3),
  total: _epic(spendable + confirming + locked + immature),
  spendable: _epic(spendable),
  awaitingConfirmation: _epic(confirming),
  awaitingFinalization: _epic(waiting),
  immature: _epic(immature),
  locked: _epic(locked),
  validatedWithNode: true,
);

/// Pumps home on [session], in the web demo when [demo], at [width] dp.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeWalletSession session, {
  bool demo = false,
  double width = 412,
  double textScale = 1,
}) async {
  // Demo adds its guide above Recent activity; a taller view builds every row.
  tester.view.physicalSize = Size(width * 3, (demo ? 1800 : 915) * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final chain = demo ? Chain.floonet : Chain.mainnet;
  final store = MemorySecretStore()
    ..values['wallet.${chain.name}.backedUp'] = '1';
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        demoModeProvider.overrideWithValue(demo),
        walletServiceProvider.overrideWithValue(
          FakeWalletService(session: session),
        ),
        secretStoreProvider.overrideWithValue(store),
        biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
        updatePlatformProvider.overrideWithValue(null),
        priceSourceProvider.overrideWithValue(_NoPrice()),
        qrScannerProvider.overrideWithValue(FakeQrScanner()),
        historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
        clockProvider.overrideWithValue(() => _now),
        sessionProvider.overrideWith(() => _OpenSession(session)),
        walletConfigProvider.overrideWith(
          () => _Config(
            (demo ? floonetPreset : mainnetPreset).config(
              dataDir: '/fake/wallets/${chain.name}',
              nodeUrl: 'https://node',
            ),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() => tester.pumpWidget(const SizedBox()));
  return ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// The words of the figure title on Send and Receive.
String _titleText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(titleFigureKey)).textSpan!.toPlainText();

/// [text] in the balance tile of [kind] on Wallet.
Finder _inTile(BalanceKind kind, String text) => find.descendant(
  of: find.byKey(balanceTileKey(kind)),
  matching: find.text(text),
);

/// What the only payment row says to a screen reader, which includes its status.
String _rowLabel(WidgetTester tester) => tester
    .widget<Semantics>(
      find
          .descendant(of: find.byType(TxTile), matching: find.byType(Semantics))
          .first,
    )
    .properties
    .label!;

void main() {
  test('what senders report posted leaves Waiting for sender for its own tile, never Total (LNX-13)', () {
    final tiles = balanceTiles(l, _summary(spendable: 1, waiting: 10), empty: false, senderPosted: _epic(4));
    expect(tiles.map((t) => (t.kind, t.label, t.value)), [
      (BalanceKind.waitingSender, l.homeTileWaitingSender, _epic(6)),
      (BalanceKind.senderPosted, l.txStatusSenderPosted, _epic(4)),
      (BalanceKind.total, l.homeTileTotal, _epic(1)),
    ]);
    // All of it reported: no Waiting for sender tile left.
    final all = balanceTiles(l, _summary(waiting: 4), empty: false, senderPosted: _epic(4));
    expect(all.map((t) => t.kind), [BalanceKind.senderPosted, BalanceKind.total]);
  });

  test('a send in flight: its change is not Waiting for sender; Total = spendable + confirming + locked', () {
    // 0.1 in one output; 0.01 sent with a 0.008 fee, not in a block yet: LEPIC locks the 0.1
    // and counts the 0.082 change as awaiting finalization, outside Total.
    TxEntry tx(TxKind kind, num credited, {String? transport, BigInt? height}) => TxEntry(
      key: 's:${kind.name}$credited',
      kind: kind,
      status: height == null ? TxStatus.awaitingConfirmation : TxStatus.confirmed,
      source: TxSource.wallet,
      createdAtUnix: 0,
      timeUnix: 0,
      confirmed: height != null,
      blockHeight: height,
      amountCredited: _epic(credited),
      amountDebited: kind == TxKind.sent ? _epic(0.1) : BigInt.zero,
      numInputs: 1,
      numOutputs: 1,
      outputCommits: const [],
      transport: transport,
      cancellable: false,
      repostable: false,
      releasable: false,
    );
    final summary = _summary(locked: 0.1, waiting: 0.082);
    final txs = [tx(TxKind.sent, 0.082)];
    expect(ownChangeOffChain(txs), _epic(0.082));
    final tiles = balanceTiles(l, summary, empty: false, ownChange: ownChangeOffChain(txs));
    expect(tiles.map((t) => (t.kind, t.value)), [
      (BalanceKind.locked, _epic(0.1)),
      (BalanceKind.total, _epic(0.1)),
    ]);
    expect(summary.total, summary.spendable + summary.awaitingConfirmation + summary.locked);
    // Someone else's payment beside it still waits for its sender; a confirmed send and a
    // received payment add no change.
    final more = [...txs, tx(TxKind.received, 2), tx(TxKind.sent, 5, height: BigInt.from(10))];
    expect(ownChangeOffChain(more), _epic(0.082));
    expect(
      balanceTiles(l, _summary(locked: 0.1, waiting: 2.082), empty: false, ownChange: ownChangeOffChain(more))
          .map((t) => (t.kind, t.value)),
      [(BalanceKind.waitingSender, _epic(2)), (BalanceKind.locked, _epic(0.1)), (BalanceKind.total, _epic(0.1))],
    );
    // A split's receiving side is the wallet's own too.
    expect(ownChangeOffChain([tx(TxKind.received, 3, transport: 'self')]), _epic(3));
  });

  group('every figure shows four decimals, the exact amount a tap away', () {
    testWidgets('Wallet and the Send header cut to four decimals; a tap opens the balance sheet', (
      tester,
    ) async {
      final session = FakeWalletSession(summary: _summary(spendable: 1234.56781234));
      await _pump(tester, session, width: 360);
      expect(tester.widget<Text>(find.byKey(balanceFigureKey)).data, '1,234.5678');
      expect(find.text('1,234.56781234 EPIC'), findsNothing);
      await tester.tap(find.byKey(balanceFigureKey));
      await tester.pumpAndSettle();
      expect(find.byKey(balanceSheetKey), findsOneWidget);
      // Total and Spendable are the same here: both rows say it in full.
      expect(find.text('1,234.56781234 EPIC'), findsNWidgets(2));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byKey(balanceSheetKey), findsNothing);
      // The screen reader hears the exact amount without the tap.
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp(r'1,234\.56781234 EPIC')),
        findsWidgets,
      );
      handle.dispose();

      await _tab(tester, l.homeSendButton);
      expect(_titleText(tester), startsWith('1,234.5678'));
      await tester.tap(find.byKey(titleFigureKey));
      await tester.pumpAndSettle();
      expect(find.byKey(balanceSheetKey), findsOneWidget);
      expect(find.text('1,234.56781234 EPIC'), findsNWidgets(2));
    });

    testWidgets('hidden balances show dots and tell nothing on a tap', (tester) async {
      final session = FakeWalletSession(summary: _summary(spendable: 1234.56781234));
      final container = await _pump(tester, session, width: 360);
      await container.read(appSettingsProvider.notifier).setHideBalances(true);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(balanceFigureKey)).data, hiddenAmount);
      await tester.tap(find.byKey(balanceFigureKey));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('1,234.56781234'), findsNothing);
      expect(
        find.ancestor(of: find.byKey(balanceFigureKey), matching: find.byType(Tooltip)),
        findsNothing,
      );
    });
  });

  group('coins on hold beside a spendable 0', () {
    testWidgets('a spendable 0 says what is on hold and coming in, plainly', (
      tester,
    ) async {
      // The review's split: 2.5 of 10 EPIC sent, the 10 locked, its change confirming.
      final session = FakeWalletSession(
        summary: _summary(locked: 10, confirming: 7.492),
      );
      await _pump(tester, session, width: 360);
      expect(tester.widget<Text>(find.byKey(balanceFigureKey)).data, '0.0000');
      // Wallet says it in tiles: the 10 locked in sends and the 7.492 confirming.
      for (final (kind, text) in [
        (BalanceKind.locked, '10.0000'),
        (BalanceKind.confirming, '7.4920'),
      ]) {
        expect(_inTile(kind, text).hitTestable(), findsOneWidget, reason: text);
      }
      // They stand still, and nothing runs to move them.
      final at = tester.getRect(_inTile(BalanceKind.locked, '10.0000'));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.getRect(_inTile(BalanceKind.locked, '10.0000')), at);
      expect(tester.binding.hasScheduledFrame, isFalse);

      // The header on Send and Receive agrees: the same 0, and the same amounts as tokens
      // (the test font is wide, so the line may be collapsed; a screen reader hears each).
      final handle = tester.ensureSemantics();
      for (final tab in [l.homeSendButton, l.homeReceiveButton]) {
        await _tab(tester, tab);
        expect(_titleText(tester), startsWith('0'), reason: tab);
        for (final text in ['10.0000 locked', '+7.4920 coming in']) {
          expect(
            find.bySemanticsLabel(RegExp(RegExp.escape(text))),
            findsOneWidget,
            reason: '$tab: $text',
          );
        }
      }
      handle.dispose();
    });

    testWidgets(
      'a tile per pending balance; the header keeps three tokens: locked, '
      'everything on chain coming in, and not on chain yet',
      (tester) async {
        final session = FakeWalletSession(
          summary: _summary(
            spendable: 3.25,
            confirming: 2,
            waiting: 0.5,
            locked: 5,
            immature: 16,
          ),
        );
        await _pump(tester, session, width: 360);
        // Wallet: every balance that is not zero, then Total.
        final tiles = balanceTiles(l, session.summaryValue, empty: false);
        expect(tiles.map((t) => (t.kind, t.label, t.value)), [
          (BalanceKind.confirming, l.homeBalanceConfirming, _epic(2)),
          (BalanceKind.waitingSender, l.homeTileWaitingSender, _epic(0.5)),
          (BalanceKind.locked, l.homeTileLocked, _epic(5)),
          (BalanceKind.total, l.homeTileTotal, _epic(26.25)),
        ]);
        expect(_inTile(BalanceKind.confirming, '2.0000'), findsOneWidget);
        // Send and Receive keep three tokens: 5 locked, 2 confirming and 16 maturing coming
        // in, and the 0.5 not on chain yet apart (never counted as coming in).
        await _tab(tester, l.homeSendButton);
        final handle = tester.ensureSemantics();
        for (final text in ['5.0000 locked', '+18.0000 coming in', 'Not on chain yet: 0.5000']) {
          expect(
            find.bySemanticsLabel(RegExp(RegExp.escape(text))),
            findsOneWidget,
            reason: text,
          );
        }
        handle.dispose();
        // The ? still lists each balance with its own words.
        final rows = BalanceHelp.rows(l, session.summaryValue);
        expect(rows.map((r) => r.$1), [
          l.balanceTotal,
          l.homeBalanceSpendable,
          l.homeBalanceConfirming,
          l.homeBalanceNotOnChain,
          l.homeBalanceLocked,
          l.homeBalanceImmature,
        ]);
      },
    );

    testWidgets('a payment not on chain yet is never counted as coming in', (
      tester,
    ) async {
      // Someone offered a large payment and never finished it.
      final session = FakeWalletSession(
        summary: _summary(spendable: 1, waiting: 1000000),
      );
      await _pump(tester, session, width: 360);
      expect(find.textContaining('coming in'), findsNothing);
      // Not a Confirming tile either: it waits for the sender, and says so.
      expect(find.byKey(balanceTileKey(BalanceKind.confirming)), findsNothing);
      expect(_inTile(BalanceKind.waitingSender, '1,000,000.0000'), findsOneWidget);
      await _tab(tester, l.homeSendButton);
      expect(find.textContaining('coming in'), findsNothing);
      // The header names it for what it is, not on chain yet, never as coming in.
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp('coming in')), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape('Not on chain yet: 1,000,000.0000'))),
        findsOneWidget,
      );
      handle.dispose();
      final rows = BalanceHelp.rows(l, session.summaryValue);
      expect(rows.map((r) => r.$1), [
        l.balanceTotal,
        l.homeBalanceSpendable,
        l.homeBalanceNotOnChain,
      ]);
      expect(rows.first.$2, _epic(1));
      expect(comingIn(session.summaryValue), BigInt.zero);
    });

    testWidgets('fits a 360 dp phone at text scale 2', (tester) async {
      final session = FakeWalletSession(
        summary: _summary(locked: 7.49283746, confirming: 6.48473625),
      );
      await _pump(tester, session, width: 360, textScale: 2);
      expect(tester.takeException(), isNull);
      // The tiles grow with the text; the first is whole, the others scroll in.
      expect(
        _inTile(BalanceKind.confirming, '6.4847').hitTestable(),
        findsOneWidget,
      );
      expect(find.byKey(balanceTileKey(BalanceKind.locked)), findsOneWidget);
      await _tab(tester, l.homeSendButton);
      expect(tester.takeException(), isNull);
    });
  });

  group('a payment row and the balance agree on confirmations', () {
    // Bob's wallet in the review: the payment is in block 220, the node is there too, but
    // the balance comes from a refresh that read the chain at 219 and counts 10.
    TxEntry received({required BigInt height}) => fakeTx(
      id: 7,
      slateId: 'from-alice',
      kind: TxKind.received,
      status: TxStatus.confirmed,
      createdAtUnix: _at(_now.subtract(const Duration(minutes: 2))),
      blockHeight: height,
      amountCredited: _epic(2.5),
      counterparty: 'esAlice123@epicbox.epiccash.com',
    );

    for (final demo in [true, false]) {
      testWidgets('a confirming balance never sits under a Received row '
          '(demo ${demo ? 'on' : 'off'})', (tester) async {
        final session = FakeWalletSession(
          summary: _summary(
            spendable: 10,
            confirming: 2.5,
            height: _tip - BigInt.one,
          ),
          transactions: [received(height: _tip)],
        );
        await _pump(tester, session, demo: demo);
        expect(_rowLabel(tester), isNot(contains('received,')));
        expect(find.textContaining(l.txStatusReceived), findsNothing);
        expect(find.textContaining(l.txStatusConfirming(0, 3)), findsOneWidget);
        expect(_inTile(BalanceKind.confirming, '2.5000'), findsOneWidget);

        // The next refresh reaches block 228: three confirmations, both say so.
        session.summaryValue = _summary(
          spendable: 12.5,
          height: _tip + BigInt.from(2),
        );
        await tester.pump(autoRefreshInterval);
        await tester.pumpAndSettle();
        expect(
          find.byKey(balanceTileKey(BalanceKind.confirming)),
          findsNothing,
        );
        expect(find.textContaining(l.txStatusReceived), findsOneWidget);
      });
    }

    testWidgets('a tip ahead of the summary does not complete a row early', (
      tester,
    ) async {
      // The node is 3 blocks past the refresh: counted at the node's tip the row would be
      // 4 deep, at the summary's height it is 1, which is what the balance says.
      final session = FakeWalletSession(
        summary: _summary(
          spendable: 10,
          confirming: 2.5,
          height: _tip - BigInt.from(3),
        ),
        transactions: [received(height: _tip - BigInt.from(3))],
      );
      await _pump(tester, session);
      expect(find.textContaining(l.txStatusConfirming(1, 3)), findsOneWidget);
      expect(find.textContaining(l.txStatusReceived), findsNothing);
    });
  });
}
