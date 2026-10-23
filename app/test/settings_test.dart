import 'dart:async';
import 'dart:convert';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/push_registration.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/tor_licence.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/restore_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_invoices.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_pin.dart';
import 'package:epic_wallet/src/ui/licences_screen.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

const _mainnetDir = '/fake/wallets/mainnet';
const _pin = '123456';

class _FakePush implements PushPlatform {
  int starts = 0;
  int deleted = 0;
  bool permitted = true;
  bool configuredBuild = true;
  Object? failure;

  @override
  Future<bool> configured() async => configuredBuild;

  @override
  Future<bool> start() async {
    starts++;
    if (failure case final error?) throw error;
    return permitted;
  }

  @override
  Future<String?> token() async => 'token';

  @override
  Future<void> deleteToken() async => deleted++;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get foreground => const Stream.empty();
}

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

  @override
  Stream<ScanProgress> scan({BigInt? startHeight, bool deleteUnconfirmed = false}) {
    lastStart = startHeight;
    final c = controller;
    return c == null ? super.scan(startHeight: startHeight) : c.stream;
  }
}

/// What the update check finds, and how often the app asked. With [offer], every opening
/// finds it, through the phases the real check passes.
class _UpdateScript {
  bool supported = false;
  AvailableUpdate? offer;
  int checks = 0;
  int installs = 0;
}

class _ScriptedUpdates extends UpdateNotifier {
  _ScriptedUpdates(this.script);

  final _UpdateScript script;

