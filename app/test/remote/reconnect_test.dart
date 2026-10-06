// RemoteWalletService with a connector: the first call connects, a drop fails what was
// pending and retries with a doubling wait, and a session the server dropped is reported.

import 'dart:async';

import 'package:epic_wallet/src/remote/channel.dart';
import 'package:epic_wallet/src/remote/client.dart';
import 'package:epic_wallet/src/remote/dispatcher.dart';
import 'package:epic_wallet/src/remote/protocol.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

const config = WalletConfig(
  dataDir: '/demo',
  chain: Chain.floonet,
  nodeUrl: 'https://floo-node.example',
  epicboxDomain: 'flooepicbox.example',
  epicboxPort: 443,
);

/// A directory without a wallet, so a create there reaches the fake's gate.
const fresh = WalletConfig(
  dataDir: '/fresh',
  chain: Chain.floonet,
  nodeUrl: 'https://floo-node.example',
  epicboxDomain: 'flooepicbox.example',
  epicboxPort: 443,
);

final String sealed = fakeSealedPassword('1');

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// A server that outlives its sockets, as the demo server's sessions outlive a reload.
class Server {
  final FakeWalletService service = FakeWalletService(
    existingWallets: {config.dataDir},
  );
  final WalletSessions sessions = WalletSessions();

  /// The server end of the live connection, and its dispatcher.
  RpcChannel? live;
  WalletDispatcher? dispatcher;
  int connects = 0;
  final List<DateTime> attempts = [];

  /// While set, connecting fails with it.
  Object? refuse;

  /// While set, connecting waits for it.
  Completer<void>? gate;

  Future<RpcChannel> connect() async {
    attempts.add(DateTime.now());
    await gate?.future;
    if (refuse case final error?) throw error;
    connects++;
    final (client, server) = loopbackPair();
    dispatcher = WalletDispatcher(service, server, sessions: sessions);
    live = server;
    return client;
  }

  /// The network drops: the server's end closes.
  Future<void> drop() async {
    await live?.close();
    live = null;
    await settle();
  }
}

