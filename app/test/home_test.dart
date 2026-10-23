import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/amount.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/history_screen.dart';
import 'package:epic_wallet/src/ui/home_parts.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/shell_header.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/ui/theme/brand.dart';
import 'package:epic_wallet/src/ui/theme/protocol.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
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
  minimumConfirmations: BigInt.from(3),
  total: (spendable ?? _epic(12.5)) + _epic(2),
  spendable: spendable ?? _epic(12.5),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: _epic(2),
  validatedWithNode: true,
);

/// [_transactions] plus [extra] older confirmed payments, so the history reminder has enough
/// to count (3 wallet payments in [_transactions]).
List<TxEntry> _backlog([int extra = 8]) => [
  ..._transactions(),
  for (var i = 0; i < extra; i++)
    fakeTx(
      id: 100 + i,
      slateId: 'old-$i',
      kind: TxKind.received,
      status: TxStatus.confirmed,
      createdAtUnix: _at(DateTime(2026, 9, 1, 10 + i)),
      amountCredited: _epic(1),
    ),
];

/// A store state with the reminder first seen 40 days before [_now].
void _reminderDue(_Harness h) {
  h.store.values['app.history_reminder_first_seen.mainnet'] =
      '${_at(_now.subtract(const Duration(days: 40)))}';
}

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

  WalletSummary refreshed;
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

final Uri _apkUrl = Uri.parse('https://example.org/app.apk');

/// Update phases set by the test; Install and Try again only count.
class _FakeUpdates extends UpdateNotifier {
  int installs = 0;

  void set(UpdateState value) => state = value;

  @override
  Future<void> install() async => installs++;
}

class _Harness {
  _Harness({
    List<TxEntry>? transactions,
    double? price,
    bool scanSupported = false,
    this.chain = Chain.mainnet,
    this.still = false,
    this.settle = true,
    this.size,
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
    // Every send asks this PIN; the check goes through the service that opened the session.
    store.values['wallet.${chain.name}.pinSealed'] = fakeSealedPassword(_pin);
    this.session.owner = service;
    // The reminder is already tracked from today, so home does not write the setting.
    store.values['app.history_reminder_first_seen.${chain.name}'] =
        '${_at(_now)}';
  }

  final Chain chain;

  /// The wallet's PIN, which a send asks for.
  static const _pin = '123456';

  /// Reduced motion, for the states whose pulses never settle: a sync that does not end.
  final bool still;

  /// Whether [pump] waits for the screen to settle; false for pulses that run on.
  final bool settle;

  /// The view's size in physical pixels at 3 per dp, unless [pump] is given one.
  final Size? size;
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
        this.size ??
        (textScale == 1 ? const Size(1080, 7200) : const Size(1080, 2340));
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
          updatePlatformProvider.overrideWithValue(null),
          updateProvider.overrideWith(_FakeUpdates.new),
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
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: still,
            ),
            child: child!,
          ),
        ),
      ),
    );
    settle ? await tester.pumpAndSettle() : await _frames(tester);
  }
}

/// The Wallet tab's list, the vertical scrollable under the header.
Finder _walletList() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

/// The first list that scrolls down: the screen's own, never the shell's pages.
Finder _verticalList() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

/// The text of Wallet's figure, or null when it is not there.
String? _figure(WidgetTester tester) {
  final figure = find.byKey(balanceFigureKey);
  return figure.evaluate().isEmpty ? null : tester.widget<Text>(figure).data;
}

/// The value of the sync line along the app bar's foot, or null when it is not there.
double? _syncLine(WidgetTester tester) {
  final line = find.byKey(headerSyncLineKey);
  return line.evaluate().isEmpty
      ? null
      : tester.widget<LinearProgressIndicator>(line).value;
}

/// Taps the tab bar's [label] and lets the pages settle; with [settle] false it pumps a
/// second of frames instead, for screens with a pulse.
Future<void> _tab(
  WidgetTester tester,
  String label, {
  bool settle = true,
}) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  settle ? await tester.pumpAndSettle() : await _frames(tester);
}

/// [count] frames 100 ms apart.
Future<void> _frames(WidgetTester tester, [int count = 10]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Lets home's timer refresh it, and waits for the screen to settle.
Future<void> _reload(WidgetTester tester) async {
  await tester.pump(autoRefreshInterval);
  await tester.pumpAndSettle();
}

/// A summary with these balances in EPIC; total is their sum.
WalletSummary _balances({
  num spendable = 0,
  num confirming = 0,
  num waiting = 0,
  num locked = 0,
  num immature = 0,
}) => WalletSummary(
  lastConfirmedHeight: _tip,
  minimumConfirmations: BigInt.from(3),
  total: _epic(spendable + confirming + waiting + locked + immature),
  spendable: _epic(spendable),
  awaitingConfirmation: _epic(confirming),
  awaitingFinalization: _epic(waiting),
  immature: _epic(immature),
  locked: _epic(locked),
  validatedWithNode: true,
);

/// [text] in the balance tile of [kind].
Finder _inTile(BalanceKind kind, String text) => find.descendant(
  of: find.byKey(balanceTileKey(kind)),
  matching: find.text(text),
);

/// The left edge of the app bar's actions: the first of scan and lock. Invoices has no icon
/// in the bar any more.
double _actionsLeft(WidgetTester tester) => [
  for (final icon in [Icons.qr_code_scanner, Icons.lock_outline])
    for (final e
        in find
            .descendant(of: find.byType(AppBar), matching: find.byIcon(icon))
            .evaluate())
      tester.getRect(find.byElementPredicate((x) => x == e)).left,
].reduce(math.min);

/// The fade the node row's bars pulse with.
Finder get _nodePulse => find
    .descendant(
      of: find.descendant(
        of: find.byKey(nodeStatusKey).first,
        matching: find.byType(Pulse),
      ),
      matching: find.byType(FadeTransition),
    )
    .first;

/// How far the landing sweep has run, 0 when it does not show.
double _sweep(WidgetTester tester) {
  final p =
      (tester.widget<CustomPaint>(find.byKey(landingSweepKey)).painter!
              as SweepLinePainter)
          .progress;
  return p >= 1 ? 0 : p;
}

/// The backdrop light's opacity.
double _glow(WidgetTester tester) =>
    (tester.widget<CustomPaint>(find.byKey(backdropPaintKey)).painter!
            as ProtocolBackdropPainter)
        .glow
        .a;

/// How much of each title shows: Wallet's name, and Send's and Receive's figure.
({double wallet, double tab}) _titleOpacity(WidgetTester tester) {
  final layers = find.descendant(
    of: find.byType(ShellBarTitle),
    matching: find.byType(Opacity),
  );
  final values = [
    for (final e in layers.evaluate()) (e.widget as Opacity).opacity,
  ];
  return (wallet: values.first, tab: values[1]);
}

/// How much of Wallet's balance area shows.
double _balanceOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(walletBalanceKey, skipOffstage: false),
            matching: find.byType(Opacity, skipOffstage: false),
          )
          .first,
    )
    .opacity;

/// The words of the figure title on Send and Receive: the figure and the unit.
String _titleText(WidgetTester tester) {
  final span = tester.widget<Text>(find.byKey(titleFigureKey)).textSpan!;
  return [
    for (final part in (span as TextSpan).children!)
      if (part is TextSpan) part.text,
  ].join(' ');
}

/// The status words of the card row with [key], as its label opens: "Node online" of
/// "Node online, node.btlabs.uk, Synced".
String _statusWord(WidgetTester tester, Key key) =>
    _statusSemantics(tester, key).label.split(', ').first;

/// The hint of the card row with [key]: the old icon's tooltip detail.
String _statusTip(WidgetTester tester, Key key) =>
    _statusSemantics(tester, key).hint;

SemanticsData _statusSemantics(WidgetTester tester, Key key) =>
    tester.getSemantics(find.byKey(key).first).getSemanticsData();

/// The tab the shell's tab bar marks.
ShellTab _selectedTab(WidgetTester tester) =>
    ShellTab.values[tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .selectedIndex];

/// The text in Send's address field.
String _toField(WidgetTester tester) => tester
    .widget<TextField>(find.widgetWithText(TextField, 'To'))
    .controller!
    .text;

/// On the shell's Send tab: [to], 1 EPIC, review, Send.
Future<void> _sendOne(WidgetTester tester, String to) async {
  await _tab(tester, 'Send');
  await tester.enterText(find.widgetWithText(TextField, 'To'), to);
  await tester.pumpAndSettle();
  await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
  await tester.enterText(find.widgetWithText(TextField, 'Amount (EPIC)'), '1');
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
  await _tap(tester, find.text('Send 1 EPIC'));
  await tester.enterText(find.byType(TextField).last, _Harness._pin);
  await tester.pumpAndSettle();
}

