// SPDX-License-Identifier: Apache-2.0
// The desktop's own outside services with no network: the public reach check (Link from the
// internet) and the update check. Each ends in its own "not available" in bounded time and
// leaves it by itself once the network is back. [NoNetwork] stands in for the network.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/desk_update.dart';
import 'package:epic_wallet/src/desktop/data/desk_update_apply.dart' show deskUpdateDirProvider, deskUpdateMarksProvider;
import 'package:epic_wallet/src/desktop/data/http_address.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'no_network.dart';

/// Sets the limit of [key] (an `app-config.toml` seconds key) to 1 s for this test (the next
/// test starts from the test settings again): a dropped connection then ends in about 1 s, and a
/// bound well under the usual limit tells which one ended it, with no wait for the usual one
/// that a busy machine can stretch past a tight bound.
void _oneSecond(String key) => hostSettings = hostSettings.withValues({key: 1});

void main() {
  group('public reach check (Link from the internet)', () {
    for (final cut in NetCut.values) {
      test('${cut.name}: no public IP, no verdict, within the probe timeout', () async {
        _oneSecond('status.reach_timeout_s');
        await withoutNetwork(cut, (_) async {
          final cache = HttpReachCache(lan: () async => '10.100.10.20');
          final r = await timed(() => cache.read(3415));
          expect(r.error, isNull);
          final reach = r.value! as HttpReach;
          expect(reach.publicIp, isNull);
          expect(reach.reachable, isNull);
          expect(reach.lan, '10.100.10.20', reason: 'the local address needs no network');
          expect(r.took, lessThan(const Duration(seconds: 5)), reason: 'its 1 s limit, not the usual 10 s');
        });
      });
    }
  });

  group('desktop update check', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('offline-update-'));
    // A check that ends in latest removes this folder itself (its old downloads), without being
    // waited for: it may be gone already, or go while this runs.
    tearDown(() async {
      try {
        await dir.delete(recursive: true);
      } on PathNotFoundException {
        // removed by the app
      }
    });

    ProviderContainer make({ManifestFetch? fetch}) {
      final c = ProviderContainer(overrides: [
        if (fetch != null) deskManifestFetchProvider.overrideWithValue(fetch),
        deskUpdateDirProvider.overrideWithValue(() async => dir),
        deskUpdateMarksProvider.overrideWithValue(null),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('refused (the real fetch): failed with the unreachable reason, not checking', () async {
      if (!deskUpdatesSupported) return markTestSkipped('a store build: no update checks');
      await withoutNetwork(NetCut.refuse, (_) async {
        final c = make();
        final r = await timed(() => c.read(deskUpdateProvider.notifier).check());
        final s = c.read(deskUpdateProvider);
        expect(s.phase, DeskUpdatePhase.failed);
        expect(s.reason, isNotEmpty);
        expect(r.took, lessThan(const Duration(seconds: 3)));
      });
    });

    test('back online: the next check leaves the failed state by itself', () async {
      if (!deskUpdatesSupported) return markTestSkipped('a store build: no update checks');
      var up = false;
      final c = make(fetch: (url) async {
        if (!up) throw const SocketException('Network is unreachable');
        return (404, '');
      });
      await c.read(deskUpdateProvider.notifier).check();
      expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.failed);
      up = true;
      await c.read(deskUpdateProvider.notifier).check();
      expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.latest);
    });

    test('dropped (the real fetch): ends in its time limit as failed, never checking for ever', () async {
      if (!deskUpdatesSupported) return markTestSkipped('a store build: no update checks');
      _oneSecond('updates.timeout_s');
      await withoutNetwork(NetCut.drop, (_) async {
        final c = make();
        final r = await timed(() => c.read(deskUpdateProvider.notifier).check());
        expect(c.read(deskUpdateProvider).phase, DeskUpdatePhase.failed);
        expect(r.took, lessThan(const Duration(seconds: 5)), reason: 'its 1 s limit, not the usual 30 s');
      });
    });
  });
}
