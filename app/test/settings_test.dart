import 'dart:async';
import 'dart:typed_data';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/restore_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _mainnetDir = '/fake/wallets/mainnet';
const _password = 'correct horse';
const _pin = '123456';

class _FakePush implements PushPlatform {
  int starts = 0;
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
  Stream<ScanProgress> scan({BigInt? startHeight}) {
    lastStart = startHeight;
    final c = controller;
    return c == null ? super.scan(startHeight: startHeight) : c.stream;
  }
}

class _Harness {
  _Harness({bool sealed = true, bool walletExists = true}) {
    if (sealed) {
      store.values['wallet.mainnet.sealed'] = 'sealed|$_pin|$_password';
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
          vaultCryptoProvider.overrideWithValue(FakeVaultCrypto()),
          updatePlatformProvider.overrideWithValue(null),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          historyFilesProvider.overrideWithValue(files),
          priceSourceProvider.overrideWithValue(_FixedPrice()),
          clockProvider.overrideWithValue(() => now),
          pushPlatformProvider.overrideWithValue(push),
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
      final h = _Harness(sealed: false, walletExists: false);
      await h.pump(tester);
      await _tapText(tester, 'I already have a wallet: restore it');
      await _enter(tester, 'Recovery phrase', h.service.phrase);
      await _tapText(tester, 'Pick the date you created the wallet');
      // The picker opens on today; pick the 1st of this month.
      await tester.tap(find.text('1'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('From 1 Sep 2026'), findsOneWidget);
      await _tapText(tester, 'Continue');
      await _enter(tester, 'PIN', _pin);
      await _enter(tester, 'Repeat PIN', _pin);

      final dayStart = DateTime(2026, 9, 1);
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

      expect(find.text('PIN changed'), findsOneWidget);
      expect(
        h.store.values['wallet.mainnet.sealed'],
        'sealed|654321|$_password',
      );
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
      expect(h.store.values['wallet.mainnet.sealed'], isNull);
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
      expect(find.text('Could not import'), findsOneWidget);
      expect(
        find.text('This history file belongs to a different wallet.'),
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
          const ImportReport(merged: 2, added: 1, skipped: 0, contactsAdded: 1),
        ),
        '2 payments got their details back, '
        '1 older payment added, 1 contact added.',
      );
      expect(
        describeImport(
          const ImportReport(merged: 0, added: 0, skipped: 3, contactsAdded: 0),
        ),
        '3 records were already here.',
      );
      expect(
        describeImport(
          const ImportReport(merged: 0, added: 0, skipped: 0, contactsAdded: 0),
        ),
        'The backup held nothing new.',
      );
    });
  });

  group('wallet', () {
    testWidgets('rescans from a height or the whole chain', (tester) async {
      final h = _Harness();
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
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(deleteDuringScanMessage), findsOneWidget);
      expect(find.byType(DeleteWalletDialog), findsNothing);
      expect(h.service.deletedWallets, isEmpty);
      await h.session.controller!.close();
      await tester.pumpAndSettle();
    });
  });

  group('payment notifications', () {
    testWidgets('are off by default and start only when turned on', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      expect(h.push.starts, 0);
      await h.openSettings(tester);
      expect(find.text(pushNotificationsHint), findsOneWidget);
      await _tapText(tester, 'Payment notifications');
      expect(h.push.starts, 1);
      expect(h.store.values['app.push'], 'true');
      expect(find.text(pushNotificationsOnMessage), findsOneWidget);
      await _tapText(tester, 'Payment notifications');
      expect(h.store.values['app.push'], 'false');
      expect(
        find.text('Notifications stop the next time the app starts.'),
        findsOneWidget,
      );
      expect(h.push.starts, 1);
    });

    testWidgets('turn back off and say so when the system blocks them', (
      tester,
    ) async {
      final h = _Harness();
      h.push.permitted = false;
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      expect(find.text(pushBlockedMessage), findsNothing);
      await _tapText(tester, 'Payment notifications');
      expect(h.push.starts, 1);
      expect(h.store.values['app.push'], 'false');
      expect(find.text(pushBlockedMessage), findsOneWidget);
      final toggle = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Payment notifications'),
      );
      expect(toggle.value, isFalse);

      // Allowed now: turning them on asks again and the warning goes.
      h.push.permitted = true;
      await _tapText(tester, 'Payment notifications');
      expect(h.push.starts, 2);
      expect(h.store.values['app.push'], 'true');
      expect(find.text(pushBlockedMessage), findsNothing);
    });

    testWidgets('turn back off and say so when Firebase fails to start', (
      tester,
    ) async {
      final h = _Harness();
      h.push.failure = Exception('no Firebase options');
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      await _tapText(tester, 'Payment notifications');
      expect(h.push.starts, 1);
      expect(h.store.values['app.push'], 'false');
      expect(find.text(pushUnavailableMessage), findsOneWidget);
      expect(find.text(pushBlockedMessage), findsNothing);
    });

    testWidgets('turn off at launch when Firebase fails to start', (
      tester,
    ) async {
      final h = _Harness();
      h.push.failure = Exception('no Firebase options');
      h.store.values['app.push'] = 'true';
      await h.pump(tester);
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
      expect(find.text('Payment notifications'), findsNothing);
      expect(find.text('Notifications'), findsNothing);
    });

    testWidgets('start at launch when saved on', (tester) async {
      final h = _Harness();
      h.store.values['app.push'] = 'true';
      await h.pump(tester);
      expect(h.push.starts, 1);
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

  group('wording', () {
    testWidgets('says where prices come from when they are turned on', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      expect(find.text(pricesOnMessage), findsNothing);
      await _tapText(tester, 'Show prices');
      expect(h.store.values['app.show_fiat'], 'false');
      expect(find.text(pricesOnMessage), findsNothing);
      await _tapText(tester, 'Show prices');
      expect(find.text(pricesOnMessage), findsOneWidget);
    });

    testWidgets('lists settings without explanations', (tester) async {
      final h = _Harness();
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
      final h = _Harness();
      await h.pump(tester);
      await h.unlock(tester);
      await h.openSettings(tester);
      await _tapText(tester, 'Network and node');
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
      final h = _Harness();
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
      await _enter(tester, 'Node URL', 'not a url');
      await _tapText(tester, 'Test connection');
      expect(find.textContaining('Enter a full URL'), findsOneWidget);
    });
  });
}
