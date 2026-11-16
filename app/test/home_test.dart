// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:convert';

import 'package:epic_wallet/src/announcements/announcements_service.dart'
    show AnnouncementsNotifier, AnnouncementsState, announcementsProvider;
import 'package:epic_wallet/src/announcements/announcement_card.dart' show AnnouncementCard;
import 'package:epic_wallet/src/btlabs_public.dart' show Announcement;
import 'package:epic_wallet/src/settings_file/host_settings.dart' show AppConfig, hostSettings;
import 'package:epic_wallet/src/dev_networks.dart' show devNetworksProvider;
import 'package:epic_wallet/src/epic1.dart' show FakeEpic1;
import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/onion_notice.dart';
import 'package:epic_wallet/src/amount.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/recent_activity.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/ui/cancel_dialog.dart' show cancelForSureKey;
import 'package:epic_wallet/src/ui/kit/kit_button.dart' show KitButton, KitButtonKind;
import 'package:epic_wallet/src/ui/kit/kit_icons.dart' show KitIcons;
import 'package:epic_wallet/src/ui/kit/kit_sheet.dart' show KitSheet;
import 'package:epic_wallet/src/ui/kit/kit_steps.dart' show KitSteps;
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/history_screen.dart';
import 'package:epic_wallet/src/ui/phone_tx_row.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'support/fake_history_files.dart';
import 'package:epic_wallet/src/ui/shell_header.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/ui/theme/brand.dart';
import 'package:epic_wallet/src/ui/theme/lattice.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/ui/kit/kit_tab_bar.dart' show kitScanButtonKey;
import 'package:epic_wallet/src/ui/home_tab.dart' show homeFigureKey, homePillKey;
import 'package:epic_wallet/src/ui/home_status.dart' show connectionsSheetKey;
import 'package:epic_wallet/src/ui/kit/kit_row.dart' show KitRow;
import 'support/shell_where.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'support/pin_pad.dart';
import 'support/send_finders.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/test_settings.dart' show testConfigWithout;
import 'support/amounts.dart';

final _l = englishStrings;

/// Noon on 30 Sep 2026, local time, so day headings do not depend on the time zone.
final DateTime _now = DateTime(2026, 9, 30, 12);

int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

/// The fake node's tip height.
final BigInt _tip = BigInt.from(2500000);

const String _bob = 'esBobAddress1234567890@box.epic.invalid';

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
  total: (spendable ?? epic(12.5)) + epic(2),
  spendable: spendable ?? epic(12.5),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: epic(2),
  validatedWithNode: true,
);

/// A new wallet: nothing in it, nothing on its way.
WalletSummary _emptySummary() => WalletSummary(
  lastConfirmedHeight: _tip,
  minimumConfirmations: BigInt.from(3),
  total: BigInt.zero,
  spendable: BigInt.zero,
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
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
      amountCredited: epic(1),
    ),
];

/// A store state with the reminder first seen 40 days before [_now].
void _reminderDue(_Harness h) {
  h.store.values['app.history_reminder_first_seen.mainnet'] =
      '${_at(_now.subtract(const Duration(days: 40)))}';
}

/// Only the pending send to Bob, which no attempt has delivered.
List<TxEntry> _undeliveredSend() => [
  fakeTx(
    id: 4,
    slateId: 'send-bob',
    kind: TxKind.sent,
    status: TxStatus.awaitingRecipient,
    createdAtUnix: _at(DateTime(2026, 9, 30, 9)),
    amountCredited: epic(0.992),
    amountDebited: epic(3),
    fee: epic(0.008),
    counterparty: _bob,
    transport: 'epicbox',
    cancellable: true,
    undelivered: true,
  ),
];

/// A pending epicbox send to Bob, today; a confirmed receive yesterday; a cancelled send and a
/// restored output earlier.
List<TxEntry> _transactions() => [
  fakeTx(
    id: 4,
    slateId: 'send-bob',
    kind: TxKind.sent,
    status: TxStatus.awaitingRecipient,
    createdAtUnix: _at(DateTime(2026, 9, 30, 9)),
    amountCredited: epic(0.992),
    amountDebited: epic(3),
    fee: epic(0.008),
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
    amountCredited: epic(5),
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
    amountCredited: epic(0.9),
    amountDebited: epic(2),
    fee: epic(0.1),
  ),
  fakeTx(
    key: 'c:restored',
    kind: TxKind.received,
    status: TxStatus.confirmed,
    source: TxSource.restored,
    createdAtUnix: _at(DateTime(2026, 8, 1, 8)),
    blockHeight: BigInt.from(2400000),
    amountCredited: epic(7.25),
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
    this.advanced = AdvancedPrefs.none,
    FakeWalletSession? session,
    bool fromBeforeOnionKey = false,
    this.extraOverrides = const [],
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
    // Made on this version, as creation and restore mark it: no notice about the Tor address.
    if (!fromBeforeOnionKey) store.values[onionNoticeKey(chain.name, config.walletId)] = onionNoticeSeen;
    this.session.owner = service;
    // The reminder is already tracked from today, so home does not write the setting.
    store.values['app.history_reminder_first_seen.${chain.name}'] =
        '${_at(_now)}';
  }

  final Chain chain;

  /// More provider overrides for the tree.
  final List<Override> extraOverrides;

  /// The wallet's PIN, which a send asks for.
  static const _pin = '123456';

  /// Reduced motion, for the states whose pulses never settle: a sync that does not end.
  final bool still;

  /// The Advanced choices the tree runs under (none, as a new wallet).
  final AdvancedPrefs advanced;

  final FakeWalletSession session;
  final _FakePrice prices;
  final FakeQrScanner scanner;
  final files = FakeHistoryFiles()..canShare = false;
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
          if (chain != Chain.mainnet) devNetworksProvider.overrideWithValue(true),
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
          updatePlatformProvider.overrideWithValue(null),
          updateProvider.overrideWith(_FakeUpdates.new),
          priceSourceProvider.overrideWithValue(prices),
          qrScannerProvider.overrideWithValue(scanner),
          historyFilesProvider.overrideWithValue(files),
          clockProvider.overrideWithValue(() => _now),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          walletConfigProvider.overrideWith(() => _Config(config)),
          ...extraOverrides,
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
          builder: (context, child) => AdvancedOptions(
            prefs: advanced,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: still,
              ),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

/// The announcements service with a fixed list of live messages; records what the screen does.
class _FakeAnnouncements extends AnnouncementsNotifier {
  _FakeAnnouncements(this.messages);

  final List<Announcement> messages;
  final dismissed = <String>[];
  final seen = <String>[];

  @override
  AnnouncementsState build() => AnnouncementsState(live: messages);

  @override
  Future<void> markSeen(String id) async => seen.add(id);

  @override
  Future<void> dismiss(String id) async {
    dismissed.add(id);
    state = AnnouncementsState(live: [for (final m in state.live) if (m.id != id) m]);
  }
}

/// [n] confirmed payments, one a day.
List<TxEntry> _latticeTxs(int n) => [
  for (var i = 0; i < n; i++)
    fakeTx(id: i, status: TxStatus.confirmed, createdAtUnix: _at(DateTime(2026, 9, 1 + i)), amountCredited: epic(i + 1)),
];

/// The Wallet tab's list, the vertical scrollable under the header.
Finder _walletList() => find
    .descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable))
    .first;

/// The first list that scrolls down: the screen's own, never the shell's pages.
Finder _verticalList() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

/// The text of Wallet's figure, or null when it is not there.
String? _figure(WidgetTester tester) {
  final figure = find.byKey(homeFigureKey);
  return figure.evaluate().isEmpty ? null : tester.widget<Text>(figure).textSpan!.toPlainText();
}

/// The value of the sync line along the app bar's foot, or null when it is not there.
double? _syncLine(WidgetTester tester) {
  final line = find.byKey(headerSyncLineKey);
  return line.evaluate().isEmpty
      ? null
      : tester.widget<LinearProgressIndicator>(line).value;
}

/// What the old tab bar's words did, on the phone shell (see [shellGo]); with [settle] false it
/// pumps a second of frames instead, for screens with a pulse.
Future<void> _tab(
  WidgetTester tester,
  String label, {
  bool settle = true,
}) async {
  await shellGo(tester, label, settle: false);
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
  total: epic(spendable + confirming + waiting + locked + immature),
  spendable: epic(spendable),
  awaitingConfirmation: epic(confirming),
  awaitingFinalization: epic(waiting),
  immature: epic(immature),
  locked: epic(locked),
  validatedWithNode: true,
);

/// The backdrop light's opacity.
double _glow(WidgetTester tester) =>
    (tester.widget<CustomPaint>(find.byKey(backdropPaintKey)).painter!
            as ProtocolBackdropPainter)
        .glowNow
        .a;

/// What a screen reader says for the connections row of the service with [key]: the service
/// and its word. The sheet opens from the status pill and closes again.
Future<String> _statusWord(WidgetTester tester, Key key) async =>
    (await _statusSemantics(tester, key)).label;

/// The hint of the connections row with [key]: its one line under the service.
Future<String> _statusTip(WidgetTester tester, Key key) async =>
    (await _statusSemantics(tester, key)).hint;

Future<SemanticsData> _statusSemantics(WidgetTester tester, Key key) async {
  final service = switch (key) {
    nodeStatusKey => 'Node',
    epicboxStatusKey => 'Epicbox',
    _ => throw ArgumentError('no connections row for $key'),
  };
  await tester.tap(find.byKey(homePillKey));
  await tester.pumpAndSettle();
  final row = find.descendant(
    of: find.byKey(connectionsSheetKey),
    matching: find.byWidgetPredicate(
      (w) => w is KitRow && (w.semanticsLabel ?? '').startsWith(service),
    ),
  );
  final data = tester.getSemantics(row).getSemanticsData();
  Navigator.of(tester.element(find.byKey(connectionsSheetKey))).pop();
  await tester.pumpAndSettle();
  return data;
}

/// The tab the shell's tab bar marks.
ShellWhere _selectedTab(WidgetTester tester) => shellWhere(tester);

/// The text in Send's address field.
String _toField(WidgetTester tester) => tester
    .widget<TextField>(sendTo())
    .controller!
    .text;

/// On the shell's Send tab: [to], 1\u00a0EPIC, review, Send.
Future<void> _sendOne(WidgetTester tester, String to) async {
  await _tab(tester, _l.homeSendButton);
  await tester.enterText(sendTo(), to);
  await tester.pumpAndSettle();
  await _tap(tester, continueButton());
  await tester.enterText(sendAmount(), '1');
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  await _tap(tester, continueButton());
  await _tap(tester, find.text('Send 1.0\u00a0EPIC'));
  await enterPin(tester, _Harness._pin);
  await tester.pumpAndSettle();
}

/// The payment page's back link (the kit's page header has no Cupertino back button).
Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byIcon(KitIcons.backLink).first);
  await tester.pumpAndSettle();
}

