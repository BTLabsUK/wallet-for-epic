import 'package:epic_wallet/src/desktop/data/desk_update.dart';
import 'package:epic_wallet/src/desktop/data/files.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_about.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_frame.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 22, 12);

  Future<(ProviderContainer, List<String>)> pump(WidgetTester tester, ManifestFetch fetch) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <String>[];
    final container = ProviderContainer(overrides: [
      deskManifestFetchProvider.overrideWithValue(fetch),
      deskUpdateClockProvider.overrideWithValue(() => now),
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
  });

  testWidgets('Community opens Telegram and epiccash.com in the browser', (tester) async {
    final (_, opened) = await pump(tester, (_) async => (404, ''));
    await tester.tap(find.widgetWithText(EButton, 'Open').first);
    await tester.tap(find.widgetWithText(EButton, 'Open').last);
    await tester.pumpAndSettle();
    expect(opened, ['https://t.me/EpicCash', 'https://epiccash.com']);
    expect(find.text('Telegram'), findsOneWidget);
  });

  testWidgets('Licences opens the licence page', (tester) async {
    await pump(tester, (_) async => (404, ''));
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
    expect(find.text('0.1.0 is the latest'), findsOneWidget);
    expect(find.text('Could not check'), findsNothing);
    await tester.tap(find.widgetWithText(EButton, 'Check now'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('a newer version offers its page; the same version is the latest', (tester) async {
    const page = 'https://github.com/BTLabs-EPIC/epic-wallet/releases/tag/v0.1.1';
    final (container, opened) = await pump(tester, (_) async => (200, '{"versionName": "9.0.0", "desktop": {"version": "0.1.1", "page": "$page"}}'));
    expect(find.text('Update available: 0.1.1'), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Get 0.1.1'));
    await tester.pumpAndSettle();
    expect(opened, [page]);

    container.updateOverrides([
      deskManifestFetchProvider.overrideWithValue((_) async => (200, '{"versionName": "9.0.0", "desktop": {"version": "0.1.0"}}')),
      deskUpdateClockProvider.overrideWithValue(() => now),
      deskOpenUrlProvider.overrideWithValue((_) async => true),
    ]);
    await tester.tap(find.widgetWithText(EButton, 'Check now'));
    await tester.pumpAndSettle();
    expect(find.text('0.1.0 is the latest'), findsOneWidget);
  });

  testWidgets("the phone's manifest alone offers nothing to the desktop", (tester) async {
    await pump(tester, (_) async => (200, '{"versionName": "0.2.0", "page": "https://github.com/blacktyger/wallet-for-epic/releases"}'));
    expect(find.text('Could not check'), findsOneWidget);
    expect(find.text('No desktop update information is published yet. Checked just now.'), findsOneWidget);
    expect(find.textContaining('Update available'), findsNothing);
  });

  testWidgets('a page off the project accounts opens the releases page instead', (tester) async {
    final (_, opened) = await pump(tester, (_) async => (200, '{"desktop": {"version": "0.1.1", "page": "https://github.com.evil.example/BTLabs-EPIC/"}}'));
    await tester.tap(find.widgetWithText(EButton, 'Get 0.1.1'));
    await tester.pumpAndSettle();
    expect(opened, [deskReleasesUrl]);
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
