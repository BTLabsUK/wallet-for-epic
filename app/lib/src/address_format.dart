// SPDX-License-Identifier: Apache-2.0
/// How an address or a server is shown, on the phone and the desktop alike. Display only: what
/// is parsed, copied and sent is always the address as it was given.
///
/// The rules:
/// - Every key, host, port and path is in the mono face; words ("Local node") are not.
/// - An Epicbox address marks the first six and last six characters of its key and breaks only
///   before its "@": the server stays whole on its own line. An onion's 56-character name is a
///   key too: its ends are marked, `.onion` quiet after it.
/// - A Link address (`http(s)://host:port/path`) marks host:port as one token and never breaks
///   inside it; the scheme and the path are quiet.
/// - A server is shown as host:port ([hostPort]); the full URL only inside an editable field.
/// - Scheme and host are shown in lower case ([displayCase]); a key keeps its case.
///
/// In a list an address is shortened to the first six and last six characters of the part
/// people check ([shortAddress]). The full address stays in tooltips, detail views and what
/// Copy copies.
library;

import 'package:flutter/painting.dart' show TextSpan, TextStyle;

/// How a part of an address is drawn.
enum AddressTone {
  /// What a reader checks: a key's first and last six characters, a link's host:port.
  mark,

  /// The middle of a key.
  plain,

  /// What says the kind: a link's scheme and path, an Epicbox `@server`, `.onion`.
  quiet,
}

/// One run of an address with one tone ([addressParts]).
final class AddressPart {
  const AddressPart(this.text, this.tone, {this.lineStart = false, this.whole = false});

  final String text;
  final AddressTone tone;

  /// A line may start here: before an Epicbox `@server` and before a link's path. Besides
  /// inside a key, the only place where an address breaks.
  final bool lineStart;

  /// Never split across lines: a host:port, an `@server`, `.onion`, a scheme.
  final bool whole;

  @override
  bool operator ==(Object other) =>
      other is AddressPart && other.text == text && other.tone == tone && other.lineStart == lineStart && other.whole == whole;

  @override
  int get hashCode => Object.hash(text, tone, lineStart, whole);

  @override
  String toString() => '${tone.name}${lineStart ? '|' : ''}${whole ? '!' : ''}($text)';
}

final RegExp _schemePrefix = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');
final RegExp _onionName = RegExp(r'^[a-zA-Z2-7]{56}$');
final RegExp _bareOnion = RegExp(r'^[a-zA-Z2-7]{56}\.onion(?::\d*)?/?$', caseSensitive: false);

/// [s] with the ASCII letters A–Z in lower case and nothing else changed, so its length stays.
String _lowerAscii(String s) =>
    String.fromCharCodes(s.codeUnits.map((c) => c >= 0x41 && c <= 0x5a ? c + 0x20 : c));

/// [text] as it is shown: a link's scheme and host:port in lower case (its user part and path
/// kept), and a bare onion address in lower case. Anything else, an Epicbox key above all
/// (its case is part of it), comes back unchanged. Only ASCII letters change, so the length
/// stays: a field can draw it over what was typed with the cursor and selection in place.
/// Display only, never what is parsed or sent ([parseRecipient] reads the text as typed).
String displayCase(String text) {
  final lead = text.length - text.trimLeft().length;
  final t = text.substring(lead);
  final scheme = _schemePrefix.matchAsPrefix(t);
  if (scheme != null) {
    final rest = t.substring(scheme.end);
    final cut = rest.indexOf(RegExp(r'[/?#]'));
    final authority = cut < 0 ? rest : rest.substring(0, cut);
    final at = authority.lastIndexOf('@');
    final user = authority.substring(0, at + 1);
    final host = authority.substring(at + 1);
    return '${text.substring(0, lead)}${_lowerAscii(scheme[0]!)}$user${_lowerAscii(host)}${rest.substring(authority.length)}';
  }
  if (_bareOnion.hasMatch(t.trimRight())) return _lowerAscii(text);
  return text;
}

