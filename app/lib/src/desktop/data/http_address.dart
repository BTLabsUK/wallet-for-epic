/// Direct HTTP addresses: the rule Send checks before it asks LEPIC, and this computer's
/// address for Receive.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../l10n.dart' show AppLocalizations, englishStrings;
import '../../tor_build.dart' show torBuilt;

/// The port `epic-wallet` and the GUI listen on.
const int defaultHttpPort = 3415;

/// [text] as an HTTP(S) address the wallet sends to, trimmed; null when it is not one.
Uri? parseHttpAddress(String text) {
  final t = text.trim();
  final uri = Uri.tryParse(t);
  if (uri == null || !uri.hasScheme) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  if (uri.host.isEmpty || uri.host.toLowerCase().endsWith('.onion') || uri.userInfo.isNotEmpty) return null;
  return uri;
}

/// What is wrong with [text] as an HTTP(S) address, in a short sentence; null when it is one.
/// `HTTP://` in capitals is accepted; `host:port` without a scheme is not, so the sender picks
/// between plain and encrypted on purpose.
String? httpAddressProblem(String text, [AppLocalizations? l]) {
  l ??= englishStrings;
  final t = text.trim();
  if (t.isEmpty) return l.deskDataHttpEnter;
  if (!t.contains('://')) return l.deskDataHttpScheme;
  final uri = parseHttpAddress(t);
  if (uri == null) {
    final host = Uri.tryParse(t)?.host.toLowerCase() ?? '';
    if (host.endsWith('.onion')) return torBuilt ? l.deskDataHttpOnion : l.sendTorNotInVersion;
    return l.deskDataHttpNot;
  }
  if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) return l.deskDataHttpPort;
  return null;
}

/// This computer: `localhost`, 127.0.0.0/8 and ::1.
bool isLoopbackHost(String host) {
  final h = host.toLowerCase();
  if (h == 'localhost') return true;
  final ip = InternetAddress.tryParse(h);
  return ip != null && ip.isLoopback;
}

/// Plain `http` to another computer: the slate travels unencrypted, so Send asks first.
bool plainHttpNeedsConsent(String text) {
  final uri = parseHttpAddress(text);
  return uri != null && uri.scheme.toLowerCase() == 'http' && !isLoopbackHost(uri.host);
}

/// Interfaces that are not the local network: containers, bridges, VPNs and tunnels.
final RegExp _virtualInterface = RegExp(
  r'^(docker|br-|virbr|veth|tun|tap|wg|tailscale|utun|zt|vethernet|vmnet|vboxnet|hamachi)'
  r'|nordlynx|nordvpn|openvpn|wireguard|proton|mullvad|vpn|tunnel|hyper-v|vmware|virtualbox|loopback',
  caseSensitive: false,
);

/// 10/8, 172.16/12 or 192.168/16.
bool isPrivateLanAddress(InternetAddress a) {
  final b = a.rawAddress;
  if (b.length != 4) return false;
  return b[0] == 10 ||
      (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
      (b[0] == 192 && b[1] == 168);
}

/// 0 for 192.168/16, 1 for 172.16/12, 2 for 10/8: a home or office network before the 10.x a
/// VPN client often keeps, whatever order the system lists the interfaces in.
int _privateRank(InternetAddress a) {
  final b = a.rawAddress;
  return b[0] == 192 ? 0 : (b[0] == 172 ? 1 : 2);
}

/// This computer's address on the local network for Receive: a private (RFC 1918) address of a
/// real interface when there is one (192.168 before 172.16 before 10), else any other non-virtual IPv4 address; null with none.
/// [list] is the interfaces, for tests.
Future<String?> lanAddress({
  Future<List<({String name, List<InternetAddress> addresses})>> Function()?
  list,
}) async {
  try {
    final interfaces = await (list ?? _systemInterfaces)();
    final found = <InternetAddress>[
      for (final i in interfaces)
        if (!_virtualInterface.hasMatch(i.name))
          for (final a in i.addresses)
            if (a.type == InternetAddressType.IPv4 && !a.isLoopback && !a.isLinkLocal) a,
    ];
    final private = found.where(isPrivateLanAddress).toList()
      ..sort((x, y) => _privateRank(x).compareTo(_privateRank(y)));
    if (private.isNotEmpty) return private.first.address;
    if (found.isNotEmpty) return found.first.address;
  } on Object {
    // No address to show; Receive says so.
  }
  return null;
}

Future<List<({String name, List<InternetAddress> addresses})>>
_systemInterfaces() async => [
  for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4))
    (name: i.name, addresses: i.addresses),
];

