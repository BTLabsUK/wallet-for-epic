import 'dart:async';

import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/amount.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/history_screen.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

/// Pushes on demand, as FCM delivers them in the foreground.
class _FakePush implements PushPlatform {
  final foregroundMessages = StreamController<RemoteMessage>.broadcast();
  int starts = 0;

  @override
  Future<bool> start() async {
    starts++;
    return true;
  }

  @override
  Future<String?> token() async => 'token';

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get foreground => foregroundMessages.stream;
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
  final push = _FakePush();
  final files = FakeHistoryFiles()..canShare = false;
  final store = MemorySecretStore();
  late final service = FakeWalletService(session: session);

  WalletConfig get config =>
      (chain == Chain.floonet ? floonetPreset : mainnetPreset).config(
        dataDir: '/fake/wallets/${chain.name}',
        nodeUrl: 'https://node',
      );

  /// Turns payment notifications on, as the app does when the setting is on.
  Future<void> startPush(WidgetTester tester) async {
    await ProviderScope.containerOf(tester.element(find.byType(HomeScreen)))
        .read(pushProvider.notifier)
        .start();
    await tester.pumpAndSettle();
  }

  Future<void> pump(
    WidgetTester tester, [
    Widget home = const HomeScreen(),
    double textScale = 1,
    Size? size,
  ]) async {
    // Tall enough that every list row is built without scrolling. At large text, a phone.
    tester.view.physicalSize =
        size ??
        (textScale == 1 ? const Size(1080, 7200) : const Size(1080, 2340));
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
          pushPlatformProvider.overrideWithValue(push),
          historyFilesProvider.overrideWithValue(files),
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

    test('one title style: contact, else short address, else the kind', () {
      expect(txTitle(fakeTx(kind: TxKind.coinbase)), 'Mining reward');
      expect(
        txTitle(fakeTx(source: TxSource.restored), contactName: 'Bob'),
        'Restored funds',
      );
      // The status never changes the title: pending, completed and cancelled read alike.
      for (final status in TxStatus.values) {
        final tx = fakeTx(
          kind: TxKind.sent,
          status: status,
          counterparty: _bob,
        );
        expect(txTitle(tx, contactName: 'Bob'), 'Bob');
        expect(txTitle(tx), 'esBobA…567890@epicbox.epiccash.com');
        expect(
          txTitle(fakeTx(kind: TxKind.sent, status: status)),
          'Outgoing payment',
        );
        expect(txTitle(fakeTx(status: status)), 'Incoming payment');
      }
      expect(
        txTitle(fakeTx(counterparty: 'http://203.0.113.5:3415')),
        'http://203.0.113.5:3415',
      );
    });

    test('details headings leave the address to the row below', () {
      final send = fakeTx(
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        counterparty: _bob,
      );
      expect(txHeading(send), 'Outgoing payment');
      expect(txHeading(send, contactName: 'Bob'), 'Bob');
      expect(
        txHeading(fakeTx(source: TxSource.imported, counterparty: _bob)),
        'Incoming payment',
      );
      expect(txHeading(fakeTx(kind: TxKind.coinbase)), 'Mining reward');
    });

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
      await tester.pump(searchDebounce);
      await tester.pumpAndSettle();
      expect(find.text('+5 EPIC'), findsOneWidget);
      expect(find.text('-2 EPIC'), findsNothing);

      await tester.enterText(find.widgetWithText(TextField, 'Search'), 'zzz');
      await tester.pump(searchDebounce);
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
          'Up to date. Connecting to the mailbox '
          'to receive payments…',
        ),
        findsOneWidget,
      );
      expect(find.text('2 EPIC not spendable yet'), findsOneWidget);
      // The height is only in the tooltip.
      expect(find.byTooltip('Synced at block 2,500,000'), findsOneWidget);
      expect(find.textContaining('2,500,000'), findsNothing);

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

    test('titles drop the server when it is the wallet\'s own', () {
      const own = 'epicbox.epiccash.com';
      expect(shortAddress(_bob, ownServer: own), 'esBobA…567890');
      expect(
        shortAddress('${'a' * 52}@EPICBOX.epiccash.com:443', ownServer: own),
        'aaaaaa…aaaaaa',
      );
      // Another server stays, since it is part of where the payment went.
      expect(
        shortAddress('${'a' * 52}@epicbox.epicnet.us', ownServer: own),
        'aaaaaa…aaaaaa@epicbox.epicnet.us',
      );
      expect(
        shortAddress('http://203.0.113.5:3415', ownServer: own),
        'http://203.0.113.5:3415',
      );
      final tx = fakeTx(kind: TxKind.sent, counterparty: _bob);
      expect(txTitle(tx, ownServer: own), 'esBobA…567890');
      final bob = fakeTx(counterparty: _bob);
      expect(
        paymentNotice(
          const ListenerEvent(
            kind: ListenerEventKind.finalized,
            slateId: 'x',
            message: 'raw',
          ),
          bob,
          ownServer: own,
        ),
        'Payment to esBobA…567890 completed',
      );
    });

    testWidgets('home rows on the wallet\'s own server show only the key', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.text('esBobA…567890'), findsOneWidget);
      expect(find.textContaining('esBobA…567890@'), findsNothing);
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
      // Cancelled is said by the chip, not the title.
      expect(find.text('Outgoing payment'), findsOneWidget);
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

    testWidgets(
      'an unknown address is the row title, the details show it once',
      (tester) async {
        final h = _Harness();
        await h.pump(tester);
        expect(find.text('esBobA…567890'), findsOneWidget);
        await _tap(tester, find.byKey(const ValueKey('tx-s:send-bob')));
        expect(find.text('Outgoing payment'), findsOneWidget);
        expect(find.textContaining('esBobA…'), findsNothing);
        expect(find.text(_bob), findsOneWidget);
        expect(find.byTooltip('Copy address'), findsOneWidget);
      },
    );

    testWidgets('large balances group thousands', (tester) async {
      final h = _Harness();
      h.session.summaryValue = _summary(spendable: _epic(1234.5678));
      await h.pump(tester);
      expect(find.text('1,234.5678 EPIC'), findsOneWidget);
    });
  });

  group('polish', () {
    const push = RemoteMessage(
      notification: RemoteNotification(title: 'Transaction waiting on relay'),
    );
    const connected = ListenerEvent(
      kind: ListenerEventKind.connected,
      message: 'a',
    );

    testWidgets('a push while connected gives no notice of its own', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.startPush(tester);
      h.session.listenerEvents.add(connected);
      await tester.pumpAndSettle();
      h.push.foregroundMessages.add(push);
      // The listener collects the same payment and gives the one notice.
      h.session.listenerEvents.add(
        ListenerEvent(
          kind: ListenerEventKind.received,
          slateId: 'from-alice',
          message: 'raw',
          amount: _epic(5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(pushNotice), findsNothing);
      expect(find.text('Transaction waiting on relay'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('5 EPIC on the way'), findsOneWidget);
    });

    testWidgets('home does not start payment notifications by itself', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(h.push.starts, 0);
    });

    testWidgets('a push while offline says the payment is waiting', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.startPush(tester);
      h.push.foregroundMessages.add(push);
      await tester.pumpAndSettle();
      expect(find.text(pushNotice), findsOneWidget);
      expect(find.text('Transaction waiting on relay'), findsNothing);
    });

    testWidgets('the chip row fades where more chips lie beyond the edge', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());
      final row = tester.state<FadingRowState>(find.byType(FadingRow));
      // The test font is wide, so the five chips do not fit 360 dp.
      expect(row.moreRight, isTrue);
      expect(row.moreLeft, isFalse);
      await tester.drag(
        find.widgetWithText(ChoiceChip, 'All'),
        const Offset(-2000, 0),
      );
      await tester.pumpAndSettle();
      expect(row.moreRight, isFalse);
      expect(row.moreLeft, isTrue);
    });
  });

  group('fix-3', () {
    test('an old mailbox send without an expiry says it can no longer complete', () {
      TxEntry send({required Duration age, BigInt? ttl, String? to = _bob}) =>
          fakeTx(
            kind: TxKind.sent,
            status: TxStatus.awaitingRecipient,
            createdAtUnix: _at(_now.subtract(age)),
            counterparty: to,
            ttlCutoffHeight: ttl,
          );
      expect(
        txExplanation(send(age: const Duration(days: 16)), _tip, now: _now),
        'Waiting for 16 days. The mailbox deletes payments after 7 days, so '
        'this one can no longer complete. Cancel it to unlock your funds, then '
        'send again.',
      );
      // Younger, or with an expiry (the TTL line covers it), or by file: the usual words.
      for (final tx in [
        send(age: const Duration(days: 10)),
        send(age: const Duration(days: 16), ttl: _tip + BigInt.one),
        send(age: const Duration(days: 16), to: null),
      ]) {
        expect(
          txExplanation(tx, _tip, now: _now),
          isNot(startsWith('Waiting for 16 days')),
        );
      }
    });

    test('broadcast again counts from when the send was finished', () {
      TxEntry posted(Duration finalized) => fakeTx(
        kind: TxKind.sent,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: _at(_now.subtract(const Duration(hours: 2))),
        finalizedAtUnix: _at(_now.subtract(finalized)),
        repostable: true,
      );
      expect(isStuck(posted(const Duration(minutes: 10)), _now), isFalse);
      expect(isStuck(posted(const Duration(minutes: 45)), _now), isTrue);
    });

    testWidgets('the pending card says the payment waits for an answer', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(
        find.text(
          '2 EPIC is waiting for the recipient\'s wallet to answer. Until then '
          'the funds stay locked. If it never answers, open the payment and '
          'tap Cancel payment.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('on its way'), findsNothing);
    });

    testWidgets('details of a 16-day-old send say to cancel and send again', (
      tester,
    ) async {
      final h = _Harness(
        transactions: [
          fakeTx(
            id: 5,
            slateId: 'old',
            kind: TxKind.sent,
            status: TxStatus.awaitingRecipient,
            createdAtUnix: _at(_now.subtract(const Duration(days: 16))),
            amountCredited: _epic(1),
            amountDebited: _epic(3),
            counterparty: _bob,
            cancellable: true,
          ),
        ],
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:old'));
      expect(find.textContaining('can no longer complete'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Cancel payment'),
        findsOneWidget,
      );
    });

    testWidgets('release funds asks first, then releases', (tester) async {
      final h = _Harness(
        transactions: [
          fakeTx(
            key: 's:refused',
            id: 6,
            kind: TxKind.sent,
            status: TxStatus.awaitingConfirmation,
            createdAtUnix: _at(_now.subtract(const Duration(days: 2))),
            finalizedAtUnix: _at(_now.subtract(const Duration(days: 2))),
            amountCredited: _epic(1),
            amountDebited: _epic(3),
            repostable: true,
            releasable: true,
          ),
        ],
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:refused'));
      final release = find.widgetWithText(OutlinedButton, 'Release funds');
      await _tap(tester, release);
      expect(
        find.text(
          'Use this only if the payment will never confirm. If it still does, '
          'you may see a wrong balance until you rescan.',
        ),
        findsOneWidget,
      );
      await _tap(tester, find.text('Keep waiting'));
      expect(h.session.releasedKeys, isEmpty);
      await _tap(tester, release);
      await _tap(tester, find.widgetWithText(FilledButton, 'Release funds'));
      expect(h.session.releasedKeys, ['s:refused']);
      expect(find.text('Funds released'), findsOneWidget);
    });

    testWidgets('no release button unless the core allows it', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      expect(find.text('Release funds'), findsNothing);
    });
  });

  group('scale and accessibility', () {
    List<TxEntry> many(int n) => [
      for (var i = 0; i < n; i++)
        fakeTx(
          id: i,
          slateId: 'many-$i',
          status: TxStatus.confirmed,
          createdAtUnix: _at(_now.subtract(Duration(hours: i))),
          amountCredited: _epic(i + 1),
          note: i == 1500 ? 'needle' : null,
        ),
    ];

    testWidgets('2,000 payments: history builds only the rows on screen', (
      tester,
    ) async {
      final h = _Harness(transactions: many(2000));
      await h.pump(tester, const HistoryScreen(), 1, const Size(1080, 2340));
      final built = find.byType(TxTile).evaluate().length;
      expect(built, greaterThan(0));
      expect(built, lessThan(40));
      // Search still reaches a row far down the list.
      await tester.enterText(
        find.widgetWithText(TextField, 'Search'),
        'needle',
      );
      await tester.pump(searchDebounce);
      await tester.pumpAndSettle();
      expect(find.byType(TxTile), findsOneWidget);
      expect(find.text('+1,501 EPIC'), findsOneWidget);
    });

    testWidgets('2,000 payments: home shows five', (tester) async {
      final h = _Harness(transactions: many(2000));
      await h.pump(tester);
      expect(find.byType(TxTile), findsNWidgets(recentActivityCount));
    });

    testWidgets('search waits for typing to pause', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());
      await tester.enterText(find.widgetWithText(TextField, 'Search'), 'rent');
      await tester.pump(const Duration(milliseconds: 100));
      // Still the whole list: the filter has not run yet.
      expect(find.byType(TxTile), findsNWidgets(4));
      await tester.pump(searchDebounce);
      await tester.pumpAndSettle();
      expect(find.byType(TxTile), findsOneWidget);
    });

    test('a row is one sentence', () {
      final tx = fakeTx(
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        amountDebited: _epic(10),
      );
      expect(
        txSpokenLabel(
          fakeTx(status: TxStatus.confirmed, amountCredited: _epic(10)),
          who: 'Alice',
          date: 'Today, 10:01',
          status: 'Completed',
          hidden: false,
        ),
        'Received 10 EPIC from Alice, completed, Today, 10:01',
      );
      expect(
        txSpokenLabel(
          tx,
          who: null,
          date: 'Today, 10:01',
          status: 'Waiting for recipient',
          hidden: true,
        ),
        'Sending a hidden amount, waiting for recipient, Today, 10:01',
      );
    });

    testWidgets('rows read as one sentence, the chip not twice', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = _Harness();
      h.session.contactsValue.add(
        const Contact(id: 'c1', name: 'Bob', address: _bob),
      );
      await h.pump(tester);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('tx-s:send-bob'))),
        matchesSemantics(
          label: 'Sending 2 EPIC to Bob, waiting for recipient, Today, 09:00',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('tx-s:from-alice'))),
        matchesSemantics(
          label: 'Received 5 EPIC, completed, Yesterday, 18:00',
          isButton: true,
          hasTapAction: true,
        ),
      );
      // The chip text is part of the sentence only.
      expect(find.bySemanticsLabel('Completed'), findsNothing);
      expect(find.bySemanticsLabel('Waiting for recipient'), findsNothing);
      handle.dispose();
    });

    testWidgets('hidden amounts: "Balance hidden" and no amount in rows', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = _Harness();
      h.store.values['app.hide_balances'] = 'true';
      await h.pump(tester);
      expect(find.bySemanticsLabel('Balance hidden'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('tx-s:from-alice'))),
        matchesSemantics(
          label: 'Received a hidden amount, completed, Yesterday, 18:00',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(find.bySemanticsLabel(RegExp('5 EPIC')), findsNothing);
      handle.dispose();
    });

    for (final (name, screen) in [
      ('home', const HomeScreen()),
      ('history', const HistoryScreen()),
      ('details of a pending send', const TxDetailsScreen(txKey: 's:send-bob')),
      ('details of a receive', const TxDetailsScreen(txKey: 's:from-alice')),
    ]) {
      testWidgets('$name: labelled tap targets of at least 48 dp', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final h = _Harness();
        await h.pump(tester, screen, 1, const Size(1080, 2340));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('fix-4', () {
    TxEntry cancelledSend({int? finalizedAt, BigInt? cutoff}) => fakeTx(
      slateId: 'late',
      kind: TxKind.sentCancelled,
      status: TxStatus.cancelled,
      amountCredited: _epic(1),
      amountDebited: _epic(3),
      counterparty: _bob,
      finalizedAtUnix: finalizedAt,
      ttlCutoffHeight: cutoff,
    );

    test('a finished send cancelled by the 14-day limit says to check', () {
      expect(
        txExplanation(
          cancelledSend(finalizedAt: _at(_now), cutoff: _tip - BigInt.one),
          _tip,
        ),
        'It did not reach the network within 14 days, so the wallet cancelled '
        'it. Check the recipient did not receive it before sending again.',
      );
      // Released by the user before the limit: it may still have left the device.
      expect(
        txExplanation(
          cancelledSend(finalizedAt: _at(_now), cutoff: _tip + BigInt.one),
          _tip,
        ),
        startsWith('The network never took it'),
      );
      // Unanswered and expired: nothing left the device.
      expect(
        txExplanation(cancelledSend(cutoff: _tip), _tip),
        startsWith('The recipient did not answer within 14 days'),
      );
      // Cancelled by the user.
      expect(
        txExplanation(cancelledSend(), _tip),
        'Cancelled. Nothing was sent, and the funds are spendable again.',
      );
    });

    test('a late answer to an expired send says nothing was sent', () {
      const late = ListenerEvent(
        kind: ListenerEventKind.error,
        slateId: 'late',
        message: 'payment expired',
      );
      expect(
        paymentNotice(
          late,
          cancelledSend(cutoff: _tip + BigInt.from(30)),
          contactName: 'Bob',
          tip: _tip,
        ),
        'Your payment to Bob expired before it was finished, so nothing was '
        'sent. The funds are unlocked.',
      );
      // A send the user cancelled long before its limit: the generic words.
      expect(
        paymentNotice(
          late,
          cancelledSend(cutoff: _tip + BigInt.from(10000)),
          tip: _tip,
        ),
        'A payment could not be completed.',
      );
      expect(
        paymentNotice(late, null, tip: _tip),
        'A payment could not be completed.',
      );
    });

    testWidgets('the expired notice arrives after the list refreshed', (
      tester,
    ) async {
      final h = _Harness(transactions: []);
      await h.pump(tester);
      // The core cancelled the send before telling the listener's subscriber.
      h.session.transactionsValue = [cancelledSend(cutoff: _tip)];
      h.session.listenerEvents.add(
        const ListenerEvent(
          kind: ListenerEventKind.error,
          slateId: 'late',
          message: 'payment expired',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('expired before it was finished'),
        findsOneWidget,
      );
      expect(find.text('View'), findsOneWidget);
    });
  });

  group('features-2', () {
    test('counts payments made since the last history export', () {
      final txs = _transactions();
      // Three made by this wallet; the restored one comes back with a restore anyway.
      expect(paymentsNotInBackup(txs, now: _now), 3);
      expect(
        paymentsNotInBackup(
          txs,
          now: _now,
          exportedAt: _at(DateTime(2026, 9, 29, 12)),
        ),
        2,
      );
      expect(
        paymentsNotInBackup(txs, now: _now, exportedAt: _at(_now)),
        isNull,
      );
      expect(paymentsNotInBackup(const [], now: _now), isNull);
      // A dismissal holds for 7 days.
      expect(
        paymentsNotInBackup(
          txs,
          now: _now,
          dismissedAt: _at(_now.subtract(const Duration(days: 3))),
        ),
        isNull,
      );
      expect(
        paymentsNotInBackup(
          txs,
          now: _now,
          dismissedAt: _at(_now.subtract(const Duration(days: 8))),
        ),
        3,
      );
    });

    const reminder =
        '3 payments are not in a history backup. A restore from your recovery '
        'phrase brings back only your balance.';

    testWidgets('home reminds to export, and export clears it', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.text(reminder), findsOneWidget);
      await _tap(tester, find.text('Export history backup'));
      expect(h.files.saved.single.name, 'epic-history-mainnet-20260930.wfeh');
      expect(find.text(reminder), findsNothing);
      expect(h.store.values['app.history_exported.mainnet'], '${_at(_now)}');
    });

    testWidgets('not now hides it for a week', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('Not now'));
      expect(find.text(reminder), findsNothing);
      expect(
        h.store.values['app.history_reminder_dismissed.mainnet'],
        '${_at(_now)}',
      );
    });

    testWidgets('stored export and dismissal times are read back', (
      tester,
    ) async {
      final h = _Harness();
      h.store.values['app.history_reminder_dismissed.mainnet'] =
          '${_at(_now.subtract(const Duration(days: 3)))}';
      // The floonet wallet's export does not count for mainnet.
      h.store.values['app.history_exported.floonet'] = '${_at(_now)}';
      await h.pump(tester);
      expect(find.text(reminder), findsNothing);
    });

    testWidgets('the phrase card comes first', (tester) async {
      final h = _Harness();
      h.store.values.remove('wallet.mainnet.backedUp');
      await h.pump(tester);
      expect(find.text('Back up your wallet'), findsOneWidget);
      expect(find.text(reminder), findsNothing);
    });

    testWidgets('send again opens Send with the same recipient', (
      tester,
    ) async {
      final h = _Harness(
        transactions: [
          fakeTx(
            slateId: 'paid',
            kind: TxKind.sent,
            status: TxStatus.confirmed,
            amountCredited: _epic(1),
            amountDebited: _epic(3),
            counterparty: _bob,
          ),
        ],
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:paid'));
      await _tap(tester, find.text('Send again'));
      expect(
        tester.widget<SendScreen>(find.byType(SendScreen)).recipient,
        _bob,
      );
    });

    testWidgets('no send again for pending sends or receives', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      expect(find.text('Send again'), findsNothing);
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
