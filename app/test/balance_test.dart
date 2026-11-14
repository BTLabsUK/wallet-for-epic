// SPDX-License-Identifier: Apache-2.0
// The balance and the rows under it tell one story: coins on hold are said plainly beside a
// spendable 0 (design review F-05), and a payment's row never says Received while the balance
// still counts it as confirming (one of the F-06 disagreements; Send's re-estimate is another,
// in send_test.dart).

import 'package:epic_wallet/src/amount.dart' show epicFor;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/home_parts.dart';
import 'package:epic_wallet/src/ui/home_tab.dart' show homeFigureKey;
import 'package:epic_wallet/src/ui/phone_tx_row.dart' show PhoneTxRow;
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'support/fake_history_files.dart';
import 'package:epic_wallet/src/ui/shell_header.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'support/shell_where.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/amounts.dart';

final AppLocalizations l = englishStrings;

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
  total: epic(spendable + confirming + locked + immature),
  spendable: epic(spendable),
  awaitingConfirmation: epic(confirming),
  awaitingFinalization: epic(waiting),
  immature: epic(immature),
  locked: epic(locked),
  validatedWithNode: true,
);

/// Pumps home on [session] at [width] dp.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeWalletSession session, {
  double width = 412,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, 915 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  const chain = Chain.mainnet;
  final store = MemorySecretStore()
    ..values['wallet.${chain.name}.backedUp'] = '1';
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
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
            mainnetPreset.config(
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
  await shellGo(tester, label);
  await _clearToast(tester);
}

/// The notice toast floats over the top and takes the touches there: close what shows.
Future<void> _clearToast(WidgetTester tester) async {
  final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));
  for (var i = 0; i < 5 && container.read(noticeProvider) != null; i++) {
    container.read(noticeProvider.notifier).dismiss();
    await tester.pumpAndSettle();
  }
}

/// The words of Home's figure.
String _figure(WidgetTester tester) =>
    (tester.widget<Text>(find.byKey(homeFigureKey)).textSpan!).toPlainText();

/// What the only payment row says to a screen reader, which includes its status.
String _rowLabel(WidgetTester tester) => tester
    .widget<Semantics>(
      find
          .descendant(of: find.byType(PhoneTxRow), matching: find.byType(Semantics))
          .first,
    )
    .properties
    .label!;

