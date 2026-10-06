// The real server binary on real LEPIC: two demos create wallets with PINs, read different
// epicbox addresses, and leave no directory once they expire. Needs the Linux library and
// creates floonet wallets locally; run it by hand, from app/:
//
//   WFE_DEMO_LEPIC_LIB=$PWD/third_party/lepic/bindings/flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so \
//     flutter test test/demo_server/lepic_server_test.dart
//
// Without WFE_DEMO_LEPIC_LIB it is skipped, so the gate stays offline and fast.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/demo_server/server.dart';
import 'package:epic_wallet/src/demo_server/ws_channel.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/remote/client.dart';
import 'package:flutter_test/flutter_test.dart';

final String? library = Platform.environment['WFE_DEMO_LEPIC_LIB'];

void main() {
  test(
    'two demos on LEPIC get their own wallets, and expiry removes both',
    () async {
      final root = await Directory.systemTemp.createTemp('wfe-demo-lepic-');
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final dart = '${Platform.environment['FLUTTER_ROOT']}/bin/dart';
      final server = await Process.start(dart, [
        'run',
        'bin/wfe_demo_server.dart',
        '--data-root',
        root.path,
        '--port',
        '0',
        '--ttl',
        '40s',
        '--sweep',
        '1s',
        '--secure-cookie',
        '0',
        '--lepic-lib',
        library!,
      ]);
      final log = <String>[];
      final port = Completer<int>();
      server.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            log.add(line);
            final m = RegExp(r'listening on [\d.]+:(\d+)').firstMatch(line);
            if (m != null && !port.isCompleted) {
              port.complete(int.parse(m.group(1)!));
            }
          });
      server.stderr.transform(utf8.decoder).listen(log.add);
      addTearDown(() => server.kill(ProcessSignal.sigkill));
      final p = await port.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => fail('server did not start:\n${log.join('\n')}'),
      );
      final base = 'http://127.0.0.1:$p';

      Future<String> startDemo() async {
        final client = HttpClient();
        final req = await client.postUrl(Uri.parse('$base/api/demo'));
        req.headers.set('origin', base);
        final res = await req.close();
        await res.drain<void>();
        client.close();
        expect(res.statusCode, HttpStatus.created);
        return res.cookies.firstWhere((c) => c.name == demoCookie).value;
      }

      /// The demo's address, and its socket's first push.
      Future<(String, Future<String>)> walletAddress(String id) async {
        final remote = RemoteWalletService(
          await IoWebSocketChannel.connect(
            'ws://127.0.0.1:$p/api/ws',
            headers: {'origin': base, 'cookie': '$demoCookie=$id'},
          ),
        );
        // What the browser sends is replaced by the demo's own config.
        final config = mainnetPreset.config(
          dataDir: '/nowhere',
          nodeUrl: mainnetPreset.nodeUrl,
        );
        final w = await remote.createWithPin(config: config, pin: '123456');
        expect(w.sealedPassword, isNotEmpty);
        final address = await w.session.epicboxAddress();
        expect(remote.validateEpicboxAddress(address: address), isTrue);
        expect(address, endsWith('@flooepicbox.btlabs.uk'));
        // A reload: the PIN opens the same wallet on a new socket.
        await remote.close();
        final again = RemoteWalletService(
          await IoWebSocketChannel.connect(
            'ws://127.0.0.1:$p/api/ws',
            headers: {'origin': base, 'cookie': '$demoCookie=$id'},
          ),
        );
        final s = await again.openWithPin(
          config: config,
          pin: '123456',
          sealedPassword: w.sealedPassword,
        );
        expect(await s.epicboxAddress(), address);
        return (address, again.pushes.first.then((push) => push.name));
      }

      final a = await startDemo();
      final b = await startDemo();
      final (addressA, endedA) = await walletAddress(a);
      final (addressB, endedB) = await walletAddress(b);
      expect(addressA, isNot(addressB));
      for (final id in [a, b]) {
        expect(
          await File('${root.path}/demos/$id/secrets.json').exists(),
          isTrue,
        );
        expect(
          await Directory('${root.path}/demos/$id/wallet/lepic').exists(),
          isTrue,
        );
      }

      // Both expire: each socket hears demoEnded, and the directories go.
      final pushes = await Future.wait([endedA, endedB])
          .timeout(const Duration(seconds: 90));
      expect(pushes, [demoEndedPush, demoEndedPush]);
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (await Directory('${root.path}/demos').list().isEmpty == false &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      expect(await Directory('${root.path}/demos').list().toList(), isEmpty);

      server.kill(ProcessSignal.sigint);
      expect(await server.exitCode.timeout(const Duration(seconds: 20)), 0);
      final text = log.join('\n');
      expect(text, contains('demo ${a.substring(0, 8)} ended (expired)'));
      expect(text, isNot(contains(a.substring(0, 9))));
      expect(text, isNot(contains('deleteWallet')), reason: text);
      // ignore: avoid_print
      print(text);
    },
    skip: library == null ? 'set WFE_DEMO_LEPIC_LIB to run on LEPIC' : false,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
