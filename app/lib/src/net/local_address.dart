/// What counts as local in the Offline mode: this computer (loopback, `localhost`) and the
/// private local network (10/8, 172.16/12, 192.168/16, link-local 169.254/16, IPv6 ULA fc00::/7
/// and link-local fe80::/10). Never a public address, an onion, or a name that resolves to a
/// public address. Pure Dart, also on the web; the lookup is passed in.
///
/// A literal address is judged without any lookup. A name is looked up once ([resolveLocal]):
/// every address it gives must be local, and the caller connects to the address found, so no
/// second lookup can return a public one.
library;

/// What a host is, without a lookup.
enum HostKind {
  /// A loopback or private-network address, or `localhost`.
  local,

  /// Any other address, as a literal IP.
  public,

  /// A `.onion` name.
  onion,

  /// Any other name: only a lookup tells.
  name,
}

/// [host] (a URL's host: brackets and an IPv6 zone allowed) as a literal address, or null.
List<int>? _literalBytes(String host) {
  var h = host.trim();
  if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
  final zone = h.indexOf('%');
  if (zone >= 0) h = h.substring(0, zone);
  if (h.isEmpty) return null;
  if (h.contains(':')) {
    try {
      return Uri.parseIPv6Address(h);
    } on FormatException {
      return null;
    }
  }
  // Only the four-part dotted form: "127.1" and "2130706433" are names here (a lookup turns
  // them into an address, which is then judged).
  if (!RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(h)) return null;
  try {
    return Uri.parseIPv4Address(h);
  } on FormatException {
    return null;
  }
}

/// Whether [bytes] (4 or 16 bytes) is a local address. IPv4-mapped IPv6 (::ffff:a.b.c.d) is
/// judged as the IPv4 address.
bool isLocalIpBytes(List<int> bytes) {
  if (bytes.length == 4) {
    final a = bytes[0], b = bytes[1];
    return a == 127 ||
        a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 169 && b == 254);
  }
  if (bytes.length != 16) return false;
  var mapped = bytes[10] == 0xff && bytes[11] == 0xff;
  for (var i = 0; i < 10 && mapped; i++) {
    if (bytes[i] != 0) mapped = false;
  }
  if (mapped) return isLocalIpBytes(bytes.sublist(12));
  var loopback = bytes[15] == 1;
  for (var i = 0; i < 15 && loopback; i++) {
    if (bytes[i] != 0) loopback = false;
  }
  return loopback || (bytes[0] & 0xfe) == 0xfc || (bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80);
}

/// [host] judged without a lookup.
HostKind hostKind(String host) {
  final h = host.trim().toLowerCase();
  final bytes = _literalBytes(h);
  if (bytes != null) return isLocalIpBytes(bytes) ? HostKind.local : HostKind.public;
  final name = h.endsWith('.') ? h.substring(0, h.length - 1) : h;
  if (name == 'localhost') return HostKind.local;
  if (name.endsWith('.onion')) return HostKind.onion;
  return HostKind.name;
}

/// Whether [address] is a literal local IP (no names, no lookup).
bool isLocalIp(String address) {
  final bytes = _literalBytes(address);
  return bytes != null && isLocalIpBytes(bytes);
}

/// Whether the node at [url] is local as written: a literal local IP or `localhost`. A name is
/// not: the wallet core looks the node up at every request, so a name could turn public later.
bool isLocalAddressUrl(String? url) {
  final u = url == null ? null : Uri.tryParse(url.trim());
  if (u == null || u.host.isEmpty) return false;
  return hostKind(u.host) == HostKind.local;
}

/// Whether [address] is a literal loopback IP: 127/8 or ::1 (IPv4-mapped judged as IPv4).
bool isLoopbackIp(String address) {
  var bytes = _literalBytes(address);
  if (bytes == null) return false;
  if (bytes.length == 16 && bytes.sublist(0, 10).every((b) => b == 0) && bytes[10] == 0xff && bytes[11] == 0xff) {
    bytes = bytes.sublist(12);
  }
  if (bytes.length == 4) return bytes[0] == 127;
  return bytes.sublist(0, 15).every((b) => b == 0) && bytes[15] == 1;
}

/// Whether [address] is a literal CGNAT address, 100.64.0.0/10: a Tailscale tailnet or a
/// carrier's own network. Not local for Offline; a plain-http node there goes through the node
/// relay (`lan_node_relay.dart`) and is judged by the app's own check ([isLocalNodeUrl]).
bool isCgnatIp(String address) {
  var bytes = _literalBytes(address);
  if (bytes == null) return false;
  if (bytes.length == 16 && bytes.sublist(0, 10).every((b) => b == 0) && bytes[10] == 0xff && bytes[11] == 0xff) {
    bytes = bytes.sublist(12);
  }
  return bytes.length == 4 && bytes[0] == 100 && (bytes[1] & 0xc0) == 64;
}

