// The phone Outputs screen (design spec phone §4): tiles from the balance, filters, rows,
// the output sheet, Split and Consolidate behind the PIN, and the strategy pref.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/smart_outputs.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/outputs_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const String _pin = '123456';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

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

  Future<ProviderContainer> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 4000);
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

  testWidgets('tiles show the balance and the counts', (tester) async {
    final h = _Harness();
    await h.pump(tester, const OutputsScreen());
    expect(find.text(_l.outputsTitle), findsOneWidget);
    expect(find.text('17 EPIC'), findsOneWidget);
    expect(find.text('3 EPIC'), findsNWidgets(2)); // tile and row
    expect(find.text('3 outputs'), findsNWidgets(1));
    expect(find.text('1 output'), findsOneWidget);
    // Nothing locked in the balance: no third tile.
    expect(find.text(_l.outputsLockedTile), findsNothing);
  });

  testWidgets('a third tile appears when the balance has locked outputs', (
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
    expect(find.textContaining('1 / 3'), findsOneWidget);
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
    expect(find.text(_l.outputsFactConfirmations), findsOneWidget);
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
    expect(container.read(noticeProvider)?.text, _l.outputsSplitStarted(5));
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

  testWidgets('both actions wait while a send is in progress', (tester) async {
    final h = _Harness();
    h.session.summaryValue = _summary(locked: 4, spendable: 13);
    await h.pump(tester, const OutputsScreen());
    for (final label in [_l.outputsSplitButton, _l.outputsConsolidateButton]) {
      final b = find.widgetWithText(OutlinedButton, label);
      expect(tester.widget<OutlinedButton>(b).onPressed, isNull);
    }
    expect(find.text(_l.outputsWaitLocked), findsOneWidget);
  });

  testWidgets('the strategy is saved and shown in Settings', (tester) async {
    final h = _Harness();
    final container = await h.pump(tester, const OutputsScreen());
    expect(find.text(_l.outputsSmallest), findsOneWidget);
    await tester.tap(find.text(_l.outputsStrategy));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.outputsAll));
    await tester.pumpAndSettle();
    expect(
      container.read(appSettingsProvider).value?.sendStrategy,
      SelectionStrategy.all,
    );
    expect(h.store.values['app.send_strategy'], 'all');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(container.read(appSettingsProvider).value?.splitChange, isFalse);
  });

  testWidgets('Settings lists Outputs with its count and strategy', (
    tester,
  ) async {
    final h = _Harness();
    h.store.values['app.send_strategy'] = 'all';
    await h.pump(tester, const SettingsScreen());
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
