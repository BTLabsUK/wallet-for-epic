// The balance and the rows under it tell one story: coins on hold are said plainly beside a
// spendable 0 (design review F-05), and a payment's row never says Completed while the balance
// still counts it as confirming (one of the F-06 disagreements; Send's re-estimate is another,
// in send_test.dart).

import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/shell_header.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

/// A summary as LEPIC reports it: it counts 10 confirmations whatever the app asks for, at
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
  minimumConfirmations: BigInt.from(10),
  total: _epic(spendable + confirming + locked + immature),
  spendable: _epic(spendable),
  awaitingConfirmation: _epic(confirming),
  awaitingFinalization: _epic(waiting),
  immature: _epic(immature),
  locked: _epic(locked),
  validatedWithNode: true,
);

/// Pumps home on [session], in the web demo when [demo], at [width] dp.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeWalletSession session, {
  bool demo = false,
  double width = 412,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, 915 * 3);
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
  addTearDown(() => tester.pumpWidget(const SizedBox()));
  return ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// The words of the figure title on Send and Receive.
String _titleText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(titleFigureKey)).textSpan!.toPlainText();

/// [text] in Wallet's pending line.
Finder _inLine(String text) =>
    find.descendant(of: find.byKey(pendingLineKey), matching: find.text(text));

/// What the only payment row says to a screen reader, which includes its status.
String _rowLabel(WidgetTester tester) => tester
    .widget<Semantics>(
      find
          .descendant(of: find.byType(TxTile), matching: find.byType(Semantics))
          .first,
    )
    .properties
    .label!;

void main() {
  group('coins on hold beside a spendable 0', () {
    testWidgets('a spendable 0 says what is on hold and coming in, plainly', (
      tester,
    ) async {
      // The review's split: 2.5 of 10 EPIC sent, the 10 locked, its change confirming.
      final session = FakeWalletSession(
        summary: _summary(locked: 10, confirming: 7.492),
      );
      await _pump(tester, session, width: 360);
      expect(tester.widget<Text>(find.byKey(balanceFigureKey)).data, '0');
      final line = find.byKey(pendingLineKey);
      for (final text in ['10 on hold', '+7.492 coming in']) {
        expect(
          find.descendant(of: line, matching: find.text(text)).hitTestable(),
          findsOneWidget,
          reason: text,
        );
      }
      // It stands still, and nothing runs to move it.
      final at = tester.getRect(find.text('10 on hold'));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.getRect(find.text('10 on hold')), at);
      expect(tester.binding.hasScheduledFrame, isFalse);

      // The title on Send and Receive agrees: the same 0, and the same words.
      for (final tab in [l.homeSendButton, l.homeReceiveButton]) {
        await _tab(tester, tab);
        expect(_titleText(tester), startsWith('0'), reason: tab);
        for (final text in ['10 on hold', '+7.492 coming in']) {
          expect(
            find.descendant(
              of: find.byType(ShellBarTitle),
              matching: find.textContaining(text),
            ),
            findsOneWidget,
            reason: '$tab: $text',
          );
        }
      }
    });

    testWidgets(
      'at most two items: on hold, and everything on chain coming in',
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
        final line = find.byKey(pendingLineKey);
        expect(find.text('5 on hold'), findsOneWidget);
        // 2 confirming and 16 maturing; the 0.5 not on chain yet is not counted.
        expect(find.text('+18 coming in'), findsOneWidget);
        expect(
          find.descendant(of: line, matching: find.byType(Text)),
          findsNWidgets(2),
        );
        // The ? still lists each balance with its own words.
        final rows = BalanceHelp.rows(l, session.summaryValue);
        expect(rows.map((r) => r.$1), [
          l.balanceTotal,
          l.homeBalanceSpendable,
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
      expect(find.textContaining('1,000,000'), findsNothing);
      final rows = BalanceHelp.rows(l, session.summaryValue);
      expect(rows.map((r) => r.$1), [
        l.balanceTotal,
        l.homeBalanceSpendable,
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
      for (final text in ['7.49283746 on hold', '+6.48473625 coming in']) {
        expect(find.text(text).hitTestable(), findsOneWidget, reason: text);
      }
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
      amountCredited: _epic(2.5),
      counterparty: 'esAlice123@epicbox.epiccash.com',
    );

    for (final demo in [true, false]) {
      testWidgets('a confirming balance never sits under a Completed row '
          '(demo ${demo ? 'on' : 'off'})', (tester) async {
        final session = FakeWalletSession(
          summary: _summary(
            spendable: 10,
            confirming: 2.5,
            height: _tip - BigInt.one,
          ),
          transactions: [received(height: _tip)],
        );
        await _pump(tester, session, demo: demo);
        expect(_rowLabel(tester), isNot(contains('completed')));
        expect(find.text(l.txStatusCompleted), findsNothing);
        expect(find.text(l.txStatusConfirming(0, 10)), findsOneWidget);
        expect(_inLine('+2.5 coming in'), findsOneWidget);

        // The next refresh reaches block 229: ten confirmations, both say so.
        session.summaryValue = _summary(
          spendable: 12.5,
          height: _tip + BigInt.from(9),
        );
        await tester.pump(autoRefreshInterval);
        await tester.pumpAndSettle();
        expect(_inLine('+2.5 coming in'), findsNothing);
        expect(find.text(l.txStatusCompleted), findsOneWidget);
      });
    }

    testWidgets('a tip ahead of the summary does not complete a row early', (
      tester,
    ) async {
      // The node is 3 blocks past the refresh: counted at the node's tip the row would be
      // 10 deep, at the summary's height it is 7, which is what the balance says.
      final session = FakeWalletSession(
        summary: _summary(
          spendable: 10,
          confirming: 2.5,
          height: _tip - BigInt.from(3),
        ),
        transactions: [received(height: _tip - BigInt.from(9))],
      );
      await _pump(tester, session);
      expect(find.text(l.txStatusConfirming(7, 10)), findsOneWidget);
      expect(find.text(l.txStatusCompleted), findsNothing);
    });
  });
}
