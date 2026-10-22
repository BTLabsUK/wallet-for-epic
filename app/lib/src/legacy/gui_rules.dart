/// The cleaning rules GUI 6.1.6 applies when it imports an older wallet, ported one to one so the
/// Import wizard brings the same values across. Sources (epic-gui-wallet, release 6.1.6, 5a83e2f):
/// src/shared/importer.js, nodeAddress.js, settingsStore.js (cleanLabel), myNodes.js,
/// setupDefaults.js (supportedLocale). Pure Dart.
library;

/// WALLET_DEFAULTS.check_node_api_http_addr (settingsStore.js) and MAINNET_FALLBACK_NODE.
const String guiDefaultNode = 'https://node.epiccash.com:3413';

/// nodeAddress.js LOCAL_NODE: the built-in node on every network.
const String guiLocalNode = 'http://127.0.0.1:3413';

/// WALLET_DEFAULTS.epicbox_domain.
const String guiDefaultEpicbox = 'epicbox.epiccash.com';

/// The languages GUI 6.1.6 offers (configService.js langs); importer.js supportedLocale maps any
/// other to 'en'. ru and zh were offered by older GUIs.
const List<String> guiLocales = ['bg', 'cz', 'de', 'en', 'fa', 'hi', 'pl'];

// nodeAddress.js: the fallbacks of older GUIs that are gone, and the mainnet nodes a GUI saved
final _deadFallbackHosts = [RegExp(r'^(.+\.)?fastepic\.eu$', caseSensitive: false), RegExp(r'^116\.203\.211\.229$')];
final _mainnetDefaultHosts = [RegExp(r'^node\.epiccash\.com$', caseSensitive: false), ..._deadFallbackHosts];
final _hasScheme = RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false);

/// importer.js EPICBOX_RENAMED.
const Map<String, String> _epicboxRenamed = {'epicbox.epic.tech': 'epicbox.epiccash.com'};

/// nodeAddress.js isPrivateHost: this computer or the local network.
bool isPrivateHost(String host) {
  var h = host.trim().toLowerCase();
  if (h.startsWith('[')) h = h.substring(1);
  if (h.endsWith(']')) h = h.substring(0, h.length - 1);
  if (h.endsWith('.')) h = h.substring(0, h.length - 1);
  if (h.isEmpty) return false;
  if (h == 'localhost' || h.endsWith('.localhost') || h.endsWith('.local') || h.endsWith('.lan')) return true;
  final v4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$').firstMatch(h);
  if (v4 != null) {
    final a = int.parse(v4[1]!), b = int.parse(v4[2]!);
    return a == 127 ||
        a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 169 && b == 254) ||
        (a == 100 && b >= 64 && b <= 127);
  }
  if (h.contains(':')) {
    return h == '::1' || RegExp(r'^f[cd][0-9a-f]{0,2}:').hasMatch(h) || RegExp(r'^fe[89ab][0-9a-f]?:').hasMatch(h);
  }
  return false;
}

/// A parsed http(s) address as the WHATWG URL parser would give it: scheme and host lowercased,
/// the default port dropped. Null when it is not one.
class _Url {
  _Url(this.scheme, this.host, this.port, this.path, this.hasUser, this.hasQuery);
  final String scheme, host, path;
  final int? port;
  final bool hasUser, hasQuery;

  /// `u.host`: the host, with the port unless it is the scheme's default.
  String get authority => port == null ? host : '$host:$port';

  static _Url? parse(String s) {
    final m = RegExp(r'^([a-z][a-z0-9+.-]*)://([^/?#]*)([^?#]*)(\?[^#]*)?(#.*)?$', caseSensitive: false).firstMatch(s);
    if (m == null) return null;
    final scheme = m[1]!.toLowerCase();
    var auth = m[2]!;
    final hasUser = auth.contains('@');
    if (hasUser) auth = auth.substring(auth.lastIndexOf('@') + 1);
    String host;
    int? port;
    final v6 = RegExp(r'^(\[[0-9a-fA-F:.]+\])(?::(\d*))?$').firstMatch(auth);
    if (v6 != null) {
      host = v6[1]!.toLowerCase();
      if (v6[2] != null && v6[2]!.isNotEmpty) port = int.parse(v6[2]!);
    } else {
      final hp = RegExp(r'^([^:\[\]]*)(?::(\d*))?$').firstMatch(auth);
      if (hp == null) return null;
      host = hp[1]!.toLowerCase();
      if (hp[2] != null && hp[2]!.isNotEmpty) port = int.parse(hp[2]!);
      if (host.isNotEmpty && !RegExp(r'^[a-z0-9._~!$&()*+,;=%-]+$').hasMatch(host)) return null;
    }
    if (port != null && port > 65535) return null;
    if ((scheme == 'http' && port == 80) || (scheme == 'https' && port == 443)) port = null;
    final path = m[3]!.isEmpty ? '/' : m[3]!;
    return _Url(scheme, host, port, path, hasUser, (m[4] ?? '').length > 1 || (m[5] ?? '').length > 1);
  }
}

