// The dispatcher's server hooks and its handling of raw frames.

import 'dart:async';
import 'dart:convert';

import 'package:epic_wallet/src/remote/channel.dart';
import 'package:epic_wallet/src/remote/client.dart';
import 'package:epic_wallet/src/remote/dispatcher.dart';
import 'package:epic_wallet/src/remote/protocol.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

const config = WalletConfig(
  dataDir: '/client/dir',
  chain: Chain.mainnet,
  nodeUrl: 'https://client.node',
  epicboxDomain: 'client.relay',
  epicboxPort: 1,
);

const serverConfig = WalletConfig(
  dataDir: '/server/demo',
  chain: Chain.floonet,
  nodeUrl: 'https://floo-node.example',
  epicboxDomain: 'flooepicbox.example',
  epicboxPort: 443,
);

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// A fake whose nodeTip fails with something other than a [WalletError].
class CrashingService extends FakeWalletService {
  @override
  Future<NodeTip> nodeTip({required WalletConfig config}) async =>
      throw StateError('/server/secret/path broke');
}

/// Raw frames against a dispatcher, without the client.
class RawPeer {
  RawPeer(this.end) {
    end.incoming.listen(
      (t) => replies.add(jsonDecode(t) as Map<String, Object?>),
    );
  }

  final RpcChannel end;
  final List<Map<String, Object?>> replies = [];

  Future<Map<String, Object?>> send(String frame) async {
    final before = replies.length;
    end.send(frame);
    await settle();
    expect(replies.length, before + 1, reason: 'one reply to $frame');
    return replies.last;
  }

  Future<void> sendUnanswered(String frame) async {
    final before = replies.length;
    end.send(frame);
    await settle();
    expect(replies.length, before, reason: 'no reply to $frame');
  }
}

Map<String, Object?> errorOf(WalletError e) => {
  'kind': e.kind.name,
  'message': e.message,
};

