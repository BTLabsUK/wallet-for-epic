// The web demo end to end, without a browser: the real demo server on real LEPIC on
// floonet, reached the way the web app reaches it (ServerDemoApi over HTTP with the cookie,
// RemoteWalletService over /api/ws). Two demos: A claims test coins, they arrive and
// confirm, A sends 1 EPIC to B over epicbox, and B sees it confirmed. Both demos end and
// their directories go.
//
// Needs the network, the Linux LEPIC library and blocks on floonet, so it runs by hand:
//
//   bash integration_test/demo_e2e.sh          (from app/; starts floo-miner for the run)
//
// which runs
//
//   WFE_DEMO_LEPIC_LIB=<liblepic_ffi.so> WFE_DEMO_APP_DIR=$PWD \
//     xvfb-run -a flutter test integration_test/demo_e2e_test.dart -d linux
//
// The test itself is only the browser's side, over dart:io; the server is `dart run
// bin/wfe_demo_server.dart` from WFE_DEMO_APP_DIR, a separate process that loads LEPIC from
// WFE_DEMO_LEPIC_LIB. Without that variable it is skipped. WFE_DEMO_WEB_ROOT, when set, is
// passed to the server as --web-root. Progress lines start with `WFE_E2E`.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/amount.dart';
import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/demo_web.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/remote/client.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'demo_e2e_support.dart';

final String? library = Platform.environment['WFE_DEMO_LEPIC_LIB'];
final String? webRoot = Platform.environment['WFE_DEMO_WEB_ROOT'];
final String ttl = Platform.environment['WFE_DEMO_E2E_TTL'] ?? '15m';
final String appDir =
    Platform.environment['WFE_DEMO_APP_DIR'] ?? Directory.current.path;
final String dart =
    Platform.environment['WFE_DEMO_DART'] ??
    '${Platform.environment['FLUTTER_ROOT']}/bin/dart';

const String pin = '123456';
final BigInt oneConfirmation = BigInt.one;

void say(String line) {
  // ignore: avoid_print
  print('WFE_E2E $line');
}

String epic(BigInt atomic) => '${atomic / atomicPerEpic} EPIC';

/// One visitor: a browser tab's HTTP side, its demo API and its wallet socket.
class Visitor {
  Visitor(this.name, Uri base) : http = IoDemoHttp(base), _base = base;

  final String name;
  final IoDemoHttp http;
  final Uri _base;
  final _ended = StreamController<void>.broadcast();
  late final ServerDemoApi api = ServerDemoApi(
    http: http,
    origin: _base,
    ended: _ended.stream,
    openLink: (_) async {},
  );
  late RemoteWalletService wallet;
  late WalletSession session;
  late String address;
  final List<ListenerEvent> events = [];
  StreamSubscription<ListenerEvent>? _listener;

  /// What the browser sends; the server replaces it with the demo's own.
  final WalletConfig config = floonetPreset.config(
    dataDir: '/demo/floonet',
    nodeUrl: floonetPreset.nodeUrl,
  );

  Future<void> start() async {
    expect(await api.status(), const DemoNone());
    final active = await api.start();
    expect(active.expiresAt.isAfter(DateTime.now()), isTrue);
    expect(await api.status(), active);
    wallet = http.wallet();
    wallet.pushes
        .where((p) => p.name == demoEndedPushName)
        .listen((_) => _ended.add(null));
    final created = await wallet.createWithPin(config: config, pin: pin);
    session = created.session;
    address = await session.epicboxAddress();
    expect(address, endsWith('@${floonetPreset.epicboxDomain}'));
    say('$name started, expires ${active.expiresAt.toUtc()}');
  }

  /// Starts the epicbox listener and waits until it is subscribed at the relay.
  Future<void> listen() async {
    final connected = Completer<void>();
    _listener = session.startListener().listen((event) {
      events.add(event);
      say('$name listener ${event.kind.name}');
      if (event.kind == ListenerEventKind.connected && !connected.isCompleted) {
        connected.complete();
      }
    }, onError: (Object e) => say('$name listener failed: $e'));
    await connected.future.timeout(const Duration(minutes: 2));
  }

  Future<WalletSummary> refreshed() async {
    await session.refresh(minimumConfirmations: oneConfirmation).drain<void>();
    return session.summary(
      refresh: false,
      minimumConfirmations: oneConfirmation,
    );
  }

  Future<void> end() async {
    await _listener?.cancel();
    await api.end();
    expect(await api.status(), const DemoNone());
    await wallet.close();
    await _ended.close();
  }
}

