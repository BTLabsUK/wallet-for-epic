import 'dart:async';
import 'dart:convert';

import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/amount.dart';
import 'package:epic_wallet/src/l10n.dart';
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
import 'package:epic_wallet/src/ui/theme/protocol.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

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

/// A session whose refresh stops at 40% until [gate] completes, then reports [refreshed].
class _SlowRefreshSession extends FakeWalletSession {
  _SlowRefreshSession({required this.refreshed})
    : super(summary: _summary(), transactions: _transactions());

  final WalletSummary refreshed;
  Completer<void> gate = Completer<void>();

  @override
  Stream<RefreshProgress> refresh({
    required BigInt minimumConfirmations,
  }) async* {
    refreshCalls++;
    yield const RefreshProgress(percent: 40, message: 'Scanning the chain');
    await gate.future;
    final error = refreshError;
    if (error != null) throw error;
    yield RefreshProgress(
      percent: 100,
      message: 'Up to date',
      summary: refreshed,
    );
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
  Future<bool> configured() async => true;

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
  // Unit tests below call the date helpers outside a widget tree, where no MaterialApp has
  // loaded the locale data.
  setUpAll(initializeDateFormatting);
  group('status words', () {
    test('name who or what the transaction waits for', () {
      String label(TxEntry tx) => txStatusLabel(englishStrings, tx, _tip);
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
      expect(
        txTitle(englishStrings, fakeTx(kind: TxKind.coinbase)),
        'Mining reward',
      );
      expect(
        txTitle(
          englishStrings,
          fakeTx(source: TxSource.restored),
          contactName: 'Bob',
        ),
        'Restored funds',
      );
      // The status never changes the title: pending, completed and cancelled read alike.
      for (final status in TxStatus.values) {
        final tx = fakeTx(
          kind: TxKind.sent,
          status: status,
          counterparty: _bob,
        );
        expect(txTitle(englishStrings, tx, contactName: 'Bob'), 'Bob');
        expect(
          txTitle(englishStrings, tx),
          'esBobA…567890@epicbox.epiccash.com',
        );
        expect(
          txTitle(englishStrings, fakeTx(kind: TxKind.sent, status: status)),
          'Outgoing payment',
        );
        expect(
          txTitle(englishStrings, fakeTx(status: status)),
          'Incoming payment',
        );
      }
      expect(
        txTitle(
          englishStrings,
          fakeTx(counterparty: 'http://203.0.113.5:3415'),
        ),
        'http://203.0.113.5:3415',
      );
    });

    test('details headings leave the address to the row below', () {
      final send = fakeTx(
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        counterparty: _bob,
      );
      expect(txHeading(englishStrings, send), 'Outgoing payment');
      expect(txHeading(englishStrings, send, contactName: 'Bob'), 'Bob');
      expect(
        txHeading(
          englishStrings,
          fakeTx(source: TxSource.imported, counterparty: _bob),
        ),
        'Incoming payment',
      );
      expect(
        txHeading(englishStrings, fakeTx(kind: TxKind.coinbase)),
        'Mining reward',
      );
    });

    test('EPIC amounts group thousands for display, not for fields', () {
      expect(epicText(englishStrings, _epic(1234.5678)), '1,234.5678 EPIC');
      expect(epicText(englishStrings, _epic(-1234567)), '-1,234,567 EPIC');
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
      expect(
        txStatusLabel(englishStrings, tx, _tip),
        'From backup, status unknown',
      );
      expect(matchesFilter(tx, HistoryFilter.pending), isFalse);
      expect(matchesFilter(tx, HistoryFilter.sent), isTrue);
      expect(
        txExplanation(englishStrings, tx, _tip),
        contains('Nothing is locked'),
      );
    });

    test('the expiry line counts down to the TTL height', () {
      final tx = fakeTx(
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        ttlCutoffHeight: _tip + BigInt.from(120),
      );
      expect(
        ttlLine(englishStrings, tx, _tip),
        'Cancels automatically if not completed by block 2,500,120 '
        '(in about 2 hours).',
      );
      expect(
        ttlLine(englishStrings, tx, _tip + BigInt.from(200)),
        startsWith('Expired'),
      );
      expect(
        ttlLine(
          englishStrings,
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
      final sections = groupHistory(englishStrings, _transactions(), _now);
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
      expect(find.text('Up to date. Connecting to epicbox…'), findsOneWidget);
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
      // Once in the status chip, once as the timeline's current step.
      expect(
        find.descendant(
          of: find.byType(TxStatusChip),
          matching: find.text('Waiting for recipient'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(StatusTimeline),
          matching: find.text('Waiting for recipient'),
        ),
        findsOneWidget,
      );
      expect(find.text('Payment started'), findsOneWidget);
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
      expect(txTitle(englishStrings, tx, ownServer: own), 'esBobA…567890');
      final bob = fakeTx(counterparty: _bob);
      expect(
        paymentNotice(
          englishStrings,
          const ListenerEvent(
            kind: ListenerEventKind.finalized,
            slateId: 'x',
            message: 'raw',
          ),
          bob,
          ownServer: own,
        ),
        'Payment to esBobA…567890 finished. Waiting for confirmations.',
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
        paymentNotice(englishStrings, received, tx),
        '1.5 EPIC on the way. It completes when the sender finishes.',
      );
      expect(
        paymentNotice(
          englishStrings,
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
        paymentNotice(englishStrings, received, null),
        'A payment is on the way. It completes when the sender finishes.',
      );
      expect(
        paymentNotice(englishStrings, received, tx, hidden: true),
        'A payment is on the way. It completes when the sender finishes.',
      );
      expect(
        paymentNotice(englishStrings, finalized, tx),
        'Payment to esBobA…567890@epicbox.epiccash.com finished. Waiting for confirmations.',
      );
      expect(
        paymentNotice(englishStrings, finalized, tx, contactName: 'Bob'),
        'Payment to Bob finished. Waiting for confirmations.',
      );
      expect(
        paymentNotice(englishStrings, finalized, null),
        'Payment finished. Waiting for confirmations.',
      );
      expect(
        paymentNotice(
          englishStrings,
          const ListenerEvent(
            kind: ListenerEventKind.error,
            message: 'relay error: Unauthorized x',
          ),
          null,
        ),
        'The epicbox server reported a problem. Retrying.',
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
      expect(
        find.text('Payment to Bob finished. Waiting for confirmations.'),
        findsOneWidget,
      );
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
        find.textContaining('Epicbox offline, reconnecting.'),
        findsOneWidget,
      );
      expect(find.textContaining('connection reset'), findsNothing);
    });
  });

  group('user-2', () {
    testWidgets('a payment notice appears in the slot without moving home', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final before = tester.getTopLeft(find.text('Spendable'));
      h.session.listenerEvents.add(
        ListenerEvent(
          kind: ListenerEventKind.received,
          slateId: 'from-alice',
          message: 'raw',
          amount: _epic(5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(noticeKey), findsOneWidget);
      expect(find.textContaining('5 EPIC on the way'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.getTopLeft(find.text('Spendable')), before);

      // "View" opens the payment and clears the notice.
      await _tap(tester, find.text('View'));
      expect(find.byType(TxDetailsScreen), findsOneWidget);
      expect(find.byKey(noticeKey), findsNothing);
    });

    testWidgets('a notice leaves after a few seconds, the newest wins', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final notices = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      ).read(noticeProvider.notifier);
      notices.show('First');
      await tester.pump(const Duration(seconds: 3));
      notices.show('Second');
      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      // The first one's timer does not cut the second short.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Second'), findsOneWidget);
      await tester.pump(noticeDuration);
      await tester.pumpAndSettle();
      expect(find.byKey(noticeKey), findsNothing);

      notices.show('Stays', persistent: true);
      await tester.pump(noticeDuration * 2);
      await tester.pumpAndSettle();
      expect(find.text('Stays'), findsOneWidget);
      await _tap(tester, find.byTooltip('Close'));
      expect(find.text('Stays'), findsNothing);
    });

    testWidgets('the slot keeps its height and grows only with large text', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(tester.getSize(find.byType(NoticeSlot)).height, noticeSlotHeight);
      await tester.pumpWidget(const SizedBox());
      await h.pump(tester, const HomeScreen(), 2);
      expect(
        tester.getSize(find.byType(NoticeSlot)).height,
        noticeSlotHeight * 2,
      );
    });
  });

  group('user-1', () {
    testWidgets('home shows the local balance at once, then the synced one', (
      tester,
    ) async {
      final session = _SlowRefreshSession(
        refreshed: _summary(spendable: _epic(20)),
      );
      final h = _Harness(session: session);
      await h.pump(tester);
      // Local figures while the refresh against the node runs, with its progress.
      expect(find.text('12.5 EPIC'), findsOneWidget);
      expect(find.textContaining('Syncing… 40%'), findsOneWidget);
      final syncBar = find.byWidgetPredicate(
        (w) => w is LinearProgressIndicator && w.semanticsLabel == 'Syncing',
      );
      expect(tester.widget<LinearProgressIndicator>(syncBar).value, 0.4);
      expect(find.byTooltip('Refresh'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.refresh),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );

      session.gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('20 EPIC'), findsOneWidget);
      expect(find.textContaining('Syncing'), findsNothing);
      expect(syncBar, findsNothing);
      expect(session.refreshCalls, 1);
    });

    testWidgets('a failed background refresh keeps the local balance', (
      tester,
    ) async {
      final session = _SlowRefreshSession(refreshed: _summary())
        ..refreshError = const WalletError(
          kind: WalletErrorKind.nodeUnreachable,
          message: 'node down',
        );
      final h = _Harness(session: session);
      await h.pump(tester);
      session.gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('12.5 EPIC'), findsOneWidget);
      expect(find.byType(ErrorText), findsOneWidget);
      expect(find.textContaining('Syncing'), findsNothing);
    });

    testWidgets('up to date and connected is all the status line says', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      h.session.listenerEvents.add(
        const ListenerEvent(kind: ListenerEventKind.connected, message: 'a'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Up to date.'), findsOneWidget);
      expect(find.textContaining('receive payments'), findsNothing);
    });

    testWidgets('the phrase card closes for good on this wallet', (
      tester,
    ) async {
      final h = _Harness();
      h.store.values.remove('wallet.mainnet.backedUp');
      await h.pump(tester);
      expect(find.text('Back up your recovery phrase.'), findsOneWidget);
      expect(find.text('Back up'), findsOneWidget);

      await _tap(tester, find.byTooltip('Dismiss'));
      expect(find.text('Back up your recovery phrase.'), findsNothing);
      expect(h.store.values['wallet.mainnet.backupCardDismissed'], '1');
      // The history reminder may show now that the phrase card is gone.
      expect(find.textContaining('not in a history backup'), findsOneWidget);

      // Still closed the next time home opens.
      await tester.pumpWidget(const SizedBox());
      await h.pump(tester);
      expect(find.text('Back up your recovery phrase.'), findsNothing);
    });

    testWidgets('deleting the wallet forgets the closed phrase card', (
      tester,
    ) async {
      final store = MemorySecretStore()
        ..values['wallet.mainnet.backupCardDismissed'] = '1';
      await WalletVault(
        store: store,
        biometrics: MemoryBiometricStore(),
        crypto: FakeVaultCrypto(),
      ).forget(Chain.mainnet);
      expect(store.values['wallet.mainnet.backupCardDismissed'], isNull);
    });
  });

  group('first run', () {
    testWidgets('an empty wallet has one line and the way to receive', (
      tester,
    ) async {
      final h = _Harness(transactions: const []);
      await h.pump(tester);
      expect(find.text('No payments yet.'), findsOneWidget);
      expect(find.textContaining('while this app is open'), findsNothing);
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
      // The local load, then the refresh; enrichment found the block time of the restored row,
      // so the list reloaded with it, and the balance was not asked again.
      expect(session.enrichCalls, 1);
      expect(session.summaryCalls, 1);
      expect(session.refreshCalls, 1);
      expect(session.transactionCalls, 3);
      expect(find.text('3 Aug, 08:00'), findsOneWidget);
      expect(find.text('1 Aug, 08:00'), findsNothing);

      // The minute refresh asks again; nothing changed, so no extra list load.
      final loads = session.transactionCalls;
      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      expect(session.enrichCalls, 2);
      expect(session.summaryCalls, 1);
      expect(session.refreshCalls, 2);
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
      // In the notice slot, not a snack bar.
      expect(find.byKey(noticeKey), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
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
      expect(find.text(englishStrings.homePushNotice), findsNothing);
      expect(find.text('Transaction waiting on relay'), findsNothing);
      expect(find.byKey(noticeKey), findsOneWidget);
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
      expect(find.text(englishStrings.homePushNotice), findsOneWidget);
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
    test('an old epicbox send without an expiry says it can no longer complete', () {
      TxEntry send({required Duration age, BigInt? ttl, String? to = _bob}) =>
          fakeTx(
            kind: TxKind.sent,
            status: TxStatus.awaitingRecipient,
            createdAtUnix: _at(_now.subtract(age)),
            counterparty: to,
            ttlCutoffHeight: ttl,
          );
      expect(
        txExplanation(
          englishStrings,
          send(age: const Duration(days: 16)),
          _tip,
          now: _now,
        ),
        'Waiting for 16 days. The epicbox deletes payments after 7 days, so '
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
          txExplanation(englishStrings, tx, _tip, now: _now),
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
          englishStrings,
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
          englishStrings,
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
          englishStrings,
          cancelledSend(finalizedAt: _at(_now), cutoff: _tip - BigInt.one),
          _tip,
        ),
        'It did not reach the network within 14 days, so the wallet cancelled '
        'it. Check the recipient did not receive it before sending again.',
      );
      // Released by the user before the limit: it may still have left the device.
      expect(
        txExplanation(
          englishStrings,
          cancelledSend(finalizedAt: _at(_now), cutoff: _tip + BigInt.one),
          _tip,
        ),
        startsWith('The network never took it'),
      );
      // Unanswered and expired: nothing left the device.
      expect(
        txExplanation(englishStrings, cancelledSend(cutoff: _tip), _tip),
        startsWith('The recipient did not answer within 14 days'),
      );
      // Cancelled by the user.
      expect(
        txExplanation(englishStrings, cancelledSend(), _tip),
        'Cancelled. Nothing was sent, and the funds are spendable again.',
      );
    });

    const coreExpired =
        'The answer to this payment came too late (block 2500030, limit '
        '2500000). The payment was cancelled: nothing was sent, and the funds '
        'unlock at the next refresh.';

    test(
      'an expired payment uses the core\'s words; other errors stay generic',
      () {
        const expired = ListenerEvent(
          kind: ListenerEventKind.expired,
          slateId: 'late',
          message: coreExpired,
        );
        // The core knows whether the funds are unlocked yet; the notice does not guess.
        expect(
          paymentNotice(
            englishStrings,
            expired,
            cancelledSend(cutoff: _tip),
            contactName: 'Bob',
          ),
          coreExpired,
        );
        expect(paymentNotice(englishStrings, expired, null), coreExpired);
        expect(
          paymentNotice(
            englishStrings,
            const ListenerEvent(
              kind: ListenerEventKind.error,
              slateId: 'late',
              message: 'raw',
            ),
            cancelledSend(cutoff: _tip),
          ),
          'A payment could not be completed.',
        );
      },
    );

    testWidgets('the expired notice arrives after the list refreshed', (
      tester,
    ) async {
      final h = _Harness(transactions: []);
      await h.pump(tester);
      // The core cancelled the send before telling the listener's subscriber.
      h.session.transactionsValue = [cancelledSend(cutoff: _tip)];
      h.session.listenerEvents.add(
        const ListenerEvent(
          kind: ListenerEventKind.expired,
          slateId: 'late',
          message: coreExpired,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(coreExpired), findsOneWidget);
      expect(find.textContaining('The funds are unlocked'), findsNothing);
      expect(find.text('View'), findsOneWidget);
    });
  });

  group('core fix-5', () {
    TxEntry cancelled(
      CancelReason? reason, {
      int? finalizedAt,
      BigInt? cutoff,
    }) => fakeTx(
      slateId: 'c',
      kind: TxKind.sentCancelled,
      status: TxStatus.cancelled,
      amountCredited: _epic(1),
      amountDebited: _epic(3),
      finalizedAtUnix: finalizedAt,
      ttlCutoffHeight: cutoff,
      cancelReason: reason,
    );

    test('the cancelled explanation follows the recorded reason', () {
      String say(TxEntry tx) => txExplanation(englishStrings, tx, _tip);
      expect(
        say(cancelled(CancelReason.user)),
        'Cancelled. Nothing was sent, and the funds are spendable again.',
      );
      // The user cancelled on day 2; from day 14 the old rule would blame the limit.
      expect(
        say(cancelled(CancelReason.user, cutoff: _tip - BigInt.one)),
        'Cancelled. Nothing was sent, and the funds are spendable again.',
      );
      // Released after a refusal, then past the limit: still a release.
      expect(
        say(
          cancelled(
            CancelReason.release,
            finalizedAt: _at(_now),
            cutoff: _tip - BigInt.one,
          ),
        ),
        startsWith('The network never took it'),
      );
      expect(
        say(cancelled(CancelReason.expiry, finalizedAt: _at(_now))),
        startsWith('It did not reach the network within 14 days'),
      );
      expect(
        say(cancelled(CancelReason.expiry)),
        startsWith('The recipient did not answer within 14 days'),
      );
      expect(
        say(cancelled(CancelReason.lateAnswer, cutoff: _tip - BigInt.one)),
        startsWith('The recipient answered after the 14-day limit'),
      );
      expect(
        say(cancelled(CancelReason.failed)),
        'It could not be delivered to the recipient, so the wallet cancelled '
        'it at once. Nothing was sent, and the funds are spendable again.',
      );
      // No recorded reason: the old rule.
      expect(
        say(cancelled(null, cutoff: _tip - BigInt.one)),
        startsWith('The recipient did not answer within 14 days'),
      );
      expect(say(cancelled(null)), startsWith('Cancelled. Nothing was sent'));
    });

    testWidgets('a delayed payment is announced once', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final delayed = ListenerEvent(
        kind: ListenerEventKind.delayed,
        slateId: 'send-bob',
        message:
            'Could not reach the node. The payment will finish once it can.',
        amount: _epic(2),
      );
      h.session.listenerEvents.add(delayed);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not reach the node. The payment will finish once it can.',
        ),
        findsOneWidget,
      );
      expect(find.text('A payment could not be completed.'), findsNothing);
      // Let the notice go, then the core retries the same payment: nothing new.
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();
      expect(find.byKey(noticeKey), findsNothing);
      h.session.listenerEvents
        ..add(
          const ListenerEvent(kind: ListenerEventKind.connected, message: 'a'),
        )
        // A new event object (no amount this time), so only the per-payment memory stops it.
        ..add(
          const ListenerEvent(
            kind: ListenerEventKind.delayed,
            slateId: 'send-bob',
            message: 'Could not reach the node. The payment will finish once it can.',
          ),
        );
      await tester.pumpAndSettle();
      expect(find.byKey(noticeKey), findsNothing);
      // Another payment still gets its own.
      h.session.listenerEvents.add(
        const ListenerEvent(
          kind: ListenerEventKind.delayed,
          slateId: 'other',
          message:
              'Could not reach the node. The payment will finish once it can.',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(noticeKey), findsOneWidget);
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
      expect(find.text('Back up your recovery phrase.'), findsOneWidget);
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

  group('fix-5', () {
    final exportedAt = _at(_now);
    TxEntry row(String key, TxStatus status, {String? note, int? at}) => fakeTx(
      key: key,
      status: status,
      createdAtUnix: at ?? _at(_now.subtract(const Duration(days: 1))),
      amountCredited: _epic(1),
      note: note,
    );

    test('settled and re-noted payments count, each once', () {
      final snapshot = HistoryExportSnapshot.of([
        row('s:was-pending', TxStatus.awaitingConfirmation),
        row('s:still-pending', TxStatus.awaitingConfirmation),
        row('s:noted', TxStatus.confirmed, note: 'Rent'),
        row('s:same', TxStatus.confirmed, note: 'Gift'),
      ]);
      final now = [
        row('s:was-pending', TxStatus.confirmed),
        row('s:still-pending', TxStatus.awaitingConfirmation),
        row('s:noted', TxStatus.confirmed, note: 'Rent for May'),
        row('s:same', TxStatus.confirmed, note: '  Gift '),
        // New since the export, and with a note: still one payment.
        row('s:new', TxStatus.confirmed, note: 'New', at: exportedAt + 60),
      ];
      expect(
        paymentsNotInBackup(
          now,
          now: _now,
          exportedAt: exportedAt,
          snapshot: snapshot,
        ),
        3,
      );
      // A cancelled one has settled too, and a removed note is a change.
      expect(
        paymentsNotInBackup(
          [
            row('s:was-pending', TxStatus.cancelled),
            row('s:noted', TxStatus.confirmed),
          ],
          now: _now,
          exportedAt: exportedAt,
          snapshot: snapshot,
        ),
        2,
      );
      // Nothing changed.
      expect(
        paymentsNotInBackup(
          [
            row('s:still-pending', TxStatus.awaitingConfirmation),
            row('s:same', TxStatus.confirmed, note: 'Gift'),
          ],
          now: _now,
          exportedAt: exportedAt,
          snapshot: snapshot,
        ),
        isNull,
      );
    });

    test('the snapshot keeps keys and note hashes, not notes', () {
      final snapshot = HistoryExportSnapshot.of([
        row('s:a', TxStatus.awaitingRecipient),
        row('s:b', TxStatus.confirmed, note: 'secret plans'),
        fakeTx(key: 'c:restored', source: TxSource.restored, note: 'x'),
      ]);
      final json = snapshot.toJson();
      expect(jsonEncode(json), isNot(contains('secret')));
      final back = HistoryExportSnapshot.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(back.pendingKeys, {'s:a'});
      expect(back.noteHashes.keys, ['s:b']);
      expect(
        back.noteHashes['s:b'],
        HistoryExportSnapshot.noteHash('secret plans'),
      );
    });

    test(
      'export stores the snapshot; deleting the wallet forgets it',
      () async {
        final store = MemorySecretStore();
        final container = ProviderContainer(
          overrides: [secretStoreProvider.overrideWithValue(store)],
        );
        addTearDown(container.dispose);
        final settings = container.read(appSettingsProvider.notifier);
        await container.read(appSettingsProvider.future);
        await settings.setHistoryExported(
          Chain.mainnet,
          _now,
          snapshot: HistoryExportSnapshot.of([
            row('s:a', TxStatus.awaitingRecipient),
          ]),
        );
        expect(
          store.values['app.history_export_snapshot.mainnet'],
          contains('s:a'),
        );
        // Read back as a fresh start would.
        container.invalidate(appSettingsProvider);
        final loaded = await container.read(appSettingsProvider.future);
        expect(loaded.historyExportSnapshots['mainnet']?.pendingKeys, {'s:a'});

        await settings.forgetHistoryBackup(Chain.mainnet);
        expect(store.values['app.history_export_snapshot.mainnet'], isNull);
        expect(
          container.read(appSettingsProvider).value?.historyExportSnapshots,
          isEmpty,
        );
      },
    );

    testWidgets('after an export, a payment that settled asks for a new one', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('Export history backup'));
      expect(find.textContaining('history backup.'), findsNothing);
      // The pending send to Bob is completed now; its record in the file is stale.
      h.session.transactionsValue = [
        for (final t in h.session.transactionsValue)
          t.key == 's:send-bob'
              ? fakeTx(
                  key: t.key,
                  slateId: t.slateId,
                  kind: t.kind,
                  status: TxStatus.confirmed,
                  createdAtUnix: t.createdAtUnix,
                  amountCredited: t.amountCredited,
                  amountDebited: t.amountDebited,
                  counterparty: t.counterparty,
                )
              : t,
      ];
      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      expect(
        find.text(
          '1 payment is new or changed since your last history backup. A '
          'restore from your recovery phrase brings back only your balance.',
        ),
        findsOneWidget,
      );
    });
  });

  group('shots-4', () {
    testWidgets(
      'the balance stays on top; the reminder sits by the waiting card',
      (tester) async {
        final h = _Harness();
        await h.pump(tester);
        double top(Finder f) => tester.getTopLeft(f).dy;
        final balance = top(find.text('12.5 EPIC'));
        final send = top(find.text('Send'));
        final waiting = top(
          find.text('A payment is waiting for the recipient'),
        );
        final reminder = top(find.textContaining('not in a history backup'));
        expect(balance, lessThan(send));
        expect(send, lessThan(waiting));
        expect(waiting, lessThan(reminder));
        expect(reminder, lessThan(top(find.text('Recent activity'))));
      },
    );

    testWidgets('add to contacts and send again share one row and style', (
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
            fee: _epic(0.008),
            counterparty: _bob,
          ),
        ],
      );
      // The test font is twice Roboto's width, so check the row on a wider view.
      await h.pump(
        tester,
        const TxDetailsScreen(txKey: 's:paid'),
        1,
        const Size(1800, 7200),
      );
      final add = find.widgetWithText(TextButton, 'Add to contacts');
      final again = find.widgetWithText(TextButton, 'Send again');
      expect(add, findsOneWidget);
      expect(again, findsOneWidget);
      expect(tester.getCenter(add).dy, tester.getCenter(again).dy);
      expect(find.byType(FilledButton), findsNothing);
      // Both lie between the address and the fee.
      final sentTo = tester.getTopLeft(find.text('Sent to')).dy;
      final fee = tester.getTopLeft(find.text('Fee')).dy;
      expect(tester.getCenter(add).dy, inExclusiveRange(sentTo, fee));
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
