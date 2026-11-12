// SPDX-License-Identifier: Apache-2.0
// Desktop flow map, part `settings`: the Settings states the desktop tour lacks (wrong passwords,
// dialogs without a shot, the view and the Advanced switches, multi-wallet), rendered on the mock
// wallet exactly as tool/desktop_tour_test.dart does. Ids `fm-settings-...`.
//
//   flutter test tool/flow_map_desk_settings_test.dart
// (DESK_SHOTS_OUT, DESK_SHOTS_SIZE, DESK_SHOTS_LANG, SHOTS_META, LAYOUT_AUDIT as in the tour.)
import 'package:epic_wallet/src/desktop/app/desk_window.dart' show PictureDeskWindow, deskWindowProvider;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:epic_wallet/src/ui/badge.dart' show BadgeLook, badgeLook;
import 'package:epic_wallet/src/camera/camera_presence.dart' show FakeCameraProbe, cameraProbeProvider;
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/devices_state.dart' show deskDeviceClockProvider;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/providers.dart' show secretStoreProvider;
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskPairingRefusalsProvider;
import 'package:epic_wallet/src/name_service/payment_refusals.dart' show paymentRefusalsProvider;
import 'package:epic_wallet/src/secret_store_api.dart' show MemorySecretStore;
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/theme/tokens.dart' show deskScale;
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/server_icons.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/shots.dart';
import 'package:epic_wallet/src/desktop/data/desk_levels.dart' show deskLevelControlProvider;
import 'package:epic_wallet/src/desktop/data/desk_node.dart' show deskNodeProvider;
import 'package:epic_wallet/src/desktop/data/mock_devices.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/depth_dial.dart' show showDepthHelp;
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/licence_texts_dialog.dart' show showLicenceTextsDialog;
import 'package:epic_wallet/src/desktop/screens/settings/local_node_dialogs.dart' show showLocalNodePortsDialog;
import 'package:epic_wallet/src/desktop/screens/settings/search/search_slot.dart' show settingsQueryProvider;
import 'package:epic_wallet/src/desktop/screens/settings/settings_advanced.dart' show confirmNetworkModeSwitch;
import 'package:epic_wallet/src/desktop/screens/settings/settings_phrase.dart' show PhraseShot;
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart' show shotOtherWallet;
import 'package:epic_wallet/src/desktop/widgets/kit.dart' show EButton, ECheckbox;
import 'package:epic_wallet/src/desktop/widgets/dialogs.dart' show EDialog;
import 'package:epic_wallet/src/desktop/data/devices_state.dart' show deskDeviceServiceProvider;
import 'package:epic_wallet/src/levels/level_providers.dart' show walletLevelProvider;
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'layout_audit.dart';
import 'shot_meta.dart';

final String _out = Platform.environment['DESK_SHOTS_OUT'] ?? 'build/desk_shots';
final bool _light = Platform.environment['DESK_SHOTS_LIGHT'] == '1';
final String? _helpLanguage = Platform.environment['DESK_SHOTS_HELP'];
final int _scale = int.tryParse(Platform.environment['DESK_SHOTS_SCALE'] ?? '') ?? 100;
final String _lang = Platform.environment['DESK_SHOTS_LANG'] ?? 'en';

final Size? _size = () {
  final m = RegExp(r'^(\d+)x(\d+)$').firstMatch(Platform.environment['DESK_SHOTS_SIZE'] ?? '');
  return m == null ? null : Size(double.parse(m[1]!), double.parse(m[2]!));
}();


// ---- helpers (the tour's own are private to settings/shots.dart and devices/shots.dart) ----

Future<void> Function(ProviderContainer) _level(WalletLevel level) => (c) async {
  await c.read(walletLevelProvider.future);
  await c.read(deskLevelControlProvider).setLevel(level);
};

