// SPDX-License-Identifier: Apache-2.0
// First run's server pick: the node and the Epicbox server in use stay when they answer (or
// could not be asked); one that does not gives way to the first of its list that does, which
// becomes the first of the list. Nothing answering leaves the lists as they were.
import 'package:epic_wallet/src/first_run_servers.dart';
import 'package:epic_wallet/src/net/probe_not_run.dart';
import 'package:epic_wallet/src/network.dart' show EpicboxRelay;
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_settings.dart';

const _n1 = 'https://n1.example';
const _n2 = 'https://n2.example';
const _n3 = 'https://n3.example';

HostSettings _settings() => testSettings().withValues({
  'node.servers': [_n1, _n2, _n3],
  'epicbox.servers': ['r1.example', 'r2.example', 'r3.example'],
});

Future<({FirstRunPick pick, Map<String, Object>? saved})> _run({
  Set<String> deadNodes = const {},
  Set<String> deadRelays = const {},
  bool relaysNotRun = false,
}) async {
  Map<String, Object>? saved;
  final pick = await moveToAnsweringServers(
    _settings(),
    nodeAnswers: (url) async => !deadNodes.contains(url),
    relayAnswers: (r) async {
      if (relaysNotRun) throw const ProbeNotRun();
      if (deadRelays.contains(r.host)) throw Exception('refused');
      return true;
    },
    save: (values) async => saved = values,
  );
  return (pick: pick, saved: saved);
}

void main() {
  test('servers in use that answer stay; nothing is written', () async {
    final r = await _run();
    expect(r.pick.node, isNull);
    expect(r.pick.relay, isNull);
    expect(r.saved, isNull);
  });

  test('a node and a relay that do not answer give way to the first of each list that does', () async {
    final r = await _run(deadNodes: {_n1, _n2}, deadRelays: {'r1.example'});
    expect(r.pick.node, _n3);
    expect(r.pick.relay, const EpicboxRelay(host: 'r2.example'));
    expect(r.saved!['node.servers'], [_n3, _n1, _n2]);
    expect(r.saved!['epicbox.servers'], ['r2.example', 'r1.example', 'r3.example']);
  });

  test('only the one that does not answer moves', () async {
    final r = await _run(deadRelays: {'r1.example'});
    expect(r.pick.node, isNull);
    expect(r.saved!.containsKey('node.servers'), isFalse);
    expect(r.saved!['epicbox.servers'], ['r2.example', 'r1.example', 'r3.example']);
  });

  test('nothing answering, or probes that could not run: the lists stay', () async {
    expect((await _run(deadNodes: {_n1, _n2, _n3})).saved, isNull);
    expect((await _run(relaysNotRun: true)).saved, isNull);
  });

  test('no pick under way: creation does not wait', () async {
    resetFirstRunServers();
    await firstRunServersSettled();
  });
}
