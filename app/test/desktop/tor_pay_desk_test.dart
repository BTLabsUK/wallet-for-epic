// SPDX-License-Identifier: Apache-2.0
// Tor for payments on the desktop (item 2): Link · Tor starts tor for the onion alone, the node,
// Epicbox and http(s) sends staying direct; the Tor switch, when it comes on, carries them over
// the same tor; Node only and Kill switch stop it; Tor only routes everything. LepicDeskWallet
// over FakeWalletSession; the password is a throwaway test value; no tor runs.
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/net/tor_net.dart' show TorNet, TorNetMode;
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _bundle = TorBundle(binary: '/app/bin/tor-bundle/tor', libDir: '/app/bin/tor-bundle');
const _onion = 'pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion';

void main() {
  late Directory support;
  late core.FakeWalletService service;
  late LepicDeskWallet wallet;
  core.FakeWalletSession session() => service.session;

  Future<void> linkTor(bool on) async {
    final s = await wallet.settings();
    await wallet.saveSettings(s.copyWith(payments: s.payments.copyWith(linkTor: on)));
    await pumpEventQueue();
  }

  Future<void> mode(NetworkMode m) async {
    final s = await wallet.settings();
    await wallet.saveSettings(s.copyWith(advanced: s.advanced.withMode(m)));
    await pumpEventQueue();
  }

  Future<void> ready() async {
    session().torEvents.add(const core.TorEvent(kind: core.TorEventKind.bootstrapped, socksPort: 9150));
    session().torEvents.add(const core.TorEvent(kind: core.TorEventKind.ready, onion: _onion, socksPort: 9150));
    await pumpEventQueue();
  }

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-tor-pay-test-');
    service = core.FakeWalletService(password: _password);
    wallet = LepicDeskWallet(
      service: service,
      walletDir: (chain) async {
        final dir = Directory(WalletRegistry.firstWalletDir(support.path, chain));
        await dir.create(recursive: true);
        return dir.path;
      },
      secrets: MemorySecretStore(),
      filesDir: () async => support,
      nodePoll: const Duration(hours: 1),
      torBundle: () async => _bundle,
      torFeature: true,
      torStartBackoff: const [],
    );
    await wallet.createWallet(name: 'Main', password: _password);
    expect(await wallet.unlock(_password), isTrue);
    await wallet.startAutostart();
    await pumpEventQueue();
  });

  tearDown(() async {
    await wallet.dispose();
    await support.delete(recursive: true);
    NetGate.set(NetworkMode.standard);
  });

  test('Normal: Link · Tor starts tor for payments alone; the rest stays direct', () async {
    expect(session().nodeAndHttpOverTorValue, isFalse, reason: 'the Tor switch is off');
    expect(session().epicboxOverTorValue, isFalse);
    session().routeLog.clear();
    await linkTor(true);
    expect(session().torStarts, hasLength(1));
    expect(session().routeLog, isNot(contains('expectTor')), reason: 'nothing waits for a tor for payments');
    expect(session().routeLog, isNot(contains('nodeAndHttpOverTor:true')));
    await ready();
    final st = await wallet.status();
    expect(st.tor, ServiceHealth.ok);
    expect(st.torCanSend, isTrue, reason: 'sends to onions work');
    expect((await wallet.settings()).tor, isFalse, reason: 'the Tor switch is untouched');
    expect(TorNet.mode, TorNetMode.direct, reason: 'prices and updates keep the clearnet');
  });

  test('a send to an onion goes through the tor for payments', () async {
    await linkTor(true);
    await ready();
    session().torStatusValue = const core.TorStatus(kind: core.TorStatusKind.ready);
    session().summaryValue = core.WalletSummary(
      lastConfirmedHeight: BigInt.from(2500000),
      minimumConfirmations: BigInt.from(3),
      total: BigInt.from(100000000),
      spendable: BigInt.from(100000000),
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: true,
    );
    final r = await wallet.send(const SendRequest(method: TxMethod.tor, amount: 10000000, to: _onion));
    expect(r, isNot(isA<SendFailed>()), reason: r is SendFailed ? r.message : null);
    expect(session().torSends, isNotEmpty);
  });

  test('the Tor switch on carries every connection over the same tor; off again keeps it for payments', () async {
    await linkTor(true);
    await ready();
    session().routeLog.clear();
    await wallet.saveSettings((await wallet.settings()).copyWith(torAutostart: true));
    await wallet.setTor(true);
    await pumpEventQueue();
    expect(session().torStarts, hasLength(1), reason: 'no second tor');
    expect(session().nodeAndHttpOverTorValue, isTrue);
    expect(session().epicboxOverTorValue, isTrue);
    await wallet.saveSettings((await wallet.settings()).copyWith(torAutostart: false));
    await wallet.setTor(false);
    await pumpEventQueue();
    expect(session().routeLog, isNot(contains('stopTor')), reason: 'Link · Tor still wants it');
    expect(session().nodeAndHttpOverTorValue, isFalse);
    expect(session().epicboxOverTorValue, isFalse);
    expect((await wallet.status()).tor, ServiceHealth.ok);
  });

  test('Link · Tor off stops the tor for payments', () async {
    await linkTor(true);
    await ready();
    session().routeLog.clear();
    await linkTor(false);
    expect(session().routeLog, contains('stopTor'));
    expect((await wallet.status()).tor, ServiceHealth.off);
  });

  for (final m in [NetworkMode.nodeOnly, NetworkMode.killSwitch]) {
    test('${m.name}: no tor for payments; it stops on the way in and starts on the way out', () async {
      await linkTor(true);
      await ready();
      session().routeLog.clear();
      await mode(m);
      expect(session().routeLog, contains('stopTor'));
      expect((await wallet.status()).tor, ServiceHealth.off);
      final starts = session().torStarts.length;
      await linkTor(false);
      await linkTor(true);
      expect(session().torStarts, hasLength(starts), reason: 'blocked by the mode');
      await mode(NetworkMode.standard);
      expect(session().torStarts.length, greaterThan(starts), reason: 'back in Normal it starts again');
    });
  }

  test('Tor only: the switch is forced on and every route goes over tor', () async {
    await linkTor(true);
    await mode(NetworkMode.torOnly);
    await pumpEventQueue();
    expect(session().nodeAndHttpOverTorValue, isTrue);
    expect(session().epicboxOverTorValue, isTrue);
    expect((await wallet.settings()).tor, isTrue);
  });
}