/// A key: its first six and last six characters marked, the middle plain; a key of 12 or
/// fewer characters marked whole.
List<AddressPart> _keyParts(String key) => key.length <= 12
    ? [AddressPart(key, AddressTone.mark)]
    : [
        AddressPart(key.substring(0, 6), AddressTone.mark),
        AddressPart(key.substring(6, key.length - 6), AddressTone.plain),
        AddressPart(key.substring(key.length - 6), AddressTone.mark),
      ];

/// A link's host:port: one marked token, or an onion's name as a key with `.onion` (and a port)
/// quiet after it.
List<AddressPart> _hostParts(String host) {
  final i = host.indexOf('.onion');
  if (i > 0 && _onionName.hasMatch(host.substring(0, i))) {
    return [..._keyParts(host.substring(0, i)), AddressPart(host.substring(i), AddressTone.quiet, whole: true)];
  }
  return [AddressPart(host, AddressTone.mark, whole: true)];
}

/// [address] in its parts, each with its tone, in the case it is shown ([displayCase]), the
/// text of the parts together being the address shown. See the rules at the top of this file.
/// Whitespace around it is left out.
List<AddressPart> addressParts(String address) {
  final a = displayCase(address.trim());
  final List<AddressPart> parts;
  final scheme = _schemePrefix.matchAsPrefix(a);
  final at = a.indexOf('@');
  if (scheme != null) {
    final rest = a.substring(scheme.end);
    final cut = rest.indexOf(RegExp(r'[/?#]'));
    final authority = cut < 0 ? rest : rest.substring(0, cut);
    final path = cut < 0 ? '' : rest.substring(cut);
    final userEnd = authority.lastIndexOf('@') + 1;
    parts = [
      AddressPart('${scheme[0]}${authority.substring(0, userEnd)}', AddressTone.quiet, whole: true),
      ..._hostParts(authority.substring(userEnd)),
      if (path.isNotEmpty) AddressPart(path, AddressTone.quiet, lineStart: path.length > 1, whole: path.length == 1),
    ];
  } else if (_bareOnion.hasMatch(a)) {
    parts = _hostParts(a);
  } else if (at > 0) {
    parts = [
      ..._keyParts(a.substring(0, at)),
      AddressPart(_lowerAscii(a.substring(at)), AddressTone.quiet, lineStart: true, whole: true),
    ];
  } else if (a.contains('.') || a.contains(':')) {
    // A host or host:port without a scheme (a key never has either).
    parts = [AddressPart(_lowerAscii(a), AddressTone.mark, whole: true)];
  } else {
    parts = _keyParts(a);
  }
  return [for (final p in parts) if (p.text.isNotEmpty) p];
}

/// The word joiner (U+2060): no line break on either side of it.
const String wordJoiner = '\u2060';

/// The zero-width space (U+200B): a line may break here.
const String zeroWidthSpace = '\u200B';

/// [s] with a [wordJoiner] between each two characters, so a line never breaks inside it. For
/// text that is only drawn (a share picture, a label whose [Semantics] carries the address),
/// never for text that is selected, copied or typed: the joiners would go with it.
String unbroken(String s) => String.fromCharCodes(
  [for (final (i, r) in s.runes.indexed) ...[if (i > 0) 0x2060, r]],
);

/// [parts] as a span, each in its tone's style over [style]. With [joined] (drawn-only text,
/// see [unbroken]) a whole part never breaks and a line may break only before a [lineStart]
/// part or inside a key; without it the text is exactly the parts' text, safe to select.
TextSpan addressPartsSpan(
  Iterable<AddressPart> parts, {
  TextStyle? style,
  required TextStyle mark,
  TextStyle? plain,
  required TextStyle quiet,
  bool joined = false,
}) => TextSpan(
  style: style,
  children: [
    for (final p in parts)
      TextSpan(
        text: !joined ? p.text : '${p.lineStart ? zeroWidthSpace : wordJoiner}${p.whole ? unbroken(p.text) : p.text}',
        style: switch (p.tone) {
          AddressTone.mark => mark,
          AddressTone.plain => plain,
          AddressTone.quiet => quiet,
        },
      ),
  ],
);