Future<void> _feature(ProviderContainer c, Set<AdvancedFeature> on) async {
  final n = c.read(deskProvider.notifier);
  final s = c.read(deskProvider).settings;
  var adv = s.advanced;
  for (final f in on) {
    adv = adv.withFeature(f, true);
  }
  await n.saveSettings(s.copyWith(advanced: adv));
}

Future<void> _linkedHeld(ProviderContainer c) async {
  final wallet = c.read(deskApiProvider) as MockDeskWallet;
  final desk = c.read(deskDeviceServiceProvider)!;
  await desk.load();
  final phone = await MockPhone.create(wallet);
  await phone.link(desk);
  await phone.makePayment(desk, commitment: mockCommitment(6), message: 'Rent for November');
  await c.read(deskProvider.notifier).refresh();
}

/// Types [text] into the [index]th text field on stage, through the engine (onChanged runs).
Future<void> _type(WidgetTester t, int index, String text) async {
  final inDialog = find.descendant(of: find.byType(EDialog), matching: find.byType(EditableText));
  final f = inDialog.evaluate().isNotEmpty ? inDialog : find.byType(EditableText);
  await t.enterText(f.at(index), text);
  await t.pump(const Duration(milliseconds: 100));
}

/// Presses the button labelled [label] (the last one on stage when several carry it).
Future<void> _press(WidgetTester t, String label, {bool first = false}) async {
  final f = find.byWidgetPredicate((w) => w is EButton && w.label == label);
  expect(f, findsWidgets, reason: 'a button "$label"');
  await t.tap(first ? f.first : f.last);
  await t.pump(const Duration(milliseconds: 100));
}

Future<void> _check(WidgetTester t) async {
  await t.tap(find.byType(ECheckbox).last);
  await t.pump(const Duration(milliseconds: 100));
}

/// Steps run after the shot's route and dialog are on stage, with the tester (typing, pressing).
final Map<String, Future<void> Function(WidgetTester)> _steps = {
  'fm-settings-phrase-wrong-password': (t) async {
    await _type(t, find.byType(EditableText).evaluate().length - 1, 'wrong');
    await _press(t, 'Show recovery phrase');
  },
  'fm-settings-delete-wallet-wrong-password': (t) async {
    await _type(t, 0, 'wrong');
    await _check(t);
    await _press(t, 'Delete wallet');
  },
  'fm-settings-change-password-wrong-current': (t) async {
    await _type(t, 0, 'wrong');
    await _type(t, 1, 'a-new-password-1');
    await _type(t, 2, 'a-new-password-1');
    await _press(t, 'Change password');
  },
  'fm-settings-phrase-copy-confirm': (t) async => _press(t, 'Copy', first: true),
  'fm-settings-device-rename': (t) async => _press(t, 'Rename', first: true),
  'fm-settings-device-remove': (t) async => _press(t, 'Remove'),
  'fm-settings-device-release': (t) async => _press(t, 'Release'),
};