void main() {
  test('what senders report posted leaves Waiting for sender for its own tile, never Total (LNX-13)', () {
    final tiles = balanceTiles(l, _summary(spendable: 1, waiting: 10), empty: false, senderPosted: epic(4));
    expect(tiles.map((t) => (t.kind, t.label, t.value)), [
      (BalanceKind.waitingSender, l.homeTileWaitingSender, epic(6)),
      (BalanceKind.senderPosted, l.txStatusSenderPosted, epic(4)),
      (BalanceKind.total, l.homeTileTotal, epic(1)),
    ]);
    // All of it reported: no Waiting for sender tile left.
    final all = balanceTiles(l, _summary(waiting: 4), empty: false, senderPosted: epic(4));
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
      amountCredited: epic(credited),
      amountDebited: kind == TxKind.sent ? epic(0.1) : BigInt.zero,
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
    expect(ownChangeOffChain(txs), epic(0.082));
    final tiles = balanceTiles(l, summary, empty: false, ownChange: ownChangeOffChain(txs));
    expect(tiles.map((t) => (t.kind, t.value)), [
      (BalanceKind.locked, epic(0.1)),
      (BalanceKind.total, epic(0.1)),
    ]);
    expect(summary.total, summary.spendable + summary.awaitingConfirmation + summary.locked);
    // Someone else's payment beside it still waits for its sender; a confirmed send and a
    // received payment add no change.
    final more = [...txs, tx(TxKind.received, 2), tx(TxKind.sent, 5, height: BigInt.from(10))];
    expect(ownChangeOffChain(more), epic(0.082));
    expect(
      balanceTiles(l, _summary(locked: 0.1, waiting: 2.082), empty: false, ownChange: ownChangeOffChain(more))
          .map((t) => (t.kind, t.value)),
      [(BalanceKind.waitingSender, epic(2)), (BalanceKind.locked, epic(0.1)), (BalanceKind.total, epic(0.1))],
    );
    // A split's receiving side is the wallet's own too.
    expect(ownChangeOffChain([tx(TxKind.received, 3, transport: 'self')]), epic(3));
  });

  group('every figure shows four decimals, the exact amount a tap away', () {
    testWidgets('Wallet cuts to four decimals; a tap opens the balance sheet', (
      tester,
    ) async {
      final session = FakeWalletSession(summary: _summary(spendable: 1234.56781234));
      await _pump(tester, session, width: 360);
      expect(_figure(tester), '1,234.5678');
      expect(find.text('1,234.56781234\u00a0EPIC'), findsNothing);
      await _clearToast(tester);
      await tester.tap(find.byKey(homeFigureKey));
      await tester.pumpAndSettle();
      expect(find.byKey(balanceSheetKey), findsOneWidget);
      // Balance, spendable now and Total are the same here: one row says it in full.
      expect(find.text('1,234.56781234\u00a0EPIC'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byKey(balanceSheetKey), findsNothing);
      // The screen reader hears the exact amount without the tap.
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp(r'1,234\.56781234\u00a0EPIC')),
        findsWidgets,
      );
      handle.dispose();

    });

    testWidgets('hidden balances show dots and tell nothing on a tap', (tester) async {
      final session = FakeWalletSession(summary: _summary(spendable: 1234.56781234));
      final container = await _pump(tester, session, width: 360);
      await container.read(appSettingsProvider.notifier).setHideBalances(true);
      await tester.pumpAndSettle();
      expect(_figure(tester), hiddenAmount);
      await tester.tap(find.byKey(homeFigureKey));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('1,234.56781234'), findsNothing);
      expect(
        find.ancestor(of: find.byKey(homeFigureKey), matching: find.byType(Tooltip)),
        findsNothing,
      );
    });
  });

  group('coins on hold beside a spendable 0', () {
    testWidgets('a spendable 0 says what is on hold and coming in, plainly', (
      tester,
    ) async {
      // The review's split: 2.5 of 10\u00a0EPIC sent, the 10 locked, its change confirming.
      final session = FakeWalletSession(
        summary: _summary(locked: 10, confirming: 7.492),
      );
      await _pump(tester, session, width: 360);
      // The figure is the wallet's balance: nothing spendable now, the 7.492 confirming.
      expect(_figure(tester), '7.492');
      // Home says it in two chips: the 7.492 arriving and the 10 held by sends.
      for (final text in [l.phoneHomeArriving(epicFor(l, epic(7.492), unit: false)), l.phoneHomeInSends(epicFor(l, epic(10.0), unit: false))]) {
        expect(find.text(text).hitTestable(), findsOneWidget, reason: text);
      }
      // They stand still, and nothing runs to move them.
      final at = tester.getRect(find.text(l.phoneHomeInSends(epicFor(l, epic(10.0), unit: false))));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.getRect(find.text(l.phoneHomeInSends(epicFor(l, epic(10.0), unit: false)))), at);
      expect(tester.binding.hasScheduledFrame, isFalse);

    });

    testWidgets('a send from the only coin: the figure keeps the change coming back', (
      tester,
    ) async {
      // 1 sent from one coin of 100 with a 0.008 fee, posted, not in a block yet: LEPIC
      // locks the 100 and holds the 98.992 change outside Total until it is mined. A
      // tester saw the balance "way off" here, so the figure must not fall to 0.
      final session = FakeWalletSession(
        summary: _summary(locked: 100, waiting: 98.992),
        transactions: [
          fakeTx(
            id: 10,
            slateId: 'to-alice',
            kind: TxKind.sent,
            status: TxStatus.awaitingConfirmation,
            confirmed: false,
            amountCredited: epic(98.992),
            amountDebited: epic(100),
            numInputs: 1,
          ),
        ],
      );
      await _pump(tester, session, width: 360);
      expect(_figure(tester), '98.992');
      // What can be sent now is in the sheet, next to the balance.
      final rows = BalanceHelp.rows(l, session.summaryValue, ownChange: epic(98.992));
      expect(rows.take(2).map((r) => (r.$1, r.$2)), [
        (l.homeWalletBalance, epic(98.992)),
        (l.homeBalanceSpendableNow, BigInt.zero),
      ]);
      // The notice toast floats over the top and takes the touches there: close what shows.
      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));
      container.read(noticeProvider.notifier).dismiss();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(homeFigureKey));
      await tester.pumpAndSettle();
      expect(find.byKey(balanceSheetKey), findsOneWidget);
      expect(find.text(l.homeBalanceSpendableNow), findsOneWidget);
    });

    testWidgets(
      'a chip per pending sum; the header keeps three tokens: locked, '
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
          (BalanceKind.confirming, l.homeBalanceConfirming, epic(2)),
          (BalanceKind.immature, l.homeBalanceImmature, epic(16)),
          (BalanceKind.waitingSender, l.homeTileWaitingSender, epic(0.5)),
          (BalanceKind.locked, l.homeTileLocked, epic(5)),
          (BalanceKind.total, l.homeTileTotal, epic(26.25)),
        ]);
        // Home: 2 confirming and 16 maturing arrive, the 5 locked are in sends.
        expect(find.text(l.phoneHomeArriving(epicFor(l, epic(18.0), unit: false))), findsOneWidget);
        expect(find.text(l.phoneHomeInSends(epicFor(l, epic(5.0), unit: false))), findsOneWidget);
        // The ? still lists each balance with its own words.
        final rows = BalanceHelp.rows(l, session.summaryValue);
        // The wallet's balance (3.25 spendable + 2 confirming), what is spendable now, then
        // the total, since all three differ.
        expect(rows.map((r) => r.$1), [
          l.homeWalletBalance,
          l.homeBalanceSpendableNow,
          l.balanceTotal,
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
      // Home shows no arriving chip for it: it waits for the sender.
      expect(find.textContaining('arriving'), findsNothing);
      await _tab(tester, l.homeSendButton);
      expect(find.textContaining('coming in'), findsNothing);
      final rows = BalanceHelp.rows(l, session.summaryValue);
      // Balance, spendable now and total are all 1: one row says it.
      expect(rows.map((r) => r.$1), [
        l.homeWalletBalance,
        l.homeBalanceNotOnChain,
      ]);
      expect(rows.first.$2, epic(1));
      expect(comingIn(session.summaryValue), BigInt.zero);
    });

    testWidgets('fits a 360 dp phone at text scale 2', (tester) async {
      final session = FakeWalletSession(
        summary: _summary(locked: 7.49283746, confirming: 6.48473625),
      );
      await _pump(tester, session, width: 360, textScale: 2);
      expect(tester.takeException(), isNull);
      // The chips wrap under the figure at this size.
      expect(find.textContaining('arriving'), findsOneWidget);
      expect(find.textContaining('in sends'), findsOneWidget);
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
      amountCredited: epic(2.5),
      counterparty: 'esAlice123@epicbox.epiccash.com',
    );

    testWidgets('a confirming balance never sits under a Received row', (tester) async {
      final session = FakeWalletSession(
        summary: _summary(
          spendable: 10,
          confirming: 2.5,
          height: _tip - BigInt.one,
        ),
        transactions: [received(height: _tip)],
      );
      await _pump(tester, session);
      expect(_rowLabel(tester), isNot(contains('received,')));
      expect(find.textContaining(l.txStatusReceived), findsNothing);
      expect(find.textContaining(l.payPosted), findsOneWidget);
      expect(find.text(l.phoneHomeArriving(epicFor(l, epic(2.5), unit: false))), findsOneWidget);

      // The next refresh reaches block 228: three confirmations, both say so.
      session.summaryValue = _summary(
        spendable: 12.5,
        height: _tip + BigInt.from(2),
      );
      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      expect(find.textContaining('arriving'), findsNothing);
      expect(_rowLabel(tester), contains('received,'));
    });

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
      expect(find.textContaining(l.payConfirming(1, 3)), findsOneWidget);
      expect(find.textContaining(l.txStatusReceived), findsNothing);
    });
  });
}
