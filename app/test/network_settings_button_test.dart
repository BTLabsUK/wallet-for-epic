// SPDX-License-Identifier: Apache-2.0
// The labelled network settings button on first run and unlock.
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

/// The labelled button when it fits, otherwise the icon with [label] as its tooltip.
Finder _button(String label) {
  final labelled = find.widgetWithText(TextButton, label);
  return labelled.evaluate().isNotEmpty ? labelled : find.byTooltip(label);
}

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
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
  }
}

void main() {
  setUpAll(_loadFonts);

  for (final MapEntry(key: screen, value: make) in _screens.entries) {
    group(screen, () {
      testWidgets('labels it with Advanced off and opens the Node and Epicbox sheets', (
        tester,
      ) async {
        final start = make();
        expect(start.store.values['app.advanced'], isNull);
        await _pump(tester, start);
        final button = find.widgetWithText(TextButton, 'Node and Epicbox');
        expect(button, findsOneWidget);
        expect(
          find.descendant(
            of: button,
            matching: find.byIcon(Icons.settings_ethernet),
          ),
          findsOneWidget,
        );
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        await _opensSheets(tester, button);
      });

      testWidgets('meets the tap target guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, make());
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });

      // The label stays while the measured button fits the width less 72 dp, for a back
      // arrow and the inset. German keeps it on 320 dp up to 1.3 and gives way at 2.0;
      // on 360 dp both languages keep it even at 2.0.
      const narrow = Size(960, 2080);
      const usual = Size(1080, 2340);
      for (final (language, label, physicalSize, scale, labelled) in [
        ('de', 'Node und Epicbox', usual, 1.0, true),
        ('de', 'Node und Epicbox', usual, 1.3, true),
        ('de', 'Node und Epicbox', narrow, 1.0, true),
        ('de', 'Node und Epicbox', narrow, 1.3, true),
        ('en', 'Node and Epicbox', usual, 1.3, true),
        ('en', 'Node and Epicbox', usual, 2.0, true),
        ('de', 'Node und Epicbox', narrow, 2.0, false),
        ('de', 'Node und Epicbox', usual, 2.0, true),
      ]) {
        final dp = physicalSize.width ~/ 3;
        final form = labelled ? 'the label' : 'the icon';
        testWidgets('shows $form in $language at $dp dp and scale $scale', (
          tester,
        ) async {
          await _pump(
            tester,
            make(),
            physicalSize: physicalSize,
            textScale: scale,
            language: language,
          );
          expect(tester.takeException(), isNull);
          final button = _button(label);
          expect(button, findsOneWidget);
          expect(
            find.widgetWithText(TextButton, label),
            labelled ? findsOneWidget : findsNothing,
          );
          final width = tester.getSize(button).width;
          expect(width, lessThanOrEqualTo(physicalSize.width / 3 - 72));
          await _opensSheets(tester, button);
        });
      }
    });
  }
}
