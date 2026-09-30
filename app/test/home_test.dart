import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/amount.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/history_screen.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// Noon on 30 Sep 2026, local time, so day headings do not depend on the time zone.
final DateTime _now = DateTime(2026, 9, 30, 12);

int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

/// The fake node's tip height.
final BigInt _tip = BigInt.from(2500000);

const String _bob = 'esBobAddress1234567890@epicbox.epiccash.com';

/// A price that tests can change, counting how often it was asked.
class _FakePrice implements PriceSource {
  _FakePrice(this.value);

  double? value;
  int calls = 0;

  @override
  Future<double?> price(String currency) async {
    calls++;
    return value;
  }
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

WalletSummary _summary({BigInt? spendable}) => WalletSummary(
  lastConfirmedHeight: _tip,
  minimumConfirmations: BigInt.from(10),
  total: (spendable ?? _epic(12.5)) + _epic(2),
  spendable: spendable ?? _epic(12.5),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: _epic(2),
  validatedWithNode: true,
);

/// A pending epicbox send to Bob, today; a confirmed receive yesterday; a cancelled send and a
/// restored output earlier.
List<TxEntry> _transactions() => [
  fakeTx(
    id: 4,
    slateId: 'send-bob',
    kind: TxKind.sent,
    status: TxStatus.awaitingRecipient,
    createdAtUnix: _at(DateTime(2026, 9, 30, 9)),
    amountCredited: _epic(0.992),
    amountDebited: _epic(3),
    fee: _epic(0.008),
    counterparty: _bob,
    ttlCutoffHeight: _tip + BigInt.from(120),
    cancellable: true,
  ),
  fakeTx(
    id: 3,
    slateId: 'from-alice',
    kind: TxKind.received,
    status: TxStatus.confirmed,
    createdAtUnix: _at(DateTime(2026, 9, 29, 18)),
    blockHeight: _tip - BigInt.from(700),
    amountCredited: _epic(5),
    kernelExcess: '09abc',
    outputCommits: const ['08commit'],
    note: 'Rent share',
  ),
  fakeTx(
    id: 2,
    slateId: 'dropped',
    kind: TxKind.sentCancelled,
    status: TxStatus.cancelled,
    createdAtUnix: _at(DateTime(2026, 9, 20, 10)),
    amountCredited: _epic(0.9),
    amountDebited: _epic(2),
    fee: _epic(0.1),
  ),
  fakeTx(
    key: 'c:restored',
    kind: TxKind.received,
    status: TxStatus.confirmed,
    source: TxSource.restored,
    createdAtUnix: _at(DateTime(2026, 8, 1, 8)),
    blockHeight: BigInt.from(2400000),
    amountCredited: _epic(7.25),
  ),
];

/// A session whose first enrichment gives the restored row its block time (3 Aug instead of
/// the scan day), counting balance and list queries.
class _EnrichingSession extends FakeWalletSession {
  _EnrichingSession()
    : super(summary: _summary(), transactions: _transactions());

  int summaryCalls = 0;
  int transactionCalls = 0;
  bool _dated = false;

  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) {
    summaryCalls++;
    return super.summary(
      refresh: refresh,
      minimumConfirmations: minimumConfirmations,
    );
  }

  @override
  Future<List<TxEntry>> transactions({required bool refresh}) {
    transactionCalls++;
    return super.transactions(refresh: refresh);
  }

  @override
  Future<int> enrichHistory() async {
    await super.enrichHistory();
    if (_dated) return 0;
    _dated = true;
    transactionsValue = [
      for (final tx in transactionsValue)
        if (tx.key == 'c:restored')
          fakeTx(
            key: tx.key,
            kind: tx.kind,
            status: tx.status,
            source: tx.source,
            createdAtUnix: _at(DateTime(2026, 8, 3, 8)),
            blockHeight: tx.blockHeight,
            amountCredited: tx.amountCredited,
          )
        else
          tx,
    ];
    return 1;
  }
}

class _Harness {
  _Harness({
    List<TxEntry>? transactions,
    double? price,
    bool scanSupported = false,
    this.chain = Chain.mainnet,
    FakeWalletSession? session,
  }) : session =
           session ??
           FakeWalletSession(
             summary: _summary(),
             transactions: transactions ?? _transactions(),
           ),
       prices = _FakePrice(price),
       scanner = FakeQrScanner(supported: scanSupported) {
    store.values['wallet.${chain.name}.backedUp'] = '1';
  }