/// Whether [host] is a name only the local network answers for: `.local` (mDNS) or `.lan`. A
/// node there is looked up before the wallet connects ([resolveLocal]).
bool isLocalNetworkName(String host) {
  var h = host.trim().toLowerCase();
  if (h.endsWith('.')) h = h.substring(0, h.length - 1);
  return h.endsWith('.local') || h.endsWith('.lan');
}

/// Whether the node at [url] is on this computer, the local network or a tailnet, as the app
/// judges it (never status.btlabs.uk, which cannot reach it): a literal local IP, `localhost`,
/// a `.local` / `.lan` name, or a CGNAT address ([isCgnatIp]).
bool isLocalNodeUrl(String? url) {
  if (isLocalAddressUrl(url)) return true;
  final u = url == null ? null : Uri.tryParse(url.trim());
  return u != null && u.host.isNotEmpty && (isLocalNetworkName(u.host) || isCgnatIp(u.host));
}

/// Looks [host] up: its addresses as strings. `InternetAddress.lookup` on a computer.
typedef HostLookup = Future<List<String>> Function(String host);

/// [host] as one local address to connect to, looked up at most once; null when it is not
/// local (a public or onion address, a name with any public address or none). A literal
/// address or `localhost` is never looked up and is returned as given.
Future<String?> resolveLocal(String host, HostLookup lookup) async {
  switch (hostKind(host)) {
    case HostKind.local:
      return host.trim();
    case HostKind.public || HostKind.onion:
      return null;
    case HostKind.name:
      final List<String> found;
      try {
        found = await lookup(host.trim());
      } on Object {
        return null;
      }
      if (found.isEmpty) return null;
      for (final a in found) {
        if (!isLocalIp(a)) return null;
      }
      return found.first;
  }
}

/// [url] (http or https) with its host replaced by the local address [resolveLocal] found, for
/// a connection that never looks the name up again; null when the address is not local.
Future<String?> localUrl(String url, HostLookup lookup) async {
  final u = Uri.tryParse(url.trim());
  if (u == null || u.host.isEmpty || (u.scheme != 'http' && u.scheme != 'https')) return null;
  final ip = await resolveLocal(u.host, lookup);
  if (ip == null) return null;
  final host = ip.startsWith('[') ? ip.substring(1, ip.length - 1) : ip;
  return host == u.host ? u.toString() : u.replace(host: host).toString();
}

/// What a node is to the user, from its address. It decides where its facts
/// come from (the node itself for every own class, never status.btlabs.uk), the panel's label
/// and whether an owner secret may travel to it.
enum NodeClass {
  /// `localhost`, 127/8, ::1.
  thisComputer,

  /// 10/8, 172.16/12, 192.168/16, 169.254/16, fc00::/7, fe80::/10, or a `.local` / `.lan` name.
  homeNetwork,

  /// 100.64/10 (a Tailscale tailnet) or a `*.ts.net` name. "VPN" in the interface.
  vpn,

  /// An https node status.btlabs.uk does not list, or one the user marked as theirs.
  ownServer,

  /// Anything else: a listed node, as today.
  public;

  /// Every class but [public]: the user's own node.
  bool get own => this != public;

  /// This computer, the home network or a VPN: never reached over Tor, plain http allowed.
  bool get local => this == thisComputer || this == homeNetwork || this == vpn;
}

/// [url]'s class without a lookup. [unlisted]: status.btlabs.uk answered and does not list
/// it; [mine]: the user marked it as their own. Either makes an https node [NodeClass.ownServer].
NodeClass nodeClassOf(String? url, {bool unlisted = false, bool mine = false}) {
  final u = url == null ? null : Uri.tryParse(url.trim());
  if (u == null || u.host.isEmpty) return NodeClass.public;
  var host = u.host.toLowerCase();
  if (host.endsWith('.')) host = host.substring(0, host.length - 1);
  if (host == 'localhost' || isLoopbackIp(host)) return NodeClass.thisComputer;
  if (isLocalIp(host) || isLocalNetworkName(host)) return NodeClass.homeNetwork;
  if (isCgnatIp(host) || host.endsWith('.ts.net')) return NodeClass.vpn;
  return unlisted || mine ? NodeClass.ownServer : NodeClass.public;
}
