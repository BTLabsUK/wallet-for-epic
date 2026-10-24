// Offline = nothing beyond this computer and the local network (net/local_address.dart): the
// classifier at every range edge, the gate's local-node input, and the LEPIC adapter letting a
// local node and Link sends to local addresses through while refusing the rest. No native
// library is loaded and no lookup reaches a resolver: [LepicWalletSession.directLookup] is
// replaced.
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
    test('Offline with a local node: node actions and files run; without one, as before', () {
      for (final t in TorState.values) {
        expect(netBlockFor(NetworkMode.offline, t, localNode: true), NetBlock.none);
        expect(netBlockFor(NetworkMode.offline, t), NetBlock.offline);
      }
      expect(fileBlockFor(NetworkMode.offline, localNode: true), NetBlock.none);
      expect(fileBlockFor(NetworkMode.offline), NetBlock.offline);
      expect(netBlockFor(NetworkMode.torOnly, TorState.starting, localNode: true), NetBlock.waitingForTor);
    });

    test('NetGate.check and TorNet.configure let a local call through in Offline', () {
      NetGate.set(NetworkMode.offline);
      expect(() => NetGate.check('x', local: true), returnsNormally);
      expect(() => NetGate.check('x'), throwsA(isA<NetBlocked>()));
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      TorNet.configure(client, local: true);
      expect(() => TorNet.configure(client), throwsA(isA<NetError>()));
    });

    test('the refusal of a non-local Link address says so, phone and desktop', () {
      const e = NetBlocked(NetworkMode.offline, 'send over HTTP', notLocal: true);
      expect(describeError(englishStrings, e), 'Offline: only local addresses.');
      expect(deskErrorText(e), 'Offline: only local addresses.');
    });
  });

  group('the LEPIC adapter in Offline', () {
    late _Wallet wallet;
    late LepicWalletSession session;
    final lookups = <String>[];
    var answer = <String>[];

    setUp(() {
      wallet = _Wallet();
      session = LepicWalletSession(wallet);
      lookups.clear();
      answer = [];
      LepicWalletSession.directLookup = (h) async {
        lookups.add(h);
        return answer;
      };
      NetGate.set(NetworkMode.offline);
    });

    Future<String> send(String url) async {
      await session.sendHttp(amount: BigInt.from(10), minimumConfirmations: BigInt.from(3), url: url, allowPlainHttp: true);
      return wallet.sentTo.last;
    }

    test('a public node: files and Link are refused before LEPIC, as before', () async {
      session.nodeUrl = 'https://node.btlabs.uk';
      await expectLater(session.createSendSlate(amount: BigInt.from(10), minimumConfirmations: BigInt.from(3)), throwsA(isA<NetBlocked>()));
      await expectLater(send('http://10.0.1.30:3415'), throwsA(isA<NetBlocked>().having((e) => e.notLocal, 'notLocal', isFalse)));
      await expectLater(session.summary(refresh: true, minimumConfirmations: BigInt.from(3)), throwsA(isA<NetBlocked>()));
      expect(wallet.slates, 0);
      expect(wallet.sentTo, isEmpty);
    });

    for (final node in ['http://127.0.0.1:3413', 'http://10.100.10.20:3413']) {
      test('a local node ($node): a file is made, Link goes to a local address only', () async {
        session.nodeUrl = node;
        await session.createSendSlate(amount: BigInt.from(10), minimumConfirmations: BigInt.from(3));
        expect(wallet.slates, 1);
        expect(await send('http://10.0.1.30:3415'), 'http://10.0.1.30:3415');
        expect(lookups, isEmpty, reason: 'a literal address is not looked up');
        await expectLater(send('https://203.0.113.5:3415'), throwsA(isA<NetBlocked>().having((e) => e.notLocal, 'notLocal', isTrue)));
        answer = ['10.0.1.31', '203.0.113.5'];
        await expectLater(send('http://pc.lan:3415'), throwsA(isA<NetBlocked>().having((e) => e.notLocal, 'notLocal', isTrue)));
        answer = ['10.0.1.31'];
        expect(await send('http://pc.lan:3415'), 'http://10.0.1.31:3415', reason: 'LEPIC connects to the address found');
        expect(lookups, ['pc.lan', 'pc.lan']);
        expect(wallet.sentTo, hasLength(2));
      });
    }

    test('Epicbox and Tor stay refused with a local node', () async {
      session.nodeUrl = 'http://10.100.10.20:3413';
      await expectLater(
        session.sendEpicbox(amount: BigInt.from(10), minimumConfirmations: BigInt.from(3), address: 'esX@epicbox.epiccash.com'),
        throwsA(isA<NetBlocked>()),
      );
      await expectLater(session.startTor(torBinary: '/x').drain<void>(), throwsA(isA<NetBlocked>()));
    });

    test('Standard leaves a Link address as given', () async {
      NetGate.set(NetworkMode.standard);
      session.nodeUrl = 'https://node.btlabs.uk';
      expect(await send('https://wallet.example.org'), 'https://wallet.example.org');
      expect(lookups, isEmpty);
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