/// Polls [check] every [every] until it returns a value, or fails after [limit].
Future<T> until<T>(
  String what,
  Duration limit,
  Future<T?> Function() check, {
  Duration every = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(limit);
  while (true) {
    final value = await check();
    if (value != null) return value;
    if (DateTime.now().isAfter(deadline)) fail('timed out waiting for $what');
    await Future<void>.delayed(every);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  test(
    'two demos on floonet: test coins for A, then A pays B 1 EPIC',
    () async {
      final root = await Directory.systemTemp.createTemp('wfe-demo-e2e-');
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final server = await Process.start(dart, workingDirectory: appDir, [
        'run',
        'bin/wfe_demo_server.dart',
        '--data-root',
        root.path,
        '--bind',
        '127.0.0.1',
        '--port',
        '0',
        '--ttl',
        ttl,
        '--secure-cookie',
        '0',
        '--lepic-lib',
        library!,
        if (webRoot != null) ...['--web-root', webRoot!],
      ]);
      final port = Completer<int>();
      final serverLog = File('${root.path}.server.log').openWrite();
      addTearDown(serverLog.close);
      server.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            serverLog.writeln(line);
            final m = RegExp(r'listening on [\d.]+:(\d+)').firstMatch(line);
            if (m != null && !port.isCompleted) {
              port.complete(int.parse(m.group(1)!));
            }
          });
      server.stderr.transform(utf8.decoder).listen(serverLog.write);
      addTearDown(() => server.kill(ProcessSignal.sigkill));
      final p = await port.future.timeout(const Duration(minutes: 2));
      final base = Uri.parse('http://127.0.0.1:$p');
      say('server on $base, data root ${root.path}, ttl $ttl');

      final a = Visitor('A', base);
      final b = Visitor('B', base);
      await a.start();
      await b.start();
      expect(a.address, isNot(b.address));
      await a.listen();
      await b.listen();

      // A claims; B claims right after from the same address, which the faucet refuses.
      Future<void> claimForA() async {
        for (var attempt = 1; ; attempt++) {
          final result = await a.api.claimTestCoins(a.address);
          final reply = a.http.faucetReplies.last;
          say(
            'A claim $attempt: ${result.runtimeType} (${reply.status} ${reply.body})',
          );
          switch (result) {
            case TestCoinsPaid():
              return;
            case TestCoinsCooldown(:final seconds):
              await Future<void>.delayed(Duration(seconds: seconds + 1));
            case TestCoinsFailed():
              if (attempt >= 5) fail('the faucet did not pay');
              await Future<void>.delayed(const Duration(minutes: 1));
          }
        }
      }

      await claimForA();
      final second = await b.api.claimTestCoins(b.address);
      final reply = b.http.faucetReplies.last;
      say('B claim: ${second.runtimeType} (${reply.status} ${reply.body})');
      expect(second, isA<TestCoinsCooldown>());
      expect((second as TestCoinsCooldown).seconds, inInclusiveRange(1, 120));

      // The faucet's payout lands over epicbox and confirms. A payout the faucet failed on
      // its own side is claimed again after four minutes.
      final amount = atomicPerEpic;
      var claimedAt = DateTime.now();
      final funded = await until(
        'A funded',
        const Duration(minutes: 12),
        () async {
          final s = await a.refreshed();
          say(
            'A total ${epic(s.total)}, spendable ${epic(s.spendable)}, '
            'height ${s.lastConfirmedHeight}',
          );
          if (s.spendable >= amount * BigInt.two) return s;
          if (s.total == BigInt.zero &&
              DateTime.now().difference(claimedAt) >
                  const Duration(minutes: 4)) {
            say('A: nothing arrived, claiming again');
            await claimForA();
            claimedAt = DateTime.now();
          }
          return null;
        },
      );
      expect(funded.spendable, greaterThanOrEqualTo(amount * BigInt.two));

      final sent = await a.session.sendEpicbox(
        amount: amount,
        minimumConfirmations: oneConfirmation,
        address: b.address,
      );
      say('A sent ${epic(amount)} to B: ${sent.status.name}');
      expect(sent.kind, TxKind.sent);

      final received = await until(
        'B confirmed',
        const Duration(minutes: 12),
        () async {
          final s = await b.refreshed();
          say(
            'B total ${epic(s.total)}, spendable ${epic(s.spendable)}, '
            'height ${s.lastConfirmedHeight}',
          );
          if (s.spendable < amount) return null;
          final txs = await b.session.transactions(refresh: false);
          return txs
              .where((t) => t.kind == TxKind.received && t.confirmed)
              .firstOrNull;
        },
      );
      expect(received.amountCredited, amount);
      expect(received.status, TxStatus.confirmed);
      say('B confirmed at height ${received.blockHeight}');
      expect(b.events.map((e) => e.kind), contains(ListenerEventKind.received));
      expect(
        a.events.map((e) => e.kind),
        contains(ListenerEventKind.finalized),
      );

      final ids = [a.http.cookie!, b.http.cookie!];
      await a.end();
      await b.end();
      for (final id in ids) {
        expect(await Directory('${root.path}/demos/$id').exists(), isFalse);
      }
      say('both demos ended, directories gone');

      server.kill(ProcessSignal.sigint);
      expect(await server.exitCode.timeout(const Duration(seconds: 30)), 0);
    },
    skip: library == null ? 'set WFE_DEMO_LEPIC_LIB to run it' : false,
    timeout: const Timeout(Duration(minutes: 40)),
  );
}
