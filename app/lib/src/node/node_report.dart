// SPDX-License-Identifier: Apache-2.0
/// What a problem report carries about the built-in node, so its state can be read without
/// asking the user: a snapshot taken at report time, the tail of its own log (`epic-server.log`)
/// and the last lines it wrote to stdout and stderr (the node keeps no stdout log, the app holds
/// them in memory). Plain text, cleaned by the report ([buildFeedbackReport]) like the app's log.
library;

import 'dart:io';

import 'fallback.dart';
import 'local_node_controller.dart';
import 'local_node_state.dart';

/// The newest lines and bytes of the node's own log a report keeps.
const int nodeReportLogLines = 2000;
const int nodeReportLogBytes = 200 * 1024;

class NodeReportData {
  const NodeReportData({required this.status, required this.serverLog, required this.stdoutTail});

  /// `key: value` lines, taken when the report was built.
  final String status;

  /// The tail of `epic-server.log`; empty when there is none.
  final String serverLog;

  /// The last lines of the node process's stdout and stderr; empty when none ran.
  final String stdoutTail;
}

/// Whether there is anything about the node to attach: it runs, ran in this session, or left a
/// log.
Future<bool> nodeWasUsed(LocalNodeController c) async =>
    c.state.phase != LocalNodePhase.stopped || c.spawns > 0 || await File(c.logPath).exists();

/// Reads the snapshot and the log tails. [publicSince] is when the wallet last moved to the
/// public node (the fallback); null when it has not this session.
Future<NodeReportData?> readNodeReport(
  LocalNodeController c, {
  FallbackChoice? choice,
  DateTime? publicSince,
  DateTime? now,
}) async {
  if (!await nodeWasUsed(c)) return null;
  final log = await c.logTail(lines: nodeReportLogLines, maxBytes: nodeReportLogBytes);
  final out = c.outputTail;
  return NodeReportData(
    status: nodeStatusText(
      c.state,
      spawns: c.spawns,
      tipSource: c.networkTipSource,
      choice: choice,
      publicSince: publicSince,
      logBytes: await _size(c.logPath),
      now: now ?? DateTime.now(),
    ),
    serverLog: log.isEmpty ? '' : '${log.join('\n')}\n',
    stdoutTail: out.isEmpty ? '' : '${out.join('\n')}\n',
  );
}

Future<int?> _size(String path) async {
  try {
    return await File(path).length();
  } on FileSystemException {
    return null;
  }
}

/// The snapshot as lines. Pure, for tests.
String nodeStatusText(
  LocalNodeState s, {
  required int spawns,
  required String tipSource,
  FallbackChoice? choice,
  DateTime? publicSince,
  int? logBytes,
  required DateTime now,
}) {
  final out = <String>[];
  void add(String key, Object? value) => out.add('$key: ${value ?? 'unknown'}');
  final running = s.phase != LocalNodePhase.stopped && s.phase != LocalNodePhase.error || s.stalled;
  final stage = s.progress?.stage;
  add('taken at', now.toUtc().toIso8601String());
  add('node', s.phase == LocalNodePhase.stopped ? 'off' : 'on');
  add('phase', s.phase.name);
  if (stage != null) add('sync status', stage.name);
  if (s.progress case final p?) {
    if (p.stageFraction != null) add('stage progress', '${(p.stageFraction! * 100).toStringAsFixed(1)}%');
    if (p.done != null && p.total != null) add('stage done', '${p.done} of ${p.total}');
  }
  if (s.reason != null) add('reason', s.reason);
  if (s.failure != null) add('failure', s.failure!.name);
  add('process running', running ? 'yes' : 'no');
  add('uptime', s.uptime == null ? 'none' : _duration(s.uptime!));
  add('started this session', '$spawns time${spawns == 1 ? '' : 's'}${spawns > 1 ? ' (${spawns - 1} restart${spawns == 2 ? '' : 's'})' : ''}');
  add('stalled', s.stalled ? 'yes' : 'no');
  add('local height', s.height);
  add('network tip', s.networkHeight);
  add('network tip from', s.networkHeight == null ? null : tipSource);
  add('blocks behind', s.blocksBehind);
  add('ready for txs', s.readyForTxs);
  add('peers', s.peers);
  add('node version', s.version);
  switch (choice) {
    case null:
      add('fallback', 'unknown');
    case FallbackChoice(consent: FallbackConsent.accepted):
      final using = decideFallback(s, choice).action == FallbackAction.usePublic;
      add('fallback', 'on (public node allowed)');
      add('wallet on public node now', using ? 'yes' : 'no');
      if (using || publicSince != null) {
        add('public node since', publicSince?.toUtc().toIso8601String());
      }
      add('fallback allowed at', choice.at?.toUtc().toIso8601String());
    default:
      add('fallback', 'off (${choice.consent.name})');
  }
  add('chain data size', s.chainDataBytes == null ? null : _bytes(s.chainDataBytes!));
  add('free disk', s.freeBytes == null ? null : _bytes(s.freeBytes!));
  add('node log size', logBytes == null ? 'none' : _bytes(logBytes));
  add('restart needed', s.restartNeeded ? 'yes' : 'no');
  add('own toml', s.userToml ? 'yes' : 'no');
  add('chain data', s.chainDataOrigin.name);
  return '${out.join('\n')}\n';
}

String _duration(Duration d) {
  final days = d.inDays, h = d.inHours % 24, m = d.inMinutes % 60, sec = d.inSeconds % 60;
  return [if (days > 0) '${days}d', if (days > 0 || h > 0) '${h}h', '${m}m', '${sec}s'].join(' ');
}

String _bytes(int b) {
  const gb = 1024 * 1024 * 1024, mb = 1024 * 1024;
  if (b >= gb) return '${(b / gb).toStringAsFixed(2)} GB';
  return '${(b / mb).toStringAsFixed(1)} MB';
}

