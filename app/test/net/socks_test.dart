// SPDX-License-Identifier: Apache-2.0
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
import 'package:epic_wallet/src/net/tor_switch.dart';
import 'package:epic_wallet/src/net/ws_probe.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart' show ListenerState;
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/tor_routes.dart';
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

  /// The next this many CONNECTs are refused (host unreachable), as a circuit that fails.
  int refuse = 0;

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
    final to = refuse > 0 ? null : targets[host];
    if (refuse > 0) refuse--;
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
MIIDNDCCAhygAwIBAgIUaTlGlT0RcbXbyztMRD4kGyFb0GUwDQYJKoZIhvcNAQEL
BQAwGzEZMBcGA1UEAwwQbm9kZS5leGFtcGxlLm9yZzAeFw0yNjEwMjMxNDQ1MDBa
Fw0zNjEwMjAxNDQ1MDBaMBsxGTAXBgNVBAMMEG5vZGUuZXhhbXBsZS5vcmcwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDlKYKr/z8fJGtI+TheqmQuDoEp
RCiLqn5xNlSK5qoF49Y3JyLs4IM8zJrqnZKRl0JuVvjcoqLc75xokzicfSFAC0r7
fr98aXubZes9/+7aeUzRJrdsEPnsacecBMiewkiKDvjDthbWUhhC9LUIN5a+RPdL
HnLJ0j+Uxl9+Z2lr6e1iuZe6r0M7JRwGx3bRbQlbYgwwaD4DV7bJmEe0ymCBg8rs
lpeePS/xAHXvZ5QtVW1xy0f5EMNqeh2NYG0gNui+MWHhtGjsyGXgFtEmcwq9Cewb
YZ6gNn98DXPEee/5ymFpNDIK872EUfdPWIT6HYhV5Mo589X2Os0XhisVD8l5AgMB
AAGjcDBuMB0GA1UdDgQWBBTbf3eMfh32C/7eV0dY3toP2/zFATAfBgNVHSMEGDAW
gBTbf3eMfh32C/7eV0dY3toP2/zFATAPBgNVHRMBAf8EBTADAQH/MBsGA1UdEQQU
MBKCEG5vZGUuZXhhbXBsZS5vcmcwDQYJKoZIhvcNAQELBQADggEBAOPo7POn0AsH
+qBm7B8VzLUvUBl5aaWVPX63laEEccWN9WTrLmpyMjV4/A4cXF1He6VQoYt+MBMz
sp77+aOLAefZScFCB1Z1LEXsJl71C04f0RYB5F8rHp6wAH2K8V3O/Dp0RC8Qs9wv
w8wPUZ1BFdF18AEIVfLJ7MQ0LKM19xx8dSkL2yjFtpHhhIoG0wQSYj6JyMJ6t83s
gsEqEPoY5Odk2/mUVm9l5bU2UxIasvJhwxRjtZUtXW8F+BEYYCNKdEXP9XJCSF06
T3wNK75vfSRTe/GKW0kvOIjSxfEag8u0gb/GoRkxrbsaCihs7hFha7LqnZ/6Dbij
qn27Lt4VUC0=
-----END CERTIFICATE-----""";
const _key = """-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDlKYKr/z8fJGtI
+TheqmQuDoEpRCiLqn5xNlSK5qoF49Y3JyLs4IM8zJrqnZKRl0JuVvjcoqLc75xo
kzicfSFAC0r7fr98aXubZes9/+7aeUzRJrdsEPnsacecBMiewkiKDvjDthbWUhhC
9LUIN5a+RPdLHnLJ0j+Uxl9+Z2lr6e1iuZe6r0M7JRwGx3bRbQlbYgwwaD4DV7bJ
mEe0ymCBg8rslpeePS/xAHXvZ5QtVW1xy0f5EMNqeh2NYG0gNui+MWHhtGjsyGXg
FtEmcwq9CewbYZ6gNn98DXPEee/5ymFpNDIK872EUfdPWIT6HYhV5Mo589X2Os0X
hisVD8l5AgMBAAECggEABpIKlvtpIn6+8Pg4FvN3+Bg1MX3wcVC3TI5Gd69t4I1b
FKX7FiNfcr5aIc4Uq9yuoQtFzuvJ5jnnmENJw006sLY4xGPQTXjkEt1EDTGejMI9
l7guWETAkuGKQX2FYwuuETv/e5lJp8AuIATdj7AqOGtP6fUcmERRUxQbHJcOOZHQ
4H3u8Y+aoBiTjm+QobwsMGTZvBnqUEqnnjCtuxrftD8RBhFQDf7d+UoOr+Rki3ro
/8yyzv7k8YRtCuGfzMWCHeREqfGc4PP7og6vmc+pUjmOI7CrB3F8V2OXYFjRpKT+
NVslymNqDKQMGFkZT9B9ur9N2pLCmLlux/jdpN7UIQKBgQD2FMXcX/9qlSuQHbaM
eRHvZiCGVCJD/NpHoCM/VHj3b6ol6t71nl0f8ffa7b88yrveBv2+cs6zuglb9kU9
fnLMCUNOshWsi68mJcfjRQGdo9XB6aL/YDzIkZAjFB/ichAGZbCA9EgExWz8luer
QsJ7bu46XkqrryvHeU+eBxZyWwKBgQDuZif+/1UiWqfRm1JPBDoskc31it3RZerS
a7VxtcLkF7lBUWk5E/YGbBWPM1+svF33fJ6CGNfNuc59+25b5UIdp24UU8H3NI0u
G4HM/MqQbHpyPz4PLLQmaofenBDScZpLoJjOBK72vBONg/6iAawql/8SMuXhWydj
SXDVTACTuwKBgQCizHld4xCaFZfdXxru8gXgiIMJ+000B2rtKc9HzX29zN0W+ryI
aD2Zrb3Y06LJ+CGzsJJcVZ3UH0aj1VhXZ3lQ7Ovfe0eFgF/eb+4+t99qyAHZqNTR
+HweANcHrf+uEuHxKYNMvM+MgIQq0zbvAVqiyG/Io6rozBm9fM8kb/H0swKBgQCV
n3ACzuXzxcoF9+HUzeZlCq2lKh7FyZ1zqz4Zu+YxmeIfaKUNucVzimqNkcS+eQrQ
xVoGdOkcqT08PI2rB1xTmD2ybE8Ug9sH0SPKL+5CbpL7GU4t3/TBF6Nmx7SXH82j
IYxF4RKesLPk4a7ypvITWYoxNdipc7hozDMQ676A+QKBgQDFmUFr76K9VBWGtX8P
NJFV4Rb3yc2q1VasRCEmJXklVFN6LwWitLeM4z056N6bkmfxQeMz+tKX7tkHh4wq
f7+caxWWqfUGQ5KP5n2evI6yVlsAFhzblEgubHsBmfSWMlz6XTQ/07BGXnur2GTs
0RyeFM7vZev7nq1Rhz3uWlcMyw==
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
    TorNet.onions = (host, port) => host == 'status.lab.invalid' ? (onion: 'abcdefghij.onion', port: 80, tls: false) : null;
    final reply = await httpGet(Uri.http('status.lab.invalid', '/api/v1/price.json'));
    expect(reply.status, 200);
    expect(reply.body, '{"ok":true}');
    expect(socks.connects.single.atyp, 3, reason: 'a name, never an address looked up here');
    expect(socks.connects.single.host, 'abcdefghij.onion');
    expect(socks.connects.single.port, 80);
    expect(seen.single.value(HttpHeaders.hostHeader), 'status.lab.invalid');
    expect(seen.single.value(HttpHeaders.userAgentHeader), isNull);
    expect(seen.single.value(HttpHeaders.acceptLanguageHeader), isNull);
  });

  test('fresh credentials per connection', () async {
    final socks = await _FakeSocks.start({'abcdefghij.onion': web.port});
    addTearDown(socks.close);
    TorNet.useTor(socks.proxy);
    TorNet.onions = (host, port) => (onion: 'abcdefghij.onion', port: 80, tls: false);
    await httpGet(Uri.http('status.lab.invalid', '/a'));
    await httpGet(Uri.http('status.lab.invalid', '/b'));
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
    final socks = await _FakeSocks.start({'node.example.org': tls.port});
    addTearDown(socks.close);
    final trust = SecurityContext(withTrustedRoots: false)..setTrustedCertificatesBytes(utf8.encode(_cert));
    final client = HttpClient()
      ..userAgent = null
      ..findProxy = ((_) => 'DIRECT')
      ..connectionFactory = socksConnectionFactory(socks.proxy, context: trust);
    addTearDown(() => client.close(force: true));
    final req = await client.getUrl(Uri.https('node.example.org', '/'));
    final res = await req.close();
    expect(await utf8.decodeStream(res), 'secret');
    expect(socks.connects.single, (atyp: 3, host: 'node.example.org', port: 443, user: socks.connects.single.user));
  });

  test('a refused CONNECT is a NetError', () async {
    final socks = await _FakeSocks.start({});
    addTearDown(socks.close);
    TorNet.useTor(socks.proxy);
    await expectLater(httpGet(Uri.https('nowhere.example', '/')), throwsA(isA<NetError>()));
  });

  test('BT Labs servers only at their onions: the built-in list, never an exit', () async {
    expect(torBuiltInOnion('status.lab.invalid', 443)?.port, 80);
    expect(torBuiltInOnion('status.lab.invalid', 443)?.tls, isFalse);
    expect(torBuiltInOnion('node.lab.invalid', 443)?.tls, isTrue);
    expect(torBuiltInOnion('box.epic.invalid', 443), isNull);
    final socks = await _FakeSocks.start({});
    addTearDown(socks.close);
    TorNet.useTor(socks.proxy);
    await expectLater(httpGet(Uri.https('new.lab.invalid', '/')), throwsA(isA<NetError>()));
    expect(socks.connects, isEmpty);
  });

  test("https never goes in clear to a plain onion a list names; the app's own status onion still serves it", () async {
    final status = torBuiltInOnion('status.lab.invalid', 443)!;
    final socks = await _FakeSocks.start({'abcdefghij.onion': web.port, status.onion: web.port});
    addTearDown(socks.close);
    TorNet.useTor(socks.proxy);
    // A plain onion from a list for an https URL: refused, and nothing goes through an exit.
    TorNet.onions = (host, port) => (onion: 'abcdefghij.onion', port: 80, tls: false);
    await expectLater(httpGet(Uri.https('status.lab.invalid', '/api/v1/status.json')), throwsA(isA<NetError>()));
    await expectLater(httpGet(Uri.https('support.lab.invalid', '/')), throwsA(isA<NetError>()));
    expect(socks.connects, isEmpty);
    // The same onion serves a plain http URL.
    expect((await httpGet(Uri.http('status.lab.invalid', '/a'))).status, 200);
    expect(socks.connects.single.host, 'abcdefghij.onion');
    // The status site's own onion, as built in and as the signed list names it: still used.
    TorNet.onions = (host, port) => host == 'status.lab.invalid' ? status : null;
    final reply = await httpGet(Uri.https('status.lab.invalid', '/api/v1/status.json'));
    expect(reply.status, 200);
    expect(socks.connects.last.host, status.onion);
    expect(socks.connects.last.port, 80);
    // No list at all: the built-in table.
    TorNet.onions = null;
    expect((await httpGet(Uri.https('status.lab.invalid', '/b'))).status, 200);
    expect(socks.connects.last.host, status.onion);
  });

  test("Send review's relay probe goes through tor while Tor is on, and a slow answer is not a failure", () async {
    // A relay that answers only after the direct probe's timeout, as one far down a circuit.
    final relay = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => relay.close(force: true));
    relay.listen((request) async {
      await Future<void>.delayed(probeTimeout + const Duration(seconds: 1));
      final socket = await WebSocketTransformer.upgrade(request);
      await socket.close();
    });
    const onion = 'relayrelayrelayrelayrelayrelayrelayrelayrelayrelayrelayr.onion';
    final socks = await _FakeSocks.start({onion: relay.port});
    addTearDown(socks.close);
    TorNet.follow(TorState.on, proxy: socks.proxy);
    addTearDown(() => TorSwitch.on = false);
    TorNet.onions = (host, port) =>
        host == 'epicbox.example.org' ? (onion: onion, port: 80, tls: false) : null;
    expect(relayProbeTimeout(), torProbeTimeout);
    // Plain ws, so the local relay needs no certificate; the route is the one wss takes.
    final probe = WebSocketRelayProbe(uriFor: (r) => Uri(scheme: 'ws', host: r.host, port: r.port));
    expect(await probe.reachable(EpicboxRelay(host: 'epicbox.example.org', port: 443)), isTrue);
    expect(socks.connects.single.host, onion);
    expect(socks.connects.single.atyp, 3);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('with Tor off the relay probe keeps the short direct timeout', () {
    TorNet.follow(TorState.off);
    expect(relayProbeTimeout(), probeTimeout);
  });

  group('android-10: the Send review\'s relay check over Tor', () {
    // A relay on this computer that takes the WebSocket handshake, behind a fake onion.
    Future<_FakeSocks> relayBehindTor() async {
      final relay = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => relay.close(force: true));
      relay.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        await socket.close();
      });
      const onion = 'relayrelayrelayrelayrelayrelayrelayrelayrelayrelayrelayr.onion';
      final socks = await _FakeSocks.start({onion: relay.port});
      addTearDown(socks.close);
      TorNet.onions = (host, port) =>
          host == 'epicbox.example.org' ? (onion: onion, port: 80, tls: false) : null;
      addTearDown(() => TorSwitch.on = false);
      return socks;
    }

    final probe = WebSocketRelayProbe(uriFor: (r) => Uri(scheme: 'ws', host: r.host, port: r.port));
    final relay = EpicboxRelay(host: 'epicbox.example.org', port: 443);

    test('Tor still connecting when the review opens: the probe waits for it, then asks', () async {
      final socks = await relayBehindTor();
      TorNet.follow(TorState.starting);
      TorNet.hold = const Duration(seconds: 5);
      addTearDown(() => TorNet.hold = Duration.zero);
      final answer = probe.reachable(relay);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(socks.accepted, 0, reason: 'nothing opened, nothing direct, while tor is not up');
      TorNet.follow(TorState.on, proxy: socks.proxy);
      expect(await answer, isTrue);
    });

    test('Tor not connected in time: the relay is not asked, so it is not flagged', () async {
      final socks = await relayBehindTor();
      TorNet.follow(TorState.starting);
      TorNet.hold = const Duration(milliseconds: 100);
      addTearDown(() => TorNet.hold = Duration.zero);
      await expectLater(probe.reachable(relay), throwsA(isA<ProbeNotRun>()));
      expect(socks.accepted, 0);
      // The review reads that as "no word": neither ready-to-send nor a relay that is down.
      final checks = sendPreflight(
        node: AsyncData(NodeTip(height: BigInt.one, nodeVersion: 'x')),
        listener: const ListenerState(connected: true),
        relays: const AsyncData(<RelayStatus>[]),
        relay: relay,
        probe: AsyncError<bool>(const ProbeNotRun(), StackTrace.empty),
      );
      expect(checks.relayOutcome, isNull);
      expect(checks.warns, isFalse);
    });

    test('a circuit that fails at once is tried once more; a working relay is not flagged', () async {
      final socks = await relayBehindTor();
      TorNet.follow(TorState.on, proxy: socks.proxy);
      socks.refuse = 1;
      expect(await probe.reachable(relay), isTrue);
      expect(socks.connects, hasLength(2));
      expect(socks.connects[0].user, isNot(socks.connects[1].user), reason: 'a new circuit');
    });

    test('two failures say the relay does not answer', () async {
      final socks = await relayBehindTor();
      TorNet.follow(TorState.on, proxy: socks.proxy);
      socks.refuse = 2;
      expect(await probe.reachable(relay), isFalse);
      expect(socks.connects, hasLength(2));
    });
  });
}
