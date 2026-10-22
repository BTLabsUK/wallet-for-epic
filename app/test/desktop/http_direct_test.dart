// Direct HTTP on the desktop: LepicDeskWallet over FakeWalletSession, which records each
// sendHttp and startHttpListener call. The password is a throwaway test value.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/http_address.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

void main() {
  late Directory support;
  late core.FakeWalletService service;
  late LepicDeskWallet wallet;
  core.FakeWalletSession session() => service.session;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-http-test-');
    service = core.FakeWalletService(password: _password);
    wallet = LepicDeskWallet(
      service: service,
      walletDir: (chain) async {
        final dir = Directory('${support.path}/wallets/${chain.name}');
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
      minimumConfirmations: BigInt.from(10),
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
    });

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

      await wallet.saveSettings(const DeskSettings(directHttp: true));
      await wallet.setHttpListening(true);
      expect(session().httpListenerStarts.single, (exposure: core.HttpExposure.localOnly, port: 3415));
      expect((await wallet.status()).httpListener, ServiceHealth.checking);
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3415));
      await pumpEventQueue();
      expect((await wallet.status()).httpListener, ServiceHealth.ok);
      expect(await wallet.httpAddress(), 'http://127.0.0.1:3415');

      await wallet.saveSettings(const DeskSettings(directHttp: true, publicMode: true, httpPort: 3420));
      expect(session().httpListenerStops, 1);
      expect(session().httpListenerStarts.last, (exposure: core.HttpExposure.internet, port: 3420));
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.started, port: 3420));
      await pumpEventQueue();
      final lan = await lanAddress();
      expect(await wallet.httpAddress(), lan == null ? '' : 'http://$lan:3420');
      expect(await wallet.httpAddress(), isNot(contains('127.0.0.1')));

      // Stop receiving stops HTTP too; Start listener brings it back while the switch is on.
      await wallet.setListening(false);
      expect(session().httpListenerStops, 2);
      expect((await wallet.status()).httpListener, ServiceHealth.off);
      await wallet.setListening(true);
      expect(session().httpListenerStarts, hasLength(3));
    });

    test('a port in use becomes the status text; Try again starts it again', () async {
      await wallet.saveSettings(const DeskSettings(directHttp: true));
      await wallet.setHttpListening(true);
      session().httpListenerEvents.add(const core.HttpListenerEvent(kind: core.HttpListenerEventKind.portInUse, port: 3415));
      await pumpEventQueue();
      final st = await wallet.status();
      expect(st.httpListener, ServiceHealth.down);
      expect(st.httpProblem, 'Port 3415 in use');
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

    test('unlock starts it only with Start with the wallet', () async {
      final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
      addTearDown(container.dispose);
      final desk = container.read(deskProvider.notifier);
      await desk.startLive(listen: true);
      expect(session().httpListenerStarts, isEmpty);
      expect(container.read(deskProvider).settings.directHttp, isFalse);
      await desk.lock();
      expect(await wallet.unlock(_password), isTrue);
      await desk.startLive(listen: false, http: true);
      expect(session().httpListenerStarts.single.exposure, core.HttpExposure.localOnly);
      expect(container.read(deskProvider).settings.directHttp, isTrue);
      expect(session().listenerStarts, 1, reason: 'Epicbox stayed off this time');
      await desk.lock();
    });
  });
}
