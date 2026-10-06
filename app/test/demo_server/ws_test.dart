// /api/ws over a real loopback socket: who may connect, what the wallet sees, expiry, idle
// dispose and resume, and the frame cap.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/demo_server/config.dart';
import 'package:epic_wallet/src/demo_server/server.dart';
import 'package:epic_wallet/src/demo_server/ws_channel.dart';
import 'package:epic_wallet/src/remote/client.dart';
import 'package:epic_wallet/src/remote/protocol.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// What a browser on another site, or a phone app, might send as its config.
const clientConfig = WalletConfig(
  dataDir: '/home/visitor/.wallet',
  chain: Chain.mainnet,
  nodeUrl: 'https://node.example',
  epicboxDomain: 'epicbox.example',
  epicboxPort: 1,
);

Future<IoWebSocketChannel> connect(
  Harness h, {
  String? cookie,
  String? origin,
}) => IoWebSocketChannel.connect(
  'ws://127.0.0.1:${h.server.port}/api/ws',
  headers: {
    'origin': origin ?? h.origin,
    if (cookie != null) 'cookie': '$demoCookie=$cookie',
  },
);

/// A started demo and a wallet client on its socket.
Future<(Visitor, RemoteWalletService)> demoClient(Harness h) async {
  final v = Visitor(h);
  await v.start();
  return (v, RemoteWalletService(await connect(h, cookie: v.cookie)));
}

/// Raw frames on a socket, for calls by handle and oversized frames.
class RawSocket {
  RawSocket(this.channel) {
    channel.incoming.listen(
      (t) => _replies.add(jsonDecode(t) as Map<String, Object?>),
    );
  }

  final IoWebSocketChannel channel;
  final StreamController<Map<String, Object?>> _replies = StreamController();
  late final StreamIterator<Map<String, Object?>> _next = StreamIterator(
    _replies.stream,
  );

  Future<Map<String, Object?>> call(String frame) async {
    channel.send(frame);
    expect(await _next.moveNext().timeout(const Duration(seconds: 5)), isTrue);
    return _next.current;
  }
}

