// W-04: the web demo in the UI. Every check that hides something runs with demo mode on and
// off, so the phone app is shown to keep it.

import 'dart:async';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/demo_screens.dart';
import 'package:epic_wallet/src/ui/first_run_screen.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
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

final AppLocalizations l = englishStrings;

class _Push implements PushPlatform {
  @override
  Future<bool> configured() async => true;

  @override
  Future<bool> start() async => true;

  @override
  Future<String?> token() async => 'token';

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

/// The app with demo mode [demo], on floonet with it and on mainnet without.
class _Harness {
  _Harness({
    this.demo = true,
    DemoStatus? status,
    bool wallet = true,
    bool backedUp = true,
    bool advanced = false,
    Uri? download,
  }) {
    api = FakeDemoApi(
      status: status ?? DemoActive(now.add(const Duration(hours: 5))),
      downloadUrl: download,
      clock: () => now,
    );
    final chain = demo ? Chain.floonet : Chain.mainnet;
    if (advanced) store.values['app.advanced'] = 'true';
    if (wallet) {
      store.values['wallet.${chain.name}.pinSealed'] = fakeSealedPassword(_pin);
      if (backedUp) store.values['wallet.${chain.name}.backedUp'] = '1';
    }
    service = FakeWalletService(
      existingWallets: wallet ? {'/fake/wallets/${chain.name}'} : {},
      session: session,
    );
  }