  final Chain chain;
  final FakeWalletSession session;
  final _FakePrice prices;
  final FakeQrScanner scanner;
  final store = MemorySecretStore();
  late final service = FakeWalletService(session: session);

  WalletConfig get config =>
      (chain == Chain.floonet ? floonetPreset : mainnetPreset).config(
        dataDir: '/fake/wallets/${chain.name}',
        nodeUrl: 'https://node',
      );

  Future<void> pump(
    WidgetTester tester, [
    Widget home = const HomeScreen(),
    double textScale = 1,
  ]) async {
    // Tall enough that every list row is built without scrolling. At large text, a phone.
    tester.view.physicalSize = textScale == 1
        ? const Size(1080, 7200)
        : const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
          vaultCryptoProvider.overrideWithValue(FakeVaultCrypto()),
          updatePlatformProvider.overrideWithValue(null),
          priceSourceProvider.overrideWithValue(prices),
          qrScannerProvider.overrideWithValue(scanner),
          clockProvider.overrideWithValue(() => _now),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          walletConfigProvider.overrideWith(() => _Config(config)),
        ],
        child: MaterialApp(
          home: home,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('status words', () {
    test('name who or what the transaction waits for', () {
      String label(TxEntry tx) => txStatusLabel(tx, _tip);
      expect(
        label(fakeTx(kind: TxKind.sent, status: TxStatus.awaitingRecipient)),
        'Waiting for recipient',
      );
      expect(
        label(fakeTx(status: TxStatus.awaitingConfirmation)),
        'Waiting for sender',
      );
      expect(
        label(fakeTx(kind: TxKind.sent, status: TxStatus.awaitingConfirmation)),
        'Confirming 0/10',
      );
      expect(
        label(
          fakeTx(status: TxStatus.confirmed, blockHeight: _tip - BigInt.two),
        ),
        'Confirming 3/10',
      );
      expect(
        label(
          fakeTx(
            status: TxStatus.confirmed,
            blockHeight: _tip - BigInt.from(9),
          ),
        ),
        'Completed',
      );
      expect(label(fakeTx(status: TxStatus.confirmed)), 'Completed');
      expect(label(fakeTx(status: TxStatus.cancelled)), 'Cancelled');
    });

    test('titles: mining reward, restored funds, contact, direction', () {
      expect(txTitle(fakeTx(kind: TxKind.coinbase)), 'Mining reward');
      expect(
        txTitle(fakeTx(source: TxSource.restored), contactName: 'Bob'),
        'Restored funds',
      );
      expect(txTitle(fakeTx(kind: TxKind.sent), contactName: 'Bob'), 'Bob');
      expect(
        txTitle(fakeTx(kind: TxKind.sentCancelled, status: TxStatus.cancelled)),
        'Send cancelled',
      );
      // A cancelled receive says so, even when the sender is a contact.
      expect(
        txTitle(
          fakeTx(kind: TxKind.receivedCancelled, status: TxStatus.cancelled),
          contactName: 'Bob',
        ),
        'Receive cancelled',
      );
    });

    test('details headings name the other side by its short address', () {
      final send = fakeTx(
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        counterparty: _bob,
      );
      expect(txHeading(send), 'Sent to esBobA…567890@epicbox.epiccash.com');
      expect(txHeading(send, contactName: 'Bob'), 'Bob');
      expect(
        txHeading(
          fakeTx(
            status: TxStatus.confirmed,
            counterparty: 'http://203.0.113.5:3415',
          ),
        ),
        'Received from http://203.0.113.5:3415',
      );
      expect(
        txHeading(fakeTx(kind: TxKind.sent, status: TxStatus.confirmed)),
        'Sent',
      );
    });

    test(
      'pending payments are Sending and Receiving, done ones Sent and Received',
      () {
        final receiving = fakeTx(
          status: TxStatus.awaitingConfirmation,
          counterparty: _bob,
        );
        expect(txTitle(receiving), 'Receiving');
        expect(
          txHeading(receiving),
          'Receiving from esBobA…567890@epicbox.epiccash.com',
        );
        expect(
          txTitle(
            fakeTx(kind: TxKind.sent, status: TxStatus.awaitingRecipient),
          ),
          'Sending',
        );
        expect(txTitle(fakeTx(status: TxStatus.confirmed)), 'Received');
        // A pending record from a backup is not known to be pending.
        expect(
          txTitle(
            fakeTx(
              kind: TxKind.sent,
              status: TxStatus.awaitingRecipient,
              source: TxSource.imported,
            ),
          ),
          'Sent',
        );
      },
    );

    test('EPIC amounts group thousands for display, not for fields', () {
      expect(epicText(_epic(1234.5678)), '1,234.5678 EPIC');
      expect(epicText(_epic(-1234567)), '-1,234,567 EPIC');
      expect(formatEpic(_epic(1234.5)), '1234.5');
      expect(
        matchesQuery(fakeTx(amountCredited: _epic(1234.5)), '1,234'),
        isTrue,
      );
    });

    test('a pending record from a backup is neither pending nor done', () {
      final tx = fakeTx(
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        source: TxSource.imported,
      );
      expect(isPending(tx), isFalse);
      expect(txStatusLabel(tx, _tip), 'From backup, status unknown');
      expect(matchesFilter(tx, HistoryFilter.pending), isFalse);
      expect(matchesFilter(tx, HistoryFilter.sent), isTrue);
      expect(txExplanation(tx, _tip), contains('Nothing is locked'));
    });

    test('the expiry line counts down to the TTL height', () {
      final tx = fakeTx(
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        ttlCutoffHeight: _tip + BigInt.from(120),
      );
      expect(
        ttlLine(tx, _tip),
        'Cancels automatically if not completed by block 2,500,120 '
        '(in about 2 hours).',
      );
      expect(ttlLine(tx, _tip + BigInt.from(200)), startsWith('Expired'));
      expect(
        ttlLine(
          fakeTx(status: TxStatus.confirmed, ttlCutoffHeight: _tip),
          _tip,
        ),
        isNull,
      );
    });

    test('explorer links: floonet kernel, mainnet block, none on usernet', () {
      final tx = fakeTx(
        status: TxStatus.confirmed,
        kernelExcess: '09ff',
        blockHeight: BigInt.from(42),
      );
      expect(
        explorerUrl(Chain.floonet, tx),
        'https://floo-explorer.btlabs.uk/kernel/09ff',
      );
      expect(
        explorerUrl(Chain.mainnet, tx),
        'https://explorer.epicmine.io/block/42',
      );
      expect(explorerUrl(Chain.usernet, tx), isNull);
      expect(
        explorerUrl(Chain.mainnet, fakeTx(status: TxStatus.confirmed)),
        isNull,
      );
      // Before it is on chain the kernel is not there (for a receive, only our part of it).
      expect(
        explorerUrl(
          Chain.floonet,
          fakeTx(status: TxStatus.awaitingConfirmation, kernelExcess: '09ff'),
        ),
        isNull,
      );
    });

    test('fiat text groups thousands and keeps satoshis for BTC', () {
      expect(fiatText(_epic(3000), 0.41, 'usd'), '1,230.00 USD');
      expect(fiatText(_epic(1), 0.00000512, 'btc'), '0.00000512 BTC');
    });
  });

  group('history', () {
    test('pending on top, then days: today, yesterday, a date', () {
      final sections = groupHistory(_transactions(), _now);
      expect(sections.map((s) => s.title), [
        'Pending',
        'Yesterday',
        '20 Sep 2026',
        '1 Aug 2026',
      ]);
      expect(sections.first.transactions.single.slateId, 'send-bob');
    });

    test('search matches note, address, contact name, amount and slate id', () {
      final txs = _transactions();
      List<String?> find(String q, {String? contact}) => [
        for (final tx in txs)
          if (matchesQuery(
            tx,
            q,
            contactName: tx.counterparty == _bob ? contact : null,
          ))
            tx.key,
      ];
      expect(find('rent'), ['s:from-alice']);
      expect(find('esBob'), ['s:send-bob']);
      expect(find('tables'), isEmpty);
      expect(find('tables', contact: 'Bobby Tables'), ['s:send-bob']);
      expect(find('7,25'), ['c:restored']);
      expect(find('dropped'), ['s:dropped']);
      expect(find('  '), hasLength(4));
    });

    testWidgets('groups by day, searches, and filters', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());

      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Restored funds'), findsOneWidget);
      expect(find.text('Cancelled'), findsWidgets);

      await tester.enterText(find.widgetWithText(TextField, 'Search'), 'rent');
      await tester.pumpAndSettle();
      expect(find.text('+5 EPIC'), findsOneWidget);
      expect(find.text('-2 EPIC'), findsNothing);

      await tester.enterText(find.widgetWithText(TextField, 'Search'), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches "zzz".'), findsOneWidget);

      await _tap(tester, find.byTooltip('Clear search'));
      await _tap(tester, find.widgetWithText(ChoiceChip, 'Sent'));
      expect(find.text('-2 EPIC'), findsOneWidget);
      expect(find.text('+5 EPIC'), findsNothing);
      // The cancelled send has its own filter.
      expect(find.text('-1 EPIC'), findsNothing);
      await _tap(tester, find.widgetWithText(ChoiceChip, 'Cancelled'));
      expect(find.text('-1 EPIC'), findsOneWidget);

      await _tap(tester, find.widgetWithText(ChoiceChip, 'Received'));
      expect(find.text('+5 EPIC'), findsOneWidget);
      expect(find.text('+7.25 EPIC'), findsOneWidget);
    });

    testWidgets('empty states in plain words', (tester) async {
      final h = _Harness(transactions: const []);
      await h.pump(tester, const HistoryScreen(filter: HistoryFilter.pending));
      expect(find.textContaining('Nothing yet.'), findsOneWidget);
    });
  });

