// macOS: the tor bundled in the release .app, started through LEPIC as the desktop app starts it,
// connects to the Tor network, and the wallet asks a public node for its tip over it. Run by
// tools/build-apple.sh smoke with --dart-define=WFE_TEST_TOR=<the .app's
// Contents/Resources/bin/tor-bundle/tor>. Needs the internet. Skipped without WFE_TEST_TOR and
// off macOS.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/btlabs_onions.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _tor = String.fromEnvironment('WFE_TEST_TOR');

/// In the order the check tries them; the first that answers over Tor passes.
const _nodes = [
  'https://node.btlabs.uk',
  'https://node.epicnet.us:3413',
  'https://node.epiccash.com:3413',
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initLepic();
  });

  testWidgets(
    'bundled tor: starts, bootstraps, carries a node request',
    (tester) async {
      final base = await getTemporaryDirectory();
      final dir = await base.createTemp('wfe-it-tor-');
      addTearDown(() => dir.delete(recursive: true));
      final config = mainnetPreset.config(dataDir: dir.path, nodeUrl: _nodes.first);
      final lepic = LepicWalletService(secrets: MemorySecretStore());
      final created = await lepic.createWithPin(config: config, pin: '123456');
      final session = created.session;
      addTearDown(session.dispose);
      await session.setOnionRoutes(onionRoutesOf(OnionDirectory()));

      final libDir = File(_tor).parent.path;
      // ignore: avoid_print
      print('TOR-CHECK binary $_tor');
      final bootstrapped = Completer<TorEvent>();
      final sub = session.startTor(torBinary: _tor, libDir: libDir).listen((e) {
        // ignore: avoid_print
        print('TOR-CHECK event ${e.kind.name} progress=${e.progress} '
            'socks=${e.socksPort} failure=${e.failure?.name}');
        if (bootstrapped.isCompleted) return;
        if (e.kind == TorEventKind.bootstrapped || e.kind == TorEventKind.ready) {
          bootstrapped.complete(e);
        } else if (e.kind == TorEventKind.failed || e.kind == TorEventKind.stopped) {
          bootstrapped.completeError('tor ${e.kind.name}: ${e.failure?.name}');
        }
      });
      addTearDown(sub.cancel);
      await bootstrapped.future.timeout(const Duration(minutes: 4));
      final status = await session.torStatus();
      // ignore: avoid_print
      print('TOR-CHECK status ${status.kind.name} socks=${status.socksPort}');

      String? answered;
      for (final url in _nodes) {
        try {
          final tip = await session
              .nodeTipFor(config: mainnetPreset.config(dataDir: dir.path, nodeUrl: url))
              .timeout(const Duration(seconds: 90));
          // ignore: avoid_print
          print('TOR-CHECK node $url over tor: height ${tip.height}, ${tip.nodeVersion}');
          answered = url;
          break;
        } catch (e) {
          // ignore: avoid_print
          print('TOR-CHECK node $url over tor failed: $e');
        }
      }
      await session.stopTor();
      expect(answered, isNotNull, reason: 'no node answered over tor');
    },
    skip: _tor.isEmpty || !Platform.isMacOS,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
