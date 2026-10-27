// W-04: the web demo in the UI. Every check that hides something runs with demo mode on and
// off, so the phone app is shown to keep it.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/launch_screen.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/demo_pin.dart';
import 'package:epic_wallet/src/ui/demo_screens.dart';
import 'package:epic_wallet/src/ui/first_run_screen.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/pin.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart' show PinRejected;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const String _pin = '123456';

final AppLocalizations l = englishStrings;

class _Push implements PushPlatform {
  @override
  Future<bool> configured() async => true;

  @override
  Future<bool> start() async => true;

  @override
  Future<String?> token() async => 'token';

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get foreground => const Stream.empty();
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

/// Updates that are supported, counting the checks.
class _Updates extends UpdateNotifier {
  _Updates(this.checks);

  final List<int> checks;

  @override
  bool get supported => true;

  @override
  Future<void> checkOnOpening() async => checks.add(1);
}

/// Records the confirmations every balance call asks for.
class _Session extends FakeWalletSession {
  final List<BigInt> confirmations = [];

  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) {
    confirmations.add(minimumConfirmations);
    return super.summary(
      refresh: refresh,
      minimumConfirmations: minimumConfirmations,
    );
  }

  @override
  Stream<RefreshProgress> refresh({required BigInt minimumConfirmations}) {
    confirmations.add(minimumConfirmations);
    return super.refresh(minimumConfirmations: minimumConfirmations);
  }
}

/// A wallet service whose next [openErrors] PIN opens fail as a lost connection.
class _Service extends FakeWalletService {
  _Service({super.existingWallets, super.session});

  int openErrors = 0;

  /// The next [pinFailures] lookups that fail as a lost connection.
  int lookupErrors = 0;

  @override
  Future<int> pinFailures({required WalletConfig config}) async {
    if (lookupErrors > 0) {
      lookupErrors--;
      throw const WalletError(
        kind: WalletErrorKind.nodeUnreachable,
        message: 'connection lost',
      );
    }
    return super.pinFailures(config: config);
  }

  @override
  Future<WalletSession> openWithPin({
    required WalletConfig config,
    required String pin,
    required String sealedPassword,
  }) {
    if (openErrors > 0) {
      openErrors--;
      throw const WalletError(
        kind: WalletErrorKind.nodeUnreachable,
        message: 'connection lost',
      );
    }
    return super.openWithPin(
      config: config,
      pin: pin,
      sealedPassword: sealedPassword,
    );
  }
}

/// The app with demo mode [demo], on floonet with it and on mainnet without.
class _Harness {
  _Harness({
    this.demo = true,
    DemoStatus? status,
    bool wallet = true,
    bool backedUp = true,
    bool advanced = false,
    String pin = _pin,
    bool demoPinFlag = false,
    this.pinless,
  }) {
    api = FakeDemoApi(
      status: status ?? DemoActive(now.add(const Duration(hours: 5))),
      clock: () => now,
    );
    final chain = demo ? Chain.floonet : Chain.mainnet;
    if (advanced) store.values['app.advanced'] = 'true';
    if (wallet) {
      store.values['wallet.${chain.name}.pinSealed'] = fakeSealedPassword(pin);
      if (backedUp) store.values['wallet.${chain.name}.backedUp'] = '1';
      if (demoPinFlag) store.values['wallet.${chain.name}.demoPin'] = '1';
    }
    service = _Service(
      existingWallets: wallet ? {'/fake/wallets/${chain.name}'} : {},
      session: session,
    );
  }

  final bool demo;

  /// The build asks for no PIN (web demo and preview); null leaves the build's own answer.
  final bool? pinless;
  late final FakeDemoApi api;
  final store = MemorySecretStore();
  final bio = MemoryBiometricStore();
  final session = _Session();
  final updateChecks = <int>[];
  late final _Service service;
  DateTime now = DateTime(2026, 10, 6, 12);
  late ProviderContainer container;

  /// Pumps the app; with [settle] off, only its first frame.
  Future<void> pump(
    WidgetTester tester, {
    double height = 2200,
    bool settle = true,
  }) async {
    tester.view.physicalSize = Size(412 * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          demoModeProvider.overrideWithValue(demo),
          if (pinless != null) pinlessProvider.overrideWithValue(pinless!),
          demoApiProvider.overrideWithValue(api),
          walletServiceProvider.overrideWithValue(service),
          walletDirProvider.overrideWithValue(
            (chain) async => '/fake/wallets/${chain.name}',
          ),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(bio),
          updatePlatformProvider.overrideWithValue(null),
          updateProvider.overrideWith(() => _Updates(updateChecks)),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          clockProvider.overrideWithValue(() => now),
          pushPlatformProvider.overrideWithValue(_Push()),
          qrScannerProvider.overrideWithValue(FakeQrScanner()),
          sharedFilesCleanupProvider.overrideWithValue(() async {}),
        ],
        child: const WalletApp(),
      ),
    );
    if (settle) await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox()));
  }

  Future<void> unlock(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextField, l.pinLabel), _pin);
    await tester.pumpAndSettle();
    expect(container.read(sessionProvider), isNotNull);
  }

  /// Chooses and repeats the PIN on first run.
  Future<void> choosePin(WidgetTester tester) async {
    // The first screen asks Create or Restore before the PIN.
    await tester.tap(find.byKey(firstRunCreateKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, l.pinLabel), _pin);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l.pinRepeatLabel),
      _pin,
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, Widget screen) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => screen)));
    await tester.pumpAndSettle();
  }

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
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