  group('home', () {
    testWidgets('balance with fiat, recent activity with pending first', (
      tester,
    ) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester);

      expect(find.text('12.5 EPIC'), findsOneWidget);
      expect(find.text('≈ 6.25 USD'), findsOneWidget);
      expect(
        find.text(
          'Synced at height 2,500,000. Connecting to the mailbox '
          'to receive payments…',
        ),
        findsOneWidget,
      );
      expect(find.text('2 EPIC not spendable yet'), findsOneWidget);

      // Recent activity: the pending send to Bob first, amounts with fiat.
      final tiles = find.byType(TxTile);
      expect(tiles, findsNWidgets(4));
      expect(tester.widget<TxTile>(tiles.first).tx.slateId, 'send-bob');
      expect(find.text('Waiting for recipient'), findsOneWidget);
      expect(find.text('≈ 2.50 USD'), findsOneWidget);
      expect(find.text('Today, 09:00'), findsOneWidget);
      expect(find.text('Yesterday, 18:00'), findsOneWidget);

      // The waiting send also gets a card that says what it means.
      expect(
        find.text('A payment is waiting for the recipient'),
        findsOneWidget,
      );
      await _tap(tester, find.text('View payment'));
      expect(find.byType(TxDetailsScreen), findsOneWidget);
      expect(find.textContaining('in about 2 hours'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await _tap(tester, find.text('See all'));
      expect(find.byType(HistoryScreen), findsOneWidget);
    });

    testWidgets('only the five newest, pending first', (tester) async {
      final h = _Harness(
        transactions: [
          for (var i = 0; i < 7; i++)
            fakeTx(
              id: i,
              status: TxStatus.confirmed,
              createdAtUnix: _at(DateTime(2026, 9, 1 + i)),
              amountCredited: _epic(i + 1),
            ),
        ],
      );
      await h.pump(tester);
      expect(find.byType(TxTile), findsNWidgets(recentActivityCount));
      expect(find.text('+7 EPIC'), findsOneWidget);
      expect(find.text('+2 EPIC'), findsNothing);
    });

    testWidgets('the eye hides every amount and remembers it', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester);

      await _tap(tester, find.byTooltip('Hide balances'));
      expect(find.text('12.5 EPIC'), findsNothing);
      expect(find.text('≈ 6.25 USD'), findsNothing);
      expect(find.text('+5 EPIC'), findsNothing);
      expect(find.text(hiddenAmount), findsWidgets);
      expect(h.store.values['app.hide_balances'], 'true');

      await _tap(tester, find.byTooltip('Show balances'));
      expect(find.text('12.5 EPIC'), findsOneWidget);
    });