Future<void> waitFor(bool Function() done, {String? reason}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out: $reason');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  test(
    'a socket needs the cookie of a live demo and an allowed Origin',
    () async {
      final h = await Harness.start();
      final v = Visitor(h);
      await v.start();

      Future<void> refused(Future<Object> attempt) =>
          expectLater(attempt, throwsA(isA<WebSocketException>()));

      await refused(connect(h));
      await refused(connect(h, cookie: 'f' * 64));
      await refused(
        connect(h, cookie: v.cookie, origin: 'https://evil.example'),
      );
      await refused(connect(h, cookie: v.cookie, origin: 'null'));
      expect(h.server.socketsOf(v.cookie!), 0);

      final ok = await connect(h, cookie: v.cookie);
      await waitFor(
        () => h.server.socketsOf(v.cookie!) == 1,
        reason: 'socket registered',
      );
      await ok.close();

      final id = v.cookie!;
      await v.end();
      await refused(connect(h, cookie: id));
    },
  );

  test(
    'every call gets the demo directory on floonet, whatever the client sent',
    () async {
      final h = await Harness.start();
      final (v, client) = await demoClient(h);
      final id = v.cookie!;

      final created = await client.createWithPin(
        config: clientConfig,
        pin: '123456',
      );
      final fake = h.services[id]!;
      final expected = h.server.configFor(id);
      expect(fake.createdConfig, expected);
      expect(expected.dataDir, h.server.store.walletDirOf(id));
      expect(expected.chain, Chain.floonet);
      expect(expected.nodeUrl, 'https://floo-node.btlabs.uk');
      expect(expected.epicboxDomain, 'flooepicbox.btlabs.uk');
      expect(await client.walletExists(config: clientConfig), isTrue);
      expect(fake.createdPin, '123456');
      expect(await created.session.epicboxAddress(), fake.session.address);

      await client.deleteWallet(config: clientConfig);
      expect(fake.deletedWallets, [expected.dataDir]);
      expect(fake.deletedWallets, isNot(contains(clientConfig.dataDir)));
      await client.close();
    },
  );

  test('the demo refuses restores, the phrase and history files', () async {
    final h = await Harness.start();
    final (v, client) = await demoClient(h);
    final fake = h.services.values;

    Future<void> refused(Future<Object?> call, String member) => expectLater(
      call,
      throwsA(
        isA<WalletError>()
            .having((e) => e.kind, 'kind', WalletErrorKind.other)
            .having((e) => e.message, 'message', refusedMember(member).message),
      ),
    );

    const phrase = 'abandon abandon abandon';
    await refused(
      client.createWithPin(
        config: clientConfig,
        mnemonic: phrase,
        pin: '123456',
      ),
      'createWithPin',
    );
    await refused(
      client.create(config: clientConfig, mnemonic: phrase, password: 'pw'),
      'create',
    );
    expect(fake.every((f) => f.createdConfig == null), isTrue);

    final s = (await client.createWithPin(
      config: clientConfig,
      pin: '123456',
    )).session;
    await refused(s.mnemonic(password: 'pw'), 'mnemonic');
    await refused(
      s.mnemonicWithPin(
        pin: '123456',
        sealedPassword: fakeSealedPassword('123456'),
      ),
      'mnemonicWithPin',
    );
    await refused(s.exportHistory(), 'exportHistory');
    await refused(s.exportHistoryCsv(), 'exportHistoryCsv');
    await refused(s.importHistory(data: utf8.encode('x')), 'importHistory');
    // What the demo keeps still works.
    expect(await s.contacts(), isEmpty);
    expect(v.cookie, isNotNull);
    await client.close();
  });

  test(
    'expiry pushes demoEnded, closes the sessions and removes the directory',
    () async {
      final h = await Harness.start(
        config: (r) => DemoServerConfig(
          dataRoot: r,
          port: 0,
          ttl: const Duration(seconds: 2),
          sweepInterval: const Duration(milliseconds: 100),
        ),
      );
      final (v, client) = await demoClient(h);
      final id = v.cookie!;
      final pushes = <String>[];
      client.pushes.listen((p) => pushes.add(p.name));
      final s = (await client.createWithPin(
        config: clientConfig,
        pin: '123456',
      )).session;
      final listener = s.startListener().listen(null, onError: (_) {});
      final fake = h.services[id]!;
      final dir = Directory(h.server.store.dirOf(id));
      expect(await dir.exists(), isTrue);

      await waitFor(() => client.closed, reason: 'socket closed at expiry');
      // The socket closes first; the wallet and its directory go after it.
      await waitFor(() => !dir.existsSync(), reason: 'directory removed');
      expect(pushes, [demoEndedPush]);
      expect(fake.session.disposeCalls, 1);
      expect(fake.deletedWallets, [h.server.store.walletDirOf(id)]);
      expect(h.server.liveCount, 0);
      await expectLater(s.epicboxAddress(), throwsA(isA<WalletError>()));
      await listener.cancel();
      expect((await v.status()).json, {'state': 'ended'});
    },
  );

  test(
    'sessions outlive a socket for the idle window, then are disposed',
    () async {
      final h = await Harness.start(
        config: (r) => DemoServerConfig(
          dataRoot: r,
          port: 0,
          idleTimeout: const Duration(milliseconds: 600),
        ),
      );
      final (v, client) = await demoClient(h);
      final id = v.cookie!;
      final s =
          (await client.createWithPin(
                config: clientConfig,
                pin: '123456',
              )).session
              as RemoteWalletSession;
      final fake = h.services[id]!;
      await client.close();
      await waitFor(() => h.server.socketsOf(id) == 0, reason: 'socket gone');

      // A reload inside the window: the old handle still answers.
      final again = RawSocket(await connect(h, cookie: id));
      final r = await again.call(
        jsonEncode({'id': 1, 'm': 'epicboxAddress', 'p': {}, 's': s.handle}),
      );
      expect(r, {'id': 1, 'r': fake.session.address});
      await again.channel.close();
      await waitFor(
        () => h.server.socketsOf(id) == 0,
        reason: 'second socket gone',
      );
      expect(h.server.hasSessions(id), isTrue);
      expect(fake.session.disposeCalls, 0);

      // Past the window with no socket: disposed, and the handle is unknown.
      await waitFor(() => !h.server.hasSessions(id), reason: 'idle dispose');
      expect(fake.session.disposeCalls, 1);
      final late = RawSocket(await connect(h, cookie: id));
      final gone = await late.call(
        jsonEncode({'id': 2, 'm': 'epicboxAddress', 'p': {}, 's': s.handle}),
      );
      expect((gone['e']! as Map)['message'], unknownSession.message);
      await late.channel.close();
      // The demo itself lives on.
      expect((await v.status()).json['state'], 'active');
    },
  );
  test('PIN calls across all demos wait for the Argon2id slots', () async {
    var running = 0;
    var peak = 0;
    final h = await Harness.start(
      config: (r) => DemoServerConfig(dataRoot: r, port: 0, argonSlots: 1),
      fake: () => _SlowPinFake(
        onEnter: () => peak = ++running > peak ? running : peak,
        onLeave: () => running--,
      ),
    );
    final clients = [for (var i = 0; i < 3; i++) (await demoClient(h)).$2];
    await Future.wait([
      for (final c in clients)
        c.createWithPin(config: clientConfig, pin: '123456'),
    ]);
    expect(peak, 1);
    for (final c in clients) {
      await c.close();
    }
  });

  test(
    'frames over the cap are refused unread, and the socket keeps working',
    () async {
      final h = await Harness.start(
        config: (r) =>
            DemoServerConfig(dataRoot: r, port: 0, maxFrameBytes: 4096),
      );
      final v = Visitor(h);
      await v.start();
      final raw = RawSocket(await connect(h, cookie: v.cookie));
      final big = jsonEncode({
        'id': 7,
        'm': 'inspectSlate',
        'p': {'json': 'x' * 5000},
      });
      final r = await raw.call(big);
      expect(r, {
        'id': 7,
        'e': {'kind': 'invalidArgument', 'message': frameTooLarge.message},
      });
      final ok = await raw.call(
        jsonEncode({
          'id': 8,
          'm': 'pinFailures',
          'p': {
            'config': {
              'dataDir': '/x',
              'chain': 'mainnet',
              'nodeUrl': 'n',
              'epicboxDomain': 'e',
              'epicboxPort': 443,
            },
          },
        }),
      );
      expect(ok, {'id': 8, 'r': 0});
      await raw.channel.close();
    },
  );
}

/// A fake whose createWithPin takes a while, reporting when it runs.
class _SlowPinFake extends FakeWalletService {
  _SlowPinFake({required this.onEnter, required this.onLeave});

  final void Function() onEnter;
  final void Function() onLeave;

  @override
  Future<PinWallet> createWithPin({
    required WalletConfig config,
    String? mnemonic,
    required String pin,
  }) async {
    onEnter();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return await super.createWithPin(
        config: config,
        mnemonic: mnemonic,
        pin: pin,
      );
    } finally {
      onLeave();
    }
  }
}