/// Asks the internet about this computer for From the internet: the router's public IP and
/// whether a port on it answers from outside. Both go over HTTPS; null when it cannot tell.
abstract interface class PublicReachProbe {
  /// The public IPv4 address the internet sees this computer as.
  Future<String?> publicIp();

  /// Whether `ip:port` accepts a TCP connection from the internet.
  Future<bool?> reachable(String ip, int port);
}

/// [PublicReachProbe] on api.ipify.org (the IP, as the GUI 6.1.6 asks it) and portchecker.io
/// (a connection from its server, so it tells what a sender sees, unlike a connection from this
/// computer through the router). No user agent, no cookies, no redirects.
class WebReachProbe implements PublicReachProbe {
  const WebReachProbe();

  static final Uri _ip = Uri.parse('https://api.ipify.org?format=json');
  static final Uri _check = Uri.parse('https://portchecker.io/api/v1/query');
  static const Duration _timeout = Duration(seconds: 10);

  @override
  Future<String?> publicIp() async {
    final json = await _json(_ip);
    final ip = json is Map ? json['ip'] : null;
    final a = ip is String ? InternetAddress.tryParse(ip) : null;
    return a != null && a.type == InternetAddressType.IPv4 ? a.address : null;
  }

  @override
  Future<bool?> reachable(String ip, int port) async {
    final json = await _json(_check, body: {'host': ip, 'ports': [port]});
    if (json is! Map || json['error'] == true) return null;
    final check = json['check'];
    if (check is! List) return null;
    for (final c in check) {
      if (c is Map && c['port'] == port && c['status'] is bool) return c['status'] as bool;
    }
    return null;
  }

  Future<Object?> _json(Uri url, {Object? body}) async {
    final client = HttpClient()
      ..connectionTimeout = _timeout
      ..userAgent = null;
    try {
      final request = await (body == null ? client.getUrl(url) : client.postUrl(url)).timeout(_timeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(_timeout);
      final text = await response.transform(utf8.decoder).join().timeout(_timeout);
      return response.statusCode == 200 ? jsonDecode(text) : null;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

/// What the internet sees of the HTTP listener From the internet.
class HttpReach {
  const HttpReach({required this.port, this.publicIp, this.lan, this.reachable, required this.checkedAt});

  final int port;

  /// The router's public IP; null when it could not be found.
  final String? publicIp;

  /// This computer on the local network, for devices at home.
  final String? lan;

  /// Whether the internet reaches `publicIp:port`; null when it could not be checked.
  final bool? reachable;

  final DateTime checkedAt;

  /// `http://<public IP>:<port>`, the address senders on the internet use; null without the IP.
  String? get publicAddress => publicIp == null ? null : 'http://$publicIp:$port';

  /// `http://<LAN address>:<port>`, for devices on the same network.
  String? get lanAddress => lan == null ? null : 'http://$lan:$port';
}

/// [HttpReach], asked again after [ttl], when the port or the local network changes, or on
/// [read]'s `recheck`. Calls at the same time share one check.
class HttpReachCache {
  HttpReachCache({
    this._probe = const WebReachProbe(),
    Future<String?> Function()? lan,
    DateTime Function()? now,
    this.ttl = const Duration(minutes: 2),
  }) : _lan = lan ?? lanAddress,
       _now = now ?? DateTime.now;

  final PublicReachProbe _probe;
  final Future<String?> Function() _lan;
  final DateTime Function() _now;
  final Duration ttl;

  HttpReach? _last;
  Future<HttpReach>? _running;
  int? _runningPort;

  /// The last check, without asking anything.
  HttpReach? get last => _last;

  Future<HttpReach> read(int port, {bool recheck = false}) async {
    final lan = await _lan();
    final last = _last;
    final fresh = last != null && last.port == port && last.lan == lan && _now().difference(last.checkedAt) < ttl;
    if (fresh && !recheck) return last;
    final running = _running;
    if (running != null && _runningPort == port) return running;
    final check = _check(port, lan);
    _running = check;
    _runningPort = port;
    try {
      return _last = await check;
    } finally {
      if (identical(_running, check)) _running = null;
    }
  }

  /// The local network address only, asking nothing on the internet (Offline). Not kept.
  Future<HttpReach> readLan(int port) async => HttpReach(port: port, lan: await _lan(), checkedAt: _now());

  /// Forgets the last check (the listener stopped, Tor came on).
  void clear() => _last = null;

  Future<HttpReach> _check(int port, String? lan) async {
    final ip = await _probe.publicIp();
    final reachable = ip == null ? null : await _probe.reachable(ip, port);
    return HttpReach(port: port, publicIp: ip, lan: lan, reachable: reachable, checkedAt: _now());
  }
}