    testWidgets('no fiat line when prices are off or unknown', (tester) async {
      final h = _Harness(price: 0.5);
      h.store.values['app.show_fiat'] = 'false';
      await h.pump(tester);
      expect(find.textContaining('USD'), findsNothing);
      expect(h.prices.calls, 0);
    });

    testWidgets('the price refreshes every five minutes', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester);
      expect(find.text('≈ 6.25 USD'), findsOneWidget);
      h.prices.value = 1;
      await tester.pump(priceRefreshInterval);
      await tester.pumpAndSettle();
      expect(find.text('≈ 12.50 USD'), findsOneWidget);
      // A failed fetch keeps the last price.
      h.prices.value = null;
      await tester.pump(priceRefreshInterval);
      await tester.pumpAndSettle();
      expect(find.text('≈ 12.50 USD'), findsOneWidget);
      expect(h.prices.calls, 3);
    });

    testWidgets('refreshes by itself every minute while on screen', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      h.session.summaryValue = _summary(spendable: _epic(20));

      // Not while another screen covers home.
      await _tap(tester, find.byKey(const ValueKey('tx-s:from-alice')));
      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('12.5 EPIC'), findsOneWidget);

      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      expect(find.text('20 EPIC'), findsOneWidget);
    });

    testWidgets('scan opens Send with the scanned address', (tester) async {
      final h = _Harness(scanSupported: true);
      h.scanner.codes.add(_bob);
      await h.pump(tester);
      await _tap(tester, find.byTooltip('Scan a QR code to send'));
      final send = tester.widget<SendScreen>(find.byType(SendScreen));
      expect(send.recipient, _bob);
    });

    testWidgets('no scan button where scanning is unsupported', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.byTooltip('Scan a QR code to send'), findsNothing);
    });

    testWidgets('a contact name replaces the address in the list', (
      tester,
    ) async {
      final h = _Harness();
      h.session.contactsValue.add(
        const Contact(id: 'c1', name: 'Bob', address: _bob),
      );
      await h.pump(tester);
      expect(find.text('Bob'), findsOneWidget);
    });
  });

  group('details', () {
    testWidgets('shows what is known and edits the note', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, const TxDetailsScreen(txKey: 's:from-alice'));

      expect(find.text('+5 EPIC'), findsOneWidget);
      expect(find.text('≈ 2.50 USD'), findsOneWidget);
      expect(find.text('Completed in block 2,499,300.'), findsOneWidget);
      expect(find.text('Rent share'), findsOneWidget);
      expect(
        find.text('https://explorer.epicmine.io/block/2499300'),
        findsOneWidget,
      );
      expect(find.text('08commit'), findsNothing);
      await _tap(tester, find.text('Technical details'));
      expect(find.text('08commit'), findsOneWidget);
      expect(find.text('from-alice'), findsOneWidget);

      await _tap(tester, find.byTooltip('Edit note'));
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '  Rent for September ',
      );
      await _tap(tester, find.text('Save'));
      expect(h.session.notes['s:from-alice'], 'Rent for September');
      expect(find.text('Rent for September'), findsOneWidget);
      expect(find.text('Note saved'), findsOneWidget);
    });

    testWidgets('cancels a waiting send after confirmation', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(
        const Contact(id: 'c1', name: 'Bob', address: _bob),
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));

      expect(find.text('Sent to'), findsOneWidget);
      expect(find.text('Bob'), findsWidgets);
      expect(find.text('Add to contacts'), findsNothing);
      expect(find.text('Waiting for recipient'), findsOneWidget);
      expect(find.textContaining('by block 2,500,120'), findsOneWidget);

      final cancel = find.widgetWithText(OutlinedButton, 'Cancel payment');
      await _tap(tester, cancel);
      await _tap(tester, find.text('Keep'));
      expect(h.session.cancelledTxIds, isEmpty);
      await _tap(tester, cancel);
      await _tap(tester, find.widgetWithText(FilledButton, 'Cancel payment'));
      expect(h.session.cancelledTxIds, [4]);
      expect(find.text('Payment cancelled'), findsOneWidget);
    });

    testWidgets('restored funds explain what the chain does not keep', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 'c:restored'));
      expect(find.text('Restored funds'), findsOneWidget);
      expect(
        find.textContaining('Found by scanning the chain'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Cancel payment'),
        findsNothing,
      );
    });

    testWidgets('an unknown address offers to save it', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      expect(find.text(_bob), findsOneWidget);
      expect(find.text('Add to contacts'), findsOneWidget);
    });

    testWidgets('floonet links the kernel', (tester) async {
      final h = _Harness(chain: Chain.floonet);
      await h.pump(tester, const TxDetailsScreen(txKey: 's:from-alice'));
      expect(
        find.text('https://floo-explorer.btlabs.uk/kernel/09abc'),
        findsOneWidget,
      );
    });

    testWidgets('a send stuck for 30 minutes can be broadcast again', (
      tester,
    ) async {
      TxEntry posted(String key, Duration age) => fakeTx(
        key: key,
        id: 9,
        kind: TxKind.sent,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: _at(_now.subtract(age)),
        amountCredited: _epic(1),
        amountDebited: _epic(2.008),
        fee: _epic(0.008),
        repostable: true,
      );
      final h = _Harness(
        transactions: [
          posted('s:old', const Duration(minutes: 45)),
          posted('s:new', const Duration(minutes: 10)),
        ],
      );
      expect(isStuck(h.session.transactionsValue.last, _now), isFalse);
      expect(isStuck(h.session.transactionsValue.first, _now), isTrue);

      await h.pump(tester, const TxDetailsScreen(txKey: 's:old'));
      expect(find.text('Not confirmed yet'), findsOneWidget);
      await _tap(tester, find.text('Broadcast again'));
      expect(h.session.repostedKeys, ['s:old']);
      expect(find.textContaining('Broadcast again. It should'), findsOneWidget);
    });
  });

  group('addresses', () {
    test('lists shorten the key around an ellipsis and keep the relay', () {
      expect(shortAddress(_bob), 'esBobA…567890@epicbox.epiccash.com');
      expect(
        shortAddress('http://203.0.113.5:3415'),
        'http://203.0.113.5:3415',
      );
      expect(shortAddress('short@relay'), 'short@relay');
      expect(shortAddress('${'a' * 52}@r.io:443'), 'aaaaaa…aaaaaa@r.io:443');
    });

    testWidgets('rows show the short address, details the full one', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(
        find.text('To esBobA…567890@epicbox.epiccash.com'),
        findsOneWidget,
      );
      expect(find.text(_bob), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('tx-s:send-bob')));
      expect(find.text(_bob), findsOneWidget);
    });
  });

  group('payment notices', () {
    const received = ListenerEvent(
      kind: ListenerEventKind.received,
      slateId: 'x',
      message: 'raw',
    );
    const finalized = ListenerEvent(
      kind: ListenerEventKind.finalized,
      slateId: 'x',
      message: 'raw',
    );

    test('say what happened in words', () {
      final tx = fakeTx(amountCredited: _epic(1.5), counterparty: _bob);
      // The listener only accepted it: the sender still has to finish.
      expect(
        paymentNotice(received, tx),
        '1.5 EPIC on the way. It completes when the sender finishes.',
      );
      expect(
        paymentNotice(
          ListenerEvent(
            kind: ListenerEventKind.received,
            message: 'raw',
            amount: _epic(2),
          ),
          null,
          contactName: 'Alice',
        ),
        '2 EPIC from Alice on the way. It completes when the sender finishes.',
      );
      expect(
        paymentNotice(received, null),
        'A payment is on the way. It completes when the sender finishes.',
      );
      expect(
        paymentNotice(received, tx, hidden: true),
        'A payment is on the way. It completes when the sender finishes.',
      );
      expect(
        paymentNotice(finalized, tx),
        'Payment to esBobA…567890@epicbox.epiccash.com completed',
      );
      expect(
        paymentNotice(finalized, tx, contactName: 'Bob'),
        'Payment to Bob completed',
      );
      expect(paymentNotice(finalized, null), 'Payment completed');
      expect(
        paymentNotice(
          const ListenerEvent(
            kind: ListenerEventKind.error,
            message: 'relay error: Unauthorized x',
          ),
          null,
        ),
        'The mailbox server reported a problem. Retrying.',
      );
    });

    testWidgets('a received payment opens its details from the notice', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      h.session.listenerEvents.add(
        ListenerEvent(
          kind: ListenerEventKind.received,
          slateId: 'from-alice',
          message: 'Received 5 EPIC from esAlice…',
          amount: _epic(5),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('5 EPIC on the way. It completes when the sender finishes.'),
        findsOneWidget,
      );
      expect(find.textContaining('esAlice'), findsNothing);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(find.byType(TxDetailsScreen), findsOneWidget);
      expect(find.text('Rent share'), findsOneWidget);
    });

    testWidgets('a completed send names the contact', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(
        const Contact(id: 'c1', name: 'Bob', address: _bob),
      );
      await h.pump(tester);
      h.session.listenerEvents.add(
        const ListenerEvent(
          kind: ListenerEventKind.finalized,
          slateId: 'send-bob',
          message: 'Sent 2 EPIC, posted to the node',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Payment to Bob completed'), findsOneWidget);
    });

    testWidgets('a lost relay says it retries', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      h.session.listenerEvents
        ..add(
          const ListenerEvent(kind: ListenerEventKind.connected, message: 'a'),
        )
        ..add(
          const ListenerEvent(
            kind: ListenerEventKind.disconnected,
            message: 'io error: connection reset by peer',
          ),
        );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Mailbox offline, reconnecting.'),
        findsOneWidget,
      );
      expect(find.textContaining('connection reset'), findsNothing);
    });
  });

  group('first run', () {
    testWidgets('an empty wallet explains how to receive', (tester) async {
      final h = _Harness(transactions: const []);
      await h.pump(tester);
      expect(find.text('Your wallet is ready'), findsOneWidget);
      expect(find.text('See all'), findsNothing);
      await _tap(tester, find.text('Show my address'));
      expect(find.byType(ReceiveScreen), findsOneWidget);
    });
  });

  group('review fixes', () {
    testWidgets('history is enriched after home loads, and on each refresh', (
      tester,
    ) async {
      final session = _EnrichingSession();
      final h = _Harness(session: session);
      await h.pump(tester);
      // Enrichment found the block time of the restored row: the list reloaded with it, and the
      // balance was not asked again.
      expect(session.enrichCalls, 1);
      expect(session.summaryCalls, 1);
      expect(session.transactionCalls, 2);
      expect(find.text('3 Aug, 08:00'), findsOneWidget);
      expect(find.text('1 Aug, 08:00'), findsNothing);

      // The minute refresh asks again; nothing changed, so no extra list load.
      final loads = session.transactionCalls;
      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      expect(session.enrichCalls, 2);
      expect(session.summaryCalls, 2);
      expect(session.transactionCalls, loads + 1);
    });

    testWidgets('no fiat values on test networks', (tester) async {
      final h = _Harness(price: 0.5, chain: Chain.floonet);
      await h.pump(tester);
      expect(find.textContaining('USD'), findsNothing);
      expect(h.prices.calls, 0);
    });
    testWidgets('cancelling a receive warns that the sender may finish', (
      tester,
    ) async {
      final h = _Harness(
        transactions: [
          fakeTx(
            id: 7,
            slateId: 'in',
            kind: TxKind.received,
            status: TxStatus.awaitingConfirmation,
            amountCredited: _epic(4),
            cancellable: true,
          ),
        ],
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:in'));
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Cancel payment'));
      expect(find.text('Cancel payment?'), findsOneWidget);
      expect(
        find.text(
          'The sender may still finish this payment. If they do after you '
          'cancel, it will not show until you rescan.',
        ),
        findsOneWidget,
      );
      await _tap(tester, find.widgetWithText(FilledButton, 'Cancel payment'));
      expect(h.session.cancelledTxIds, [7]);
    });

    testWidgets('cancelling a send keeps the send wording', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Cancel payment'));
      expect(find.textContaining('unlock its funds'), findsOneWidget);
      expect(find.textContaining('rescan'), findsNothing);
    });

    testWidgets('a pending record from a backup is not in the pending card', (
      tester,
    ) async {
      final h = _Harness(
        transactions: [
          fakeTx(
            key: 'k:old',
            kind: TxKind.sent,
            status: TxStatus.awaitingRecipient,
            source: TxSource.imported,
            amountCredited: _epic(1),
            amountDebited: _epic(3),
          ),
        ],
      );
      await h.pump(tester);
      expect(find.text('A payment is waiting for the recipient'), findsNothing);
      expect(find.text('From backup, status unknown'), findsOneWidget);
    });

    testWidgets('the pending card keeps both buttons on one row', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      // The test font draws every glyph 1 em wide, about twice Roboto's width, so check the
      // layout on a wider view; the screenshot tour checks a phone with real fonts.
      tester.view.physicalSize = const Size(1800, 7200);
      await tester.pumpAndSettle();
      final why = tester.getCenter(find.text('Why is it waiting?'));
      final view = tester.getCenter(find.text('View payment'));
      expect(why.dy, view.dy);
    });

    testWidgets('cancelled rows show no fiat value', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, const HistoryScreen());
      // The cancelled 1 EPIC send would be 0.50 USD.
      expect(find.text('-1 EPIC'), findsOneWidget);
      expect(find.text('≈ 0.50 USD'), findsNothing);
      expect(find.text('≈ 1.00 USD'), findsOneWidget);
      expect(find.text('Send cancelled'), findsOneWidget);
    });

    testWidgets('filter chips scroll on one row', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());
      final first = tester.getCenter(find.widgetWithText(ChoiceChip, 'All'));
      final last = tester.getCenter(
        find.widgetWithText(ChoiceChip, 'Cancelled'),
      );
      expect(first.dy, last.dy);
    });

    testWidgets('details copy only what is worth copying', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:from-alice'));
      expect(find.byTooltip('Copy date'), findsNothing);
      expect(find.byTooltip('Copy explorer link'), findsOneWidget);
      expect(find.text('Copy explorer link'), findsOneWidget);
      expect(find.byTooltip('Copy address'), findsNothing);
      await _tap(tester, find.text('Technical details'));
      expect(find.byTooltip('Copy slate id'), findsOneWidget);
      expect(find.byTooltip('Copy kernel'), findsOneWidget);
      expect(find.byTooltip('Copy block height'), findsNothing);
      expect(find.text('Local id'), findsOneWidget);
      expect(find.byTooltip('Copy local id'), findsNothing);
      expect(find.text('Wallet log id'), findsNothing);

      // A tap on the explorer row copies it too.
      await _tap(tester, find.text('Copy explorer link'));
      expect(find.text('Link copied'), findsOneWidget);
    });

    testWidgets('a send to an unknown address is titled with it', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      expect(
        find.text('Sending to esBobA…567890@epicbox.epiccash.com'),
        findsOneWidget,
      );
      expect(find.byTooltip('Copy address'), findsOneWidget);
    });

    testWidgets('large balances group thousands', (tester) async {
      final h = _Harness();
      h.session.summaryValue = _summary(spendable: _epic(1234.5678));
      await h.pump(tester);
      expect(find.text('1,234.5678 EPIC'), findsOneWidget);
    });
  });

  group('large text', () {
    for (final (name, screen) in [
      ('home', const HomeScreen()),
      ('history', const HistoryScreen()),
      ('details of a pending send', const TxDetailsScreen(txKey: 's:send-bob')),
      ('details of a receive', const TxDetailsScreen(txKey: 's:from-alice')),
    ]) {
      testWidgets('$name at text scale 2 has no overflow', (tester) async {
        final h = _Harness(price: 0.5);
        await h.pump(tester, screen, 2);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(screen.runtimeType)),
          ).scale(10),
          20,
        );
        expect(tester.takeException(), isNull);
        // Every part of the list is laid out, not only the first screen.
        await tester.fling(
          find.byType(Scrollable).first,
          const Offset(0, -3000),
          3000,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('an empty home at text scale 2 has no overflow', (
      tester,
    ) async {
      final h = _Harness(transactions: const []);
      await h.pump(tester, const HomeScreen(), 2);
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -3000),
        3000,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
