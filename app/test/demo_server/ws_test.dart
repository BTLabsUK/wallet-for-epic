// SPDX-License-Identifier: Apache-2.0
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
  _moreTests();
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
  test(
    'an open on a new page replaces the sessions the old page left',
    () async {
      final h = await Harness.start();
      final (v, first) = await demoClient(h);
      final id = v.cookie!;
      final created = await first.createWithPin(
        config: clientConfig,
        pin: '123456',
      );
      final old = created.session as RemoteWalletSession;
      final fake = h.services[id]!;
      await first.close();

      // A reload that kept no handle unlocks with the PIN; LEPIC would refuse a second open of
      // the directory, so the old session is disposed first.
      final second = RemoteWalletService(await connect(h, cookie: id));
      await second.openWithPin(
        config: clientConfig,
        pin: '123456',
        sealedPassword: created.sealedPassword,
      );
      expect(fake.session.disposeCalls, 1);
      final raw = RawSocket(await connect(h, cookie: id));
      final gone = await raw.call(
        jsonEncode({'id': 1, 'm': 'epicboxAddress', 'p': {}, 's': old.handle}),
      );
      expect((gone['e']! as Map)['message'], unknownSession.message);
      await raw.channel.close();
      await second.close();
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
void _moreTests() {
  test('a demo that ends during a gated open leaves no wallet open', () async {
    final gate = Completer<void>();
    final h = await Harness.start(
      fake: () => _DirMakingFake()..createGate = gate,
    );
    final (v, client) = await demoClient(h);
    final id = v.cookie!;
    final call = client.createWithPin(config: clientConfig, pin: '123456');
    unawaited(call.then((_) {}, onError: (Object _) {}));
    await waitFor(() => h.services.containsKey(id), reason: 'service made');
    final fake = h.services[id]! as _DirMakingFake;
    await waitFor(() => fake.entered, reason: 'open waiting in the wallet');

    // The visitor ends the demo while the open waits; then the open finishes.
    expect((await v.end()).status, HttpStatus.noContent);
    final dir = Directory(h.server.store.dirOf(id));
    expect(await dir.exists(), isFalse);
    gate.complete();

    await expectLater(call, throwsA(isA<WalletError>()));
    await waitFor(
      () => fake.session.disposeCalls == 1,
      reason: 'late session disposed',
    );
    expect(fake.createdConfig, isNotNull, reason: 'the open did run');
    await waitFor(
      () => !dir.existsSync(),
      reason: 're-created directory removed',
    );
    expect(h.server.liveCount, 0);
  });

  test('concurrent starts never pass the live cap', () async {
    final h = await Harness.start(
      config: (r) => DemoServerConfig(
        dataRoot: r,
        port: 0,
        maxLiveDemos: 2,
        trustProxy: true,
      ),
    );
    final replies = await Future.wait([
      for (var i = 0; i < 6; i++)
        Visitor(h, forwardedFor: '198.51.100.$i').start(),
    ]);
    final created = replies.where((r) => r.status == HttpStatus.created);
    final refused = replies.where(
      (r) => r.status == HttpStatus.tooManyRequests,
    );
    expect(created, hasLength(2));
    expect(refused, hasLength(4));
    expect(
      refused.every(
        (r) => r.headers.value(HttpHeaders.retryAfterHeader) != null,
      ),
      isTrue,
    );
    expect(h.server.liveCount, 2);
    expect(await Directory(h.server.store.demosDir).list().length, 2);
  });

  test('a demo holds at most 4 sockets; the fifth gets 429', () async {
    final h = await Harness.start();
    final v = Visitor(h);
    await v.start();
    final open = <IoWebSocketChannel>[];
    final attempts = await Future.wait([
      for (var i = 0; i < 5; i++)
        connect(
          h,
          cookie: v.cookie,
        ).then<Object>((c) => c, onError: (Object e) => e),
    ]);
    open.addAll(attempts.whereType<IoWebSocketChannel>());
    expect(open, hasLength(4));
    expect(attempts.whereType<WebSocketException>(), hasLength(1));
    await waitFor(
      () => h.server.socketsOf(v.cookie!) == 4,
      reason: 'four sockets',
    );
    expect(await upgradeStatus(h, v.cookie!), HttpStatus.tooManyRequests);

    await open.removeLast().close();
    await waitFor(
      () => h.server.socketsOf(v.cookie!) == 3,
      reason: 'one closed',
    );
    open.add(await connect(h, cookie: v.cookie));
    for (final c in open) {
      await c.close();
    }
  });
}

/// The HTTP status of a WebSocket upgrade request, as the browser would see it.
Future<int> upgradeStatus(Harness h, String cookie) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse('${h.base}/api/ws'));
    req.headers
      ..set('origin', h.origin)
      ..set(HttpHeaders.cookieHeader, '$demoCookie=$cookie')
      ..set(HttpHeaders.connectionHeader, 'Upgrade')
      ..set(HttpHeaders.upgradeHeader, 'websocket')
      ..set('sec-websocket-version', '13')
      ..set('sec-websocket-key', base64.encode(List.filled(16, 7)));
    final res = await req.close();
    await res.drain<void>();
    return res.statusCode;
  } finally {
    client.close(force: true);
  }
}

/// A fake whose create writes into the wallet directory, as LEPIC does, after its gate.
class _DirMakingFake extends FakeWalletService {
  /// True once createWithPin has started.
  bool entered = false;

  @override
  Future<PinWallet> createWithPin({
    required WalletConfig config,
    String? mnemonic,
    required String pin,
  }) async {
    entered = true;
    final w = await super.createWithPin(
      config: config,
      mnemonic: mnemonic,
      pin: pin,
    );
    await Directory('${config.dataDir}/lepic').create(recursive: true);
    return w;
  }
}

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
