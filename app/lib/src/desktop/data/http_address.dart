// SPDX-License-Identifier: Apache-2.0
/// Direct HTTP addresses: the rule Send checks before it asks LEPIC, and this computer's
/// address for Receive.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../l10n.dart' show AppLocalizations, englishStrings;
import '../../tor_build.dart' show torBuilt;
import '../../net/http.dart' show httpGet;
import '../../net/tor_switch.dart' show TorSwitch;
import '../../settings_file/host_settings.dart' show appConfig, hostSettings;

/// The port the Link · HTTP listener takes unless the user picks another
/// (`http.listen_port` of `app-config.toml`).
int get defaultHttpPort => appConfig.httpListenPort;

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

/// The status server cannot check over Tor (it would see the exit, not this computer): it says
/// so, and the check needs Tor off.
class ReachNeedsTorOff implements Exception {
  const ReachNeedsTorOff();
}

/// [PublicReachProbe] on our status server (`[status] ip` and `reach` of `app-config.toml`):
/// the address it sees this computer at, and whether a connection from it to that address and
/// [port] gets through (it checks only the asking address, so it tells what a sender sees).
/// Answers: `{"ip": "…"}` and `{"ip", "port", "open", "foreign_api", "detail"}`; an error is
/// `{"error": "…"}` (400; 429 = try later, read as "could not tell"). Never with Tor on: a Tor
/// exit would answer for the exit's address, and the status onion answers "not available over
/// Tor" ([ReachNeedsTorOff] either way).
class WebReachProbe implements PublicReachProbe {
  const WebReachProbe();

  /// Whether `app-config.toml` names the two addresses; without them there is no check.
  static bool get configured => hostSettings.config.statusIp != null && hostSettings.config.statusReach(0) != null;

  @override
  Future<String?> publicIp() async {
    if (TorSwitch.on) throw const ReachNeedsTorOff();
    final url = hostSettings.config.statusIp;
    if (url == null) return null;
    final json = await _json(Uri.parse(url));
    final ip = json is Map ? json['ip'] : null;
    final a = ip is String ? InternetAddress.tryParse(ip) : null;
    return a != null && a.type == InternetAddressType.IPv4 ? a.address : null;
  }

  @override
  Future<bool?> reachable(String ip, int port) async {
    final url = hostSettings.config.statusReach(port);
    if (url == null) return null;
    final json = await _json(Uri.parse(url));
    final open = json is Map ? json['open'] : null;
    return open is bool ? open : null;
  }

  Future<Object?> _json(Uri url) async {
    try {
      final reply = await httpGet(
        url,
        headers: const {'accept': 'application/json'},
        timeout: hostSettings.config.reachTimeout,
        maxBytes: 4096,
      );
      if (reply.status != 200) {
        final error = reply.status == 400 ? jsonDecode(reply.body) : null;
        if (error is Map && '${error['error']}'.contains('Tor')) throw const ReachNeedsTorOff();
        return null;
      }
      return jsonDecode(reply.body);
    } on ReachNeedsTorOff {
      rethrow;
    } on Object {
      return null;
    }
  }
}

/// What the internet sees of the HTTP listener From the internet.
class HttpReach {
  const HttpReach({required this.port, this.publicIp, this.lan, this.reachable, this.needsTorOff = false, required this.checkedAt});

  final int port;

  /// The router's public IP; null when it could not be found.
  final String? publicIp;

  /// This computer on the local network, for devices at home.
  final String? lan;

  /// Whether the internet reaches `publicIp:port`; null when it could not be checked.
  final bool? reachable;

  /// The status server said it cannot check over Tor.
  final bool needsTorOff;

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
    try {
      final ip = await _probe.publicIp();
      final reachable = ip == null ? null : await _probe.reachable(ip, port);
      return HttpReach(port: port, publicIp: ip, lan: lan, reachable: reachable, checkedAt: _now());
    } on ReachNeedsTorOff {
      return HttpReach(port: port, lan: lan, needsTorOff: true, checkedAt: _now());
    }
  }
}