  final bool demo;
  late final FakeDemoApi api;
  final store = MemorySecretStore();
  final bio = MemoryBiometricStore();
  final session = _Session();
  final updateChecks = <int>[];
  late final FakeWalletService service;
  DateTime now = DateTime(2026, 10, 6, 12);
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester, {double height = 780}) async {
    tester.view.physicalSize = Size(412 * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          demoModeProvider.overrideWithValue(demo),
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
    await tester.pumpAndSettle();
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

/// The visible notice's text, or null.
String? _notice(_Harness h) => h.container.read(noticeProvider)?.text;

void main() {
  group('welcome', () {
    testWidgets('shows what the demo is, then Start leads to the first run', (
      tester,
    ) async {
      final h = _Harness(status: const DemoNone(), wallet: false);
      await h.pump(tester);
      for (final text in [
        l.demoWelcomeTitle,
        l.demoWelcomeLine,
        l.demoWelcomeNoValue,
        l.demoWelcomeNothingToInstall,
        l.demoWelcomeDeleted,
      ]) {
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

      await _tap(tester, find.text(l.demoStart));
      expect(h.api.starts, 1);
      expect(find.byType(FirstRunScreen), findsOneWidget);
      expect(find.text(l.pinChooseTitle(6)), findsOneWidget);
      // The first run is on floonet.
      expect(
        find.text('${l.firstRunTitle}${networkSuffix(l, Chain.floonet)}'),
        findsOneWidget,
      );
      await h.choosePin(tester);
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

    for (final withUrl in [true, false]) {
      testWidgets(
        'Get the app ${withUrl ? 'opens the download page' : 'hides without a URL'}',
        (tester) async {
          final url = Uri.parse('https://example.org/app');
          final h = _Harness(
            status: const DemoNone(),
            wallet: false,
            download: withUrl ? url : null,
          );
          await h.pump(tester);
          expect(find.text(l.demoWelcomeTitle), findsOneWidget);
          if (!withUrl) {
            expect(find.text(l.demoGetApp), findsNothing);
            return;
          }
          await _tap(tester, find.text(l.demoGetApp));
          expect(h.api.opened, [url]);
        },
      );
    }
  });

  group('ended', () {
    testWidgets('from status(), with Start again', (tester) async {
      final url = Uri.parse('https://example.org/app');
      final h = _Harness(
        status: const DemoEnded(),
        wallet: false,
        download: url,
      );
      await h.pump(tester);
      expect(find.text(l.demoEndedTitle), findsOneWidget);
      expect(find.text(l.demoEndedBody), findsOneWidget);
      expect(find.text(l.demoGetApp), findsOneWidget);
      await _tap(tester, find.text(l.demoStartAgain));
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

    testWidgets('beside Floonet, with the exact time in its tooltip', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      expect(find.text(chainName(l, Chain.floonet)), findsOneWidget);
      expect(find.text(l.demoEndsInHours(5)), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byKey(demoCountdownKey));
      expect(
        tooltip.message,
        l.demoEndsAt(formatDateTime(l, h.now.add(const Duration(hours: 5)))),
      );
      expect(_notice(h), isNull);

      // Under an hour it counts minutes.
      h.now = h.now.add(const Duration(hours: 4, minutes: 20));
      await tester.pump(const Duration(seconds: 15));
      expect(find.text(l.demoEndsInMinutes(40)), findsOneWidget);
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
      expect(find.text(l.demoEndsInMinutes(25)), findsOneWidget);
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
        // The empty Wallet tab offers it.
        expect(find.text(l.homeNoPayments), findsOneWidget);
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
      await h.open(tester, const SettingsScreen());
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
      expect(phone.read(minimumConfirmationsProvider), BigInt.from(10));
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
          expect(h.session.confirmations.toSet(), {
            demo ? BigInt.one : BigInt.from(10),
          });
          expect(
            find.text(l.txStatusConfirming(1, 10)),
            demo ? findsNothing : findsWidgets,
          );
          expect(
            find.text(l.txStatusCompleted),
            demo ? findsWidgets : findsNothing,
          );
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
        if (demo) await _tap(tester, find.text(l.demoStart));
        expect(find.byType(FirstRunScreen), findsOneWidget);
        expect(find.text(l.firstRunRestore), present);
        expect(find.byType(NetworkSettingsButton), present);
        await h.choosePin(tester);
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
        h.session.transactionsValue.add(
          fakeTx(id: 1, amountCredited: BigInt.from(100000000)),
        );
        await h.pump(tester);
        await h.unlock(tester);
        expect(find.text(l.homeHistoryExportButton), present);
      });

      testWidgets('Send and contacts: QR scan ($mode)', (tester) async {
        final h = _Harness(demo: demo);
        await h.pump(tester);
        await h.unlock(tester);
        await h.tab(tester, l.homeSendButton);
        expect(find.text(l.sendScanButton), present);
        await h.open(tester, const ContactsScreen());
        await _tap(tester, find.byType(FloatingActionButton));
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
        for (final text in [
          l.settingsNetworkAndNode,
          l.settingsRescan,
          l.settingsBiometrics,
          l.settingsPaymentNotifications,
          l.settingsCheckUpdates,
          l.settingsBackupPhrase,
          l.settingsExportHistory,
          l.settingsExportCsv,
          l.settingsImportHistory,
          l.settingsSendFeedback,
          l.settingsDeleteWallet,
        ]) {
          expect(find.text(text), present, reason: text);
        }
        // What stays: display, PIN change, contacts, help, and the other way out.
        for (final text in [
          l.settingsTheme,
          l.languageSetting,
          l.settingsCurrency,
          l.settingsChangePin,
          l.settingsContacts,
          l.settingsHelp,
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
        expect(find.text(l.demoEnd), demo ? findsOneWidget : findsNothing);
      });

      testWidgets('Help: feedback ($mode)', (tester) async {
        final h = _Harness(demo: demo);
        await h.pump(tester, height: 3000);
        await h.unlock(tester);
        await h.open(tester, const HelpScreen());
        expect(find.text(l.helpSendFeedback), present);
      });
    }

    for (final withUrl in [true, false]) {
      testWidgets(
        'About: Get the app ${withUrl ? 'with' : 'hidden without'} a URL',
        (tester) async {
          final url = Uri.parse('https://example.org/app');
          final h = _Harness(download: withUrl ? url : null);
          await h.pump(tester, height: 4000);
          await h.unlock(tester);
          await h.open(tester, const SettingsScreen());
          expect(find.text(l.settingsHelp), findsOneWidget);
          if (!withUrl) {
            expect(find.text(l.demoGetApp), findsNothing);
            return;
          }
          await _tap(tester, find.text(l.demoGetApp));
          expect(h.api.opened, [url]);
        },
      );
    }
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
          final h = _Harness(
            status: status,
            wallet: false,
            download: Uri.parse('https://example.org/app'),
          );
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
