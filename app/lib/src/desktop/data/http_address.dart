/// Direct HTTP addresses: the rule Send checks before it asks LEPIC, and this computer's
/// address for Receive.
library;

import 'dart:io';

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
String? httpAddressProblem(String text) {
  final t = text.trim();
  if (t.isEmpty) return 'Enter the recipient’s address';
  if (!t.contains('://')) return 'Start with https:// or http://';
  final uri = parseHttpAddress(t);
  if (uri == null) {
    final host = Uri.tryParse(t)?.host.toLowerCase() ?? '';
    if (host.endsWith('.onion')) return 'Onion addresses need Tor';
    return 'Not an http(s) address';
  }
  if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) return 'Port must be 1 to 65535';
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
  r'^(docker|br-|virbr|veth|tun|wg|tailscale|utun|zt)',
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

/// This computer's address on the local network for Receive: a private (RFC 1918) address of a
/// real interface when there is one, else any other non-virtual IPv4 address; null with none.
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
    for (final a in found) {
      if (isPrivateLanAddress(a)) return a.address;
    }
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
