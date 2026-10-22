import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/node/node_api_types.dart';
import 'package:epic_wallet/src/node/sync_progress.dart';
import 'package:flutter_test/flutter_test.dart';

NodeStatusInfo status(String sync, {NodeSyncInfo? info, int height = 0}) =>
    NodeStatusInfo(
      protocolVersion: 2,
      userAgent: 'MW/Epic 4.1.0',
      connections: 8,
      tip: NodeTipInfo(height),
      syncStatus: sync,
      syncInfo: info,
    );

void main() {
  test('every sync status has its stage', () {
    for (final (s, stage) in [
      ('awaiting_peers', SyncStage.waitingForPeers),
      ('header_sync', SyncStage.headers),
      ('txhashset_download', SyncStage.chainStateDownload),
      ('txhashset_kernels_validation', SyncStage.chainStateKernels),
      ('txhashset_rangeproofs_validation', SyncStage.chainStateRangeProofs),
      ('syncing', SyncStage.chainStateProcessing),
      ('body_sync', SyncStage.blocks),
      ('no_sync', SyncStage.synced),
      ('compacting', SyncStage.compacting),
      ('shutdown', SyncStage.shuttingDown),
      ('something_new', SyncStage.unknown),
    ]) {
      expect(stageOf(s), stage, reason: s);
    }
  });

  test('the weights add up to 1', () {
    expect(
      syncStageWeights.values.reduce((a, b) => a + b),
      closeTo(1, 1e-9),
    );
  });

  group('progressOf', () {
    test('headers: heights against the network tip', () {
      // The node's highest_height is only its batch target (seen live: 332288 of 336896).
      const info = NodeSyncInfo(currentHeight: 250, highestHeight: 300);
      final p = progressOf(status('header_sync', info: info), networkHeight: 1000);
      expect(p.stage, SyncStage.headers);
      expect(p.stageFraction, 0.25);
      expect(p.overall, closeTo(0.075, 1e-9));
      expect((p.done, p.total), (250, 1000));
      final unknown = progressOf(status('header_sync', info: info));
      expect((unknown.done, unknown.total), (250, null), reason: 'no tip known: no fraction, not 83 %');
      expect(unknown.stageFraction, isNull);
      expect(unknown.overall, isNull);
    });

    test('blocks: the higher of the node\'s highest and the network tip', () {
      const info = NodeSyncInfo(currentHeight: 500, highestHeight: 1000);
      expect(progressOf(status('body_sync', info: info)).total, 1000);
      expect(progressOf(status('body_sync', info: info), networkHeight: 2000).total, 2000);
      expect(progressOf(status('body_sync', info: info), networkHeight: 900).total, 1000);
    });

    test('chain state download: bytes', () {
      final p = progressOf(
        status(
          'txhashset_download',
          info: const NodeSyncInfo(downloadedBytes: 50, totalBytes: 100),
        ),
      );
      expect(p.stageFraction, 0.5);
      expect(p.overall, closeTo(0.45, 1e-9));
      expect((p.done, p.total), (50, 100));
    });

    test('kernels and range proofs: items', () {
      final k = progressOf(
        status(
          'txhashset_kernels_validation',
          info: const NodeSyncInfo(kernels: 1, kernelsTotal: 4),
        ),
      );
      expect(k.stageFraction, 0.25);
      expect(k.overall, closeTo(0.6125, 1e-9));
      final r = progressOf(
        status(
          'txhashset_rangeproofs_validation',
          info: const NodeSyncInfo(rangeProofs: 3, rangeProofsTotal: 4),
        ),
      );
      expect(r.stageFraction, 0.75);
      expect(r.overall, closeTo(0.725, 1e-9));
    });

    test('blocks: heights, the last fifth', () {
      final p = progressOf(
        status(
          'body_sync',
          info: const NodeSyncInfo(currentHeight: 900, highestHeight: 1000),
        ),
      );
      expect(p.stage, SyncStage.blocks);
      expect(p.overall, closeTo(0.98, 1e-9));
    });

    test('synced is whole', () {
      final p = progressOf(status('no_sync', height: 77));
      expect(p, const SyncProgress(
        SyncStage.synced,
        stageFraction: 1,
        overall: 1,
        done: 77,
        total: 77,
      ));
    });

    test('stages without a measure have no fraction', () {
      for (final s in ['awaiting_peers', 'syncing', 'compacting', 'shutdown', 'x']) {
        final p = progressOf(status(s));
        expect(p.stageFraction, isNull, reason: s);
        expect(p.overall, isNull, reason: s);
      }
    });

    test('a zero total or overshoot is safe', () {
      expect(
        progressOf(
          status(
            'txhashset_download',
            info: const NodeSyncInfo(downloadedBytes: 5, totalBytes: 0),
          ),
        ).stageFraction,
        isNull,
      );
      expect(
        progressOf(
          status(
            'header_sync',
            info: const NodeSyncInfo(currentHeight: 12, highestHeight: 10),
          ),
          networkHeight: 10,
        ).stageFraction,
        1,
      );
    });

    test('the real get_status fixture parses into a progress', () {
      final json = jsonDecode(
        File('test/fixtures/node/get_status.json').readAsStringSync(),
      );
      final ok = (json is Map && json['result'] is Map)
          ? (json['result'] as Map)['Ok']
          : json;
      final p = progressOf(parseStatus(ok), networkHeight: 3764980);
      expect(p.stage, SyncStage.headers);
      expect((p.done, p.total), (7168, 3764980));
    });
  });

  test('networkTipOf: the directory over the peers, not below the node, ignoring 0', () {
    expect(networkTipOf(), isNull);
    expect(networkTipOf(highestHeight: 0), isNull);
    expect(networkTipOf(highestHeight: 10, peersHeight: 30, directoryTip: 20), 20);
    expect(networkTipOf(highestHeight: 10, peersHeight: 30), 30);
    expect(networkTipOf(highestHeight: 25, directoryTip: 20), 25);
    expect(networkTipOf(directoryTip: 5), 5);
  });

  test('EtaEstimator gives nothing once the node stopped moving for a window', () {
    final t0 = DateTime(2026, 1, 1);
    final e = EtaEstimator()
      ..add(t0, SyncStage.headers, 0, 1000)
      ..add(t0.add(const Duration(seconds: 30)), SyncStage.headers, 300, 1000);
    expect(e.eta(now: t0.add(const Duration(seconds: 40))), isNotNull);
    expect(e.eta(now: t0.add(const Duration(minutes: 3))), isNull);
  });

  group('EtaEstimator', () {
    final t0 = DateTime(2026, 1, 1);
    DateTime at(int s) => t0.add(Duration(seconds: s));

    test('needs two samples over 20 s', () {
      final e = EtaEstimator();
      expect(e.eta(), isNull);
      e.add(at(0), SyncStage.headers, 0, 1000);
      expect(e.eta(), isNull);
      e.add(at(10), SyncStage.headers, 100, 1000);
      expect(e.ratePerSecond(), isNull);
      e.add(at(20), SyncStage.headers, 200, 1000);
      expect(e.ratePerSecond(), 10);
      expect(e.eta(), const Duration(seconds: 80));
    });

    test('no progress is no ETA', () {
      final e = EtaEstimator()
        ..add(at(0), SyncStage.headers, 100, 1000)
        ..add(at(60), SyncStage.headers, 100, 1000);
      expect(e.ratePerSecond(), isNull);
      expect(e.eta(), isNull);
    });

    test('a new stage or a step back starts over; a moving total does not', () {
      final e = EtaEstimator()
        ..add(at(0), SyncStage.headers, 0, 1000)
        ..add(at(30), SyncStage.headers, 300, 1000);
      expect(e.eta(), isNotNull);
      e.add(at(31), SyncStage.chainStateDownload, 0, 5000);
      expect(e.eta(), isNull);
      e.add(at(60), SyncStage.chainStateDownload, 1000, 5000);
      expect(e.ratePerSecond(), closeTo(1000 / 29, 1e-9));
      // The total moves (the tip grows, or becomes known): the rate stays, the ETA follows it.
      e.add(at(61), SyncStage.chainStateDownload, 1100, 6000);
      expect(e.eta(), isNotNull);
      e.add(at(90), SyncStage.chainStateDownload, 500, 6000);
      expect(e.eta(), isNull, reason: 'a step back');
    });

    test('an unknown total gives a rate but no ETA', () {
      final e = EtaEstimator()
        ..add(at(0), SyncStage.headers, 0, null)
        ..add(at(30), SyncStage.headers, 3000, null);
      expect(e.ratePerSecond(), 100);
      expect(e.eta(), isNull);
      e.add(at(40), SyncStage.headers, 4000, 14000);
      expect(e.eta(), const Duration(seconds: 100));
    });

    test('the window slides: old samples stop counting', () {
      final e = EtaEstimator()
        ..add(at(0), SyncStage.blocks, 0, 100000)
        ..add(at(60), SyncStage.blocks, 60000, 100000);
      expect(e.ratePerSecond(), 1000);
      // slows down to 10/s for the next 5 minutes
      for (var s = 120; s <= 420; s += 60) {
        e.add(at(s), SyncStage.blocks, 60000 + (s - 60) * 10, 100000);
      }
      expect(e.ratePerSecond(), closeTo(10, 1e-9));
    });

    test('reset forgets', () {
      final e = EtaEstimator()
        ..add(at(0), SyncStage.headers, 0, 10)
        ..add(at(30), SyncStage.headers, 3, 10)
        ..reset();
      expect(e.ratePerSecond(), isNull);
    });
  });
}