final List<DeskShot> flowMapSettingsShots = [
  // wrong passwords
  const DeskShot(id: 'fm-settings-phrase-wrong-password', title: 'Recovery phrase, wrong password', route: DeskRoute.settingsPhrase),
  DeskShot(id: 'fm-settings-delete-wallet-wrong-password', title: 'Delete wallet, wrong password', route: DeskRoute.settingsAccount, dialog: showDeleteWalletDialog),
  DeskShot(id: 'fm-settings-change-password-wrong-current', title: 'Change password, wrong current password', route: DeskRoute.settingsSecurity, dialog: showChangePasswordDialog),
  // multi-wallet
  DeskShot(id: 'fm-settings-wallets-removed-from-list', title: 'Wallets, one removed from the list: Add back', route: DeskRoute.settingsWallets, prepare: (c, _) async => c.read(deskProvider.notifier).removeWallet(shotOtherWallet.id, WalletRemoval.list)),
  // dialogs without a shot
  DeskShot(id: 'fm-settings-network-switch-confirm', title: 'Switch to Kill switch? with sends waiting', route: DeskRoute.settingsPrivacy, dialog: (c) => confirmNetworkModeSwitch(c, mode: NetworkMode.killSwitch, waiting: 2)),
  DeskShot(id: 'fm-settings-depth-help', title: 'Advanced, what the views decide', route: DeskRoute.settingsAdvanced, dialog: showDepthHelp),
  DeskShot(id: 'fm-settings-licence-texts', title: 'About, licence texts', route: DeskRoute.settingsAbout, dialog: showLicenceTextsDialog),
  const DeskShot(id: 'fm-settings-phrase-copy-confirm', title: 'Recovery phrase, copy confirm', route: DeskRoute.settingsPhrase, arg: PhraseShot.shown),
  DeskShot(id: 'fm-settings-device-rename', title: 'Linked devices, rename', route: DeskRoute.settingsDevices, height: 1100, prepare: (c, _) => _linkedHeld(c)),
  DeskShot(id: 'fm-settings-device-remove', title: 'Linked devices, remove a device', route: DeskRoute.settingsDevices, height: 1100, prepare: (c, _) => _linkedHeld(c)),
  DeskShot(id: 'fm-settings-device-release', title: 'Linked devices, release a held payment', route: DeskRoute.settingsDevices, height: 1100, prepare: (c, _) => _linkedHeld(c)),
  DeskShot(
    id: 'fm-settings-local-ports-dialog',
    title: 'Local node, the ports dialog',
    route: DeskRoute.settingsNode,
    before: (c) => _feature(c, {AdvancedFeature.builtInNode}),
    dialog: (ctx) => showLocalNodePortsDialog(ctx, ProviderScope.containerOf(ctx).read(deskNodeProvider), running: false),
  ),
  // the view and the Advanced switches
  DeskShot(id: 'fm-settings-advanced-all-on', title: 'Advanced, every switch on: count and Reset', route: DeskRoute.settingsAdvanced, height: 1450, before: (c) => _feature(c, {...AdvancedFeature.values}.difference(retiredFeatures))),
  DeskShot(id: 'fm-settings-node-server-details', title: 'Node, Advanced › Server details on', route: DeskRoute.settingsNode, before: (c) => _feature(c, {AdvancedFeature.serverDetails})),
  DeskShot(id: 'fm-settings-rescan-shallow', title: 'Recheck balance, Shallow view', route: DeskRoute.settingsRescan, before: _level(WalletLevel.justSendReceive)),
  DeskShot(id: 'fm-settings-rescan-from-height', title: 'Recheck balance, Advanced › Recheck from a height on', route: DeskRoute.settingsRescan, height: 1000, before: (c) => _feature(c, {AdvancedFeature.recheckFromHeight})),
  DeskShot(id: 'fm-settings-security-shallow', title: 'Security, Shallow view', route: DeskRoute.settingsSecurity, before: _level(WalletLevel.justSendReceive)),
  DeskShot(id: 'fm-settings-transactions-shallow', title: 'Transactions, Shallow view', route: DeskRoute.settingsReceiving, height: 1000, before: _level(WalletLevel.justSendReceive)),
  DeskShot(id: 'fm-settings-devices-shallow', title: 'Linked devices, Shallow view', route: DeskRoute.settingsDevices, before: _level(WalletLevel.justSendReceive)),
  DeskShot(id: 'fm-settings-wallet-deeper', title: 'Wallet, Deeper view', route: DeskRoute.settingsAccount, before: _level(WalletLevel.casual)),
  DeskShot(id: 'fm-settings-node-deeper', title: 'Node, Deeper view', route: DeskRoute.settingsNode, before: _level(WalletLevel.casual)),
  DeskShot(id: 'fm-settings-search-no-results', title: 'Settings search, no match', route: DeskRoute.settingsAccount, prepare: (c, _) async => c.read(settingsQueryProvider.notifier).set('zzqx')),
  DeskShot(id: 'fm-settings-help-no-results', title: 'Help, search without a match', route: DeskRoute.settingsHelp, arg: 'zzqxw'),
  DeskShot(id: 'fm-settings-privacy-node-only', title: 'Network & privacy, Node only', route: DeskRoute.settingsPrivacy, height: 1000, prepare: (c, _) async {
    final n = c.read(deskProvider.notifier);
    final s = c.read(deskProvider).settings;
    await n.saveSettings(s.copyWith(advanced: s.advanced.withMode(NetworkMode.nodeOnly)));
  }),
];

Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async => ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  final cjk = _lang == 'zh';
  if (cjk) {
    // The first face of each collection; it has Latin, Cyrillic and Han glyphs.
    for (final weight in ['Regular', 'Bold']) {
      roboto.addFont(read('/usr/share/fonts/opentype/noto/NotoSansCJK-$weight.ttc'));
    }
  } else {
    for (final face in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
      roboto.addFont(read('$dir/$face'));
    }
  }
  await roboto.load();
  for (final (family, file) in [
    if (cjk) ('Montserrat', '/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc') else ('Montserrat', 'assets/fonts/Montserrat-SemiBold.ttf'),
    if (cjk) ('JetBrainsMonoNL', '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc') else ('JetBrainsMonoNL', 'assets/fonts/JetBrainsMonoNL-Regular.ttf'),
    ('EpicStatusIcons', 'assets/fonts/EpicStatusIcons.ttf'), // the icon font is not loaded by the test binding
  ]) {
    await (FontLoader(family)..addFont(read(file))).load();
  }
  // The Thai font of the fallback (bundledFallback), for Help in Thai.
  final thai = FontLoader('NotoSansThai');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    thai.addFont(read('assets/fonts/NotoSansThai-$weight.ttf'));
  }
  await thai.load();
  // The bundled Chinese fallback (cjkFamily).
  await (FontLoader('NotoSansSCSubset')..addFont(read('assets/fonts/NotoSansSCSubset.otf'))).load();
  await (FontLoader('MaterialIcons')..addFont(read('$dir/MaterialIcons-Regular.otf'))).load();
}

