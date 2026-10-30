// SPDX-License-Identifier: Apache-2.0
// Link HTTP on the desktop: LepicDeskWallet over FakeWalletSession, which records each
// sendHttp and startHttpListener call. The password is a throwaway test value.
import 'dart:io';

import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/data/http_address.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

/// A router with public IP 203.0.113.24 whose port is not forwarded; counts what it was asked.
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
  late core.FakeWalletService service;
  late LepicDeskWallet wallet;
  late _Probe probe;
  core.FakeWalletSession session() => service.session;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-http-test-');
    service = core.FakeWalletService(password: _password);
    probe = _Probe();
    wallet = LepicDeskWallet(
      httpReach: HttpReachCache(probe: probe, lan: () async => '10.0.1.24'),
      service: service,
      walletDir: (chain) async {
        final dir = Directory(WalletRegistry.firstWalletDir(support.path, chain));
        await dir.create(recursive: true);
        return dir.path;
      },
      secrets: MemorySecretStore(),
      filesDir: () async => support,
      nodePoll: const Duration(hours: 1),
    );
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
    await wallet.dispose();
    await support.delete(recursive: true);
  });

  group('address rules', () {
    test('http(s)://host[:port], HTTP in capitals; host:port and others refused', () {
      expect(httpAddressProblem('https://wallet.example.org'), isNull);
      expect(httpAddressProblem(' HTTP://203.0.113.5:3415 '), isNull);
      expect(httpAddressProblem('https://wallet.example.org:8443/x'), isNull);
      expect(httpAddressProblem('203.0.113.5:3415'), 'Start with https:// or http://');
      expect(httpAddressProblem('ftp://203.0.113.5'), 'Not an http(s) address');
      expect(httpAddressProblem('http://abc.onion'), 'Onion addresses need Tor');
      expect(httpAddressProblem(''), isNotNull);
    }, skip: torBuilt ? null : 'no Tor in this build');

    test('consent only for plain http to another computer', () {
      expect(plainHttpNeedsConsent('http://203.0.113.5:3415'), isTrue);
      expect(plainHttpNeedsConsent('HTTP://wallet.example.org'), isTrue);
      expect(plainHttpNeedsConsent('https://203.0.113.5'), isFalse);
      expect(plainHttpNeedsConsent('http://127.0.0.1:3415'), isFalse);
      expect(plainHttpNeedsConsent('http://localhost:3415'), isFalse);
      expect(plainHttpNeedsConsent('http://[::1]:3415'), isFalse);
    });
  });

  group('send', () {
    test('a malformed address is refused before LEPIC', () async {
      for (final to in ['203.0.113.5:3415', 'ftp://203.0.113.5', 'esAddress@epicbox.epiccash.com']) {
        final r = await wallet.send(SendRequest(method: TxMethod.http, amount: 1000, to: to));
        expect(r, isA<SendFailed>(), reason: to);
        expect((r as SendFailed).inActivity, isFalse);
      }
      expect(session().httpSends, isEmpty);
    });

    test('plain http to another computer needs consent', () async {
      const to = 'http://203.0.113.5:3415';
      final refused = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: to));
      expect((refused as SendFailed).message, 'Plain HTTP not confirmed');
      expect(session().httpSends, isEmpty);

      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: to, allowPlainHttp: true, message: ' rent '));
      expect(r, isA<SendDone>());
      expect((r as SendDone).tx.method, TxMethod.http);
      final sent = session().httpSends.single;
      expect(sent.url, to);
      expect(sent.allowPlainHttp, isTrue);
      expect(sent.amount, BigInt.from(1000));
      expect(session().sentMessages.single, 'rent');
    });

    test('plain http to this computer and https need no consent', () async {
      expect(await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: 'http://127.0.0.1:3415')), isA<SendDone>());
      // An https send never passes the consent on, even when the screen set it.
      expect(await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: 'https://wallet.example.org', allowPlainHttp: true)), isA<SendDone>());
      expect([for (final s in session().httpSends) s.allowPlainHttp], [false, false]);
    });

    test('no answer: the payment stays sent and waits in Activity', () async {
      session().sendError = const core.WalletError(kind: core.WalletErrorKind.transportFailed, message: 'connection refused');
      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: 'https://wallet.example.org'));
      expect(r, isA<SendFailed>());
      expect((r as SendFailed).inActivity, isTrue);
      expect(r.message, contains('did not answer'));
      final waiting = (await wallet.transactions()).where((t) => t.state == TxState.waitingRecipient && !t.incoming);
      expect(waiting, hasLength(1));
      expect(waiting.single.method, TxMethod.http);
    });

    test('LEPIC’s URL errors read as short sentences', () async {
      session().sendError = const core.WalletError(kind: core.WalletErrorKind.httpUrlInvalid, message: 'bad url');
      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: 'https://wallet.example.org'));
      expect((r as SendFailed).message, 'Not an http(s) address');
      expect(r.inActivity, isFalse);
    });
  });

  group('listener', () {
    test('off until turned on; follows the reach and the port', () async {
      expect((await wallet.status()).httpListener, ServiceHealth.off);
      expect(await wallet.httpAddress(), '');
      await wallet.setListening(true);
      expect(session().httpListenerStarts, isEmpty, reason: 'the HTTP switch is off');

      await wallet.saveSettings(const DeskSettings(payments: PaymentPrefs(linkHttp: true)));
      await wallet.setHttpListening(true);
      expect(session().httpListenerStarts.single, (exposure: core.HttpExposure.localOnly, port: 3415));
      expect((await wallet.status()).httpListener, ServiceHealth.checking);
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3415));
      await pumpEventQueue();
      expect((await wallet.status()).httpListener, ServiceHealth.ok);
      expect(await wallet.httpAddress(), 'http://127.0.0.1:3415');

      await wallet.saveSettings(const DeskSettings(payments: PaymentPrefs(linkHttp: true), publicMode: true, httpPort: 3420));
      expect(session().httpListenerStops, 1);
      expect(session().httpListenerStarts.last, (exposure: core.HttpExposure.internet, port: 3420));
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3420));
      await pumpEventQueue();
      expect(await wallet.httpAddress(), 'http://203.0.113.24:3420', reason: 'the router’s public IP, never the LAN address');
      final reach = await wallet.httpReach();
      expect((reach!.publicAddress, reach.lanAddress, reach.reachable), ('http://203.0.113.24:3420', 'http://10.0.1.24:3420', false));

      // Stop receiving stops HTTP too; Start listener brings it back while the switch is on.
      await wallet.setListening(false);
      expect(session().httpListenerStops, 2);
      expect((await wallet.status()).httpListener, ServiceHealth.off);
      await wallet.setListening(true);
      expect(session().httpListenerStarts, hasLength(3));
    });

    test('Node only with a LAN node: the Link listener stops, no address, the internet is not asked', () async {
      await wallet.useNode('http://10.100.10.20:3413');
      await wallet.saveSettings((await wallet.settings()).let((s) => s.copyWith(payments: s.payments.copyWith(linkHttp: true), publicMode: true, httpPort: 3420)));
      await wallet.setHttpListening(true);
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3420));
      await pumpEventQueue();
      final s = await wallet.settings();
      await wallet.saveSettings(s.copyWith(advanced: s.advanced.withMode(NetworkMode.nodeOnly)));
      await pumpEventQueue();
      addTearDown(() => NetGate.set(NetworkMode.standard));
      final asked = probe.asked;
      expect((await wallet.status()).httpListener, isNot(ServiceHealth.ok), reason: 'no Link in Node only');
      expect(await wallet.httpAddress(), '');
      expect((await wallet.httpReach())?.publicAddress, isNull);
      expect(probe.asked, asked);
    });

    test('a port in use becomes the status text; Try again starts it again', () async {
      await wallet.saveSettings(const DeskSettings(payments: PaymentPrefs(linkHttp: true)));
      await wallet.setHttpListening(true);
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.portInUse, port: 3415));
      await pumpEventQueue();
      final st = await wallet.status();
      expect(st.httpListener, ServiceHealth.down);
      expect(st.httpProblem, HttpProblem.portInUse);
      expect(st.httpProblemPort, 3415);
      expect(await wallet.httpAddress(), '');
      await wallet.setHttpListening(true);
      expect(session().httpListenerStarts, hasLength(2));
      expect((await wallet.status()).httpProblem, isNull);
    });

    test('a payment reloads the history; a refusal changes nothing', () async {
      await wallet.setHttpListening(true);
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3415));
      await pumpEventQueue();
      final before = session().transactionsCalls;
      session().httpListenerEvents.add(core.HttpListenerEvent(kind: core.HttpListenerEventKind.received, txId: 7, amount: BigInt.one));
      await pumpEventQueue();
      expect(session().transactionsCalls, greaterThan(before));
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.refused, refusal: core.HttpRefusal.unavailable));
      await pumpEventQueue();
      expect((await wallet.status()).httpListener, ServiceHealth.ok);
    });

    test('lock stops it', () async {
      await wallet.setHttpListening(true);
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3415));
      await pumpEventQueue();
      await wallet.lock();
      expect(session().httpListenerStops, 1);
      expect((await wallet.status()).httpListener, ServiceHealth.off);
    });

    test('unlock starts it only with Link · HTTP on (the one switch)', () async {
      final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
      addTearDown(container.dispose);
      final desk = container.read(deskProvider.notifier);
      await desk.startLive();
      expect(session().httpListenerStarts, isEmpty);
      expect(container.read(deskProvider).settings.directHttp, isFalse);
      expect(session().listenerStarts, 1, reason: 'Epicbox starts with the wallet by default');
      await desk.lock();
      expect(await wallet.unlock(_password), isTrue);
      final own0 = await wallet.settings();
      await wallet.saveSettings(own0.copyWith(payments: own0.payments.copyWith(linkHttp: true), epicboxAutostart: false));
      await desk.startLive();
      expect(session().httpListenerStarts.single.exposure, core.HttpExposure.localOnly);
      expect(container.read(deskProvider).settings.directHttp, isTrue);
      expect(session().listenerStarts, 1, reason: 'Epicbox stayed off this time');
      await desk.lock();
    });
  });

  group('send failures and reposts', () {
    const to = 'https://wallet.example.org';
    const waits = 'The payment waits in Activity; cancel it there to free the coins.';

    test('an error after the send was stored leaves it in Activity, whatever its kind', () async {
      session()
        ..storeBeforeError = true
        ..sendError = const core.WalletError(kind: core.WalletErrorKind.nodeUnreachable, message: 'finalize failed');
      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: to));
      expect((r as SendFailed).inActivity, isTrue);
      expect(r.message, 'Node not answering. $waits');
      expect((await wallet.transactions()).where((t) => t.state == TxState.waitingRecipient), hasLength(1));
    });

    test('an error that stored nothing is not in Activity', () async {
      session().sendError = const core.WalletError(kind: core.WalletErrorKind.notEnoughFunds, message: 'short');
      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: to));
      expect((r as SendFailed).inActivity, isFalse);
      expect(r.message, isNot(contains('Activity')));
      expect((await wallet.transactions()).where((t) => !t.incoming), isEmpty);
    });

    test('no answer reads as one sentence', () async {
      session().sendError = const core.WalletError(kind: core.WalletErrorKind.transportFailed, message: 'refused');
      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: to));
      expect((r as SendFailed).message, startsWith('The recipient’s wallet did not answer or refused. '));
    });

    test('a node that did not take the payment gets it again once', () async {
      session().httpPosted = false;
      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: to));
      expect(r, isA<SendDone>(), reason: r is SendFailed ? r.message : '');
      expect(session().repostedKeys, hasLength(1));
    });

    test('still refused: the funds stay locked and Activity can cancel it', () async {
      session()
        ..httpPosted = false
        ..repostFailures = 3;
      final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: to));
      expect((r as SendFailed).message, 'Signed by both wallets, but the node refused it. Cancel it in Activity to free the coins.');
      expect(r.inActivity, isTrue);
      expect(session().repostFailures, 2, reason: 'tried once');
      expect(session().repostedKeys, isEmpty);
    });

    test('plain http asks on each send', () async {
      const plain = 'http://203.0.113.5:3415';
      for (var i = 0; i < 2; i++) {
        final r = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: plain));
        expect((r as SendFailed).message, 'Plain HTTP not confirmed');
      }
      expect(await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: plain, allowPlainHttp: true)), isA<SendDone>());
      final again = await wallet.send(const SendRequest(method: TxMethod.http, amount: 1000, to: plain));
      expect((again as SendFailed).message, 'Plain HTTP not confirmed', reason: 'consent is not remembered');
      expect(session().httpSends, hasLength(1));
    });
  });

  group('own HTTP settings per wallet', () {
    Future<ProviderContainer> live() async {
      final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
      addTearDown(container.dispose);
      return container;
    }

    test('a second wallet does not inherit the first one’s reach or port; Link · HTTP is the app’s switch', () async {
      final main0 = await wallet.settings();
      await wallet.saveSettings(main0.copyWith(publicMode: true, httpPort: 3420, payments: main0.payments.copyWith(linkHttp: true)));
      await wallet.createWallet(name: 'Savings', password: _password);
      await wallet.lock();
      final all = await wallet.wallets();
      await wallet.selectWallet(all.firstWhere((w) => w.name == 'Savings').id);
      expect(await wallet.unlock(_password), isTrue);
      final desk = (await live()).read(deskProvider.notifier);
      await desk.startLive(listen: false);
      // Link · HTTP is the app's switch: Savings starts the listener too, on its own reach and port.
      expect(session().httpListenerStarts.single, (exposure: core.HttpExposure.localOnly, port: 3415));
      final own = await wallet.settings();
      expect((own.publicMode, own.httpPort, own.payments.linkHttp), (false, 3415, true));

      // Savings keeps its own reach and port, apart from the first wallet.
      await wallet.saveSettings(own.copyWith(httpPort: 3500));
      await wallet.lock();
      await wallet.selectWallet(all.firstWhere((w) => w.name == 'Main').id);
      expect(await wallet.unlock(_password), isTrue);
      var first = await wallet.settings();
      expect((first.publicMode, first.httpPort, first.payments.linkHttp), (true, 3420, true));
      await desk.startLive(listen: false);
      expect(session().httpListenerStarts.last, (exposure: core.HttpExposure.internet, port: 3420));
      await wallet.lock();
      await wallet.selectWallet(all.firstWhere((w) => w.name == 'Savings').id);
      expect(await wallet.unlock(_password), isTrue);
      first = await wallet.settings();
      expect((first.publicMode, first.httpPort, first.payments.linkHttp), (false, 3500, true));
    });

    test('a reopen on another node restarts HTTP with the same reach', () async {
      await wallet.saveSettings((await wallet.settings()).let((s) => s.copyWith(payments: s.payments.copyWith(linkHttp: true), publicMode: true, httpPort: 3420)));
      await wallet.setHttpListening(true);
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3420));
      await pumpEventQueue();
      await wallet.useNode('https://node.example.org');
      expect(session().httpListenerStarts, hasLength(2));
      expect(session().httpListenerStarts.last, (exposure: core.HttpExposure.internet, port: 3420));
    });
  });

  group('public address', () {
    test('asked only From the internet with the listener on (Tor: tor_direct_test)', () async {
      await wallet.saveSettings(const DeskSettings(payments: PaymentPrefs(linkHttp: true)));
      await wallet.setHttpListening(true);
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3415));
      await pumpEventQueue();
      expect(await wallet.httpReach(), isNull);
      expect(await wallet.httpAddress(), 'http://127.0.0.1:3415');
      expect(probe.asked, 0, reason: 'Local only asks nothing of the internet');

      await wallet.saveSettings(const DeskSettings(payments: PaymentPrefs(linkHttp: true), publicMode: true));
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3415));
      await pumpEventQueue();
      expect((await wallet.httpReach())?.reachable, isFalse);
      expect(probe.asked, 1);
      await wallet.httpAddress();
      expect(probe.asked, 1, reason: 'kept, not asked again');
      await wallet.httpReach(recheck: true);
      expect(probe.asked, 2);

    });
  });

  group('lanAddress', () {
    List<({String name, List<InternetAddress> addresses})> nics(Map<String, String> byName) => [
      for (final e in byName.entries) (name: e.key, addresses: [InternetAddress(e.value)]),
    ];

    test('prefers a private address and skips containers, bridges and tunnels', () async {
      final a = await lanAddress(
        list: () async => nics({
          'docker0': '172.17.0.1',
          'br-1f2e': '172.18.0.1',
          'virbr0': '10.0.122.1',
          'veth9': '172.19.0.2',
          'tun0': '10.8.0.2',
          'wg0': '10.9.0.2',
          'tailscale0': '10.64.0.5',
          'wlp3s0': '203.0.113.9',
          'enp2s0': '10.0.1.24',
        }),
      );
      expect(a, '10.0.1.24');
    });

    test('windows-04: a VPN adapter listed first does not beat the Ethernet address', () async {
      expect(await lanAddress(list: () async => nics({'NordLynx': '10.5.0.2', 'Ethernet': '10.0.0.57'})), '10.0.0.57');
      expect(await lanAddress(list: () async => nics({'OpenVPN TAP-Windows': '10.8.0.6', 'Wi-Fi': '172.20.1.5'})), '172.20.1.5');
      expect(await lanAddress(list: () async => nics({'Unknown1': '10.0.0.4', 'Unknown2': '10.0.0.9'})), '10.0.0.9');
    });

    test('a public address only when no private one is left; none with only virtual ones', () async {
      expect(await lanAddress(list: () async => nics({'docker0': '172.17.0.1', 'eth0': '203.0.113.9'})), '203.0.113.9');
      expect(await lanAddress(list: () async => nics({'docker0': '172.17.0.1', 'utun3': '10.0.0.2', 'zt0': '10.1.0.2'})), isNull);
      expect(await lanAddress(list: () async => nics({'lo': '127.0.0.1', 'eth0': '169.254.1.2'})), isNull);
    });
  });
}


extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
