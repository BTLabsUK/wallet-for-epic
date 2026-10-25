// The desktop wallet follows the network mode of Settings › Advanced (network_gate.dart):
// Offline asks no node, starts no listener or tor and keeps the wallet open on its own files,
// and leaving it starts everything again without a restart; Tor only turns the Tor switch on
// and refuses it off. LepicDeskWallet over FakeWalletSession; the password is a throwaway
// test value; no tor runs.
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/net/tor_net.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _bundle = TorBundle(binary: '/app/bin/tor-bundle/tor', libDir: '/app/bin/tor-bundle');

void main() {
  late Directory support;
  late core.FakeWalletService service;
  late MemorySecretStore secrets;
  late LepicDeskWallet wallet;
  core.FakeWalletSession session() => service.session;

  LepicDeskWallet make() => LepicDeskWallet(
    service: service,
    walletDir: (chain) async {
      final dir = Directory('${support.path}/wallets/${chain.name}');
      await dir.create(recursive: true);
      return dir.path;
    },
    secrets: secrets,
    filesDir: () async => support,
    nodePoll: const Duration(hours: 1),
    torBundle: () async => _bundle,
    torFeature: true,
  );

  Future<void> mode(NetworkMode m) async {
    final s = await wallet.settings();
    await wallet.saveSettings(s.copyWith(advanced: s.advanced.withMode(m)));
    await pumpEventQueue();
  }

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-net-modes-test-');
    service = core.FakeWalletService(password: _password);
    secrets = MemorySecretStore();
    wallet = make();
    await wallet.createWallet(name: 'Main', password: _password);
    expect(await wallet.unlock(_password), isTrue);
    await pumpEventQueue();
  });

  tearDown(() async {
    await wallet.dispose();
    NetGate.set(NetworkMode.standard);
    TorNet.useDirect();
    await support.delete(recursive: true);
  });

  test('Offline while open: everything that reaches the network stops and is refused', () async {
    await wallet.setEpicboxListening(true);
    await wallet.setTor(true);
    expect(session().listenerStarts, 1);
    expect(session().torStarts, hasLength(1));
    await mode(NetworkMode.offline);
    expect(NetGate.offline, isTrue);
    expect(session().listenerStops, greaterThan(0));
    expect(session().torStops, greaterThan(0));
    final tips = session().nodeTipsFor.length;
    final refreshes = session().refreshCalls;
    await wallet.syncNow();
    await wallet.startAutostart();
    expect(session().nodeTipsFor.length, tips);
    expect(session().refreshCalls, refreshes);
    expect(session().listenerStarts, 1);
    await expectLater(wallet.setEpicboxListening(true), throwsA(isA<DeskError>()));
    await expectLater(wallet.setTor(true), throwsA(isA<DeskError>()));
    await expectLater(wallet.rescan().drain<void>(), throwsA(isA<DeskError>()));
    expect(session().torStarts, hasLength(1));
    // The wallet stays open on what it last saw.
    expect(await wallet.balance(), isNotNull);
  });

  test('back to Standard resumes what ran, without a restart', () async {
    await wallet.setEpicboxListening(true);
    await wallet.setTor(true);
    await mode(NetworkMode.offline);
    final tips = session().nodeTipsFor.length;
    await mode(NetworkMode.standard);
    await pumpEventQueue();
    expect(session().listenerStarts, 2);
    expect(session().torStarts, hasLength(2));
    expect(session().nodeTipsFor.length, greaterThan(tips));
  });

  test('unlocked in Offline: local data only; leaving it starts as an unlock would', () async {
    await wallet.lock();
    await mode(NetworkMode.offline);
    session().nodeTipsFor.clear();
    final refreshes = session().refreshCalls;
    expect(await wallet.unlock(_password), isTrue);
    await wallet.startAutostart();
    await pumpEventQueue();
    expect(session().nodeTipsFor, isEmpty);
    expect(session().refreshCalls, refreshes);
    expect(session().listenerStarts, 0);
    await mode(NetworkMode.standard);
    await pumpEventQueue();
    expect(session().nodeTipsFor, isNotEmpty);
    expect(session().refreshCalls, greaterThan(refreshes));
  });

  test('Tor only turns the Tor switch on and refuses it off', () async {
    expect((await wallet.settings()).torAutostart, isFalse);
    await mode(NetworkMode.torOnly);
    final s = await wallet.settings();
    expect(s.torAutostart, isTrue);
    expect(s.tor, isTrue);
    expect(session().torStarts, hasLength(1));
    await expectLater(wallet.setTor(false), throwsA(isA<DeskError>()));
    await wallet.saveSettings(s.copyWith(torAutostart: false));
    expect((await wallet.settings()).torAutostart, isTrue);
    session().routeLog.clear();
    await wallet.setEpicboxOverTor(false);
    expect(session().routeLog, isNot(contains('epicboxOverTor:false')));
    // Back to Standard leaves the switch on, for the user to turn off.
    await mode(NetworkMode.standard);
    expect((await wallet.settings()).torAutostart, isTrue);
    await wallet.setTor(false);
    expect((await wallet.settings()).tor, isFalse);
  });

  test('Tor only: a wallet opens with Tor on', () async {
    await mode(NetworkMode.torOnly);
    await wallet.lock();
    session().torStarts.clear();
    expect(await wallet.unlock(_password), isTrue);
    await wallet.startAutostart();
    await pumpEventQueue();
    expect(session().torStarts, hasLength(1));
    expect(session().routeLog, contains('expectTor'));
  });

  group('Offline with a local node', () {
    for (final node in ['http://127.0.0.1:3413', 'http://10.100.10.20:3413']) {
      test('$node: still synced, rechecked and receiving over HTTP; Epicbox and Tor stay off', () async {
        await wallet.useNode(node);
        await pumpEventQueue();
        await mode(NetworkMode.offline);
        final tips = session().nodeTipsFor.length;
        final refreshes = session().refreshCalls;
        await wallet.syncNow();
        expect(session().refreshCalls, greaterThan(refreshes));
        await wallet.rescan().drain<void>();
        expect(session().scanCalls, greaterThan(0));
        await wallet.saveSettings((await wallet.settings()).let((s) => s.copyWith(payments: s.payments.copyWith(linkHttp: true))));
        await wallet.setHttpListening(true);
        expect(session().httpListenerStarts, isNotEmpty);
        await expectLater(wallet.setEpicboxListening(true), throwsA(isA<DeskError>()));
        await expectLater(wallet.setTor(true), throwsA(isA<DeskError>()));
        expect(session().nodeTipsFor.length, greaterThanOrEqualTo(tips));
      });
    }

    test('a public node: refused as before', () async {
      await wallet.useNode('https://node.example');
      await mode(NetworkMode.offline);
      final refreshes = session().refreshCalls;
      await wallet.syncNow();
      expect(session().refreshCalls, refreshes);
      await expectLater(wallet.rescan().drain<void>(), throwsA(isA<DeskError>()));
      await wallet.saveSettings((await wallet.settings()).let((s) => s.copyWith(payments: s.payments.copyWith(linkHttp: true))));
      await expectLater(wallet.setHttpListening(true), throwsA(isA<DeskError>()));
    });
  });
}


extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
