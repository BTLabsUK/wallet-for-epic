// SPDX-License-Identifier: Apache-2.0
// Desktop HTTP From the internet on the real LEPIC core: the listener on 0.0.0.0, Receive showing
// the router's public IP and the port check on the real network, both asked of the status server
// (`[status] ip` and `reach` of app-config.toml).
// A throwaway empty wallet; nothing is sent. On a network without a forwarded port the warning shows.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/state.dart' show deskApiProvider, deskProvider;
import 'package:epic_wallet/src/settings_file/host_settings.dart' show appConfig;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: HTTP from the internet shows the public IP and its reachability', (tester) async {
    captureErrors();
    final password = randomPassword();
    await boot(tester);
    await tapText(tester, 'Create a new wallet');
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Create wallet', last: true);
    await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
    await tapText(tester, 'Reveal phrase');
    await tapText(tester, RegExp('[Ww]ritten down'));
    await tapText(tester, 'Continue', last: true);
    // Setup: node, Epicbox and Review with their defaults.
    for (var i = 0; i < 4 && !hasText('Unlock wallet'); i++) {
      await waitText(tester, RegExp(r'^(Continue|Save settings)$'));
      await settle(tester, ms: 1000);
      await tapText(tester, hasText('Save settings') ? 'Save settings' : 'Continue', last: true);
      await settle(tester, ms: 3000);
    }
    await waitText(tester, 'Unlock wallet');
    await typeIn(tester, 0, password);
    await tapText(tester, 'Unlock', last: true);
    await waitText(tester, RegExp('Overview|Balance'), timeout: const Duration(seconds: 120));
    await settle(tester, ms: 3000);
    if (hasText('Skip tour')) await tapText(tester, 'Skip tour');

    // Settings › Receiving: HTTP on, then From the internet through the guide.
    final desk = containerOf(tester).read(deskProvider.notifier);
    await tester.runAsync(() => desk.setHttp(true));
    await tapText(tester, 'Settings');
    await tapText(tester, 'Receiving');
    await settle(tester, ms: 1500);
    await tapText(tester, 'From the internet');
    await settle(tester, ms: 800);
    await tapText(tester, 'Receive from the internet', last: true);
    await settle(tester, ms: 3000);
    await waitText(tester, RegExp('reachable from the internet|Public IP not found|Reachability unknown'), timeout: const Duration(seconds: 60));
    await shot(tester, 'http-public-settings');

    final ss = Process.runSync('ss', ['-ltnH']).stdout as String;
    final port = appConfig.httpListenPort;
    record('listener bound on all interfaces', ss.contains('0.0.0.0:$port'), ss.split('\n').where((l) => l.contains(':$port')).join(' / '));

    final reach = await tester.runAsync(() => containerOf(tester).read(deskApiProvider).httpReach());
    // The status server's answer, asked here directly: the app must show the same address.
    final seen = (await tester.runAsync(() async {
      final c = HttpClient();
      try {
        final r = await (await c.getUrl(Uri.parse(appConfig.statusIp!))).close();
        final body = await r.transform(const SystemEncoding().decoder).join();
        final j = jsonDecode(body);
        return j is Map ? '${j['ip']}' : '';
      } finally {
        c.close();
      }
    }))!.trim();
    record('public IP is the router’s', reach?.publicIp == seen, 'app ${reach?.publicIp} / status $seen / lan ${reach?.lan} / reachable ${reach?.reachable}');

    await tapText(tester, 'Receive');
    await settle(tester, ms: 2000);
    await waitText(tester, RegExp('reachable from the internet|Public IP not found|Reachability unknown'), timeout: const Duration(seconds: 60));
    final address = await tester.runAsync(() => containerOf(tester).read(deskApiProvider).httpAddress());
    record('Receive shows http://<public IP>:<port>', address == 'http://$seen:$port' && find.textContaining(address!, skipOffstage: false).evaluate().isNotEmpty, '$address');
    record('warning shown when the port is not forwarded', reach?.reachable != false || hasText('Not reachable from the internet'), texts().where((t) => t.contains('reachable') || t.contains('Forward')).join(' | '));
    dump('receive');
    await shot(tester, 'http-public-receive');
    record('no Flutter errors', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
  });
}
