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

/// This computer's first IPv4 address on the local network, or null (no network).
Future<String?> lanAddress() async {
  try {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (final i in interfaces) {
      for (final a in i.addresses) {
        if (!a.isLoopback && !a.isLinkLocal) return a.address;
      }
    }
  } on Object {
    // No address to show; Receive says so.
  }
  return null;
}
