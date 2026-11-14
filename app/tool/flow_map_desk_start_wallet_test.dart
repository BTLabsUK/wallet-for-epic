// SPDX-License-Identifier: Apache-2.0
// Desktop flow map, part `start-wallet`: states of the start, Overview shell and Activity flows the
// desktop tour lacks (Forgot password, the title bar menus, the shortcuts
// dialog, Home with Outputs on), rendered on the mock wallet exactly as
// tool/desktop_tour_test.dart does. Ids `fm-start-wallet-...`.
//
//   flutter test tool/flow_map_desk_start_wallet_test.dart
// (DESK_SHOTS_OUT, DESK_SHOTS_SIZE, DESK_SHOTS_LANG, SHOTS_META, LAYOUT_AUDIT as in the tour.)
import 'package:epic_wallet/src/desktop/app/desk_window.dart' show PictureDeskWindow, deskWindowProvider;
import 'package:epic_wallet/src/advanced.dart' show AdvancedFeature, NetworkMode;
import 'package:epic_wallet/src/desktop/app/shots.dart';
import 'package:epic_wallet/src/desktop/app/title_bar.dart' show showDeskShortcuts;
import 'package:epic_wallet/src/desktop/screens/onboarding/reset_password_screen.dart' show ResetPasswordArg;
import 'dart:async' show Completer, unawaited;
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


const _savings = '5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f';
const _goodPhraseWords = ['zoo','zoo','zoo','zoo','zoo','zoo','zoo','zoo','zoo','zoo','zoo','wrong'];
const _otherPhraseWords = ['legal','winner','thank','year','wave','sausage','worth','useful','legal','winner','thank','yellow'];

Future<void> _outputsOn(ProviderContainer c) async {
  final s = c.read(deskProvider).settings;
  await c.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: s.advanced.withFeature(AdvancedFeature.outputs, true)));
}

Future<void> _torOnly(ProviderContainer c) async {
  final s = c.read(deskProvider).settings;
  await c.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: s.advanced.withMode(NetworkMode.torOnly)));
}

/// The mock, with the reset's answer set by the shot: `working` never ends, `failed` throws,
/// `unverifiable` is the core's "cannot be checked" answer.
class _ResetWallet extends MockDeskWallet {
  _ResetWallet(this.answer, {required super.seedInvoices}) : super(delay: Duration.zero);

  final String answer;

  @override
  Future<void> resetPassword(String id, {required List<String> phrase, required String newPassword}) async {
    switch (answer) {
      case 'working':
        await Completer<void>().future;
      case 'failed':
        throw const DeskError('The password was not changed.');
      case 'unverifiable':
        throw const DeskError('The phrase cannot be checked against this wallet.', resetUnverifiable: true);
    }
  }
}

MockDeskWallet _walletFor(String id, {required bool seedInvoices}) {
  for (final answer in ['working', 'failed', 'unverifiable']) {
    if (id == 'fm-start-wallet-reset-$answer') return _ResetWallet(answer, seedInvoices: seedInvoices);
  }
  return MockDeskWallet(delay: Duration.zero, seedInvoices: seedInvoices);
}

