import 'package:epic_wallet/src/desktop/data/desk_update.dart';
import 'package:epic_wallet/src/desktop/data/files.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_about.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_frame.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/updater.dart' show updateKeyringProvider;
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
  setUpAll(() async {
    newer = await signedUpdate(testUpdatePayload(versionName: '9.0.0', desktop: {'version': '26.10.1', 'page': page}));
    same = await signedUpdate(testUpdatePayload(versionName: '9.0.0', desktop: {'version': deskAppVersion}, serial: 1790000100));
    phoneOnly = await signedUpdate(testUpdatePayload(versionName: '0.2.0'));
    // The verifier's schema only takes pages on the project's GitHub accounts, so a page
    // elsewhere is a manifest that does not verify, not one that opens a fallback.
    offAccounts = await signedUpdate(testUpdatePayload(desktop: {'version': '26.10.1', 'page': 'https://github.com.evil.example/BTLabs-EPIC/'}));
    unsignedNewer = '{"versionName": "9.0.0", "desktop": {"version": "26.10.1", "page": "$page"}}';
    forgedNewer = await signedUpdate(testUpdatePayload(desktop: {'version': '26.10.1', 'page': page}), keys: [await testUpdateStrangerKey()]);
    // Older than [newer] (a replay): it says this version is the latest, which must not win.
    olderLatest = await signedUpdate(testUpdatePayload(desktop: {'version': deskAppVersion}, serial: 1789999000));
    testBuild = await signedUpdate(testUpdatePayload(desktop: {'version': '26.10.1-rc1', 'page': page}));
  });

  Future<(ProviderContainer, List<String>)> pump(WidgetTester tester, ManifestFetch fetch) async {
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
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsAboutScreen())),
    ));
    await tester.pumpAndSettle();
    return (container, opened);
  }

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
  });

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
  });

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
  });

  testWidgets('a newer version offers its page; the same version is the latest', (tester) async {
    final (container, opened) = await pump(tester, (_) async => (200, newer));
    expect(find.text('Update available: 26.10.1'), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Get 26.10.1'));
    await tester.pumpAndSettle();
    expect(opened, [page]);

    container.updateOverrides([
      deskManifestFetchProvider.overrideWithValue((_) async => (200, same)),
      deskUpdateClockProvider.overrideWithValue(() => now),
      updateKeyringProvider.overrideWithValue(testUpdateKeyring),
      deskOpenUrlProvider.overrideWithValue((_) async => true),
    ]);
    await tester.tap(find.widgetWithText(EButton, 'Check now'));
    await tester.pumpAndSettle();
    expect(find.text('$deskAppVersion is the latest'), findsOneWidget);
  });

  testWidgets("the phone's manifest alone offers nothing to the desktop", (tester) async {
    await pump(tester, (_) async => (200, phoneOnly));
    expect(find.text('Could not check'), findsOneWidget);
    expect(find.text('No desktop update information is published yet. Checked just now.'), findsOneWidget);
    expect(find.textContaining('Update available'), findsNothing);
  });

  testWidgets('a page off the project accounts: the manifest is not used', (tester) async {
    await pump(tester, (_) async => (200, offAccounts));
    expect(find.text('$deskAppVersion is the latest'), findsOneWidget);
    expect(find.textContaining('Update available'), findsNothing);
  });

  for (final (name, body) in [('an unsigned', () => unsignedNewer), ('a forged', () => forgedNewer)]) {
    testWidgets('$name manifest offers no update and no error', (tester) async {
      await pump(tester, (_) async => (200, body()));
      expect(find.text('$deskAppVersion is the latest'), findsOneWidget);
      expect(find.textContaining('Update available'), findsNothing);
      expect(find.text('Could not check'), findsNothing);
    });
  }

  testWidgets('a known update stays offered when a later manifest is replayed, forged or too large', (tester) async {
    var body = (200, newer);
    await pump(tester, (_) async => body);
    expect(find.text('Update available: 26.10.1'), findsOneWidget);
    for (final next in [(200, olderLatest), (200, forgedNewer), (deskManifestTooLarge, ''), (404, '')]) {
      body = next;
      await tester.tap(find.widgetWithText(EButton, 'Check now'));
      await tester.pumpAndSettle();
      expect(find.text('Update available: 26.10.1'), findsOneWidget, reason: 'after ${next.$1}');
    }
  });

  test('the releases fallback is the project repo', () {
    expect(deskReleasesUrl, 'https://github.com/BTLabs-EPIC/wallet-for-epic/releases/latest');
    expect(isDeskUpdatePage(deskReleasesUrl), isTrue);
  });

  test('download pages: https on the project accounts only', () {
    expect(isDeskUpdatePage('https://github.com/BTLabs-EPIC/epic-wallet/releases'), isTrue);
    expect(isDeskUpdatePage('https://github.com/blacktyger/wallet-for-epic/releases/latest'), isTrue);
    expect(isDeskUpdatePage('https://GitHub.com/blacktyger/x'), isTrue);
    expect(isDeskUpdatePage('http://github.com/blacktyger/x'), isFalse);
    expect(isDeskUpdatePage('https://github.com/someone/x'), isFalse);
    expect(isDeskUpdatePage('https://github.com/blacktyger.evil/x'), isFalse);
    expect(isDeskUpdatePage('https://user@github.com/blacktyger/x'), isFalse);
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
}
