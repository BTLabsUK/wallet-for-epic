// The SOCKS5 client and TorNet: names go to tor as names (address type 3), every request
// goes through the proxy while Tor is on, none goes out while it is not connected, and plain
// http never leaves through an exit.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/net/socks.dart';
import 'package:epic_wallet/src/net/tor_net.dart';
import 'package:flutter_test/flutter_test.dart';

/// A SOCKS5 proxy on this computer that records each CONNECT and forwards it to [targets]
/// (requested host → local port).
class _FakeSocks {
  _FakeSocks._(this._server, this.targets) {
    _server.listen(_serve);
  }

  static Future<_FakeSocks> start(Map<String, int> targets) async =>
      _FakeSocks._(await ServerSocket.bind(InternetAddress.loopbackIPv4, 0), targets);

  final ServerSocket _server;
  final Map<String, int> targets;
  final List<({int atyp, String host, int port, String user})> connects = [];
  int accepted = 0;

  SocksProxy get proxy => SocksProxy('127.0.0.1', _server.port);

  Future<void> close() => _server.close();

  Future<void> _serve(Socket client) async {
    accepted++;
    final buf = <int>[];
    final more = StreamController<void>.broadcast();
    Socket? upstream;
    client.listen((d) {
      if (upstream != null) {
        upstream.add(d);
      } else {
        buf.addAll(d);
        more.add(null);
      }
    }, onDone: () => upstream?.destroy(), onError: (_) {});
    Future<List<int>> take(int n) async {
      while (buf.length < n) {
        await more.stream.first;
      }
      final out = buf.sublist(0, n);
      buf.removeRange(0, n);
      return out;
    }

    final greet = await take(2);
    await take(greet[1]);
    client.add([5, 2]);
    final auth = await take(2);
    final user = utf8.decode(await take(auth[1]));
    final passLen = (await take(1))[0];
    await take(passLen);
    client.add([1, 0]);
    final head = await take(4);
    final atyp = head[3];
    final host = atyp == 3 ? utf8.decode(await take((await take(1))[0])) : '';
    if (atyp == 1) await take(4);
    final p = await take(2);
    final port = p[0] << 8 | p[1];
    connects.add((atyp: atyp, host: host, port: port, user: user));
    final to = targets[host];
    if (to == null) {
      client.add([5, 4, 0, 1, 0, 0, 0, 0, 0, 0]);
      await client.close();
      return;
    }
    final up = await Socket.connect(InternetAddress.loopbackIPv4, to);
    client.add([5, 0, 0, 1, 127, 0, 0, 1, 0, 0]);
    upstream = up;
    if (buf.isNotEmpty) up.add(Uint8List.fromList(buf));
    up.listen(client.add, onDone: () => client.destroy(), onError: (_) {});
  }
}

