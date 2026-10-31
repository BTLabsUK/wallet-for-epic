// SPDX-License-Identifier: Apache-2.0
// A fresh install opens no connection before its first-start step is answered
// (levels/first_start.dart): the gate holds every kind of connection, a real request never
// reaches a listening server, and the mode picked underneath (Undercover = Tor only) is the
// one the first connection is made in. An existing install is never held.
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/levels/first_start.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    NetGate.releaseFirstStart();
    NetGate.set(NetworkMode.standard);
  });

  test('a fresh install holds every connection until the step is answered', () async {
    final store = MemorySecretStore();
    expect(await holdUntilFirstStart(store), isTrue);
    expect(store.values[levelKey], levelPendingValue);
    expect(NetGate.firstStartHold, isTrue);

    // Every kind, to every host, loopback included.
    for (final kind in NetDial.values) {
      for (final host in ['node.example', '127.0.0.1', 'localhost']) {
        expect(NetGate.allows(kind, host), isFalse, reason: '${kind.name} $host');
      }
    }
    expect(() => NetGate.check('epicbox'), throwsA(isA<NetBlocked>()));
    expect(() => NetGate.checkNode('node tip'), throwsA(isA<NetBlocked>()));

    // A real request to a real server on this machine never arrives.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var hits = 0;
    final served = server.listen((r) {
      hits++;
      r.response.close();
    });
    addTearDown(() async {
      await served.cancel();
      await server.close(force: true);
    });
    final url = Uri.parse('http://127.0.0.1:${server.port}/status.json');
    // The HTTP layer reports the gate's refusal as a NetError ("Network mode").
    await expectLater(httpGet(url), throwsA(isA<NetError>()));
    expect(hits, 0);

    // Undercover picked: Tor only is stored underneath and takes over at the release.
    NetGate.set(NetworkMode.torOnly);
    expect(NetGate.mode, NetworkMode.killSwitch);
    NetGate.releaseFirstStart();
    expect(NetGate.firstStartHold, isFalse);
    expect(NetGate.mode, NetworkMode.torOnly);

    // Released in Normal, the same request goes through.
    NetGate.set(NetworkMode.standard);
    expect((await httpGet(url)).status, 200);
    expect(hits, 1);
  });

  test('an existing install is never held and lands on its level', () async {
    final store = MemorySecretStore({'app.qr_method_seen': '1'});
    expect(await holdUntilFirstStart(store), isFalse);
    expect(NetGate.firstStartHold, isFalse);
    expect(LevelChoice.decode(store.values[levelKey]), const LevelChosen(existingInstallLevel));
  });

  test('tasks waiting for the first start run once it is answered', () async {
    NetGate.holdFirstStart();
    var ran = 0;
    afterFirstStart(() => ran++);
    await Future<void>.delayed(Duration.zero);
    expect(ran, 0);
    NetGate.releaseFirstStart();
    await Future<void>.delayed(Duration.zero);
    expect(ran, 1);
  });
}
