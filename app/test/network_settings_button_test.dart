// SPDX-License-Identifier: Apache-2.0
// The network entry on first run and unlock (the unlock screen's Ready pill).
//
// The owner, 2026-10-05: the icon alone was impossible to spot, and on first run it hid behind
// Advanced options, so a new install could not reach floonet. The label gives way to the
// icon by fit, so these tests load the real faces: the test font's square glyphs are far wider
// than Roboto and would push every label to the icon.
import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/kit/kit_icons.dart' show KitIcons;
import 'package:epic_wallet/src/ui/kit/kit_status_pill.dart';
import 'package:epic_wallet/src/ui/network_menu.dart';
import 'package:epic_wallet/src/ui/server_list_sheet.dart';
import 'package:epic_wallet/src/ui/server_picker.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _pin = '123456';

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

class _NoPrice implements PriceSource {
  const _NoPrice();

  @override
  Future<double?> price(String currency) async => null;
}

/// Roboto, the bundled Montserrat and the icons, as the screenshot tour loads them.
Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  await (FontLoader(
    'Montserrat',
  )..addFont(read('assets/fonts/Montserrat-SemiBold.ttf'))).load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('$dir/MaterialIcons-Regular.otf'))).load();
}

/// A new install, or a sealed mainnet wallet waiting for its PIN; Advanced options off.
typedef _Start = ({FakeWalletService service, MemorySecretStore store});

final Map<String, _Start Function()> _screens = {
  'first run': () => (service: FakeWalletService(), store: MemorySecretStore()),
  'unlock': () => (
    service: FakeWalletService(existingWallets: {'/fake/wallets/mainnet'}),
    store: MemorySecretStore()
      ..values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_pin),
  ),
};

Future<void> _pump(
  WidgetTester tester,
  _Start start, {
  Size physicalSize = const Size(1080, 2340),
  double textScale = 1,
  String? language,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (language != null) start.store.values['app.language'] = language;
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(start.service),
        walletDirProvider.overrideWithValue(
          (chain) async => '/fake/wallets/${chain.name}',
        ),
        secretStoreProvider.overrideWithValue(start.store),
        biometricStoreProvider.overrideWithValue(
          MemoryBiometricStore(available: false),
        ),
        updatePlatformProvider.overrideWithValue(null),
        relayDirectoryProvider.overrideWithValue(_NoRelays()),
        slateFilesProvider.overrideWithValue(FakeSlateFiles()),
        priceSourceProvider.overrideWithValue(const _NoPrice()),
      ],
      child: const WalletApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// The unlock screen's Ready pill: the way to the servers before a wallet is open.
Finder _pill() => find.byType(KitStatusPill);

/// The button opens the menu; each of its items opens its picker sheet.
Future<void> _opensSheets(WidgetTester tester, Finder button) async {
  for (final (item, kind) in [
    (networkMenuNodeKey, ServerKind.node),
    (networkMenuEpicboxKey, ServerKind.relay),
  ]) {
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byKey(networkMenuNetworkKey), findsNothing, reason: 'release builds: no Network');
    await tester.tap(find.byKey(item));
    await tester.pumpAndSettle();
    final sheet = find.byType(ServerListSheet);
    expect(sheet, findsOneWidget);
    expect(tester.widget<ServerListSheet>(sheet).kind, kind);
    // The header's close comes before the field's clear button, which is a close icon too.
    await tester.tap(find.byIcon(KitIcons.close).first);
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
  }
}

void main() {
  setUpAll(_loadFonts);

  // The phone's first-run Welcome has no network button; the unlock screen's Ready pill opens
  // the Node and Epicbox choice (the redesign replaced the labelled button on both).
  testWidgets('first run shows no network button', (tester) async {
    await _pump(tester, _screens['first run']!());
    expect(tester.takeException(), isNull);
    expect(_pill(), findsNothing);
    expect(find.byTooltip('Node and Epicbox'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Node and Epicbox'), findsNothing);
  });

  group('unlock', () {
    testWidgets('the Ready pill opens the Node and Epicbox sheets', (tester) async {
      final start = _screens['unlock']!();
      expect(start.store.values['app.advanced'], isNull);
      await _pump(tester, start);
      expect(_pill(), findsOneWidget);
      expect(tester.getSize(_pill()).height, greaterThanOrEqualTo(48));
      await _opensSheets(tester, _pill());
    });

    testWidgets('meets the tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _screens['unlock']!());
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    // The pill is short and fits every size and language.
    const narrow = Size(960, 2080);
    const usual = Size(1080, 2340);
    for (final (language, physicalSize, scale) in [
      ('de', usual, 1.0),
      ('de', narrow, 1.3),
      ('de', narrow, 2.0),
      ('en', usual, 2.0),
    ]) {
      final dp = physicalSize.width ~/ 3;
      testWidgets('shows the pill in $language at $dp dp and scale $scale', (tester) async {
        await _pump(tester, _screens['unlock']!(), physicalSize: physicalSize, textScale: scale, language: language);
        expect(tester.takeException(), isNull);
        expect(_pill(), findsOneWidget);
        expect(tester.getSize(_pill()).width, lessThanOrEqualTo(physicalSize.width / 3 - 32));
        await _opensSheets(tester, _pill());
      });
    }
  });
}
