// The distribution switch (lib/src/dist_build.dart, https://docs.btlabs.uk/developers/build/variants/): which parts a build
// for our own page, Google Play or F-Droid carries. Run each way:
//   flutter test test/dist_build_test.dart
//   flutter test --dart-define=WFE_DIST=play test/dist_build_test.dart
//   flutter test --dart-define=WFE_DIST=fdroid test/dist_build_test.dart
import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/dist_build.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _define = String.fromEnvironment('WFE_DIST', defaultValue: 'web');

void main() {
  // The updater's platform side sets a method channel handler.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the constants follow WFE_DIST', () {
    expect(dist.name, _define);
    expect(distUpdates, _define == 'web');
    expect(inAppUpdates, torBuilt && _define == 'web');
    expect(distStore, switch (_define) { 'play' => 'Google Play', 'fdroid' => 'F-Droid', _ => null });
  });

  test('no updater where the build has none', () {
    // Tests run as Android, where the build from our own page has one.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(updatePlatformProvider) != null, inAppUpdates);
  });

  test('About names the store in every language', () {
    for (final lang in ['en', 'de', 'pl', 'ru', 'zh', 'th']) {
      final l = lookupAppLocalizations(Locale(lang));
      expect(l.settingsUpdatesFrom('F-Droid'), contains('F-Droid'), reason: lang);
    }
  });
}
