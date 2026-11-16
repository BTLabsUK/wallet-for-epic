// SPDX-License-Identifier: Apache-2.0
/// Mock builds only: pictures of the app's own frame for a test lane that may not record the
/// screen (the Mac lane). WFE_MOCK_SHOT_DIR names a folder; a file `req` put there holding a
/// name makes `<name>.png` there (or `<name>.err`). No folder named: nothing runs.
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

final _key = GlobalKey();

/// A line in the mock build's log for the lane to read; nothing in any other build.
void mockLaneLog(String line) {
  if (const bool.fromEnvironment('WFE_DESK_MOCK')) stdout.writeln('mock-lane: $line');
}

var _busy = false;

/// [app] in a boundary that can be pictured, when the lane asked for it; [app] alone in any build
/// but the mock one.
Widget mockShots(Widget app) {
  if (!const bool.fromEnvironment('WFE_DESK_MOCK')) return app;
  final dir = Platform.environment['WFE_MOCK_SHOT_DIR'];
  if (dir == null || dir.isEmpty) return app;
  Timer.periodic(const Duration(milliseconds: 300), (_) => unawaited(_take(dir)));
  stdout.writeln('mock-shots: watching $dir');
  return RepaintBoundary(key: _key, child: app);
}

Future<void> _take(String dir) async {
  final req = File('$dir/req');
  if (_busy || !req.existsSync()) return;
  _busy = true;
  var name = 'shot';
  try {
    name = req.readAsStringSync().trim();
    req.deleteSync();
    final boundary = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('no boundary');
    final ratio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    stdout.writeln('mock-shots: $name.png');
  } on Object catch (e) {
    File('$dir/$name.err').writeAsStringSync('$e');
  } finally {
    _busy = false;
  }
}
