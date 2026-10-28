// SPDX-License-Identifier: Apache-2.0
// Epicbox over Tor on the desktop, the mechanism the app's Tor setting drives: on by default and
// handed to the open wallet at unlock and on change, with the onion routes; tor that starts with
// the wallet is announced before the first Epicbox connection; a retry keeps the connection
// waiting; Tor off after tor ended lets it go direct; and ServiceStatus.epicboxViaTor says when
// the connection waits for tor. LepicDeskWallet over FakeWalletSession; the password is a
// throwaway test value; no tor runs.
import 'dart:io';

import 'package:epic_wallet/src/btlabs_onions.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
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
    // Tor that ended stays ended here: no restarts by itself.
    torStartBackoff: const [],
  );

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-epicbox-tor-test-');
    service = core.FakeWalletService(password: _password);
    secrets = MemorySecretStore();
    wallet = make();
    await wallet.createWallet(name: 'Main', password: _password);
    expect(await wallet.unlock(_password), isTrue);
  });

  tearDown(() async {
    await wallet.dispose();
    await support.delete(recursive: true);
  });

  test('on by default; handed to the open wallet at unlock and on change', () async {
    expect(session().epicboxOverTorValue, isTrue, reason: 'given at unlock');
    await wallet.setEpicboxOverTor(false);
    expect(session().epicboxOverTorValue, isFalse, reason: 'applied at once');
    await wallet.lock();
    expect(await wallet.unlock(_password), isTrue);
    expect(session().epicboxOverTorValue, isFalse, reason: 'kept for the next unlock');
  });

  test('the TLS onion routes reach the wallet at unlock', () async {
    expect(session().onionRoutes, onionRoutesOf(wallet.onions));
    expect(session().onionRoutes!.map((r) => r.host), contains('flooepicbox.btlabs.uk'));
  });

  test('tor that starts with the wallet is announced before the first Epicbox connection', () async {
    await wallet.saveSettings((await wallet.settings()).copyWith(torAutostart: true));
    await wallet.lock();
    expect(await wallet.unlock(_password), isTrue);
    session().routeLog.clear();
    await wallet.startAutostart();
    await pumpEventQueue();
    final log = session().routeLog;
    expect(log, containsAllInOrder(['expectTor', 'listener', 'startTor']));
    expect(log.indexOf('expectTor'), lessThan(log.indexOf('listener')), reason: 'no direct connection first');
  });

  test('without tor at unlock the listener starts without waiting for it', () async {
    session().routeLog.clear();
    await wallet.startAutostart();
    await pumpEventQueue();
    expect(session().routeLog, ['listener']);
  });

  test('a retry announces the new tor before stopping the old one', () async {
    await wallet.setTor(true);
    await pumpEventQueue();
    session().torEvents.add(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.stopped));
    session().torEvents.add(const core.TorEvent(kind: core.TorEventKind.stopped));
    await pumpEventQueue();
    session().routeLog.clear();
    await wallet.setTor(true);
    await pumpEventQueue();
    expect(session().routeLog, ['expectTor', 'stopTor', 'startTor']);
  });

  test('Tor turned off after it ended by itself lets the Epicbox connection go direct', () async {
    await wallet.setTor(true);
    await pumpEventQueue();
    session().torEvents.add(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.stopped));
    session().torEvents.add(const core.TorEvent(kind: core.TorEventKind.stopped));
    await pumpEventQueue();
    session().routeLog.clear();
    await wallet.setTor(false);
    expect(session().routeLog, ['stopTor']);
  });

  test('epicboxViaTor while Tor is on and Epicbox over Tor is on', () async {
    await wallet.setEpicboxListening(true);
    expect((await wallet.status()).epicboxViaTor, isFalse, reason: 'Tor off');
    await wallet.setTor(true);
    await pumpEventQueue();
    final status = await wallet.status();
    expect(status.epicboxViaTor, isTrue);
    expect(status.epicboxHealth, ServiceHealth.checking, reason: 'shown as Connecting via Tor');
    await wallet.setEpicboxOverTor(false);
    expect((await wallet.status()).epicboxViaTor, isFalse);
  });
}