/// Opens the payment page's More sheet (who, route, date, ids), where the detail rows live.
Future<void> _openMore(WidgetTester tester) async {
  await _tap(tester, find.byKey(txDetailsMoreKey));
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
      String label(TxEntry tx) => txStatusLabel(englishStrings, tx, _tip, target: 3);
      expect(
        label(fakeTx(kind: TxKind.sent, status: TxStatus.awaitingRecipient)),
        _l.txStatusWaitingRecipient,
      );
      expect(
        label(fakeTx(status: TxStatus.awaitingConfirmation)),
        _l.txStatusWaitingSender,
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
        _l.txStatusReceived,
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
        _l.txMiningReward,
      );
      expect(
        txTitle(
          englishStrings,
          fakeTx(source: TxSource.restored),
          contactName: 'Bob',
        ),
        _l.txRestoredFunds,
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
          'esBobA…567890@box.epic.invalid',
        );
        expect(
          txTitle(englishStrings, fakeTx(kind: TxKind.sent, status: status)),
          _l.txOutgoingPayment,
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
        '203.0.113.5:3415',
      );
    });

    test('details headings leave the address to the row below', () {
      final send = fakeTx(
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        counterparty: _bob,
      );
      expect(txHeading(englishStrings, send), _l.txOutgoingPayment);
      expect(txHeading(englishStrings, send, contactName: 'Bob'), 'Bob');
      expect(
        txHeading(
          englishStrings,
          fakeTx(source: TxSource.imported, counterparty: _bob),
        ),
        _l.txIncomingPayment,
      );
      expect(
        txHeading(englishStrings, fakeTx(kind: TxKind.coinbase)),
        _l.txMiningReward,
      );
    });

    test('EPIC amounts group thousands for display, not for fields', () {
      expect(epicText(englishStrings, epic(1234.5678)), '1,234.5678\u00a0EPIC');
      expect(epicText(englishStrings, epic(-1234567)), '\u22121,234,567.0\u00a0EPIC');
      expect(formatEpic(epic(1234.5)), '1234.5');
      expect(
        matchesQuery(fakeTx(amountCredited: epic(1234.5)), '1,234'),
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
        _l.txStatusFromBackup,
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

    test('explorer links: the block by its height, none before it is known or without an explorer', () {
      final tx = fakeTx(
        status: TxStatus.confirmed,
        kernelExcess: '09ff',
        blockHeight: BigInt.from(42),
      );
      expect(explorerUrl(Chain.mainnet, tx), hostSettings.explorerBlock(42));
      expect(explorerUrl(Chain.mainnet, tx), endsWith('/blockdetail/42'));
      expect(explorerUrl(Chain.mainnet, fakeTx(status: TxStatus.confirmed)), isNull);
      expect(explorerUrl(Chain.mainnet, fakeTx(status: TxStatus.confirmed, blockHeight: BigInt.from(1))), hostSettings.explorerBlock(1));
      hostSettings = hostSettings.withConfig(AppConfig.fromText(testConfigWithout(['[explorer]'])));
      expect(explorerUrl(Chain.mainnet, tx), isNull, reason: 'no explorer in app-config.toml: no link');
    });

    test('fiat text groups thousands and keeps satoshis for BTC', () {
      expect(fiatText(epic(3000), 0.41, 'usd'), '1,230.00\u00a0USD');
      expect(fiatText(epic(1), 0.00000512, 'btc'), '0.00000512\u00a0BTC');
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

      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Restored'), findsOneWidget);
      // The cancelled send stays in the list, greyed.
      expect(find.text('\u22121.0'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, _l.phoneActSearchHint), 'rent');
      await tester.pump(searchDebounce);
      await tester.pumpAndSettle();
      expect(find.textContaining('+5.0'), findsOneWidget);
      expect(find.text('\u22122.0'), findsNothing);

      await tester.enterText(find.widgetWithText(TextField, _l.phoneActSearchHint), 'zzz');
      await tester.pump(searchDebounce);
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches “zzz”.'), findsOneWidget);

      await _tap(tester, find.text(_l.historyClearSearch));
      await _tap(tester, find.text('Sent'));
      expect(find.text('\u22122.0'), findsOneWidget);
      expect(find.text('+5.0'), findsNothing);
      // A cancelled send is in All only.
      expect(find.text('\u22121.0'), findsNothing);
      // Pending and Cancelled are not filters of the screen any more.
      expect(find.text('Cancelled'), findsNothing);

      await _tap(tester, find.text('Received'));
      expect(find.textContaining('+5.0'), findsOneWidget);
      expect(find.text('+7.25'), findsOneWidget);
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
      expect(find.text('≈\u00a0\$6.25'), findsOneWidget);
      expect((await _statusWord(tester, nodeStatusKey)), 'Node, Synced');
      expect((await _statusWord(tester, epicboxStatusKey)), 'Epicbox, Connecting');
      // The height is only in the tooltip.
      expect(find.textContaining('2,500,000'), findsNothing);

      // Recent activity: the pending send to Bob first, amounts with fiat.
      final tiles = find.byType(PhoneTxRow);
      expect(tiles, findsNWidgets(4));
      expect(tester.widget<PhoneTxRow>(tiles.first).tx.slateId, 'send-bob');
      expect(find.textContaining('Waiting for recipient'), findsOneWidget);
      expect(find.text('\$2.50'), findsOneWidget);
      // The waiting send says so in its own row; the open row shows no time.
      expect(find.textContaining('Yesterday'), findsOneWidget);
      expect(find.text('A payment is waiting for the recipient'), findsNothing);
      await _tap(tester, find.textContaining('Waiting for recipient'));
      expect(find.byType(TxDetailsScreen), findsOneWidget);
      expect(find.textContaining('in about 2 hours'), findsOneWidget);
      await _back(tester);

      // Four payments are all on Home: no "View all" to the same rows.
      expect(find.textContaining('View all'), findsNothing);
    });

    testWidgets('only the five newest, pending first', (tester) async {
      final h = _Harness(
        transactions: [
          for (var i = 0; i < 7; i++)
            fakeTx(
              id: i,
              status: TxStatus.confirmed,
              createdAtUnix: _at(DateTime(2026, 9, 1 + i)),
              amountCredited: epic(i + 1),
            ),
        ],
      );
      await h.pump(tester);
      expect(find.byType(PhoneTxRow), findsNWidgets(recentActivityCount));
      expect(find.text('+7.0'), findsOneWidget);
      expect(find.text('+2.0'), findsNothing);
      await _tap(tester, find.text(_l.phoneHomeSeeAll));
      expect(_selectedTab(tester), ShellWhere.activity);
    });

    // "See all" sits on the Recent head whatever the list holds, and opens the Activity tab.
    testWidgets('See all opens Activity, under one payment and five', (tester) async {
      for (final n in [1, recentActivityCount]) {
        await tester.pumpWidget(const SizedBox());
        await _Harness(transactions: _latticeTxs(n)).pump(tester);
        expect(find.byType(PhoneTxRow), findsNWidgets(n));
        await _tap(tester, find.text(_l.phoneHomeSeeAll));
        expect(_selectedTab(tester), ShellWhere.activity, reason: '$n');
      }
    });

    testWidgets('Home has no BT Labs lattice, whatever the list holds', (tester) async {
      await _Harness(transactions: _latticeTxs(1)).pump(tester);
      expect(find.byType(BrandLattice), findsNothing);
    });

    testWidgets('the eye hides every amount and remembers it', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester);

      await _tap(tester, find.byTooltip(_l.homeHideBalances));
      expect(_figure(tester), hiddenAmount);
      expect(find.text('≈\u00a0\$6.25'), findsNothing);
      expect(find.text('+5.0\u00a0EPIC'), findsNothing);
      expect(find.text(hiddenAmount), findsWidgets);
      expect(h.store.values['app.hide_balances'], 'true');

      await _tap(tester, find.byTooltip(_l.homeShowBalances));
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
      expect(find.text('≈\u00a0\$6.25'), findsOneWidget);
      h.prices.value = 1;
      await tester.pump(priceRefreshInterval);
      await tester.pumpAndSettle();
      expect(find.text('≈\u00a0\$12.50'), findsOneWidget);
      // A failed fetch keeps the last price.
      h.prices.value = null;
      await tester.pump(priceRefreshInterval);
      await tester.pumpAndSettle();
      expect(find.text('≈\u00a0\$12.50'), findsOneWidget);
      expect(h.prices.calls, 3);
    });

    testWidgets('refreshes by itself every minute, also under another screen', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      h.session.summaryValue = _summary(spendable: epic(20));

      // android-06: a screen over home (Outputs, a transaction) still gets fresh figures.
      await _tap(tester, find.byKey(const ValueKey('tx-s:from-alice')));
      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      await _back(tester);
      expect(_figure(tester), '20.0');

      h.session.summaryValue = _summary(spendable: epic(30));
      await tester.pump(autoRefreshInterval);
      await tester.pumpAndSettle();
      expect(_figure(tester), '30.0');
    });

    // Home leaves Confirming x/3 when a direct send or an Epicbox receive completes, without a
    // rescan (android-06).
    for (final (name, kind, slate) in [
      ('a direct send', TxKind.sent, 'to-desktop'),
      ('an epicbox receive', TxKind.received, 'from-epic-pay'),
    ]) {
      testWidgets('details of $name move from Confirming to completed by themselves', (
        tester,
      ) async {
        TxEntry payment({required TxStatus status}) => fakeTx(
          id: 9,
          slateId: slate,
          kind: kind,
          status: status,
          createdAtUnix: _at(DateTime(2026, 9, 30, 11)),
          blockHeight: _tip,
          amountCredited: kind == TxKind.sent ? epic(0.992) : epic(2),
          amountDebited: kind == TxKind.sent ? epic(3) : BigInt.zero,
          fee: kind == TxKind.sent ? epic(0.008) : null,
          transport: kind == TxKind.sent ? 'http' : 'epicbox',
        );
        final h = _Harness(
          transactions: [
            payment(status: TxStatus.awaitingConfirmation),
            ..._transactions(),
          ],
        );
        await h.pump(tester);
        await _tap(tester, find.byKey(ValueKey('tx-s:$slate')));
        // The page's steps carry the count; a finished payment folds them into one line.
        expect(find.text(_l.payConfirming(1, 3)), findsOneWidget);

        // The core confirms it and the chain grows two blocks, all while the details are open.
        h.session
          ..transactionsValue = [
            payment(status: TxStatus.confirmed),
            ..._transactions(),
          ]
          ..summaryValue = WalletSummary(
            lastConfirmedHeight: _tip + BigInt.two,
            minimumConfirmations: BigInt.from(3),
            total: epic(14.5),
            spendable: epic(12.5),
            awaitingConfirmation: BigInt.zero,
            awaitingFinalization: BigInt.zero,
            immature: BigInt.zero,
            locked: epic(2),
            validatedWithNode: true,
          );
        await tester.pump(autoRefreshInterval);
        await tester.pumpAndSettle();
        expect(find.text(_l.payConfirming(1, 3)), findsNothing);
        expect(find.text('Completed'), findsOneWidget);
        await tester.pump(boostMaxWindow); // the payment's boost ends, so no timer outlives the test
      });
    }

    // Bob's phone sent over HTTP and went from Confirming to completed with no 1/3 or
    // 2/3 between: home refreshed once a minute and Epic's blocks come in bursts. A new block
    // now refreshes within [tipCheckInterval], each confirmation on screen.
    testWidgets('a send counts each new block within seconds, not at the minute', (
      tester,
    ) async {
      TxEntry sent() => fakeTx(
        id: 9,
        slateId: 'to-desktop',
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        createdAtUnix: _at(DateTime(2026, 9, 30, 11)),
        blockHeight: _tip,
        amountCredited: epic(0.992),
        amountDebited: epic(3),
        fee: epic(0.008),
        transport: 'http',
      );
      WalletSummary at(BigInt height) => WalletSummary(
        lastConfirmedHeight: height,
        minimumConfirmations: BigInt.from(3),
        total: epic(14.5),
        spendable: epic(12.5),
        awaitingConfirmation: epic(0.992),
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      );
      final h = _Harness(transactions: [sent(), ..._transactions()]);
      await h.pump(tester);
      Finder row(String text) => find.descendant(
        of: find.byType(PhoneTxRow),
        matching: find.textContaining(text),
      );
      expect(row('Confirming 1 of 3'), findsOneWidget);

      for (final (blocks, word) in [(1, 'Confirming 2 of 3'), (2, null)]) {
        final height = _tip + BigInt.from(blocks);
        h.service.nodeTipValue = NodeTip(height: height, nodeVersion: '3.6.0');
        h.session.summaryValue = at(height);
        await tester.pump(tipCheckInterval);
        await tester.pumpAndSettle();
        // A finished payment drops the status word and shows its time.
        if (word != null) {
          expect(row(word), findsOneWidget, reason: 'at ${blocks + 1} confirmations');
        } else {
          expect(row('Confirming'), findsNothing, reason: 'at ${blocks + 1} confirmations');
        }
      }

      // No new block: the tip checks refresh nothing.
      final refreshes = h.session.refreshCalls;
      await tester.pump(tipCheckInterval);
      await tester.pumpAndSettle();
      expect(h.session.refreshCalls, refreshes);
      await tester.pump(boostMaxWindow); // the payment's boost ends, so no timer outlives the test
    });

    // The owner, 2026-11-14: the count is the wallet's own setting, 6 unless changed, never a
    // fixed 10. A wallet with nothing stored counts to 6; a count stored later takes over.
    testWidgets('the row counts to the wallet\'s confirmations: 6 by default, then the stored count', (
      tester,
    ) async {
      TxEntry sent() => fakeTx(
        id: 9,
        slateId: 'to-desktop',
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        createdAtUnix: _at(DateTime(2026, 9, 30, 11)),
        blockHeight: _tip,
        amountCredited: epic(0.992),
        amountDebited: epic(3),
        fee: epic(0.008),
        transport: 'http',
      );
      WalletSummary at(BigInt height, int stored) => WalletSummary(
        lastConfirmedHeight: height,
        minimumConfirmations: BigInt.from(stored),
        total: epic(14.5),
        spendable: epic(12.5),
        awaitingConfirmation: epic(0.992),
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      );
      final session = FakeWalletSession(
        summary: at(_tip, defaultMinimumConfirmations),
        transactions: [sent(), ..._transactions()],
      );
      final h = _Harness(session: session);
      await h.pump(tester);
      Finder row(String text) => find.descendant(
        of: find.byType(PhoneTxRow),
        matching: find.textContaining(text),
      );
      expect(row(_l.payConfirming(1, 6)), findsOneWidget);
      expect(row('of 10'), findsNothing);

      // Four more blocks: 5 of 6, still confirming.
      final later = _tip + BigInt.from(4);
      h.service.nodeTipValue = NodeTip(height: later, nodeVersion: '3.6.0');
      session.summaryValue = at(later, defaultMinimumConfirmations);
      await tester.pump(tipCheckInterval);
      await tester.pumpAndSettle();
      expect(row(_l.payConfirming(5, 6)), findsOneWidget);

      // The user stores 4 in Settings › Advanced › Confirmations: the next balance carries it
      // and the payment is done.
      final next = later + BigInt.one;
      h.service.nodeTipValue = NodeTip(height: next, nodeVersion: '3.6.0');
      session.summaryValue = at(next, 4);
      await tester.pump(tipCheckInterval);
      await tester.pumpAndSettle();
      expect(row('Confirming'), findsNothing);
      await tester.pump(boostMaxWindow); // the payment's boost ends, so no timer outlives the test
    });

    testWidgets('a payment waiting for its block sees it within seconds (watch mode)', (
      tester,
    ) async {
      // We answered a minute ago; the sender posts and the next block takes it.
      TxEntry answered({BigInt? height}) => fakeTx(
        id: 11,
        slateId: 'from-desktop',
        kind: TxKind.received,
        status: height == null ? TxStatus.awaitingConfirmation : TxStatus.confirmed,
        createdAtUnix: _at(_now.subtract(const Duration(minutes: 1))),
        blockHeight: height,
        amountCredited: epic(1),
        transport: 'epicbox',
      );
      final h = _Harness(transactions: [answered(), ..._transactions()]);
      await h.pump(tester);
      final refreshes = h.session.refreshCalls;
      final next = _tip + BigInt.one;
      h.service.nodeTipValue = NodeTip(height: next, nodeVersion: '3.6.0');
      h.session.summaryValue = WalletSummary(
        lastConfirmedHeight: next,
        minimumConfirmations: BigInt.from(3),
        total: epic(15.5),
        spendable: epic(12.5),
        awaitingConfirmation: epic(1),
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: epic(2),
        validatedWithNode: true,
      );
      h.session.transactionsValue = [answered(height: next), ..._transactions()];
      await tester.pump(boostMinInterval);
      await tester.pumpAndSettle();
      expect(h.session.refreshCalls, refreshes + 1, reason: 'one refresh, at the boosted pace');
      expect(
        find.descendant(of: find.byType(PhoneTxRow), matching: find.textContaining('Confirming 1 of 3')),
        findsOneWidget,
      );
      await tester.pump(boostMaxWindow); // the payment's boost ends, so no timer outlives the test
    });

    testWidgets('with nothing pending the tip is asked at the normal pace only', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final asks = h.session.nodeTipsFor.length;
      // Not at the boosted pace: none in two of its steps.
      await tester.pump(boostMinInterval * 2);
      expect(h.session.nodeTipsFor.length, asks);
      // One at the normal pace (the timer started while home loaded).
      await tester.pump(tipCheckInterval);
      expect(h.session.nodeTipsFor.length, asks + 1);
    });

    testWidgets('scan opens Send with the scanned address', (tester) async {
      // Reduced motion: the pending dot on Send's title would pulse on.
      final h = _Harness(scanSupported: true, still: true);
      // A whole address: the scan router sends anything else to its "not an Epic code" sheet.
      const scanned =
          'esBobKey2345678923456789ABCDEFGHJKLMNPQRSTUVWXYZabcd@box.epic.invalid';
      h.scanner.codes.add(scanned);
      await h.pump(tester);
      await _tap(tester, find.byKey(kitScanButtonKey));
      // The Send tab, not a pushed screen, with the recipient filled in.
      expect(find.byType(SendView), findsOneWidget);
      expect(_toField(tester), scanned);
      expect(_selectedTab(tester), ShellWhere.send);
    });

    testWidgets('Android back: Send steps back, then Send and Receive go to Wallet, Wallet leaves', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final payee = '${'b' * 52}@box.epic.invalid';
      await _tab(tester, _l.homeSendButton);
      await tester.enterText(sendTo(), payee);
      await tester.pumpAndSettle();
      await _tap(tester, continueButton());
      expect(sendAmount(), findsOneWidget);
      // Amount back to To, the address kept, still on Send.
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(sendAmount(), findsNothing);
      expect(_toField(tester), payee);
      expect(_selectedTab(tester), ShellWhere.send);
      // To has no step before it: Wallet.
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(_selectedTab(tester), ShellWhere.home);
      await _tab(tester, _l.homeReceiveButton);
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(_selectedTab(tester), ShellWhere.home);
      // On Wallet the app goes to the background; the activity stays, so the engine and the
      // wallet open in the core stay together.
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('epic_wallet/app_task'), (call) async {
        calls.add(call.method);
        return true;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('epic_wallet/app_task'), null));
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(calls, ['toBack']);
      expect(_selectedTab(tester), ShellWhere.home);
    });

    testWidgets('a recovery phrase QR says what it is, never its words', (tester) async {
      final h = _Harness(scanSupported: true, still: true);
      h.scanner.codes.add('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art');
      await h.pump(tester);
      await _tap(tester, find.byKey(kitScanButtonKey));
      expect(find.text(_l.scanPhraseFoundQr), findsOneWidget);
      expect(find.textContaining('abandon'), findsNothing);
      expect(find.text(_l.commonCopy), findsNothing);
      await _tap(tester, find.text(_l.commonOk));
      expect(find.text(_l.scanPhraseFoundQr), findsNothing);
      expect(_selectedTab(tester), ShellWhere.home);
    });

    testWidgets('no scan button where scanning is unsupported', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.byTooltip('Scan a code'), findsNothing);
    });

    testWidgets('a contact name replaces the address in the list', (
      tester,
    ) async {
      final h = _Harness();
      h.session.contactsValue.add(
        Contact(id: 'c1', name: 'Bob', address: _bob),
      );
      await h.pump(tester);
      expect(find.text('Bob'), findsOneWidget);
    });
  });

  group('details', () {
    testWidgets('shows what is known and edits the note', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, const TxDetailsScreen(txKey: 's:from-alice'));

      // The details say the exact amount.
      expect(find.textContaining('+5.0'), findsOneWidget);
      expect(find.textContaining('≈\u00a0\$2.50'), findsOneWidget);
      expect(find.text('Rent share'), findsOneWidget);
      expect(find.text('08commit'), findsNothing);
      await _openMore(tester);
      expect(find.text('2,499,300'), findsOneWidget);
      // The explorer link is a row that copies it; the address is not printed.
      expect(find.text(_l.txDetailsExplorerLink), findsOneWidget);
      expect(find.text(hostSettings.explorerBlock(2499300)!), findsNothing);
      expect(find.text('08commit'), findsNothing);
      // The coins sheet has the row that shows the technical details.
      await _tap(tester, find.text(_l.phonePayCoins));
      expect(find.text('08commit'), findsOneWidget);
      await _tap(tester, find.byKey(txDetailsTechnicalKey));
      expect(find.text('08commit'), findsOneWidget);
      expect(find.text('from-alice'), findsOneWidget);
      await _tap(tester, find.text(_l.commonDone).last);
      await _tap(tester, find.text(_l.commonDone));

      await _tap(tester, find.byKey(txPrivateNoteKey));
      await tester.enterText(
        find.descendant(
          of: find.byType(KitSheet),
          matching: find.byType(TextField),
        ),
        '  Rent for September ',
      );
      await _tap(tester, find.text(_l.commonSave));
      expect(h.session.notes['s:from-alice'], 'Rent for September');
      expect(find.text('Rent for September'), findsOneWidget);
      expect(find.text(_l.txDetailsNoteSaved), findsOneWidget);
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
            amountCredited: epic(5),
            note: 'Rent share',
            messages: const [
              SlateMessage(role: SlateRole.sender, text: 'September rent'),
            ],
          ),
        ],
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:from-alice'));
      // One label for the message, whoever wrote it (GP-011).
      expect(find.text(_l.txDetailsMessageFromSender), findsOneWidget);
      expect(find.textContaining('September rent'), findsOneWidget);
      expect(find.textContaining(_l.txDetailsMessageHintFromSender), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(txPrivateNoteKey), matching: find.text(_l.phonePayNote)),
        findsOneWidget,
      );
      expect(find.text('Rent share'), findsOneWidget);
    });

    testWidgets(
      'a sent message reads Message as on Send; the same text kept apart is the private note',
      (tester) async {
        final h = _Harness(
          transactions: [
            fakeTx(
              id: 5,
              slateId: 'rent-bob',
              kind: TxKind.sent,
              status: TxStatus.confirmed,
              blockHeight: _tip - BigInt.from(700),
              amountDebited: epic(3),
              fee: epic(0.008),
              counterparty: _bob,
              // Send keeps the typed message as the private note too.
              note: 'For rent',
              messages: const [
                SlateMessage(role: SlateRole.sender, text: 'For rent'),
              ],
            ),
          ],
        );
        await h.pump(tester, const TxDetailsScreen(txKey: 's:rent-bob'));
        final message = find.byKey(txOwnMessageKey);
        expect(
          find.descendant(of: message, matching: find.text(_l.txDetailsYourMessage)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: message, matching: find.textContaining('For rent')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: message,
            matching: find.textContaining(_l.txDetailsMessageHintToRecipient),
          ),
          findsOneWidget,
        );
        final note = find.byKey(txPrivateNoteKey);
        expect(
          find.descendant(of: note, matching: find.text(_l.phonePayNote)),
          findsOneWidget,
        );
        expect(find.descendant(of: note, matching: find.text('For rent')), findsOneWidget);
        expect(find.text('Your message'), findsNothing);
        // The private note stays editable, under its own name.
        await _tap(tester, note);
        expect(
          find.descendant(
            of: find.byType(KitSheet),
            matching: find.text(_l.txDetailsNoteDialogTitle),
          ),
          findsWidgets,
        );
        expect(find.text(_l.txDetailsNoteHelper), findsOneWidget);
      },
    );

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
            amountDebited: epic(3),
            fee: epic(0.008),
            counterparty: _bob,
            messages: const [
              SlateMessage(role: SlateRole.sender, text: 'for the pizza'),
              SlateMessage(role: SlateRole.receiver, text: 'thanks!'),
            ],
          ),
        ],
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      // One label for both; the line under each says which way it went.
      expect(find.text('Message'), findsNWidgets(2));
      expect(find.textContaining('for the pizza'), findsOneWidget);
      expect(find.textContaining(_l.txDetailsMessageHintToRecipient), findsOneWidget);
      expect(find.textContaining('thanks!'), findsOneWidget);
      expect(find.textContaining(_l.txDetailsMessageHintFromRecipient), findsOneWidget);
    });

    testWidgets('a payment without messages shows none', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:from-alice'));
      expect(find.text('Message'), findsNothing);
      expect(find.text('Message'), findsNothing);
    });

    testWidgets('cancels a waiting send after confirmation', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(
        Contact(id: 'c1', name: 'Bob', address: _bob),
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));

      // The recipient reads in the line under the amount and in the steps; the More sheet has
      // the rest.
      expect(find.textContaining('To Bob'), findsOneWidget);
      expect(find.text(_l.phoneProgWaitingAnswerNamed('Bob')), findsOneWidget);
      // The network step shows once the payment is on the network.
      expect(find.text(_l.phoneProgNetwork), findsNothing);
      expect(find.textContaining('by block 2,500,120'), findsOneWidget);
      await _openMore(tester);
      expect(find.text(_l.txDetailsSentTo), findsOneWidget);
      expect(find.text(_l.txDetailsAddToContacts), findsNothing);
      await _tap(tester, find.text(_l.commonDone));

      final cancel = find.widgetWithText(KitButton, 'Cancel payment').first;
      await _tap(tester, cancel);
      await _tap(tester, find.text(_l.txDetailsCancelKeep));
      expect(h.session.cancelledTxIds, isEmpty);
      await _tap(tester, cancel);
      await _tap(tester, find.widgetWithText(DangerButton, 'Cancel payment').last);
      expect(h.session.cancelledTxIds, [4]);
      expect(find.text(_l.txDetailsPaymentCancelled), findsOneWidget);
    });

    testWidgets('an undelivered epicbox send says so and sends again', (
      tester,
    ) async {
      final h = _Harness(transactions: _undeliveredSend());
      // The retry at start fails (the relay is still down), so the row stays undelivered.
      h.session.resendEpicboxError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'relay down',
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      expect(h.session.resentEpicboxKeys, isEmpty);
      h.session.resendEpicboxError = null;
      expect(find.text(_l.txStatusNotDelivered), findsOneWidget);
      await _tap(tester, find.widgetWithText(KitButton, _l.txDetailsSendAgain));
      expect(h.session.resentEpicboxKeys, ['s:send-bob']);
      expect(find.widgetWithText(KitButton, _l.txDetailsSendAgain), findsNothing);
      expect(find.text(_l.txDetailsCancelPayment), findsOneWidget);
    });

    testWidgets('linux-14: the relay that did not answer is named, on the row and in the error', (
      tester,
    ) async {
      final h = _Harness(transactions: _undeliveredSend());
      h.session.resendEpicboxError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'epicbox post failed: relay sent nothing in time',
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      expect(
        find.textContaining('did not answer, so the recipient has not received this payment'),
        findsOneWidget,
      );
      await _tap(tester, find.widgetWithText(KitButton, _l.txDetailsSendAgain));
      expect(
        find.descendant(
          of: find.byKey(noticeKey),
          matching: find.textContaining(' did not answer.'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(KitButton, _l.txDetailsSendAgain), findsOneWidget);
    });

    testWidgets('a send that is not undelivered has no Send again', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      expect(find.text(_l.txDetailsSendAgain), findsNothing);
      expect(find.text(_l.phoneProgWaitingAnswer), findsWidgets);
    });

    testWidgets('opening the wallet sends an undelivered epicbox send again, once', (
      tester,
    ) async {
      final h = _Harness(transactions: _undeliveredSend());
      await h.pump(tester);
      await _reload(tester);
      expect(h.session.resentEpicboxKeys, ['s:send-bob']);
    });

    testWidgets('restored funds explain what the chain does not keep', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 'c:restored'));
      expect(find.text(_l.txRestoredFunds), findsOneWidget);
      expect(
        find.textContaining('Found on the chain. Sender and fee'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(KitButton, 'Cancel payment'),
        findsNothing,
      );
    });

    testWidgets('an unknown address offers to save it', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      await _openMore(tester);
      // The whole address as one text, the server straight after the key (the frame's sheet).
      expect(find.text(_bob), findsOneWidget);
      expect(find.text(_l.txDetailsAddToContacts), findsOneWidget);
    });

    testWidgets(
      'a send the node refused says it is not on the network and can be broadcast again at once (android-17)',
      (tester) async {
        final h = _Harness(
          transactions: [
            fakeTx(
              key: 's:refused',
              id: 9,
              kind: TxKind.sent,
              status: TxStatus.awaitingConfirmation,
              createdAtUnix: _at(_now.subtract(const Duration(minutes: 1))),
              amountCredited: epic(1),
              amountDebited: epic(2.008),
              fee: epic(0.008),
              kernelExcess: '08abc',
              repostable: true,
            ),
          ],
        );
        expect(isStuck(h.session.transactionsValue.single), isTrue);

        await h.pump(tester, const TxDetailsScreen(txKey: 's:refused'));
        expect(find.text(_l.phoneProgNotPosted), findsOneWidget);
        expect(find.textContaining('Published to the network'), findsNothing);
        expect(find.textContaining('Confirming 0'), findsNothing);
        await _tap(tester, find.text(_l.txDetailsBroadcastAgain));
        expect(h.session.repostedKeys, contains('s:refused'));
        expect(
          find.textContaining(_l.txDetailsBroadcastAgainDone),
          findsOneWidget,
        );
      },
    );
  });

  group('addresses', () {
    test('lists shorten the key around an ellipsis and keep the relay', () {
      expect(shortAddress(_bob), 'esBobA…567890@box.epic.invalid');
      // A link: host:port whole, without the scheme, in lower case; never cut inside a host.
      expect(shortAddress('http://203.0.113.5:3415'), '203.0.113.5:3415');
      expect(shortAddress('https://Pay.Example.com:3415/'), 'pay.example.com:3415');
      expect(shortAddress('http://host:3415'), 'host:3415');
      expect(shortAddress('short@relay'), 'short@relay');
      expect(shortAddress('${'a' * 52}@r.io:443'), 'aaaaaa…aaaaaa@r.io:443');
    });

    test('titles drop the server when it is the wallet\'s own', () {
      const own = 'box.epic.invalid';
      expect(shortAddress(_bob, ownServer: own), 'esBobA…567890');
      expect(
        shortAddress('${'a' * 52}@BOX.EPIC.INVALID:443', ownServer: own),
        'aaaaaa…aaaaaa',
      );
      // Another server stays, since it is part of where the payment went.
      expect(
        shortAddress('${'a' * 52}@box.net.invalid', ownServer: own),
        'aaaaaa…aaaaaa@box.net.invalid',
      );
      expect(
        shortAddress('http://203.0.113.5:3415', ownServer: own),
        '203.0.113.5:3415',
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
        'Payment to esBobA…567890 finished. Confirming.',
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
      final tx = fakeTx(amountCredited: epic(1.5), counterparty: _bob);
      // The listener only accepted it: the sender still has to finish.
      expect(
        paymentNotice(englishStrings, received, tx),
        '1.5\u00a0EPIC on the way.',
      );
      expect(
        paymentNotice(
          englishStrings,
          ListenerEvent(
            kind: ListenerEventKind.received,
            message: 'raw',
            amount: epic(2),
          ),
          null,
          contactName: 'Alice',
        ),
        '2.0\u00a0EPIC from Alice on the way.',
      );
      expect(
        paymentNotice(englishStrings, received, null),
        'A payment is on the way.',
      );
      expect(
        paymentNotice(englishStrings, received, tx, hidden: true),
        'A payment is on the way.',
      );
      expect(
        paymentNotice(englishStrings, finalized, tx),
        'Payment to esBobA…567890@box.epic.invalid finished. Confirming.',
      );
      expect(
        paymentNotice(englishStrings, finalized, tx, contactName: 'Bob'),
        'Payment to Bob finished. Confirming.',
      );
      expect(
        paymentNotice(englishStrings, finalized, null),
        'Payment finished. Confirming.',
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
          message: 'Received 5.0\u00a0EPIC from esAlice…',
          amount: epic(5),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('5.0\u00a0EPIC on the way.'),
        findsOneWidget,
      );
      expect(find.textContaining('esAlice'), findsNothing);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(find.byType(TxDetailsScreen), findsOneWidget);
      expect(find.text('Rent share'), findsOneWidget);
    });

    testWidgets('a repeat shows no notice and leaves the received one up', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final loads = h.session.transactionsCalls;
      h.session.listenerEvents.add(
        const ListenerEvent(
          kind: ListenerEventKind.received,
          txId: 3,
          message: 'raw',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('on the way'), findsOneWidget);
      final afterReceived = h.session.transactionsCalls;
      h.session.listenerEvents.add(
        const ListenerEvent(
          kind: ListenerEventKind.repeated,
          txId: 3,
          message: 'answered again',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('on the way'), findsOneWidget);
      expect(find.textContaining('Already accepted'), findsNothing);
      expect(h.session.transactionsCalls, afterReceived);
      expect(afterReceived, greaterThan(loads));
    });

    testWidgets('a completed send names the contact', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(
        Contact(id: 'c1', name: 'Bob', address: _bob),
      );
      await h.pump(tester);
      h.session.listenerEvents.add(
        const ListenerEvent(
          kind: ListenerEventKind.finalized,
          slateId: 'send-bob',
          message: 'Sent 2.0\u00a0EPIC, posted to the node',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Payment to Bob finished. Confirming.'),
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
      await tester.pump(statusSettle);
      expect((await _statusWord(tester, epicboxStatusKey)), 'Epicbox, Not connected');
      expect(
        await _statusTip(tester, epicboxStatusKey),
        contains('This wallet is not connected to its Epicbox server and keeps trying'),
      );
      expect(find.textContaining('connection reset'), findsNothing);
    });
  });

  group('user-2', () {
    testWidgets('a payment notice floats over the top and leaves the balance where it is', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final before = tester.getTopLeft(find.byKey(homeFigureKey));
      h.session.listenerEvents.add(
        ListenerEvent(
          kind: ListenerEventKind.received,
          slateId: 'from-alice',
          message: 'raw',
          amount: epic(5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(noticeKey), findsOneWidget);
      expect(find.textContaining('5.0\u00a0EPIC on the way'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      // A toast on top of the page: the balance does not move for it.
      expect(tester.getTopLeft(find.byKey(homeFigureKey)), before);

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
          amount: epic(5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_l.homeNoticeView), findsOneWidget);
      // What a lock does: home goes, the unlock screen takes the whole stack.
      Navigator.of(tester.element(find.byType(HomeScreen))).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const SlotScaffold(body: SizedBox.expand()),
        ),
        (_) => false,
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsNothing);
      await tester.tap(find.text(_l.homeNoticeView));
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
      await tester.tap(find.text(_l.updateInstallButton));
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
      expect(
        find.text('Installing version 1.4.0…'),
        findsOneWidget,
      );

      updates.set(UpdateState(UpdatePhase.failed, update: update));
      await tester.pumpAndSettle();
      expect(shown()?.level, NoticeLevel.error);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(updates.installs, 2);

      updates.set(const UpdateState(UpdatePhase.upToDate));
      await tester.pumpAndSettle();
      expect(find.text(_l.updateUpToDate), findsOneWidget);
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
        refreshed: _summary(spendable: epic(20)),
      );
      final h = _Harness(session: session, still: true);
      await h.pump(tester);
      // Syncing shows once it lasts (walletStatusProvider).
      await tester.pump(statusSettle);
      // Local figures while the refresh against the node runs, with its progress.
      expect(_figure(tester), '12.5');
      expect((await _statusWord(tester, nodeStatusKey)), 'Node, Syncing 40%');
      // The line along the app bar's foot is drawn as far as the sync has come, and no
      // other progress shows.
      expect(_syncLine(tester), 0.4);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // Pull to refresh replaced the button.
      expect(find.byTooltip('Refresh'), findsNothing);

      session.gate.complete();
      await tester.pumpAndSettle();
      expect(_figure(tester), '20.0');
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
      expect((await _statusWord(tester, nodeStatusKey)), 'Node, Synced');
      expect((await _statusWord(tester, epicboxStatusKey)), 'Epicbox, Connected');
      expect(find.textContaining('Up to date'), findsNothing);
      expect(find.textContaining('receive payments'), findsNothing);
    });

    testWidgets('the phrase reminder is a card in the slot, not a notice', (tester) async {
      final h = _Harness(transactions: _backlog());
      _reminderDue(h);
      h.store.values.remove('wallet.mainnet.backedUp');
      await h.pump(tester);
      expect(find.text(_l.phoneBackupReminderText), findsOneWidget);
      expect(find.text(_l.phoneBackupReminderAction), findsOneWidget);
      expect(find.byKey(noticeKey), findsNothing);
      // Nothing is stored just by showing it.
      expect(h.store.values['wallet.mainnet.backupNoticeAt'], isNull);
      // The history reminder waits until the phrase is written down.
      expect(find.textContaining('not in the exported wallet data'), findsNothing);

      // It stays on the next opening, and the day after.
      await tester.pumpWidget(const SizedBox());
      await h.pump(tester);
      expect(find.text(_l.phoneBackupReminderText), findsOneWidget);
    });

    testWidgets('the cross hides the phrase reminder for a day, then it comes back', (tester) async {
      final h = _Harness(transactions: _backlog());
      _reminderDue(h);
      h.store.values.remove('wallet.mainnet.backedUp');
      await h.pump(tester);
      await _tap(tester, find.byIcon(KitIcons.close));
      expect(find.text(_l.phoneBackupReminderText), findsNothing);
      expect(h.store.values['wallet.mainnet.backupNoticeAt'], '${_now.millisecondsSinceEpoch}');

      // Not on the next opening the same day.
      await tester.pumpWidget(const SizedBox());
      await h.pump(tester);
      expect(find.text(_l.phoneBackupReminderText), findsNothing);

      // A day later it comes back.
      h.store.values['wallet.mainnet.backupNoticeAt'] = '${_now.subtract(const Duration(days: 1)).millisecondsSinceEpoch}';
      await tester.pumpWidget(const SizedBox());
      await h.pump(tester);
      expect(find.text(_l.phoneBackupReminderText), findsOneWidget);
    });

    testWidgets('a backed up phrase never shows the reminder', (tester) async {
      final h = _Harness(transactions: _backlog());
      _reminderDue(h);
      h.store.values['wallet.mainnet.backedUp'] = '1';
      await h.pump(tester);
      expect(find.text(_l.phoneBackupReminderText), findsNothing);
      expect(find.byKey(noticeKey), findsNothing);
    });

    testWidgets('deleting the wallet forgets the phrase reminder', (
      tester,
    ) async {
      final store = MemorySecretStore()
        ..values['wallet.mainnet.backupCardDismissed'] = '1'
        ..values['wallet.mainnet.backupNoticeAt'] = '1';
      await WalletVault(
        store: store,
        biometrics: MemoryBiometricStore(),
        service: FakeWalletService(),
      ).forget(Chain.mainnet);
      expect(store.values['wallet.mainnet.backupCardDismissed'], isNull);
      expect(store.values['wallet.mainnet.backupNoticeAt'], isNull);
    });
  });

  group('the Tor address notice', () {
    testWidgets('a wallet made through the vault opens without it, the phrase reminder shows', (
      tester,
    ) async {
      final h = _Harness(transactions: _backlog(), fromBeforeOnionKey: true);
      _reminderDue(h);
      h.store.values
        ..remove('wallet.mainnet.backedUp')
        ..remove('wallet.mainnet.pinSealed');
      final created = await tester.runAsync(
        () => WalletVault(store: h.store, biometrics: MemoryBiometricStore(), service: FakeWalletService(), legacyFiles: (_) async => false).create(h.config, pin: _Harness._pin),
      );
      created!.session.dispose();
      await h.pump(tester);
      expect(find.text(_l.torAddressChangedTitle), findsNothing);
      expect(find.text(_l.phoneBackupReminderText), findsOneWidget);
    });

    testWidgets('a wallet from before the update sees one line, once; the phrase reminder is in the slot', (
      tester,
    ) async {
      final h = _Harness(transactions: _backlog(), fromBeforeOnionKey: true);
      _reminderDue(h);
      h.store.values.remove('wallet.mainnet.backedUp');
      h.store.values['app.payment_prefs'] = PaymentPrefs.phoneDefaults.copyWith(linkTor: true).encode();
      await h.pump(tester);
      final notice = find.byKey(noticeKey);
      expect(find.descendant(of: notice, matching: find.text(_l.torAddressChangedTitle)), findsOneWidget);
      expect(find.descendant(of: notice, matching: find.byIcon(KitIcons.close)), findsOneWidget);
      expect(h.store.values[onionNoticeKey('mainnet', null)], onionNoticeSeen);
      expect(h.store.values['wallet.mainnet.backupNoticeAt'], isNull);

      await tester.tap(find.descendant(of: notice, matching: find.byIcon(KitIcons.close)));
      await tester.pumpAndSettle();
      expect(notice, findsNothing);

      await tester.pumpWidget(const SizedBox());
      await h.pump(tester);
      expect(find.text(_l.torAddressChangedTitle), findsNothing);
      expect(find.text(_l.phoneBackupReminderText), findsOneWidget);
    });

    testWidgets('a wallet with epic1 sees it too: it is not held back', (tester) async {
      final session = FakeWalletSession(summary: _summary(), transactions: _backlog())..epic1Fake = FakeEpic1();
      final h = _Harness(session: session, fromBeforeOnionKey: true);
      h.store.values['app.payment_prefs'] = PaymentPrefs.phoneDefaults.copyWith(linkTor: true).encode();
      await h.pump(tester);
      expect(find.descendant(of: find.byKey(noticeKey), matching: find.text(_l.torAddressChangedTitle)), findsOneWidget);
      expect(h.store.values[onionNoticeKey('mainnet', null)], onionNoticeSeen);
    });

    testWidgets('with Tor receiving off it does not show, and waits', (tester) async {
      final h = _Harness(transactions: _backlog(), fromBeforeOnionKey: true);
      h.store.values['app.payment_prefs'] = PaymentPrefs.phoneDefaults.copyWith(linkTor: false).encode();
      await h.pump(tester);
      expect(find.text(_l.torAddressChangedTitle), findsNothing);
      expect(h.store.values[onionNoticeKey('mainnet', null)], isNull);
    });
  });

  group('tab swipe', () {
    testWidgets('a sideways swipe moves to the next and previous tab', (tester) async {
      final h = _Harness(transactions: const []);
      await h.pump(tester);
      final c = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
      expect(c.read(shellTabProvider), ShellTab.home);
      await tester.fling(find.byType(HomeScreen), const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(c.read(shellTabProvider), ShellTab.activity);
      await tester.fling(find.byType(HomeScreen), const Offset(300, 0), 1500);
      await tester.pumpAndSettle();
      expect(c.read(shellTabProvider), ShellTab.home);
    });
  });

  group('first run', () {
    testWidgets('an empty wallet shows Recent as empty slots, and Receive is the gold button', (
      tester,
    ) async {
      final h = _Harness(session: FakeWalletSession(summary: _emptySummary(), transactions: const []));
      await h.pump(tester);
      expect(find.text('No payments yet'), findsNothing);
      expect(find.text(_l.phoneHomeRecent), findsOneWidget);
      expect(find.text(_l.phoneHomeFirstPayment), findsOneWidget);
      expect(find.text(_l.phoneHomeFirstPaymentHint), findsOneWidget);
      expect(find.textContaining('while this app is open'), findsNothing);
      expect(find.text('See all'), findsNothing);
      expect(find.text('Show my address'), findsNothing);
      KitButtonKind kind(String label) => tester.widget<KitButton>(find.widgetWithText(KitButton, label)).kind;
      expect(kind(_l.homeReceiveButton), KitButtonKind.gold);
      expect(kind(_l.homeSendButton), KitButtonKind.quiet);
    });

    testWidgets('with money or a payment, Send is the gold button and the slots are gone', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.text(_l.phoneHomeFirstPayment), findsNothing);
      KitButtonKind kind(String label) => tester.widget<KitButton>(find.widgetWithText(KitButton, label)).kind;
      expect(kind(_l.homeSendButton), KitButtonKind.gold);
      expect(kind(_l.homeReceiveButton), KitButtonKind.quiet);
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
      expect(find.textContaining('3 Aug'), findsOneWidget);
      expect(find.textContaining('1 Aug'), findsNothing);

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
            amountCredited: epic(4),
            cancellable: true,
            // Past the 15-minute hold, so Cancel is offered (test/receive_cancel_test.dart).
            createdAtUnix: _now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          ),
        ],
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:in'));
      await _tap(tester, find.byKey(txDetailsCancelReceiveKey));
      expect(find.text(_l.txDetailsCancelTitle), findsOneWidget);
      expect(find.textContaining('Nothing has arrived yet'), findsOneWidget);
      expect(find.textContaining('shows as received'), findsOneWidget);
      await _tap(tester, find.widgetWithText(DangerButton, 'Cancel payment').last);
      expect(h.session.cancelledTxIds, [7]);
    });

    testWidgets('cancelling a send keeps the send wording', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      await _tap(tester, find.widgetWithText(KitButton, _l.txDetailsCancelPayment).first);
      expect(find.textContaining('cancelling is free and certain'), findsOneWidget, reason: 'the dialog only: no quiet line under Cancel');
      expect(find.textContaining('rescan'), findsNothing);
    });

    testWidgets('another linked device\'s payment is not in the pending card', (tester) async {
      final h = _Harness(
        transactions: [
          fakeTx(
            key: 'd:desk:s1',
            kind: TxKind.sent,
            status: TxStatus.awaitingRecipient,
            amountDebited: epic(1),
            origin: TxOrigin.linkedDevice,
          ),
        ],
      );
      await h.pump(tester);
      expect(find.text('A payment is waiting for the recipient'), findsNothing);
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
            amountCredited: epic(1),
            amountDebited: epic(3),
          ),
        ],
      );
      await h.pump(tester);
      expect(find.text('A payment is waiting for the recipient'), findsNothing);
      // It is a row of Recent, not an open payment.
      expect(find.byType(PhoneTxRow), findsOneWidget);
      expect(find.textContaining('Waiting for'), findsNothing);
    });

    testWidgets('cancelled rows show no fiat value', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, const HistoryScreen());
      // The cancelled 1\u00a0EPIC send would be 0.50\u00a0USD.
      expect(find.text('\u22121.0'), findsOneWidget);
      expect(find.text('\$0.50'), findsNothing);
      expect(find.text('\$1.00'), findsOneWidget);
      // Cancelled is said by the chip, not the title.
      expect(find.text(_l.txOutgoingPayment), findsOneWidget);
    });

    testWidgets('the three filters sit on one row', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());
      final first = tester.getCenter(find.text('All'));
      final last = tester.getCenter(find.text('Sent'));
      expect(first.dy, last.dy);
    });

    testWidgets(
      'technical rows hide by default; More shows them once, the switch stays off',
      (tester) async {
        final h = _Harness();
        await h.pump(tester, const TxDetailsScreen(txKey: 's:from-alice'));
        expect(find.text(_l.txDetailsKernel), findsNothing);
        expect(find.text(_l.phonePayMore), findsOneWidget);
        await _openMore(tester);
        expect(find.text('08commit'), findsNothing);
        expect(find.text(_l.txDetailsKernel), findsNothing);
        expect(find.byKey(txDetailsTechnicalKey), findsNothing);
        await _tap(tester, find.text(_l.phonePayCoins));
        expect(find.text(_l.txDetailsKernel), findsNothing);
        await _tap(tester, find.byKey(txDetailsTechnicalKey));
        // The rows show, and the row is gone.
        expect(find.text('08commit'), findsOneWidget);
        expect(find.text(_l.txDetailsKernel), findsOneWidget);
        expect(find.byKey(txDetailsTechnicalKey), findsNothing);
        // Only this view: a new one starts hidden again.
        await tester.pumpWidget(const SizedBox());
        final again = _Harness();
        await again.pump(tester, const TxDetailsScreen(txKey: 's:from-alice'));
        await _openMore(tester);
        expect(find.text('08commit'), findsNothing);
        await _tap(tester, find.text(_l.phonePayCoins));
        expect(find.byKey(txDetailsTechnicalKey), findsOneWidget);
      },
    );

    testWidgets('with Technical details on the rows show and there is no More', (
      tester,
    ) async {
      final h = _Harness(
        advanced: const AdvancedPrefs(
          features: {AdvancedFeature.technicalDetails},
        ),
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:from-alice'));
      await _openMore(tester);
      expect(find.text('08commit'), findsOneWidget);
      expect(find.byKey(txDetailsTechnicalKey), findsNothing);
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
      await _openMore(tester);
      // Rows copy on a tap; there are no tooltips on them.
      expect(find.byTooltip('Copy date'), findsNothing);
      expect(find.byTooltip(_l.txDetailsCopyAddress), findsNothing);
      expect(find.byTooltip('Copy block height'), findsNothing);
      expect(find.byTooltip('Copy local id'), findsNothing);
      expect(find.text(_l.txDetailsExplorerLink), findsOneWidget);
      expect(find.text(_l.phonePayId), findsOneWidget);
      expect(find.text('Wallet log id'), findsNothing);
      await _tap(tester, find.text(_l.phonePayCoins));
      await _tap(tester, find.byKey(txDetailsTechnicalKey));
      expect(find.text(_l.txDetailsLocalId), findsOneWidget);
      await _tap(tester, find.text(_l.commonDone).last);

      // A tap on the explorer row copies it.
      await _tap(tester, find.text(_l.txDetailsExplorerLink));
      expect(find.text(_l.txDetailsLinkCopied), findsOneWidget);
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
        // The line under the amount names the short address; the sheet has it whole.
        expect(find.textContaining('To esBobA…'), findsOneWidget);
        expect(find.text(_bob.split('@').first), findsNothing);
        await _openMore(tester);
        expect(find.text(_bob), findsOneWidget);
        expect(find.text(_l.txDetailsCopyAddress), findsOneWidget);
      },
    );

    testWidgets('large balances group thousands', (tester) async {
      final h = _Harness();
      h.session.summaryValue = _summary(spendable: epic(1234.5678));
      await h.pump(tester);
      expect(_figure(tester), '1,234.5678');
    });
  });

  group('polish', () {
    testWidgets('a scrolling row fades where more lies beyond the edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              child: FadingRow(
                children: [
                  for (var i = 0; i < 5; i++) SizedBox(width: 90, child: Text('chip $i')),
                ],
              ),
            ),
          ),
        ),
      );
      final row = tester.state<FadingRowState>(find.byType(FadingRow));
      expect(row.moreRight, isTrue);
      expect(row.moreLeft, isFalse);
      await tester.drag(find.text('chip 0'), const Offset(-2000, 0));
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
        'Waiting for 16 days. The Epicbox server deletes payments after 7 days, so '
        'this one can no longer complete. Cancel it to free the coins, then '
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

    test('a posted send is not stuck: only one the node refused', () {
      TxEntry finished({required bool repostable}) => fakeTx(
        kind: TxKind.sent,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: _at(_now.subtract(const Duration(hours: 2))),
        amountCredited: epic(1),
        amountDebited: epic(2.008),
        fee: epic(0.008),
        kernelExcess: '08abc',
        repostable: repostable,
      );
      expect(isStuck(finished(repostable: false)), isFalse);
      expect(isStuck(finished(repostable: true)), isTrue);
      expect(
        txStatusLabel(englishStrings, finished(repostable: true), _tip),
        _l.txStatusNotPosted,
      );
      expect(
        txExplanation(englishStrings, finished(repostable: false), _tip),
        startsWith('Published to the network'),
      );
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
            amountCredited: epic(1),
            amountDebited: epic(3),
            counterparty: _bob,
            cancellable: true,
          ),
        ],
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:old'));
      expect(find.textContaining('can no longer complete'), findsOneWidget);
      expect(
        find.widgetWithText(KitButton, _l.txDetailsCancelPayment).first,
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
            amountCredited: epic(1),
            amountDebited: epic(3),
            repostable: true,
            releasable: true,
          ),
        ],
      );
      await h.pump(tester, const TxDetailsScreen(txKey: 's:refused'));
      final release = find.widgetWithText(KitButton, _l.txDetailsReleaseFunds);
      await _tap(tester, release);
      // One calm sentence, the two-line comparison, the choices named by outcome (B-04).
      expect(find.text(_l.txDetailsReleaseBody), findsOneWidget);
      expect(find.text(_l.cancelCompareMoveBack), findsOneWidget);
      expect(find.textContaining('Unlock coins: free'), findsOneWidget);
      expect(find.textContaining(_l.cancelMoveBack), findsNWidgets(2));
      expect(find.text(_l.cancelUnlockOpen), findsOneWidget);
      await _tap(tester, find.text(_l.txDetailsReleaseKeepWaiting));
      expect(h.session.releasedKeys, isEmpty);
      await _tap(tester, release);
      await _tap(tester, find.byKey(cancelForSureKey));
      expect(h.session.releasedKeys, ['s:refused']);
      expect(find.textContaining(_l.txDetailsFundsReleased), findsOneWidget);
    });

    testWidgets('no release button unless the core allows it', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      expect(find.text(_l.txDetailsReleaseFunds), findsNothing);
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
          amountCredited: epic(i + 1),
          note: i == 1500 ? 'needle' : null,
        ),
    ];

    testWidgets('2,000 payments: history builds only the rows on screen', (
      tester,
    ) async {
      final h = _Harness(transactions: many(2000));
      await h.pump(tester, const HistoryScreen(), 1, const Size(1080, 2340));
      final built = find.byType(PhoneTxRow).evaluate().length;
      expect(built, greaterThan(0));
      expect(built, lessThan(40));
      // Search still reaches a row far down the list.
      await tester.enterText(
        find.widgetWithText(TextField, _l.phoneActSearchHint),
        'needle',
      );
      await tester.pump(searchDebounce);
      await tester.pumpAndSettle();
      expect(find.byType(PhoneTxRow), findsOneWidget);
      expect(find.text('+1,501.0'), findsOneWidget);
    });

    testWidgets('2,000 payments: home shows five', (tester) async {
      final h = _Harness(transactions: many(2000));
      await h.pump(tester);
      expect(find.byType(PhoneTxRow), findsNWidgets(recentActivityCount));
    });

    testWidgets('search waits for typing to pause', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());
      await tester.enterText(find.widgetWithText(TextField, _l.phoneActSearchHint), 'rent');
      await tester.pump(const Duration(milliseconds: 100));
      // Still the whole list: the filter has not run yet.
      expect(find.byType(PhoneTxRow), findsNWidgets(4));
      await tester.pump(searchDebounce);
      await tester.pumpAndSettle();
      expect(find.byType(PhoneTxRow), findsOneWidget);
    });

    test('a row is one sentence', () {
      final tx = fakeTx(
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        amountDebited: epic(10),
      );
      expect(
        txSpokenLabel(
          englishStrings,
          fakeTx(status: TxStatus.confirmed, amountCredited: epic(10)),
          who: 'Alice',
          date: 'Today, 10:01',
          status: 'Received',
          hidden: false,
        ),
        'Received 10.0\u00a0EPIC from Alice, completed, Today, 10:01',
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
        Contact(id: 'c1', name: 'Bob', address: _bob),
      );
      await h.pump(tester);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('tx-s:send-bob'))),
        matchesSemantics(
          label: 'Sending 2.0\u00a0EPIC to Bob, waiting for Bob, 09:00',
          isButton: true,
          hasTapAction: true,
          hasLongPressAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('tx-s:from-alice'))),
        matchesSemantics(
          label: 'Received 5.0\u00a0EPIC, completed, Yesterday, 18:00',
          isButton: true,
          hasTapAction: true,
          hasLongPressAction: true,
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
      // Wallet's figure reads its caption too.
      expect(
        find.bySemanticsLabel('Balance: Balance hidden'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('tx-s:from-alice'))),
        matchesSemantics(
          label: 'Received a hidden amount, completed, Yesterday, 18:00',
          isButton: true,
          hasTapAction: true,
          hasLongPressAction: true,
        ),
      );
      expect(find.bySemanticsLabel(RegExp('5\u00a0EPIC')), findsNothing);
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
      amountCredited: epic(1),
      amountDebited: epic(3),
      counterparty: _bob,
      finalizedAtUnix: finalizedAt,
      ttlCutoffHeight: cutoff,
    );

    test('a finished send cancelled past its limit says to check', () {
      expect(
        txExplanation(
          englishStrings,
          cancelledSend(finalizedAt: _at(_now), cutoff: _tip - BigInt.one),
          _tip,
        ),
        'It did not reach the network in time and was cancelled. Check the '
        'recipient did not receive it before sending again.',
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
        startsWith('The recipient did not answer within 24 hours'),
      );
      // Cancelled by the user.
      expect(
        txExplanation(englishStrings, cancelledSend(), _tip),
        'Nothing was paid, and the coins are spendable again. If it already '
        'arrived, the recipient’s wallet may still show it as waiting.',
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
          'A payment failed.',
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
      expect(find.text(_l.homeNoticeView), findsOneWidget);
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
      amountCredited: epic(1),
      amountDebited: epic(3),
      finalizedAtUnix: finalizedAt,
      ttlCutoffHeight: cutoff,
      cancelReason: reason,
    );

    test('the cancelled explanation follows the recorded reason', () {
      String say(TxEntry tx) => txExplanation(englishStrings, tx, _tip);
      expect(
        say(cancelled(CancelReason.user)),
        'Nothing was paid, and the coins are spendable again. If it already '
        'arrived, the recipient’s wallet may still show it as waiting.',
      );
      // The user cancelled on day 2; from day 14 the old rule would blame the limit.
      expect(
        say(cancelled(CancelReason.user, cutoff: _tip - BigInt.one)),
        'Nothing was paid, and the coins are spendable again. If it already '
        'arrived, the recipient’s wallet may still show it as waiting.',
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
        startsWith('It did not reach the network in time'),
      );
      expect(
        say(cancelled(CancelReason.expiry)),
        startsWith('The recipient did not answer within 24 hours'),
      );
      expect(
        say(cancelled(CancelReason.lateAnswer, cutoff: _tip - BigInt.one)),
        startsWith('The recipient answered after the 24-hour limit'),
      );
      expect(
        say(cancelled(CancelReason.failed)),
        'It could not be delivered to the recipient, so the wallet cancelled '
        'it at once. Nothing was sent, and the coins are spendable again.',
      );
      // No recorded reason: the old rule.
      expect(
        say(cancelled(null, cutoff: _tip - BigInt.one)),
        startsWith('The recipient did not answer within 24 hours'),
      );
      expect(say(cancelled(null)), startsWith('Nothing was paid'));
      // android-13: a cancelled send may have reached the recipient, so it never says
      // nothing was sent.
      for (final r in [
        CancelReason.user,
        CancelReason.expiry,
        CancelReason.lateAnswer,
        null,
      ]) {
        expect(say(cancelled(r)), isNot(contains('Nothing was sent')));
      }
    });

    testWidgets('a delayed payment is announced once', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final delayed = ListenerEvent(
        kind: ListenerEventKind.delayed,
        slateId: 'send-bob',
        message:
            'Could not reach the node. The payment will finish once it can.',
        amount: epic(2),
      );
      h.session.listenerEvents.add(delayed);
      await tester.pumpAndSettle();
      expect(
        find.text(_l.homeNoticeDelayed),
        findsOneWidget,
      );
      expect(find.text('A payment failed.'), findsNothing);
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
          amountCredited: epic(1),
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

    // The desktop's words (GP-046).
    const reminder = '11 payments are not in the exported wallet data.';

    testWidgets('home reminds to export, and export clears it', (tester) async {
      final h = _Harness(transactions: _backlog());
      _reminderDue(h);
      await h.pump(tester);
      expect(find.text(reminder), findsOneWidget);
      await _tap(tester, find.text(_l.homeHistoryExportButton));
      expect(h.files.saved.single.name, 'epic-wallet-data-20260930.wfeh');
      expect(find.text(reminder), findsNothing);
      expect(h.store.values['app.history_exported.mainnet'], '${_at(_now)}');
    });

    testWidgets('not now hides it for 30 days', (tester) async {
      final h = _Harness(transactions: _backlog());
      _reminderDue(h);
      await h.pump(tester);
      await _tap(tester, find.text(_l.homeHistoryReminderNotNow));
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
      expect(find.text(_l.phoneBackupReminderText), findsOneWidget);
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
            amountCredited: epic(1),
            amountDebited: epic(3),
            counterparty: _bob,
          ),
        ],
      );
      await h.pump(tester);
      await _tap(tester, find.byKey(const ValueKey('tx-s:paid')));
      await _tap(tester, find.text(_l.txDetailsSendAgain));
      // Details close, and the shell shows Send with the recipient.
      expect(find.byType(TxDetailsScreen), findsNothing);
      expect(_selectedTab(tester), ShellWhere.send);
      expect(_toField(tester), _bob);
    });

    testWidgets('no send again for pending sends or receives', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:send-bob'));
      expect(find.text(_l.txDetailsSendAgain), findsNothing);
    });
  });

  group('fix-5', () {
    final exportedAt = _at(_now);
    TxEntry row(String key, TxStatus status, {String? note, int? at}) => fakeTx(
      key: key,
      status: status,
      createdAtUnix: at ?? _at(_now.subtract(const Duration(days: 1))),
      amountCredited: epic(1),
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
      await _tap(tester, find.text(_l.homeHistoryExportButton));
      expect(find.textContaining('exported wallet data.'), findsNothing);
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
      'the balance stays on top; the reminder sits above Recent',
      (tester) async {
        final h = _Harness(transactions: _backlog());
        _reminderDue(h);
        await h.pump(tester);
        double top(Finder f) => tester.getTopLeft(f).dy;
        final balance = top(find.byKey(homeFigureKey));
        final reminder = top(find.textContaining('not in the exported wallet data'));
        expect(balance, lessThan(reminder));
        expect(reminder, lessThan(top(find.text(_l.phoneHomeRecent))));
      },
    );

    testWidgets('send again is a button, add to contacts a row in More', (
      tester,
    ) async {
      final h = _Harness(
        transactions: [
          fakeTx(
            slateId: 'paid',
            kind: TxKind.sent,
            status: TxStatus.confirmed,
            amountCredited: epic(1),
            amountDebited: epic(3),
            fee: epic(0.008),
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
      final again = find.widgetWithText(KitButton, _l.txDetailsSendAgain);
      expect(again, findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      // The address, with its Add to contacts row, is in the More sheet.
      expect(find.text(_l.txDetailsAddToContacts), findsNothing);
      await _openMore(tester);
      expect(find.text(_l.txDetailsAddToContacts), findsOneWidget);
      final sentTo = tester.getTopLeft(find.text(_l.txDetailsSentTo)).dy;
      expect(tester.getTopLeft(find.text(_l.txDetailsAddToContacts)).dy, greaterThan(sentTo));
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
    final payee = '${'b' * 52}@box.epic.invalid';

    // DEFECT (home_parts.dart _BalanceTile): the tile's Semantics is a button with
    // excludeSemantics and no onTap, so the InkWell's tap action is dropped and a screen
    // reader cannot press it.

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

    testWidgets('with reduced motion the glow does not breathe', (
      tester,
    ) async {
      final session = _SlowRefreshSession(refreshed: _summary());
      final h = _Harness(session: session, still: true);
      await h.pump(tester);
      // Syncing shows once it lasts (walletStatusProvider).
      await tester.pump(statusSettle);
      expect(_syncLine(tester), 0.4);
      final glow = _glow(tester);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        expect(_glow(tester), glow);
      }
      session.gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a failed listener stream shows epicbox offline', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      h.session.listenerEvents.addError(StateError('relay closed'));
      await tester.pumpAndSettle();
      await tester.pump(statusSettle);
      expect((await _statusWord(tester, epicboxStatusKey)), 'Epicbox, Not connected');
    });

    testWidgets(
      'no network on Home; the node row names a test network',
      (tester) async {
        final network = find.textContaining(
          RegExp('Main network|Test network|Mainnet|Floonet|Usernet'),
        );
        final main = _Harness();
        await main.pump(tester);
        expect(network, findsNothing);
        expect(find.byType(BrandWordmark), findsNothing);
        final mainRow = await _statusTip(tester, nodeStatusKey);
        expect(mainRow, isNot(contains('Mainnet')));
        expect(mainRow, startsWith('Up to date'));

        await tester.pumpWidget(const SizedBox());
        final floo = _Harness(chain: Chain.floonet);
        await floo.pump(tester);
        expect(find.textContaining('Floonet'), findsNothing);
        expect(find.byType(BrandWordmark), findsNothing);
        // The sheet's node row says so, and a screen reader hears it too.
        expect(await _statusTip(tester, nodeStatusKey), startsWith('Test network'));
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
        'Balance: 12.5\u00a0EPIC\n'
        'Spendable now, plus payments and change still confirming, and coins held for a linked device.\n\n'
        'Total: 14.5\u00a0EPIC\nEverything in this wallet, spendable or not.\n\n'
        'Locked by a payment in progress: 2.0\u00a0EPIC\n'
        'Held for a payment you started; the change comes back when it '
        'completes.',
      );
    });

    testWidgets('Receive keeps its tab across a tab change', (tester) async {
      final h = _Harness(still: true);
      await h.pump(tester);
      await _tab(tester, _l.homeReceiveButton);
      expect(find.byKey(receiveAddressKey).hitTestable(), findsOneWidget);
      for (final tab in ['Wallet', 'Send', 'Receive']) {
        await _tab(tester, tab);
      }
      expect(find.byKey(receiveAddressKey).hitTestable(), findsOneWidget);
      expect(find.text(_l.receiveFileTitle), findsNothing);
    });

    testWidgets('Done after a payment goes to Wallet with a fresh form', (
      tester,
    ) async {
      final h = _Harness(still: true);
      await h.pump(tester, const HomeScreen(), 1, const Size(1080, 2340));
      await _sendOne(tester, payee);
      expect(find.byType(KitSteps), findsOneWidget);
      await _tap(tester, find.text(_l.commonDone));
      expect(_selectedTab(tester), ShellWhere.home);
      await _tab(tester, _l.homeSendButton);
      expect(_toField(tester), isEmpty);
    });

    testWidgets(
      'a recipient handed over while the tracker shows waits for the next form',
      (tester) async {
        final h = _Harness(still: true);
        await h.pump(tester, const HomeScreen(), 1, const Size(1080, 2340));
        await _sendOne(tester, payee);
        expect(find.byType(KitSteps), findsOneWidget);
        final carol = '${'c' * 52}@box.epic.invalid';
        ProviderScope.containerOf(tester.element(find.byType(SendView)))
            .read(sendRecipientProvider.notifier)
            .hand(carol);
        await tester.pumpAndSettle();
        // The tracker stays.
        expect(find.byType(KitSteps), findsOneWidget);
        await _tap(tester, find.text(_l.commonDone));
        await _tab(tester, _l.homeSendButton);
        expect(_toField(tester), carol);

        // The same from the payment file screens.
        await _tap(tester, find.byKey(sendRecipientClearKey));
        await chooseWay(tester);
        await tester.enterText(
          sendAmount(),
          '1',
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        await _tap(tester, find.text(_l.sendMakeFile));
        await enterPin(tester, _Harness._pin);
        await tester.pumpAndSettle();
        ProviderScope.containerOf(tester.element(find.byType(SendView)))
            .read(sendRecipientProvider.notifier)
            .hand(payee);
        await tester.pumpAndSettle();
        expect(find.text(_l.phoneFileSendHint), findsOneWidget);
        // Done is the header's back arrow (the frame has no close on this page).
        await _tap(tester, find.descendant(of: find.byType(SendView), matching: find.byTooltip(_l.phoneKitBack)));
        await _tab(tester, _l.homeSendButton);
        expect(_toField(tester), payee);
      },
    );

    testWidgets(
      'the tracker moves on when their wallet answers, without a notice',
      (tester) async {
        final h = _Harness(still: true);
        await h.pump(tester, const HomeScreen(), 1, const Size(1080, 2340));
        await _sendOne(tester, payee);
        expect(find.byType(KitSteps), findsOneWidget);

        // Their reply comes: the listener finishes and posts it.
        h.session.transactionsValue.add(
          fakeTx(
            slateId: 'send-1',
            kind: TxKind.sent,
            status: TxStatus.awaitingConfirmation,
            amountDebited: epic(1) + h.session.fee,
            fee: h.session.fee,
            counterparty: payee,
          ),
        );
        h.session.listenerEvents.add(
          const ListenerEvent(
            kind: ListenerEventKind.finalized,
            slateId: 'send-1',
            message: 'Sent 1.0\u00a0EPIC, posted to the node',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(_l.phoneProgSent), findsOneWidget);
        expect(find.text(_l.phoneProgNetwork), findsOneWidget);
        // The tracker says it; a notice would say it twice.
        expect(find.textContaining('finished. Confirming'), findsNothing);
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
        // that a rebuild repeats; every button there passes. The flow header's close and back
        // marks are the kit's 44 dp (HANDOFF 7.7), so the two flows skip the 48 dp rule.
        if (tab == 'Wallet') {
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
                of: find.byType(Scaffold),
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
    // The brief's matrix: each amount on Home's figure and on Send's and Receive's header,
    // at three phone widths and two text scales, with the fiat value, without it, and hidden.
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
      // Above the 21 million a typed amount may be, so not through parseEpic.
    ].map((t) {
      final parts = '$t.'.split('.');
      return BigInt.parse('${parts[0]}${parts[1].padRight(8, '0')}');
    }).toList();

    WalletSummary summaryOf(BigInt spendable) => WalletSummary(
      lastConfirmedHeight: _tip,
      minimumConfirmations: BigInt.from(3),
      total: spendable + epic(2),
      spendable: spendable,
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: epic(2),
      validatedWithNode: true,
    );

    for (final width in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 2.0]) {
        for (final mode in ['fiat', 'no fiat', 'hidden']) {
          testWidgets('the matrix at $width dp, text x$scale, $mode', (tester) async {
            final h = _Harness(
              price: mode == 'no fiat' ? null : 0.5,
              still: true,
              session: FakeWalletSession(summary: summaryOf(matrix.first), transactions: _transactions()),
            );
            if (mode == 'hidden') h.store.values['app.hide_balances'] = 'true';
            await h.pump(tester, const HomeScreen(), scale, Size(width * 3, 2340));
            for (final amount in matrix) {
              h.session.summaryValue = summaryOf(amount);
              await _reload(tester);
              final shown = mode == 'hidden' ? hiddenAmount : displayEpic(amount);
              final why = '${formatEpic(amount)} on Home';
              expect(tester.takeException(), isNull, reason: why);
              // One line by the display rule, inside the screen.
              final figure = tester.widget<Text>(find.byKey(homeFigureKey));
              expect(figure.textSpan!.toPlainText(), shown, reason: why);
              expect(figure.maxLines, 1, reason: why);
              expect(tester.getRect(find.byKey(homeFigureKey)).right, lessThanOrEqualTo(width + 0.5), reason: why);
              expect(find.byKey(fiatValueKey), mode == 'fiat' ? findsOneWidget : findsNothing, reason: why);
              for (final flow in [_l.homeSendButton, _l.homeReceiveButton]) {
                await _tab(tester, flow);
                expect(tester.takeException(), isNull, reason: '$why, $flow');
                await closeShellFlow(tester);
              }
            }
          });
        }
      }
    }
  });

  // Send keeps its draft across tabs, and a filled recipient always
  // has × to empty it, with the method it moved back where Send starts (the owner).
  group('Send recipient Clear', () {
    // The method line under the To field names the way the address takes (the field picks it).
    Finder methodLine(String name) => find.descendant(of: find.byType(SendView), matching: find.text(name));
    // The Who step has no button until an address is in (Send-1), so none counts as off.
    bool canContinue(WidgetTester tester) => continueButton().evaluate().isNotEmpty && continueOnPressed(tester) != null;

    /// Wallet, then Receive, then back to Send.
    Future<void> leaveAndBack(WidgetTester tester) async {
      await _tab(tester, _l.shellWalletTab);
      await _tab(tester, _l.homeReceiveButton);
      await _tab(tester, 'Send');
    }

    Future<void> clear(WidgetTester tester) async {
      expect(find.byTooltip(_l.sendClearRecipient), findsOneWidget);
      await _tap(tester, find.byKey(sendRecipientClearKey));
      expect(_toField(tester), isEmpty);
      expect(methodLine('Epicbox'), findsNothing, reason: 'no address, no method line');
      expect(methodLine('Link · HTTP'), findsNothing);
      expect(canContinue(tester), isFalse);
      expect(find.byKey(sendRecipientClearKey), findsNothing);
    }

    testWidgets('a pasted Link address stays across tabs; × empties it and the method', (tester) async {
      final h = _Harness(still: true);
      await h.pump(tester);
      await _tab(tester, _l.homeSendButton);
      expect(find.byKey(sendRecipientClearKey), findsNothing, reason: 'nothing to clear yet');
      const link = 'http://192.168.1.24:3415';
      await tester.enterText(sendTo(), link);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(methodLine(_l.methodDirectHttp), findsOneWidget, reason: 'the address picked the method');
      expect(methodLine('Link · HTTP'), findsOneWidget);
      // Send is a flow over the tab bar now: leaving it ends the draft, the next Send starts empty.
      await leaveAndBack(tester);
      expect(_toField(tester), isEmpty);
      expect(find.byKey(sendRecipientClearKey), findsNothing);
      await tester.enterText(sendTo(), link);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(methodLine('Link · HTTP'), findsOneWidget);
      await clear(tester);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('a pasted Epicbox address and a picked contact both clear', (tester) async {
      final h = _Harness(still: true);
      final carol = '${'c' * 52}@box.net.invalid';
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Carol', address: carol, note: null),
      );
      await h.pump(tester);
      await _tab(tester, _l.homeSendButton);
      final bob = '${'b' * 52}@box.epic.invalid';
      await tester.enterText(sendTo(), bob);
      await tester.pumpAndSettle();
      expect(canContinue(tester), isTrue);
      await clear(tester);

      await pickContact(tester, 'Carol');
      // A picked contact shows as a chip in place of the field.
      expect(find.byKey(sendRecipientClearKey), findsOneWidget);
      expect(sendTo(), findsNothing);
      await clear(tester);
    });
  });

  group('announcement toast', () {
    const first = Announcement(id: 'first-2611', text: 'Faucet open for beta testers.');
    const second = Announcement(id: 'second-2611', text: 'A second message.');
    final card = find.byKey(const ValueKey('home-announcement'));

    testWidgets('shows the first live message under the balance, seen but kept', (tester) async {
      final fake = _FakeAnnouncements([first, second]);
      final h = _Harness(extraOverrides: [announcementsProvider.overrideWith(() => fake)]);
      await h.pump(tester);
      expect(card, findsOneWidget);
      expect(find.text('Faucet open for beta testers.'), findsOneWidget);
      expect(find.text('A second message.'), findsNothing);
      expect(fake.seen, ['first-2611']);
      expect(fake.dismissed, isEmpty);
      expect(tester.getTopLeft(card).dy, greaterThan(tester.getBottomLeft(find.byKey(homeFigureKey)).dy));
    });

    testWidgets('the × dismisses it and the next live message takes its place', (tester) async {
      final fake = _FakeAnnouncements([first, second]);
      final h = _Harness(extraOverrides: [announcementsProvider.overrideWith(() => fake)]);
      await h.pump(tester);
      await tester.tap(find.byKey(const ValueKey('announcement-dismiss')));
      await tester.pumpAndSettle();
      expect(fake.dismissed, ['first-2611']);
      expect(find.text('Faucet open for beta testers.'), findsNothing);
      expect(find.text('A second message.'), findsOneWidget);
    });

    testWidgets('nothing is shown, and no space kept, when nothing is live', (tester) async {
      final fake = _FakeAnnouncements(const []);
      final h = _Harness(extraOverrides: [announcementsProvider.overrideWith(() => fake)]);
      await h.pump(tester);
      expect(card, findsNothing);
      expect(find.byType(AnnouncementCard), findsNothing);
    });
  });
}