const _cert = """-----BEGIN CERTIFICATE-----
MIIDNDCCAhygAwIBAgIUCmbARxfqOWb/0eiVT5JCgcjM9f4wDQYJKoZIhvcNAQEL
BQAwGzEZMBcGA1UEAwwQc3RhdHVzLmJ0bGFicy51azAeFw0yNjEwMjMxNDI5Mzla
Fw0zNjEwMjAxNDI5MzlaMBsxGTAXBgNVBAMMEHN0YXR1cy5idGxhYnMudWswggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC1cip4Tgx/7oe6GNysDUwrg+nF
6var156ypcFRAiUY+B8+GHpihH2vUOS7YqnGLTP1dIDAiYpHN270fTFPHlx559lA
1IMmCGc+vwle20zO2eOUieFl4Oh+EGWBdJthBub8wSbCJjhgUKVogOjkPGnd5MFn
JiXYyQ0NsncDrTR7eutpe0nxhLNK8yX9SRuMwTBrgQCkmGT4B8LBmlByiT+oiZJD
KoCchd7iMMI0ouj7/tp2V1NZ18dNo5f63E3ZkZ1VETTK/cxf2UO4ltpDenYemJij
kX1BocuJQMPGcKXl776P7ACz/k5tb7mkKPnIJ9WyXCha5iDXVAgD2FkBJiHxAgMB
AAGjcDBuMB0GA1UdDgQWBBTICcsrQK7w1ccRJNzTGtff5OacOTAfBgNVHSMEGDAW
gBTICcsrQK7w1ccRJNzTGtff5OacOTAPBgNVHRMBAf8EBTADAQH/MBsGA1UdEQQU
MBKCEHN0YXR1cy5idGxhYnMudWswDQYJKoZIhvcNAQELBQADggEBAHQFYU5gf/WQ
5AK3W2ExlFwl0vXtfGLWUp7fGI2waHbhR0yakpvGzuxWYrIFHglEwr4diZ8wynRf
Vtd4YrGGl4Kx5ipkKVBl4ehOPoi4mFpzKcx88gYQ06UByBWFhdMYqSzIcv6U5uek
wxILooZY+5AjSfF/wEsFe2EdwrMfvyfbEamQ9ZyEd5xghiRu80SvQ3NmP/cI/UeB
rqJAQEvOFzkik/PwCwQp6cP9wtT1B8XPq1useAEWSASM2+LrFUpVXOJKRsUnhQ1q
CMKGtfuuFgT7DfqbByqvYEQxi2eDJy2/LjudhTyU9bGm05LzrKaWvM7q29VKKmKK
1Aonc9naYSY=
-----END CERTIFICATE-----""";
const _key = """-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC1cip4Tgx/7oe6
GNysDUwrg+nF6var156ypcFRAiUY+B8+GHpihH2vUOS7YqnGLTP1dIDAiYpHN270
fTFPHlx559lA1IMmCGc+vwle20zO2eOUieFl4Oh+EGWBdJthBub8wSbCJjhgUKVo
gOjkPGnd5MFnJiXYyQ0NsncDrTR7eutpe0nxhLNK8yX9SRuMwTBrgQCkmGT4B8LB
mlByiT+oiZJDKoCchd7iMMI0ouj7/tp2V1NZ18dNo5f63E3ZkZ1VETTK/cxf2UO4
ltpDenYemJijkX1BocuJQMPGcKXl776P7ACz/k5tb7mkKPnIJ9WyXCha5iDXVAgD
2FkBJiHxAgMBAAECggEADWGvbX1JbAtKH0NuIueS0ogWru4L5dMvymUcbhOxFg0B
NjHVSia9+OFdEnoi+JFPillelX859NP1xDo8xLpXKkvFuK5I7dPOKXvVU8BAreYL
5AyMfwL999jQY6JsmH9LJyDnnDH4E8Je2zzb8C6JxZT1XodwYHM+GeCA6S3WTQo9
P4xei8EShF1e71rUDzOPgM33tFSL8VHnWgNcO4uK1/7ALu4XPZZAVSXaeqgZkWWa
n1Ws3U+7dG8k4y9Ru8UfRt1SVUwE+4jP+neV9izxtXZKPhYki6vLqCjEobtTh1Tn
wtgkpZIGQRhmSVpMvorhz0x8XhsI+t1uDrb16UPJQQKBgQDaKTfU25upTx5Yh1aj
SvO7AMVXUnObms4I1FYHQuz4BLTGHpIfLE8LaJjpcqr7Rb/QXwCY/qKUJXeu8rVD
qauRovqyAGVdop6UOif44ERORGVOMHsIY68+4CFnWQBh8z01Pgdr6rGS893oaSWC
IHAJ4nqv9HtW/aeZWzpgdDXbdQKBgQDU6roPUIuzC02Z3oN8LMcZzXQYf1PgSaLq
YIRuiBwwSfzmiWRJ8E/LdL7rcfW6OIPAmI8SnX0xPcj4qCsEO4qASoa7/ydjrOQz
c5SjyJw1bOEsssRlqHgzC52o2RESlaq+3RdiaeQU7WNhssFTc+bzvQtvyc/lJoXA
/qZXc+tpDQKBgBqHAov2fDIVNcpsAoPunD5z9IsOspIMO9tk/mT5pVjvMZAZrYju
2Vm4yUcxs0rEi3Np6eewptI+0BPM3W+x1PPrjnJQjALbwE6j17Jyiru9o1fjm0JE
5M1PcaBgeSRv8FRmC3761cbZsnUNPAtbqGP7TxHQN6M3SsbiCfIqj1X1AoGBAKfb
9pwkUD7z5lYsy1SWqNF63NCDcckdxMcrGL1bqX2Ylz3Zi6uPPhmVDP/qdGRAMf8h
R4rRhuXPZCZFzsQjfOnv15FXc+JtZ+v4b3NAsYadNFldBuFulHUJ714y4/bW8CpR
fCImgZ7OGM/pcektMyNuIxoa7UAnwsOI//NqfGnxAoGALtDUG5h35v2ch34XBLiy
3g4/XyhTTiuJuW6xafKtgNO7C/HLut4fEhXSBfyYomqJKbNFYu3EkPaWE830wXU2
qp3CeaZVxctr7Xy26nG8DlduwYmFdUAoU6qaZiRgNYU8w5Au0g2aNjXfW91eQ9lO
8ZfB6DolWUnykCpKVHya0W8=
-----END PRIVATE KEY-----""";

