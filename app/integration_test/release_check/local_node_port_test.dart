// SPDX-License-Identifier: Apache-2.0
// Desktop live check of the bundled node's ports (Settings › Node › Local node › Advanced): a
// fresh wallet, the Local node dialog with API 13413 and P2P 13414 typed under Advanced, Start
// local node; then the node must listen on both ports (`ss -ltn`), the app must reach it (its
// probe answers from the node), settings.toml must hold `[local_node]`, and Stop must free the
// ports. Needs the `epic` binary at `<bundle>/bin/epic` (tool/release_check.sh pattern). Never
// prints the phrase or the password; the wallet stays empty.
import 'dart:io';

import 'package:epic_wallet/src/data_folder.dart' show appDataDirectory;
import 'package:epic_wallet/src/desktop/app/routes.dart' show DeskRoute, deskNavProvider;
import 'package:epic_wallet/src/desktop/data/desk_node.dart' show deskNodeProvider;
import 'package:epic_wallet/src/desktop/data/state.dart' show deskProvider;
import 'package:epic_wallet/src/desktop/screens/onboarding/local_node_step.dart' show LocalNodePortsFields;
import 'package:epic_wallet/src/advanced.dart' show AdvancedFeature;
import 'package:epic_wallet/src/node/local_node_state.dart' show LocalNodePhase;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

const apiPort = 13413;
const p2pPort = 13414;

Future<String> listening(WidgetTester tester) async {
  final r = (await tester.runAsync(() => Process.run('ss', ['-ltn'])))!;
  final lines = '${r.stdout}'.split('\n').where((l) => l.contains(':$apiPort ') || l.contains(':$p2pPort ')).map((l) => l.trim()).toList();
  return lines.join(' | ');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop: the bundled node on ports set under Advanced', (tester) async {
    captureErrors();
    final dir = (await tester.runAsync(appDataDirectory))!;
    final file = File('${dir.path}${Platform.pathSeparator}settings.toml');
    // The bundled binary (lib/src/builtin_node_provider.dart: bin/epic beside the executable).
    // The test build makes the bundle afresh, so the test puts the node there itself.
    final epicBin = Platform.environment['RC_EPIC_BIN'] ?? '${Platform.environment['RC_EPIC_HOME'] ?? Platform.environment['HOME']}/epic/qa-funder/bin/epic';
    final binDir = Directory('${File(Platform.resolvedExecutable).parent.path}/bin');
    await tester.runAsync(() async {
      await binDir.create(recursive: true);
      await File(epicBin).copy('${binDir.path}/epic');
    });
    record('the epic binary is beside the app', File('${binDir.path}/epic').existsSync(), '${binDir.path}/epic from $epicBin');
    await boot(tester);

    final password = randomPassword();
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
    await settle(tester, ms: 2000);
    if (hasText('Skip tour')) await tapText(tester, 'Skip tour');

    final c = containerOf(tester);
    final desk = c.read(deskProvider.notifier);
    final s = c.read(deskProvider).settings;
    await tester.runAsync(() => desk.saveSettings(s.copyWith(advanced: s.advanced.withFeature(AdvancedFeature.builtInNode, true))));
    await settle(tester);
    c.read(deskNavProvider.notifier).go(DeskRoute.settingsNode);
    await settle(tester, ms: 1500);
    record('before: nothing listens on $apiPort/$p2pPort', (await listening(tester)).isEmpty, await listening(tester));

    // The Local node row sits in the Node server combobox: open it first.
    await tester.tap(find.bySemanticsLabel(RegExp('^Node server: ')).first, warnIfMissed: false);
    await settle(tester, ms: 800);
    await tester.ensureVisible(find.byKey(const ValueKey('server-row-local')));
    await tester.tap(find.byKey(const ValueKey('server-row-local')));
    await settle(tester, ms: 800);
    await waitText(tester, 'Start the bundled node', timeout: const Duration(seconds: 20));
    // The fold by its key: "Advanced" is also the Settings sidebar's entry.
    await tester.ensureVisible(find.byKey(const ValueKey('local-node-advanced')));
    await tester.tap(find.byKey(const ValueKey('local-node-advanced')), warnIfMissed: false);
    await settle(tester, ms: 600);
    expect(hasText('API port'), isTrue, reason: 'the fold opened: ${shownTexts(20)}');
    // Semantics are off in the real app: the two fields by their place in the ports widget.
    final fields = find.descendant(of: find.byType(LocalNodePortsFields), matching: find.byType(EditableText));
    expect(fields, findsNWidgets(2), reason: shownTexts(20));
    await tester.enterText(fields.at(0), '$apiPort');
    await tester.enterText(fields.at(1), '$p2pPort');
    await settle(tester, ms: 600);
    record('the dialog shows the typed ports beside Advanced', hasText('API $apiPort · P2P $p2pPort'), shownTexts(12));
    await shot(tester, 'local-node-ports-dialog');
    await tapText(tester, 'Start local node');
    await settle(tester, ms: 2000);
    if (hasText('Existing blockchain data')) await tapText(tester, 'Continue', last: true);

    final api = c.read(deskNodeProvider);
    final end = DateTime.now().add(const Duration(seconds: 90));
    var ports = '';
    while (DateTime.now().isBefore(end)) {
      ports = await listening(tester);
      if (ports.contains(':$apiPort ') && ports.contains(':$p2pPort ')) break;
      await settle(tester, ms: 2000);
    }
    record('ss -ltn: the node listens on $apiPort and $p2pPort', ports.contains(':$apiPort ') && ports.contains(':$p2pPort '), ports);
    final text = file.existsSync() ? file.readAsStringSync() : '';
    record('settings.toml holds [local_node] with both ports', text.contains('[local_node]') && text.contains('api_port = $apiPort') && text.contains('p2p_port = $p2pPort'), text.substring(text.indexOf('[local_node]').clamp(0, text.length)).trim().replaceAll('\n', ' / '));
    final state = (await tester.runAsync(() => api.states().first))!;
    record('the app has the node running', state.phase != LocalNodePhase.stopped && state.phase != LocalNodePhase.error, 'phase ${state.phase.name}, height ${state.height}, failure ${state.failure?.name}, reason ${state.reason}');
    final probe = (await tester.runAsync(() => api.probe(url: 'http://127.0.0.1:$apiPort')))!;
    record('the app reaches the node at 127.0.0.1:$apiPort', probe.answers, 'answers ${probe.answers}, ours ${probe.ours}, version ${probe.version}, height ${probe.height}');
    await shot(tester, 'local-node-ports-running');

    await tester.runAsync(() => api.stop());
    await settle(tester, ms: 3000);
    final stopEnd = DateTime.now().add(const Duration(seconds: 30));
    var after = await listening(tester);
    while (after.isNotEmpty && DateTime.now().isBefore(stopEnd)) {
      await settle(tester, ms: 2000);
      after = await listening(tester);
    }
    record('after Stop: nothing listens on $apiPort/$p2pPort', after.isEmpty, after);
    record('no Flutter errors', flutterErrors.isEmpty, flutterErrors.join('; '));
  });
}
