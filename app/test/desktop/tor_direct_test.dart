// SPDX-License-Identifier: Apache-2.0
// Tor on the desktop: LepicDeskWallet over FakeWalletSession, which records each startTor,
// stopTor and sendTor call (one session for every open, so the counts run on). The password is a throwaway test value; no tor runs.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/desktop/data/http_address.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/net/tor_net.dart';
import 'package:epic_wallet/src/net/tor_switch.dart';
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _bundle = TorBundle(binary: '/app/bin/tor-bundle/tor', libDir: '/app/bin/tor-bundle');
const _onion = 'http://pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion';

/// Counts what the internet was asked for HTTP From the internet.
class _Probe implements PublicReachProbe {
  int asked = 0;

  @override
  Future<String?> publicIp() async {
    asked++;
    return '203.0.113.24';
  }

  @override
  Future<bool?> reachable(String ip, int port) async => false;
}

void main() {
  late Directory support;
  final probe = _Probe();
  late core.FakeWalletService service;
  late LepicDeskWallet wallet;
  TorBundle? bundle;
  core.FakeWalletSession session() => service.session;

  LepicDeskWallet make() => LepicDeskWallet(
    service: service,
    walletDir: (chain) async {
      final dir = Directory(WalletRegistry.firstWalletDir(support.path, chain));
      await dir.create(recursive: true);
      return dir.path;
    },
    secrets: MemorySecretStore(),
    filesDir: () async => support,
    nodePoll: const Duration(hours: 1),
    torBundle: () async => bundle,
    torFeature: true,
    torStartBackoff: const [Duration.zero, Duration.zero, Duration.zero],
    httpReach: HttpReachCache(probe: probe, lan: () async => '10.0.1.24'),
  );

  Future<void> tor(core.TorEvent e) async {
    session().torEvents.add(e);
    await pumpEventQueue();
  }

  Future<void> connected() async {
    await tor(const core.TorEvent(kind: core.TorEventKind.bootstrapped));
    session().torStatusValue = const core.TorStatus(kind: core.TorStatusKind.bootstrapped);
  }

  setUp(() async {
    bundle = _bundle;
    support = await Directory.systemTemp.createTemp('desk-tor-test-');
    service = core.FakeWalletService(password: _password);
    wallet = make();
    await wallet.createWallet(name: 'Main', password: _password);
    expect(await wallet.unlock(_password), isTrue);
    await wallet.sync();
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
  });

  tearDown(() async {
    TorNet.useDirect();
    await wallet.dispose();
    await support.delete(recursive: true);
  });

  group('the setting', () {
    test('off by default: nothing starts, the line says Off', () async {
      expect((await wallet.settings()).tor, isFalse);
      expect(session().torStarts, isEmpty);
      final st = await wallet.status();
      expect(st.tor, ServiceHealth.off);
      expect(torStatusLine(englishStrings, st), 'Off');
    });

    test('on starts tor from the bundle; unlock starts it again only with Start with the wallet', () async {
      await wallet.setTor(true);
      expect(session().torStarts.single, (torBinary: _bundle.binary, libDir: _bundle.libDir));
      await wallet.lock();
      expect(session().torStops, 1, reason: 'lock stops tor');
      expect((await wallet.status()).tor, ServiceHealth.off);

      expect(await wallet.unlock(_password), isTrue);
      expect((await wallet.settings()).tor, isFalse, reason: 'Tor is now-only (W4 §3.3)');
      await wallet.startAutostart();
      await pumpEventQueue();
      expect(session().torStarts, hasLength(1), reason: 'Start with the wallet is off');

      await wallet.saveSettings((await wallet.settings()).copyWith(torAutostart: true));
      await wallet.lock();
      expect(await wallet.unlock(_password), isTrue);
      await wallet.startAutostart();
      await pumpEventQueue();
      expect(session().torStarts, hasLength(2), reason: 'started again after unlock');
      expect((await wallet.settings()).tor, isTrue);

      await wallet.setTor(false);
      expect(session().torStops, 2);
      await wallet.saveSettings((await wallet.settings()).copyWith(torAutostart: false));
      await wallet.lock();
      expect(await wallet.unlock(_password), isTrue);
      await wallet.startAutostart();
      await pumpEventQueue();
      expect(session().torStarts, hasLength(2), reason: 'off: not started');
    });

    test('turned off while the bundle is looked up: tor does not start', () async {
      final found = Completer<TorBundle?>();
      final slow = LepicDeskWallet(
        service: service,
        walletDir: (chain) async => WalletRegistry.firstWalletDir(support.path, chain),
        secrets: MemorySecretStore(),
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
        torBundle: () => found.future,
        torFeature: true,
      );
      addTearDown(slow.dispose);
      expect(await slow.unlock(_password), isTrue);
      final before = session().torStarts.length;
      final on = slow.setTor(true);
      await pumpEventQueue();
      await slow.setTor(false);
      found.complete(_bundle);
      await on;
      await pumpEventQueue();
      expect(session().torStarts.length, before);
    });

    test('one switch for the app: a second wallet opens with Tor on too, and off stays off', () async {
      await wallet.setTor(true);
      await wallet.saveSettings((await wallet.settings()).copyWith(torAutostart: true));
      await wallet.createWallet(name: 'Savings', password: _password);
      await wallet.lock();
      final all = await wallet.wallets();
      await wallet.selectWallet(all.firstWhere((w) => w.name == 'Savings').id);
      expect(await wallet.unlock(_password), isTrue);
      await wallet.startAutostart();
      await pumpEventQueue();
      expect((await wallet.settings()).tor, isTrue, reason: 'never a wallet without Tor that was on');
      expect(session().torStarts, hasLength(2), reason: 'Main, then Savings');

      await wallet.saveSettings((await wallet.settings()).copyWith(torAutostart: false));
      await wallet.setTor(false);
      await wallet.lock();
      await wallet.selectWallet(all.firstWhere((w) => w.name == 'Main').id);
      expect(await wallet.unlock(_password), isTrue);
      await wallet.startAutostart();
      await pumpEventQueue();
      expect((await wallet.settings()).tor, isFalse);
      expect(session().torStarts, hasLength(2), reason: 'none at this unlock');
    });

    test('switching wallets stops the first one’s tor', () async {
      await wallet.setTor(true);
      final first = session();
      await wallet.createWallet(name: 'Savings', password: _password);
      final all = await wallet.wallets();
      await wallet.selectWallet(all.firstWhere((w) => w.name == 'Savings').id);
      expect(await wallet.unlock(_password), isTrue);
      expect(first.torStops, 1);
    });

    test('the switch is remembered: on again at the next unlock, off stays off', () async {
      final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
      addTearDown(container.dispose);
      final desk = container.read(deskProvider.notifier);
      await desk.setTor(true);
      expect(container.read(deskProvider).settings.tor, isTrue);
      expect(container.read(deskProvider).settings.torAutostart, isTrue);
      await desk.lock();
      expect(await wallet.unlock(_password), isTrue);
      await desk.startLive();
      expect(container.read(deskProvider).settings.tor, isTrue, reason: 'one switch: remembered');
      // Saving another setting leaves Tor alone.
      await desk.saveSettings(container.read(deskProvider).settings.copyWith(tor: false, hideAmounts: true));
      expect((await wallet.settings()).tor, isTrue);
      await desk.setTor(false);
      await desk.lock();
      expect(await wallet.unlock(_password), isTrue);
      await desk.startLive();
      expect(container.read(deskProvider).settings.tor, isFalse);
      await desk.lock();
    });

    test('without the bundle the switch is disabled and nothing starts', () async {
      await wallet.dispose();
      bundle = null;
      wallet = make();
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      final st = await wallet.status();
      expect(st.torIncluded, isFalse);
      expect(torStatusLine(englishStrings, st), 'Tor not included in this build');
      await wallet.setTor(true);
      expect(session().torStarts, isEmpty);
      expect((await wallet.status()).torProblem, 'Tor not included in this build');
    });
  });

  test('Retry shows while tor connects past the limit, and restarts it', () async {
    await wallet.dispose();
    wallet = LepicDeskWallet(
      service: service,
      walletDir: (chain) async => WalletRegistry.firstWalletDir(support.path, chain),
      secrets: MemorySecretStore(),
      filesDir: () async => support,
      nodePoll: const Duration(hours: 1),
      torBundle: () async => bundle,
      torFeature: true,
      torRetryAfter: const Duration(milliseconds: 50),
    );
    await wallet.createWallet(name: 'Main', password: _password);
    expect(await wallet.unlock(_password), isTrue);
    final starts = session().torStarts.length;
    await wallet.setTor(true);
    expect((await wallet.status()).torSlowStart, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect((await wallet.status()).torSlowStart, isTrue);
    await wallet.setTor(true);
    expect(session().torStarts, hasLength(starts + 2));
    final st = await wallet.status();
    expect((st.tor, st.torSlowStart), (ServiceHealth.checking, false));
  });

  group('status from events', () {
    setUp(() => wallet.setTor(true));

    test('progress, connected, publishing, ready', () async {
      expect(torStatusLine(englishStrings, await wallet.status()), 'Connecting to Tor… 0%');
      await tor(const core.TorEvent(kind: core.TorEventKind.starting, progress: 45));
      var st = await wallet.status();
      expect((st.tor, st.torProgress, st.torCanSend), (ServiceHealth.checking, 45, false));
      expect(torStatusLine(englishStrings, st), 'Connecting to Tor… 45%');
      await tor(const core.TorEvent(kind: core.TorEventKind.bootstrapped));
      st = await wallet.status();
      expect(st.torCanSend, isTrue);
      expect(torStatusLine(englishStrings, st), 'Publishing the onion address…');
      await tor(const core.TorEvent(kind: core.TorEventKind.ready, onion: 'pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion'));
      st = await wallet.status();
      expect(st.tor, ServiceHealth.ok);
      expect(torStatusLine(englishStrings, st), 'Ready');
      expect(await wallet.torAddress(), _onion);
    });

    for (final (failure, text) in [
      (core.TorFailure.network, 'Cannot reach the Tor network'),
      (core.TorFailure.start, 'Tor did not start'),
      (core.TorFailure.clock, 'The computer’s clock is wrong'),
      (core.TorFailure.missing, 'Tor not included in this build'),
      (core.TorFailure.stopped, 'Tor stopped'),
    ]) {
      test('${failure.name} stops tor with “$text”; on again is Retry', () async {
        // A start that did not connect is tried three more times by itself first.
        final tries = {core.TorFailure.network, core.TorFailure.start, core.TorFailure.stopped}.contains(failure) ? 4 : 1;
        for (var i = 0; i < tries; i++) {
          await tor(core.TorEvent(kind: core.TorEventKind.failed, failure: failure));
        }
        await tor(const core.TorEvent(kind: core.TorEventKind.stopped));
        expect(session().torStarts, hasLength(tries));
        final st = await wallet.status();
        expect(st.tor, ServiceHealth.down);
        expect(st.torProblem, text);
        expect(torStatusLine(englishStrings, st), text);
        await wallet.setTor(true);
        expect(session().torStarts, hasLength(tries + 1));
        expect((await wallet.status()).tor, ServiceHealth.checking);
      });
    }

    for (final failure in [core.TorFailure.publish, core.TorFailure.keys, core.TorFailure.listener]) {
      test('${failure.name}: “Onion address not published”', () async {
        await connected();
        await tor(core.TorEvent(kind: core.TorEventKind.failed, failure: failure));
        final st = await wallet.status();
        expect(st.torProblem, 'Onion address not published');
        expect(torStatusLine(englishStrings, st), startsWith('Onion address not published'));
      });
    }

    // RC3: the first restart with Tor on failed its control connection and stayed "Not
    // connected" until the user turned Tor off and on.
    test('a first start that fails is tried again by itself; nothing goes direct meanwhile', () async {
      await tor(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.start));
      expect(session().torStarts, hasLength(2));
      var st = await wallet.status();
      expect((st.tor, st.torProblem), (ServiceHealth.checking, null));
      expect(torStatusLine(englishStrings, st), startsWith('Connecting to Tor'));
      expect(TorNet.mode, TorNetMode.waiting);
      await connected();
      await tor(const core.TorEvent(kind: core.TorEventKind.ready, onion: 'pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion'));
      st = await wallet.status();
      expect(st.tor, ServiceHealth.ok);
    });

    test('a start that keeps failing shows failed after three more tries, then Retry starts again', () async {
      for (var i = 0; i < 3; i++) {
        await tor(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.start));
        expect((await wallet.status()).tor, ServiceHealth.checking, reason: 'try ${i + 1}');
        expect(TorNet.mode, TorNetMode.waiting);
      }
      expect(session().torStarts, hasLength(4));
      await tor(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.start));
      expect(session().torStarts, hasLength(4));
      final st = await wallet.status();
      expect((st.tor, st.torProblem), (ServiceHealth.down, 'Tor did not start'));
      expect(TorNet.mode, TorNetMode.waiting);
      await wallet.setTor(true);
      expect(session().torStarts, hasLength(5));
      // Retry gives the automatic tries again.
      await tor(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.start));
      expect(session().torStarts, hasLength(6));
    });

    test('turned off while a try waits: it does not start', () async {
      final slow = LepicDeskWallet(
        service: service,
        walletDir: (chain) async => WalletRegistry.firstWalletDir(support.path, chain),
        secrets: MemorySecretStore(),
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
        torBundle: () async => bundle,
        torFeature: true,
        torStartBackoff: const [Duration(milliseconds: 200)],
      );
      await wallet.dispose();
      wallet = slow;
      expect(await wallet.unlock(_password), isTrue);
      await wallet.setTor(true);
      final before = session().torStarts.length;
      await tor(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.start));
      await wallet.setTor(false);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(session().torStarts, hasLength(before));
      expect((await wallet.status()).tor, ServiceHealth.off);
    });

    test('a stall before connecting is retried, showing Connecting throughout', () async {
      await tor(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.network));
      expect(session().torStarts, hasLength(2));
      expect(session().torStops, 1);
      var st = await wallet.status();
      expect((st.tor, st.torProblem), (ServiceHealth.checking, null));
      // The stop of the first try does not end the second.
      await tor(const core.TorEvent(kind: core.TorEventKind.starting, progress: 10));
      expect((await wallet.status()).tor, ServiceHealth.checking);
      await connected();
      await tor(const core.TorEvent(kind: core.TorEventKind.ready, onion: 'pg6mmjiyjmcrsslvykfwnntlaru7p5svn6y2ymmju6nubxndf4pscryd.onion'));
      st = await wallet.status();
      expect(st.tor, ServiceHealth.ok);
    });

    test('tor that loses the network after connecting is restarted by itself, with fresh tries', () async {
      await connected();
      await tor(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.network));
      expect(session().torStarts, hasLength(2));
      final st = await wallet.status();
      expect((st.tor, st.torCanSend), (ServiceHealth.checking, false));
      expect(TorNet.mode, TorNetMode.waiting);
    });

    test('a clock failure is not restarted: it would fail again', () async {
      await tor(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.clock));
      await tor(const core.TorEvent(kind: core.TorEventKind.stopped));
      expect(session().torStarts, hasLength(1));
      expect((await wallet.status()).tor, ServiceHealth.down);
    });

    test('listener and keys leave sends working', () async {
      await connected();
      await tor(const core.TorEvent(kind: core.TorEventKind.failed, failure: core.TorFailure.keys));
      final st = await wallet.status();
      expect((st.tor, st.torCanSend), (ServiceHealth.slow, true));
      expect(torStatusLine(englishStrings, st), 'Onion address not published. Sends work.');
    });

    test('a stop nobody asked for restarts tor; after the tries it reads “Tor stopped”', () async {
      await connected();
      await tor(const core.TorEvent(kind: core.TorEventKind.stopped));
      expect(session().torStarts, hasLength(2));
      expect((await wallet.status()).tor, ServiceHealth.checking);
      for (var i = 0; i < 3; i++) {
        await tor(const core.TorEvent(kind: core.TorEventKind.stopped));
      }
      expect(session().torStarts, hasLength(4));
      expect(torStatusLine(englishStrings, await wallet.status()), 'Tor stopped');
    });

    test('a payment over Tor reloads the history', () async {
      final before = session().transactionsCalls;
      await tor(core.TorEvent(kind: core.TorEventKind.received, txId: 7, amount: BigInt.one));
      expect(session().transactionsCalls, greaterThan(before));
    });

    test('a reopen on another node restarts tor', () async {
      await connected();
      await wallet.useNode('https://node.example.org');
      expect(session().torStops, 1);
      expect(session().torStarts, hasLength(2), reason: 'started again on the new session');
    });
  });

  group('send', () {
    const waits = 'The payment waits in Activity; cancel it there to free the coins.';

    test('an onion under Link goes over Tor', () async {
      await wallet.setTor(true);
      await connected();
      expect(wallet.isOnionAddress(_onion), isTrue);
      expect(wallet.isOnionAddress('https://wallet.example.org'), isFalse);
      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: _onion, message: 'rent'));
      expect(r, isA<SendDone>(), reason: r is SendFailed ? r.message : '');
      expect((r as SendDone).tx.method, TxMethod.tor);
      expect(session().torSends.single.onion, _onion);
      expect(session().httpSends, isEmpty);
      expect(session().sentMessages.single, 'rent');
    });

    test('a build without Tor sends an onion under HTTP as HTTP and never starts tor', () async {
      final plain = LepicDeskWallet(
        service: service,
        walletDir: (chain) async => WalletRegistry.firstWalletDir(support.path, chain),
        secrets: MemorySecretStore(),
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
        torBundle: () async => bundle,
        torFeature: false,
      );
      addTearDown(plain.dispose);
      expect(await plain.unlock(_password), isTrue);
      await pumpEventQueue();
      final starts = session().torStarts.length;
      final r = await plain.send(const SendRequest(method: TxMethod.http, amount: 1000, to: _onion));
      expect(r is SendFailed ? r.message : '', isNot(contains('Turn on Tor')), reason: 'no pointer to a hidden switch');
      expect(session().torSends, isEmpty);
      expect(session().torStarts.length, starts);
    });

    test('Tor off: refused before LEPIC with Turn on Tor', () async {
      final r = await wallet.send(const SendRequest(method: TxMethod.tor, amount: 1000, to: _onion));
      expect((r as SendFailed).message, contains('Turn on Tor'));
      expect(r.inActivity, isFalse);
      expect(session().torSends, isEmpty);
    });

    test('Tor still connecting: refused before LEPIC', () async {
      await wallet.setTor(true);
      final r = await wallet.send(const SendRequest(method: TxMethod.tor, amount: 1000, to: _onion));
      expect((r as SendFailed).message, 'Tor is still connecting. Try again in a moment.');
      expect(session().torSends, isEmpty);
    });

    test('not an onion: refused before LEPIC', () async {
      await wallet.setTor(true);
      await connected();
      final r = await wallet.send(const SendRequest(method: TxMethod.tor, amount: 1000, to: 'abc.onion'));
      expect((r as SendFailed).message, 'Not an onion address');
      expect(session().torSends, isEmpty);
    });

    test('a send takes its time; the result comes when it ends', () async {
      await wallet.setTor(true);
      await connected();
      session().torSendGate = Completer<void>();
      var done = false;
      final pending = wallet.send(const SendRequest(method: TxMethod.tor, amount: 1000, to: _onion)).then((r) {
        done = true;
        return r;
      });
      await pumpEventQueue();
      expect(done, isFalse);
      session().torSendGate!.complete();
      expect(await pending, isA<SendDone>());
    });

    test('not reached: stored, waits in Activity', () async {
      await wallet.setTor(true);
      await connected();
      session().sendError = const core.WalletError(kind: core.WalletErrorKind.onionUnreachable, message: 'not reached');
      final r = await wallet.send(const SendRequest(method: TxMethod.tor, amount: 1000, to: _onion));
      expect((r as SendFailed).inActivity, isTrue);
      expect(r.message, 'The recipient’s wallet is not reachable over Tor. Epicbox delivers a payment while it is offline. $waits');
      final waiting = (await wallet.transactions()).where((t) => t.state == TxState.waitingRecipient && !t.incoming);
      expect(waiting.single.method, TxMethod.tor);
    });

    test('refused by LEPIC before storing: not in Activity', () async {
      await wallet.setTor(true);
      await connected();
      session().sendError = const core.WalletError(kind: core.WalletErrorKind.notEnoughFunds, message: 'short');
      final r = await wallet.send(const SendRequest(method: TxMethod.tor, amount: 1000, to: _onion));
      expect((r as SendFailed).inActivity, isFalse);
      expect(r.message, 'Not enough EPIC');
      expect((await wallet.transactions()).where((t) => !t.incoming), isEmpty);
    });

    test('tor down when LEPIC checks: not stored, not in Activity', () async {
      await wallet.setTor(true);
      await connected();
      session().torStatusValue = core.TorStatus.off;
      final r = await wallet.send(const SendRequest(method: TxMethod.tor, amount: 1000, to: _onion));
      expect((r as SendFailed).inActivity, isFalse);
      expect(r.message, 'Tor is not connected');
    });
  });

  // WAL-05: plain http:// to another computer never goes through a Tor exit, in any mode.
  group('plain HTTP with the Tor switch on', () {
    const lan = 'http://10.0.1.30:3415';
    final offText = englishStrings.sendPlainHttpOffWithTor;

    tearDown(() {
      NetGate.set(NetworkMode.standard);
      TorSwitch.on = false;
    });

    test('Normal: a send with consent is refused before LEPIC', () async {
      await wallet.setTor(true);
      await connected();
      expect(TorSwitch.on, isTrue);
      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: lan, allowPlainHttp: true));
      expect((r as SendFailed).message, offText);
      expect(r.inActivity, isFalse);
      expect(session().httpSends, isEmpty);
    });

    test('Tor only: refused the same way', () async {
      NetGate.set(NetworkMode.torOnly);
      TorSwitch.on = true;
      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: lan, allowPlainHttp: true));
      expect((r as SendFailed).message, offText);
      expect(session().httpSends, isEmpty);
    });

    test('https and an onion still go', () async {
      await wallet.setTor(true);
      await connected();
      expect(await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: 'https://wallet.example.org')), isA<SendDone>());
      expect(await wallet.send(const SendRequest(method: TxMethod.tor, amount: 1000, to: _onion)), isA<SendDone>());
      expect(session().httpSends.single.url, 'https://wallet.example.org');
      expect(session().torSends.single.onion, _onion);
    });

    test('switch off: plain HTTP goes with consent, and only with it', () async {
      final asked = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: lan));
      expect((asked as SendFailed).message, englishStrings.deskErrPlainHttp);
      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: lan, allowPlainHttp: true));
      expect(r, isA<SendDone>(), reason: r is SendFailed ? r.message : '');
      expect(session().httpSends.single.allowPlainHttp, isTrue);
    });

    test('a resend of an earlier plain HTTP send is refused once Tor is on', () async {
      session().transactionsValue.add(core.fakeTx(id: 77, slateId: 'plain-1', kind: core.TxKind.sent, amountDebited: BigInt.from(1000), counterparty: lan, transport: 'http', undelivered: true));
      await wallet.setTor(true);
      await connected();
      await expectLater(wallet.resendTx(77), throwsA(isA<Exception>().having((e) => deskErrorText(e), 'text', offText)));
      expect(session().httpSends, isEmpty);
    });
  });

  test('Activity names a Tor receipt by its transport', () {
    final e = core.fakeTx(id: 3, slateId: 's', transport: 'tor', amountCredited: BigInt.from(5));
    expect(deskTx(e, tip: 0, minConf: 10, fallbackId: -1).method, TxMethod.tor);
    final h = core.fakeTx(id: 4, slateId: 't', counterparty: _onion, amountCredited: BigInt.from(5));
    expect(deskTx(h, tip: 0, minConf: 10, fallbackId: -1).method, TxMethod.tor);
  });

  test('HTTP From the internet asks nothing over the clearnet once Tor is on', () async {
    await wallet.saveSettings(const DeskSettings(payments: PaymentPrefs(linkHttp: true), publicMode: true));
    await wallet.setHttpListening(true);
    session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3415));
    await pumpEventQueue();
    probe.asked = 0;
    expect(await wallet.httpReach(recheck: true), isNotNull);
    expect(probe.asked, 1);
    await wallet.setTor(true);
    // The check needs Tor off: said, never asked.
    expect((await wallet.httpReach(recheck: true))?.needsTorOff, isTrue);
    expect(await wallet.httpAddress(), '');
    expect(probe.asked, 1);
  });

}
