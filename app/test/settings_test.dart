// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:io' show File;

import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/tor_licence.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/language_flag.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/first_run_screen.dart';
import 'package:epic_wallet/src/ui/restore_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/server_list_sheet.dart'
    show
        ServerListSheet,
        serverListAddKey,
        serverListFieldKey,
        serverListFootKey,
        serverListSwitchKey;
import 'package:epic_wallet/src/ui/pairing/pair_check.dart' show confirmRemovePairingKey;
import 'package:epic_wallet/src/ui/settings_invoices.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/history/backup_summary.dart';
import 'package:epic_wallet/src/ui/settings_pin.dart';
import 'package:epic_wallet/src/ui/licences_screen.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/tor_ui.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/experimental.dart';
import 'support/test_settings.dart' show useNetworkModeFile;

const _mainnetDir = '/fake/wallets/mainnet';
const _pin = '123456';

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

class _FixedPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

/// A fake whose scan runs until the test ends it, and which records the start height.
class _ScanSession extends FakeWalletSession {
  StreamController<ScanProgress>? controller;
  BigInt? lastStart;

  /// Every [scan] call, scripted or not.
  int scans = 0;

  @override
  Stream<ScanProgress> scan({BigInt? startHeight, bool deleteUnconfirmed = false}) {
    lastStart = startHeight;
    scans++;
    final c = controller;
    return c == null ? super.scan(startHeight: startHeight) : c.stream;
  }

  /// The core ends a stopped scan's stream.
  @override
  void cancelScan() {
    super.cancelScan();
    unawaited(controller?.close());
  }
}

/// What the update check finds, and how often the app asked. With [offer], every opening
/// finds it, through the phases the real check passes.
class _UpdateScript {
  /// Null: the real rule ([UpdateNotifier.supported]: this build has an updater and a platform).
  bool? supported = false;
  AvailableUpdate? offer;
  int checks = 0;
  int installs = 0;
}

class _ScriptedUpdates extends UpdateNotifier {
  _ScriptedUpdates(this.script);

  final _UpdateScript script;

  @override
  bool get supported => script.supported ?? super.supported;

  @override
  Future<void> checkOnOpening() async {
    script.checks++;
    final offer = script.offer;
    if (offer == null) return;
    state = UpdateState(UpdatePhase.checking, update: state.update);
    await Future<void>.delayed(Duration.zero);
    state = UpdateState(UpdatePhase.available, update: offer);
  }

  @override
  Future<void> install() async => script.installs++;

  void set(UpdateState value) => state = value;
}

final _update = AvailableUpdate(
  versionName: '1.6.1',
  notes: '',
  apk: ReleaseApk(
    abi: 'arm64-v8a',
    versionCode: 23,
    url: Uri.parse('https://example.org/app.apk'),
    sha256: '',
    size: 1,
  ),
);

class _Harness {
  _Harness({
    bool sealed = true,
    bool walletExists = true,
    bool advanced = false,
    bool scanSupported = false,
    bool experimental = false,
    this.tor = false,
  }) : scanner = FakeQrScanner(supported: scanSupported) {
    if (advanced) store.values['app.advanced'] = 'true';
    // Pairing and Invoices on (Experimental), with what the old Advanced switch showed.
    if (experimental) {
      store.values[phoneAdvancedPrefsKey] = advanced
          ? 'invoices,pairing,recheckFromHeight,serverDetails,technicalDetails|standard'
          : phoneExperimentalOn;
    }
    if (sealed) {
      store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_pin);
    }
    service = FakeWalletService(
      existingWallets: walletExists ? {_mainnetDir} : {},
      session: session,
    );
  }

  final store = MemorySecretStore();

  /// The phone's installer side; null as off Android.
  UpdatePlatform? updatePlatform;
  final bio = MemoryBiometricStore(available: false);
  final files = FakeHistoryFiles();
  final session = _ScanSession();
  final FakeQrScanner scanner;

  /// A bundled tor on this device, so the Tor switch is offered.
  final bool tor;
  final updates = _UpdateScript();
  int cleanups = 0;
  late final FakeWalletService service;
  DateTime now = DateTime(2026, 9, 30, 12);
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          walletDirProvider.overrideWithValue(
            (chain) async => '/fake/wallets/${chain.name}',
          ),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(bio),
          updatePlatformProvider.overrideWithValue(updatePlatform),
          updateProvider.overrideWith(() => _ScriptedUpdates(updates)),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          historyFilesProvider.overrideWithValue(files),
          priceSourceProvider.overrideWithValue(_FixedPrice()),
          clockProvider.overrideWithValue(() => now),
          qrScannerProvider.overrideWithValue(scanner),
          sharedFilesCleanupProvider.overrideWithValue(() async => cleanups++),
          if (tor)
            torBundleFinderProvider.overrideWithValue(
              () async => const TorBundle(binary: '/data/app/lib/arm64/libtor.so'),
            ),
        ],
        child: const WalletApp(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    // Home screens may keep refresh timers; unmounting cancels them.
    addTearDown(() => tester.pumpWidget(const SizedBox()));
  }

  Future<void> unlock(WidgetTester tester) async {
    expect(find.text('Unlock wallet'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'PIN'), _pin);
    await tester.pumpAndSettle();
    expect(container.read(sessionProvider), isNotNull);
  }

  /// [openSettings] for screens with endless animations, such as a running scan.
  Future<void> openSettingsNow(
    WidgetTester tester, [
    SettingsSection? section,
  ]) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => SettingsScreen(section: section),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The Settings hub, or with [section] that page over it.
  Future<void> openSettings(
    WidgetTester tester, [
    SettingsSection? section,
  ]) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => SettingsScreen(section: section),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _reveal(tester, field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

Future<void> _states(
  WidgetTester tester,
  List<AppLifecycleState> states, {
  required bool settle,
}) async {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
  // A running scan animates forever, so its tests only pump.
  if (settle) await tester.pumpAndSettle();
}

/// Resumed to paused, the way a phone goes through the states.
Future<void> _leave(WidgetTester tester, {bool settle = true}) =>
    _states(tester, const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ], settle: settle);

/// Paused back to resumed.
Future<void> _return(WidgetTester tester, {bool settle = true}) =>
    _states(tester, const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ], settle: settle);

