// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/feedback.dart';
import 'package:epic_wallet/src/node/fallback.dart';
import 'package:epic_wallet/src/node/local_node_state.dart';
import 'package:epic_wallet/src/node/node_api_types.dart';
import 'package:epic_wallet/src/node/node_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 16, 12);
  final state = deriveLocalNodeState(
    BuiltInNodeState(
      NodeStatusKind.syncing,
      height: 3000000,
      highest: 3764980,
      connections: 7,
      status: NodeStatusInfo(
        protocolVersion: 2,
        userAgent: 'MW/Epic 4.1.0',
        connections: 7,
        tip: NodeTipInfo(3000000),
        syncStatus: 'body_sync',
        syncInfo: NodeSyncInfo(currentHeight: 3000000, highestHeight: 3764980),
      ),
    ),
    now: now,
    dataFolder: '/n/main',
    chainDataPath: '/n/main/chain_data',
    startedAt: now.subtract(const Duration(hours: 2, minutes: 5)),
    chainDataBytes: 5 * 1024 * 1024 * 1024,
    freeBytes: 40 * 1024 * 1024 * 1024,
  );

  test('the snapshot states phase, heights, peers, uptime, restarts, fallback and disk', () {
    final text = nodeStatusText(
      state,
      spawns: 3,
      tipSource: 'node directory',
      choice: FallbackChoice(FallbackConsent.accepted, at: DateTime.utc(2026, 11, 16, 10)),
      publicSince: DateTime.utc(2026, 11, 16, 11),
      logBytes: 2048,
      now: now,
    );
    for (final line in [
      'node: on',
      'phase: syncing',
      'process running: yes',
      'uptime: 2h 5m 0s',
      'started this session: 3 times (2 restarts)',
      'local height: 3000000',
      'network tip: 3764980',
      'network tip from: node directory',
      'peers: 7',
      'fallback: on (public node allowed)',
      'public node since: 2026-11-16T11:00:00.000Z',
      'chain data size: 5.00 GB',
      'free disk: 40.00 GB',
    ]) {
      expect(text, contains(line));
    }
  });

  test('a stopped node says off and fallback off', () {
    final text = nodeStatusText(
      deriveLocalNodeState(const BuiltInNodeState.off(), now: now, dataFolder: '/n', chainDataPath: '/n/c'),
      spawns: 0,
      tipSource: 'unknown',
      choice: const FallbackChoice(FallbackConsent.declined),
      now: now,
    );
    expect(text, contains('node: off'));
    expect(text, contains('process running: no'));
    expect(text, contains('fallback: off (declined)'));
  });

  test('the report attaches the node files with peer addresses cleaned', () {
    final report = buildFeedbackReport(
      message: 'node stuck',
      details: const FeedbackDetails(appVersion: '26.11.4', platform: 'linux', network: 'Mainnet', node: 'local', relay: 'r', sync: 's'),
      at: now,
      ui: 'desktop',
      node: const NodeReportData(
        status: 'node: on\n',
        serverLog: '20261116 INFO peer 95.216.12.34:3414 connected\n20261116 WARN peer [2a01:4f9::1]:3414 banned\nheight 3000001\n',
        stdoutTail: 'stdout line from 8.8.4.4\n',
      ),
    );
    final names = [for (final f in report.files) f.name];
    expect(names, containsAll(['node/status.txt', 'node/epic-server.log', 'node/stdout.log']));
    final all = report.text;
    expect(all, isNot(contains('95.216.12.34')));
    expect(all, isNot(contains('2a01:4f9')));
    expect(all, isNot(contains('8.8.4.4')));
    expect(all, contains('height 3000001'));
  });
}
