// SPDX-License-Identifier: Apache-2.0
// Three shots of text selection on the desktop (selectable.dart), on the mock wallet, dark theme,
// written as PNGs to $DESK_SHOTS_OUT (default build/desk_shots): a Help topic with a dragged
// selection, a transaction's details with one, and the Remove wallet dialog with its text selected.
//
//   flutter test tool/desktop_select_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/desk_window.dart' show PictureDeskWindow, deskWindowProvider;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart' show showRemoveWalletDialog;
import 'package:epic_wallet/src/desktop/screens/settings/help_pairing.dart' show HelpAt;
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart' show demoOtherWallet;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final String _out = Platform.environment['DESK_SHOTS_OUT'] ?? 'build/desk_shots';

Future<void> _loadFonts() async {
  final dir = '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async => ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  for (final (family, file) in [
    ('Montserrat', 'assets/fonts/Montserrat-SemiBold.ttf'),
    ('JetBrainsMonoNL', 'assets/fonts/JetBrainsMonoNL-Regular.ttf'),
    ('EpicStatusIcons', 'assets/fonts/EpicStatusIcons.ttf'),
  ]) {
    await (FontLoader(family)..addFont(read(file))).load();
  }
  await (FontLoader('MaterialIcons')..addFont(read('$dir/MaterialIcons-Regular.otf'))).load();
}

typedef _Shot = ({String id, DeskRoute route, Object? arg, String select, double dx, double dy, Future<void> Function(BuildContext)? dialog});

const _shots = <_Shot>[
  (id: 'select-help-cleanup', route: DeskRoute.settingsHelp, arg: HelpAt('maintenance'), select: 'takes a wallet off the list', dx: 520, dy: 40, dialog: null),
  (id: 'select-tx-detail', route: DeskRoute.activity, arg: 36, select: 'Confirmed, ', dx: 220, dy: 0, dialog: null),
  (id: 'select-dialog-remove-wallet', route: DeskRoute.settingsWallets, arg: null, select: 'To delete its files', dx: 400, dy: 18, dialog: _removeWallet),
];

Future<void> _removeWallet(BuildContext c) => showRemoveWalletDialog(c, demoOtherWallet);

void main() {
  setUpAll(_loadFonts);
  for (final shot in _shots) {
    testWidgets(shot.id, (tester) async {
      tester.view.physicalSize = const Size(1280, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
          deskWindowProvider.overrideWithValue(const PictureDeskWindow()),
        ],
      );
      var closed = false;
      addTearDown(() => closed ? null : container.dispose());
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      container.read(deskNavProvider.notifier).reset(shot.route, shot.arg);
      final boundary = GlobalKey();
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: RepaintBoundary(key: boundary, child: const DeskApp())));
      Future<void> settle() async {
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 60));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        }
      }

      await settle();
      if (shot.dialog != null) {
        shot.dialog!(tester.element(find.byType(DeskRoot)));
        await settle();
        await tester.pump(const Duration(milliseconds: 400));
      }
      final text = find.byWidgetPredicate((w) => w is Text && (w.textSpan?.toPlainText() ?? w.data ?? '').contains(shot.select)).first;
      await Scrollable.ensureVisible(tester.element(text), alignment: 0.4);
      await tester.pump();
      final from = tester.getTopLeft(text) + const Offset(2, 8);
      final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
      await tester.pump();
      await g.moveTo(from + Offset(shot.dx / 2, shot.dy / 2));
      await tester.pump();
      await g.moveTo(from + Offset(shot.dx, shot.dy));
      await tester.pump();
      await g.up();
      await tester.pump(const Duration(milliseconds: 200));

      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final file = File('$_out/${shot.id}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      closed = true;
      container.dispose();
    });
  }
}
