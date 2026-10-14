// The web demo's checklist on the Wallet tab: get test coins, then send some to someone.

import 'dart:async';

import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/demo_guide.dart';
import 'package:epic_wallet/src/ui/demo_screens.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations l = englishStrings;

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

final DateTime _now = DateTime(2026, 10, 13, 23);

int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _NoPush implements PushPlatform {
  @override
  Future<bool> configured() async => false;

  @override
  Future<bool> start() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get foreground => const Stream.empty();
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

/// The faucet's 10 EPIC, still waiting for the faucet to finish.
TxEntry _faucet() => fakeTx(
  id: 1,
  slateId: 'faucet',
  kind: TxKind.received,
  status: TxStatus.awaitingConfirmation,
  createdAtUnix: _at(_now.subtract(const Duration(minutes: 3))),
  amountCredited: _epic(10),
  counterparty: 'esFaucet123@flooepicbox.btlabs.uk',
);

/// 2.5 EPIC to a friend's demo, not answered yet.
TxEntry _send() => fakeTx(
  id: 2,
  slateId: 'to-friend',
  kind: TxKind.sent,
  status: TxStatus.awaitingRecipient,
  createdAtUnix: _at(_now.subtract(const Duration(minutes: 1))),
  amountCredited: _epic(7.492),
  amountDebited: _epic(10),
  fee: _epic(0.008),
  counterparty: 'esFriend123@flooepicbox.btlabs.uk',
);

WalletSummary _summary({num spendable = 0, num waiting = 0, num locked = 0}) =>
    WalletSummary(
      lastConfirmedHeight: BigInt.from(2500000),
      minimumConfirmations: BigInt.from(10),
      total: _epic(spendable + locked),
      spendable: _epic(spendable),
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: _epic(waiting),
      immature: BigInt.zero,
      locked: _epic(locked),
      validatedWithNode: true,
    );

class _Harness {
  _Harness({
    this.demo = true,
    List<TxEntry>? transactions,
    WalletSummary? summary,
  }) : session = FakeWalletSession(
         summary: summary ?? _summary(),
         transactions: transactions ?? [],
       );

  final bool demo;
  final FakeWalletSession session;
  final api = FakeDemoApi(
    status: DemoActive(_now.add(const Duration(hours: 5))),
  );
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
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
          demoApiProvider.overrideWithValue(api),
          walletServiceProvider.overrideWithValue(
            FakeWalletService(session: session),
          ),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
          updatePlatformProvider.overrideWithValue(null),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner()),
          pushPlatformProvider.overrideWithValue(_NoPush()),
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
    container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox()));
  }

  /// The wallet's next refresh brings [transactions] and [summary].
  Future<void> refresh(
    WidgetTester tester,
    List<TxEntry> transactions,
    WalletSummary summary,
  ) async {
    session
      ..transactionsValue = transactions
      ..summaryValue = summary;
    await tester.pump(autoRefreshInterval);
    await tester.pumpAndSettle();
  }
}

Finder _inGuide(Finder finder) =>
    find.descendant(of: find.byKey(demoGuideKey), matching: finder);

/// The step whose screen-reader words are [label], and whether it is a live region.
SemanticsNode _step(WidgetTester tester, String label) =>
    tester.getSemantics(find.bySemanticsLabel(label));