void main() {
  late HttpServer web;
  late List<HttpHeaders> seen;

  setUp(() async {
    seen = [];
    web = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    web.listen((r) {
      seen.add(r.headers);
      r.response.write('{"ok":true}');
      r.response.close();
    });
  });

  tearDown(() async {
    TorNet.useDirect();
    TorNet.onions = null;
    await web.close(force: true);
  });

  test('a BT Labs host goes to its onion as a name, with no User-Agent', () async {
    final socks = await _FakeSocks.start({'abcdefghij.onion': web.port});
    addTearDown(socks.close);
    TorNet.useTor(socks.proxy);
    TorNet.onions = (host, port) => host == 'status.btlabs.uk' ? (onion: 'abcdefghij.onion', port: 80, tls: false) : null;
    final reply = await httpGet(Uri.https('status.btlabs.uk', '/api/v1/price.json'));
    expect(reply.status, 200);
    expect(reply.body, '{"ok":true}');
    expect(socks.connects.single.atyp, 3, reason: 'a name, never an address looked up here');
    expect(socks.connects.single.host, 'abcdefghij.onion');
    expect(socks.connects.single.port, 80);
    expect(seen.single.value(HttpHeaders.hostHeader), 'status.btlabs.uk');
    expect(seen.single.value(HttpHeaders.userAgentHeader), isNull);
    expect(seen.single.value(HttpHeaders.acceptLanguageHeader), isNull);
  });

  test('fresh credentials per connection', () async {
    final socks = await _FakeSocks.start({'abcdefghij.onion': web.port});
    addTearDown(socks.close);
    TorNet.useTor(socks.proxy);
    TorNet.onions = (host, port) => (onion: 'abcdefghij.onion', port: 80, tls: false);
    await httpGet(Uri.https('status.btlabs.uk', '/a'));
    await httpGet(Uri.https('status.btlabs.uk', '/b'));
    expect(socks.connects, hasLength(2));
    expect(socks.connects[0].user, isNot(socks.connects[1].user));
  });

  test('plain http never leaves through an exit', () async {
    final socks = await _FakeSocks.start({'example.org': web.port});
    addTearDown(socks.close);
    TorNet.useTor(socks.proxy);
    await expectLater(httpGet(Uri.http('example.org', '/')), throwsA(isA<NetError>()));
    expect(socks.connects, isEmpty);
  });

  test('Tor on but not connected: nothing is opened, nothing goes direct', () async {
    final socks = await _FakeSocks.start({});
    addTearDown(socks.close);
    TorNet.waitForTor();
    await expectLater(httpGet(Uri.http('127.0.0.2', '/')), throwsA(isA<NetError>()));
    await expectLater(httpGet(Uri.http('example.org', '/')), throwsA(isA<NetError>()));
    expect(socks.accepted, 0);
    expect(seen, isEmpty);
  });

  test('a node on this computer stays direct while Tor is on', () async {
    TorNet.waitForTor();
    final reply = await httpGet(Uri.http('127.0.0.1:${web.port}', '/'));
    expect(reply.status, 200);
  });

  test('https through an exit: TLS checked for the real host over the SOCKS stream', () async {
    final ctx = SecurityContext()
      ..useCertificateChainBytes(utf8.encode(_cert))
      ..usePrivateKeyBytes(utf8.encode(_key));
    final tls = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, ctx);
    addTearDown(() => tls.close(force: true));
    tls.listen((r) {
      r.response.write('secret');
      r.response.close();
    });
    final socks = await _FakeSocks.start({'status.btlabs.uk': tls.port});
    addTearDown(socks.close);
    final trust = SecurityContext(withTrustedRoots: false)..setTrustedCertificatesBytes(utf8.encode(_cert));
    final client = HttpClient()
      ..userAgent = null
      ..findProxy = ((_) => 'DIRECT')
      ..connectionFactory = socksConnectionFactory(socks.proxy, context: trust);
    addTearDown(() => client.close(force: true));
    final req = await client.getUrl(Uri.https('status.btlabs.uk', '/'));
    final res = await req.close();
    expect(await utf8.decodeStream(res), 'secret');
    expect(socks.connects.single, (atyp: 3, host: 'status.btlabs.uk', port: 443, user: socks.connects.single.user));
  });

  test('a refused CONNECT is a NetError', () async {
    final socks = await _FakeSocks.start({});
    addTearDown(socks.close);
    TorNet.useTor(socks.proxy);
    await expectLater(httpGet(Uri.https('nowhere.example', '/')), throwsA(isA<NetError>()));
  });

  test('BT Labs servers only at their onions: the built-in list, never an exit', () async {
    expect(builtInOnions('status.btlabs.uk', 443)?.port, 80);
    expect(builtInOnions('status.btlabs.uk', 443)?.tls, isFalse);
    expect(builtInOnions('node.btlabs.uk', 443)?.tls, isTrue);
    expect(builtInOnions('epicbox.epiccash.com', 443), isNull);
    final socks = await _FakeSocks.start({});
    addTearDown(socks.close);
    TorNet.useTor(socks.proxy);
    await expectLater(httpGet(Uri.https('new.btlabs.uk', '/')), throwsA(isA<NetError>()));
    expect(socks.connects, isEmpty);
  });
}
