// The phone Outputs screen (design spec phone §4): tiles from the balance, filters, rows,
// the output sheet, Split and Consolidate behind the PIN, and the strategy pref.

import 'dart:io';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/smart_outputs.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/info_hint.dart';
import 'package:epic_wallet/src/ui/outputs_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const String _pin = '123456';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

const _sendOptions = AdvancedPrefs(features: {AdvancedFeature.sendOptions});

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

WalletOutput _out(
  String commitment,
  num value, {
  WalletOutputStatus status = WalletOutputStatus.unspent,
  OutputCategory? category = OutputCategory.spendable,
  int confirmations = 10,
  int? txId,
  bool coinbase = false,
}) => WalletOutput(
  commitment: commitment,
  value: _epic(value),
  status: status,
  category: category,
  isCoinbase: coinbase,
  height: BigInt.from(2499000),
  lockHeight: BigInt.zero,
  confirmations: BigInt.from(confirmations),
  txId: txId,
);

String _commit(String c) => c * 66;

/// Six outputs: three spendable (10, 5, 2), one confirming (3), one locked (4), one spent (1).
List<WalletOutput> _six() => [
  _out(_commit('a'), 10),
  _out(_commit('b'), 5),
  _out(_commit('c'), 2),
  _out(
    _commit('d'),
    3,
    status: WalletOutputStatus.unconfirmed,
    category: OutputCategory.awaitingConfirmation,
    confirmations: 1,
  ),
  _out(
    _commit('e'),
    4,
    status: WalletOutputStatus.locked,
    category: OutputCategory.locked,
    txId: 7,
  ),
  _out(_commit('f'), 1, status: WalletOutputStatus.spent, category: null),
];

WalletSummary _summary({num locked = 0, num spendable = 17}) => WalletSummary(
  lastConfirmedHeight: BigInt.from(2500000),
  minimumConfirmations: BigInt.from(3),
  total: _epic(spendable + 3 + locked),
  spendable: _epic(spendable),
  awaitingConfirmation: _epic(3),
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: _epic(locked),
  validatedWithNode: true,
);

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(
    dataDir: '/fake/wallets/mainnet',
    nodeUrl: 'https://node',
  );
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _NoPush implements PushPlatform {
  @override
  Future<bool> start() async => false;

  @override
  Future<bool> configured() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get foreground => const Stream.empty();
}

class _Harness {
  _Harness({List<WalletOutput>? outputs}) {
    store.values['wallet.mainnet.backedUp'] = '1';
    store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_pin);
    session.outputsValue = outputs ?? _six();
    session.owner = service;
  }

  final session = FakeWalletSession(summary: _summary());
  final store = MemorySecretStore();
  final bio = MemoryBiometricStore();
  late final service = FakeWalletService(session: session);

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget home, {
    double width = 360,
    AdvancedPrefs advanced = AdvancedPrefs.none,
  }) async {
    tester.view.physicalSize = Size(width * 3, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(bio),
          updatePlatformProvider.overrideWithValue(null),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
          pushPlatformProvider.overrideWithValue(_NoPush()),
          historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
          sessionProvider.overrideWith(() => _Open(session)),
          walletConfigProvider.overrideWith(_Config.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => AdvancedOptions(prefs: advanced, child: child!),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
  }
}

/// Roboto (the body face) and Montserrat, as a phone draws them.
Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  await (FontLoader('Montserrat')..addFont(read('assets/fonts/Montserrat-SemiBold.ttf'))).load();
}

