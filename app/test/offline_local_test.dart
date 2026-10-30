// SPDX-License-Identifier: Apache-2.0
// Local addresses (net/local_address.dart): the classifier at every range edge, the lookup
// once, and the LEPIC adapter per network mode (Node only: the node and files; Kill switch:
// files only). No native library is loaded and no lookup reaches a resolver.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart' show deskErrorText;
import 'package:epic_wallet/src/errors.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/net/local_address.dart';
import 'package:epic_wallet/src/net/node_peers.dart';
import 'package:epic_wallet/src/net/tor_net.dart';
import 'package:epic_wallet/src/models.dart' show HttpExposure;
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

/// Fails any native call but the two it stands in for, recording where a Link send went.
class _Wallet implements lepic.EpicWallet {
  final List<String> sentTo = [];
  int slates = 0;

  @override
  bool get isDisposed => false;

  @override
  Future<lepic.Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    lepic.SendOptions? options,
  }) async {
    slates++;
    return const lepic.Slate(txId: 5, slateId: 'sent-1', json: '{}');
  }

  @override
  Future<lepic.HttpSentTx> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
    required bool allowPlainHttp,
    String? message,
    lepic.SendOptions? options,
  }) async {
    sentTo.add(url);
    return lepic.HttpSentTx(txId: 5, slateId: 'sent-1', amount: amount, fee: BigInt.one, posted: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('reached LEPIC: ${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    NetGate.set(NetworkMode.standard);
    TorNet.useDirect();
  });

  group('hostKind: literal addresses, no lookup', () {
    void kind(String host, HostKind want) => expect(hostKind(host), want, reason: host);

    test('IPv4 loopback and private ranges, at their edges', () {
      for (final h in ['127.0.0.1', '127.255.255.255', '127.0.0.0']) {
        kind(h, HostKind.local);
      }
      for (final h in ['10.0.0.0', '10.255.255.255', '172.16.0.0', '172.31.255.255', '10.0.0.0', '10.0.255.255', '169.254.0.0', '169.254.255.255']) {
        kind(h, HostKind.local);
      }
      for (final h in ['126.255.255.255', '128.0.0.0', '9.255.255.255', '11.0.0.0', '172.15.255.255', '172.32.0.0', '192.167.255.255', '192.169.0.0', '169.253.255.255', '169.255.0.0', '0.0.0.0', '255.255.255.255', '8.8.8.8', '100.63.255.255']) {
        kind(h, HostKind.public);
      }
    });

    test('IPv6 loopback, ULA fc00::/7 and link-local fe80::/10, at their edges', () {
      for (final h in ['::1', '[::1]', 'fc00::', 'fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', 'fe80::', 'febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff', 'fe80::1%eth0', '[fe80::1%25eth0]']) {
        kind(h, HostKind.local);
      }
      for (final h in ['::', '::2', 'fbff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', 'fe00::', 'fec0::', '2001:db8::1', '2606:4700::1111']) {
        kind(h, HostKind.public);
      }
    });

    test('IPv4-mapped IPv6 is judged as the IPv4 address', () {
      kind('::ffff:10.100.10.20', HostKind.local);
      kind('::ffff:127.0.0.1', HostKind.local);
      kind('[::ffff:c0a8:114]', HostKind.local);
      kind('::ffff:8.8.8.8', HostKind.public);
      kind('::ffff:172.32.0.1', HostKind.public);
    });

    test('localhost is local; an onion is an onion; anything else is a name', () {
      kind('localhost', HostKind.local);
      kind('LocalHost.', HostKind.local);
      kind('abcdefghijklmnopqrstuvwxyz234567abcdefghijklmnopqrstuvwx.onion', HostKind.onion);
      kind('wallet.onion.', HostKind.onion);
      for (final h in ['node.btlabs.uk', 'mynode.lan', 'localhost.example.com', '127.1', '2130706433', '0x7f.0.0.1', '']) {
        kind(h, HostKind.name);
      }
    });

    test('isLocalAddressUrl: literal local hosts only, never a name', () {
      expect(isLocalAddressUrl('http://10.100.10.20:3413'), isTrue);
      expect(isLocalAddressUrl('http://127.0.0.1:3413'), isTrue);
      expect(isLocalAddressUrl('http://[::1]:3413'), isTrue);
      expect(isLocalAddressUrl('http://localhost:3413'), isTrue);
      expect(isLocalAddressUrl('https://node.btlabs.uk'), isFalse);
      expect(isLocalAddressUrl('http://mynode.lan:3413'), isFalse);
      expect(isLocalAddressUrl('http://8.8.8.8:3413'), isFalse);
      expect(isLocalAddressUrl(null), isFalse);
      expect(isLocalAddressUrl('not a url'), isFalse);
    });
  });

  group('resolveLocal: a name is looked up once', () {
    test('a literal address and localhost are never looked up', () async {
      Future<List<String>> never(String h) async => fail('looked up $h');
      expect(await resolveLocal('10.100.10.20', never), '10.100.10.20');
      expect(await resolveLocal('localhost', never), 'localhost');
      expect(await resolveLocal('8.8.8.8', never), isNull);
      expect(await resolveLocal('abc.onion', never), isNull);
    });

    test('all local: the first address; any public, none or a failure: refused', () async {
      final asked = <String>[];
      Future<List<String>> Function(String) answer(List<String> found) => (h) async {
        asked.add(h);
        return found;
      };
      expect(await resolveLocal('pc.lan', answer(['10.100.10.20', 'fe80::1'])), '10.100.10.20');
      expect(await resolveLocal('pc.lan', answer(['10.100.10.20', '203.0.113.5'])), isNull);
      expect(await resolveLocal('pc.lan', answer(['203.0.113.5'])), isNull);
      expect(await resolveLocal('pc.lan', answer([])), isNull);
      expect(await resolveLocal('pc.lan', (_) async => throw const SocketException('no')), isNull);
      expect(asked, List.filled(4, 'pc.lan'));
    });

    test('localUrl connects to the address found, keeping the rest of the URL', () async {
      expect(await localUrl('http://pc.lan:3415/v2/foreign', (_) async => ['10.100.10.20']), 'http://10.100.10.20:3415/v2/foreign');
      expect(await localUrl('http://pc.lan:3415', (_) async => ['fd00::5']), 'http://[fd00::5]:3415');
      expect(await localUrl('http://10.100.10.20:3415', (_) async => fail('looked up')), 'http://10.100.10.20:3415');
      expect(await localUrl('http://pc.lan:3415', (_) async => ['10.100.10.20', '8.8.8.8']), isNull);
      expect(await localUrl('https://wallet.example.org', (_) async => ['203.0.113.5']), isNull);
      expect(await localUrl('ftp://10.100.10.20', (_) async => []), isNull);
    });
  });

  group('the gate', () {
    test('Node only lets node actions and files run on any node; the rest is held', () {
      for (final t in TorState.values) {
        expect(netBlockFor(NetworkMode.nodeOnly, t, node: true), NetBlock.none);
        expect(netBlockFor(NetworkMode.nodeOnly, t), NetBlock.nodeOnly);
      }
      expect(nodeOnlyUsesNode(NetworkMode.nodeOnly, localNode: true), isFalse);
      expect(nodeOnlyUsesNode(NetworkMode.nodeOnly, localNode: false), isTrue);
      expect(netBlockFor(NetworkMode.torOnly, TorState.starting, node: true), NetBlock.waitingForTor);
    });

    test('NetGate.checkNode lets the node through in Node only, not in Kill switch', () {
      NetGate.set(NetworkMode.nodeOnly);
      expect(() => NetGate.checkNode('x'), returnsNormally);
      expect(() => NetGate.check('x'), throwsA(isA<NetBlocked>()));
      NetGate.set(NetworkMode.killSwitch);
      expect(() => NetGate.checkNode('x'), throwsA(isA<NetBlocked>()));
    });

    test('a refusal by the mode reads as the mode, phone and desktop', () {
      const e = NetBlocked(NetworkMode.killSwitch, 'send over HTTP');
      expect(describeError(englishStrings, e), englishStrings.netBlockKillSwitch);
      expect(deskErrorText(e), englishStrings.deskShellOffline);
      const t = NetBlocked(NetworkMode.torOnly, 'send over HTTP');
      expect(describeError(englishStrings, t), englishStrings.advModeTorOnlyLine);
    });
  });

  group('the LEPIC adapter by mode', () {
    late _Wallet wallet;
    late LepicWalletSession session;

    setUp(() {
      wallet = _Wallet();
      session = LepicWalletSession(wallet);
    });

    Future<String> send(String url) async {
      await session.sendHttp(amount: BigInt.from(10), minimumConfirmations: BigInt.from(3), url: url, allowPlainHttp: true);
      return wallet.sentTo.last;
    }

    test('Node only: a file is made; Link, Epicbox and Tor are refused before LEPIC', () async {
      NetGate.set(NetworkMode.nodeOnly);
      session.nodeUrl = 'https://node.btlabs.uk';
      await session.createSendSlate(amount: BigInt.from(10), minimumConfirmations: BigInt.from(3));
      expect(wallet.slates, 1);
      await expectLater(send('http://10.0.1.30:3415'), throwsA(isA<NetBlocked>()));
      await expectLater(
        session.sendEpicbox(amount: BigInt.from(10), minimumConfirmations: BigInt.from(3), address: 'esX@epicbox.epiccash.com'),
        throwsA(isA<NetBlocked>()),
      );
      await expectLater(session.startListener().drain<void>(), throwsA(isA<NetBlocked>()));
      await expectLater(session.startHttpListener(exposure: HttpExposure.localOnly, port: 3415).drain<void>(), throwsA(isA<NetBlocked>()));
      expect(wallet.sentTo, isEmpty);
    });

    test('Kill switch: a file is made without a node; a refresh, a scan and tor are refused', () async {
      NetGate.set(NetworkMode.killSwitch);
      session.nodeUrl = 'http://127.0.0.1:3413';
      await session.createSendSlate(amount: BigInt.from(10), minimumConfirmations: BigInt.from(3));
      expect(wallet.slates, 1);
      await expectLater(session.summary(refresh: true, minimumConfirmations: BigInt.from(3)), throwsA(isA<NetBlocked>()));
      await expectLater(session.scan().drain<void>(), throwsA(isA<NetBlocked>()));
      await expectLater(session.startTor(torBinary: '/x').drain<void>(), throwsA(isA<NetBlocked>()));
      await expectLater(session.postFinished('{}'), throwsA(isA<NetBlocked>()));
    });

    test('Standard leaves a Link address as given', () async {
      NetGate.set(NetworkMode.standard);
      session.nodeUrl = 'https://node.btlabs.uk';
      expect(await send('https://wallet.example.org'), 'https://wallet.example.org');
    });

    test('the Epicbox switch off, in Standard: Epicbox sends and the listener are refused before LEPIC; files and Link go on', () async {
      addTearDown(() => NetGate.setEpicbox(true));
      NetGate.set(NetworkMode.standard);
      NetGate.setEpicbox(false);
      session.nodeUrl = 'https://node.btlabs.uk';
      await expectLater(
        session.sendEpicbox(amount: BigInt.from(10), minimumConfirmations: BigInt.from(3), address: 'esX@epicbox.epiccash.com'),
        throwsA(isA<NetBlocked>().having((e) => e.epicboxOff, 'epicboxOff', isTrue)),
      );
      await expectLater(session.startListener().drain<void>(), throwsA(isA<NetBlocked>().having((e) => e.epicboxOff, 'epicboxOff', isTrue)));
      await session.createSendSlate(amount: BigInt.from(10), minimumConfirmations: BigInt.from(3));
      expect(wallet.slates, 1);
      expect(await send('https://wallet.example.org'), 'https://wallet.example.org');
    });
  });

  group('nodePeerCount', () {
    test('reads connections from owner get_status; null when it does not say', () async {
      Uri? asked;
      Map<String, Object?>? sent;
      Future<HttpReply> Function(Uri, List<int>) reply(int status, Object body) => (u, b) async {
        asked = u;
        sent = jsonDecode(utf8.decode(b)) as Map<String, Object?>;
        return HttpReply(status, jsonEncode(body));
      };
      expect(await nodePeerCount('http://10.100.10.20:3413/', post: reply(200, {'result': {'Ok': {'connections': 0}}})), 0);
      expect(asked.toString(), 'http://10.100.10.20:3413/v2/owner');
      expect(sent?['method'], 'get_status');
      expect(await nodePeerCount('http://127.0.0.1:3413', post: reply(200, {'result': {'Ok': {'connections': 8}}})), 8);
      expect(await nodePeerCount('http://127.0.0.1:3413', post: reply(401, {})), isNull);
      expect(await nodePeerCount('http://127.0.0.1:3413', post: reply(200, {'result': {'Err': 'x'}})), isNull);
      expect(await nodePeerCount('http://127.0.0.1:3413', post: (_, _) async => throw const NetError('down')), isNull);
    });
  });
}
