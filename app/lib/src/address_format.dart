// SPDX-License-Identifier: Apache-2.0
/// How an address is shown in a list: the first six and last six characters of the part people
/// check when reading an address out, the kind kept. Pure Dart, shared by the phone and the
/// desktop. The full address stays in tooltips, detail views and what Copy copies.
library;

String _mid(String x) =>
    x.length <= 14 ? x : '${x.substring(0, 6)}…${x.substring(x.length - 6)}';

/// First six and last six of the checked part, kind kept. [compact] drops the kind part
/// (`@host`, `.onion`, `http(s)://`) for a cell that sits next to a kind tag. Only cuts: case
/// is kept and an already short form comes back unchanged.
String shortAddress(String address, {bool compact = false}) {
  final t = address.trim();
  final lower = t.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    final schemeEnd = t.indexOf('://') + 3;
    final scheme = t.substring(0, schemeEnd);
    final rest = t.substring(schemeEnd);
    final cut = rest.indexOf(RegExp(r'[/?#]'));
    final authority = cut < 0 ? rest : rest.substring(0, cut);
    final path = cut < 0 ? '' : rest.substring(cut);
    final colon = authority.startsWith('[') ? -1 : authority.lastIndexOf(':');
    final host = colon < 0 ? authority : authority.substring(0, colon);
    final port = colon < 0 ? '' : authority.substring(colon);
    final tail = path.isEmpty || path == '/' ? '' : '/…';
    // An onion host is shortened as a bare onion address is: its 56 characters never fit a row.
    final shown = host.toLowerCase().endsWith('.onion')
        ? '${_mid(host.substring(0, host.length - 6))}${host.substring(host.length - 6)}'
        : (host.length > 32 ? _mid(host) : host);
    return '${compact ? '' : scheme}$shown$port$tail';
  }
  if (lower.endsWith('.onion')) {
    return '${_mid(t.substring(0, t.length - 6))}${compact ? '' : '.onion'}';
  }
  final at = t.indexOf('@');
  final key = at < 0 ? t : t.substring(0, at);
  final host = at < 0 ? '' : t.substring(at);
  return '${_mid(key)}${compact ? '' : host}';
}

/// The rail's host line: when [host] has three or more labels and the first equals [rowName]
/// (case-insensitive) that label is dropped, since the row's name already says it.
/// `railHost('Epicbox', 'epicbox.stackwallet.com')` is `stackwallet.com`.
String railHost(String rowName, String host) {
  final labels = host.split('.');
  if (labels.length >= 3 && labels.first.toLowerCase() == rowName.toLowerCase()) {
    return labels.skip(1).join('.');
  }
  return host;
}

/// A server's name for a one-line summary: [host] (or a node URL) without its port, scheme and
/// first label when it has three or more, so `node.btlabs.uk:3413` and `epicbox.epiccash.com`
/// read `btlabs.uk` and `epiccash.com`. An IP address or a two-label name stays as it is.
String shortHost(String host) {
  var h = host.trim().toLowerCase();
  if (h.contains('://')) h = Uri.tryParse(h)?.host ?? h;
  final colon = h.lastIndexOf(':');
  if (colon > 0 && h.indexOf(':') == colon) h = h.substring(0, colon);
  final labels = h.split('.');
  final ip = labels.length == 4 && labels.every((l) => int.tryParse(l) != null);
  return labels.length >= 3 && !ip ? labels.skip(1).join('.') : h;
}