/// [address] as a span in its parts ([addressParts], [addressPartsSpan]).
TextSpan addressSpan(String address, {TextStyle? style, required TextStyle mark, TextStyle? plain, required TextStyle quiet, bool joined = false}) =>
    addressPartsSpan(addressParts(address), style: style, mark: mark, plain: plain, quiet: quiet, joined: joined);

/// [parts] in lines: a new line at each [AddressPart.lineStart] part. An Epicbox address is
/// `[key, @server]`, a link with a path `[scheme host:port, /path]`, anything else one line.
List<List<AddressPart>> addressLines(List<AddressPart> parts) {
  final lines = <List<AddressPart>>[];
  for (final p in parts) {
    if (lines.isEmpty || p.lineStart) lines.add([]);
    lines.last.add(p);
  }
  return lines;
}

/// A server or node URL as it is shown: `host:port`, lower case, without the scheme, the path or
/// a user part; the port when the URL names one other than its scheme's own (80 for http, 443
/// for https). A text with no host comes back trimmed. `https://Node.Example.org:<port>/` is
/// `node.example.org:<port>`, `https://node.example.org:443` is `node.example.org`,
/// `http://[::1]:<port>` is `[::1]:<port>`. The full URL is only shown inside the field that edits
/// it.
String hostPort(String url) {
  final t = url.trim();
  // Uri would percent-encode a space into a host: words are no address.
  if (t.contains(RegExp(r'\s'))) return t;
  final schemed = _schemePrefix.hasMatch(t);
  final uri = Uri.tryParse(schemed ? t : 'http://$t');
  if (uri == null || uri.host.isEmpty) return t;
  final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
  // Uri gives the scheme's default port when none is written: only a written one is shown.
  final port = _writtenPort.firstMatch(t)?[1];
  final scheme = uri.scheme.toLowerCase();
  final own = schemed && ((scheme == 'http' && port == '80') || (scheme == 'https' && port == '443'));
  return _lowerAscii(port == null || own ? host : '$host:$port');
}

final RegExp _writtenPort = RegExp(r'^(?:[a-zA-Z][a-zA-Z0-9+.-]*://)?(?:[^@/?#]*@)?(?:\[[^\]]*\]|[^:/?#]*):(\d+)');

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

/// [url] as people read it: without the scheme and a closing slash (`https://example.org/` is
/// `example.org`).
String shownUrl(String url) => url.replaceFirst(RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false), '').replaceFirst(RegExp(r'/$'), '');

/// The rail's host line: when [host] has three or more labels and the first equals [rowName]
/// (case-insensitive) that label is dropped, since the row's name already says it.
/// `railHost('Epicbox', 'epicbox.example.org')` is `example.org`.
String railHost(String rowName, String host) {
  final labels = host.split('.');
  if (labels.length >= 3 && labels.first.toLowerCase() == rowName.toLowerCase()) {
    return labels.skip(1).join('.');
  }
  return host;
}

/// A server's name for a one-line summary: [host] (or a node URL) without its port, scheme and
/// first label when it has three or more, so `node.example.org:<port>` and `epicbox.example.net`
/// read `example.org` and `example.net`. An IP address or a two-label name stays as it is.
String shortHost(String host) {
  var h = host.trim().toLowerCase();
  if (h.contains('://')) h = Uri.tryParse(h)?.host ?? h;
  final colon = h.lastIndexOf(':');
  if (colon > 0 && h.indexOf(':') == colon) h = h.substring(0, colon);
  final labels = h.split('.');
  final ip = labels.length == 4 && labels.every((l) => int.tryParse(l) != null);
  return labels.length >= 3 && !ip ? labels.skip(1).join('.') : h;
}