void main() {
  group('outputWord', () {
    test('names every status', () {
      expect(outputWord(_six()[0]), OutputLabel.spendable);
      expect(outputWord(_six()[3]), OutputLabel.confirming);
      expect(outputWord(_six()[4]), OutputLabel.locked);
      expect(outputWord(_six()[5]), OutputLabel.spent);
      expect(
        outputWord(
          _out(
            'x',
            1,
            status: WalletOutputStatus.unconfirmed,
            category: OutputCategory.awaitingFinalization,
          ),
        ),
        OutputLabel.finalizing,
      );
      expect(
        outputWord(
          _out('x', 1, category: OutputCategory.immature, coinbase: true),
        ),
        OutputLabel.immature,
      );
      expect(
        outputWord(
          _out(
            'x',
            1,
            status: WalletOutputStatus.unconfirmed,
            category: null,
            coinbase: true,
          ),
        ),
        OutputLabel.mining,
      );
    });
  });

  testWidgets('tiles lead with the count and show the value below', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester, const OutputsScreen());
    expect(find.text(_l.outputsTitle), findsOneWidget);
    expect(find.text('17 EPIC'), findsOneWidget);
    expect(find.text('3 EPIC'), findsNWidgets(2)); // tile and row
    expect(find.text('3 outputs'), findsOneWidget);
    // Confirming and Locked both count one.
    expect(find.text('1 output'), findsNWidgets(2));
    // Total instead of Immature on a phone: every output not spent, the whole balance.
    expect(find.text('5 outputs'), findsOneWidget);
    expect(find.text('20 EPIC'), findsOneWidget);
    expect(find.text(_l.outputsLockedTile), findsOneWidget);
    expect(find.text(_l.homeTileTotal), findsOneWidget);
    expect(find.text(_l.outputsImmature), findsNothing);
    // The label is the eyebrow, the count the main line, the value the last.
    final label = tester.getTopLeft(find.text(_l.outputsSpendable).first).dy;
    final count = tester.getTopLeft(find.text('3 outputs')).dy;
    final value = tester.getTopLeft(find.text('17 EPIC')).dy;
    expect(label, lessThan(count));
    expect(count, lessThan(value));
  });

  testWidgets('android-03: each tile counts the outputs its value adds up', (tester) async {
    // 2 spendable; 0.5 confirming; 0.6 and 0.4 awaiting finalization; a 0.01 unpaid invoice.
    // LEPIC's figures: awaiting finalization is in Confirming but not in Total, and an unpaid
    // invoice is in no figure.
    final h = _Harness(
      outputs: [
        _out(_commit('a'), 2),
        _out(_commit('b'), 0.5, status: WalletOutputStatus.unconfirmed, category: OutputCategory.awaitingConfirmation, confirmations: 1),
        _out(_commit('c'), 0.6, status: WalletOutputStatus.unconfirmed, category: OutputCategory.awaitingFinalization, confirmations: 0),
        _out(_commit('d'), 0.4, status: WalletOutputStatus.unconfirmed, category: OutputCategory.awaitingFinalization, confirmations: 0),
        _out(_commit('e'), 0.01, status: WalletOutputStatus.unconfirmed, category: OutputCategory.unpaidInvoice, confirmations: 0),
      ],
    );
    h.session.summaryValue = WalletSummary(
      lastConfirmedHeight: BigInt.from(2500000),
      minimumConfirmations: BigInt.from(3),
      total: _epic(2.5),
      spendable: _epic(2),
      awaitingConfirmation: _epic(0.5),
      awaitingFinalization: _epic(1),
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: true,
    );
    await h.pump(tester, const OutputsScreen());
    // Confirming: 0.5 + 0.6 + 0.4, three outputs; the unpaid invoice is in no tile.
    expect(find.text('1.5 EPIC'), findsOneWidget);
    expect(find.text('3 outputs'), findsOneWidget);
    // Total: 2 + 0.5, two outputs; nothing awaiting finalization.
    expect(find.text('2.5 EPIC'), findsOneWidget);
    expect(find.text('2 outputs'), findsOneWidget);
  });

  testWidgets('the table sits under the tiles, Advanced below it', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester, const OutputsScreen(), advanced: _sendOptions);
    // Filters, then the header, then the rows.
    final filters = tester.getTopLeft(find.text(_l.outputsFilterAll(5))).dy;
    final head = tester.getTopLeft(find.text(_l.outputsColState)).dy;
    final row = tester.getTopLeft(find.text('10 EPIC')).dy;
    expect(filters, lessThan(head));
    expect(head, lessThan(row));
    expect(find.text(_l.outputsColValue), findsOneWidget);
    expect(find.text(_l.outputsColConfirmations), findsOneWidget);
    expect(find.text('10'), findsNWidgets(4));
    expect(find.text('1'), findsOneWidget);
    // The advanced section follows the last row and holds the actions.
    final advanced = find.text(_l.outputsAdvanced);
    expect(advanced, findsOneWidget);
    final lastRow = tester.getBottomLeft(find.text('4 EPIC').last).dy;
    expect(tester.getTopLeft(advanced).dy, greaterThan(lastRow));
    for (final label in [
      _l.outputsSplitButton,
      _l.outputsConsolidateButton,
      _l.outputsDefaultsMoved,
    ]) {
      expect(
        tester.getTopLeft(find.text(label)).dy,
        greaterThan(tester.getTopLeft(advanced).dy),
        reason: label,
      );
    }
  });

  testWidgets('no explanation text in the main view', (tester) async {
    final h = _Harness();
    await h.pump(tester, const OutputsScreen());
    expect(find.textContaining('pieces the balance is made of'), findsNothing);
    // The send defaults moved to Settings › Transactions: nothing of them here without Send
    // options, and only a line pointing there with it.
    expect(find.text(_l.outputsStrategy), findsNothing);
    expect(find.text(_l.outputsSplitChange), findsNothing);
    expect(find.text(_l.outputsDefaultsMoved), findsNothing);
    expect(find.byType(InfoHint), findsNothing);
    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('Send options on: one line points to Settings › Transactions, nothing duplicated', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester, const OutputsScreen(), advanced: _sendOptions);
    expect(find.text(_l.outputsStrategy), findsNothing);
    expect(find.text(_l.outputsSplitChange), findsNothing);
    await tester.tap(find.byKey(outputsDefaultsLinkKey));
    await tester.pumpAndSettle();
    expect(
      find.byKey(settingsSectionKey(SettingsSection.transactions)),
      findsOneWidget,
    );
  });

  testWidgets('android-19: a row note that does not fit wraps instead of being cut', (
    tester,
  ) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final h = _Harness(outputs: [_out(_commit('a'), 0.1, txId: 3)]);
    h.session.transactionsValue = [
      fakeTx(
        id: 3,
        kind: TxKind.received,
        timeUnix: yesterday.millisecondsSinceEpoch ~/ 1000,
        amountCredited: _epic(0.1),
      ),
    ];
    // Real faces: the test font's square glyphs are twice as wide as any real text.
    await tester.runAsync(_loadFonts);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await h.pump(tester, const OutputsScreen(), width: 360);
    final note = find.textContaining(_l.dateYesterday.toLowerCase());
    expect(note, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(note);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a row with no height on chain shows a dash', (tester) async {
    final h = _Harness(outputs: [
      WalletOutput(
        commitment: _commit('a'),
        value: _epic(2),
        status: WalletOutputStatus.unconfirmed,
        category: OutputCategory.awaitingConfirmation,
        isCoinbase: false,
        height: BigInt.zero,
        lockHeight: BigInt.zero,
        confirmations: BigInt.zero,
      ),
    ]);
    await h.pump(tester, const OutputsScreen());
    expect(find.text('–'), findsOneWidget);
  });

  testWidgets('lays out at text scale 1.3 on a 360 dp phone', (tester) async {
    final h = _Harness();
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await h.pump(tester, const OutputsScreen());
    expect(tester.takeException(), isNull);
    expect(find.text(_l.outputsAdvanced), findsOneWidget);
  });

  testWidgets('the Locked tile shows the locked balance', (
    tester,
  ) async {
    final h = _Harness();
    h.session.summaryValue = _summary(locked: 4, spendable: 13);
    await h.pump(tester, const OutputsScreen());
    expect(find.text(_l.outputsLockedTile), findsOneWidget);
    expect(find.text('4 EPIC'), findsNWidgets(2)); // tile and row
  });

  testWidgets('filters narrow the list and spent rows wait for the toggle', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester, const OutputsScreen());
    expect(find.text(_l.outputsFilterAll(5)), findsOneWidget);
    expect(find.text(_l.outputsFilterSpendable(3)), findsOneWidget);
    expect(find.text(_l.outputsFilterConfirming(1)), findsOneWidget);
    expect(find.text(_l.outputsFilterLocked(1)), findsOneWidget);
    expect(find.text('10 EPIC'), findsOneWidget);
    expect(find.text('1 EPIC'), findsNothing);
    await tester.tap(find.text(_l.outputsFilterConfirming(1)));
    await tester.pumpAndSettle();
    expect(find.text('10 EPIC'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.text(_l.outputsFilterAll(5)));
    await tester.tap(find.text(_l.outputsShowSpent));
    await tester.pumpAndSettle();
    expect(find.text('1 EPIC'), findsOneWidget);
  });

  testWidgets('opens on the filter it is given', (tester) async {
    final h = _Harness();
    await h.pump(tester, const OutputsScreen(filter: OutputsFilter.locked));
    expect(find.text('4 EPIC'), findsWidgets);
    expect(find.text('10 EPIC'), findsNothing);
    expect(find.textContaining(_l.outputsWordLocked), findsWidgets);
  });

  testWidgets('a row opens the output sheet with the full commitment', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester, const OutputsScreen());
    await tester.tap(find.text('10 EPIC'));
    await tester.pumpAndSettle();
    expect(find.text(_commit('a')), findsOneWidget);
    expect(find.text(_l.outputsMeanSpendable), findsOneWidget);
    expect(find.text(_l.outputsFactHeight), findsOneWidget);
    expect(find.text('2499000'), findsOneWidget);
    // The table header and the sheet's fact carry the same word.
    expect(find.text(_l.outputsFactConfirmations), findsNWidgets(2));
    expect(find.text(_l.outputsCopy), findsOneWidget);
  });

  testWidgets('empty wallet says so', (tester) async {
    final h = _Harness(outputs: const []);
    h.session.summaryValue = _summary(spendable: 0);
    await h.pump(tester, const OutputsScreen());
    expect(find.textContaining(_l.outputsEmpty), findsOneWidget);
    final split = find.widgetWithText(OutlinedButton, _l.outputsSplitButton);
    expect(tester.widget<OutlinedButton>(split).onPressed, isNull);
    expect(find.textContaining(_l.outputsSplitNeeds), findsOneWidget);
  });

  testWidgets('Split shows the estimate and asks the PIN before posting', (
    tester,
  ) async {
    final h = _Harness();
    final container = await h.pump(tester, const OutputsScreen());
    await tester.tap(find.text(_l.outputsSplitButton));
    await tester.pumpAndSettle();
    expect(find.text(_l.outputsSplitTitle), findsOneWidget);
    expect(find.text(_l.outputsSplitInto(4)), findsOneWidget);
    expect(find.text(_l.outputsFactFee), findsOneWidget);
    expect(find.text(_l.outputsFactEach), findsOneWidget);
    await tester.tap(find.byTooltip('+'));
    await tester.pumpAndSettle();
    expect(find.text(_l.outputsSplitInto(5)), findsOneWidget);
    await tester.tap(find.text(_l.outputsSplitInto(5)));
    await tester.pumpAndSettle();
    expect(find.text(_l.outputsSplitPin), findsOneWidget);
    // Cancelled: nothing posted.
    await tester.tap(find.text(_l.commonCancel).last);
    await tester.pumpAndSettle();
    expect(h.session.splits, isEmpty);
    await tester.tap(find.text(_l.outputsSplitInto(5)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, _pin);
    await tester.pumpAndSettle();
    expect(h.session.splits, [5]);
    expect(find.text(_l.outputsSplitTitle), findsNothing);
    expect(container.read(noticeProvider)?.text, _l.outputsSplitStarted(5, 3));
  });

  testWidgets('Consolidate posts once after the PIN', (tester) async {
    final h = _Harness();
    await h.pump(tester, const OutputsScreen());
    await tester.tap(find.text(_l.outputsConsolidateButton));
    await tester.pumpAndSettle();
    expect(find.text(_l.outputsConsolidateTitle), findsOneWidget);
    await tester.tap(find.text(_l.outputsConsolidateAction));
    await tester.pumpAndSettle();
    expect(find.text(_l.outputsConsolidatePin), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, _pin);
    await tester.pumpAndSettle();
    expect(h.session.consolidations, 1);
  });

  testWidgets('Consolidate makes one output with Split change on', (tester) async {
    final h = _Harness();
    h.store.values['app.split_change'] = 'true';
    final spendable = h.session.outputsValue
        .where((o) => o.category == OutputCategory.spendable)
        .length;
    expect(spendable, greaterThan(1));
    await h.pump(tester, const OutputsScreen());
    await tester.tap(find.text(_l.outputsConsolidateButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.outputsConsolidateAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, _pin);
    await tester.pumpAndSettle();
    expect(h.session.consolidations, 1);
    expect(h.session.splits, isEmpty);
    expect(h.session.sentOptions, isEmpty);
    final made = h.session.outputsValue.where((o) => o.commitment.startsWith('self-'));
    expect(made, hasLength(1));
  });

  testWidgets('both actions wait while a send is in progress', (tester) async {
    final h = _Harness();
    h.session.summaryValue = _summary(locked: 4, spendable: 13);
    await h.pump(tester, const OutputsScreen());
    for (final label in [_l.outputsSplitButton, _l.outputsConsolidateButton]) {
      final b = find.widgetWithText(OutlinedButton, label);
      expect(tester.widget<OutlinedButton>(b).onPressed, isNull);
    }
    expect(find.text(_l.outputsWaitLocked(3)), findsOneWidget);
  });

  testWidgets('Settings › Wallet lists Outputs with its count and strategy', (
    tester,
  ) async {
    final h = _Harness();
    h.store.values['app.send_strategy'] = 'all';
    await h.pump(
      tester,
      const SettingsSectionScreen(section: SettingsSection.wallet),
      advanced: const AdvancedPrefs(features: {AdvancedFeature.outputs}),
    );
    await tester.scrollUntilVisible(
      find.text(_l.outputsTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(_l.outputsSettingsSubtitle(5, _l.outputsAll)),
      findsOneWidget,
    );
  });
}