void main() {
  test('steps come from the history and the balance', () {
    expect(demoGuideSteps(_summary(), const []), (coins: false, sent: false));
    // Coins still waiting for the faucet count: they are on their way.
    expect(demoGuideSteps(_summary(waiting: 10), const []), (
      coins: true,
      sent: false,
    ));
    expect(demoGuideSteps(_summary(), [_faucet()]), (coins: true, sent: false));
    expect(demoGuideSteps(_summary(locked: 10), [_send(), _faucet()]), (
      coins: true,
      sent: true,
    ));
    // A cancelled send is not a payment made.
    final cancelled = fakeTx(
      id: 3,
      kind: TxKind.sentCancelled,
      status: TxStatus.cancelled,
      amountDebited: _epic(1),
    );
    expect(demoGuideSteps(_summary(), [cancelled]).sent, isFalse);
  });

  testWidgets('without demo mode nothing of the guide shows', (tester) async {
    final h = _Harness(demo: false);
    await h.pump(tester);
    expect(find.byKey(demoGuideKey), findsNothing);
    expect(find.text(l.demoGuideTitle), findsNothing);
    expect(find.text(l.demoGuideSend), findsNothing);
    expect(find.byKey(testCoinsKey), findsNothing);
    expect(find.text(l.homeNoPayments), findsOneWidget);
  });

  testWidgets('an empty demo wallet: Get test coins first, as a list', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final h = _Harness();
    await h.pump(tester);
    expect(find.byKey(demoGuideKey), findsOneWidget);
    expect(_inGuide(find.text(l.demoGuideTitle)), findsOneWidget);
    // Step 1 is the main button; the empty state below has none of its own.
    expect(
      _inGuide(find.widgetWithText(FilledButton, l.demoTestCoins)),
      findsOneWidget,
    );
    expect(find.byKey(testCoinsKey), findsOneWidget);
    expect(find.text(l.homeNoPayments), findsOneWidget);
    // Step 2 waits: no hint, no button yet.
    expect(find.text(l.demoGuideSendHint), findsNothing);
    expect(find.text(l.demoGuideOpenSend), findsNothing);
    // Each step says its state, and says it again when it changes.
    for (final label in [
      l.demoGuideStepToDo(l.demoTestCoins),
      l.demoGuideStepToDo(l.demoGuideSend),
    ]) {
      final node = _step(tester, label);
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      expect(node.parent?.getSemanticsData().role, SemanticsRole.listItem);
      expect(node.parent?.parent?.getSemanticsData().role, SemanticsRole.list);
    }
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('while the faucet works, one line says so', (tester) async {
    final h = _Harness();
    final gate = h.api.claimGate = Completer<void>();
    await h.pump(tester);
    await tester.tap(find.byKey(testCoinsKey));
    await tester.pump();
    await tester.pump();
    expect(_inGuide(find.text(l.demoGuideAsking)), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(testCoinsKey)).onPressed,
      isNull,
    );
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text(l.demoGuideAsking), findsNothing);
    expect(h.api.claimedFor, [h.session.address]);
  });

  testWidgets('the steps tick as the history changes, and step 2 opens Send', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final h = _Harness();
    await h.pump(tester);
    // The faucet's payment arrives, still to be finished by the faucet.
    await h.refresh(tester, [_faucet()], _summary(waiting: 10));
    expect(
      find.bySemanticsLabel(l.demoGuideStepDone(l.demoTestCoins)),
      findsOneWidget,
    );
    expect(find.byKey(testCoinsKey), findsNothing);
    expect(_inGuide(find.text(l.demoGuideSendHint)), findsOneWidget);
    expect(l.demoGuideSendHint, isNot(contains('tab')));
    await tester.tap(find.text(l.demoGuideOpenSend));
    await tester.pumpAndSettle();
    expect(h.container.read(shellTabProvider), ShellTab.send);
    expect(find.byType(SendView).hitTestable(), findsOneWidget);

    // A send to a friend's demo: both done, one quiet line, no buttons.
    await h.refresh(tester, [_send(), _faucet()], _summary(locked: 10));
    h.container.read(shellTabProvider.notifier).go(ShellTab.wallet);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(l.demoGuideStepDone(l.demoGuideSend)),
      findsOneWidget,
    );
    expect(find.text(l.demoGuideDone), findsOneWidget);
    expect(find.text(l.demoGuideOpenSend), findsNothing);
    handle.dispose();
  });

  testWidgets('a returning visitor finds the steps ticked', (tester) async {
    final handle = tester.ensureSemantics();
    final h = _Harness(
      transactions: [_send(), _faucet()],
      summary: _summary(locked: 10),
    );
    await h.pump(tester);
    for (final step in [l.demoTestCoins, l.demoGuideSend]) {
      expect(find.bySemanticsLabel(l.demoGuideStepDone(step)), findsOneWidget);
    }
    expect(find.text(l.demoGuideDone), findsOneWidget);
    expect(find.byKey(testCoinsKey), findsNothing);
    handle.dispose();
  });

  testWidgets(
    'Hide puts it away; Get test coins goes back to the empty state',
    (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await tester.tap(_inGuide(find.text(l.demoGuideHide)));
      await tester.pumpAndSettle();
      expect(find.byKey(demoGuideKey), findsNothing);
      expect(find.byKey(testCoinsKey), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, l.demoTestCoins).hitTestable(),
        findsOneWidget,
      );
    },
  );

  testWidgets('fits a 360 dp phone at text scale 2', (tester) async {
    final h = _Harness(
      transactions: [_faucet()],
      summary: _summary(waiting: 10),
    );
    await h.pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