/// Scrolls to [finder] when it is out of sight, then taps it. A control already in sight is
/// not scrolled to, so the shell's pages stay on their tab.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (!tester.any(finder.hitTestable())) {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }
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
        'Confirming 0/3',
      );
      expect(
        label(
          fakeTx(status: TxStatus.confirmed, blockHeight: _tip - BigInt.one),
        ),
        'Confirming 2/3',
      );
      expect(
        label(
          fakeTx(status: TxStatus.confirmed, blockHeight: _tip - BigInt.two),
        ),
        'Received',
      );
      expect(label(fakeTx(status: TxStatus.confirmed)), 'Received');
      expect(
        label(fakeTx(kind: TxKind.sent, status: TxStatus.confirmed)),
        'Sent',
      );
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

      expect(_figure(tester), '12.5');
      expect(find.text('≈ 6.25 USD'), findsOneWidget);
      expect(_statusWord(tester, nodeStatusKey), 'Node online');
      expect(_statusWord(tester, epicboxStatusKey), 'Epicbox connecting');
      // 2 EPIC are locked, so the Locked in sends tile says so.
      expect(_inTile(BalanceKind.locked, '2'), findsOneWidget);
      // The height is only in the tooltip.
      expect(
        _statusTip(tester, nodeStatusKey),
        contains('Synced at block 2,500,000'),
      );
      expect(find.textContaining('2,500,000'), findsNothing);

      // Recent activity: the pending send to Bob first, amounts with fiat.
      final tiles = find.byType(TxTile);
      expect(tiles, findsNWidgets(4));
      expect(tester.widget<TxTile>(tiles.first).tx.slateId, 'send-bob');
      expect(find.textContaining('Waiting for recipient'), findsOneWidget);
      expect(find.text('≈ 2.50 USD'), findsOneWidget);
      expect(find.textContaining('Today, 09:00'), findsOneWidget);
      expect(find.textContaining('Yesterday, 18:00'), findsOneWidget);

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

      await _tap(tester, find.text('View all 4'));
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
      expect(_figure(tester), hiddenAmount);
      expect(find.text('≈ 6.25 USD'), findsNothing);
      expect(find.text('+5 EPIC'), findsNothing);
      expect(find.text(hiddenAmount), findsWidgets);
      expect(h.store.values['app.hide_balances'], 'true');

      await _tap(tester, find.byTooltip('Show balances'));
      expect(_figure(tester), '12.5');
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
      expect(_figure(tester), '12.5');

      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      expect(_figure(tester), '20');
    });

    testWidgets('scan opens Send with the scanned address', (tester) async {
      // Reduced motion: the pending dot on Send's title would pulse on.
      final h = _Harness(scanSupported: true, still: true);
      h.scanner.codes.add(_bob);
      await h.pump(tester);
      await _tap(tester, find.byTooltip('Scan a QR code to send'));
      // The Send tab, not a pushed screen, with the recipient filled in.
      expect(find.byType(SendView), findsOneWidget);
      expect(_toField(tester), _bob);
      expect(_selectedTab(tester), ShellTab.send);
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

    testWidgets('a received message shows apart from the private note', (
      tester,
    ) async {
      final h = _Harness(
        transactions: [
          fakeTx(
            id: 3,
            slateId: 'from-alice',
            kind: TxKind.received,
            status: TxStatus.confirmed,
            blockHeight: _tip - BigInt.from(700),
            amountCredited: _epic(5),
            note: 'Rent share',
            messages: const [
              SlateMessage(role: SlateRole.sender, text: 'September rent'),
            ],
          ),
        ],
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:from-alice'));
      expect(find.text('Message from the sender'), findsOneWidget);
      expect(find.text('September rent'), findsOneWidget);
      expect(find.text('Your message'), findsNothing);
      expect(find.text('Private note, only on this device'), findsOneWidget);
      expect(find.text('Rent share'), findsOneWidget);
    });

    testWidgets('a finished send shows both parties\' messages', (
      tester,
    ) async {
      final h = _Harness(
        transactions: [
          fakeTx(
            id: 4,
            slateId: 'send-bob',
            kind: TxKind.sent,
            status: TxStatus.awaitingConfirmation,
            amountDebited: _epic(3),
            fee: _epic(0.008),
            counterparty: _bob,
            messages: const [
              SlateMessage(role: SlateRole.sender, text: 'for the pizza'),
              SlateMessage(role: SlateRole.receiver, text: 'thanks!'),
            ],
          ),
        ],
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      expect(find.text('Your message'), findsOneWidget);
      expect(find.text('for the pizza'), findsOneWidget);
      expect(find.text('Message from the recipient'), findsOneWidget);
      expect(find.text('thanks!'), findsOneWidget);
      expect(find.text('Message from the sender'), findsNothing);
    });

    testWidgets('a payment without messages shows none', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:from-alice'));
      expect(find.text('Message from the sender'), findsNothing);
      expect(find.text('Your message'), findsNothing);
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

    test('a repeat says it was already accepted, never "on the way"', () {
      const repeated = ListenerEvent(
        kind: ListenerEventKind.repeated,
        txId: 3,
        message: 'raw',
      );
      final tx = fakeTx(amountCredited: _epic(1.5), counterparty: _bob);
      expect(
        paymentNotice(englishStrings, repeated, tx),
        'This payment was already accepted. The sender got the same answer '
        'again; no second payment is on the way.',
      );
      expect(
        paymentNotice(englishStrings, repeated, tx, contactName: 'Alice'),
        'The payment from Alice was already accepted. They got the same '
        'answer again; no second payment is on the way.',
      );
    });

    testWidgets('a repeated payment neither reloads home nor counts as new', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final loads = h.session.transactionsCalls;
      h.session.listenerEvents.add(
        const ListenerEvent(
          kind: ListenerEventKind.repeated,
          txId: 3,
          message: 'answered again',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This payment was already accepted.'),
        findsOneWidget,
      );
      expect(find.textContaining('on the way. It completes'), findsNothing);
      expect(h.session.transactionsCalls, loads);
      // The notice still leads to the payment answered the first time.
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
      expect(_statusWord(tester, epicboxStatusKey), 'Epicbox offline');
      expect(
        _statusTip(tester, epicboxStatusKey),
        contains('Epicbox offline, reconnecting.'),
      );
      expect(find.textContaining('connection reset'), findsNothing);
    });
  });

  group('user-2', () {
    testWidgets('a payment notice docks above the balance and moves it down', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final before = tester.getTopLeft(find.byKey(balanceFigureKey));
      final headerBefore = tester.getRect(find.byKey(walletBalanceKey));
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
      // Docked between the app bar and the balance: nothing overlaps, and the balance
      // moved down by the dock's height.
      final card = tester.getRect(find.byKey(noticeKey));
      final header = tester.getRect(find.byKey(walletBalanceKey));
      final appBar = tester.getRect(find.byType(AppBar));
      final dock = tester.getSize(find.byType(NoticeDock)).height;
      expect(card.overlaps(appBar), isFalse);
      expect(card.overlaps(header), isFalse);
      expect(card.top, greaterThanOrEqualTo(appBar.bottom));
      expect(header.top, greaterThanOrEqualTo(card.bottom));
      expect(header.top, headerBefore.top + dock);
      expect(
        tester.getTopLeft(find.byKey(balanceFigureKey)),
        before.translate(0, dock),
      );

      // "View" opens the payment and clears the notice.
      await _tap(tester, find.text('View'));
      expect(find.byType(TxDetailsScreen), findsOneWidget);
      expect(find.byKey(noticeKey), findsNothing);
    });

    testWidgets('View on a notice that outlived home does nothing', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      h.session.listenerEvents.add(
        ListenerEvent(
          kind: ListenerEventKind.received,
          slateId: 'from-alice',
          message: 'raw',
          amount: _epic(5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('View'), findsOneWidget);
      // What a lock does: home goes, the unlock screen takes the whole stack.
      Navigator.of(tester.element(find.byType(HomeScreen))).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const SlotScaffold(body: SizedBox.expand()),
        ),
        (_) => false,
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsNothing);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TxDetailsScreen), findsNothing);
    });

    testWidgets('payment notices carry their level and View', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      for (final (kind, level) in [
        (ListenerEventKind.received, NoticeLevel.success),
        (ListenerEventKind.finalized, NoticeLevel.success),
        (ListenerEventKind.repeated, NoticeLevel.info),
        (ListenerEventKind.expired, NoticeLevel.warning),
        (ListenerEventKind.delayed, NoticeLevel.warning),
        (ListenerEventKind.error, NoticeLevel.error),
      ]) {
        expect(paymentNoticeLevel(kind), level, reason: kind.name);
        c.read(noticeProvider.notifier).clear();
        h.session.listenerEvents.add(
          ListenerEvent(kind: kind, slateId: 'from-alice', message: 'raw'),
        );
        await tester.pumpAndSettle();
        expect(c.read(noticeProvider)?.level, level, reason: kind.name);
      }
    });

    testWidgets('update phases become notices, the download with progress', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      final updates = c.read(updateProvider.notifier) as _FakeUpdates;
      final update = AvailableUpdate(
        versionName: '1.4.0',
        notes: '',
        apk: ReleaseApk(
          abi: 'arm64-v8a',
          versionCode: 19,
          url: _apkUrl,
          sha256: '',
          size: 1,
        ),
      );
      Notice? shown() => c.read(noticeProvider);

      updates.set(UpdateState(UpdatePhase.available, update: update));
      await tester.pumpAndSettle();
      expect(find.text('Version 1.4.0 is available.'), findsOneWidget);
      expect(shown()?.level, NoticeLevel.info);
      expect(shown()?.persistent, isTrue);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(updates.installs, 1);

      updates.set(
        UpdateState(UpdatePhase.downloading, update: update, progress: 0.42),
      );
      await tester.pumpAndSettle();
      expect(find.text('Downloading version 1.4.0… 42%'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(noticeKey),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(bar.value, 0.42);
      final id = shown()!.id;
      updates.set(
        UpdateState(UpdatePhase.downloading, update: update, progress: 0.5),
      );
      await tester.pumpAndSettle();
      expect(shown()!.id, id, reason: 'the same card, updated in place');
      expect(find.text('Downloading version 1.4.0… 50%'), findsOneWidget);

      updates.set(UpdateState(UpdatePhase.installing, update: update));
      await tester.pumpAndSettle();
      expect(find.text('Installing version 1.4.0…'), findsOneWidget);

      updates.set(UpdateState(UpdatePhase.failed, update: update));
      await tester.pumpAndSettle();
      expect(shown()?.level, NoticeLevel.error);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(updates.installs, 2);

      updates.set(const UpdateState(UpdatePhase.upToDate));
      await tester.pumpAndSettle();
      expect(find.text('This is the latest version.'), findsOneWidget);
      expect(shown()?.level, NoticeLevel.success);

      updates.set(UpdateState(UpdatePhase.available, update: update));
      await tester.pumpAndSettle();
      updates.set(const UpdateState(UpdatePhase.idle));
      await tester.pumpAndSettle();
      expect(shown(), isNull);
    });
  });

  group('user-1', () {
    testWidgets('home shows the local balance at once, then the synced one', (
      tester,
    ) async {
      final session = _SlowRefreshSession(
        refreshed: _summary(spendable: _epic(20)),
      );
      final h = _Harness(session: session, still: true);
      await h.pump(tester);
      // Local figures while the refresh against the node runs, with its progress.
      expect(_figure(tester), '12.5');
      expect(_statusWord(tester, nodeStatusKey), 'Node syncing 40%');
      // The line along the app bar's foot is drawn as far as the sync has come, and no
      // other progress shows.
      expect(_syncLine(tester), 0.4);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // Pull to refresh replaced the button.
      expect(find.byTooltip('Refresh'), findsNothing);

      session.gate.complete();
      await tester.pumpAndSettle();
      expect(_figure(tester), '20');
      expect(find.textContaining('Syncing'), findsNothing);
      expect(_syncLine(tester), isNull);
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
      final h = _Harness(session: session, still: true);
      await h.pump(tester);
      session.gate.complete();
      await tester.pumpAndSettle();
      expect(_figure(tester), '12.5');
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
      expect(_statusWord(tester, nodeStatusKey), 'Node online');
      expect(_statusWord(tester, epicboxStatusKey), 'Epicbox online');
      expect(find.textContaining('Up to date'), findsNothing);
      expect(find.textContaining('receive payments'), findsNothing);
    });

    testWidgets('the phrase card closes for good on this wallet', (
      tester,
    ) async {
      final h = _Harness(transactions: _backlog());
      _reminderDue(h);
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
        service: FakeWalletService(),
      ).forget(Chain.mainnet);
      expect(store.values['wallet.mainnet.backupCardDismissed'], isNull);
    });
  });

  group('first run', () {
    testWidgets('an empty wallet has one line; Receive is the tab beside it', (
      tester,
    ) async {
      final h = _Harness(transactions: const []);
      await h.pump(tester);
      expect(find.text('No payments yet.'), findsOneWidget);
      expect(find.textContaining('while this app is open'), findsNothing);
      expect(find.text('See all'), findsNothing);
      expect(find.text('Show my address'), findsNothing);
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
      expect(find.textContaining('3 Aug, 08:00'), findsOneWidget);
      expect(find.textContaining('1 Aug, 08:00'), findsNothing);

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
      expect(
        find.textContaining('From backup, status unknown'),
        findsOneWidget,
      );
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
      expect(_figure(tester), '1,234.5678');
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
        find.text('2 EPIC stays locked until the recipient\'s wallet answers.'),
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
          status: 'Received',
          hidden: false,
        ),
        'Received 10 EPIC from Alice, received, Today, 10:01',
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
          label: 'Received 5 EPIC, received, Yesterday, 18:00',
          isButton: true,
          hasTapAction: true,
        ),
      );
      // The chip text is part of the sentence only.
      expect(find.bySemanticsLabel('Received'), findsNothing);
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
      // Wallet's figure reads its caption too (D-10).
      expect(
        find.bySemanticsLabel('Spendable: Balance hidden'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('tx-s:from-alice'))),
        matchesSemantics(
          label: 'Received a hidden amount, received, Yesterday, 18:00',
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
      await tester.pump(noticeDuration(NoticeLevel.warning, action: true));
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
      expect(unbackedPayments(txs), 3);
      expect(
        unbackedPayments(txs, exportedAt: _at(DateTime(2026, 9, 29, 12))),
        2,
      );
      expect(unbackedPayments(txs, exportedAt: _at(_now)), 0);
      expect(unbackedPayments(const []), 0);
    });

    group('when to remind', () {
      final long = _at(_now.subtract(const Duration(days: 31)));
      int? remind(
        List<TxEntry> txs, {
        int? exportedAt,
        int? dismissedAt,
        int? firstSeenAt,
        DateTime? at,
      }) => paymentsNotInBackup(
        txs,
        now: at ?? _now,
        exportedAt: exportedAt,
        dismissedAt: dismissedAt,
        firstSeenAt: firstSeenAt,
      );
      int daysAgo(int d, [Duration extra = Duration.zero]) =>
          _at(_now.subtract(Duration(days: d)).add(extra));

      test('the constants', () {
        expect(historyReminderMinPayments, 10);
        expect(historyReminderPause, const Duration(days: 30));
      });

      test('needs 10 payments, 9 are not enough', () {
        expect(remind(_backlog(6), firstSeenAt: long), isNull); // 9
        expect(remind(_backlog(7), firstSeenAt: long), 10);
        expect(remind(_backlog(8), firstSeenAt: long), 11);
      });

      test('30 days since the export, 29 are not enough', () {
        // The export is older than every payment here, so all still count.
        final txs = _backlog(8);
        final early = _at(DateTime(2026, 7, 1));
        expect(early, lessThan(daysAgo(40)));
        expect(
          remind(txs, exportedAt: daysAgo(29, const Duration(hours: 1))),
          isNull,
        );
        expect(remind(txs, exportedAt: daysAgo(30)), 11);
        expect(remind(txs, exportedAt: early), 11);
      });

      test('30 days since the dismissal, 29 are not enough', () {
        final txs = _backlog(8);
        expect(
          remind(
            txs,
            dismissedAt: daysAgo(29, const Duration(hours: 1)),
            firstSeenAt: long,
          ),
          isNull,
        );
        expect(remind(txs, dismissedAt: daysAgo(30), firstSeenAt: long), 11);
      });

      test('the later of export and dismissal decides', () {
        final txs = _backlog(8);
        // Old export, fresh dismissal: held.
        expect(
          remind(txs, exportedAt: daysAgo(60), dismissedAt: daysAgo(5)),
          isNull,
        );
        // Fresh export (before the payments above would count) with an old dismissal: held.
        expect(
          remind(txs, exportedAt: daysAgo(5), dismissedAt: daysAgo(60)),
          isNull,
        );
        // Both old: shown.
        expect(
          remind(txs, exportedAt: daysAgo(45), dismissedAt: daysAgo(40)),
          11,
        );
      });

      test(
        'a never exported, never dismissed wallet counts from first seen',
        () {
          final txs = _backlog(8);
          expect(remind(txs), isNull); // first seen not stored yet
          expect(remind(txs, firstSeenAt: daysAgo(1)), isNull);
          expect(
            remind(txs, firstSeenAt: daysAgo(29, const Duration(hours: 1))),
            isNull,
          );
          expect(remind(txs, firstSeenAt: daysAgo(30)), 11);
          // An export or dismissal later than first seen restarts the wait.
          expect(
            remind(txs, firstSeenAt: daysAgo(60), dismissedAt: daysAgo(2)),
            isNull,
          );
        },
      );

      test('never right after a payment', () {
        TxEntry fresh(Duration age) => fakeTx(
          id: 999,
          slateId: 'fresh',
          kind: TxKind.received,
          status: TxStatus.awaitingConfirmation,
          createdAtUnix: _at(_now.subtract(age)),
          amountCredited: _epic(1),
        );
        final base = _backlog(8);
        expect(
          remind([
            ...base,
            fresh(const Duration(minutes: 2)),
          ], firstSeenAt: long),
          isNull,
        );
        expect(
          remind([
            ...base,
            fresh(const Duration(minutes: 9)),
          ], firstSeenAt: long),
          isNull,
        );
        expect(
          remind([
            ...base,
            fresh(const Duration(minutes: 11)),
          ], firstSeenAt: long),
          12,
        );
      });
    });

    const reminder =
        '11 payments are not in a history backup. A restore from your recovery '
        'phrase brings back only your balance.';

    testWidgets('home reminds to export, and export clears it', (tester) async {
      final h = _Harness(transactions: _backlog());
      _reminderDue(h);
      await h.pump(tester);
      expect(find.text(reminder), findsOneWidget);
      await _tap(tester, find.text('Export history backup'));
      expect(h.files.saved.single.name, 'epic-history-mainnet-20260930.wfeh');
      expect(find.text(reminder), findsNothing);
      expect(h.store.values['app.history_exported.mainnet'], '${_at(_now)}');
    });

    testWidgets('not now hides it for 30 days', (tester) async {
      final h = _Harness(transactions: _backlog());
      _reminderDue(h);
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
      final h = _Harness(transactions: _backlog());
      _reminderDue(h);
      h.store.values['app.history_reminder_dismissed.mainnet'] =
          '${_at(_now.subtract(const Duration(days: 29)))}';
      // The floonet wallet's export does not count for mainnet.
      h.store.values['app.history_exported.floonet'] = '${_at(_now)}';
      await h.pump(tester);
      expect(find.text(reminder), findsNothing);
    });

    testWidgets('a new wallet is not reminded; its first-seen time is stored', (
      tester,
    ) async {
      final h = _Harness(transactions: _backlog());
      h.store.values.remove('app.history_reminder_first_seen.mainnet');
      await h.pump(tester);
      expect(find.text(reminder), findsNothing);
      expect(
        h.store.values['app.history_reminder_first_seen.mainnet'],
        '${_at(_now)}',
      );
    });

    testWidgets('the phrase card comes first', (tester) async {
      final h = _Harness(transactions: _backlog());
      _reminderDue(h);
      h.store.values.remove('wallet.mainnet.backedUp');
      await h.pump(tester);
      expect(find.text('Back up your recovery phrase.'), findsOneWidget);
      expect(find.text(reminder), findsNothing);
    });

    testWidgets('send again opens Send with the same recipient', (
      tester,
    ) async {
      final h = _Harness(
        still: true,
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
      await h.pump(tester);
      await _tap(tester, find.byKey(const ValueKey('tx-s:paid')));
      await _tap(tester, find.text('Send again'));
      // Details close, and the shell shows Send with the recipient.
      expect(find.byType(TxDetailsScreen), findsNothing);
      expect(_selectedTab(tester), ShellTab.send);
      expect(_toField(tester), _bob);
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
        unbackedPayments(now, exportedAt: exportedAt, snapshot: snapshot),
        3,
      );
      // A cancelled one has settled too, and a removed note is a change.
      expect(
        unbackedPayments(
          [
            row('s:was-pending', TxStatus.cancelled),
            row('s:noted', TxStatus.confirmed),
          ],
          exportedAt: exportedAt,
          snapshot: snapshot,
        ),
        2,
      );
      // Nothing changed.
      expect(
        unbackedPayments(
          [
            row('s:still-pending', TxStatus.awaitingConfirmation),
            row('s:same', TxStatus.confirmed, note: 'Gift'),
          ],
          exportedAt: exportedAt,
          snapshot: snapshot,
        ),
        0,
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
      final h = _Harness(transactions: _backlog());
      _reminderDue(h);
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
      // One changed payment is far below the 10 the reminder waits for.
      expect(find.textContaining('changed since your last'), findsNothing);
      final snapshot = h.store.values['app.history_export_snapshot.mainnet'];
      expect(snapshot, isNotNull);
    });
  });

  group('shots-4', () {
    testWidgets(
      'the balance stays on top; the reminder sits by the waiting card',
      (tester) async {
        final h = _Harness(transactions: _backlog());
        _reminderDue(h);
        await h.pump(tester);
        double top(Finder f) => tester.getTopLeft(f).dy;
        final balance = top(find.byKey(balanceFigureKey));
        final waiting = top(
          find.text('A payment is waiting for the recipient'),
        );
        final reminder = top(find.textContaining('not in a history backup'));
        expect(balance, lessThan(waiting));
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
        // Reduced motion: at this size Wallet's pending line would scroll on.
        final h = _Harness(price: 0.5, still: true);
        await h.pump(tester, screen, 2);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(screen.runtimeType)),
          ).scale(10),
          20,
        );
        expect(tester.takeException(), isNull);
        // Every part of the list is laid out, not only the first screen.
        await tester.fling(_verticalList(), const Offset(0, -3000), 3000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('an empty home at text scale 2 has no overflow', (
      tester,
    ) async {
      final h = _Harness(transactions: const [], still: true);
      await h.pump(tester, const HomeScreen(), 2);
      await tester.fling(_walletList(), const Offset(0, -3000), 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('shell', () {
    final payee = '${'b' * 52}@epicbox.epiccash.com';

    testWidgets('a tap from Send to Receive keeps the figure title on the way', (
      tester,
    ) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester);
      await _tab(tester, 'Send', settle: false);
      for (final (from, to) in [('Send', 'Receive'), ('Receive', 'Send')]) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(to),
          ),
        );
        // Every frame of the move: Wallet's title and figure stay out of sight.
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(_titleOpacity(tester), (wallet: 0.0, tab: 1.0));
          expect(_balanceOpacity(tester), 0, reason: '$from to $to');
        }
        await _frames(tester);
      }
      // A tap to Wallet still opens it.
      await _tab(tester, 'Wallet', settle: false);
      expect(_titleOpacity(tester), (wallet: 1.0, tab: 0.0));
      expect(_balanceOpacity(tester), 1);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('a docked notice overlaps nothing at text scale $scale', (
        tester,
      ) async {
        final h = _Harness(still: true);
        await h.pump(tester, const HomeScreen(), scale);
        final c = ProviderScope.containerOf(
          tester.element(find.byType(HomeScreen)),
        );
        (c.read(updateProvider.notifier) as _FakeUpdates).set(
          UpdateState(
            UpdatePhase.available,
            update: AvailableUpdate(
              versionName: '1.6.1',
              notes: '',
              apk: ReleaseApk(
                abi: 'arm64-v8a',
                versionCode: 23,
                url: _apkUrl,
                sha256: '',
                size: 1,
              ),
            ),
          ),
        );
        for (final (tab, below) in [
          ('Send', find.byType(SendView)),
          ('Receive', find.byType(ReceiveView)),
          ('Wallet', find.byKey(walletBalanceKey)),
        ]) {
          await _tab(tester, tab);
          expect(tester.takeException(), isNull, reason: tab);
          final card = tester.getRect(find.byKey(noticeKey));
          final page = tester.getRect(below);
          expect(card.overlaps(tester.getRect(find.byType(AppBar))), isFalse);
          expect(page.top, greaterThanOrEqualTo(card.bottom), reason: tab);
          expect(find.text('Update'), findsOneWidget);
        }
      });
    }

    testWidgets('a tap changes tab; app bar, title and tab bar stay', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final title = tester.element(find.byType(ShellBarTitle));
      final bar = tester.element(find.byType(NavigationBar));
      final appBar = tester.element(find.byType(AppBar));
      expect(_selectedTab(tester), ShellTab.wallet);

      await _tab(tester, 'Receive', settle: false);
      expect(_selectedTab(tester), ShellTab.receive);
      expect(find.byType(ReceiveView), findsOneWidget);
      await _tab(tester, 'Send', settle: false);
      expect(_selectedTab(tester), ShellTab.send);
      expect(find.byType(SendView), findsOneWidget);

      expect(tester.element(find.byType(ShellBarTitle)), same(title));
      expect(tester.element(find.byType(NavigationBar)), same(bar));
      expect(tester.element(find.byType(AppBar)), same(appBar));
    });

    testWidgets('a swipe changes tab; title and tab bar stay', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final title = tester.element(find.byType(ShellBarTitle));
      final bar = tester.element(find.byType(NavigationBar));

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await _frames(tester);
      expect(_selectedTab(tester), ShellTab.receive);
      expect(find.byType(ReceiveView), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await _frames(tester);
      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await _frames(tester);
      expect(_selectedTab(tester), ShellTab.send);

      expect(tester.element(find.byType(ShellBarTitle)), same(title));
      expect(tester.element(find.byType(NavigationBar)), same(bar));
    });

    testWidgets(
      'Send and Receive: the figure is the title, with what is on hold',
      (tester) async {
        final h = _Harness(price: 0.5);
        await h.pump(tester);
        // On Wallet the title is the name; the figure title waits out of sight.
        expect(_titleOpacity(tester), (wallet: 1.0, tab: 0.0));
        expect(find.text('Epic Cash'), findsOneWidget);
        for (final tab in ['Send', 'Receive']) {
          await _tab(tester, tab, settle: false);
          expect(_titleOpacity(tester), (wallet: 0.0, tab: 1.0), reason: tab);
          expect(_titleText(tester), '12.5 EPIC', reason: tab);
          // 2 EPIC are locked: the line under the figure says so, as Wallet's does.
          final pending = find.byKey(titlePendingKey);
          expect(tester.widget<Text>(pending).data, '2 on hold', reason: tab);
          expect(
            tester.getRect(pending).top,
            greaterThanOrEqualTo(
              tester.getRect(find.byKey(titleFigureKey)).bottom,
            ),
          );
          expect(
            tester.getRect(pending).bottom,
            lessThanOrEqualTo(tester.getRect(find.byType(AppBar)).bottom),
          );
          // No figure, fiat, caption or pending line in the body.
          expect(find.byKey(balanceFigureKey).hitTestable(), findsNothing);
          expect(find.text('Spendable'), findsNothing);
        }
        // Nothing pending: no line, the figure alone.
        h.session.summaryValue = WalletSummary(
          lastConfirmedHeight: _tip,
          minimumConfirmations: BigInt.from(3),
          total: _epic(12.5),
          spendable: _epic(12.5),
          awaitingConfirmation: BigInt.zero,
          awaitingFinalization: BigInt.zero,
          immature: BigInt.zero,
          locked: BigInt.zero,
          validatedWithNode: true,
        );
        await tester.pump(autoRefreshInterval);
        await tester.pumpAndSettle();
        expect(find.byKey(titlePendingKey), findsNothing);
        expect(_titleText(tester), '12.5 EPIC');
        // Hidden: the title hides the figure too.
        await _tab(tester, 'Wallet');
        await _tap(tester, find.byTooltip('Hide balances'));
        await _tab(tester, 'Send');
        expect(_titleText(tester), '$hiddenAmount EPIC');
      },
    );

    testWidgets('with reduced motion the syncing node holds still', (
      tester,
    ) async {
      final session = _SlowRefreshSession(refreshed: _summary());
      final h = _Harness(session: session, still: true);
      await h.pump(tester);
      double opacityOf(Finder fade) =>
          tester.widget<FadeTransition>(fade).opacity.value;
      final node = _nodePulse;
      for (var i = 0; i < 5; i++) {
        expect(opacityOf(node), 1);
        await tester.pump(const Duration(milliseconds: 300));
      }
      // Nothing is left running: the screen settles.
      await tester.pumpAndSettle();
      session.gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a swipe cross-fades the title and the figure', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      // A little past halfway to Receive: about 0.4 open.
      await gesture.moveBy(const Offset(-215, 0));
      await tester.pump();
      final (:wallet, :tab) = _titleOpacity(tester);
      expect(wallet, allOf(greaterThan(0), lessThan(1)));
      expect(tab, allOf(greaterThan(0), lessThan(1)));
      expect(_balanceOpacity(tester), wallet);
      // The page under the app bar does not move up or down.
      expect(
        tester.getRect(find.byKey(walletBalanceKey)).top,
        tester.getRect(find.byType(AppBar)).bottom + progressSlotHeight,
      );
      expect(tester.takeException(), isNull);
      await gesture.up();
      await _frames(tester);
      expect(_selectedTab(tester), ShellTab.receive);
    });

    testWidgets('Wallet: caption, figure, gold EPIC, fiat row, tiles', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = _Harness(price: 0.5, size: const Size(1236, 2340));
      await h.pump(tester);
      final area = tester.getRect(find.byKey(walletBalanceKey));
      final figure = tester.getRect(find.byKey(balanceFigureKey));
      final unit = tester.getRect(find.byKey(balanceUnitKey));
      final fiat = tester.getRect(find.byKey(fiatValueKey));
      final caption = tester.getRect(find.byKey(balanceCaptionKey));
      final style = tester.widget<Text>(find.byKey(balanceFigureKey)).style!;
      expect(style.fontSize, figureSize);
      expect(style.fontFamily, montserrat);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(_figure(tester), '12.5');
      // EPIC small and gold at the figure's top right.
      final unitText = tester.widget<Text>(find.byKey(balanceUnitKey));
      final tokens = protocolLight;
      expect(unitText.data, 'EPIC');
      expect(unitText.style!.fontSize, 15);
      expect(unitText.style!.color, tokens.accentText);
      expect(unitText.style!.letterSpacing, closeTo(2.1, 0.01));
      expect(unit.left, closeTo(figure.right + 8, 0.5));
      expect(unit.top, closeTo(figure.top + 7, 0.5));
      // The caption says what the figure is, above it.
      expect(find.text('Available to spend'), findsOneWidget);
      expect(caption.bottom, lessThanOrEqualTo(figure.top));
      // No panel, dots, breakdown, life line or status words.
      expect(
        find.ancestor(
          of: find.byKey(balanceFigureKey),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).border != null,
          ),
        ),
        findsNothing,
      );
      // Centred as a unit: the figure and its EPIC, in the area's middle.
      expect(
        figure.expandToInclude(unit).center.dx,
        closeTo(area.center.dx, 1),
      );
      expect(find.text('Spendable'), findsNothing);
      expect(find.textContaining('not spendable yet'), findsNothing);
      expect(find.byKey(walletStatusesKey), findsNothing);
      expect(find.byType(BalanceHelp), findsNothing);
      // The fiat value in mono under the figure, then the eye.
      expect(find.text('≈ 6.25 USD'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('≈ 6.25 USD')).style!.fontFamily,
        jetBrainsMono,
      );
      expect(fiat.top, greaterThanOrEqualTo(figure.bottom));
      final eye = tester.getRect(find.byTooltip('Hide balances'));
      expect(eye.left, greaterThanOrEqualTo(fiat.right));
      expect(eye.center.dy, closeTo(fiat.center.dy, 1));
      // The locked 2 EPIC is a tile under that row, not a line.
      expect(find.byKey(pendingLineKey), findsNothing);
      final tile = find.byKey(balanceTileKey(BalanceKind.locked));
      expect(tile, findsOneWidget);
      expect(tester.getRect(tile).top, greaterThanOrEqualTo(eye.bottom));
      expect(_inTile(BalanceKind.locked, 'Locked in sends'), findsOneWidget);
      expect(_inTile(BalanceKind.locked, '2'), findsOneWidget);
      expect(
        tester.getSemantics(tile),
        matchesSemantics(
          label: 'Locked in sends: 2',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(find.bySemanticsLabel('Spendable: 12.5 EPIC'), findsOneWidget);
      handle.dispose();
    });

    // DEFECT (home_parts.dart _BalanceTile): the tile's Semantics is a button with
    // excludeSemantics and no onTap, so the InkWell's tap action is dropped and a screen
    // reader cannot press it.
    testWidgets(
      'a balance tile with a value can be pressed by a screen reader',
      (tester) async {
        final handle = tester.ensureSemantics();
        final h = _Harness(still: true);
        await h.pump(tester);
        expect(
          tester.getSemantics(find.byKey(balanceTileKey(BalanceKind.locked))),
          matchesSemantics(
            label: 'Locked in sends: 2',
            isButton: true,
            hasTapAction: true,
          ),
        );
        handle.dispose();
      },
      
    );

    testWidgets('the balance tiles: each pending balance, then Total', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = _Harness(still: true);
      await h.pump(tester);
      h.session.summaryValue = _balances(
        spendable: 3.25,
        confirming: 2,
        waiting: 0.5,
        locked: 5,
        immature: 16,
      );
      await _reload(tester);
      // One tile per balance that is not zero, in a fixed order, Total last.
      const order = [
        (BalanceKind.confirming, 'Confirming', '2'),
        (BalanceKind.waitingSender, 'Waiting for sender', '0.5'),
        (BalanceKind.locked, 'Locked in sends', '5'),
        (BalanceKind.total, 'Total', '26.75'),
      ];
      // A grid, nothing scrolls sideways: every tile is on screen, in reading order (top
      // to bottom, then left to right), inside the row's bounds.
      expect(
        find.descendant(
          of: find.byKey(balanceTilesKey),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      final grid = tester.getRect(find.byKey(balanceTilesKey));
      final places = <(double, double)>[];
      for (final (kind, label, value) in order) {
        expect(_inTile(kind, label), findsOneWidget, reason: label);
        expect(_inTile(kind, value), findsOneWidget, reason: label);
        final tile = tester.getRect(find.byKey(balanceTileKey(kind)));
        expect(tile.left, greaterThanOrEqualTo(grid.left), reason: label);
        expect(tile.right, lessThanOrEqualTo(grid.right + 0.5), reason: label);
        places.add((tile.top, tile.left));
        // One label per tile, read once.
        expect(
          find.bySemanticsLabel('$label: $value'),
          findsOneWidget,
          reason: label,
        );
      }
      for (var i = 1; i < places.length; i++) {
        final (t0, l0) = places[i - 1];
        final (t1, l1) = places[i];
        expect(t1 > t0 || (t1 == t0 && l1 > l0), isTrue, reason: 'tile $i');
      }
      // Two columns at phone width: four tiles make a 2 × 2 grid, Total last.
      expect(places.where((p) => p.$1 == places.first.$1).length, 2);
      expect(
        tester.getRect(find.byKey(balanceTileKey(BalanceKind.total))).width,
        closeTo((grid.width - BalanceTiles.gap) / 2, 0.5),
      );
      // Only what is pending.
      h.session.summaryValue = _balances(spendable: 1, confirming: 2);
      await _reload(tester);
      expect(_inTile(BalanceKind.confirming, '2'), findsOneWidget);
      expect(find.byKey(balanceTileKey(BalanceKind.locked)), findsNothing);
      // Everything confirmed, then a wallet without payments.
      final tokens = protocolLight;
      h.session.summaryValue = _balances(spendable: 12.5);
      await _reload(tester);
      expect(_inTile(BalanceKind.calm, 'All confirmed'), findsOneWidget);
      expect(
        tester
            .widget<Text>(_inTile(BalanceKind.calm, 'All confirmed'))
            .style!
            .color,
        tokens.faint,
      );
      h.session
        ..summaryValue = _balances()
        ..transactionsValue = [];
      await _reload(tester);
      expect(_inTile(BalanceKind.calm, 'Nothing here yet'), findsOneWidget);
      // Hidden amounts hide these too.
      h.session.summaryValue = _balances(spendable: 1, confirming: 2);
      await _reload(tester);
      await _tap(tester, find.byTooltip('Hide balances'));
      expect(_inTile(BalanceKind.confirming, hiddenAmount), findsOneWidget);
      expect(_inTile(BalanceKind.confirming, '2'), findsNothing);
      handle.dispose();
    });

    for (final width in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Wallet keeps one height at $width dp, text x$scale', (
          tester,
        ) async {
          final h = _Harness(price: 0.5, still: true);
          await h.pump(
            tester,
            const HomeScreen(),
            scale,
            Size(width * 3, 2340),
          );
          double height() =>
              tester.getSize(find.byKey(walletBalanceKey)).height;
          final states = <String, double>{};
          Future<void> state(String name, WalletSummary s) async {
            h.session.summaryValue = s;
            await _reload(tester);
            expect(tester.takeException(), isNull, reason: name);
            states[name] = height();
          }

          await state('settled', _balances(spendable: 12.5));
          await state(
            'pending, one kind',
            _balances(spendable: 12.5, locked: 2),
          );
          await state(
            'pending, four kinds',
            _balances(
              spendable: 3.25,
              confirming: 2,
              waiting: 0.5,
              locked: 5,
              immature: 16,
            ),
          );
          // A payment lands: 2 EPIC confirmed, while the sweep runs.
          h.session.summaryValue = _balances(
            spendable: 5.25,
            waiting: 0.5,
            locked: 5,
            immature: 16,
          );
          await tester.pump(autoRefreshInterval);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(_sweep(tester), greaterThan(0), reason: 'landing');
          states['landing'] = height();
          await tester.pumpAndSettle();
          await state('long figure', _balances(spendable: 20999999.99999999));
          await _tap(tester, find.byTooltip('Hide balances'));
          states['hidden'] = height();
          await _tap(tester, find.byTooltip('Show balances'));
          h.session.transactionsValue = [];
          await state('empty', _balances());
          expect(find.text('Nothing here yet'), findsWidgets);
          expect(
            states.values.toSet(),
            hasLength(1),
            reason: states.toString(),
          );
        });
      }
    }

    testWidgets('a long figure shrinks to fit, never below 34, on one line', (
      tester,
    ) async {
      final h = _Harness(price: 0.5, still: true);
      await h.pump(tester, const HomeScreen(), 1, const Size(960, 2340));
      for (final amount in [12.5, 1234.5678, 20999999.99999999]) {
        h.session.summaryValue = _balances(spendable: amount);
        await _reload(tester);
        final text = tester.widget<Text>(find.byKey(balanceFigureKey));
        final area = tester.getRect(find.byKey(walletBalanceKey));
        expect(
          text.style!.fontSize,
          inInclusiveRange(figureMinSize, figureSize),
        );
        expect(text.maxLines, 1);
        expect(
          tester.getRect(find.byKey(balanceUnitKey)).right,
          lessThanOrEqualTo(area.right),
          reason: '$amount',
        );
        expect(tester.takeException(), isNull);
      }
      // The test font draws every glyph a full em wide: 10 glyphs and the unit at 320 dp.
      expect(
        tester.widget<Text>(find.byKey(balanceFigureKey)).style!.fontSize,
        lessThan(figureSize),
      );
    });

    for (final (what, spendable) in [
      ('a short figure', 12.5),
      ('the 21 million figure', 20999999.99999999),
    ]) {
      for (final width in [320.0, 412.0]) {
        testWidgets(
          'statuses in the card on Wallet only, with $what at $width dp',
          (tester) async {
            final h = _Harness(
              still: true,
              price: 0.5,
              size: Size(width * 3, 2340),
              session: FakeWalletSession(
                summary: _balances(spendable: spendable, locked: 2),
                transactions: _transactions(),
              ),
            );
            await h.pump(tester);
            final appBar = find.byType(AppBar);
            // Wallet: the card's rows, under the tiles; the figure's row has the fiat value and
            // the eye to itself.
            expect(find.byKey(walletStatusesKey), findsNothing);
            final node = tester.getRect(find.byKey(nodeStatusKey));
            final epicbox = tester.getRect(find.byKey(epicboxStatusKey));
            final fiat = tester.getRect(find.byKey(fiatValueKey));
            final eye = tester.getRect(find.byTooltip('Hide balances'));
            expect(eye.left, greaterThanOrEqualTo(fiat.right - 0.5));
            expect(fiat.center.dy, closeTo(eye.center.dy, 1));
            expect(node.height, greaterThanOrEqualTo(48));
            expect(epicbox.top, greaterThanOrEqualTo(node.bottom - 0.5));
            expect(
              node.top,
              greaterThanOrEqualTo(
                tester.getRect(find.byKey(balanceTilesKey)).bottom,
              ),
            );
            expect(find.text('Node online'), findsNothing);
            for (final tab in ['Wallet', 'Send', 'Receive']) {
              await _tab(tester, tab);
              // Never in the app bar, never in a row under it.
              expect(
                find.descendant(
                  of: appBar,
                  matching: find.byKey(nodeStatusKey),
                ),
                findsNothing,
                reason: tab,
              );
              expect(
                find.byKey(nodeStatusKey).hitTestable(),
                tab == 'Wallet' ? findsOneWidget : findsNothing,
                reason: tab,
              );
              expect(
                find.byKey(epicboxStatusKey).hitTestable(),
                tab == 'Wallet' ? findsOneWidget : findsNothing,
                reason: tab,
              );
              expect(tester.takeException(), isNull, reason: tab);
            }
            // Send and Receive bodies start right under the app bar.
            for (final (tab, body) in [
              ('Send', find.byType(SendView)),
              ('Receive', find.byType(ReceiveView)),
            ]) {
              await _tab(tester, tab);
              expect(
                tester.getRect(body).top,
                tester.getRect(appBar).bottom + progressSlotHeight,
                reason: tab,
              );
              // The figure title has the bar to itself, and shrinks rather than overflows.
              expect(
                tester.getRect(find.byKey(titleFigureKey)).right,
                lessThanOrEqualTo(_actionsLeft(tester) + 0.5),
              );
            }
          },
        );
      }
    }

    for (final width in [320.0, 360.0, 412.0]) {
      testWidgets('Wallet\'s balance is centred at $width dp', (tester) async {
        final h = _Harness(
          price: 0.5,
          still: true,
          size: Size(width * 3, 2340),
        );
        await h.pump(tester);
        final centre = width / 2;
        for (final (name, summary) in [
          ('settled', _balances(spendable: 12.5)),
          ('one pending', _balances(spendable: 12.5, locked: 2)),
          ('long', _balances(spendable: 20999999.99999999, confirming: 2)),
        ]) {
          h.session.summaryValue = summary;
          await _reload(tester);
          // The figure and its EPIC as one unit.
          final figure = tester
              .getRect(find.byKey(balanceFigureKey))
              .expandToInclude(tester.getRect(find.byKey(balanceUnitKey)));
          expect(figure.center.dx, closeTo(centre, 1), reason: name);
          // The row: the fiat value and the eye, with the button's 48 dp target.
          final row = tester
              .getRect(find.byKey(fiatValueKey))
              .expandToInclude(
                tester.getRect(
                  find.descendant(
                    of: find.byKey(walletBalanceKey),
                    matching: find.byType(IconButton),
                  ),
                ),
              );
          expect(row.center.dx, closeTo(centre, 1), reason: name);
          expect(tester.takeException(), isNull, reason: name);
        }
      });
    }

    testWidgets(
      'a tile with a long value shrinks nothing and scrolls nowhere',
      (tester) async {
        final h = _Harness(size: const Size(2400, 2340));
        await h.pump(tester);
        h.session.summaryValue = _balances(
          spendable: 3.25,
          confirming: 2.12345678,
          waiting: 0.5,
          locked: 5.12345678,
          immature: 16,
        );
        await _reload(tester);
        final row = tester.getRect(find.byKey(balanceTilesKey));
        for (final (kind, text) in [
          (BalanceKind.locked, '5.12345678'),
          (BalanceKind.confirming, '2.12345678'),
        ]) {
          final tile = tester.getRect(find.byKey(balanceTileKey(kind)));
          final words = tester.getRect(_inTile(kind, text));
          expect(words.left, greaterThanOrEqualTo(tile.left), reason: text);
          expect(words.right, lessThanOrEqualTo(tile.right), reason: text);
          expect(tile.left, greaterThanOrEqualTo(row.left), reason: text);
        }
        final at = tester.getRect(_inTile(BalanceKind.locked, '5.12345678'));
        await tester.pump(const Duration(seconds: 3));
        expect(tester.getRect(_inTile(BalanceKind.locked, '5.12345678')), at);
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(tester.takeException(), isNull);
      },
    );

    for (final still in [false, true]) {
      testWidgets(
        'a landed payment sweeps the bar once${still ? ', reduced motion' : ''}',
        (tester) async {
          final h = _Harness(
            still: still,
            session: FakeWalletSession(
              summary: _balances(spendable: 10, confirming: 2),
              transactions: _transactions(),
            ),
          );
          await h.pump(tester);
          expect(_sweep(tester), 0, reason: 'not on the first balance');
          // Other changes: a new payment on its way, a cancelled send's funds back.
          for (final other in [
            _balances(spendable: 10, confirming: 2, waiting: 1),
            _balances(spendable: 10, confirming: 2, waiting: 1, locked: 3),
            _balances(spendable: 13, confirming: 2, waiting: 1),
          ]) {
            h.session.summaryValue = other;
            await tester.pump(autoRefreshInterval);
            for (var i = 0; i < 8; i++) {
              await tester.pump(const Duration(milliseconds: 100));
              expect(_sweep(tester), 0, reason: '$other');
            }
            await _frames(tester, 15);
          }
          // The confirming 2 EPIC lands.
          h.session.summaryValue = _balances(spendable: 15, waiting: 1);
          await tester.pump(autoRefreshInterval);
          await tester.pump();
          final seen = <double>[];
          for (var i = 0; i < 14; i++) {
            await tester.pump(const Duration(milliseconds: 100));
            seen.add(_sweep(tester));
          }
          expect(seen.first, greaterThan(0));
          expect(seen.reduce(math.max), greaterThan(0.7));
          // Once: about 1.2 s, then gone, on the app bar's foot.
          expect(seen.last, 0);
          expect(seen.where((v) => v > 0).length, inInclusiveRange(10, 12));
          final sweep = tester.getRect(find.byKey(landingSweepKey));
          expect(
            sweep.top,
            closeTo(tester.getRect(find.byType(AppBar)).bottom, 0.5),
          );
          expect(sweep.height, SweepLinePainter.thickness);
          await _frames(tester, 15);
          expect(_sweep(tester), 0);
          // On every tab: the bar is shared.
          await _tab(tester, 'Send', settle: false);
          h.session.summaryValue = _balances(spendable: 16);
          await tester.pump(autoRefreshInterval);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(_sweep(tester), greaterThan(0));
          await _frames(tester, 15);
        },
      );
    }

    test('a landing is spendable up because incoming money arrived', () {
      expect(paymentLanded(null, _balances(spendable: 1)), isFalse);
      expect(
        paymentLanded(
          _balances(spendable: 1, confirming: 2),
          _balances(spendable: 3),
        ),
        isTrue,
      );
      expect(
        paymentLanded(
          _balances(spendable: 1, immature: 16),
          _balances(spendable: 17),
        ),
        isTrue,
      );
      // A cancelled send's funds coming back are not a landing.
      expect(
        paymentLanded(
          _balances(spendable: 1, locked: 2),
          _balances(spendable: 3),
        ),
        isFalse,
      );
      // Nor a new payment on its way.
      expect(
        paymentLanded(
          _balances(spendable: 1),
          _balances(spendable: 1, confirming: 2),
        ),
        isFalse,
      );
    });

    testWidgets(
      'while syncing: a line on the bar on every tab, and the glow breathes',
      (tester) async {
        final session = _SlowRefreshSession(refreshed: _summary());
        final h = _Harness(session: session, settle: false);
        await h.pump(tester);
        for (final tab in ['Wallet', 'Send', 'Receive']) {
          await _tab(tester, tab, settle: false);
          expect(_syncLine(tester), 0.4, reason: tab);
          final line = tester.getRect(find.byKey(headerSyncLineKey));
          expect(
            line.top,
            closeTo(tester.getRect(find.byType(AppBar)).bottom, 0.5),
            reason: tab,
          );
          expect(line.height, progressSlotHeight);
        }
        // The light swells and fades; the syncing node pulses, on Wallet, its only place.
        await _tab(tester, 'Wallet', settle: false);
        final glows = <double>{};
        final nodes = <double>{};
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 200));
          glows.add(_glow(tester));
          nodes.add(tester.widget<FadeTransition>(_nodePulse).opacity.value);
        }
        expect(glows.length, greaterThan(3));
        expect(nodes.length, greaterThan(3));
        session.gate.complete();
        // Pump instead of settling, as the tab titles' dot pulses.
        await _frames(tester);
        expect(_syncLine(tester), isNull);
        final glow = _glow(tester);
        await tester.pump(const Duration(milliseconds: 500));
        expect(_glow(tester), glow);
      },
    );

    testWidgets('with reduced motion the glow does not breathe', (
      tester,
    ) async {
      final session = _SlowRefreshSession(refreshed: _summary());
      final h = _Harness(session: session, still: true);
      await h.pump(tester);
      expect(_syncLine(tester), 0.4);
      final glow = _glow(tester);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        expect(_glow(tester), glow);
      }
      session.gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a tap moves the pages in about 250 ms', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Send'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final page = tester.widget<PageView>(find.byType(PageView)).controller!;
      expect(page.page, allOf(greaterThan(0), lessThan(1)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(page.page, 0);
    });

    testWidgets('a tap from Send to Receive never marks Wallet on the way', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _tab(tester, 'Send', settle: false);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Receive'),
        ),
      );
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        expect(_selectedTab(tester), ShellTab.receive);
      }
      // The pending dot pulses on Receive's title, so pump instead of settling.
      await _frames(tester);
      expect(_selectedTab(tester), ShellTab.receive);
      // A swipe afterwards still changes the tab.
      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await _frames(tester);
      expect(_selectedTab(tester), ShellTab.wallet);
    });

    testWidgets('a failed listener stream shows epicbox offline', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      h.session.listenerEvents.addError(StateError('relay closed'));
      await tester.pumpAndSettle();
      expect(_statusWord(tester, epicboxStatusKey), 'Epicbox offline');
    });

    testWidgets('with reduced motion a tap cuts to the tab', (tester) async {
      final h = _Harness();
      await h.pump(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Receive'),
        ),
      );
      await tester.pump();
      await tester.pump();
      final page = tester.widget<PageView>(find.byType(PageView)).controller!;
      expect(page.page, 2);
    });

    testWidgets(
      'no network in the bar; the node tooltip names a test network',
      (tester) async {
        final main = _Harness();
        await main.pump(tester);
        for (final tab in ['Wallet', 'Send', 'Receive']) {
          await _tab(tester, tab, settle: false);
          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.textContaining(RegExp('Mainnet|Floonet|Usernet')),
            ),
            findsNothing,
            reason: tab,
          );
        }
        await _tab(tester, 'Wallet', settle: false);
        expect(find.text('Epic Cash'), findsOneWidget);
        expect(_statusTip(tester, nodeStatusKey), isNot(contains('Mainnet')));
        expect(
          _statusTip(tester, nodeStatusKey).split('\n').first,
          'Up to date.',
        );

        await tester.pumpWidget(const SizedBox());
        final floo = _Harness(chain: Chain.floonet);
        await floo.pump(tester);
        for (final tab in ['Wallet', 'Send', 'Receive']) {
          await _tab(tester, tab, settle: false);
          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.textContaining('Floonet'),
            ),
            findsNothing,
            reason: tab,
          );
          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.byIcon(Icons.help_outline),
            ),
            findsNothing,
            reason: tab,
          );
        }
        await _tab(tester, 'Wallet', settle: false);
        expect(find.text('Epic Cash'), findsOneWidget);
        // The title is not cut.
        expect(
          tester
              .renderObject<RenderParagraph>(
                find.descendant(
                  of: find.text('Epic Cash'),
                  matching: find.byType(RichText),
                ),
              )
              .didExceedMaxLines,
          isFalse,
        );
        final tip = _statusTip(tester, nodeStatusKey).split('\n');
        expect(tip.first, 'Floonet, test coins');
        expect(tip[1], 'Up to date.');
        // A screen reader hears it too.
        expect(
          tester
              .widget<Semantics>(
                find
                    .descendant(
                      of: find.byKey(nodeStatusKey),
                      matching: find.byWidgetPredicate(
                        (w) => w is Semantics && w.properties.hint != null,
                      ),
                    )
                    .first,
              )
              .properties
              .hint,
          startsWith('Floonet, test coins\n'),
        );
      },
    );

    test('the ? explains each balance, zero ones left out', () {
      // The ? is no longer on Wallet (its tiles name the pending balances); the help text
      // stays for where BalanceHelp is used.
      final tip = BalanceHelp.message(
        englishStrings,
        _balances(spendable: 12.5, locked: 2),
        false,
      ).toPlainText();
      expect(
        tip,
        'Total: 14.5 EPIC\nEverything in this wallet, spendable or not.\n\n'
        'Spendable: 12.5 EPIC\n\n'
        'Locked by a payment in progress: 2 EPIC\n'
        'Held for a payment you started; the change comes back when it '
        'completes.',
      );
    });

    testWidgets('a tab keeps its form while another is shown', (tester) async {
      final h = _Harness(still: true);
      await h.pump(tester);
      await _tab(tester, 'Send');
      await tester.enterText(
        find.widgetWithText(TextField, 'To'),
        payee,
      );
      await _tab(tester, 'Receive');
      await _tab(tester, 'Wallet');
      await _tab(tester, 'Send');
      expect(_toField(tester), payee);
    });

    testWidgets('Receive keeps its tab across a tab change', (tester) async {
      final h = _Harness(still: true);
      await h.pump(tester);
      await _tab(tester, 'Receive');
      // Epicbox address by default.
      expect(find.byKey(receiveAddressKey).hitTestable(), findsOneWidget);
      expect(find.text('Receive by payment file'), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byKey(receiveTabsKey),
          matching: find.text('File'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Receive by payment file'), findsOneWidget);
      expect(find.byKey(receiveAddressKey), findsNothing);
      for (final tab in ['Wallet', 'Send', 'Receive']) {
        await _tab(tester, tab);
      }
      expect(find.text('Receive by payment file'), findsOneWidget);
      expect(find.byKey(receiveAddressKey), findsNothing);
      // And back.
      await tester.tap(
        find.descendant(
          of: find.byKey(receiveTabsKey),
          matching: find.text('Epicbox'),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 'Wallet');
      await _tab(tester, 'Receive');
      expect(find.byKey(receiveAddressKey).hitTestable(), findsOneWidget);
    });

    testWidgets('Done after a payment goes to Wallet with a fresh form', (
      tester,
    ) async {
      final h = _Harness(still: true);
      await h.pump(tester, const HomeScreen(), 1, const Size(1080, 2340));
      await _sendOne(tester, payee);
      expect(find.text('Waiting for their wallet'), findsOneWidget);
      await _tap(tester, find.text('Done'));
      expect(_selectedTab(tester), ShellTab.wallet);
      await _tab(tester, 'Send');
      expect(_toField(tester), isEmpty);
    });

    testWidgets(
      'a recipient handed over while the tracker shows waits for the next form',
      (tester) async {
        final h = _Harness(still: true);
        await h.pump(tester, const HomeScreen(), 1, const Size(1080, 2340));
        await _sendOne(tester, payee);
        expect(find.text('Waiting for their wallet'), findsOneWidget);
        final carol = '${'c' * 52}@epicbox.epiccash.com';
        ProviderScope.containerOf(tester.element(find.byType(SendView)))
            .read(sendRecipientProvider.notifier)
            .hand(carol);
        await tester.pumpAndSettle();
        // The tracker stays.
        expect(find.text('Waiting for their wallet'), findsOneWidget);
        await _tap(tester, find.text('Done'));
        await _tab(tester, 'Send');
        expect(_toField(tester), carol);

        // The same from the payment file screens.
        await _tap(tester, find.text('File').last);
        await tester.enterText(
          find.widgetWithText(TextField, 'Amount (EPIC)'),
          '1',
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        await _tap(tester, find.text('Make payment file'));
        await tester.enterText(find.byType(TextField).last, _Harness._pin);
        await tester.pumpAndSettle();
        ProviderScope.containerOf(tester.element(find.byType(SendView)))
            .read(sendRecipientProvider.notifier)
            .hand(payee);
        await tester.pumpAndSettle();
        expect(find.text('Waiting for their reply'), findsOneWidget);
        await _tap(tester, find.widgetWithText(TextButton, 'Done'));
        await _tab(tester, 'Send');
        expect(_toField(tester), payee);
      },
    );

    testWidgets(
      'the tracker moves on when their wallet answers, without a notice',
      (tester) async {
        final h = _Harness(still: true);
        await h.pump(tester, const HomeScreen(), 1, const Size(1080, 2340));
        await _sendOne(tester, payee);
        expect(find.text('Waiting for their wallet'), findsOneWidget);

        // Their reply comes: the listener finishes and posts it.
        h.session.transactionsValue.add(
          fakeTx(
            slateId: 'send-1',
            kind: TxKind.sent,
            status: TxStatus.awaitingConfirmation,
            amountDebited: _epic(1) + h.session.fee,
            fee: h.session.fee,
            counterparty: payee,
          ),
        );
        h.session.listenerEvents.add(
          const ListenerEvent(
            kind: ListenerEventKind.finalized,
            slateId: 'send-1',
            message: 'Sent 1 EPIC, posted to the node',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Waiting for their wallet'), findsNothing);
        expect(find.text('Their wallet signed'), findsOneWidget);
        expect(find.text('Sent to the network'), findsOneWidget);
        expect(find.textContaining('Confirming 0/'), findsOneWidget);
        // The tracker says it; a notice would say it twice.
        expect(find.textContaining('finished. Waiting for'), findsNothing);
      },
    );

    testWidgets('pull to refresh on the Wallet tab reloads from the node', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const HomeScreen(), 1, const Size(1080, 2340));
      final before = h.session.refreshCalls;
      await tester.fling(_walletList(), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(h.session.refreshCalls, before + 1);
    });

    for (final tab in ['Send', 'Wallet', 'Receive']) {
      testWidgets('$tab tab: labelled tap targets of at least 48 dp', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final h = _Harness(scanSupported: true, still: true);
        await h.pump(tester, const HomeScreen(), 1, const Size(1080, 2340));
        await _tab(tester, tab);
        // Receive's short address is selectable text, 24 dp tall, inside the address card
        // that D-02 rebuilds; every button there passes.
        if (tab != 'Receive') {
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        }
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('$tab tab at text scale 2 has no overflow', (tester) async {
        final h = _Harness(price: 0.5, scanSupported: true, still: true);
        await h.pump(tester, const HomeScreen(), 2);
        await _tab(tester, tab);
        expect(tester.takeException(), isNull);
        await tester.fling(
          find
              .descendant(
                of: find.byType(PageView),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                ),
              )
              .first,
          const Offset(0, -3000),
          3000,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
  group('amounts', () {
    // The brief's matrix (D-09): each amount on Wallet's figure and Send's and Receive's
    // title, at three phone widths, at text scale 1 and 2, with the fiat value, without it,
    // and hidden.
    final matrix = [
      '0',
      '0.00000001',
      '0.5',
      '1',
      '12.5',
      '999.99999999',
      '1000',
      '123456.789',
      '1234567.12345678',
      // Epic's supply approaches 21 million; a wallet must still show more.
      '20999999.99999999',
      '99999999.99999999',
    ].map(parseEpic).toList();

    WalletSummary summaryOf(BigInt spendable) => WalletSummary(
      lastConfirmedHeight: _tip,
      minimumConfirmations: BigInt.from(3),
      total: spendable + _epic(2),
      spendable: spendable,
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: _epic(2),
      validatedWithNode: true,
    );

    for (final width in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 2.0]) {
        for (final mode in ['fiat', 'no fiat', 'hidden']) {
          testWidgets('the matrix at $width dp, text x$scale, $mode', (
            tester,
          ) async {
            final h = _Harness(
              price: mode == 'no fiat' ? null : 0.5,
              still: true,
              session: FakeWalletSession(
                summary: summaryOf(matrix.first),
                transactions: _transactions(),
              ),
            );
            if (mode == 'hidden') h.store.values['app.hide_balances'] = 'true';
            await h.pump(
              tester,
              const HomeScreen(),
              scale,
              Size(width * 3, 2340),
            );
            final height = tester.getSize(find.byKey(walletBalanceKey)).height;
            for (final amount in matrix) {
              h.session.summaryValue = summaryOf(amount);
              await _reload(tester);
              final shown = mode == 'hidden'
                  ? hiddenAmount
                  : displayEpic(amount);
              for (final tab in ['Wallet', 'Send', 'Receive']) {
                await _tab(tester, tab);
                final why = '${formatEpic(amount)} on $tab';
                expect(tester.takeException(), isNull, reason: why);
                if (tab == 'Wallet') {
                  // One line by the display rule, inside the area with its unit.
                  final figure = tester.widget<Text>(
                    find.byKey(balanceFigureKey),
                  );
                  expect(figure.data, shown, reason: why);
                  expect(figure.maxLines, 1, reason: why);
                  final area = tester.getRect(find.byKey(walletBalanceKey));
                  expect(
                    tester.getRect(find.byKey(balanceUnitKey)).right,
                    lessThanOrEqualTo(area.right + 0.5),
                    reason: why,
                  );
                  expect(
                    tester.getSize(find.byKey(walletBalanceKey)).height,
                    height,
                    reason: why,
                  );
                  if (mode == 'fiat') {
                    expect(find.byKey(fiatValueKey), findsOneWidget);
                  } else {
                    expect(find.byKey(fiatValueKey), findsNothing);
                  }
                } else {
                  // The title: the figure and its unit, clear of the actions.
                  expect(_titleText(tester), '$shown EPIC', reason: why);
                  final title = tester.getRect(find.byKey(titleFigureKey));
                  expect(
                    title.right,
                    lessThanOrEqualTo(_actionsLeft(tester) + 0.5),
                    reason: why,
                  );
                }
              }
              await _tab(tester, 'Wallet');
            }
          });
        }
      }
    }
  });
}
