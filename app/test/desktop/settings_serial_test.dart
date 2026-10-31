// SPDX-License-Identifier: Apache-2.0
// Desktop settings writes run one at a time and the newest settings are the ones stored (AB-03).
import 'dart:async';
import 'dart:math';

import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A wallet whose first settings write waits on [gate], counting writes that overlap.
class _SlowWallet extends MockDeskWallet {
  _SlowWallet() : super(delay: Duration.zero);

  Completer<void>? gate;
  final saved = <int>[];
  int running = 0;
  int mostAtOnce = 0;

  @override
  Future<void> saveSettings(DeskSettings settings) async {
    running++;
    mostAtOnce = max(mostAtOnce, running);
    final wait = gate;
    gate = null;
    if (wait != null) await wait.future;
    saved.add(settings.scale);
    await super.saveSettings(settings);
    running--;
  }
}

void main() {
  test('two saves close together: one write at a time, the newer settings stored last', () async {
    final api = _SlowWallet();
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
    addTearDown(container.dispose);
    final desk = container.read(deskProvider.notifier);
    await desk.refresh();
    api.saved.clear();

    final first = Completer<void>();
    api.gate = first;
    final a = desk.saveSettings(container.read(deskProvider).settings.copyWith(scale: 110));
    final b = desk.saveSettings(container.read(deskProvider).settings.copyWith(scale: 120));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // The second waits for the first, which waits on the gate.
    expect(api.saved, isEmpty);
    first.complete();
    await Future.wait([a, b]);

    expect(api.mostAtOnce, 1);
    expect(api.saved.last, 120);
    expect((await api.settings()).scale, 120);
    expect(container.read(deskProvider).settings.scale, 120);

    // Idle again: a later save runs at once, nothing left queued behind the earlier ones.
    await desk.saveSettings(container.read(deskProvider).settings.copyWith(scale: 130));
    expect(api.saved.last, 130);
  });
}
