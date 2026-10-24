// The desktop's main screens in the longest languages (German, Russian) and the one without
// spaces (Thai) at the smallest supported window, 1280 x 800: an overflow or a build error fails.
// The full set, in every language and at 1920 x 1080 too, is the shot tour
// (tool/desktop_tour_test.dart with DESK_SHOTS_LANG and DESK_SHOTS_SIZE).
import 'dart:io';

import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/shots.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/shots.dart';
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/shots.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/shots.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shots whose text runs longest: the shell and sidebars, tables, forms, settings rows, tour.
const _ids = {
  '10-overview', '11-activity', '19a-outputs', '12-tx-detail', '13-send', '13j-send-summary', '17-receive',
  '21-contacts', '22-settings-node', '23-settings-receiving', '24-settings-appearance', '25-settings-account',
  '28-settings-rescan', '30-settings-help', '04-setup', '04b-setup-node', '05-unlock', '41-tour', '41b-tour-settings',
};

Future<void> _loadFonts() async {
  final dir = '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async => ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  await (FontLoader('Montserrat')..addFont(read('assets/fonts/Montserrat-SemiBold.ttf'))).load();
  await (FontLoader('JetBrainsMonoNL')..addFont(read('assets/fonts/JetBrainsMonoNL-Regular.ttf'))).load();
  final thai = FontLoader('NotoSansThai');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    thai.addFont(read('assets/fonts/NotoSansThai-$weight.ttf'));
  }
  await thai.load();
  await (FontLoader('MaterialIcons')..addFont(read('$dir/MaterialIcons-Regular.otf'))).load();
}

void main() {
  setUpAll(_loadFonts);
  final shots = [...onboardingShots, ...walletShots, ...transferShots, ...settingsShots].where((s) => _ids.contains(s.id)).toList();

  test('the shot list still names the screens this test means', () {
    for (final id in _ids) {
      expect(shots.where((s) => s.id == id), isNotEmpty, reason: id);
    }
  });

  for (final lang in ['de', 'ru', 'th']) {
    group(lang, () {
      for (final shot in shots) {
        testWidgets('${shot.id} fits 1280 x 800', (tester) => _pumpShot(tester, shot, lang));
      }
    });
  }
}

Future<void> _pumpShot(WidgetTester tester, DeskShot shot, String lang) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  final s = container.read(deskProvider).settings;
  await tester.runAsync(() => container.read(deskProvider.notifier).saveSettings(s.copyWith(language: () => lang)));
  container.read(deskNavProvider.notifier).reset(shot.route, shot.arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  }
  if (shot.prepare != null) {
    await tester.runAsync(() => shot.prepare!(container, tester.element(find.byType(DeskRoot))));
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(Localizations.localeOf(tester.element(find.byType(DeskRoot))).languageCode, lang);
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}
