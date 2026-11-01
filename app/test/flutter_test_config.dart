// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/ui/motion_switches.dart';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter_test/flutter_test.dart'
    show GoldenFileComparator, LocalFileComparator, TestFailure, goldenFileComparator, setUp;

import 'support/test_settings.dart';

/// Runs before every test file here. A waiting payment's tile laps a few times, and the pulse
/// on Send's tracker breathes a few times. Seconds of loops would keep `pumpAndSettle` busy, so
/// the tests see both still (the full current mark, a plain ring). `test/tx_icon_test.dart` turns
/// the tile's loop on for the tests of the loader. Every test reads its hosts from
/// `test/settings/` (the two files, example hosts only), the process-wide settings. A golden
/// that differs says which command redraws it.
///
/// Every test compiles this file: keep its imports to the few files above, so a change to a
/// screen reaches only the tests that use it (`tools/t affected`).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  txEdgeRunMoves = false;
  sendPulseMoves = false;
  hostSettings = testSettings();
  goldenFileComparator = _GoldenHint(goldenFileComparator);
  // A test that changes the settings (a pick, a switch) does not leak into the next one.
  setUp(() {
    hostSettings = testSettings();
    shippedHostSettings = hostSettings;
  });
  await testMain();
}

/// flutter's own comparator, with the command that redraws the golden added to a failure.
class _GoldenHint extends GoldenFileComparator {
  _GoldenHint(this._inner);

  final GoldenFileComparator _inner;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    try {
      return await _inner.compare(imageBytes, golden);
    } on FlutterError catch (e) {
      throw FlutterError('${e.message}\n${_hint(golden)}');
    } on TestFailure catch (e) {
      throw TestFailure('${e.message}\n${_hint(golden)}');
    }
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) => _inner.update(golden, imageBytes);

  @override
  Uri getTestUri(Uri key, int? version) => _inner.getTestUri(key, version);

  String _hint(Uri golden) {
    final inner = _inner;
    var path = inner is LocalFileComparator ? inner.basedir.resolveUri(golden).toFilePath() : golden.path;
    final app = '${Directory.current.path}/';
    if (path.startsWith(app)) path = 'app/${path.substring(app.length)}';
    return 'If the new look is intended, redraw it (Linux only) and look at the image before you '
        'commit it: tools/t goldens --update $path';
  }
}