String _hostOf(String s) => _Url.parse(_hasScheme.hasMatch(s) ? s : 'http://$s')?.host ?? '';

String _trimSlashes(String s) => s.replaceFirst(RegExp(r'/+$'), '');

/// nodeAddress.js cleanNodeAddress(address, {network}).url: the saved node address cleaned as
/// GUI 6.1 does at import. [network] is 'mainnet', 'floonet' or 'usernet'.
String cleanNodeAddress(String saved, {String network = 'mainnet'}) {
  var s = _trimSlashes(saved.trim());
  if (s.isEmpty) return saved;
  if (RegExp(r'^[a-z][a-z0-9+.-]*:/*$', caseSensitive: false).hasMatch(s)) return saved;
  if (!_hasScheme.hasMatch(s)) s = '${isPrivateHost(_hostOf(s)) ? 'http' : 'https'}://$s';
  final u = _Url.parse(s);
  if (u == null || (u.scheme != 'http' && u.scheme != 'https') || u.host.isEmpty || u.hasUser) return saved;
  final testnet = network == 'floonet' || network == 'usernet';
  if (testnet && _mainnetDefaultHosts.any((r) => r.hasMatch(u.host))) return guiLocalNode;
  if (_deadFallbackHosts.any((r) => r.hasMatch(u.host))) return guiDefaultNode;
  return '${u.scheme}://${u.authority}${_trimSlashes(u.path)}';
}

/// walletToml.js localNodeUrl: the network's own node API port.
String guiLocalNodeUrl(String network) =>
    'http://127.0.0.1:${switch (network) { 'floonet' => 13413, 'usernet' => 23413, _ => 3413 }}';

/// importer.js fallbackNodeAddress(url, {network}).
String fallbackNodeAddress(String url, {String network = 'mainnet'}) {
  final def = network == 'mainnet' ? guiDefaultNode : guiLocalNodeUrl(network);
  var u = url.trim();
  if (u.isEmpty) return def;
  if (!_hasScheme.hasMatch(u)) {
    final host = u.split(RegExp(r'[:/]'))[0].toLowerCase();
    u = '${host == '127.0.0.1' || host == 'localhost' ? 'http' : 'https'}://$u';
  }
  final p = _Url.parse(u);
  if (p == null || (p.scheme != 'http' && p.scheme != 'https')) return def;
  return _trimSlashes(u);
}

/// importer.js cleanNode as GUI 6.1.6 runs it (main.js injects cleanNodeAddress): the cleaned
/// address, or fallbackNodeAddress when that gives nothing.
String importerNodeAddress(String? url, {String network = 'mainnet'}) {
  final r = cleanNodeAddress(url ?? '', network: network);
  return r.isNotEmpty ? r : fallbackNodeAddress(url ?? '', network: network);
}

/// importer.js cleanEpicbox: trimmed, lowercased, a retired server renamed, empty → the default.
String cleanEpicbox(String? domain) {
  final d = (domain ?? '').trim().toLowerCase();
  if (d.isEmpty) return guiDefaultEpicbox;
  return _epicboxRenamed[d] ?? d;
}

/// setupDefaults.js supportedLocale with 6.1.6's languages: a code it offers, else 'en'.
String guiSupportedLocale(String lang) => guiLocales.contains(lang) ? lang : 'en';

/// settingsStore.js LABEL_MAX and cleanLabel: control characters become a space, direction marks
/// and overrides are dropped, trimmed, at most [max] code points.
const int guiLabelMax = 32;
String cleanGuiLabel(String label, {int max = guiLabelMax}) {
  final s = label
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f-\u009f]+'), ' ')
      .replaceAll(RegExp(r'[\u200e\u200f\u202a-\u202e\u2066-\u2069]'), '')
      .trim();
  final runes = s.runes.toList();
  return String.fromCharCodes(runes.length > max ? runes.sublist(0, max) : runes).trim();
}

/// myNodes.js NODE_LABEL_MAX and MY_NODES_MAX.
const int guiNodeLabelMax = 40;
const int guiMyNodesMax = 50;

/// nodeAddress.js nodeFieldAddress.
String nodeFieldAddress(String text) {
  var s = text.trim();
  if (s.isNotEmpty && !_hasScheme.hasMatch(s)) s = '${isPrivateHost(_hostOf(s)) ? 'http' : 'https'}://$s';
  return _trimSlashes(s);
}

/// nodeAddress.js nodeCheckAddress(text, {complete: false}): a plain http(s) node address, or ''.
String nodeCheckAddress(String text) {
  final s = nodeFieldAddress(text);
  if (s.isEmpty || s.length > 300) return '';
  final u = _Url.parse(s);
  if (u == null || (u.scheme != 'http' && u.scheme != 'https') || u.host.isEmpty || u.hasUser || u.hasQuery) return '';
  return s;
}

/// nodeAddress.js nodeAddressKey: the same node however it is written.
String nodeAddressKey(String text) {
  final s = nodeCheckAddress(text);
  if (s.isEmpty) return '';
  final u = _Url.parse(s)!;
  return '${u.scheme}://${u.authority}${_trimSlashes(u.path)}';
}
