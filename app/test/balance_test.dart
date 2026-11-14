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
import 'package:epic_wallet/src/ui/home_change.dart';
import 'package:epic_wallet/src/ui/home_parts.dart';
import 'package:epic_wallet/src/ui/home_tab.dart' show homeFigureKey;
import 'package:epic_wallet/src/ui/kit/kit_row.dart' show KitRow;
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
  int confirmations = 3,
}) => WalletSummary(
  lastConfirmedHeight: height ?? _tip,
  minimumConfirmations: BigInt.from(confirmations),
  total: _epic(spendable + confirming + locked + immature),
  spendable: _epic(spendable),
  awaitingConfirmation: _epic(confirming),
  awaitingFinalization: _epic(waiting),
  immature: _epic(immature),
  locked: _epic(locked),
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

/// [text] inside the balance sheet.
Finder _sheetText(WidgetTester tester, String text) =>
    find.descendant(of: find.byKey(balanceSheetKey), matching: find.text(text));

/// The value of the balance sheet's row titled [title].
String? _sheetValue(WidgetTester tester, String title) => tester
    .widget<KitRow>(
      find.descendant(of: find.byKey(balanceSheetKey), matching: find.widgetWithText(KitRow, title)),
    )
    .value;

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
      // The figure is what can be spent now: nothing; the 7.492 confirming is in a chip.
      expect(_figure(tester), '0.0');
      // Home says it in two chips: the 7.492 arriving and the 10 held by sends.
      for (final text in [l.phoneHomeArriving(epicFor(l, _epic(7.492), unit: false)), l.phoneHomeInSends(epicFor(l, _epic(10.0), unit: false))]) {
        expect(find.text(text).hitTestable(), findsOneWidget, reason: text);
      }
      // They stand still, and nothing runs to move them.
      final at = tester.getRect(find.text(l.phoneHomeInSends(epicFor(l, _epic(10.0), unit: false))));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.getRect(find.text(l.phoneHomeInSends(epicFor(l, _epic(10.0), unit: false)))), at);
      expect(tester.binding.hasScheduledFrame, isFalse);

    });

    testWidgets('a send from the only coin: the figure is 0, the change confirms in a chip', (
      tester,
    ) async {
      // 1 sent from one coin of 100 with a 0.008 fee, posted, not in a block yet: LEPIC
      // locks the 100 and holds the 98.992 change outside Total until it is mined. Home shows
      // what can be spent (0) and the change in one chip with its time: a block, then the 3
      // confirmations this summary counts.
      final session = FakeWalletSession(
        summary: _summary(locked: 100, waiting: 98.992),
        transactions: [
          fakeTx(
            id: 10,
            slateId: 'to-alice',
            kind: TxKind.sent,
            status: TxStatus.awaitingConfirmation,
            confirmed: false,
            amountCredited: _epic(98.992),
            amountDebited: _epic(100),
            numInputs: 1,
          ),
        ],
      );
      await _pump(tester, session, width: 360);
      expect(_figure(tester), '0.0');
      final chip = l.phoneChangeAbout('98.992', 4);
      expect(find.text(chip), findsOneWidget);
      expect(find.textContaining('in sends'), findsNothing);
      await _clearToast(tester);
      await tester.tap(find.text(chip));
      await tester.pumpAndSettle();
      expect(find.byKey(balanceSheetKey), findsOneWidget);
      expect(_sheetText(tester, l.phoneBalanceAvailableNow), findsOneWidget);
      expect(_sheetText(tester, l.phoneChangeRowBlock(4)), findsOneWidget);
      expect(_sheetText(tester, l.homeBalanceLocked), findsNothing);
      expect(_sheetValue(tester, l.balanceTotal), '98.992\u00a0EPIC');
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
          (BalanceKind.confirming, l.homeBalanceConfirming, _epic(2)),
          (BalanceKind.immature, l.homeBalanceImmature, _epic(16)),
          (BalanceKind.waitingSender, l.homeTileWaitingSender, _epic(0.5)),
          (BalanceKind.locked, l.homeTileLocked, _epic(5)),
          (BalanceKind.total, l.homeTileTotal, _epic(26.25)),
        ]);
        // Home: 2 confirming and 16 maturing arrive, the 5 locked are in sends.
        expect(find.text(l.phoneHomeArriving(epicFor(l, _epic(18.0), unit: false))), findsOneWidget);
        expect(find.text(l.phoneHomeInSends(epicFor(l, _epic(5.0), unit: false))), findsOneWidget);
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
      expect(rows.first.$2, _epic(1));
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

  group('the change of open sends confirms in one chip', () {
    const tom = 'esTomAddress1234567890@box.epic.invalid';
    const sam = 'esSamAddress1234567890@box.epic.invalid';

    TxEntry send(
      int id,
      num change, {
      String? to,
      TxStatus status = TxStatus.awaitingRecipient,
      BigInt? height,
    }) => fakeTx(
      id: id,
      slateId: 'send-$id',
      kind: TxKind.sent,
      status: status,
      confirmed: status == TxStatus.confirmed,
      blockHeight: height,
      amountCredited: _epic(change),
      amountDebited: _epic(change + 5.26),
      counterparty: to,
      numInputs: 1,
    );

    testWidgets('one send: waiting for Tom, about 4 min once posted, the confirmations left '
        'once in a block, and gone when spendable', (tester) async {
      final session = FakeWalletSession(
        summary: _summary(spendable: 284.7321, locked: 1000.252, waiting: 994.992),
        transactions: [send(1, 994.992, to: tom)],
      );
      session.contactsValue.add(Contact(id: 'c1', name: 'Tom', address: tom));
      await _pump(tester, session, width: 360);
      expect(_figure(tester), '284.7321');
      expect(find.text(l.phoneChangeWaitingFor('994.992', 'Tom')), findsOneWidget);
      // The coins the send spent are not shown again as "in sends".
      expect(find.textContaining('in sends'), findsNothing);

      // Tom answered, the send is posted: a block, then the 3 confirmations.
      session.transactionsValue = [send(1, 994.992, to: tom, status: TxStatus.awaitingConfirmation)];
      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      expect(find.text(l.phoneChangeAbout('994.992', 4)), findsOneWidget);

      // In the tip's block: 1 of 3 confirmations, 2 left.
      session.transactionsValue = [
        send(1, 994.992, to: tom, status: TxStatus.confirmed, height: _tip),
      ];
      session.summaryValue = _summary(spendable: 284.7321, confirming: 994.992);
      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      expect(find.text(l.phoneChangeAbout('994.992', 2)), findsOneWidget);
      // Counted once: the confirming change is not "arriving" as well.
      expect(find.textContaining('arriving'), findsNothing);

      // 3 confirmations: the change is spendable and the chip goes.
      session.transactionsValue = [
        send(1, 994.992, to: tom, status: TxStatus.confirmed, height: _tip - BigInt.two),
      ];
      session.summaryValue = _summary(spendable: 1279.7241);
      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      expect(_figure(tester), '1,279.7241');
      expect(find.textContaining('confirming'), findsNothing);
    });

    testWidgets('two sends: the soonest time; a tap lists each send in the sheet', (
      tester,
    ) async {
      final session = FakeWalletSession(
        summary: _summary(spendable: 10, locked: 120, waiting: 100, confirming: 13.5),
        transactions: [
          send(1, 100, to: tom),
          send(2, 13.5, to: sam, status: TxStatus.confirmed, height: _tip),
        ],
      );
      session.contactsValue.add(Contact(id: 'c1', name: 'Tom', address: tom));
      await _pump(tester, session, width: 360);
      expect(_figure(tester), '10.0');
      final chip = l.phoneChangeNextIn('113.5', 2);
      expect(find.text(chip), findsOneWidget);
      expect(find.textContaining('arriving'), findsNothing);
      await _clearToast(tester);
      await tester.tap(find.text(chip));
      await tester.pumpAndSettle();
      expect(find.byKey(balanceSheetKey), findsOneWidget);
      expect(_sheetValue(tester, l.phoneBalanceAvailableNow), '10.0 EPIC');
      expect(_sheetValue(tester, l.homeBalanceConfirming), '113.5 EPIC');
      // The soonest first: Sam's in a block, then Tom's waiting for his reply.
      final hints = [l.phoneChangeRowConfirming(2, 1, 3), l.phoneChangeRowReply];
      for (final hint in hints) {
        expect(_sheetText(tester, hint), findsOneWidget, reason: hint);
      }
      expect(
        tester.getTopLeft(_sheetText(tester, hints[0])).dy,
        lessThan(tester.getTopLeft(_sheetText(tester, hints[1])).dy),
      );
      // The coins the sends spent are gone; nothing is left on hold.
      expect(_sheetText(tester, l.homeBalanceLocked), findsNothing);
      expect(_sheetValue(tester, l.balanceTotal), '123.5 EPIC');
      expect(_sheetText(tester, l.phoneBalanceChangeNote(3)), findsOneWidget);
      await tester.tap(_sheetText(tester, l.commonDone));
      await tester.pumpAndSettle();
      expect(find.byKey(balanceSheetKey), findsNothing);
    });

    testWidgets('two sends with no answer: waiting for 2 replies', (tester) async {
      final session = FakeWalletSession(
        summary: _summary(spendable: 1, locked: 30, waiting: 25),
        transactions: [send(1, 10, to: tom), send(2, 15)],
      );
      await _pump(tester, session, width: 360);
      expect(find.text(l.phoneChangeWaitingReplies('25.0', 2)), findsOneWidget);
    });

    testWidgets('the time follows the Confirmations setting', (tester) async {
      final session = FakeWalletSession(
        summary: _summary(spendable: 1, locked: 30, waiting: 25, confirmations: 10),
        transactions: [send(1, 25, status: TxStatus.awaitingConfirmation)],
      );
      await _pump(tester, session, width: 360);
      expect(find.text(l.phoneChangeAbout('25.0', 11)), findsOneWidget);
    });

    test('openChange: what each send waits for and when', () {
      final tip = _tip;
      final sends = openChange(
        [
          send(1, 1),
          send(2, 2, status: TxStatus.awaitingConfirmation),
          send(3, 3, status: TxStatus.confirmed, height: tip),
          send(4, 4, status: TxStatus.confirmed, height: tip - BigInt.from(9)),
          send(5, 5, status: TxStatus.cancelled),
          fakeTx(id: 6, kind: TxKind.received, status: TxStatus.awaitingConfirmation, amountCredited: _epic(6)),
          send(7, 0, status: TxStatus.awaitingConfirmation),
        ],
        tip,
        target: 10,
      );
      // Posted: a block and 10; in the tip's block: 9 left; 10 confirmations: done.
      expect(sends.map((c) => (c.tx.id, c.wait, c.minutes)), [
        (3, ChangeWait.confirming, 9),
        (2, ChangeWait.block, 11),
        (1, ChangeWait.reply, null),
      ]);
      expect(changeSum(sends), _epic(6));
      expect(changeInBlock(sends), _epic(3));
      // With no name the chip waits for "reply".
      expect(changeChipText(l, sends.sublist(2), '1.0'), l.phoneChangeWaitingReply('1.0'));
    });

    test('chipName cuts a long name at a word', () {
      expect(chipName('Tom'), 'Tom');
      expect(chipName('Northwind Exchange'), 'Northwind…');
      expect(chipName('Supercalifragilistic'), 'Supercalifra…');
      expect(chipName('  Ann Lee  '), 'Ann Lee');
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
      // A finished row says "completed" (its chip, Received, already starts the sentence).
      expect(_rowLabel(tester), isNot(contains('completed,')));
      expect(find.textContaining(l.txStatusReceived), findsNothing);
      expect(find.textContaining(l.lvPolPosted), findsOneWidget);
      expect(find.text(l.phoneHomeArriving(epicFor(l, _epic(2.5), unit: false))), findsOneWidget);

      // The next refresh reaches block 228: three confirmations, both say so.
      session.summaryValue = _summary(
        spendable: 12.5,
        height: _tip + BigInt.from(2),
      );
      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      expect(find.textContaining('arriving'), findsNothing);
      expect(_rowLabel(tester), contains('completed,'));
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
      expect(find.textContaining(l.lvPayConfirming(1, 3)), findsOneWidget);
      expect(find.textContaining(l.txStatusReceived), findsNothing);
    });
  });
}