void main() {
  late Server server;
  late RemoteWalletService client;
  late List<RemoteConnection> states;

  setUp(() {
    server = Server();
    client = RemoteWalletService.reconnecting(
      server.connect,
      firstRetry: const Duration(milliseconds: 20),
      maxRetry: const Duration(milliseconds: 80),
    );
    states = [];
    client.connectionChanges.listen(states.add);
  });

  tearDown(() => client.close());

  Future<void> until(RemoteConnection state) async {
    for (var i = 0; i < 200 && client.connection != state; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(client.connection, state);
  }

  test('idle until the first call, which waits for the connection', () async {
    expect(client.connection, RemoteConnection.idle);
    await settle();
    expect(server.connects, 0);
    server.gate = Completer<void>();
    final exists = client.walletExists(config: config);
    await settle();
    expect(client.connection, RemoteConnection.connecting);
    server.gate!.complete();
    expect(await exists, isTrue);
    expect(client.connection, RemoteConnection.connected);
    expect(states, [RemoteConnection.connecting, RemoteConnection.connected]);
  });

  test('a drop fails calls in flight as a connection problem', () async {
    await client.walletExists(config: config);
    // A call the server never answers before the drop.
    server.service.createGate = Completer<void>();
    final pending = expectLater(
      client.create(config: fresh, password: 'p'),
      throwsA(connectionClosed),
    );
    await settle();
    await server.drop();
    await pending;
    expect(states, contains(RemoteConnection.reconnecting));
  });

  test('while reconnecting, calls fail at once', () async {
    await client.walletExists(config: config);
    server.refuse = StateError('down');
    await server.drop();
    await expectLater(
      client.walletExists(config: config),
      throwsA(connectionClosed),
    );
    await expectLater(
      client
          .openWithPin(config: config, pin: '1', sealedPassword: sealed)
          .then((_) {}),
      throwsA(connectionClosed),
    );
  });

  test(
    'retries after 1 step, doubling up to the cap, and comes back',
    () async {
      await client.walletExists(config: config);
      server.refuse = StateError('down');
      server.attempts.clear();
      final dropped = DateTime.now();
      await server.drop();
      for (var i = 0; i < 200 && server.attempts.length < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(server.attempts.length, greaterThanOrEqualTo(5));
      final gaps = [
        server.attempts[0].difference(dropped),
        for (var i = 1; i < 5; i++)
          server.attempts[i].difference(server.attempts[i - 1]),
      ];
      // Timers never fire early: each gap is at least its step, 20, 40, 80, 80 ms.
      const steps = [20, 40, 80, 80, 80];
      for (var i = 0; i < gaps.length; i++) {
        expect(
          gaps[i].inMilliseconds,
          greaterThanOrEqualTo(steps[i] - 2),
          reason: 'gap $i of $gaps',
        );
      }
      expect(gaps[3].inMilliseconds, lessThan(80 * 3), reason: 'capped');
      server.refuse = null;
      await until(RemoteConnection.connected);
      expect(await client.walletExists(config: config), isTrue);
      expect(states, [
        RemoteConnection.connecting,
        RemoteConnection.connected,
        RemoteConnection.reconnecting,
        RemoteConnection.connected,
      ]);
    },
  );

  test('the wait starts again at the first step after a success', () async {
    await client.walletExists(config: config);
    server.refuse = StateError('down');
    await server.drop();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    server.refuse = null;
    await until(RemoteConnection.connected);
    server.attempts.clear();
    final dropped = DateTime.now();
    await server.drop();
    await until(RemoteConnection.connected);
    final gap = server.attempts.single.difference(dropped).inMilliseconds;
    expect(gap, lessThan(60), reason: 'one first step, not the doubled one');
  });

  test('a session survives a reconnect while the server keeps it', () async {
    final session = await client.openWithPin(
      config: config,
      pin: '1',
      sealedPassword: sealed,
    );
    await server.drop();
    await until(RemoteConnection.connected);
    expect(await session.epicboxAddress(), isNotEmpty);
  });

  test('a session the server dropped goes to lostSessions', () async {
    final lost = <String>[];
    client.lostSessions.listen(lost.add);
    final session = await client.openWithPin(
      config: config,
      pin: '1',
      sealedPassword: sealed,
    ) as RemoteWalletSession;
    await server.drop();
    // The idle timeout passed on the server meanwhile.
    server.sessions.disposeAll();
    await until(RemoteConnection.connected);
    await expectLater(session.epicboxAddress(), throwsA(unknownSession));
    await expectLater(
      session.refresh(minimumConfirmations: BigInt.one).drain<void>(),
      throwsA(unknownSession),
    );
    expect(lost, [session.handle, session.handle]);
    // Another error is not a lost session.
    await expectLater(
      client.openWithPin(config: config, pin: '9', sealedPassword: 'bad'),
      throwsA(isA<WalletError>()),
    );
    expect(lost, hasLength(2));
  });

  test('a first connection that fails goes to reconnecting', () async {
    server.refuse = StateError('down');
    await expectLater(
      client.walletExists(config: config),
      throwsA(connectionClosed),
    );
    expect(client.connection, RemoteConnection.reconnecting);
    server.refuse = null;
    await until(RemoteConnection.connected);
  });

  test('disconnect stops retrying; the next call connects again', () async {
    await client.walletExists(config: config);
    server.refuse = StateError('down');
    await server.drop();
    await client.disconnect();
    expect(client.connection, RemoteConnection.idle);
    final attempts = server.attempts.length;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(server.attempts.length, attempts, reason: 'no retry once idle');
    server.refuse = null;
    expect(await client.walletExists(config: config), isTrue);
    expect(client.connection, RemoteConnection.connected);
  });

  test(
    'disconnect while connected closes the socket and fails pending',
    () async {
      await client.walletExists(config: config);
      server.service.createGate = Completer<void>();
      final pending = expectLater(
        client.create(config: fresh, password: 'p'),
        throwsA(connectionClosed),
      );
      await settle();
      await client.disconnect();
      await pending;
      expect(client.connection, RemoteConnection.idle);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(server.connects, 1, reason: 'no reconnect after disconnect');
    },
  );

  test('pushes span connections and end at close', () async {
    final pushes = <String>[];
    var done = false;
    client.pushes.listen((p) => pushes.add(p.name), onDone: () => done = true);
    await client.walletExists(config: config);
    await server.drop();
    await until(RemoteConnection.connected);
    server.dispatcher!.push('demoEnded');
    await settle();
    expect(pushes, ['demoEnded']);
    expect(done, isFalse);
    await client.close();
    await settle();
    expect(done, isTrue);
    expect(client.connection, RemoteConnection.closed);
    await expectLater(
      client.walletExists(config: config),
      throwsA(connectionClosed),
    );
  });

  test('dispose is not sent while not connected, and never connects', () async {
    final session = await client.openWithPin(
      config: config,
      pin: '1',
      sealedPassword: sealed,
    );
    await client.disconnect();
    session.dispose();
    await settle();
    expect(client.connection, RemoteConnection.idle);
    expect(server.connects, 1);
  });
}