void main() {
  test('the filter refuses named members, seeing their parameters', () async {
    final fake = FakeWalletService();
    final (a, b) = loopbackPair();
    final refused = <String>[];
    WalletDispatcher(
      fake,
      b,
      refuse: (member, params) {
        final no =
            member == 'mnemonic' ||
            (member == 'createWithPin' && params['mnemonic'] != null);
        if (no) refused.add(member);
        return no;
      },
    );
    final client = RemoteWalletService(a);
    await expectLater(
      client.createWithPin(config: config, mnemonic: 'words', pin: '1234'),
      throwsA(refusedMember('createWithPin')),
    );
    expect(fake.createdPin, isNull);
    final w = await client.createWithPin(config: config, pin: '1234');
    await expectLater(
      w.session.mnemonic(password: 'x'),
      throwsA(refusedMember('mnemonic')),
    );
    expect(await w.session.epicboxAddress(), fake.session.address);
    expect(refused, ['createWithPin', 'mnemonic']);
    await client.close();
  });

  test(
    'the rewrite applies to every config before the service sees it',
    () async {
      final fake = FakeWalletService();
      final (a, b) = loopbackPair();
      final seen = <WalletConfig>[];
      WalletDispatcher(
        fake,
        b,
        rewriteConfig: (c) {
          seen.add(c);
          return serverConfig;
        },
      );
      final client = RemoteWalletService(a);
      expect(await client.walletExists(config: config), false);
      await client.createWithPin(config: config, pin: '1234');
      expect(fake.createdConfig, serverConfig);
      expect(fake.existingWallets, {serverConfig.dataDir});
      expect(await client.walletExists(config: config), true);
      expect(await client.pinFailures(config: config), 0);
      await client.nodeTip(config: config);
      await client.openWithPin(
        config: config,
        pin: '1234',
        sealedPassword: fakeSealedPassword('1234'),
      );
      await client.deleteWallet(config: config);
      expect(fake.deletedWallets, [serverConfig.dataDir]);
      expect(seen, List.filled(7, config));
      await client.close();
    },
  );

  test(
    'an exception that is not a WalletError reaches the client without detail',
    () async {
      final logged = <Object>[];
      final (a, b) = loopbackPair();
      WalletDispatcher(CrashingService(), b, onError: (e, _) => logged.add(e));
      final client = RemoteWalletService(a);
      await expectLater(client.nodeTip(config: config), throwsA(serverError));
      expect(logged.single, isA<StateError>());
      await client.close();
    },
  );

  test('pushes reach the client', () async {
    final (a, b) = loopbackPair();
    final dispatcher = WalletDispatcher(FakeWalletService(), b);
    final client = RemoteWalletService(a);
    final pushes = <RpcPush>[];
    client.pushes.listen(pushes.add);
    dispatcher.push('demoEnded', {'at': 5});
    await settle();
    expect(pushes.single.name, 'demoEnded');
    expect(pushes.single.data, {'at': 5});
    await dispatcher.close();
    await settle();
    expect(client.closed, true);
  });

  group('raw frames', () {
    late FakeWalletService fake;
    late RawPeer peer;

    setUp(() {
      fake = FakeWalletService();
      final (a, b) = loopbackPair();
      WalletDispatcher(fake, b, maxFrameBytes: 300);
      peer = RawPeer(a);
    });

    test('unknown members are refused', () async {
      expect(
        await peer.send('{"id":1,"m":"validateMnemonic","p":{"phrase":"x"}}'),
        {'id': 1, 'e': errorOf(unknownMember('validateMnemonic'))},
      );
      expect(await peer.send('{"id":2,"m":"epicboxAddress","p":{}}'), {
        'id': 2,
        'e': errorOf(unknownMember('epicboxAddress')),
      });
      expect(await peer.send('{"id":3,"m":"nodeTip","p":{},"s":"abc"}'), {
        'id': 3,
        'e': errorOf(unknownMember('nodeTip')),
      });
      expect(await peer.send('{"id":4,"m":"toString","p":{}}'), {
        'id': 4,
        'e': errorOf(unknownMember('toString')),
      });
    });

    test('an unknown session handle', () async {
      expect(
        await peer.send('{"id":1,"m":"epicboxAddress","p":{},"s":"abc"}'),
        {'id': 1, 'e': errorOf(unknownSession)},
      );
    });

    test('parameters that do not decode', () async {
      final r = await peer.send(
        '{"id":1,"m":"walletExists","p":{"config":{"dataDir":3}}}',
      );
      expect((r['e'] as Map)['kind'], 'other');
      expect((r['e'] as Map)['message'], contains('walletExists.config'));
      final r2 = await peer.send('{"id":2,"m":"walletExists","p":{}}');
      expect((r2['e'] as Map)['kind'], 'other');
    });

    test('malformed frames', () async {
      expect(await peer.send('{"id":5,"m":'), {
        'id': 5,
        'e': errorOf(badFrame),
      });
      expect(await peer.send('{"id":6,"m":7,"p":{}}'), {
        'id': 6,
        'e': errorOf(badFrame),
      });
      expect(await peer.send('{"id":7,"m":"nodeTip","p":[]}'), {
        'id': 7,
        'e': errorOf(badFrame),
      });
      expect(await peer.send('{"id":8,"m":"nodeTip","p":{},"s":1}'), {
        'id': 8,
        'e': errorOf(badFrame),
      });
      await peer.sendUnanswered('not json');
      await peer.sendUnanswered('[1,2]');
      await peer.sendUnanswered('{"m":"nodeTip"}');
      await peer.sendUnanswered('{"id":"1","m":"nodeTip"}');
    });

    test('the frame cap counts UTF-8 bytes', () async {
      final config = jsonEncode({
        'dataDir': '/d',
        'chain': 'floonet',
        'nodeUrl': 'n',
        'epicboxDomain': 'e',
        'epicboxPort': 1,
      });
      // 100 characters, 300 bytes: under the cap in characters, over it in bytes.
      final wide = '€' * 100;
      expect(
        await peer.send(
          '{"id":9,"m":"createWithPin","p":{"config":$config,"pin":"$wide"}}',
        ),
        {'id': 9, 'e': errorOf(frameTooLarge)},
      );
      expect(fake.createdPin, isNull);
      await peer.sendUnanswered('{"m":"x","p":"${'a' * 400}"}');
      final ok = await peer.send(
        '{"id":10,"m":"createWithPin","p":{"config":$config,"pin":"1234"}}',
      );
      expect((ok['r'] as Map)['sealedPassword'], fakeSealedPassword('1234'));
    });

    test('a request id in use is refused', () async {
      fake.createGate = Completer<void>();
      const create =
          '{"id":1,"m":"create","p":{"config":{"dataDir":"/d","chain":"floonet",'
          '"nodeUrl":"n","epicboxDomain":"e","epicboxPort":1},"password":"p"}}';
      peer.end.send(create);
      await settle();
      expect(await peer.send(create), {'id': 1, 'e': errorOf(idInUse)});
      fake.createGate!.complete();
      await settle();
      expect((peer.replies.last['r'] as Map)['invoices'], true);
    });

    test('a cancel does not free the id of a one-shot call', () async {
      fake.createGate = Completer<void>();
      const create =
          '{"id":1,"m":"create","p":{"config":{"dataDir":"/d","chain":"floonet",'
          '"nodeUrl":"n","epicboxDomain":"e","epicboxPort":1},"password":"p"}}';
      peer.end.send(create);
      await settle();
      await peer.sendUnanswered('{"id":1,"cancel":true}');
      expect(await peer.send(create), {'id': 1, 'e': errorOf(idInUse)});
      fake.createGate!.complete();
      await settle();
      expect(
        peer.replies.where((r) => r['id'] == 1 && r.containsKey('r')),
        hasLength(1),
      );
    });
  });

  test('calls and streams over maxInFlight are refused until one ends', () async {
    final fake = FakeWalletService();
    final (a, b) = loopbackPair();
    WalletDispatcher(fake, b, maxInFlight: 3);
    final peer = RawPeer(a);
    const cfg =
        '{"dataDir":"/d","chain":"floonet","nodeUrl":"n","epicboxDomain":"e","epicboxPort":1}';
    // One session (answered at once), then a held call and two open streams.
    final opened = await peer.send(
      '{"id":1,"m":"createWithPin","p":{"config":$cfg,"pin":"1234"}}',
    );
    final handle = ((opened['r'] as Map)['session'] as Map)['s'];
    fake.createGate = Completer<void>();
    peer.end.send(
      '{"id":2,"m":"create","p":{"config":{"dataDir":"/e","chain":"floonet",'
      '"nodeUrl":"n","epicboxDomain":"e","epicboxPort":1},"password":"p"}}',
    );
    await settle();
    await peer.sendUnanswered(
      '{"id":3,"m":"startListener","p":{},"s":"$handle"}',
    );
    await peer.sendUnanswered(
      '{"id":4,"m":"invoiceEvents","p":{},"s":"$handle"}',
    );
    expect(
      await peer.send('{"id":5,"m":"epicboxAddress","p":{},"s":"$handle"}'),
      {'id': 5, 'e': errorOf(tooManyInFlight)},
    );
    expect(tooManyInFlight.kind, WalletErrorKind.invalidArgument);
    // A cancelled stream frees its place.
    await peer.sendUnanswered('{"id":3,"cancel":true}');
    expect(
      await peer.send('{"id":6,"m":"epicboxAddress","p":{},"s":"$handle"}'),
      {'id': 6, 'r': fake.session.address},
    );
    // Full again, then a held call answers and frees its place.
    await peer.sendUnanswered(
      '{"id":7,"m":"startListener","p":{},"s":"$handle"}',
    );
    expect(
      await peer.send('{"id":8,"m":"epicboxAddress","p":{},"s":"$handle"}'),
      {'id': 8, 'e': errorOf(tooManyInFlight)},
    );
    fake.createGate!.complete();
    await settle();
    expect(peer.replies.last['id'], 2);
    expect(
      await peer.send('{"id":9,"m":"epicboxAddress","p":{},"s":"$handle"}'),
      {'id': 9, 'r': fake.session.address},
    );
  });

  group('sessions', () {
    test(
      'a dispatcher disposes its own sessions when the channel ends',
      () async {
        final fake = FakeWalletService();
        final (a, b) = loopbackPair();
        final dispatcher = WalletDispatcher(fake, b);
        final client = RemoteWalletService(a);
        await client.createWithPin(config: config, pin: '1234');
        await client.close();
        await dispatcher.done;
        expect(fake.session.disposeCalls, 1);
      },
    );

    test('a shared table outlives the socket, and its handles work on the next one', () async {
      final fake = FakeWalletService();
      final sessions = WalletSessions();
      final (a1, b1) = loopbackPair();
      final first = WalletDispatcher(fake, b1, sessions: sessions);
      final c1 = RemoteWalletService(a1);
      final w = await c1.createWithPin(config: config, pin: '1234');
      final handle = (w.session as RemoteWalletSession).handle;
      await c1.close();
      await first.done;
      expect(fake.session.disposeCalls, 0);
      expect(sessions[handle], same(fake.session));

      final (a2, b2) = loopbackPair();
      WalletDispatcher(fake, b2, sessions: sessions);
      final peer = RawPeer(a2);
      expect(
        await peer.send('{"id":1,"m":"epicboxAddress","p":{},"s":"$handle"}'),
        {'id': 1, 'r': fake.session.address},
      );
      sessions.disposeAll();
      expect(fake.session.disposeCalls, 1);
      expect(sessions.isEmpty, true);
    });

    test('handles are random 128-bit hex, distinct per session', () {
      final sessions = WalletSessions();
      final handles = {
        for (var i = 0; i < 50; i++) sessions.add(FakeWalletSession()),
      };
      expect(handles, hasLength(50));
      expect(handles.every(RegExp(r'^[0-9a-f]{32}$').hasMatch), true);
    });
  });
}
