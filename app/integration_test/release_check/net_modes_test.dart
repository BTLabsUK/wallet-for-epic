// SPDX-License-Identifier: Apache-2.0
// The network-mode proof (docs/network-modes.md): the real desktop wallet on real LEPIC, started
// with settings.toml naming a network mode, inside tool/offline_check.sh's namespace WITH the
// network (OFFLINE_ONLINE=1) and every connect() and DNS question traced (OFFLINE_TRACE=1). The
// trace, not this test, is the proof: tool/net_trace_summary.py lists what each process reached.
// This test makes the app do what reaches out: start in the mode, create a wallet, sit on
// Overview while its timers run, and call the app's own requests (status site, price, IP,
// update downloads, problem reports, an Epicbox probe) the way their screens do.
//
//   NET_MODE=kill_switch|node_only|tor_only   the mode written before the first start
//   NET_NODE=https://host[:port]              Node only: the one node in the list
//   NET_IDLE_S=90                             how long Overview runs
//   NET_TOR_BUNDLE=<dir>                      tools/fetch-tor.sh linux output, copied beside the
//                                             test build's executable (bin/tor-bundle)
//   NET_TOR=1                                 the Tor switch turned on once the wallet is open
//                                             (Node only: tor carries the node and must publish
//                                             no onion; the trace shows ADD_ONION and listen())
//
//   OFFLINE_ONLINE=1 OFFLINE_TRACE=1 NET_MODE=kill_switch \
//     build-slot tool/offline_check.sh integration_test/release_check/net_modes_test.dart
@Tags(['release-check'])
library;

import 'dart:io';

import 'package:epic_wallet/src/desktop/app/desk_app.dart' show DeskApp;
import 'package:epic_wallet/src/desktop/data/state.dart' show deskProvider;
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/net/ws_probe.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

final home = Platform.environment['RC_HOME'] ?? Directory.systemTemp.path;
final mode = Platform.environment['NET_MODE'] ?? 'kill_switch';
final node = Platform.environment['NET_NODE'] ?? '';
final idle = int.tryParse(Platform.environment['NET_IDLE_S'] ?? '') ?? 90;
final withTor = Platform.environment['NET_TOR'] == '1';

/// The app's own requests, as their screens make them: each answered or refused by the gate.
Future<Map<String, String>> callOut() async {
  final c = hostSettings.config;
  final urls = <String, String?>{
    'status directory': c.statusDirectory,
    'price': c.statusPrice,
    'reach/IP': c.statusIp,
    'update downloads': c.updateDownloads,
    'problem report': c.supportReport,
  };
  final out = <String, String>{};
  for (final e in urls.entries) {
    final url = e.value;
    if (url == null) continue;
    try {
      final r = await httpGet(Uri.parse(url), timeout: const Duration(seconds: 15));
      out[e.key] = 'answered ${r.status}';
    } on NetBlocked {
      out[e.key] = 'refused by the mode';
    } on Object catch (x) {
      out[e.key] = 'failed ${x.runtimeType}';
    }
  }
  for (final s in hostSettings.epicboxServers.take(1)) {
    try {
      final ok = await probeWebSocket(Uri.parse('wss://${s.label}'), timeout: const Duration(seconds: 15));
      out['Epicbox probe'] = ok ? 'answered' : 'no answer';
    } on NetBlocked {
      out['Epicbox probe'] = 'refused by the mode';
    } on Object catch (x) {
      out['Epicbox probe'] = 'failed ${x.runtimeType}';
    }
  }
  return out;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: network mode $mode from the first start', (tester) async {
    captureErrors();
    await tester.runAsync(() async {
      final f = File('$home/.epic_cash_desktop/settings.toml');
      await f.parent.create(recursive: true);
      final nodes = node.isEmpty ? '' : '[node]\nservers = ["$node"]\n\n';
      await f.writeAsString('$nodes[network]\nmode = "$mode"\n');
    });
    final torSrc = Platform.environment['NET_TOR_BUNDLE'] ?? '';
    if (torSrc.isNotEmpty) {
      final dest = '${File(Platform.resolvedExecutable).parent.path}/bin/tor-bundle';
      await tester.runAsync(() async {
        await Directory(dest).create(recursive: true);
        await Process.run('cp', ['-a', '$torSrc/.', dest]);
      });
    }
    final password = randomPassword();
    await boot(tester);
    await settle(tester, ms: 3000);
    record('the app starts in the saved mode', NetGate.mode.name == {'kill_switch': 'killSwitch', 'node_only': 'nodeOnly', 'tor_only': 'torOnly'}[mode],
        'gate ${NetGate.mode.name}, file $mode');

    await tapText(tester, 'Create a new wallet');
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Create wallet', last: true);
    await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
    await tapText(tester, 'Reveal phrase');
    await tapText(tester, RegExp('[Ww]ritten down'));
    await tapText(tester, 'Continue', last: true);
    await waitText(tester, 'Skip setup', timeout: const Duration(seconds: 60));
    await tapText(tester, 'Skip setup');
    await waitText(tester, RegExp('Unlock wallet|Available to spend|Skip tour'), timeout: const Duration(seconds: 120));
    if (hasText('Unlock wallet')) {
      await typeIn(tester, 0, password);
      await tapText(tester, 'Unlock', last: true);
    }
    await waitText(tester, RegExp('Overview|Balance'), timeout: const Duration(seconds: 120));
    record('the wallet opens to Overview', true);
    await settle(tester, ms: 2000);
    if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
    await shot(tester, 'net-$mode-overview');
    if (withTor) {
      final desk = ProviderScope.containerOf(tester.element(find.byType(DeskApp))).read(deskProvider.notifier);
      await tester.runAsync(() => desk.setTor(true));
      record('the Tor switch turned on', true);
    }

    final calls = await tester.runAsync(callOut) ?? const {};
    for (final e in calls.entries) {
      // A probe may answer "no answer" for a refusal; the trace says whether anything left.
      final refused = !e.value.startsWith('answered');
      // Tor only lets them through tor; Kill switch and Node only refuse every one of them.
      record('${e.key}: ${e.value}', mode == 'tor_only' || refused);
    }

    // The app's own timers (status, price, refresh, listener, tip watch) run meanwhile.
    final end = DateTime.now().add(Duration(seconds: idle));
    while (DateTime.now().isBefore(end)) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      await tester.pump();
    }
    await shot(tester, 'net-$mode-after');
    record('no uncaught errors', flutterErrors.isEmpty, flutterErrors.take(3).join(' | '));
  });
}
