import 'package:epic_wallet/src/dist_build.dart' show distStore;
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/desktop/data/desk_update.dart';
import 'package:epic_wallet/src/desktop/data/files.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_about.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_frame.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart' show projectRepoPublic;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/btlabs_public.dart' show ManifestState;
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/updater.dart' show updateKeyringProvider, updateStateKey;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/signed_update.dart';

void main() {
  final now = DateTime(2026, 10, 22, 12);

  // Signed manifests (test key A; the test keyring stands in for the bundled one).
  const page = 'https://github.com/BTLabs-EPIC/epic-wallet/releases/tag/v26.10.1';
  late String newer, same, phoneOnly, offAccounts, unsignedNewer, forgedNewer, olderLatest, testBuild;
  // A version newer than any this app will carry, so the tests hold whatever the app's version is.
  const next = '99.1.0';
  setUpAll(() async {
    newer = await signedUpdate(testUpdatePayload(versionName: '9.0.0', desktop: {'version': next, 'page': page}));
    same = await signedUpdate(testUpdatePayload(versionName: '9.0.0', desktop: {'version': deskAppVersion}, serial: 1790000100));
    phoneOnly = await signedUpdate(testUpdatePayload(versionName: '0.2.0'));
    // The verifier's schema only takes pages on the project's GitHub accounts, so a page
    // elsewhere is a manifest that does not verify, not one that opens a fallback.
    offAccounts = await signedUpdate(testUpdatePayload(desktop: {'version': next, 'page': 'https://github.com.evil.example/BTLabs-EPIC/'}));
    unsignedNewer = '{"versionName": "9.0.0", "desktop": {"version": "$next", "page": "$page"}}';
    forgedNewer = await signedUpdate(testUpdatePayload(desktop: {'version': next, 'page': page}), keys: [await testUpdateStrangerKey()]);
    // Older than [newer] (a replay): it says this version is the latest, which must not win.
    olderLatest = await signedUpdate(testUpdatePayload(desktop: {'version': deskAppVersion}, serial: 1789999000));
    testBuild = await signedUpdate(testUpdatePayload(desktop: {'version': '$next-rc1', 'page': page}));
  });

  Future<(ProviderContainer, List<String>)> pump(WidgetTester tester, ManifestFetch fetch, {Widget? home}) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <String>[];
    final container = ProviderContainer(overrides: [
      deskManifestFetchProvider.overrideWithValue(fetch),
      deskUpdateClockProvider.overrideWithValue(() => now),
      updateKeyringProvider.overrideWithValue(testUpdateKeyring),
      deskOpenUrlProvider.overrideWithValue((url) async {
        opened.add(url);
        return true;
      }),
    ]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: home ?? const Scaffold(body: SettingsAboutScreen())),
    ));
    await tester.pumpAndSettle();
    return (container, opened);
  }

  testWidgets('windows-02: no link to the source repository while it is private', (tester) async {
    await pump(tester, (_) async => (200, newer));
    expect(projectRepoPublic, isFalse);
    expect(find.text('Source code'), findsNothing);
    expect(find.textContaining('wallet-for-epic'), findsNothing);
    expect(find.textContaining('code is on GitHub'), findsNothing);
    expect(find.textContaining('Apache-2.0'), findsWidgets, reason: 'the licence line stays');
  });

  // Run also with --dart-define=WFE_DIST=msstore (https://docs.btlabs.uk/developers/build/variants/).
  testWidgets('a store build names its store and has no Updates group', (tester) async {
    await pump(tester, (_) async => (200, newer));
    final from = find.byKey(const ValueKey('about-updates-from'));
    if (distStore == null) {
      expect(from, findsNothing);
    } else {
      expect(find.text('Updates come from $distStore.'), findsOneWidget);
      expect(find.byKey(const ValueKey('about-update-act')), findsNothing);
      expect(find.text('Check now'), findsNothing);
    }
  });

  testWidgets('About shows the contact address', (tester) async {
    await pump(tester, (_) async => (200, newer));
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('support@btlabs.uk'), findsOneWidget);
  });

  test('versions compare by number', () {
    expect(isNewerVersion('0.1.1', '0.1.0'), isTrue);
    expect(isNewerVersion('0.1.10', '0.1.9'), isTrue);
    expect(isNewerVersion('0.1.0', '0.1.0'), isFalse);
    expect(isNewerVersion('0.1.0+3', '0.1.0'), isFalse);
    expect(isNewerVersion('0.0.9', '0.1.0'), isFalse);
    // Calendar versions (https://docs.btlabs.uk/developers/releases/) after the 0.1.x releases.
    expect(isNewerVersion('26.10.0', '0.1.1'), isTrue);
    expect(isNewerVersion('0.1.1', '26.10.0'), isFalse);
    expect(isNewerVersion('26.10.1', '26.10.0'), isTrue);
    expect(isNewerVersion('26.11.0', '26.10.9'), isTrue);
    expect(isNewerVersion('27.1.0', '26.12.3'), isTrue);
    expect(isNewerVersion('26.10.0', '26.10.0 (abc1234)'), isFalse);
    // A test build is never offered, and its release is newer than it.
    expect(isNewerVersion('26.10.1-rc1', '26.10.0'), isFalse);
    expect(isNewerVersion('26.10.0', '26.10.0-rc2'), isTrue);
    expect(isNewerVersion('26.10.0-rc2', '26.10.0-rc1'), isFalse);
  });

  testWidgets('a test build in the manifest is not offered', (tester) async {
    await pump(tester, (_) async => (200, testBuild));
    expect(find.text('$deskAppVersion is the latest'), findsOneWidget);
  }, skip: !inAppUpdates);

  testWidgets('Community opens Telegram and epiccash.com in the browser', (tester) async {
    final (_, opened) = await pump(tester, (_) async => (404, ''));
    await tester.tap(find.widgetWithText(EButton, 'Open').first);
    await tester.tap(find.widgetWithText(EButton, 'Open').at(1));
    await tester.pumpAndSettle();
    expect(opened, ['https://t.me/EpicCash', 'https://epiccash.com']);
    expect(find.text('Telegram'), findsOneWidget);
  });

  testWidgets('Licences: one line per component, the tor source note, and View opens the full texts', (tester) async {
    await pump(tester, (_) async => (404, ''));
    expect(find.text('Licences'), findsOneWidget);
    expect(find.textContaining('Tor: GNU General Public License, version 3.'), findsOneWidget);
    expect(find.textContaining('LEPIC, the Epic Cash wallet library: Apache 2.0'), findsOneWidget);
    expect(find.textContaining('Flutter and its Dart packages'), findsOneWidget);
    expect(find.textContaining('tor 0.4.9.14, unmodified'), findsOneWidget, reason: 'the GPL notice with the source');
    expect(find.text('Credits'), findsNothing);
    await tester.ensureVisible(find.widgetWithText(EButton, 'View'));
    await tester.tap(find.widgetWithText(EButton, 'View'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  }, skip: !torBuilt);

  testWidgets('no manifest published: no update and no error; Check now asks again', (tester) async {
    var calls = 0;
    await pump(tester, (_) async {
      calls++;
      return (404, 'Not Found');
    });
    expect(find.text('$deskAppVersion is the latest'), findsOneWidget);
    expect(find.text('Could not check'), findsNothing);
    await tester.tap(find.widgetWithText(EButton, 'Check now'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  }, skip: !inAppUpdates);

  testWidgets('a newer version: About says so and offers it; the same version is the latest', (tester) async {
    final (container, opened) = await pump(tester, (_) async => (200, newer));
    expect(find.text('Update available: $next'), findsOneWidget);
    // No installer or AppImage under test: this copy cannot install it, so the page, and why.
    expect(find.textContaining('This copy cannot install updates itself.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('about-update-act')));
    await tester.pumpAndSettle();
    expect(opened, [page], reason: 'this copy installs nothing itself: the button opens the page');

    container.updateOverrides([
      deskManifestFetchProvider.overrideWithValue((_) async => (200, same)),
      deskUpdateClockProvider.overrideWithValue(() => now),
      updateKeyringProvider.overrideWithValue(testUpdateKeyring),
      deskOpenUrlProvider.overrideWithValue((_) async => true),
    ]);
    await tester.tap(find.widgetWithText(EButton, 'Check now'));
    await tester.pumpAndSettle();
    expect(find.text('$deskAppVersion is the latest'), findsOneWidget);
  }, skip: !inAppUpdates);

  testWidgets("the phone's manifest alone offers nothing to the desktop", (tester) async {
    await pump(tester, (_) async => (200, phoneOnly));
    expect(find.text('Could not check'), findsOneWidget);
    expect(find.text('No desktop update information is published yet. Checked just now.'), findsOneWidget);
    expect(find.textContaining('Update available'), findsNothing);
  }, skip: !inAppUpdates);

  testWidgets('a page off the project accounts: the manifest is not used', (tester) async {
    await pump(tester, (_) async => (200, offAccounts));
    expect(find.text('$deskAppVersion is the latest'), findsOneWidget);
    expect(find.textContaining('Update available'), findsNothing);
  }, skip: !inAppUpdates);

  for (final (name, body) in [('an unsigned', () => unsignedNewer), ('a forged', () => forgedNewer)]) {
    testWidgets('$name manifest offers no update and no error', (tester) async {
      await pump(tester, (_) async => (200, body()));
      expect(find.text('$deskAppVersion is the latest'), findsOneWidget);
      expect(find.textContaining('Update available'), findsNothing);
      expect(find.text('Could not check'), findsNothing);
    }, skip: !inAppUpdates);
  }

  testWidgets('a known update stays offered when a later manifest is replayed, forged or too large', (tester) async {
    var body = (200, newer);
    await pump(tester, (_) async => body);
    expect(find.text('Update available: $next'), findsOneWidget);
    for (final reply in [(200, olderLatest), (200, forgedNewer), (deskManifestTooLarge, ''), (404, '')]) {
      body = reply;
      await tester.tap(find.widgetWithText(EButton, 'Check now'));
      await tester.pumpAndSettle();
      expect(find.text('Update available: $next'), findsOneWidget, reason: 'after ${reply.$1}');
    }
  }, skip: !inAppUpdates);

  test('the fallback download page is the public BT Labs page', () {
    expect(deskReleasesUrl, 'https://examples.btlabs.uk/epic-cash-wallets/');
    expect(isDeskUpdatePage('https://examples.btlabs.uk/epic-cash-wallets/#download'), isTrue);
    expect(isDeskUpdatePage('https://examples.btlabs.uk/other/'), isFalse);
    expect(isDeskUpdatePage('https://examples.btlabs.uk.evil.example/epic-cash-wallets/'), isFalse);
    expect(isDeskUpdatePage(deskReleasesUrl), isTrue);
  });

  test('download pages: https on the project account only', () {
    expect(isDeskUpdatePage('https://github.com/BTLabs-EPIC/epic-wallet/releases'), isTrue);
    expect(isDeskUpdatePage('https://GitHub.com/BTLabs-EPIC/x'), isTrue);
    expect(isDeskUpdatePage('http://github.com/BTLabs-EPIC/x'), isFalse);
    expect(isDeskUpdatePage('https://github.com/someone/x'), isFalse);
    // The developer's own account is no download place any more.
    expect(isDeskUpdatePage('https://github.com/blacktyger/wallet-for-epic/releases/latest'), isFalse);
    expect(isDeskUpdatePage('https://github.com/BTLabs-EPIC.evil/x'), isFalse);
    expect(isDeskUpdatePage('https://user@github.com/BTLabs-EPIC/x'), isFalse);
    expect(isDeskUpdatePage('https://example.com/get'), isFalse);
  });

  testWidgets('copyLink tries once more when the clipboard refuses', (tester) async {
    var refusals = 1;
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method != 'Clipboard.setData') return null;
      if (refusals-- > 0) throw PlatformException(code: 'busy');
      copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    expect(await tester.runAsync(() => copyLink('https://t.me/EpicCash')), isTrue);
    expect(copied, ['https://t.me/EpicCash']);
    refusals = 2;
    expect(await tester.runAsync(() => copyLink('https://epiccash.com')), isFalse);
  });

  test('the desktop keeps the last manifest across restarts: an older one is refused', () async {
    final secrets = MemorySecretStore();
    // One app run: a fresh controller on the same desk store.
    Future<DeskUpdateState> run(String body) async {
      final c = ProviderContainer(overrides: [
        deskStoreProvider.overrideWithValue(DeskStore(secrets)),
        deskManifestFetchProvider.overrideWithValue((_) async => (200, body)),
        deskUpdateClockProvider.overrideWithValue(() => now),
        updateKeyringProvider.overrideWithValue(testUpdateKeyring),
      ]);
      await c.read(deskUpdateProvider.notifier).check();
      final s = c.read(deskUpdateProvider);
      c.dispose();
      return s;
    }

    final latest = await signedUpdate(testUpdatePayload(desktop: {'version': deskAppVersion}, serial: 1790000100));
    final newer2 = await signedUpdate(testUpdatePayload(desktop: {'version': next, 'page': page}, serial: 1790000200));
    expect((await run(latest)).phase, DeskUpdatePhase.latest);
    final stored = ManifestState.fromJson(await DeskStore(secrets).readJson(updateStateKey));
    expect(stored?.serial, 1790000100);
    // A replayed older manifest that offers an update: not used after the restart.
    expect((await run(newer)).phase, DeskUpdatePhase.latest);
    expect(ManifestState.fromJson(await DeskStore(secrets).readJson(updateStateKey))?.serial, 1790000100);
    expect((await run(newer2)).version, next);
    expect(ManifestState.fromJson(await DeskStore(secrets).readJson(updateStateKey))?.serial, 1790000200);
    // What is stored does not read: ignored, and replaced by the next good one.
    await secrets.write(updateStateKey, '{broken');
    expect((await run(newer)).version, next);
    expect(ManifestState.fromJson(await DeskStore(secrets).readJson(updateStateKey))?.serial, 1790000000);
  }, skip: inAppUpdates ? null : 'no in-app updates in this build');
}
