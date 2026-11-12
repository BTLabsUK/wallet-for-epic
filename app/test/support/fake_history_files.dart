// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/ui/settings_history.dart' show HistoryFiles;
import 'package:flutter/foundation.dart' show Uint8List;

/// Records saves and shares and hands out queued picks, for widget tests.
class FakeHistoryFiles implements HistoryFiles {
  final List<({String name, Uint8List bytes})> saved = [];
  final List<({String name, Uint8List bytes})> shared = [];
  final List<Uint8List?> picks = [];

  @override
  bool canShare = true;

  @override
  Future<bool> save({
    required String name,
    required Uint8List bytes,
    required String dialogTitle,
  }) async {
    saved.add((name: name, bytes: bytes));
    return true;
  }

  @override
  Future<bool> share({required String name, required Uint8List bytes}) async {
    shared.add((name: name, bytes: bytes));
    return true;
  }

  @override
  Future<Uint8List?> pick({required String dialogTitle}) async =>
      picks.isEmpty ? null : picks.removeAt(0);
}