/// Taps the widget with [key] as a pointer would, then lets the popover or dialog draw.
Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key).first);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _resetToPassword(WidgetTester tester) async {
  final fields = find.byType(EditableText);
  await tester.enterText(fields.at(0), 'a-new-password-1');
  await tester.pump(const Duration(milliseconds: 100));
  await tester.enterText(fields.at(1), 'a-new-password-1');
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _resetSubmit(WidgetTester t) async {
  await _resetToPassword(t);
  await _tap(t, const ValueKey('reset-password-save'));
  await t.pump(const Duration(milliseconds: 600));
}

final Map<String, Future<void> Function(WidgetTester)> _steps = {
  'fm-start-wallet-reset-wrong-phrase': (t) async {
    await _resetToPassword(t);
    await _tap(t, const ValueKey('reset-password-save'));
    await t.pump(const Duration(milliseconds: 600));
  },
  'fm-start-wallet-reset-working': _resetSubmit,
  'fm-start-wallet-reset-failed': _resetSubmit,
  'fm-start-wallet-reset-unverifiable': _resetSubmit,
  'fm-start-wallet-app-menu': (t) => _tap(t, const ValueKey('bar-brand')),
  'fm-start-wallet-wallet-menu': (t) => _tap(t, const ValueKey('bar-wallet')),
  'fm-start-wallet-mode-mark-tor-only': (t) => _tap(t, const ValueKey('bar-net-mode')),
  'fm-start-wallet-shortcuts': (t) async {
    unawaited(showDeskShortcuts());
    await t.pump(const Duration(milliseconds: 300));
  },
};

final List<DeskShot> flowMapStartWalletShots = [
  const DeskShot(id: 'fm-start-wallet-reset-words', title: 'Forgot password: the recovery phrase', route: DeskRoute.resetPassword, arg: ResetPasswordArg(_savings)),
  const DeskShot(id: 'fm-start-wallet-reset-password', title: 'Forgot password: the new password', route: DeskRoute.resetPassword, arg: ResetPasswordArg(_savings, phrase: [..._goodPhraseWords])),
  const DeskShot(id: 'fm-start-wallet-reset-wrong-phrase', title: 'Forgot password: the phrase belongs to another wallet', route: DeskRoute.resetPassword, arg: ResetPasswordArg(_savings, phrase: [..._otherPhraseWords])),
  const DeskShot(id: 'fm-start-wallet-reset-working', title: 'Forgot password: setting the password', route: DeskRoute.resetPassword, arg: ResetPasswordArg(_savings, phrase: [..._goodPhraseWords])),
  const DeskShot(id: 'fm-start-wallet-reset-failed', title: 'Forgot password: the password was not changed', route: DeskRoute.resetPassword, arg: ResetPasswordArg(_savings, phrase: [..._goodPhraseWords])),
  const DeskShot(id: 'fm-start-wallet-reset-unverifiable', title: 'Forgot password: the phrase cannot be checked', route: DeskRoute.resetPassword, arg: ResetPasswordArg(_savings, phrase: [..._goodPhraseWords])),
  const DeskShot(id: 'fm-start-wallet-app-menu', title: 'Overview: the app menu open', route: DeskRoute.overview),
  const DeskShot(id: 'fm-start-wallet-wallet-menu', title: 'Overview: the wallet switcher with three wallets', route: DeskRoute.overview),
  DeskShot(id: 'fm-start-wallet-mode-mark-tor-only', title: 'Overview, Tor only: the mode mark popover', route: DeskRoute.overview, before: _torOnly),
  const DeskShot(id: 'fm-start-wallet-shortcuts', title: 'Overview: the keyboard shortcuts dialog', route: DeskRoute.overview),
  DeskShot(id: 'fm-start-wallet-overview-outputs-on', title: 'Home with Advanced › Outputs on', route: DeskRoute.overview, before: _outputsOn),
  DeskShot(id: 'fm-start-wallet-activity-outputs-on', title: 'Activity with Advanced › Outputs on', route: DeskRoute.activity, before: _outputsOn),
];

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
  final all = flowMapStartWalletShots;
  // The invoice shots start from a seeded book.
  final experimental = <String>{};

  for (final shot in all) {
    testWidgets(shot.id, (tester) async {
      tester.view.physicalSize = _size ?? Size(shot.width, shot.height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final wallet = _walletFor(shot.id, seedInvoices: experimental.contains(shot.id));
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
      final step = _steps[shot.id];
      if (step != null) {
        await step(tester);
        await settle();
        await tester.pump(const Duration(milliseconds: 400));
      }
      if (shot.dialog != null) {
        // Not awaited: it completes when the dialog closes.
        shot.dialog!(ctx);
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