/// Pumps frames until the demo PIN animation shows, at most two seconds' worth.
Future<void> _untilDemoPinFill(WidgetTester tester) async {
  for (var i = 0; i < 40 && find.byType(DemoPinFill).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.byType(DemoPinFill), findsOneWidget);
}

/// The visible notice's text, or null.
String? _notice(_Harness h) => h.container.read(noticeProvider)?.text;

void main() {
  group('welcome', () {
    testWidgets('shows what the demo is, then Start leads to the first run', (
      tester,
    ) async {
      final h = _Harness(status: const DemoNone(), wallet: false);
      await h.pump(tester);
      for (final text in [l.demoWelcomeTitle, l.demoWelcomeLine]) {
        expect(find.text(text), findsOneWidget);
      }
      // The main button sits in the bottom bar of ScreenBody.
      expect(
        find.descendant(
          of: find.byType(ScreenBody),
          matching: find.widgetWithText(FilledButton, l.demoStart),
        ),
        findsOneWidget,
      );
      expect(find.byType(FirstRunScreen), findsNothing);

      await tester.tap(find.text(l.demoStart));
      await _untilDemoPinFill(tester);
      expect(h.api.starts, 1);
      expect(find.byType(FirstRunScreen), findsOneWidget);
      // The demo PIN is filled in: nothing to choose.
      expect(find.text(l.pinChooseTitle(6)), findsNothing);
      // The demo's first run names no network: it only sets itself up.
      expect(find.text(l.demoPinSetUpTitle), findsOneWidget);
      expect(
        find.text('${l.firstRunTitle}${networkSuffix(l, Chain.floonet)}'),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(h.container.read(sessionProvider), isNotNull);
      expect(find.text(l.shellWalletTab), findsOneWidget);
    });

    testWidgets('a failed start says why and stays', (tester) async {
      final h = _Harness(status: const DemoNone(), wallet: false);
      h.api.startError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'down',
      );
      await h.pump(tester);
      await _tap(tester, find.text(l.demoStart));
      expect(find.byType(FirstRunScreen), findsNothing);
      expect(find.byType(ErrorText), findsOneWidget);
      expect(find.text(l.demoStart), findsOneWidget);
    });

    testWidgets('the welcome line leads with the outcome, not the network', (
      tester,
    ) async {
      final h = _Harness(status: const DemoNone(), wallet: false);
      await h.pump(tester);
      expect(l.demoWelcomeLine, isNot(startsWith('Floonet')));
      expect(l.demoWelcomeLine, isNot(contains('Epicbox')));
      // The title, the line and the main button: nothing else to read first.
      expect(
        find.descendant(
          of: find.byType(ScreenBody),
          matching: find.byType(Text),
        ),
        findsNWidgets(3),
      );
    });
  });

  group('ended', () {
    testWidgets('from status(), with Start again', (tester) async {
      final h = _Harness(status: const DemoEnded(), wallet: false);
      await h.pump(tester);
      expect(find.text(l.demoEndedTitle), findsOneWidget);
      expect(find.text(l.demoEndedBody), findsOneWidget);
      // Start again is the one button.
      expect(
        find.byWidgetPredicate((w) => w is ButtonStyleButton),
        findsOneWidget,
      );
      await tester.tap(find.text(l.demoStartAgain));
      await _untilDemoPinFill(tester);
      expect(h.api.starts, 1);
      expect(find.byType(FirstRunScreen), findsOneWidget);
    });

    testWidgets('from the server event, over any screen', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.open(tester, const SettingsScreen());
      h.api.endNow();
      await tester.pumpAndSettle();
      expect(find.text(l.demoEndedTitle), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
      expect(h.container.read(sessionProvider), isNull);
      // Only the ended screen is left to go back to.
      expect(
        tester.state<NavigatorState>(find.byType(Navigator).first).canPop(),
        isFalse,
      );
    });

    testWidgets('from status() once the countdown ran out', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      h.api.current = const DemoEnded();
      h.now = h.now.add(const Duration(hours: 5, seconds: 1));
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(find.text(l.demoEndedTitle), findsOneWidget);
    });

    testWidgets('an event without a running demo changes nothing', (
      tester,
    ) async {
      final h = _Harness(status: const DemoNone(), wallet: false);
      await h.pump(tester);
      h.api.endNow();
      await tester.pumpAndSettle();
      expect(find.text(l.demoWelcomeTitle), findsOneWidget);
    });
  });

  group('countdown', () {
    test('hours from an hour on, rounded; minutes below, rounded up', () {
      expect(demoTimeLeft(const Duration(hours: 24)), (hours: 24, minutes: 0));
      expect(demoTimeLeft(const Duration(hours: 4, minutes: 31)), (
        hours: 5,
        minutes: 0,
      ));
      expect(demoTimeLeft(const Duration(hours: 1, minutes: 29)), (
        hours: 1,
        minutes: 0,
      ));
      expect(demoTimeLeft(const Duration(hours: 1)), (hours: 1, minutes: 0));
      expect(demoTimeLeft(const Duration(minutes: 59, seconds: 1)), (
        hours: 0,
        minutes: 60,
      ));
      expect(demoTimeLeft(const Duration(minutes: 40)), (
        hours: 0,
        minutes: 40,
      ));
      expect(demoTimeLeft(const Duration(seconds: 1)), (hours: 0, minutes: 1));
      expect(demoTimeLeft(Duration.zero), isNull);
    });

    testWidgets('a Test coins pill in the title, Floonet and the end in its '
        'tooltip', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      // The bar names no network; the pill's tooltip says Floonet.
      expect(find.text(chainName(l, Chain.floonet)), findsNothing);
      expect(
        find.text('${l.demoTestCoinsPill} · ${l.demoLeftHours(5)}'),
        findsOneWidget,
      );
      final tooltip = tester.widget<Tooltip>(find.byKey(demoCountdownKey));
      expect(tooltip.message, contains('Floonet'));
      final end = formatDateTime(l, h.now.add(const Duration(hours: 5)));
      expect(
        tooltip.message,
        '${l.demoTestCoinsPillTip}\n${l.demoEndsAt(end)}',
      );
      expect(_notice(h), isNull);

      // Under an hour it counts minutes.
      h.now = h.now.add(const Duration(hours: 4, minutes: 20));
      await tester.pump(const Duration(seconds: 15));
      expect(
        find.text('${l.demoTestCoinsPill} · ${l.demoLeftMinutes(40)}'),
        findsOneWidget,
      );
      expect(_notice(h), isNull);
    });

    testWidgets('warns once at 30 minutes left', (tester) async {
      final h = _Harness(status: DemoActive(DateTime(2026, 10, 6, 12, 31)));
      await h.pump(tester);
      await h.unlock(tester);
      expect(_notice(h), isNull);
      h.now = h.now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 15));
      expect(_notice(h), l.demoEndingSoon);
      expect(h.container.read(noticeProvider)?.level, NoticeLevel.warning);
      h.container.read(noticeProvider.notifier).clear();
      h.now = h.now.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 15));
      await tester.pump(const Duration(seconds: 15));
      expect(_notice(h), isNull);
      expect(
        find.text('${l.demoTestCoinsPill} · ${l.demoLeftMinutes(25)}'),
        findsOneWidget,
      );
    });

    testWidgets('fits at text scale 2', (tester) async {
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      // Reduced motion: at this size Wallet's "Nothing here yet" does not fit, and scrolls on.
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      expect(find.byKey(demoCountdownKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Get test coins', () {
    for (final (name, result, text) in <(String, TestCoinsResult, String)>[
      ('paid', const TestCoinsPaid(), l.demoTestCoinsPaid),
      ('cooldown', const TestCoinsCooldown(39), l.demoTestCoinsCooldown(39)),
      ('failed', const TestCoinsFailed(), l.demoTestCoinsFailed),
    ]) {
      testWidgets('on Wallet: $name', (tester) async {
        final h = _Harness();
        h.api.claims.add(result);
        await h.pump(tester);
        await h.unlock(tester);
        // The empty Wallet tab offers it, in the checklist.
        expect(find.text(l.homeNoPayments), findsOneWidget);
        expect(find.byKey(testCoinsKey), findsOneWidget);
        await _tap(tester, find.byKey(testCoinsKey));
        expect(h.api.claimedFor, [h.session.address]);
        expect(_notice(h), text);
      });
    }

    testWidgets('on Receive, disabled while a claim runs', (tester) async {
      final h = _Harness();
      final gate = h.api.claimGate = Completer<void>();
      await h.pump(tester);
      await h.unlock(tester);
      await h.tab(tester, l.homeReceiveButton);
      final button = find.byKey(testCoinsKey);
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      await tester.pump();
      FilledButton widget() =>
          tester.widget<FilledButton>(find.byKey(testCoinsKey).first);
      expect(widget().onPressed, isNull);
      await tester.tap(button, warnIfMissed: false);
      gate.complete();
      await tester.pumpAndSettle();
      expect(h.api.claimedFor, hasLength(1));
      expect(widget().onPressed, isNotNull);
      expect(_notice(h), l.demoTestCoinsPaid);
    });

    test('a claim that throws is a failure', () async {
      final container = ProviderContainer(
        overrides: [demoApiProvider.overrideWithValue(_ThrowingApi())],
      );
      addTearDown(container.dispose);
      final result = await container
          .read(testCoinsProvider.notifier)
          .claim('address');
      expect(result, isA<TestCoinsFailed>());
      expect(container.read(testCoinsProvider), isFalse);
    });

    testWidgets('absent without demo mode', (tester) async {
      final h = _Harness(demo: false);
      await h.pump(tester);
      await h.unlock(tester);
      expect(find.text(l.homeNoPayments), findsOneWidget);
      expect(find.byKey(testCoinsKey), findsNothing);
      await h.tab(tester, l.homeReceiveButton);
      expect(find.byKey(testCoinsKey), findsNothing);
      expect(find.byKey(demoCountdownKey), findsNothing);
    });
  });

  group('End demo', () {
    testWidgets('confirms, ends the demo and shows the welcome screen', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, height: 3000);
      await h.unlock(tester);
      await h.open(
        tester,
        const SettingsSectionScreen(section: SettingsSection.wallet),
      );
      expect(find.text(l.settingsDeleteWallet), findsNothing);
      await _tap(tester, find.text(l.demoEnd));
      expect(find.text(l.demoEndTitle), findsOneWidget);
      // Cancel keeps it.
      await _tap(tester, find.text(l.commonCancel));
      expect(h.api.ends, 0);
      await _tap(tester, find.text(l.demoEnd));
      await _tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(l.demoEnd),
        ),
      );
      expect(h.api.ends, 1);
      expect(h.container.read(sessionProvider), isNull);
      expect(find.text(l.demoWelcomeTitle), findsOneWidget);
      expect(find.text(l.demoEndedTitle), findsNothing);
      expect(h.store.values['wallet.floonet.pinSealed'], isNull);
    });
  });

  group('network and confirmations', () {
    test('demo mode forces floonet and counts 1 confirmation', () async {
      final store = MemorySecretStore()
        ..values['app.network'] = 'mainnet'
        ..values['app.node.floonet'] = 'https://elsewhere.example';
      ProviderContainer make(bool demo) => ProviderContainer(
        overrides: [
          demoModeProvider.overrideWithValue(demo),
          secretStoreProvider.overrideWithValue(store),
        ],
      );
      final demo = make(true);
      addTearDown(demo.dispose);
      final choice = await demo.read(networkChoiceProvider.future);
      expect(choice.preset, floonetPreset);
      expect(choice.nodeUrl, floonetPreset.nodeUrl);
      expect(choice.relay, floonetPreset.defaultRelay);
      await demo
          .read(networkChoiceProvider.notifier)
          .save(mainnetPreset, mainnetPreset.nodeUrl);
      expect(
        (await demo.read(networkChoiceProvider.future)).preset,
        floonetPreset,
      );
      expect(store.values['app.network'], 'mainnet');
      expect(demo.read(minimumConfirmationsProvider), BigInt.one);

      final phone = make(false);
      addTearDown(phone.dispose);
      expect(
        (await phone.read(networkChoiceProvider.future)).preset,
        mainnetPreset,
      );
      expect(phone.read(minimumConfirmationsProvider), BigInt.from(6));
    });

    for (final demo in [true, false]) {
      testWidgets(
        'balances and status use the count (demo ${demo ? 'on' : 'off'})',
        (tester) async {
          final h = _Harness(demo: demo);
          // One block deep at the fake node's tip.
          h.session.transactionsValue.add(
            fakeTx(
              id: 1,
              confirmed: true,
              blockHeight: BigInt.from(2500000),
              amountCredited: BigInt.from(100000000),
            ),
          );
          await h.pump(tester);
          await h.unlock(tester);
          expect(h.session.confirmations, isNotEmpty);
          // Balance calls ask with the fallback, which LEPIC ignores.
          expect(h.session.confirmations.toSet(), {
            demo ? BigInt.one : BigInt.from(6),
          });
          // Rows count with what the balance counted (6 here, as the fake LEPIC reports),
          // so a row never says Received under coins the balance still has as confirming.
          expect(find.textContaining(l.txStatusConfirming(1, 6)), findsWidgets);
          expect(find.textContaining(l.txStatusReceived), findsNothing);
        },
      );
    }
  });

  group('hidden in demo mode', () {
    for (final demo in [true, false]) {
      final present = demo ? findsNothing : findsWidgets;
      final mode = demo ? 'absent with demo mode' : 'present without it';

      testWidgets('first run: restore, network settings, biometrics ($mode)', (
        tester,
      ) async {
        final h = _Harness(demo: demo, status: const DemoNone(), wallet: false);
        await h.pump(tester);
        if (demo) {
          await tester.tap(find.text(l.demoStart));
          await _untilDemoPinFill(tester);
        }
        expect(find.byType(FirstRunScreen), findsOneWidget);
        expect(find.text(l.firstRunRestore), present);
        expect(find.byType(NetworkSettingsButton), present);
        if (demo) {
          // The demo PIN goes straight on to the wallet, with no biometrics question.
          await tester.pumpAndSettle();
          expect(h.container.read(sessionProvider), isNotNull);
        } else {
          await h.choosePin(tester);
        }
        expect(find.text(l.pinBiometricsQuestion), present);
      });

      testWidgets('unlock: network settings ($mode)', (tester) async {
        final h = _Harness(demo: demo);
        await h.pump(tester);
        expect(find.widgetWithText(TextField, l.pinLabel), findsOneWidget);
        expect(find.byType(NetworkSettingsButton), present);
      });

      testWidgets(
        'unlock: Forgot PIN ${demo ? 'ends the demo' : 'resets the wallet'}',
        (tester) async {
          final h = _Harness(demo: demo);
          await h.pump(tester);
          await _tap(tester, find.text(l.pinForgot));
          expect(find.text(l.pinResetTitle), present);
          expect(
            find.text(l.demoEndTitle),
            demo ? findsOneWidget : findsNothing,
          );
          if (!demo) return;
          await _tap(
            tester,
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text(l.demoEnd),
            ),
          );
          expect(h.api.ends, 1);
          expect(h.store.values['wallet.floonet.pinSealed'], isNull);
          expect(find.text(l.demoWelcomeTitle), findsOneWidget);
        },
      );

      testWidgets('home: phrase card, QR scan, updates ($mode)', (
        tester,
      ) async {
        final h = _Harness(demo: demo, backedUp: false);
        await h.pump(tester);
        await h.unlock(tester);
        expect(find.text(l.homeBackupCardText), present);
        expect(find.byTooltip(l.homeScanTooltip), present);
        expect(h.updateChecks, demo ? isEmpty : isNotEmpty);
      });

      testWidgets('home: history backup reminder ($mode)', (tester) async {
        final h = _Harness(demo: demo);
        // The reminder waits for 10 older payments and 30 days.
        final chain = demo ? Chain.floonet : Chain.mainnet;
        int secondsAgo(Duration d) =>
            h.now.subtract(d).millisecondsSinceEpoch ~/ 1000;
        h.store.values['app.history_reminder_first_seen.${chain.name}'] =
            '${secondsAgo(const Duration(days: 40))}';
        for (var i = 0; i < 10; i++) {
          h.session.transactionsValue.add(
            fakeTx(
              id: i + 1,
              createdAtUnix: secondsAgo(const Duration(days: 5)),
              amountCredited: BigInt.from(100000000),
            ),
          );
        }
        await h.pump(tester);
        await h.unlock(tester);
        expect(find.text(l.homeHistoryExportButton), present);
      });

      testWidgets('Send and contacts: QR scan ($mode)', (tester) async {
        final h = _Harness(demo: demo);
        // Coins to send, or Send shows its empty state instead of the form.
        h.session.summaryValue = WalletSummary(
          lastConfirmedHeight: BigInt.from(100),
          minimumConfirmations: BigInt.from(3),
          total: BigInt.from(1000000000),
          spendable: BigInt.from(1000000000),
          awaitingConfirmation: BigInt.zero,
          awaitingFinalization: BigInt.zero,
          immature: BigInt.zero,
          locked: BigInt.zero,
          validatedWithNode: true,
        );
        await h.pump(tester);
        await h.unlock(tester);
        await h.tab(tester, l.homeSendButton);
        expect(find.text(l.sendScanButton), present);
        await h.open(tester, const ContactsScreen());
        await _tap(tester, find.byTooltip(l.contactsAdd));
        expect(find.byTooltip(l.scanQrTooltip), present);
      });

      testWidgets('Receive: share ($mode)', (tester) async {
        final h = _Harness(demo: demo);
        await h.pump(tester);
        await h.unlock(tester);
        await h.tab(tester, l.homeReceiveButton);
        expect(find.byKey(receiveShareKey), present);
      });

      testWidgets('Settings ($mode)', (tester) async {
        final h = _Harness(demo: demo, advanced: true);
        await h.pump(tester, height: 4000);
        await h.unlock(tester);
        await h.open(tester, const SettingsScreen());
        // The hub has no Notifications row any more (it is on Advanced, and the demo has none).
        expect(find.byKey(settingsPushKey), findsNothing);
        // What the demo hides, page by page. Send feedback lives in Help.
        final pages = {
          SettingsSection.security: [
            l.settingsBiometrics,
            l.settingsBackupPhrase,
            // The demo wallet keeps the demo PIN, which unlock fills in.
            l.settingsChangePin,
          ],
          SettingsSection.wallet: [
            l.settingsRescan,
            l.settingsExportHistory,
            l.settingsExportCsv,
            l.settingsImportHistory,
            l.settingsDeleteWallet,
          ],
          SettingsSection.about: [l.settingsCheckUpdates],
        };
        for (final MapEntry(key: section, value: texts) in pages.entries) {
          await tester.tap(find.byKey(settingsGroupKey(section)));
          await tester.pumpAndSettle();
          for (final text in texts) {
            expect(find.text(text), present, reason: '$section $text');
          }
          if (section == SettingsSection.wallet) {
            expect(find.text(l.demoEnd), demo ? findsOneWidget : findsNothing);
            // What stays.
            expect(find.text(l.settingsContacts), findsOneWidget);
          }
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
        // What stays: display.
        await tester.tap(find.byKey(settingsGroupKey(SettingsSection.display)));
        await tester.pumpAndSettle();
        for (final text in [
          l.settingsTheme,
          l.languageSetting,
          l.settingsCurrency,
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
      });

      testWidgets('Help: feedback ($mode)', (tester) async {
        final h = _Harness(demo: demo);
        await h.pump(tester, height: 3000);
        await h.unlock(tester);
        await h.open(tester, const HelpScreen());
        expect(find.text(l.helpSendFeedback), present);
      });
    }
  });

  group('no PIN in the web demo and preview', () {
    Finder pinField() => find.widgetWithText(TextField, l.pinLabel);
    Finder unlockButton() => find.widgetWithText(FilledButton, l.pinlessUnlock);

    testWidgets('a phone or desktop build asks for the PIN: only a web build goes without', (
      tester,
    ) async {
      // These tests run outside the web, as phone and desktop builds do.
      expect(pinlessBuild, isFalse);
      final h = _Harness(demo: false, pin: demoPin, demoPinFlag: true);
      await h.pump(tester);
      expect(h.container.read(pinlessProvider), isFalse);
      expect(pinField(), findsOneWidget);
      expect(unlockButton(), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(h.container.read(sessionProvider), isNull);
      await tester.enterText(pinField(), demoPin);
      await tester.pumpAndSettle();
      expect(h.container.read(sessionProvider), isNotNull);
    });

    testWidgets('a phone or desktop build sets up a new wallet with a chosen PIN', (
      tester,
    ) async {
      final h = _Harness(demo: false, wallet: false);
      await h.pump(tester);
      expect(find.byKey(firstRunCreateKey), findsOneWidget);
      expect(h.container.read(sessionProvider), isNull);
      await h.choosePin(tester);
      expect(find.text(l.pinBiometricsQuestion), findsOneWidget);
      expect(h.container.read(sessionProvider), isNull);
    });

    testWidgets('preview, first start: straight into the wallet, no PIN set up', (
      tester,
    ) async {
      final h = _Harness(demo: false, wallet: false, pinless: true);
      await h.pump(tester);
      expect(pinField(), findsNothing);
      expect(h.container.read(sessionProvider), isNotNull);
      expect(h.service.createdPin, demoPin);
      expect(h.store.values['wallet.mainnet.demoPin'], '1');
      expect(find.text(l.shellWalletTab), findsOneWidget);
    });

    testWidgets('preview, later starts: straight into the wallet; Lock works and one tap '
        'unlocks', (tester) async {
      final h = _Harness(demo: false, pin: demoPin, demoPinFlag: true, pinless: true);
      await h.pump(tester);
      expect(pinField(), findsNothing);
      expect(h.container.read(sessionProvider), isNotNull);
      expect(find.text(l.shellWalletTab), findsOneWidget);

      // Lock wallet, as Settings does it (lockWallet).
      h.container.read(lockReasonProvider.notifier).set(LockReason.manual);
      h.container.read(sessionProvider.notifier).lock();
      unawaited(
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
              (_) => false,
            ),
      );
      await tester.pumpAndSettle();
      expect(h.container.read(sessionProvider), isNull);
      expect(unlockButton(), findsOneWidget);
      expect(pinField(), findsNothing);
      expect(find.text(l.pinForgot), findsNothing);
      await _tap(tester, unlockButton());
      expect(h.container.read(sessionProvider), isNotNull);
      expect(find.text(l.shellWalletTab), findsOneWidget);
    });

    testWidgets('demo: opens on start with no PIN dots', (tester) async {
      final h = _Harness(pin: demoPin, demoPinFlag: true, pinless: true);
      await h.pump(tester);
      expect(find.byType(DemoPinFill), findsNothing);
      expect(pinField(), findsNothing);
      expect(h.container.read(sessionProvider), isNotNull);
    });

    testWidgets('a preview wallet sealed under another PIN still asks for it', (tester) async {
      final h = _Harness(demo: false, pinless: true);
      await h.pump(tester);
      expect(pinField(), findsOneWidget);
      expect(h.container.read(sessionProvider), isNull);
      await h.unlock(tester);
    });
  });

  group('demo PIN', () {
    Finder pinField() => find.widgetWithText(TextField, l.pinLabel);

    testWidgets('first run creates the wallet with no typing and notes it', (
      tester,
    ) async {
      final h = _Harness(status: const DemoNone(), wallet: false);
      await h.pump(tester);
      await tester.tap(find.text(l.demoStart));
      await _untilDemoPinFill(tester);
      expect(pinField(), findsNothing);
      expect(find.text(l.demoPinSetUpTitle), findsOneWidget);
      expect(find.text(l.demoPinFilled), findsOneWidget);
      await tester.pumpAndSettle();
      expect(h.container.read(sessionProvider), isNotNull);
      expect(h.service.createdPin, demoPin);
      expect(h.store.values['wallet.floonet.demoPin'], '1');
      expect(find.text(l.shellWalletTab), findsOneWidget);
    });

    testWidgets('unlock opens the wallet with no typing', (tester) async {
      final h = _Harness(pin: demoPin, demoPinFlag: true);
      await h.pump(tester, settle: false);
      await _untilDemoPinFill(tester);
      // The field never shows while the dots fill, nor Forgot PIN, nor the network title.
      expect(pinField(), findsNothing);
      expect(find.text(l.pinForgot), findsNothing);
      expect(find.text(l.demoPinUnlockTitle), findsOneWidget);
      expect(h.container.read(sessionProvider), isNull);
      await tester.pumpAndSettle();
      expect(h.container.read(sessionProvider), isNotNull);
      expect(find.text(l.shellWalletTab), findsOneWidget);
    });

    testWidgets('a failed lookup says so and offers Try again', (tester) async {
      final h = _Harness(pin: demoPin, demoPinFlag: true);
      h.service.lookupErrors = 1;
      await h.pump(tester);
      expect(find.byType(ErrorText), findsOneWidget);
      expect(pinField(), findsNothing);
      expect(h.container.read(sessionProvider), isNull);
      await _tap(tester, find.widgetWithText(FilledButton, l.launchTryAgain));
      expect(find.byType(ErrorText), findsNothing);
      expect(h.container.read(sessionProvider), isNotNull);
    });

    testWidgets('without demo mode the same store still asks for the PIN', (
      tester,
    ) async {
      final h = _Harness(demo: false, pin: demoPin, demoPinFlag: true);
      await h.pump(tester);
      expect(find.byType(DemoPinFill), findsNothing);
      expect(pinField(), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(h.container.read(sessionProvider), isNull);
      await tester.enterText(pinField(), demoPin);
      await tester.pumpAndSettle();
      expect(h.container.read(sessionProvider), isNotNull);
    });

    testWidgets('a demo without the note asks for the PIN', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.byType(DemoPinFill), findsNothing);
      expect(pinField(), findsOneWidget);
      // The manual field keeps the usual title, without the network: the header's Test coins
      // pill names it in the demo. Forgot PIN stays.
      expect(find.text(l.unlockTitle), findsOneWidget);
      expect(
        find.text('${l.unlockTitle}${networkSuffix(l, Chain.floonet)}'),
        findsNothing,
      );
      expect(find.text(l.demoPinUnlockTitle), findsNothing);
      expect(find.text(l.pinForgot), findsOneWidget);
      expect(h.container.read(sessionProvider), isNull);
      await h.unlock(tester);
    });

    testWidgets('after a wrong PIN the field shows', (tester) async {
      final h = _Harness(pin: demoPin, demoPinFlag: true);
      h.service.pinFailureCount = 1;
      await h.pump(tester);
      expect(find.byType(DemoPinFill), findsNothing);
      expect(pinField(), findsOneWidget);
      expect(h.container.read(sessionProvider), isNull);
    });

    testWidgets('a rejected demo PIN falls back to the field', (tester) async {
      // The note is there, but the wallet was sealed under another PIN.
      final h = _Harness(demoPinFlag: true);
      await h.pump(tester);
      expect(find.byType(DemoPinFill), findsNothing);
      expect(pinField(), findsOneWidget);
      expect(h.container.read(sessionProvider), isNull);
      await h.unlock(tester);
    });

    testWidgets('a lost connection offers Try again', (tester) async {
      final h = _Harness(pin: demoPin, demoPinFlag: true);
      h.service.openErrors = 1;
      await h.pump(tester);
      expect(h.container.read(sessionProvider), isNull);
      expect(find.byType(ErrorText), findsOneWidget);
      expect(pinField(), findsNothing);
      await _tap(tester, find.widgetWithText(FilledButton, l.launchTryAgain));
      expect(h.container.read(sessionProvider), isNotNull);
    });

    for (final demo in [true, false]) {
      testWidgets(
        'the PIN prompt ${demo ? 'fills in the demo PIN' : 'asks for the PIN'}',
        (tester) async {
          final pin = demo ? demoPin : _pin;
          final h = _Harness(demo: demo, pin: pin, demoPinFlag: true);
          await h.pump(tester);
          if (!demo) await h.unlock(tester);
          expect(h.container.read(sessionProvider), isNotNull);
          String? got;
          unawaited(
            askPin<String>(
              tester.element(find.byType(Scaffold).first),
              action: (pin) async => pin,
            ).then((value) => got = value),
          );
          await tester.pump();
          await tester.pump();
          if (demo) {
            expect(find.byType(DemoPinFill), findsOneWidget);
            expect(pinField(), findsNothing);
            await tester.pumpAndSettle();
            expect(got, demoPin);
          } else {
            expect(find.byType(DemoPinFill), findsNothing);
            expect(pinField(), findsOneWidget);
            await tester.pump(const Duration(seconds: 3));
            expect(got, isNull);
            await tester.enterText(pinField(), _pin);
            await tester.pumpAndSettle();
            expect(got, _pin);
          }
          expect(find.byType(AlertDialog), findsNothing);
        },
      );
    }

    testWidgets(
      'the PIN prompt keeps the dots and offers Try again on an error',
      (tester) async {
        final h = _Harness(pin: demoPin, demoPinFlag: true);
        await h.pump(tester);
        var calls = 0;
        String? got;
        unawaited(
          askPin<String>(
            tester.element(find.byType(Scaffold).first),
            action: (pin) async {
              if (calls++ == 0) {
                throw const WalletError(
                  kind: WalletErrorKind.nodeUnreachable,
                  message: 'connection lost',
                );
              }
              return pin;
            },
          ).then((value) => got = value),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byType(DemoPinFill), findsOneWidget);
        expect(find.byType(ErrorText), findsOneWidget);
        expect(pinField(), findsNothing);
        await _tap(tester, find.widgetWithText(FilledButton, l.launchTryAgain));
        expect(calls, 2);
        expect(got, demoPin);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'the PIN prompt falls back to the field when the PIN is refused',
      (tester) async {
        final h = _Harness(pin: demoPin, demoPinFlag: true);
        await h.pump(tester);
        unawaited(
          askPin<String>(
            tester.element(find.byType(Scaffold).first),
            action: (pin) async => throw const PinRejected(1),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byType(DemoPinFill), findsNothing);
        expect(pinField(), findsOneWidget);
        expect(find.text(l.launchTryAgain), findsNothing);
      },
    );

    testWidgets('the PIN prompt asks for the PIN after a wrong one', (
      tester,
    ) async {
      final h = _Harness(pin: demoPin, demoPinFlag: true);
      await h.pump(tester);
      expect(h.container.read(sessionProvider), isNotNull);
      h.service.pinFailureCount = 1;
      String? got;
      unawaited(
        askPin<String>(
          tester.element(find.byType(Scaffold).first),
          action: (pin) async => pin,
        ).then((value) => got = value),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DemoPinFill), findsNothing);
      expect(pinField(), findsOneWidget);
      expect(got, isNull);
    });

    Future<List<int>> pumpFill(WidgetTester tester, {bool reduced = false}) {
      final done = <int>[];
      return tester
          .pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: reduced),
                  child: Scaffold(body: DemoPinFill(onDone: () => done.add(1))),
                ),
              ),
            ),
          )
          .then((_) => done);
    }

    testWidgets('fills in about a second and finishes once', (tester) async {
      final done = await pumpFill(tester);
      await tester.pump(const Duration(milliseconds: 900));
      expect(done, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      expect(done, hasLength(1));
      await tester.pumpAndSettle();
      expect(done, hasLength(1));
    });

    testWidgets('Skip finishes at once, and only once', (tester) async {
      final done = await pumpFill(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text(l.demoPinSkip));
      await tester.pump();
      // 100 ms in, far before the animation's end.
      expect(done, hasLength(1));
      // Skip fades out over 150 ms, keeps its space, and can no longer be reached.
      final skip = find.ancestor(
        of: find.text(l.demoPinSkip),
        matching: find.byType(AnimatedOpacity),
      );
      final box = tester.getRect(find.text(l.demoPinSkip));
      expect(tester.widget<AnimatedOpacity>(skip).opacity, 0);
      expect(
        tester.widget<AnimatedOpacity>(skip).duration,
        const Duration(milliseconds: 150),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getRect(find.text(l.demoPinSkip)), box);
      expect(
        tester
            .widget<ExcludeFocus>(
              find
                  .ancestor(
                    of: find.text(l.demoPinSkip),
                    matching: find.byType(ExcludeFocus),
                  )
                  .first,
            )
            .excluding,
        isTrue,
      );
      expect(
        tester
            .widget<IgnorePointer>(
              find
                  .ancestor(
                    of: find.text(l.demoPinSkip),
                    matching: find.byType(IgnorePointer),
                  )
                  .first,
            )
            .ignoring,
        isTrue,
      );
      await tester.pump(const Duration(seconds: 2));
      // A tap on the dots after the end does nothing more.
      await tester.tap(find.text(l.demoPinFilled));
      await tester.pump();
      expect(done, hasLength(1));
    });

    testWidgets('a tap on the dots skips too', (tester) async {
      final done = await pumpFill(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text(l.demoPinFilled));
      await tester.pump();
      expect(done, hasLength(1));
    });

    testWidgets('reduced motion finishes after the first frame', (
      tester,
    ) async {
      final done = await pumpFill(tester, reduced: true);
      expect(done, hasLength(1));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      // Skip goes at once, with no fade.
      final skip = find.ancestor(
        of: find.text(l.demoPinSkip),
        matching: find.byType(AnimatedOpacity),
      );
      expect(tester.widget<AnimatedOpacity>(skip).opacity, 0);
      expect(tester.widget<AnimatedOpacity>(skip).duration, Duration.zero);
    });

    testWidgets('announces itself and keeps Skip reachable', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpFill(tester);
      expect(find.bySemanticsLabel(l.demoPinFilled), findsOneWidget);
      final node = tester.getSemantics(find.bySemanticsLabel(l.demoPinFilled));
      expect(node.flagsCollection.isLiveRegion, isTrue);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tester.pumpAndSettle();
      semantics.dispose();
    });
  });

  group('no other app', () {
    // The demo is the app itself: no phone app, store, install or download anywhere.
    final mention = RegExp(
      r'\b(apps?|store|install\w*|download\w*|apk)\b',
      caseSensitive: false,
    );

    /// Every word the screen shows: texts, rich texts and tooltips.
    List<String> words(WidgetTester tester) => [
      for (final e in find.byType(RichText, skipOffstage: false).evaluate())
        (e.widget as RichText).text.toPlainText(),
      for (final e in find.byType(Tooltip, skipOffstage: false).evaluate())
        (e.widget as Tooltip).message ?? '',
    ];

    void expectNoMention(WidgetTester tester, String screen) {
      for (final text in words(tester)) {
        expect(mention.hasMatch(text), isFalse, reason: '$screen: "$text"');
      }
    }

    test('the English demo strings', () {
      final arb = jsonDecode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      final demo = arb.entries.where(
        (e) => e.key.startsWith('demo') && e.value is String,
      );
      expect(demo, isNotEmpty);
      for (final MapEntry(:key, :value) in demo) {
        expect(mention.hasMatch(value as String), isFalse, reason: key);
      }
    });

    test('the landing page and its card', () {
      for (final path in [
        '../demo/site/public/index.html',
        '../demo/site/card.html',
      ]) {
        final page = File(path).readAsStringSync();
        // The words people read, not the markup's own names (stylesheets, icons).
        final text = page
            .replaceAll(RegExp(r'<(style|script)[^>]*>[\s\S]*?</\1>'), ' ')
            .replaceAll(RegExp(r'<[^>]*>'), ' ');
        expect(mention.hasMatch(text), isFalse, reason: path);
        expect(page, isNot(contains('data-download')), reason: path);
        final meta = RegExp(r'content="([^"]*)"')
            .allMatches(page)
            .map((m) => m.group(1)!);
        for (final value in meta) {
          expect(mention.hasMatch(value), isFalse, reason: '$path: $value');
        }
      }
    });

    testWidgets('welcome and ended', (tester) async {
      for (final status in [const DemoNone(), const DemoEnded()]) {
        final h = _Harness(status: status, wallet: false);
        await h.pump(tester);
        expectNoMention(tester, '$status');
      }
    });

    testWidgets('the demo PIN, Wallet with its guide, Receive, Settings', (
      tester,
    ) async {
      final h = _Harness(status: const DemoNone(), wallet: false);
      await h.pump(tester, height: 4000);
      await tester.tap(find.text(l.demoStart));
      await _untilDemoPinFill(tester);
      expectNoMention(tester, 'demo PIN');
      await tester.pumpAndSettle();
      expect(find.text(l.demoGuideTitle), findsOneWidget);
      expectNoMention(tester, 'Wallet');
      await h.tab(tester, l.homeReceiveButton);
      expect(find.text(l.demoReceiveKeepOpen), findsOneWidget);
      expectNoMention(tester, 'Receive');
      await h.open(tester, const SettingsScreen());
      expectNoMention(tester, 'Settings');
    });
  });

  group('accessibility', () {
    for (final (name, status) in <(String, DemoStatus)>[
      ('welcome', const DemoNone()),
      ('ended', const DemoEnded()),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$name at text scale $scale', (tester) async {
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          final h = _Harness(status: status, wallet: false);
          final semantics = tester.ensureSemantics();
          await h.pump(tester);
          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantics.dispose();
        });
      }
    }
  });
}

class _ThrowingApi extends FakeDemoApi {
  @override
  Future<TestCoinsResult> claimTestCoins(String address) async =>
      throw StateError('offline');
}