  @override
  bool get supported => script.supported;

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
  }) : scanner = FakeQrScanner(supported: scanSupported) {
    if (advanced) store.values['app.advanced'] = 'true';
    if (sealed) {
      store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_pin);
    }
    service = FakeWalletService(
      existingWallets: walletExists ? {_mainnetDir} : {},
      session: session,
    );
  }

  final store = MemorySecretStore();
  final bio = MemoryBiometricStore(available: false);
  final files = FakeHistoryFiles();
  final session = _ScanSession();
  final push = _FakePush();
  final posts = <({Uri url, String body, Duration timeout})>[];
  final FakeQrScanner scanner;
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
          updatePlatformProvider.overrideWithValue(null),
          updateProvider.overrideWith(() => _ScriptedUpdates(updates)),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          historyFilesProvider.overrideWithValue(files),
          priceSourceProvider.overrideWithValue(_FixedPrice()),
          clockProvider.overrideWithValue(() => now),
          pushPlatformProvider.overrideWithValue(push),
          pushPostProvider.overrideWithValue((url, body, timeout) async {
            posts.add((url: url, body: body, timeout: timeout));
            return 204;
          }),
          qrScannerProvider.overrideWithValue(scanner),
          sharedFilesCleanupProvider.overrideWithValue(() async => cleanups++),
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
  Future<void> openSettingsNow(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> openSettings(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
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
      expect(defaults.autoLockMinutes, 5);

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

      final third = make();
      expect((await third.read(appSettingsProvider.future)).autoLockMinutes, 0);
      third.dispose();
    });
  });

  group('restore by date', () {
    test('estimates a height before the real one', () {
      // get_header on node.btlabs.uk: height 3,500,000 at 2026-04-21T08:33:26Z and
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
      final h = _Harness(advanced: true, sealed: false, walletExists: false);
      await h.pump(tester);
      await _tapText(tester, 'I already have a wallet: restore it');
      await _enter(tester, 'Recovery phrase', h.service.phrase);
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
        find.textContaining('the .wfeh file you shared or saved outside'),
        findsOneWidget,
      );

      h.files.picks.add(await h.session.exportHistory());
      await _tapText(tester, 'Import a history backup');
      expect(find.text('History imported'), findsOneWidget);
      await _tapText(tester, 'OK');
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
      await h.openSettings(tester);
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
      await h.openSettings(tester);
      expect(find.text('System default'), findsOneWidget);
      await _tapText(tester, 'Language');
      for (final language in appLanguages) {
        expect(find.text(language.name), findsOneWidget);
      }
      await _tapText(tester, 'Deutsch');
      expect(h.store.values['app.language'], 'de');
      expect(h.container.read(appSettingsProvider).value?.language, 'de');
      expect(app().locale, const Locale('de'));
    });
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
      h.now = h.now.add(const Duration(minutes: 5));
      await _return(tester);
      expect(h.container.read(sessionProvider), isNull);
      expect(h.updates.checks, 2);
      await h.unlock(tester);
      expect(h.updates.checks, 3);
    });

    testWidgets(
      'the notice shows once per opening, again after lock and unlock',
      (tester) async {
        final h = _Harness()..updates.offer = _update;
        await h.pump(tester);
        await h.unlock(tester);
        Finder notice() => find.descendant(
          of: find.byKey(noticeKey),
          matching: find.text('Version 1.6.1 is available.'),
        );
        expect(notice(), findsOneWidget);
        // Dismissed, it stays away until the next opening.
        await tester.tap(
          find.descendant(
            of: find.byKey(noticeKey),
            matching: find.byTooltip('Close'),
          ),
        );
        await tester.pumpAndSettle();
        expect(notice(), findsNothing);
        await tester.pump(const Duration(minutes: 10));
        expect(notice(), findsNothing);

        await _leave(tester);
        await _return(tester);
        expect(notice(), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byKey(noticeKey),
            matching: find.byTooltip('Close'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Lock wallet'));
        await tester.pumpAndSettle();
        expect(notice(), findsNothing);
        await h.unlock(tester);
        expect(notice(), findsOneWidget);
      },
    );

    testWidgets('an update puts a dot on Settings and a row at its top', (
      tester,
    ) async {
      final h = _Harness()
        ..updates.supported = true
        ..updates.offer = _update;
      await h.pump(tester);
      await h.unlock(tester);
      expect(find.byKey(settingsUpdateDotKey), findsOneWidget);
      expect(
        find.byTooltip('Settings: an update is available'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(settingsButtonKey));
      await tester.pumpAndSettle();
      final row = find.byKey(settingsUpdateRowKey);
      expect(
        find.descendant(of: row, matching: find.text('Update to 1.6.1')),
        findsOneWidget,
      );
      // Above every other row.
      final tiles = find.byType(ListTile);
      expect(tester.getTopLeft(tiles.first).dy, tester.getTopLeft(row).dy);
      await tester.tap(
        find.descendant(of: row, matching: find.text('Install')),
      );
      await tester.pumpAndSettle();
      expect(h.updates.installs, 1);

      // Without an update: no dot, no row.
      (h.container.read(updateProvider.notifier) as _ScriptedUpdates).set(
        const UpdateState(UpdatePhase.idle),
      );
      await tester.pumpAndSettle();
      expect(row, findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(settingsUpdateDotKey), findsNothing);
      expect(find.byTooltip('Settings'), findsOneWidget);
    });
  });

  group('auto-lock', () {
    testWidgets('locks after the timeout, not before', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);

      await _leave(tester);
      h.now = h.now.add(const Duration(minutes: 4));
      await _return(tester);
      expect(h.container.read(sessionProvider), isNotNull);

      await _leave(tester);
      h.now = h.now.add(const Duration(minutes: 5));
      await _return(tester);
      expect(h.container.read(sessionProvider), isNull);
      expect(find.text('Unlock wallet'), findsOneWidget);
    });

    testWidgets('never and immediately', (tester) async {
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
          .setAutoLockMinutes(0);
      await _leave(tester);
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

      await _leave(tester, settle: false);
      h.now = h.now.add(const Duration(minutes: 10));
      await _return(tester, settle: false);
      expect(h.container.read(sessionProvider), isNotNull);

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
      h.store.values['app.auto_lock'] = '0';
      await h.pump(tester);
      await h.unlock(tester);
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
      await h.openSettings(tester);
      await _tapText(tester, 'Change PIN');

      await _enter(tester, 'Current PIN', '000000');
      expect(find.textContaining('Wrong PIN'), findsOneWidget);
      await _enter(tester, 'Current PIN', _pin);
      await _enter(tester, 'PIN', '654321');
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
      // The dock closed and the content moved back up by its height.
      expect(tester.getSize(find.byType(NoticeDock)).height, 0);
      expect(
        tester.getTopLeft(find.text('Change PIN')),
        docked.translate(0, -dock),
      );
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
      await h.openSettings(tester);
      await _tapText(tester, 'Delete this wallet');

      FilledButton deleteButton() =>
          tester.widget(find.widgetWithText(FilledButton, 'Delete wallet'));
      expect(deleteButton().onPressed, isNull);
      await tester.tap(find.text('I have written down my recovery phrase'));
      await tester.pump();
      expect(deleteButton().onPressed, isNull);
      await _enter(tester, 'Type "delete" to confirm', 'delet');
      expect(deleteButton().onPressed, isNull);
      await _enter(tester, 'Type "delete" to confirm', 'delete');
      expect(deleteButton().onPressed, isNotNull);
      await tester.tap(find.text('Delete wallet'));
      await tester.pumpAndSettle();

      // Cancelling the PIN keeps the wallet.
      await _tapText(tester, 'Cancel');
      expect(h.service.deletedWallets, isEmpty);

      await _tapText(tester, 'Delete this wallet');
      await tester.tap(find.text('I have written down my recovery phrase'));
      await _enter(tester, 'Type "delete" to confirm', 'delete');
      await tester.tap(find.text('Delete wallet'));
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
      await h.openSettings(tester);

      await _reveal(tester, find.text('Back up recovery phrase'));
      await _tapText(tester, 'Export history backup');
      // Share comes first: the copy that matters is the one off this phone.
      expect(
        find.text(
          'History backups hold payments up to now. Export again after new '
          'payments.',
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Share')).dy <
            tester.getTopLeft(find.text('Save to device')).dy,
        isTrue,
      );
      await _tapText(tester, 'Save to device');
      expect(h.files.saved.single.name, 'epic-history-mainnet-20260930.wfeh');
      expect(h.files.saved.single.bytes, isNotEmpty);
      expect(
        find.text('Saved epic-history-mainnet-20260930.wfeh'),
        findsOneWidget,
      );

      await _tapText(tester, 'Export CSV');
      expect(find.textContaining('not encrypted'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Export CSV'));
      await tester.pumpAndSettle();
      await _tapText(tester, 'Share');
      expect(h.files.shared.single.name, 'epic-history-mainnet-20260930.csv');
      expect(h.files.saved, hasLength(1));

      h.files.picks.add(h.files.saved.first.bytes);
      await _tapText(tester, 'Import history backup');
      expect(find.text('History imported'), findsOneWidget);
      await _tapText(tester, 'OK');

      // A cancelled pick does nothing.
      await _tapText(tester, 'Import history backup');
      expect(find.text('History imported'), findsNothing);

      h.session.importError = const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'This history file belongs to a different wallet',
      );
      h.files.picks.add(Uint8List.fromList([1, 2, 3]));
      await _tapText(tester, 'Import history backup');
      // An error notice, not a dialog.
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(noticeKey),
          matching: find.text(
            'Could not import the history backup. '
            'This history file belongs to a different wallet.',
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
      await h.openSettings(tester);
      await _tapText(tester, 'Export history backup');
      expect(find.text('Share'), findsNothing);
      expect(h.files.saved.single.name, 'epic-history-mainnet-20260930.wfeh');
    });

    testWidgets('dismissing the choice exports nothing', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      await _tapText(tester, 'Export history backup');
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();
      expect(h.files.saved, isEmpty);
      expect(h.files.shared, isEmpty);
    });

    test('describes the import counts in words', () {
      expect(
        describeImport(
          englishStrings,
          const ImportReport(merged: 2, added: 1, skipped: 0, contactsAdded: 1),
        ),
        '2 payments got their details back, '
        '1 older payment added, 1 contact added.',
      );
      expect(
        describeImport(
          englishStrings,
          const ImportReport(merged: 0, added: 0, skipped: 3, contactsAdded: 0),
        ),
        '3 records were already here.',
      );
      expect(
        describeImport(
          englishStrings,
          const ImportReport(merged: 0, added: 0, skipped: 0, contactsAdded: 0),
        ),
        'The backup held nothing new.',
      );
    });
  });

  group('wallet', () {
    testWidgets('rescans from a height or the whole chain', (tester) async {
      final h = _Harness(advanced: true);
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);

      await _tapText(tester, 'Rescan the chain');
      await _tapText(tester, 'From a block height');
      await _tapText(tester, 'Rescan');
      expect(find.text('Enter a block height of 1 or more.'), findsOneWidget);
      await _enter(tester, 'Start height', '3000000');
      await _tapText(tester, 'Rescan');
      expect(h.session.lastStart, BigInt.from(3000000));

      await _tapText(tester, 'Rescan the chain');
      await _tapText(tester, 'The whole chain');
      await _tapText(tester, 'Rescan');
      expect(h.session.lastStart, BigInt.one);
      expect(h.session.scanCalls, 2);
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
      await h.openSettingsNow(tester);
      final tile = find.text('Delete this wallet');
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(tile);
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

  group('notifications', () {
    const relay = 'esPushKey@flooepicbox.btlabs.uk';

    Finder row() => find.byKey(settingsPushKey);

    Future<void> tapRow(WidgetTester tester) async {
      await _reveal(tester, row());
      await tester.tap(row());
      await tester.pumpAndSettle();
    }

    Future<void> turnOn(WidgetTester tester) async {
      await tapRow(tester);
      await tester.tap(find.text(englishStrings.pushConfirmAction));
      await tester.pumpAndSettle();
    }

    testWidgets('are off by default; turning on asks first and Cancel keeps them off', (
      tester,
    ) async {
      final h = _Harness();
      h.session.address = relay;
      await h.pump(tester);
      await h.unlock(tester);
      expect(h.push.starts, 0);
      await h.openSettings(tester);
      // The label alone, with its explanation behind the info icon, and no state line.
      await _reveal(tester, row());
      expect(
        find.descendant(of: row(), matching: find.text('Notifications')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row(),
          matching: find.byTooltip(
            'A notice when a payment is waiting. Off while Tor is on.',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.widget<SwitchListTile>(row()).subtitle, isNull);

      await tapRow(tester);
      expect(find.text('Turn on notifications?'), findsOneWidget);
      expect(
        find.text(
          'Notifications go through Google’s service. They never include amounts, addresses or names.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(h.push.starts, 0);
      expect(h.store.values['app.push'], isNot('true'));
      expect(h.posts, isEmpty);
      expect(tester.widget<SwitchListTile>(row()).value, isFalse);
    });

    testWidgets('Turn on registers; turning off unregisters, drops the token and says so', (
      tester,
    ) async {
      final h = _Harness();
      h.session.address = relay;
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      await turnOn(tester);
      expect(h.push.starts, 1);
      expect(h.store.values['app.push'], 'true');
      expect(tester.widget<SwitchListTile>(row()).value, isTrue);
      expect(h.posts, hasLength(1));
      expect(h.posts.single.url.toString(),
          'https://flooepicbox.btlabs.uk/push/v1/register');
      final body = jsonDecode(h.posts.single.body) as Map<String, dynamic>;
      expect(body['address'], relay);
      expect(body['token'], 'token');
      final stamp = h.now.millisecondsSinceEpoch ~/ 1000;
      expect(body['timestamp'], stamp);
      expect(body['signature'], 'sig:register:token:$stamp');
      expect(h.session.pushSignatures.single.action, 'register');

      await tapRow(tester);
      expect(h.store.values['app.push'], 'false');
      expect(h.posts, hasLength(2));
      expect(h.posts.last.url.path, '/push/v1/unregister');
      expect(h.push.deleted, 1);
      expect(
        find.descendant(
          of: find.byKey(noticeKey),
          matching: find.text('Notifications off'),
        ),
        findsOneWidget,
      );
      expect(tester.widget<SwitchListTile>(row()).value, isFalse);
    });

    testWidgets('turn back off and say so when the system blocks them', (
      tester,
    ) async {
      final h = _Harness();
      h.push.permitted = false;
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      expect(find.text(englishStrings.settingsPushBlocked), findsNothing);
      await turnOn(tester);
      expect(h.push.starts, 1);
      expect(h.store.values['app.push'], 'false');
      expect(find.text(englishStrings.settingsPushBlocked), findsOneWidget);
      expect(tester.widget<SwitchListTile>(row()).value, isFalse);
      expect(h.posts, isEmpty);

      // Allowed now: turning them on asks again and the warning goes.
      h.push.permitted = true;
      await turnOn(tester);
      expect(h.push.starts, 2);
      expect(h.store.values['app.push'], 'true');
      expect(find.text(englishStrings.settingsPushBlocked), findsNothing);
    });

    testWidgets('turn back off and say so when Firebase fails to start', (
      tester,
    ) async {
      final h = _Harness();
      h.push.failure = Exception('no Firebase options');
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      await turnOn(tester);
      expect(h.push.starts, 1);
      expect(h.store.values['app.push'], 'false');
      expect(find.text(englishStrings.settingsPushUnavailable), findsOneWidget);
      expect(find.text(englishStrings.settingsPushBlocked), findsNothing);
    });

    testWidgets('turn off at unlock when Firebase fails to start', (
      tester,
    ) async {
      final h = _Harness();
      h.push.failure = Exception('no Firebase options');
      h.store.values['app.push'] = 'true';
      await h.pump(tester);
      expect(h.push.starts, 0, reason: 'nothing before the wallet opens');
      await h.unlock(tester);
      expect(h.push.starts, 1);
      expect(h.store.values['app.push'], 'false');
    });

    testWidgets('are not offered in a build without Firebase configuration', (
      tester,
    ) async {
      final h = _Harness();
      h.push.configuredBuild = false;
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      expect(row(), findsNothing);
      expect(find.text('Notifications'), findsNothing);
      expect(h.push.starts, 0);
    });

    testWidgets('start and register after each unlock when saved on', (
      tester,
    ) async {
      final h = _Harness();
      h.session.address = relay;
      h.store.values['app.push'] = 'true';
      await h.pump(tester);
      expect(h.push.starts, 0);
      await h.unlock(tester);
      expect(h.push.starts, 1);
      expect(h.posts.map((p) => p.url.path), ['/push/v1/register']);
    });

    testWidgets('the one-time reminder comes a minute after unlock, once', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await tester.pump(const Duration(seconds: 59));
      expect(find.byKey(noticeKey), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(noticeKey),
          matching: find.text('Notifications are available in Settings.'),
        ),
        findsOneWidget,
      );
      expect(h.store.values['app.push_hint_shown'], 'true');
    });

    testWidgets('no reminder once it was shown', (tester) async {
      final h = _Harness();
      h.store.values['app.push_hint_shown'] = 'true';
      await h.pump(tester);
      await h.unlock(tester);
      await tester.pump(const Duration(seconds: 90));
      await tester.pumpAndSettle();
      expect(find.byKey(noticeKey), findsNothing);
    });

    testWidgets('no reminder when they are on', (tester) async {
      final h = _Harness();
      h.store.values['app.push'] = 'true';
      await h.pump(tester);
      await h.unlock(tester);
      await tester.pump(const Duration(seconds: 90));
      await tester.pumpAndSettle();
      expect(find.byKey(noticeKey), findsNothing);
      expect(h.store.values['app.push_hint_shown'], isNull);
    });
  });

  testWidgets('Contacts opens the contact list for editing, not the picker', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await h.unlock(tester);
    await h.openSettings(tester);
    await _tapText(tester, 'Contacts');
    final screen = tester.widget<ContactsScreen>(find.byType(ContactsScreen));
    expect(screen.pick, isFalse);
  });

  group('invoices', () {
    // A valid epicbox address with a key made of [c].
    String addr(String c) => '${'es$c'.padRight(52, c)}@epicbox.epiccash.com';
    final shop = addr('S');
    final exchange = addr('X');

    Future<_Harness> openInvoices(
      WidgetTester tester, {
      bool advanced = false,
      bool scanSupported = false,
      Future<void> Function(_Harness h)? before,
    }) async {
      final h = _Harness(advanced: advanced, scanSupported: scanSupported);
      await h.pump(tester);
      await h.unlock(tester);
      await before?.call(h);
      await h.openSettings(tester);
      await _tapText(tester, 'Invoice address and trusted services');
      expect(find.byType(InvoiceSettingsScreen), findsOneWidget);
      return h;
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
      await h.openSettings(tester);
      // The section would sit between History and Wallet.
      await _reveal(tester, find.text('Import history backup'));
      expect(find.text('Contacts'), findsOneWidget);
      expect(find.text('Invoices'), findsNothing);
      expect(find.text('Invoice address and trusted services'), findsNothing);
    });

    testWidgets('the section shows on a core with invoices', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      await _reveal(tester, find.text('Import history backup'));
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Invoice address and trusted services'), findsOneWidget);
    });

    testWidgets('shows the invoice address as a QR code and copies it', (
      tester,
    ) async {
      final h = await openInvoices(tester);
      final address = FakeWalletSession.fakeInvoiceAddress(
        h.session.invoiceHistory.invoiceIndex,
      );
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
      expect(find.byType(PrettyQrView), findsOneWidget);
      expect(
        find.bySemanticsLabel('QR code of your invoice address'),
        findsOneWidget,
      );
      // Not the payments address: services get their own.
      expect(address, isNot(h.session.address));
      await _tapText(tester, 'Copy');
      expect(copied, [
        {'text': address},
      ]);
      expect(notice('Invoice address copied.'), findsOneWidget);
    });

    testWidgets('adding explains what it allows, then saves a valid address', (
      tester,
    ) async {
      final h = await openInvoices(tester);
      expect(
        find.text(englishStrings.invoiceSettingsNoServices),
        findsOneWidget,
      );
      await _tapText(tester, 'Add a service');
      expect(
        find.text(englishStrings.invoiceSettingsAddExplanation),
        findsOneWidget,
      );
      // Two sentences: what it allows, and that each invoice still needs approval.
      final explanation = englishStrings.invoiceSettingsAddExplanation;
      expect('.'.allMatches(explanation).length, 2);
      expect(explanation, contains('approve each invoice'));

      await _enter(tester, 'Name', 'Shop');
      await _enter(tester, "The service's epicbox address", '  $shop ');
      await _tapText(tester, 'Add service');
      expect(find.byType(TrustedServiceAddScreen), findsNothing);
      expect(h.session.allowlist, [shop]);
      // The fake dates the entry when it is added (TrustedService.since).
      expect(
        [for (final t in await h.session.trustedServices()) (t.address, t.label)],
        [(shop, 'Shop')],
      );
      expect(find.text('Shop'), findsOneWidget);
      expect(notice('Shop can now send you invoices.'), findsOneWidget);
      // Adding never paid anything.
      expect(h.session.invoicePayments, 0);
    });

    testWidgets('a scanned address fills the field', (tester) async {
      final h = await openInvoices(tester, scanSupported: true);
      await _tapText(tester, 'Add a service');
      h.scanner.codes.add(exchange);
      await tester.tap(find.byTooltip('Scan QR code'));
      await tester.pumpAndSettle();
      expect(find.text(exchange), findsOneWidget);
      await _enter(tester, 'Name', 'Exchange');
      await _tapText(tester, 'Add service');
      expect(h.session.allowlist, [exchange]);
    });

    testWidgets('refuses a missing name, an invalid address and its own', (
      tester,
    ) async {
      final own = addr('W');
      final h = await openInvoices(
        tester,
        before: (h) async => h.session.address = own,
      );
      await _tapText(tester, 'Add a service');
      await _tapText(tester, 'Add service');
      expect(find.text('Give the service a name.'), findsOneWidget);
      expect(
        find.text('Paste or scan the address the service shows.'),
        findsOneWidget,
      );

      await _enter(tester, 'Name', 'Shop');
      await _enter(tester, "The service's epicbox address", 'esShop@nowhere');
      await _tapText(tester, 'Add service');
      expect(
        find.text(
          englishStrings.contactsAddressInvalid('es5x…@epicbox.epiccash.com'),
        ),
        findsOneWidget,
      );
      // A wallet URL is no service address either.
      await _enter(
        tester,
        "The service's epicbox address",
        'http://203.0.113.5:3415',
      );
      await _tapText(tester, 'Add service');
      expect(
        find.text(
          englishStrings.contactsAddressInvalid('es5x…@epicbox.epiccash.com'),
        ),
        findsOneWidget,
      );
      // The wallet's own address passes the format check; the core refuses it.
      await _enter(tester, "The service's epicbox address", own);
      await _tapText(tester, 'Add service');
      expect(find.byType(TrustedServiceAddScreen), findsOneWidget);
      expect(find.byType(ErrorText), findsOneWidget);
      expect(h.session.allowlist, isEmpty);
    });

    testWidgets('removing asks first', (tester) async {
      final h = await openInvoices(
        tester,
        before: (h) =>
            h.session.addTrustedService(address: shop, label: 'Shop'),
      );
      expect(find.text('Shop'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove Shop'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Shop?'), findsOneWidget);
      expect(
        find.text(englishStrings.invoiceSettingsRemoveBody),
        findsOneWidget,
      );
      await _tapText(tester, 'Keep');
      expect(h.session.allowlist, [shop]);
      expect(find.text('Shop'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove Shop'));
      await tester.pumpAndSettle();
      await _tapText(tester, 'Remove');
      expect(h.session.allowlist, isEmpty);
      expect(await h.session.trustedServices(), isEmpty);
      expect(find.byTooltip('Remove Shop'), findsNothing);
      expect(notice('Shop can no longer send you invoices.'), findsOneWidget);
    });

    testWidgets('rotation and the dropped count are hidden without Advanced', (
      tester,
    ) async {
      await openInvoices(tester);
      expect(find.text('Get a new invoice address'), findsNothing);
      expect(find.textContaining('Dropped from unknown senders'), findsNothing);
    });

    testWidgets(
      'Advanced rotates after a confirm and shows the dropped count',
      (tester) async {
        final h = await openInvoices(tester, advanced: true);
        final first = FakeWalletSession.fakeInvoiceAddress(1);
        // Advanced shows the full address.
        expect(find.text(first), findsOneWidget);
        await _reveal(
          tester,
          find.text('Dropped from unknown senders this session: 0'),
        );
        h.container.read(droppedInvoiceMessagesProvider.notifier).add(3);
        await tester.pumpAndSettle();
        await _reveal(
          tester,
          find.text('Dropped from unknown senders this session: 3'),
        );

        await _tapText(tester, 'Get a new invoice address');
        expect(find.text('Get a new invoice address?'), findsOneWidget);
        expect(
          find.text(englishStrings.invoiceSettingsRotateBody),
          findsOneWidget,
        );
        await _tapText(tester, 'Keep');
        expect(h.session.invoiceHistory.invoiceIndex, 1);

        await _tapText(tester, 'Get a new invoice address');
        await _tapText(tester, 'Get new address');
        expect(h.session.invoiceHistory.invoiceIndex, 2);
        expect(
          notice('New invoice address ready. Give it to your services.'),
          findsOneWidget,
        );
        await _reveal(
          tester,
          find.text(FakeWalletSession.fakeInvoiceAddress(2)),
        );
        expect(find.text(first), findsNothing);
      },
    );
  });

  group('about', () {
    testWidgets('Licences opens the licence page with the bundled tor in it', (
      tester,
    ) async {
      registerTorLicence();
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
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
      expect(find.textContaining('tor 0.4.9.14, unmodified'), findsOneWidget);
      await _reveal(tester, find.byKey(licencesFullKey));
      await tester.tap(find.byKey(licencesFullKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.text('Epic Wallet'), findsWidgets);
      // British, like the row and the rest of the app.
      expect(find.text('Licences'), findsOneWidget);
      expect(find.text('Licenses'), findsNothing);
      // The registry reads the licences on real async.
      for (var i = 0; i < 50 && find.text('tor').evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(find.text('tor'), findsOneWidget);
    });
  });

  group('wording', () {
    testWidgets('says where prices come from when they are turned on', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
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
      await h.openSettings(tester);
      for (final title in [
        'Back up recovery phrase',
        'Export history backup',
        'Export CSV',
        'Import history backup',
        'Contacts',
        'Rescan the chain',
        'Delete this wallet',
      ]) {
        await _reveal(tester, find.text(title));
        final tile = tester.widget<ListTile>(
          find.widgetWithText(ListTile, title),
        );
        expect(tile.subtitle, isNull, reason: title);
      }
      await _reveal(tester, find.text('Epicbox server'));
      expect(find.textContaining('relay'), findsNothing);
      expect(find.textContaining('Relay'), findsNothing);
      expect(find.textContaining('ailbox'), findsNothing);
    });

    testWidgets('network settings call the relay an epicbox server', (
      tester,
    ) async {
      final h = _Harness(advanced: true);
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      await _tapText(tester, 'Network and node');
      await _reveal(tester, find.text('Epicbox server'));
      expect(find.text('Epicbox server'), findsOneWidget);
      // An empty field offers no use button, so it does not look confirmed.
      expect(find.byTooltip('Use this server'), findsNothing);
      // _NoRelays lists nothing, so there is no health source line either.
      expect(
        find.text('Health from status.btlabs.uk, measured from its server.'),
        findsNothing,
      );
      await _enter(
        tester,
        'Other epicbox server (host or host:port)',
        'mail.example.com',
      );
      await tester.tap(find.byTooltip('Use this server'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Changing the epicbox server changes your address'),
        findsOneWidget,
      );
      expect(find.textContaining('relay'), findsNothing);
      expect(find.textContaining('ailbox'), findsNothing);
    });
  });

  group('network', () {
    testWidgets('test connection shows the node height and version', (
      tester,
    ) async {
      final h = _Harness(advanced: true);
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      await _tapText(tester, 'Network and node');
      expect(find.text('The real Epic Cash network.'), findsOneWidget);
      await _tapText(tester, 'Test connection');
      expect(
        find.text(
          'Connected. The node is at block 2,500,000, running version 3.6.0.',
        ),
        findsOneWidget,
      );
      // Back up to the node field, above the relay list.
      await tester.drag(find.byType(Scrollable).last, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await _enter(tester, 'Node URL', 'not a url');
      await _tapText(tester, 'Test connection');
      await tester.drag(find.byType(Scrollable).last, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter a full URL'), findsOneWidget);
    });
  });

  group('advanced options', () {
    /// Every text in the Settings list, built by scrolling it from top to bottom.
    Future<Set<String>> settingsTexts(WidgetTester tester) async {
      final seen = <String>{};
      final list = find.byType(Scrollable).last;
      await tester.drag(list, const Offset(0, 20000));
      await tester.pumpAndSettle();
      for (var i = 0; i < 20; i++) {
        seen.addAll(
          tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? ''),
        );
        await tester.drag(list, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      await tester.drag(list, const Offset(0, 20000));
      await tester.pumpAndSettle();
      return seen;
    }

    testWidgets('the switch shows network, node, relay and rescan, and is '
        'saved', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);

      final off = await settingsTexts(tester);
      for (final hidden in ['Rescan the chain', 'Epicbox server']) {
        expect(off, isNot(contains(hidden)), reason: hidden);
      }
      // Kept: the connection is for everyone (the status card on Home opens the same
      // pickers), the Home backup reminder points at the exports, and help is for everyone.
      for (final kept in [
        'Network and node',
        'Network',
        'Export history backup',
        'Export CSV',
        'Import history backup',
        'Help',
        'Send feedback',
        'Advanced options',
      ]) {
        expect(off, contains(kept), reason: kept);
      }

      await _tapText(tester, 'Advanced options');
      expect(h.store.values['app.advanced'], 'true');
      final on = await settingsTexts(tester);
      for (final shown in [
        'Network and node',
        'Rescan the chain',
        'Network',
        'Epicbox server',
      ]) {
        expect(on, contains(shown), reason: shown);
      }

      await _tapText(tester, 'Advanced options');
      expect(h.store.values['app.advanced'], 'false');
      expect(await settingsTexts(tester), isNot(contains('Rescan the chain')));
    });

    testWidgets(
      'restore scans the whole chain and offers no start without it',
      (tester) async {
        final h = _Harness(sealed: false, walletExists: false);
        await h.pump(tester);
        // The network choice shows without Advanced too, so a new install can reach floonet.
        // By its semantics label, as label or icon: network_settings_button_test.dart checks
        // which form shows, with the real faces.
        expect(find.bySemanticsLabel('Network settings'), findsOneWidget);
        await _tapText(tester, 'I already have a wallet: restore it');
        expect(find.text('Where to start scanning'), findsNothing);
        expect(find.text('Pick the date you created the wallet'), findsNothing);
        expect(find.text('Block height'), findsNothing);
        await _enter(tester, 'Recovery phrase', h.service.phrase);
        await _tapText(tester, 'Continue');
        await _enter(tester, 'PIN', _pin);
        await _enter(tester, 'Repeat PIN', _pin);
        expect(h.session.scanCalls, 1);
        // No start height: the core scans a restored wallet from block 1.
        expect(h.session.lastStart, isNull);
      },
    );

    testWidgets('restore and first run offer the choices with it', (
      tester,
    ) async {
      final h = _Harness(sealed: false, walletExists: false, advanced: true);
      await h.pump(tester);
      expect(find.bySemanticsLabel('Network settings'), findsOneWidget);
      await _tapText(tester, 'I already have a wallet: restore it');
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