void main() {
  // An asset read inside an earlier test's fake clock never completes; the next test reads it again.
  setUp(() {
    rootBundle.evict(torSourceAsset);
    rootBundle.evict(torLicenceAsset);
  });

  group('AppSettings', () {
    test('defaults, and every setting persists in the store', () async {
      final store = MemorySecretStore();
      ProviderContainer make() => ProviderContainer(
        overrides: [secretStoreProvider.overrideWithValue(store)],
      );
      final first = make();
      final defaults = await first.read(appSettingsProvider.future);
      expect(defaults.themeMode, ThemeMode.system);
      expect(defaults.fiatCurrency, 'usd');
      expect(defaults.showFiat, isTrue);
      expect(defaults.hideBalances, isFalse);
      expect(defaults.autoLockMinutes, 15);

      final n = first.read(appSettingsProvider.notifier);
      await n.setThemeMode(ThemeMode.dark);
      await n.setFiatCurrency('EUR');
      await n.setShowFiat(false);
      await n.setHideBalances(true);
      await n.setAutoLockMinutes(null);
      first.dispose();

      final second = make();
      final saved = await second.read(appSettingsProvider.future);
      expect(saved.themeMode, ThemeMode.dark);
      expect(saved.fiatCurrency, 'eur');
      expect(saved.showFiat, isFalse);
      expect(saved.hideBalances, isTrue);
      expect(saved.autoLockMinutes, isNull);
      await second.read(appSettingsProvider.notifier).setAutoLockMinutes(0);
      second.dispose();

      // An old "immediately" reads as the shortest choice, a minute; more than an hour as 60.
      final third = make();
      expect((await third.read(appSettingsProvider.future)).autoLockMinutes, 1);
      await third.read(appSettingsProvider.notifier).setAutoLockMinutes(90);
      third.dispose();
      final fourth = make();
      expect((await fourth.read(appSettingsProvider.future)).autoLockMinutes, 60);
      fourth.dispose();
    });
  });

  group('restore by date', () {
    test('estimates a height before the real one', () {
      // get_header on node.lab.invalid: height 3,500,000 at 2026-04-21T08:33:26Z and
      // 1,000,000 at 2021-07-12T19:08:50Z.
      final h1 = mainnetHeightForDate(DateTime.utc(2026, 4, 21, 8, 33, 26));
      expect(h1 < BigInt.from(3500000), isTrue);
      expect(h1 > BigInt.from(3500000 - 30000), isTrue);
      final h2 = mainnetHeightForDate(DateTime.utc(2021, 7, 12, 19, 8, 50));
      expect(h2 < BigInt.from(1000000), isTrue);
      expect(mainnetHeightForDate(DateTime.utc(2019, 9, 1)), BigInt.one);
    });

    testWidgets('scans from the date, then offers a history import', (
      tester,
    ) async {
      final h = _Harness(sealed: false, walletExists: false);
      await h.pump(tester);
      await _tapText(tester, 'Restore from phrase');
      await _enter(tester, 'Recovery phrase', h.service.phrase);
      await _tapText(tester, 'Start from a date or height');
      await _tapText(tester, 'Pick the date you created the wallet');
      // The picker opens on today (the real clock); pick the 1st of this month.
      await tester.tap(find.text('1'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final today = DateTime.now();
      final dayStart = DateTime(today.year, today.month);
      expect(
        find.text('From ${localDay(englishStrings, dayStart)}'),
        findsOneWidget,
      );
      await _tapText(tester, 'Continue');
      await _enter(tester, 'PIN', _pin);
      await _enter(tester, 'Repeat PIN', _pin);

      expect(h.session.lastStart, mainnetHeightForDate(dayStart));
      expect(find.text('Your wallet is restored'), findsOneWidget);
      expect(
        find.textContaining('import the wallet data file you exported'),
        findsOneWidget,
      );

      h.files.picks.add(await h.session.exportHistory());
      await _tapText(tester, 'Import wallet data');
      expect(find.text(englishStrings.historyBackupImportedTitle), findsOneWidget);
      await _tapText(tester, 'Done');
      expect(find.byType(RestoreScreen), findsNothing);
    });
  });

  group('theme', () {
    testWidgets('applies the saved theme and follows changes', (tester) async {
      final h = _Harness();
      h.store.values['app.theme'] = 'dark';
      await h.pump(tester);
      MaterialApp app() => tester.widget(find.byType(MaterialApp));
      expect(app().themeMode, ThemeMode.dark);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.display);
      await _tapText(tester, 'Theme');
      await _tapText(tester, 'Light');
      expect(app().themeMode, ThemeMode.light);
      expect(h.store.values['app.theme'], 'light');
    });
  });

  group('language', () {
    testWidgets('follows the system until one is picked by its own name', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      MaterialApp app() => tester.widget(find.byType(MaterialApp));
      expect(app().locale, isNull);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.display);
      // The theme and the language both follow the system (GP-027).
      expect(find.text('System'), findsNWidgets(2));
      await _tapText(tester, 'Language');
      for (final language in appLanguages) {
        expect(find.text(language.name), findsOneWidget);
      }
      // A flag by each language's name; the system row has a globe instead.
      expect(find.byType(LanguageFlag), findsNWidgets(appLanguages.length));
      await _tapText(tester, 'Deutsch');
      expect(h.store.values['app.language'], 'de');
      expect(h.container.read(appSettingsProvider).value?.language, 'de');
      expect(app().locale, const Locale('de'));
    });
  });

  group('language on first run', () {
    // The language the app's screens speak after the first frame, with [system] as the phone's
    // languages and [saved] as the stored choice.
    Future<String> uiLanguage(
      WidgetTester tester,
      List<Locale> system, {
      String? saved,
    }) async {
      tester.platformDispatcher.localesTestValue = system;
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final h = _Harness();
      if (saved != null) h.store.values['app.language'] = saved;
      await h.pump(tester);
      return AppLocalizations.of(tester.element(find.byType(Navigator).first))
          .localeName;
    }

    testWidgets('a system language the app has is the language', (tester) async {
      expect(await uiLanguage(tester, [const Locale('de', 'DE')]), 'de');
    });

    testWidgets('the first of the system languages the app has wins', (
      tester,
    ) async {
      expect(
        await uiLanguage(tester, [const Locale('ja'), const Locale('th')]),
        'th',
      );
    });

    testWidgets('a system language the app lacks gives English', (tester) async {
      expect(await uiLanguage(tester, [const Locale('ja')]), 'en');
    });

    testWidgets('an explicit choice beats the system', (tester) async {
      expect(
        await uiLanguage(tester, [const Locale('de')], saved: 'pl'),
        'pl',
      );
    });
  });

  group('hub', () {
    testWidgets('shows the groups in order, and each opens its page', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      final order = [
        // The desktop's order (GP2-021); Security keeps its place first.
        settingsGroupKey(SettingsSection.security),
        settingsGroupKey(SettingsSection.transactions),
        settingsGroupKey(SettingsSection.privacyNetwork),
        settingsGroupKey(SettingsSection.display),
        settingsGroupKey(SettingsSection.wallet),
        settingsHelpKey,
        settingsGroupKey(SettingsSection.about),
      ];
      var last = -1.0;
      for (final key in order) {
        expect(find.byKey(key), findsOneWidget, reason: '$key');
        final top = tester.getTopLeft(find.byKey(key)).dy;
        expect(top, greaterThan(last), reason: '$key');
        last = top;
      }
      for (final section in SettingsSection.values) {
        // The hub has eight rows now: the last may be below the fold.
        await tester.ensureVisible(find.byKey(settingsGroupKey(section)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(settingsGroupKey(section)));
        await tester.pumpAndSettle();
        expect(find.byKey(settingsSectionKey(section)), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(settingsHelpKey));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);
    });

    testWidgets('Security starts with the backup and ends with Lock wallet; '
        'Wallet ends with Delete', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.security);
      final titles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((t) => (t.title as Text?)?.data)
          .whereType<String>()
          .toList();
      expect(titles.first, 'Back up recovery phrase');
      expect(titles.last, 'Lock wallet');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await h.openSettings(tester, SettingsSection.wallet);
      await _reveal(tester, find.text('Delete wallet'));
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect((tiles.last.title as Text).data, 'Delete wallet');
    });

    testWidgets('Privacy & network opens at once with the Tor switch under '
        'the Privacy header', (tester) async {
      final h = _Harness(tor: true);
      await h.pump(tester);
      await h.unlock(tester);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const SettingsScreen(privacy: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(settingsSectionKey(SettingsSection.privacyNetwork)),
        findsOneWidget,
      );
      expect(find.byKey(settingsPrivacyKey), findsOneWidget);
      expect(find.byKey(torReceivingSwitchKey), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(torReceivingSwitchKey)).dy,
        greaterThan(tester.getTopLeft(find.byKey(settingsPrivacyKey)).dy),
      );
    }, skip: !torBuilt);
  });

  group('updates on opening', () {
    testWidgets('checks at start, on unlock and on a resume, never between', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      // Locked at start: the unlock is the opening.
      expect(h.updates.checks, 0);
      await h.unlock(tester);
      expect(h.updates.checks, 1);

      // Time on screen and a trip to Settings check nothing.
      await tester.pump(const Duration(minutes: 10));
      await h.openSettings(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(h.updates.checks, 1);

      // Opened again without an unlock.
      await _leave(tester);
      h.now = h.now.add(const Duration(minutes: 1));
      await _return(tester);
      expect(h.updates.checks, 2);

      // A system dialog (inactive and back) and a file picker are not openings.
      await _states(tester, const [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ], settle: true);
      final hold = Completer<void>();
      unawaited(
        h.container
            .read(autoLockHoldProvider.notifier)
            .during(() => hold.future),
      );
      await _leave(tester);
      await _return(tester);
      hold.complete();
      await tester.pumpAndSettle();
      expect(h.updates.checks, 2);

      // Away past the timeout: it locks, and the unlock checks once.
      await _leave(tester);
      h.now = h.now.add(const Duration(minutes: 15));
      await _return(tester);
      expect(h.container.read(sessionProvider), isNull);
      expect(h.updates.checks, 2);
      await h.unlock(tester);
      expect(h.updates.checks, 3);
    });

    testWidgets(
      'the notice offers a version once: closed, it stays closed after reopening and after '
      'lock and unlock; a newer version shows again',
      (tester) async {
        final h = _Harness()..updates.offer = _update;
        await h.pump(tester);
        await h.unlock(tester);
        Finder notice([String version = '1.6.1']) => find.descendant(
          of: find.byKey(noticeKey),
          matching: find.text('Version $version is available.'),
        );
        expect(notice(), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byKey(noticeKey),
            matching: find.byTooltip('Close'),
          ),
        );
        await tester.pumpAndSettle();
        expect(notice(), findsNothing);
        expect(h.store.values[updateNoticeDismissedKey], '1.6.1');

        await _leave(tester);
        await _return(tester);
        expect(notice(), findsNothing);
        await tester.tap(find.byTooltip('Lock wallet'));
        await tester.pumpAndSettle();
        await h.unlock(tester);
        expect(notice(), findsNothing);

        h.updates.offer = AvailableUpdate(
          versionName: '1.6.2',
          notes: '',
          apk: _update.apk,
        );
        await _leave(tester);
        await _return(tester);
        expect(notice('1.6.2'), findsOneWidget);
      },
    );

    testWidgets('an update is offered by the notice only: no dot, no row in Settings', (
      tester,
    ) async {
      final h = _Harness()
        ..updates.supported = true
        ..updates.offer = _update;
      await h.pump(tester);
      await h.unlock(tester);
      Finder notice() => find.descendant(
        of: find.byKey(noticeKey),
        matching: find.text('Version 1.6.1 is available.'),
      );
      expect(notice(), findsOneWidget);
      expect(find.byType(Badge), findsNothing);
      expect(find.byTooltip('Settings'), findsOneWidget);
      await tester.tap(find.byKey(settingsButtonKey));
      await tester.pumpAndSettle();
      // Settings never shows a second offer: the same notice, nothing in the list.
      expect(notice(), findsOneWidget);
      expect(find.textContaining('Update to'), findsNothing);
      expect(
        find.descendant(of: find.byType(ListView), matching: find.text('Install')),
        findsNothing,
      );
      await tester.tap(
        find.descendant(of: find.byKey(noticeKey), matching: find.text('Update')),
      );
      await tester.pumpAndSettle();
      expect(h.updates.installs, 1);
    });
  });

  group('auto-lock', () {
    testWidgets('locks after the timeout, not before', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);

      // The default is 15 minutes away.
      await _leave(tester);
      h.now = h.now.add(const Duration(minutes: 14));
      await _return(tester);
      expect(h.container.read(sessionProvider), isNotNull);

      await _leave(tester);
      h.now = h.now.add(const Duration(minutes: 15));
      await _return(tester);
      expect(h.container.read(sessionProvider), isNull);
      expect(find.text('Unlock wallet'), findsOneWidget);
    });

    testWidgets('never, and the shortest choice (a minute)', (tester) async {
      final h = _Harness();
      h.store.values['app.auto_lock'] = 'never';
      await h.pump(tester);
      await h.unlock(tester);
      await _leave(tester);
      h.now = h.now.add(const Duration(days: 1));
      await _return(tester);
      expect(h.container.read(sessionProvider), isNotNull);

      await h.container
          .read(appSettingsProvider.notifier)
          .setAutoLockMinutes(1);
      await _leave(tester);
      h.now = h.now.add(const Duration(seconds: 59));
      await _return(tester);
      expect(h.container.read(sessionProvider), isNotNull);
      await _leave(tester);
      h.now = h.now.add(const Duration(minutes: 1));
      await _return(tester);
      expect(h.container.read(sessionProvider), isNull);
    });

    testWidgets('waits for a running scan to finish', (tester) async {
      final h = _Harness();
      h.session.controller = StreamController<ScanProgress>();
      await h.pump(tester);
      await h.unlock(tester);
      unawaited(h.container.read(scanProvider.notifier).run());
      await tester.pump();
      expect(h.container.read(scanProvider).running, isTrue);

      // Away, the scan pauses (Android cuts the network); back, it goes on as a new scan.
      await _leave(tester, settle: false);
      expect(h.container.read(scanProvider).paused, isTrue);
      h.session.controller = StreamController<ScanProgress>();
      h.now = h.now.add(const Duration(minutes: 20));
      await _return(tester, settle: false);
      await tester.pump();
      expect(h.container.read(sessionProvider), isNotNull);
      expect(h.session.scans, 2);

      h.session.controller!.add(
        const ScanProgress(percent: 100, message: 'Done', finished: true),
      );
      await h.session.controller!.close();
      await tester.pumpAndSettle();
      expect(h.container.read(sessionProvider), isNull);
      expect(find.text('Unlock wallet'), findsOneWidget);
    });

    testWidgets('a trip to the file picker does not count', (tester) async {
      final h = _Harness();
      h.store.values['app.auto_lock'] = '1';
      await h.pump(tester);
      await h.unlock(tester);
      final hold = Completer<void>();
      unawaited(
        h.container
            .read(autoLockHoldProvider.notifier)
            .during(() => hold.future),
      );
      await _leave(tester);
      h.now = h.now.add(const Duration(minutes: 10));
      await _return(tester);
      hold.complete();
      await tester.pumpAndSettle();
      expect(h.container.read(sessionProvider), isNotNull);
    });
  });

  group('biometric unlock', () {
    _Harness withBiometrics({bool succeed = true}) {
      final h = _Harness();
      h.bio
        ..available = true
        ..succeed = succeed
        ..values['wallet.mainnet.pin'] = _pin;
      h.store.values['wallet.mainnet.pinBiometrics'] = '1';
      return h;
    }

    testWidgets('a cold start prompts once', (tester) async {
      final h = withBiometrics();
      await h.pump(tester);
      expect(h.bio.prompts, 1);
      expect(h.container.read(sessionProvider), isNotNull);
    });

    testWidgets('Lock wallet waits for a tap on Use biometrics', (
      tester,
    ) async {
      final h = withBiometrics();
      await h.pump(tester);
      expect(h.bio.prompts, 1);

      await tester.tap(find.byTooltip('Lock wallet'));
      await tester.pumpAndSettle();
      expect(h.container.read(sessionProvider), isNull);
      expect(find.text('Unlock wallet'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'PIN'), findsOneWidget);
      expect(h.bio.prompts, 1);

      await tester.tap(find.text('Use biometrics'));
      await tester.pumpAndSettle();
      expect(h.bio.prompts, 2);
      expect(h.container.read(sessionProvider), isNotNull);
    });

    testWidgets('a dismissed prompt is not offered again on a return', (
      tester,
    ) async {
      final h = withBiometrics(succeed: false);
      await h.pump(tester);
      expect(h.bio.prompts, 1);
      expect(find.text('Unlock wallet'), findsOneWidget);

      await _leave(tester);
      h.now = h.now.add(const Duration(minutes: 10));
      await _return(tester);
      expect(h.bio.prompts, 1);
      expect(find.text('Unlock wallet'), findsOneWidget);
    });

    testWidgets('the auto-lock timeout prompts again', (tester) async {
      final h = withBiometrics();
      await h.pump(tester);
      expect(h.bio.prompts, 1);

      await _leave(tester);
      h.now = h.now.add(const Duration(minutes: 15));
      await _return(tester);
      expect(h.bio.prompts, 2);
      expect(h.container.read(sessionProvider), isNotNull);
    });
  });

  group('security', () {
    testWidgets('change PIN asks for the current PIN and a new one twice', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.security);
      await _tapText(tester, 'Change PIN');

      final field = find.byType(TextField);
      final at = tester.getRect(field);
      await _enter(tester, 'Current PIN', '000000');
      expect(find.textContaining('Wrong PIN'), findsOneWidget);
      expect(tester.getRect(field), at, reason: 'the error line was held');
      await _enter(tester, 'Current PIN', _pin);
      // The new PIN's field is named so, and takes the current one's place (#64).
      expect(tester.getRect(find.widgetWithText(TextField, 'New PIN')), at);
      await _enter(tester, 'New PIN', '654321');
      expect(tester.getRect(find.widgetWithText(TextField, 'Repeat PIN')), at);
      await _enter(tester, 'Repeat PIN', '654321');

      // Back on settings, docked under the app bar, and gone after a while.
      expect(find.byType(ChangePinScreen), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(noticeKey),
          matching: find.text('PIN changed'),
        ),
        findsOneWidget,
      );
      final docked = tester.getTopLeft(find.text('Change PIN'));
      final dock = tester.getSize(find.byType(NoticeDock)).height;
      expect(dock, greaterThan(0));
      await tester.pump(noticeDuration(NoticeLevel.success));
      await tester.pumpAndSettle();
      expect(find.text('PIN changed'), findsNothing);
      // The dock closed, and the row under the finger stayed where it was (android-02).
      expect(tester.getSize(find.byType(NoticeDock)).height, 0);
      expect(tester.getTopLeft(find.text('Change PIN')), docked);
      expect(
        h.store.values['wallet.mainnet.pinSealed'],
        fakeSealedPassword('654321'),
      );
      expect(h.service.confirmedPinChanges.last, fakeSealedPassword('654321'));
    });

    testWidgets('delete needs the warning, the word and the PIN', (
      tester,
    ) async {
      final h = _Harness();
      // History backup records of this network, and one of another network that must stay.
      h.store.values['app.history_exported.mainnet'] = '1790000000';
      h.store.values['app.history_reminder_dismissed.mainnet'] = '1790000001';
      h.store.values['app.history_exported.floonet'] = '1790000002';
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);
      await _tapText(tester, 'Delete wallet');

      FilledButton deleteButton() =>
          tester.widget(find.widgetWithText(FilledButton, 'Delete wallet'));
      expect(deleteButton().onPressed, isNull);
      await tester.tap(find.text('I have written down my recovery phrase'));
      await tester.pump();
      expect(deleteButton().onPressed, isNull);
      await _enter(tester, 'Type “delete” to confirm', 'delet');
      expect(deleteButton().onPressed, isNull);
      await _enter(tester, 'Type “delete” to confirm', 'delete');
      expect(deleteButton().onPressed, isNotNull);
      await tester.tap(find.text('Delete wallet').last);
      await tester.pumpAndSettle();

      // Cancelling the PIN keeps the wallet.
      await _tapText(tester, 'Cancel');
      expect(h.service.deletedWallets, isEmpty);

      await _tapText(tester, 'Delete wallet');
      await tester.tap(find.text('I have written down my recovery phrase'));
      await _enter(tester, 'Type “delete” to confirm', 'delete');
      await tester.tap(find.text('Delete wallet').last);
      await tester.pumpAndSettle();
      await _enter(tester, 'PIN', _pin);

      expect(h.service.deletedWallets, [_mainnetDir]);
      expect(h.cleanups, 1);
      expect(h.store.values['wallet.mainnet.pinSealed'], isNull);
      // A new wallet on this network starts without the deleted one's backup dates.
      expect(h.store.values['app.history_exported.mainnet'], isNull);
      expect(h.store.values['app.history_reminder_dismissed.mainnet'], isNull);
      expect(h.store.values['app.history_exported.floonet'], '1790000002');
      final settings = h.container.read(appSettingsProvider).value!;
      expect(settings.historyExportedAt, {'floonet': 1790000002});
      expect(settings.historyReminderDismissedAt, isEmpty);
      expect(h.container.read(sessionProvider), isNull);
      expect(find.text('Welcome'), findsOneWidget);
    });
  });

  group('history backup', () {
    testWidgets('exports the backup and the CSV, and imports', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);

      await _tapText(tester, 'Export wallet data');
      // Share comes first: the copy that matters is the one off this phone.
      // What the file holds, that it is not the recovery phrase, and the order of a restore.
      expect(find.text(backupFileNote(englishStrings)), findsOneWidget);
      expect(backupFileNote(englishStrings), contains('enter the recovery phrase first'));
      expect(
        tester.getTopLeft(find.text('Share')).dy <
            tester.getTopLeft(find.text('Save to device')).dy,
        isTrue,
      );
      await _tapText(tester, 'Save to device');
      expect(h.files.saved.single.name, 'epic-wallet-data-20260930.wfeh');
      expect(h.files.saved.single.bytes, isNotEmpty);
      expect(
        find.text('Saved epic-wallet-data-20260930.wfeh'),
        findsOneWidget,
      );

      await _tapText(tester, 'Export CSV');
      expect(find.textContaining('Not encrypted'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Export CSV'));
      await tester.pumpAndSettle();
      await _tapText(tester, 'Share');
      expect(h.files.shared.single.name, 'epic-payments-20260930.csv');
      expect(h.files.saved, hasLength(1));

      h.files.picks.add(h.files.saved.first.bytes);
      await _tapText(tester, 'Import wallet data');
      expect(find.text(englishStrings.historyBackupImportedTitle), findsOneWidget);
      await _tapText(tester, 'Done');

      // A cancelled pick does nothing.
      await _tapText(tester, 'Import wallet data');
      expect(find.text(englishStrings.historyBackupImportedTitle), findsNothing);

      h.session.importError = const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'This history file belongs to a different wallet',
      );
      h.files.picks.add(Uint8List.fromList([1, 2, 3]));
      await _tapText(tester, 'Import wallet data');
      // An error notice, not a dialog.
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(noticeKey),
          matching: find.text(
            'Could not import the wallet data. '
            'This file belongs to a different wallet. Only the wallet restored from the same recovery phrase can open it.',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('saves straight to the device where nothing can share', (
      tester,
    ) async {
      final h = _Harness();
      h.files.canShare = false;
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);
      await _tapText(tester, 'Export wallet data');
      expect(find.text('Share'), findsNothing);
      expect(h.files.saved.single.name, 'epic-wallet-data-20260930.wfeh');
    });

    testWidgets('dismissing the choice exports nothing', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);
      await _tapText(tester, 'Export wallet data');
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();
      expect(h.files.saved, isEmpty);
      expect(h.files.shared, isEmpty);
    });

    test('one summary says what came back', () {
      expect(
        backupRestoredText(englishStrings, payments: 12, notes: 1, contacts: 4, pairings: 2, invoices: 3, settings: true),
        'Imported: 12 payments, 1 note, 4 contacts, 2 pairings, 3 invoices and settings.',
      );
      expect(backupRestoredText(englishStrings, contacts: 1), 'Imported: 1 contact.');
      expect(
        backupRestoredText(englishStrings, payments: 2, alreadyHere: 3),
        'Imported: 2 payments. 3 records were already here.',
      );
      expect(backupRestoredText(englishStrings, alreadyHere: 3), 'The file held nothing new.');
    });
  });

  group('wallet', () {
    testWidgets('Recheck balance without Recheck from a height only confirms', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);

      await _tapText(tester, 'Recheck balance');
      // No start choice: the from-height stays behind the Advanced switch.
      expect(find.text('From a block height'), findsNothing);
      expect(find.text('From a date'), findsNothing);
      expect(find.text('The whole chain'), findsNothing);
      // Block 0: only a scan from there finishes a restore.
      await _tapText(tester, 'Recheck');
      expect(h.session.lastStart, BigInt.zero);
      expect(h.session.scanCalls, 1);
    });

    testWidgets('Kill switch: Recheck balance waits, with the reason', (
      tester,
    ) async {
      final h = _Harness();
      h.store.values['app.advanced_prefs'] = 'outputs|standard';
      useNetworkModeFile(NetworkMode.killSwitch);
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);
      await _reveal(tester, find.text('Recheck balance'));
      expect(find.text('Recheck balance needs the node. Off in Kill switch.'), findsOneWidget);
      await _tapText(tester, 'Recheck balance');
      expect(find.byType(AlertDialog), findsNothing);
      expect(h.session.scanCalls, 0);
    });

    testWidgets('rescans from a height or the whole chain', (tester) async {
      final h = _Harness(advanced: true);
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);

      await _tapText(tester, 'Recheck balance');
      await _tapText(tester, 'From a block height');
      await _tapText(tester, 'Recheck');
      expect(find.text('Enter a block height of 1 or more.'), findsOneWidget);
      await _enter(tester, 'Start height', '3000000');
      await _tapText(tester, 'Recheck');
      expect(h.session.lastStart, BigInt.from(3000000));

      await _tapText(tester, 'Recheck balance');
      await _tapText(tester, 'The whole chain');
      await _tapText(tester, 'Recheck');
      expect(h.session.lastStart, BigInt.zero);
      expect(h.session.scanCalls, 2);
    });
  });

  // A tester on 26.10.16 never saw Restore: it was a link under the PIN field, and on a small
  // phone the keyboard covered it, so the PIN made a new wallet. The first screen now asks
  // Create or Restore before any field, Delete leads back to that choice, and Settings › Wallet
  // restores through Delete's own warning and PIN.
  group('restore is a first-class choice', () {
    testWidgets(
      'first run offers Create and Restore before the PIN, in view at 360×760 and text scale '
      '1.3 with a keyboard-sized inset',
      (tester) async {
        final h = _Harness(sealed: false, walletExists: false);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await h.pump(tester);
        // 360×760 dp; the lower 300 dp as a keyboard would take them.
        tester.view.physicalSize = const Size(1080, 2280);
        tester.view.viewInsets = const FakeViewPadding(bottom: 900);
        await tester.pumpAndSettle();

        expect(find.byType(FirstRunScreen), findsOneWidget);
        expect(find.widgetWithText(TextField, 'PIN'), findsNothing);
        final create = find.byKey(firstRunCreateKey);
        final restore = find.byKey(firstRunRestoreKey);
        expect(find.text('Create a new wallet'), findsOneWidget);
        expect(find.text('Restore from phrase'), findsOneWidget);
        // Both whole buttons inside the part of the screen the keyboard leaves, unscrolled.
        for (final button in [create, restore]) {
          final rect = tester.getRect(button);
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(760 - 300), reason: 'under the keyboard');
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(360));
        }
        // Node and Epicbox stays on the first screen (as the icon at this text scale).
        expect(find.byType(NetworkSettingsButton), findsOneWidget);

        // Create leads to the PIN; Back returns to the choice; Restore leads to the phrase.
        await tester.tap(create);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextField, 'PIN'), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(create, findsOneWidget);
        // The system's Back does the same, instead of leaving the app.
        await tester.tap(create);
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(create, findsOneWidget);
        expect(find.byType(FirstRunScreen), findsOneWidget);
        await tester.tap(restore);
        await tester.pumpAndSettle();
        expect(find.byType(RestoreScreen), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Recovery phrase'), findsOneWidget);
      },
    );

    testWidgets('after Delete the first screen offers Create and Restore', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);
      await _tapText(tester, 'Delete wallet');
      await tester.tap(find.text('I have written down my recovery phrase'));
      await _enter(tester, 'Type “delete” to confirm', 'delete');
      await tester.tap(find.text('Delete wallet').last);
      await tester.pumpAndSettle();
      await _enter(tester, 'PIN', _pin);

      expect(h.service.deletedWallets, [_mainnetDir]);
      expect(find.byType(FirstRunScreen), findsOneWidget);
      expect(find.byKey(firstRunCreateKey), findsOneWidget);
      expect(find.byKey(firstRunRestoreKey), findsOneWidget);
      expect(find.widgetWithText(TextField, 'PIN'), findsNothing);
      await tester.tap(find.byKey(firstRunRestoreKey));
      await tester.pumpAndSettle();
      expect(find.byType(RestoreScreen), findsOneWidget);
    });

    // The phrase comes first; the wallet goes only once it checks out and the warning and
    // the PIN confirmed, and the restored wallet keeps the PIN.
    testWidgets(
      'Settings › Wallet › Restore from a phrase asks for the phrase first, then the delete '
      'warning and the PIN, and replaces the wallet in one step',
      (tester) async {
        final h = _Harness();
        await h.pump(tester);
        await h.unlock(tester);
        await h.openSettings(tester, SettingsSection.wallet);
        await _reveal(tester, find.byKey(settingsRestoreKey));
        // Next to Delete, in the row's normal colour.
        expect(find.text('Restore from phrase'), findsOneWidget);
        expect(find.text('Delete wallet'), findsOneWidget);

        // The phrase first; Back leaves the wallet as it is.
        await _tapText(tester, 'Restore from phrase');
        expect(find.byType(RestoreScreen), findsOneWidget);
        expect(find.byType(DeleteWalletDialog), findsNothing);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(RestoreScreen), findsNothing);
        expect(find.text('Delete wallet'), findsOneWidget);
        expect(h.container.read(sessionProvider), isNotNull);

        // A phrase that does not check out never reaches the warning.
        await _tapText(tester, 'Restore from phrase');
        await _enter(tester, 'Recovery phrase', 'abandon abandon abandon');
        await _tapText(tester, 'Continue');
        expect(find.textContaining('This phrase has 3 words.'), findsOneWidget);
        expect(find.byType(DeleteWalletDialog), findsNothing);

        await _enter(tester, 'Recovery phrase', h.service.phrase);
        await _tapText(tester, 'Continue');
        expect(find.byType(DeleteWalletDialog), findsOneWidget);
        expect(
          find.textContaining('This wallet is removed and the wallet of the typed phrase'),
          findsOneWidget,
        );
        // Keep wallet: nothing deleted, the phrase still there.
        await _tapText(tester, 'Keep wallet');
        expect(h.service.deletedWallets, isEmpty);
        expect(find.text(h.service.phrase), findsOneWidget);

        // The extra paragraph makes the dialog scroll on a 360 dp phone: the checkbox is
        // scrolled into view first, as a user would.
        final havePhrase = find.text('I have written down my recovery phrase');
        Future<void> confirm() async {
          await _tapText(tester, 'Continue');
          expect(find.byType(DeleteWalletDialog), findsOneWidget);
          await tester.ensureVisible(havePhrase);
          await tester.pumpAndSettle();
          await tester.tap(havePhrase);
          await _enter(tester, 'Type “delete” to confirm', 'delete');
          await tester.tap(find.text('Delete wallet').last);
          await tester.pumpAndSettle();
        }

        // Cancelling the PIN keeps the wallet too.
        await confirm();
        await _tapText(tester, 'Cancel');
        expect(h.service.deletedWallets, isEmpty);
        expect(h.container.read(sessionProvider), isNotNull);

        await confirm();
        expect(find.textContaining('The restored wallet keeps this PIN.'), findsOneWidget);
        await _enter(tester, 'PIN', _pin);

        // Deleted and restored in one step, with the same PIN; the scan then runs.
        expect(h.service.deletedWallets, [_mainnetDir]);
        expect(h.service.createdMnemonic, h.service.phrase);
        expect(h.service.createdPin, _pin);
        expect(h.store.values['wallet.mainnet.pinSealed'], fakeSealedPassword(_pin));
        expect(h.cleanups, 1);
        expect(h.session.scanCalls, 1);
        expect(find.text('Import wallet data'), findsOneWidget);
        expect(find.byType(FirstRunScreen), findsNothing);
      },
    );

    // A delete that fails after the wallet closed leaves for the launch screen.
    // The automatic restore scan never holds a delete: it is stopped first. A Recheck the user
    // started still is.
    testWidgets('Delete stops the automatic restore scan; a running Recheck still waits', (tester) async {
      final h = _Harness();
      h.session
        ..restoreScanPending = true
        ..controller = StreamController<ScanProgress>();
      await h.pump(tester);
      await tester.enterText(find.widgetWithText(TextField, 'PIN'), _pin);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(h.container.read(scanProvider).running, isTrue);
      expect(h.session.lastStart, isNull, reason: 'the automatic scan from block 0');
      // The running scan animates: frames instead of settling.
      Future<void> frames() async {
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await h.openSettingsNow(tester, SettingsSection.wallet);
      final delete = find.text('Delete wallet');
      await tester.ensureVisible(delete);
      await frames();
      await tester.tap(delete);
      await frames();
      await tester.tap(find.text('I have written down my recovery phrase'));
      await tester.enterText(find.widgetWithText(TextField, 'Type “delete” to confirm'), 'delete');
      await frames();
      await tester.tap(find.text('Delete wallet').last);
      await frames();
      await tester.enterText(find.widgetWithText(TextField, 'PIN'), _pin);
      await frames();
      await tester.pumpAndSettle();

      expect(h.session.scanCancels, 1);
      expect(h.service.deletedWallets, [_mainnetDir]);
      expect(find.byType(FirstRunScreen), findsOneWidget);
      // The stopped scan did not start again.
      expect(h.session.scans, 1);
    });

    testWidgets('Delete waits for a Recheck the user started', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      h.session.controller = StreamController<ScanProgress>();
      await h.openSettings(tester, SettingsSection.wallet);
      await _tapText(tester, 'Recheck balance');
      await tester.tap(find.text('Recheck'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(h.container.read(scanProvider).running, isTrue);
      await tester.tap(find.text('Delete wallet').last);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Wait for the scan to finish before deleting the wallet.'), findsOneWidget);
      expect(find.byType(DeleteWalletDialog), findsNothing);
      expect(h.session.scanCancels, 0);
      await h.session.controller!.close();
      await tester.pumpAndSettle();
    });

    testWidgets('a delete that fails returns to the launch screen with the reason', (tester) async {
      final h = _Harness();
      h.service.deleteError = const WalletError(kind: WalletErrorKind.walletBusy, message: 'busy');
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);
      await _tapText(tester, 'Delete wallet');
      await tester.tap(find.text('I have written down my recovery phrase'));
      await _enter(tester, 'Type “delete” to confirm', 'delete');
      await tester.tap(find.text('Delete wallet').last);
      await tester.pumpAndSettle();
      await _enter(tester, 'PIN', _pin);

      expect(h.service.deletedWallets, isEmpty);
      expect(h.container.read(sessionProvider), isNull);
      expect(find.byType(SettingsScreen), findsNothing);
      // The wallet is still there: its unlock screen, with the reason in a notice.
      expect(find.text('Unlock wallet'), findsOneWidget);
      expect(find.textContaining('Wallet not deleted.'), findsOneWidget);
    });
  });

  group('delete while scanning', () {
    testWidgets('is refused with a plain reason', (tester) async {
      final h = _Harness();
      h.session.controller = StreamController<ScanProgress>();
      await h.pump(tester);
      await h.unlock(tester);
      unawaited(h.container.read(scanProvider.notifier).run());
      await tester.pump();
      await h.openSettingsNow(tester, SettingsSection.wallet);
      final tile = find.text('Delete wallet');
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.scrollUntilVisible(tile, 300, scrollable: find.byType(Scrollable).first);
      await tester.pump();
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text(englishStrings.settingsDeleteDuringScan),
        findsOneWidget,
      );
      expect(find.byType(DeleteWalletDialog), findsNothing);
      expect(h.service.deletedWallets, isEmpty);
      await h.session.controller!.close();
      await tester.pumpAndSettle();
    });
  });

  testWidgets('Contacts opens the contact list for editing, not the picker', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await h.unlock(tester);
    await h.openSettings(tester, SettingsSection.wallet);
    await _tapText(tester, 'Contacts');
    final screen = tester.widget<ContactsScreen>(find.byType(ContactsScreen));
    expect(screen.pick, isFalse);
  });

  group('invoices', () {
    final l = lookupAppLocalizations(const Locale('en'));
    // A valid epicbox address with a key made of [c].
    String addr(String c) => '${'es$c'.padRight(52, c)}@box.epic.invalid';
    final shop = addr('S');

    /// Settings › Wallet › Invoices, after [seed] paired the session's contacts.
    Future<_Harness> openInvoices(
      WidgetTester tester, {
      bool advanced = false,
      Future<void> Function(_Harness h)? seed,
    }) async {
      final h = _Harness(advanced: advanced, experimental: true);
      await seed?.call(h);
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);
      await _tapText(tester, 'Invoices');
      expect(find.byType(InvoiceSettingsScreen), findsOneWidget);
      return h;
    }

    /// A saved contact [name] paired as [state], with Allow invoices [allow].
    Future<PairingRecord> paired(
      _Harness h,
      String name, {
      PairingState state = PairingState.verified,
      bool allow = false,
      bool saved = true,
    }) async {
      String? id;
      if (saved) {
        await h.session.saveContact(contact: Contact(id: '', name: name, address: shop));
        id = (await h.session.contacts()).firstWhere((c) => c.name == name).id;
      }
      return h.session.pairing.seedPaired(
        name: name,
        state: state,
        allowInvoices: allow,
        contactId: id,
        paymentsAddress: shop,
        kind: PairingParty.exchange,
      );
    }

    Finder notice(String text) =>
        find.descendant(of: find.byKey(noticeKey), matching: find.text(text));

    testWidgets('the section is hidden on a core without invoices', (
      tester,
    ) async {
      final h = _Harness(advanced: true);
      h.session.invoicesSupported = false;
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);
      await _reveal(tester, find.text('Contacts'));
      expect(find.text('Contacts'), findsOneWidget);
      expect(find.text('Who may ask you to pay'), findsNothing);
    });

    testWidgets('the section says who may ask you to pay', (tester) async {
      final h = _Harness(experimental: true);
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.wallet);
      await _reveal(tester, find.text('Who may ask you to pay'));
      expect(find.text('Who may ask you to pay'), findsOneWidget);
      expect(find.text('Invoice address and trusted services'), findsNothing);
    });

    testWidgets('no pairings: the empty state offers Pair with a shop or exchange', (tester) async {
      await openInvoices(tester);
      expect(find.text(l.invSetEmpty), findsOneWidget);
      await tester.tap(find.byKey(invoiceSettingsPairKey));
      await tester.pumpAndSettle();
      expect(find.text(l.pairTitle), findsWidgets);
      expect(find.text(l.pairInPerson), findsOneWidget);
    });

    testWidgets('a verified contact is switched on and off; off declines its requests', (tester) async {
      late PairingRecord r;
      final h = await openInvoices(tester, seed: (h) async => r = await paired(h, 'Northwind', allow: true));
      expect(find.text('Northwind'), findsOneWidget);
      expect(find.text(l.invSetAllowed), findsOneWidget);
      h.session.relayInvoice(from: shop, slateId: 'i1', amount: BigInt.from(100));
      await h.session.drainInvoices();
      await tester.tap(find.byKey(invoiceSettingsSwitchKey(r.id)));
      await tester.pumpAndSettle();
      expect(notice('${l.invSetSwitchedOff('Northwind')} ${l.invSetDeclinedCount(1)}'), findsOneWidget);
      expect(h.session.declinedInvoices, ['i1']);
      expect(find.text(l.invSetOff), findsOneWidget);
      await tester.tap(find.byKey(invoiceSettingsSwitchKey(r.id)));
      await tester.pumpAndSettle();
      expect((await h.session.pairing.pairing(r.id))!.allowInvoices, isTrue);
    });

    testWidgets('a contact not verified cannot be allowed until the words are checked', (tester) async {
      late PairingRecord r;
      await openInvoices(tester, seed: (h) async => r = await paired(h, 'Tom', state: PairingState.paired));
      expect(find.text(l.contactCheckWordsFirst), findsOneWidget);
      final sw = tester.widget<Switch>(find.byKey(invoiceSettingsSwitchKey(r.id)));
      expect(sw.onChanged, isNull);
      expect(sw.value, isFalse);
      await tester.tap(find.byKey(invoiceSettingsMenuKey(r.id)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.noticeCheckWords).last);
      await tester.pumpAndSettle();
      expect(find.text(l.sasMatch), findsOneWidget);
    });

    testWidgets('keys changed: the risk badge, paused, and Check the words; never allowed', (tester) async {
      late PairingRecord r;
      await openInvoices(tester, seed: (h) async => r = await paired(h, 'Marta', state: PairingState.keysChanged));
      expect(find.text(l.trustKeysChanged), findsOneWidget);
      expect(find.text(l.contactKeysChangedPaused), findsOneWidget);
      expect(find.text(l.contactCheckWordsFirst), findsNothing, reason: 'not the paired text');
      final sw = tester.widget<Switch>(find.byKey(invoiceSettingsSwitchKey(r.id)));
      expect(sw.onChanged, isNull);
      expect(sw.value, isFalse);
      await tester.tap(find.byKey(invoiceSettingsMenuKey(r.id)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.noticeCheckWords).last);
      await tester.pumpAndSettle();
      expect(find.text(l.sasMatch), findsOneWidget);
    });

    testWidgets('a pairing whose contact is gone offers Add to contacts and Remove pairing', (tester) async {
      final h = await openInvoices(tester, seed: (h) async => paired(h, 'Marta', saved: false));
      expect(find.text(l.pairNotInContacts), findsOneWidget);
      final marta = (await h.session.pairing.pairings()).single;
      await tester.tap(find.byKey(invoiceSettingsMenuKey(marta.id)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.contactRemovePairing).last);
      await tester.pumpAndSettle();
      expect(find.text(l.contactRemovePairingTitle('Marta')), findsOneWidget, reason: 'asks first');
      await tester.tap(find.byKey(confirmRemovePairingKey));
      await tester.pumpAndSettle();
      expect(await h.session.pairing.pairings(), isEmpty);
    });

    testWidgets('Time to pay is a readout under Advanced only', (tester) async {
      await openInvoices(tester);
      expect(find.text(l.invSetTimeToPay), findsNothing);
    });

    testWidgets('Advanced shows how long an invoice stays payable', (tester) async {
      await openInvoices(tester, advanced: true);
      await _reveal(tester, find.text(l.invSetTimeToPay));
      expect(find.text(l.invSetTimeToPayHint(invoiceExpiry.inHours)), findsOneWidget);
    });
  });

  group('about', () {
    testWidgets('About shows the source code link from app-config.toml', (
      tester,
    ) async {
      registerTorLicence();
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.about);
      expect(projectRepoUrl, isNotNull);
      expect(find.text('Licences'), findsOneWidget);
      await _reveal(tester, find.text('Source code'));
      expect(find.text('Source code'), findsOneWidget);
      expect(find.text('Epic Cash'), findsWidgets, reason: 'the other links stay');
      await _reveal(tester, find.text(hostSettings.supportEmail!));
      expect(find.text('Contact'), findsOneWidget);
      // An email address, not a link: the notice says so.
      final copied = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') copied.add(call.arguments);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.ensureVisible(find.text(hostSettings.supportEmail!));
      await tester.pump();
      await tester.tap(find.text(hostSettings.supportEmail!));
      await tester.pump();
      expect(copied, [
        {'text': hostSettings.supportEmail!},
      ]);
      final notices = ProviderScope.containerOf(
        tester.element(find.text(hostSettings.supportEmail!)),
      );
      expect(notices.read(noticeProvider)?.text, 'Address copied');
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.semanticLabel == 'Copy address',
        ),
        findsOneWidget,
      );
      // Back up to Licences, above the contact row.
      await tester.scrollUntilVisible(
        find.byKey(settingsLicencesKey),
        -200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(settingsLicencesKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LicencesScreen), findsOneWidget);
      expect(find.text('Epic Cash Mobile by BT Labs: Apache 2.0.'), findsOneWidget);
      expect(find.textContaining('wallet-for-epic'), findsNothing);
      expect(find.textContaining('GitHub'), findsNothing);
    });

    testWidgets('Licences opens the licence page with the bundled tor in it', (
      tester,
    ) async {
      registerTorLicence();
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.about);
      await _reveal(tester, find.byKey(settingsLicencesKey));
      expect(find.text('Licences'), findsOneWidget);
      final row = tester.widget<ListTile>(find.byKey(settingsLicencesKey));
      expect(row.subtitle, isNull, reason: 'label only');
      await tester.tap(find.byKey(settingsLicencesKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      // The short screen: one line per component, the tor source note, the full texts behind
      // one button.
      expect(find.byType(LicencesScreen), findsOneWidget);
      expect(find.textContaining('Tor: GNU General Public License, version 3.'), findsOneWidget);
      expect(find.textContaining('LEPIC, the Epic Cash wallet library: Apache 2.0'), findsOneWidget);
      // The source note is an asset, read in real time.
      for (var i = 0; i < 50 && find.textContaining('tor 0.4.9.14, unmodified', skipOffstage: false).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      expect(find.textContaining('tor 0.4.9.14, unmodified', skipOffstage: false), findsOneWidget);
      await _reveal(tester, find.byKey(licencesFullKey));
      await tester.tap(find.byKey(licencesFullKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      // The app's own page of full texts (UP-025), not Flutter's stock LicensePage.
      expect(find.byType(LicenceTextsScreen), findsOneWidget);
      // British, like the row and the rest of the app.
      expect(find.text('Licenses'), findsNothing);
      // The registry reads the licences on real async.
      for (var i = 0; i < 50 && find.text('Tor').evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(find.text('Tor'), findsOneWidget);
    }, skip: !torBuilt);
  });

  testWidgets('About offers Check for updates wherever the updater runs, with Tor and without', (tester) async {
    final h = _Harness()
      ..updates.supported = null
      ..updatePlatform = _NoInstaller();
    await h.pump(tester);
    await h.unlock(tester);
    await h.openSettings(tester, SettingsSection.about);
    // Every build from our own page has it, the build without Tor too; a store build none.
    expect(find.text('Check for updates'), inAppUpdates ? findsOneWidget : findsNothing);
    expect(h.container.read(updateProvider.notifier).supported, inAppUpdates);
  });

  group('a notice under the finger (android-02)', () {
    // Phone sizes in dp: a 411 x 914 and a 360 x 740, where the hub and About fit on screen
    // or nearly so and cannot scroll by themselves.
    const phones = [(w: 411.0, h: 914.0), (w: 360.0, h: 740.0), (w: 360.0, h: 640.0)];

    for (final phone in phones) {
      for (final page in [null, SettingsSection.about]) {
        testWidgets(
          '${page?.name ?? 'hub'} at ${phone.w.round()}x${phone.h.round()}: opening and closing a notice moves no row',
          (tester) async {
            final h = _Harness();
            h.updates.supported = true;
            await h.pump(tester);
            await h.unlock(tester);
            tester.view.devicePixelRatio = 2;
            tester.view.physicalSize = Size(phone.w * 2, phone.h * 2);
            await h.openSettings(tester, page);
            final rows = page == null
                ? [
                    find.byKey(settingsGroupKey(SettingsSection.privacyNetwork)),
                    find.byKey(settingsGroupKey(SettingsSection.display)),
                  ]
                : [find.text('Version'), find.text('Check for updates')];
            for (final row in rows) {
              expect(row, findsOneWidget);
            }
            final before = [for (final row in rows) tester.getCenter(row)];
            h.container
                .read(noticeProvider.notifier)
                .show('Notifications off', level: NoticeLevel.info);
            await tester.pump();
            // Every frame of the dock opening, then settled.
            for (var i = 0; i < 12; i++) {
              await tester.pump(const Duration(milliseconds: 30));
              for (var r = 0; r < rows.length; r++) {
                expect(
                  tester.getCenter(rows[r]).dy,
                  moreOrLessEquals(before[r].dy, epsilon: 1),
                  reason: 'open, frame $i',
                );
              }
            }
            await tester.pumpAndSettle(const Duration(milliseconds: 50));
            expect(tester.getSize(find.byType(NoticeDock).last).height, greaterThan(0));
            for (var r = 0; r < rows.length; r++) {
              expect(tester.getCenter(rows[r]).dy, moreOrLessEquals(before[r].dy, epsilon: 1));
            }
            // Closing does not move them either.
            await tester.pump(noticeDuration(NoticeLevel.info));
            await tester.pumpAndSettle(const Duration(milliseconds: 50));
            expect(tester.getSize(find.byType(NoticeDock).last).height, 0);
            for (var r = 0; r < rows.length; r++) {
              expect(tester.getCenter(rows[r]).dy, moreOrLessEquals(before[r].dy, epsilon: 1));
            }
          },
        );
      }
    }
  });

  group('wording', () {
    testWidgets('says where prices come from when they are turned on', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.display);
      expect(find.text(englishStrings.settingsPricesOnNotice), findsNothing);
      await _tapText(tester, 'Show prices');
      expect(h.store.values['app.show_fiat'], 'false');
      expect(find.text(englishStrings.settingsPricesOnNotice), findsNothing);
      await _tapText(tester, 'Show prices');
      expect(find.text(englishStrings.settingsPricesOnNotice), findsOneWidget);
    });

    testWidgets('lists settings without explanations', (tester) async {
      final h = _Harness(advanced: true);
      await h.pump(tester);
      await h.unlock(tester);
      // Rows on the pages are labels only; a state line is allowed on the hub, not here.
      Future<void> noSubtitles(
        SettingsSection section,
        List<String> titles,
      ) async {
        await h.openSettings(tester, section);
        for (final title in titles) {
          await _reveal(tester, find.text(title));
          final tile = tester.widget<ListTile>(
            find.widgetWithText(ListTile, title),
          );
          expect(tile.subtitle, isNull, reason: title);
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      await noSubtitles(SettingsSection.wallet, [
        'Export wallet data',
        'Export CSV',
        'Import wallet data',
        'Contacts',
        'Recheck balance',
        'Delete wallet',
      ]);
      // The Node and Epicbox rows show their server as a state line, so only the plain words
      // are checked on the Privacy & network page.
      await h.openSettings(tester, SettingsSection.privacyNetwork);
      await _reveal(tester, find.byKey(settingsEpicboxKey));
      expect(find.textContaining('relay'), findsNothing);
      expect(find.textContaining('Relay'), findsNothing);
      expect(find.textContaining('ailbox'), findsNothing);
    });

    testWidgets('the Epicbox row opens the picker, which calls the relay an epicbox server', (
      tester,
    ) async {
      final h = _Harness(advanced: true);
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester, SettingsSection.privacyNetwork);
      await _reveal(tester, find.byKey(settingsEpicboxKey));
      await tester.tap(find.byKey(settingsEpicboxKey));
      await tester.pumpAndSettle();
      expect(find.byType(ServerListSheet), findsOneWidget);
      expect(
        find.descendant(of: find.byType(ServerListSheet), matching: find.text('Epicbox')),
        findsOneWidget,
      );
      // The warning names the address, not a relay or a mailbox.
      expect(find.textContaining('relay'), findsNothing);
      expect(find.textContaining('ailbox'), findsNothing);
      await tester.enterText(find.byKey(serverListFieldKey), 'mail.example.com');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverListAddKey));
      await tester.pumpAndSettle();
      // The foot offers the switch; it asks first, naming the address, not a relay or a mailbox.
      await tester.tap(
        find.descendant(of: find.byKey(serverListFootKey), matching: find.text('Switch')),
      );
      await tester.pumpAndSettle();
      // The confirm says the address changes (the sheet's own warning says it too).
      expect(find.text('Switching gives you a new Epicbox address.'), findsWidgets);
      expect(find.byKey(serverListSwitchKey), findsOneWidget);
      expect(find.textContaining('relay'), findsNothing);
      expect(find.textContaining('ailbox'), findsNothing);
    });
  });

  group('advanced options', () {
    /// Every text built on the page in front: the pages are short enough to build whole.
    Set<String> pageTexts(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .toSet();

    testWidgets('the Advanced page saves a switch, and Recheck from a height follows', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      // Off: Recheck balance only confirms; Node and Epicbox stay for everyone.
      await h.openSettings(tester, SettingsSection.privacyNetwork);
      final privacy = pageTexts(tester);
      for (final kept in ['Node', 'Epicbox']) {
        expect(privacy, contains(kept), reason: kept);
      }
      await h.openSettings(tester, SettingsSection.advanced);
      expect(h.store.values['app.advanced_prefs'], isNull);
      await _tapText(tester, 'Recheck from a height');
      expect(h.store.values['app.advanced_prefs'], 'recheckFromHeight|standard');
      await h.openSettings(tester, SettingsSection.wallet);
      await _tapText(tester, 'Recheck balance');
      expect(find.text('From a block height'), findsOneWidget);
      await _tapText(tester, 'Cancel');

      // Off again: the page's own reset.
      await h.openSettings(tester, SettingsSection.advanced);
      await _tapText(tester, 'Hide everything again');
      expect(h.store.values['app.advanced_prefs'], '|standard');
      await h.openSettings(tester, SettingsSection.wallet);
      await _tapText(tester, 'Recheck balance');
      expect(find.text('From a block height'), findsNothing);
    });

    // Tester report 26.10.21: Connection servers on the phone, not on the tablet. The tablet had
    // Pairing off; every width gets the same Settings, which this keeps true.
    group('the same rows at every width', () {
      // Width classes in dp: phone, foldable / small tablet, tablet portrait and landscape.
      const sizes = [(w: 411.0, h: 914.0), (w: 673.0, h: 841.0), (w: 800.0, h: 1280.0), (w: 1280.0, h: 800.0)];

      // Every keyed widget and text a page builds, scrolled from top to bottom.
      Future<Set<String>> pageRows(WidgetTester tester) async {
        final rows = <String>{};
        void collect() {
          for (final e in find.byWidgetPredicate((w) => w.key is ValueKey<String> || w is Text).evaluate()) {
            final w = e.widget;
            rows.add(w is Text ? 'text:${w.data ?? w.textSpan?.toPlainText()}' : 'key:${(w.key! as ValueKey<String>).value}');
          }
        }

        final list = find.byType(Scrollable).first;
        collect();
        for (var i = 0; i < 40; i++) {
          final pos = tester.state<ScrollableState>(list).position;
          if (pos.pixels >= pos.maxScrollExtent) break;
          await tester.drag(list, const Offset(0, -300));
          await tester.pumpAndSettle();
          collect();
        }
        return rows;
      }

      for (final experimental in [false, true]) {
        testWidgets('every Settings page, Experimental ${experimental ? 'on' : 'off'}: tablet and foldable show what the phone shows', (
          tester,
        ) async {
          final h = _Harness(experimental: experimental, advanced: true);
          await h.pump(tester);
          await h.unlock(tester);
          Map<SettingsSection?, Set<String>>? phone;
          for (final size in sizes) {
            tester.view.devicePixelRatio = 2;
            tester.view.physicalSize = Size(size.w * 2, size.h * 2);
            final pages = <SettingsSection?, Set<String>>{};
            for (final section in [null, ...SettingsSection.values]) {
              await h.openSettings(tester, section);
              pages[section] = await pageRows(tester);
              if (section == SettingsSection.advanced) {
                // No Connection servers row: they are the first of the Epicbox list.
                expect(pages[section], isNot(contains('key:adv-connection-servers')), reason: '$size');
                for (final row in ['adv-pairing', 'adv-invoices', 'adv-linkedDevices', 'adv-mode-standard', 'adv-mode-nodeOnly']) {
                  expect(pages[section], contains('key:$row'), reason: '$row at $size');
                }
              }
              tester.state<NavigatorState>(find.byType(Navigator).first).pop();
              await tester.pumpAndSettle();
            }
            phone ??= pages;
            for (final section in pages.keys) {
              expect(pages[section], phone[section], reason: '${section?.name ?? 'hub'} at ${size.w.round()}x${size.h.round()}');
            }
          }
        });
      }
    });

    testWidgets(
      'restore scans the whole chain and offers no start without it',
      (tester) async {
        final h = _Harness(sealed: false, walletExists: false);
        await h.pump(tester);
        // The network choice shows without Advanced too, so a new install can reach floonet.
        // By its semantics label, as label or icon: network_settings_button_test.dart checks
        // which form shows, with the real faces.
        expect(find.bySemanticsLabel('Node and Epicbox'), findsOneWidget);
        await _tapText(tester, 'Restore from phrase');
        expect(find.text('Where to start scanning'), findsNothing);
        expect(find.text('Pick the date you created the wallet'), findsNothing);
        expect(find.text('Block height'), findsNothing);
        expect(find.byKey(restoreStartLinkKey), findsOneWidget);
        await _enter(tester, 'Recovery phrase', h.service.phrase);
        await _tapText(tester, 'Continue');
        await _enter(tester, 'PIN', _pin);
        await _enter(tester, 'Repeat PIN', _pin);
        expect(h.session.scanCalls, 1);
        // No start height: the core scans a restored wallet from block 1.
        expect(h.session.lastStart, isNull);
      },
    );

    testWidgets('restore offers the start to everyone, behind a link', (
      tester,
    ) async {
      // Advanced is off: Restore is a one-off, so the choice is not behind a switch.
      final h = _Harness(sealed: false, walletExists: false);
      await h.pump(tester);
      expect(find.bySemanticsLabel('Node and Epicbox'), findsOneWidget);
      await _tapText(tester, 'Restore from phrase');
      expect(find.byKey(restoreStartLinkKey), findsOneWidget);
      expect(find.text('Start from a date or height'), findsOneWidget);
      expect(find.text('Where to start scanning'), findsNothing);
      await _tapText(tester, 'Start from a date or height');
      expect(find.byKey(restoreStartLinkKey), findsNothing);
      expect(find.text('Where to start scanning'), findsOneWidget);
      expect(find.text('Pick the date you created the wallet'), findsOneWidget);
      await _tapText(tester, 'Block height');
      expect(
        find.widgetWithText(TextField, 'Start height (optional)'),
        findsOneWidget,
      );
    });
  });
}

/// An Android platform side that is never asked to install.
class _NoInstaller implements UpdatePlatform {
  @override
  Future<InstalledApp> installedApp() async =>
      const InstalledApp(packageName: 'uk.btlabs.epiccash.mobile', versionCode: 1, versionName: '1.0.0', abis: ['arm64-v8a']);

  @override
  Future<String> install(File apk) => throw UnimplementedError();

  @override
  Future<void> requestInstallPermission() async {}

  @override
  Stream<({String status, String? message})> get installEvents => const Stream.empty();
}
