// SPDX-License-Identifier: Apache-2.0
// Desktop release check: settings.toml and the app in step, both ways (docs/settings-file.md).
// Real LEPIC, the node and Epicbox server tool/release_check.sh picked, a fresh HOME. Checks the
// first start writes the shipped file, a hand edit shows up while the app runs, an app change
// lands in the file with the user's text kept, a broken file is never rewritten (and saved aside
// when the app must write), a deleted file comes back, and a hand-edited Epicbox server moves the
// wallet's address. Never prints the phrase or the password; the wallet stays empty.
import 'dart:io';

import 'package:epic_wallet/src/data_folder.dart' show appDataDirectory;
import 'package:epic_wallet/src/desktop/app/routes.dart' show DeskRoute, deskNavProvider;
import 'package:epic_wallet/src/desktop/data/state.dart' show deskApiProvider, deskProvider;
import 'package:epic_wallet/src/desktop/widgets/server_list_panel.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

const relay = String.fromEnvironment('WFE_CHECK_RELAY', defaultValue: freshRelay);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: settings.toml both ways', (tester) async {
    captureErrors();
    final dir = (await tester.runAsync(appDataDirectory))!;
    final file = File('${dir.path}${Platform.pathSeparator}settings.toml');
    record('fresh data folder has no settings.toml', !file.existsSync(), file.path);

    await boot(tester);
    final shipped = (await tester.runAsync(() => rootBundle.loadString('assets/settings/settings.toml')))!;
    record('first start writes settings.toml', file.existsSync(), file.path);
    record('first file is the shipped default, byte for byte', file.existsSync() && file.readAsStringSync() == shipped,
        '${file.existsSync() ? file.lengthSync() : 0} bytes vs ${shipped.length}');

    // A wallet, on the servers the run picked (the app writes those picks to the file).
    final password = randomPassword();
    await tapText(tester, 'Create a new wallet');
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Create wallet', last: true);
    await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
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
    await pickNode(tester, node);
    String nodeInUse() => containerOf(tester).read(deskProvider).status?.node.url ?? '?';
    String relayInUse() => containerOf(tester).read(deskProvider).status?.epicbox.domain ?? '?';
    record('app pick of the node is written to the file', file.readAsStringSync().contains('use = "$node"'), nodeInUse());

    // File → app: a hand-added Epicbox server shows in the Epicbox list while the app runs.
    final handBlock = '\n# Added by hand while the app runs.\n[[epicbox.servers]]\nhost = "relay.example.invalid"\noperator = "Hand edit"\n';
    file.writeAsStringSync(file.readAsStringSync() + handBlock);
    await pumpUntil(tester, () => hostSettings.epicboxServers.any((s) => s.host == 'relay.example.invalid'),
        timeout: const Duration(seconds: 20), what: 'hand edit read');
    containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.settingsNode);
    await settle(tester, ms: 800);
    await tapText(tester, RegExp(r'^Receiving$'));
    await settle(tester, ms: 800);
    await tester.ensureVisible(find.byType(ServerListPanel).first);
    await tester.tap(find.byType(ServerListPanel).first, warnIfMissed: false);
    await settle(tester, ms: 1200);
    await shot(tester, 'settings-01-hand-relay');
    record('hand-added relay shows in the Epicbox list', hasText('relay.example.invalid'), shownTexts(12));
    await key(tester, LogicalKeyboardKey.escape);
    await settle(tester);

    // App → file: a node added in Settings › Node is written at once, the hand edit kept.
    Future<void> addNode(String value) async {
      containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.settingsNode);
      await settle(tester, ms: 1200);
      await tester.ensureVisible(find.byType(ServerListPanel).first);
      await tester.tap(find.byType(ServerListPanel).first, warnIfMissed: false);
      await settle(tester, ms: 800);
      final field = find.descendant(of: find.byKey(const ValueKey('server-list-field')), matching: find.byType(EditableText));
      await tester.enterText(field, value);
      await settle(tester, ms: 800);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester, ms: 2000);
      await key(tester, LogicalKeyboardKey.escape);
      await settle(tester);
    }

    await addNode('node.example.invalid:3413');
    final afterAdd = file.readAsStringSync();
    record('node added in the app is in the file', afterAdd.contains('node.example.invalid:3413'), '');
    record('the hand edit and its comment are kept', afterAdd.contains(handBlock.trim()), '');
    record('the shipped comments are kept', afterAdd.contains('# Epic Cash wallet settings'), '');

    // A hand edit of the node in use: the wallet reconnects to it.
    final otherNode = node2 == node ? node : node2;
    file.writeAsStringSync(file.readAsStringSync().replaceFirst('use = "$node"', 'use = "$otherNode"'));
    await pumpUntil(tester, () => nodeInUse() == otherNode, timeout: const Duration(minutes: 2), what: 'node switch');
    record('hand-edited node.use is used live', nodeInUse() == otherNode, nodeInUse());

    // A broken file: kept as it is, the last good settings stay, a notice names the line.
    final broken = '${file.readAsStringSync()}\n[[broken\n';
    file.writeAsStringSync(broken);
    await pumpUntil(tester, () => hasText(RegExp(r'settings\.toml, line \d+')), timeout: const Duration(seconds: 20), what: 'broken notice');
    await shot(tester, 'settings-02-broken-notice');
    record('a broken file shows a notice with its line', hasText(RegExp(r'settings\.toml, line \d+')), shownTexts(8));
    await settle(tester, ms: 3000);
    record('a broken file is not rewritten', file.readAsStringSync() == broken, '');
    record('the last good settings stay in use', nodeInUse() == otherNode && hostSettings.nodeUse == otherNode, nodeInUse());

    // The app must write while the file is broken: the file is saved aside first.
    await addNode('node2.example.invalid:3413');
    final backups = dir.listSync().whereType<File>().where((f) => f.path.contains('settings.toml.bad-')).toList();
    record('a write while broken saves settings.toml.bad-<time>', backups.length == 1 && backups.first.readAsStringSync() == broken,
        backups.map((f) => f.uri.pathSegments.last).join(', '));
    final rewritten = file.readAsStringSync();
    record('then writes a good file with the change', !rewritten.contains('[[broken') && rewritten.contains('node2.example.invalid:3413'), '');

    // The file deleted while the app runs: written again from the settings in use.
    file.deleteSync();
    await pumpUntil(tester, file.existsSync, timeout: const Duration(seconds: 20), what: 'file written again');
    await settle(tester, ms: 1500);
    await shot(tester, 'settings-03-recreated');
    record('a deleted file is written again', file.existsSync() && file.readAsStringSync().contains('node2.example.invalid:3413'), '');
    record('and a notice says so', hasText('settings.toml was missing'), shownTexts(8));

    // A hand edit of the Epicbox server in use moves the wallet's address to it.
    final api = containerOf(tester).read(deskApiProvider);
    final before = (await tester.runAsync(api.epicboxAddress))!;
    final target = relay == freshRelay ? 'epicbox.stackwallet.com' : freshRelay;
    final from = hostSettings.epicboxUse;
    file.writeAsStringSync(file.readAsStringSync().replaceFirst('use = "$from"', 'use = "$target"'));
    await pumpUntil(tester, () => relayInUse() == target, timeout: const Duration(minutes: 2), what: 'relay switch');
    await settle(tester, ms: 3000);
    final after = (await tester.runAsync(api.epicboxAddress))!;
    record('hand-edited epicbox.use moves the address', after.endsWith('@$target') && after.split('@').first == before.split('@').first,
        '${before.split('@').last} -> ${after.split('@').last}');
    await shot(tester, 'settings-04-relay-switched');

    record('no Flutter errors', flutterErrors.isEmpty, flutterErrors.take(3).join(' | '));
  }, timeout: const Timeout(Duration(minutes: 20)));
}