/// The fixture PNG for an icon URL, by its hash.
Future<Uint8List?> _fixtureIcon(Uri url) async {
  final hash = RegExp(r'([0-9a-f]{20})-[0-9]+[.]png$').firstMatch(url.path)?.group(1);
  final f = File('test/fixtures/icons/$hash-128.png');
  return f.existsSync() ? f.readAsBytesSync() : null;
}

void main() {
  setUpAll(_loadFonts);
  // The screens show the shipped servers (the tour is not under test/, so no test settings are loaded).
  hostSettings = HostSettings.fromText(
    File('assets/config/settings.default.toml').readAsStringSync(),
    config: AppConfig.fromText(File('assets/config/app-config.toml').readAsStringSync()),
  );
  shippedHostSettings = hostSettings;
  // BADGE_LOOK=bare|outline|ghost renders another badge direction (badge.dart).
  final look = Platform.environment['BADGE_LOOK'];
  if (look != null) badgeLook = BadgeLook.values.byName(look);
  final all = flowMapSettingsShots;
  // The invoice shots start from a seeded book.
  final experimental = <String>{};

  for (final shot in all) {
    testWidgets(shot.id, (tester) async {
      tester.view.physicalSize = _size ?? Size(shot.width, shot.height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final wallet = MockDeskWallet(delay: Duration.zero, seedInvoices: true, otherWalletRows: shot.id.contains('other-wallet'));
      final container = ProviderContainer(
        overrides: [
          deskApiProvider.overrideWithValue(wallet),
          // The app's own refusals, as main_desktop.dart sets them: a card that takes no payments.
          paymentRefusalsProvider.overrideWith((ref) => ref.watch(deskPairingRefusalsProvider)),
          // The devices' book is kept in memory, and their times follow the mock's pairing clock.
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          deskDeviceClockProvider.overrideWithValue(() => wallet.pairing.clock()),
          // The operators' icons status.btlabs.uk serves, from the test fixtures.
          serverIconFetchProvider.overrideWithValue(_fixtureIcon),
          // The title bar with its window controls, as the app draws them on Linux.
          deskWindowProvider.overrideWithValue(const PictureDeskWindow()),
          // A laptop with its camera: Scan is offered (the scan shots set their own answer).
          cameraProbeProvider.overrideWithValue(FakeCameraProbe()),
        ],
        retry: (_, _) => null,
      );
      var closed = false;
      addTearDown(() => closed ? null : container.dispose());
      // A first-start shot holds the gate (onboarding/shots.dart); the next shot starts open.
      addTearDown(NetGate.releaseFirstStart);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      final s = container.read(deskProvider).settings;
      await tester.runAsync(
        () => container.read(deskProvider.notifier).saveSettings(s.copyWith(
          theme: _light ? ThemeChoice.light : null,
          scale: _scale,
          language: () => _lang,
          helpLanguage: _helpLanguage == null ? null : () => _helpLanguage,
        )),
      );
      if (shot.before != null) await tester.runAsync(() => shot.before!(container));
      container.read(deskNavProvider.notifier).reset(shot.route, shot.arg);

      final boundary = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(key: boundary, child: const DeskApp()),
        ),
      );
      Future<void> settle() async {
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 60));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        }
      }

      await settle();
      final ctx = tester.element(find.byType(DeskRoot));
      if (shot.prepare != null) {
        await tester.runAsync(() => shot.prepare!(container, ctx));
        await settle();
      }
      if (shot.after != null) {
        await tester.runAsync(() => shot.after!(container, ctx));
        await settle();
      }
      if (shot.opensDialog) {
        // The dialog opens once an estimate came back (real time and frames): wait for it.
        for (var i = 0; i < 60 && find.byType(Dialog).evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 60));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
        }
        expect(find.byType(Dialog), findsOneWidget, reason: '${shot.id} opens a dialog');
        await settle();
        await tester.pump(const Duration(milliseconds: 400));
      }
      if (shot.dialog != null) {
        // Not awaited: it completes when the dialog closes.
        shot.dialog!(ctx);
        await settle();
        await tester.pump(const Duration(milliseconds: 400));
      }

      final step = _steps[shot.id];
      if (step != null) {
        await step(tester);
        await settle();
        await tester.pump(const Duration(milliseconds: 400));
      }

      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final file = File('$_out/${_lang == 'en' ? '' : '$_lang/'}${shot.id}${_light ? '-light' : ''}${_scale == 100 ? '' : '-s$_scale'}${_helpLanguage == null ? '' : '-help-$_helpLanguage'}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
        if (layoutAudit) writeLayoutAudit(file.path, boundary.currentContext! as Element, deskScale);
        if (shotMeta) {
          writeShotMeta(file.path, boundary.currentContext! as Element, {
            'id': shot.id,
            'title': shot.title,
            'route': shot.route.name,
            if (shot.arg != null) 'arg': '${shot.arg}',
            'dialog': shot.dialog != null || shot.opensDialog,
            'width': (_size?.width ?? shot.width).round(),
            'height': (_size?.height ?? shot.height).round(),
            'theme': _light ? 'light' : 'dark',
            'lang': _lang,
            'scale': _scale,
            'experimental': experimental.contains(shot.id),
          });
        }
      });
      // Anything drawn with an overflow or thrown while building fails the shot.
      expect(tester.takeException(), isNull);
      // The app goes first, then its services: a dialog closing with the tree may start a timer.
      await tester.pumpWidget(const SizedBox());
      closed = true;
      container.dispose();
    });
  }
}
