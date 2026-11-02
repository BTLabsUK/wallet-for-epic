// SPDX-License-Identifier: Apache-2.0
/// Send's one recipient field: what typed, pasted or scanned text is (an Epicbox address, an
/// onion, an http(s) wallet address, a transaction text, or just words), the address in its
/// clean form with a note for each thing the clean-up changed, the host exactly as it will be
/// contacted, and what the network mode holds. The method follows from the address; there is
/// no method picker. Pure Dart, shared by the phone and desktop screens, also on the web.
///
/// Rules (the approved Send design):
/// - No scheme: a name gets `https://`; an IP address, `localhost`, a `.local` name or an IPv6
///   address gets `http://`, with the listener's default port when none is given.
/// - Only `http` and `https`. No user part, no control characters; `?…` and `#…` are left out
///   (LEPIC's ForeignUrl refuses `?`, `#`, `@` and whitespace). An international name is sent
///   and shown in its ASCII (punycode) form, the one that is contacted.
/// - A contact's first address: Epicbox, then https, then Tor, then plain http, skipping any the
///   mode holds ([bestAddressIndex]).
/// - Plain http with the Tor switch on (Normal): this device and the local network go direct,
///   an internet address is held ([SendHold.torOnPlainHttp]). Tor only holds plain http to
///   anything but this device.
library;

import 'advanced.dart' show NetworkMode;
import 'net/local_address.dart' show isLocalIpBytes;
import 'network_gate.dart' show NetGate, plainHttpOffNow;
import 'recipient.dart' show Recipient, RecipientKind, plainHttpToOtherDevice;
import 'wallet_service.dart' show onionAddressFormat, onionHost;

/// Longest clean address Send takes (an Epicbox address is about 70 characters, a wallet URL
/// rarely over 100).
const int recipientMaxLength = 512;

/// Longest text read as a recipient at all; a transaction text is recognised before this.
const int recipientInputMaxLength = 4096;

/// What [readRecipient] found.
enum RecipientInputKind {
  /// Nothing, or only whitespace.
  empty,

  /// `key@relay`.
  epicbox,

  /// `<56 characters>.onion`: Link · Tor.
  onion,

  /// `https://…`: Link · HTTPS.
  https,

  /// `http://…`: Link · HTTP.
  http,

  /// A slatepack or a slate's JSON: a transaction text to open, not an address.
  slate,

  /// Words that are no address: a contact's name, or nothing at all ([RecipientInput.problem]
  /// is [RecipientProblem.notAddress] then, for the screen to show once no contact matches).
  text,

  /// An address that cannot be paid as it is: [RecipientInput.problem] says why.
  invalid,
}

/// Each thing the clean-up changed, in the order it happened.
enum RecipientNote {
  /// Text around one address was left out.
  textAround,

  /// An address split by spaces or line breaks was joined.
  joined,

  /// Spaces or invisible characters inside or around it were removed.
  spaces,

  /// Quotes or brackets around it were removed.
  quotes,

  /// An onion written another way (`http://`, a port, upper case) in its standard form.
  onionForm,

  /// `epicbox://` left out.
  epicboxScheme,

  /// No relay after the key: the default one ([RecipientInput.host]).
  defaultRelay,

  /// The relay in lower case.
  relayLower,

  /// No scheme: `https://` added.
  httpsAdded,

  /// No scheme: `http://` added.
  httpAdded,

  /// No port: the listener's default ([RecipientInput.port]).
  defaultPort,

  /// A bare IPv6 address put in brackets.
  brackets,

  /// `HTTP://` in lower case.
  schemeLower,

  /// The host in lower case.
  hostLower,

  /// An international name written in its ASCII form, as it is contacted.
  idn,

  /// `/v2/foreign` left out: the wallet adds it.
  foreignPath,

  /// A trailing `/` left out.
  trailingSlash,

  /// `?…` or `#…` left out.
  queryLeftOut,
}

/// Why a text is not an address Send can pay.
enum RecipientProblem {
  /// No address shape, and (the screen decides) no contact has this name.
  notAddress,

  /// A scheme other than http, https or epicbox.
  otherScheme,

  /// Half an address (`http://192.168.`, a name without a dot, a short key).
  incomplete,

  /// Something with `.onion` that is not a whole Tor address.
  onionIncomplete,

  /// A port outside 1–65535.
  badPort,

  /// A user name or password in the address (`user@host`).
  credentials,

  /// Characters an address cannot hold (control characters, `@` in the path).
  badCharacters,

  /// Longer than [recipientMaxLength].
  tooLong,
}

/// Where an http(s) host is, by its literal form (no lookup).
enum HostScope {
  /// `localhost`, 127.0.0.0/8, ::1.
  thisDevice,

  /// A private or link-local address (10/8, 172.16/12, 192.168/16, 169.254/16, fc00::/7,
  /// fe80::/10) or a `.local` name.
  network,

  /// Anything else: a public address or a name.
  internet,
}

/// What the network mode holds a send to an address with.
enum SendHold {
  /// Kill switch: nothing connects.
  killSwitch,

  /// Node only: only the node connects.
  nodeOnly,

  /// Tor only: plain http to another device cannot go over Tor.
  torOnlyPlainHttp,

  /// The Tor switch is on (Normal): plain http to an internet address cannot go over Tor.
  torOnPlainHttp,
}

/// The fix a [SendHold] offers: the one action that lifts it.
enum SendHoldFix {
  /// Network mode back to Normal.
  normalMode,

  /// The Tor switch off.
  torOff,
}

extension SendHoldWays on SendHold {
  SendHoldFix get fix => this == SendHold.torOnPlainHttp ? SendHoldFix.torOff : SendHoldFix.normalMode;

  /// Nothing connects, so Pay in person and Pay with a file are offered beside the fix.
  bool get offersDirect => this == SendHold.killSwitch || this == SendHold.nodeOnly;
}

/// A recipient as Send reads it.
class RecipientInput {
  const RecipientInput._(
    this.kind, {
    this.address = '',
    this.notes = const [],
    this.problem,
    this.host = '',
    this.port,
    this.path = '',
    this.scope = HostScope.internet,
    this.unicodeHost,
    this.key,
  });

  static const empty = RecipientInput._(RecipientInputKind.empty);

  final RecipientInputKind kind;

  /// The clean address: `key@relay`, `<56>.onion`, or `scheme://host[:port][/path]` with the
  /// host in its ASCII form. The text as given (trimmed) for [RecipientInputKind.text],
  /// [RecipientInputKind.slate] and [RecipientInputKind.invalid].
  final String address;

  /// What the clean-up changed; empty when [address] is the text as given.
  final List<RecipientNote> notes;

  /// Set for [RecipientInputKind.invalid] (and [RecipientProblem.notAddress] for words).
  final RecipientProblem? problem;

  /// The host contacted: the Epicbox relay (as written after `@`), the onion, or the URL's host
  /// in lower-case ASCII, IPv6 without brackets.
  final String host;

  /// The port contacted: as given, else 443 for https, the listener's default for http and 80
  /// for an onion. Null for Epicbox.
  final int? port;

  /// The URL's path without a trailing `/`, or empty.
  final String path;

  /// Where an http(s) host is ([HostScope.internet] for every other kind).
  final HostScope scope;

  /// The name as typed, when it was an international one ([RecipientNote.idn]).
  final String? unicodeHost;

  /// The Epicbox key (the part before `@`).
  final String? key;

  /// An address of a kind Send can pay (Epicbox, onion, http or https).
  bool get isAddress => switch (kind) {
    RecipientInputKind.epicbox || RecipientInputKind.onion || RecipientInputKind.https || RecipientInputKind.http => true,
    _ => false,
  };

  bool get isLink => kind == RecipientInputKind.https || kind == RecipientInputKind.http || kind == RecipientInputKind.onion;

  bool get isUrl => kind == RecipientInputKind.https || kind == RecipientInputKind.http;

  /// Plain http to another device (not encrypted): the review says so.
  bool get plainHttpToOther => kind == RecipientInputKind.http && scope != HostScope.thisDevice;

  /// The host in brackets when it is an IPv6 address.
  String get hostShown => host.contains(':') ? '[$host]' : host;

  /// `host:port` as contacted, for the review's Host row.
  String get contacted => port == null ? hostShown : '$hostShown:$port';

  /// The address for the wallet, as the rest of the app keeps it.
  Recipient? get recipient => switch (kind) {
    RecipientInputKind.epicbox => Recipient(RecipientKind.epicbox, address),
    RecipientInputKind.onion => Recipient(RecipientKind.tor, address),
    RecipientInputKind.https || RecipientInputKind.http => Recipient(RecipientKind.http, address),
    _ => null,
  };
}

// --------------------------------------------------------------------------------------------
// Reading the text

final RegExp _b58 = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$');
final RegExp _ws = RegExp(r'\s+');

/// Zero-width and other invisible characters chat apps add (ZWSP, ZWNJ, ZWJ, word joiner, BOM,
/// soft hyphen).
final RegExp _invisible = RegExp('[\u200B\u200C\u200D\u2060\uFEFF\u00AD]');

/// Control characters other than whitespace: never part of an address.
final RegExp _control = RegExp('[\u0000-\u0008\u000E-\u001F\u007F]');

final RegExp _schemeAny = RegExp(r'^[a-z][a-z0-9+.\-]*://', caseSensitive: false);
final RegExp _httpScheme = RegExp(r'^https?://', caseSensitive: false);

/// A transaction text: a slatepack, or a slate's JSON.
bool _isSlate(String t) =>
    RegExp(r'BEGINSLATEPACK', caseSensitive: false).hasMatch(t) ||
    (t.startsWith('{') && RegExp(r'"(version_info|num_participants|ver)"').hasMatch(t));

String _trimPunct(String w) => w
    .replaceFirst(RegExp('^[<("\'“‘«„]+'), '')
    .replaceFirst(RegExp('[>)"\'”’».,;!?]+\$'), '');

bool _isIPv4(String h) {
  if (!RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(h)) return false;
  return h.split('.').every((n) => int.parse(n) <= 255);
}

/// A bare IPv6 address (no brackets): hex groups and at least two colons.
bool _isBareV6(String h) => RegExp(r'^[0-9a-f:.]+$', caseSensitive: false).hasMatch(h) && ':'.allMatches(h).length >= 2 && _v6Bytes(h) != null;

List<int>? _v6Bytes(String h) {
  try {
    return Uri.parseIPv6Address(h);
  } on FormatException {
    return null;
  }
}

/// A host name with a dot and a top-level label of letters (or a punycode one).
bool _nameShape(String h) {
  final labels = h.split('.');
  if (labels.length < 2 || labels.any((x) => x.isEmpty)) return false;
  final tld = labels.last;
  return RegExp(r'^(\p{L}{2,}|xn--[a-z0-9\-]+)$', unicode: true, caseSensitive: false).hasMatch(tld);
}

/// One word that has the look of an address: worth lifting out of the text around it.
bool _looksAddress(String w) {
  if (w.isEmpty) return false;
  if (w.contains('://')) return true;
  if (RegExp(r'\.onion\b', caseSensitive: false).hasMatch(w)) return true;
  if (RegExp(r'^[a-z2-7]{56}$', caseSensitive: false).hasMatch(w)) return true;
  final key = w.split('@').first;
  if (key.length >= 40 && _b58.hasMatch(key)) return true;
  final hostPart = w.replaceFirst(RegExp(r'/.*$'), '');
  if (RegExp(r'^\[[0-9a-f:.]+\](:\d+)?$', caseSensitive: false).hasMatch(hostPart)) return true;
  if (_isBareV6(hostPart)) return true;
  final m = RegExp(r'^([^:/\[\]@]+)(:\d+)?$').firstMatch(hostPart);
  if (m == null) return false;
  final h = m[1]!.toLowerCase();
  return _isIPv4(h) || h == 'localhost' || _nameShape(h);
}

/// Reads [raw] as Send's recipient. [defaultRelay] is the Epicbox relay in use (for a bare
/// key), [listenPort] the Link · HTTP listener's default port.
RecipientInput readRecipient(String raw, {required String defaultRelay, required int listenPort}) {
  final notes = <RecipientNote>[];
  var t = raw.replaceAll(_invisible, '');
  if (t.length != raw.length) notes.add(RecipientNote.spaces);
  t = t.trim();
  if (t.isEmpty) return RecipientInput.empty;
  if (_isSlate(t)) return RecipientInput._(RecipientInputKind.slate, address: t);
  if (t.length > recipientInputMaxLength) return _invalid(t, RecipientProblem.tooLong);
  if (_control.hasMatch(t)) return _invalid(t, RecipientProblem.badCharacters);

  // Text around one address: keep the address. An address split by spaces: join it.
  final words = t.split(_ws);
  if (words.length > 1) {
    final candidates = words.map(_trimPunct).where(_looksAddress).toList();
    if (candidates.length == 1) {
      t = candidates.single;
      notes.add(RecipientNote.textAround);
    } else {
      final joined = words.join();
      if (_looksAddress(_trimPunct(joined))) {
        t = joined;
        notes.add(RecipientNote.joined);
      } else {
        return RecipientInput._(RecipientInputKind.text, address: t, problem: RecipientProblem.notAddress);
      }
    }
  }
  final unquoted = _trimPunct(t);
  if (unquoted != t) {
    if (!notes.contains(RecipientNote.textAround)) notes.add(RecipientNote.quotes);
    t = unquoted;
  }
  if (t.isEmpty) return RecipientInput._(RecipientInputKind.text, address: raw.trim(), problem: RecipientProblem.notAddress);

  // An onion, in any of its forms (before URLs: http://<onion> goes over Tor).
  if (onionAddressFormat(t)) {
    final norm = onionHost(t);
    if (norm != t) notes.add(RecipientNote.onionForm);
    return RecipientInput._(RecipientInputKind.onion, address: norm, host: norm, port: 80, notes: notes);
  }
  if (RegExp(r'\.onion\b', caseSensitive: false).hasMatch(t)) return _invalid(t, RecipientProblem.onionIncomplete);

  // Epicbox.
  if (t.toLowerCase().startsWith('epicbox://')) {
    t = t.substring('epicbox://'.length);
    notes.add(RecipientNote.epicboxScheme);
  }
  if (!t.contains('://')) {
    final at = t.split('@');
    if (at.length <= 2 && _b58.hasMatch(at.first) && at.first.length >= 40) {
      final key = at.first;
      var relay = at.length == 2 ? at[1] : '';
      if (relay.isEmpty) {
        relay = defaultRelay;
        notes.add(RecipientNote.defaultRelay);
      } else if (relay != relay.toLowerCase()) {
        relay = relay.toLowerCase();
        notes.add(RecipientNote.relayLower);
      }
      if (!RegExp(r'^[a-z0-9.\-]+(:\d{1,5})?$').hasMatch(relay)) return _invalid(t, RecipientProblem.incomplete);
      final norm = '$key@$relay';
      if (norm.length > recipientMaxLength) return _invalid(t, RecipientProblem.tooLong);
      return RecipientInput._(RecipientInputKind.epicbox, address: norm, host: relay.split(':').first, key: key, notes: notes);
    }
    // The start of a key, still being typed or cut short.
    if (at.length == 1 && t.length >= 16 && t.startsWith('es') && _b58.hasMatch(t)) return _invalid(t, RecipientProblem.incomplete);
  }

  // URLs, with or without a scheme.
  if (_schemeAny.hasMatch(t) && !_httpScheme.hasMatch(t)) return _invalid(t, RecipientProblem.otherScheme);
  var s = t;
  if (!_httpScheme.hasMatch(s)) {
    if (_isBareV6(s)) {
      s = '[${s.toLowerCase()}]';
      notes.add(RecipientNote.brackets);
    }
    final m = RegExp(r'^(\[[0-9a-fA-F:.]+\]|[^\s/:?#\[\]@]+)(:\d*)?([/?#].*)?$').firstMatch(s);
    if (m == null) {
      if (s.contains('@')) return _invalid(t, RecipientProblem.credentials);
      return RecipientInput._(RecipientInputKind.text, address: raw.trim(), problem: RecipientProblem.notAddress);
    }
    final h = m[1]!;
    final bare = h.startsWith('[') ? h.substring(1, h.length - 1) : h.toLowerCase();
    final lan = h.startsWith('[') || _isIPv4(bare) || bare == 'localhost' || bare.endsWith('.local');
    if (!lan && !_nameShape(bare)) {
      // Digits and dots that are not four parts: half an IP address.
      if (RegExp(r'^[\d.]+$').hasMatch(bare) && bare.contains('.')) return _invalid(t, RecipientProblem.incomplete);
      return RecipientInput._(RecipientInputKind.text, address: raw.trim(), problem: RecipientProblem.notAddress);
    }
    if (lan) {
      notes.add(RecipientNote.httpAdded);
      final port = m[2];
      if (port == null || port == ':') {
        s = 'http://$h:$listenPort${m[3] ?? ''}';
        notes.add(RecipientNote.defaultPort);
      } else {
        s = 'http://$s';
      }
    } else {
      s = 'https://$s';
      notes.add(RecipientNote.httpsAdded);
    }
  } else if (s.substring(0, s.indexOf(':')) != s.substring(0, s.indexOf(':')).toLowerCase()) {
    notes.add(RecipientNote.schemeLower);
  }
  return _readUrl(s, t, notes, listenPort);
}

RecipientInput _invalid(String t, RecipientProblem p) => RecipientInput._(RecipientInputKind.invalid, address: t, problem: p);

RecipientInput _readUrl(String s, String given, List<RecipientNote> notes, int listenPort) {
  final m = RegExp(r'^(https?)://([^/?#]*)([^?#]*)(\?[^#]*)?(#.*)?$', caseSensitive: false).firstMatch(s);
  if (m == null) return _invalid(given, RecipientProblem.incomplete);
  final scheme = m[1]!.toLowerCase();
  final authority = m[2]!;
  if (authority.contains('@')) return _invalid(given, RecipientProblem.credentials);
  if (authority.isEmpty) return _invalid(given, RecipientProblem.incomplete);

  // Host and port.
  String rawHost;
  String? portText;
  if (authority.startsWith('[')) {
    final close = authority.indexOf(']');
    if (close < 0) return _invalid(given, RecipientProblem.incomplete);
    rawHost = authority.substring(1, close);
    final rest = authority.substring(close + 1);
    if (rest.isNotEmpty) {
      if (!rest.startsWith(':')) return _invalid(given, RecipientProblem.incomplete);
      portText = rest.substring(1);
    }
  } else {
    final colon = authority.lastIndexOf(':');
    rawHost = colon < 0 ? authority : authority.substring(0, colon);
    if (colon >= 0) portText = authority.substring(colon + 1);
  }
  int? port;
  if (portText != null && portText.isNotEmpty) {
    if (!RegExp(r'^\d+$').hasMatch(portText)) return _invalid(given, RecipientProblem.incomplete);
    port = portText.length > 5 ? 0 : int.parse(portText);
    if (port < 1 || port > 65535) return _invalid(given, RecipientProblem.badPort);
  }

  String host;
  String? unicodeHost;
  final v6 = authority.startsWith('[');
  if (v6) {
    final zone = rawHost.indexOf('%');
    final bytes = _v6Bytes(zone < 0 ? rawHost : rawHost.substring(0, zone));
    if (bytes == null || zone >= 0) return _invalid(given, RecipientProblem.incomplete);
    host = rawHost.toLowerCase();
  } else {
    final lower = rawHost.toLowerCase();
    if (lower.isEmpty || lower.endsWith('.') || lower.startsWith('.')) return _invalid(given, RecipientProblem.incomplete);
    if (RegExp(r'^[\d.]+$').hasMatch(lower)) {
      if (!_isIPv4(lower)) return _invalid(given, RecipientProblem.incomplete);
      host = lower;
    } else {
      if (lower != 'localhost' && !_nameShape(lower)) return _invalid(given, RecipientProblem.incomplete);
      final labels = lower.split('.');
      final ascii = <String>[];
      for (final label in labels) {
        if (label.length > 63 || label.startsWith('-') || label.endsWith('-')) return _invalid(given, RecipientProblem.incomplete);
        if (!RegExp(r'^[\p{L}\p{N}\p{M}\-_]+$', unicode: true).hasMatch(label)) return _invalid(given, RecipientProblem.badCharacters);
        if (RegExp(r'^[a-z0-9\-_]+$').hasMatch(label)) {
          ascii.add(label);
        } else {
          final encoded = _punycode(label);
          if (encoded == null) return _invalid(given, RecipientProblem.badCharacters);
          ascii.add('xn--$encoded');
        }
      }
      host = ascii.join('.');
      if (host != lower) {
        unicodeHost = lower;
        notes.add(RecipientNote.idn);
      }
      if (host.length > 253) return _invalid(given, RecipientProblem.tooLong);
    }
    if (rawHost != lower && !notes.contains(RecipientNote.idn)) notes.add(RecipientNote.hostLower);
  }

  // Path: /v2/foreign is the wallet's own; a trailing / goes; ? and # are left out.
  var path = m[3]!;
  if (RegExp(r'^/v2/foreign/?$', caseSensitive: false).hasMatch(path)) {
    path = '';
    notes.add(RecipientNote.foreignPath);
  } else if (path.endsWith('/')) {
    path = path.replaceFirst(RegExp(r'/+$'), '');
    notes.add(RecipientNote.trailingSlash);
  }
  if (path.isNotEmpty && !RegExp(r'^(/[A-Za-z0-9\-._~%!$&()*+,;=:]+)+$').hasMatch(path)) {
    return _invalid(given, RecipientProblem.badCharacters);
  }
  if (m[4] != null || m[5] != null) notes.add(RecipientNote.queryLeftOut);

  final shown = v6 ? '[$host]' : host;
  final norm = '$scheme://$shown${port == null ? '' : ':$port'}$path';
  if (norm.length > recipientMaxLength) return _invalid(given, RecipientProblem.tooLong);
  return RecipientInput._(
    scheme == 'https' ? RecipientInputKind.https : RecipientInputKind.http,
    address: norm,
    host: host,
    port: port ?? (scheme == 'https' ? 443 : listenPort),
    path: path,
    scope: hostScope(host),
    unicodeHost: unicodeHost,
    notes: notes,
  );
}

/// Where [host] (a URL's host, IPv6 with or without brackets) is, without a lookup.
HostScope hostScope(String host) {
  var h = host.trim().toLowerCase();
  if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
  if (h == 'localhost' || h.endsWith('.localhost')) return HostScope.thisDevice;
  if (h.endsWith('.local')) return HostScope.network;
  List<int>? bytes;
  if (h.contains(':')) {
    bytes = _v6Bytes(h);
  } else if (_isIPv4(h)) {
    bytes = Uri.parseIPv4Address(h);
  }
  if (bytes == null) return HostScope.internet;
  final loopback = bytes.length == 4
      ? bytes[0] == 127
      : (bytes.sublist(0, 15).every((b) => b == 0) && bytes[15] == 1) ||
            (bytes.sublist(0, 10).every((b) => b == 0) && bytes[10] == 0xff && bytes[11] == 0xff && bytes[12] == 127);
  if (loopback) return HostScope.thisDevice;
  return isLocalIpBytes(bytes) ? HostScope.network : HostScope.internet;
}

/// [url]'s host scope, or null when it is no http(s) URL with a host.
HostScope? urlHostScope(String url) {
  final m = RegExp(r'^https?://(\[[^\]]*\]|[^/:?#]*)', caseSensitive: false).firstMatch(url.trim());
  if (m == null || m[1]!.isEmpty) return null;
  return hostScope(m[1]!);
}

/// Plain `http` to this device or the local network: it goes direct, never through Tor, while
/// the Tor switch is on in Normal (Tor cannot reach the local network).
bool plainHttpGoesDirect(String url) {
  if (!url.trim().toLowerCase().startsWith('http://')) return false;
  final scope = urlHostScope(url);
  return scope == HostScope.thisDevice || scope == HostScope.network;
}

/// A send or resend to [url] the wallet refuses now: plain http to another device while the
/// Tor switch is on or in Tor only, except, in Normal, to the local network ([plainHttpGoesDirect]).
bool plainHttpHeldNow(String url) =>
    plainHttpOffNow && plainHttpToOtherDevice(url) && (NetGate.torOnly || !plainHttpGoesDirect(url));

// --------------------------------------------------------------------------------------------
// What the mode holds

/// What the network [mode] with the Tor switch [torOn] holds a send to [to] with; null when it
/// may go. The method switches (Settings › Transactions) and a tor still starting are the
/// screens' own notes ([NetBlock]).
SendHold? sendHoldFor(RecipientInput to, {required NetworkMode mode, required bool torOn}) {
  if (!to.isAddress) return null;
  switch (mode) {
    case NetworkMode.killSwitch:
      return SendHold.killSwitch;
    case NetworkMode.nodeOnly:
      return SendHold.nodeOnly;
    case NetworkMode.torOnly:
      return to.kind == RecipientInputKind.http && to.scope != HostScope.thisDevice ? SendHold.torOnlyPlainHttp : null;
    case NetworkMode.standard:
      return torOn && to.kind == RecipientInputKind.http && to.scope == HostScope.internet ? SendHold.torOnPlainHttp : null;
  }
}

/// Whether the Tor switch carries a send to [to]: Epicbox and https over Tor while it is on or
/// in Tor only; plain http never (held, or direct to the local network); an onion always.
bool sendOverTor(RecipientInput to, {required NetworkMode mode, required bool torOn}) {
  final tor = torOn || mode == NetworkMode.torOnly;
  return switch (to.kind) {
    RecipientInputKind.epicbox || RecipientInputKind.https => tor && to.scope != HostScope.thisDevice,
    _ => false,
  };
}

/// The order a contact's addresses are tried in: Epicbox, https, Tor, plain http.
int _rank(RecipientInputKind k) => switch (k) {
  RecipientInputKind.epicbox => 0,
  RecipientInputKind.https => 1,
  RecipientInputKind.onion => 2,
  RecipientInputKind.http => 3,
  _ => 4,
};

/// The index in [addresses] (a contact's, each read with [read]) Send uses first: the first by
/// Epicbox, https, Tor, plain http that [held] does not hold, else the first by that order.
/// -1 when there are none.
int bestAddressIndex(
  List<String> addresses, {
  required RecipientInput Function(String) read,
  required bool Function(RecipientInput) held,
}) {
  if (addresses.isEmpty) return -1;
  final read0 = [for (final a in addresses) read(a)];
  final order = [for (var i = 0; i < addresses.length; i++) i]..sort((a, b) {
    final r = _rank(read0[a].kind).compareTo(_rank(read0[b].kind));
    return r != 0 ? r : a.compareTo(b);
  });
  for (final i in order) {
    if (read0[i].isAddress && !held(read0[i])) return i;
  }
  return order.first;
}

// --------------------------------------------------------------------------------------------
// Punycode (RFC 3492), for an international host name's ASCII form.

String? _punycode(String input) {
  const base = 36, tMin = 1, tMax = 26, skew = 38, damp = 700, initialBias = 72, initialN = 128;
  final cps = input.runes.toList();
  final out = StringBuffer();
  for (final c in cps) {
    if (c < 0x80) out.writeCharCode(c);
  }
  final b = out.length;
  var h = b;
  if (b > 0) out.write('-');
  var n = initialN, delta = 0, bias = initialBias;
  int adapt(int delta, int numPoints, bool first) {
    delta = first ? delta ~/ damp : delta ~/ 2;
    delta += delta ~/ numPoints;
    var k = 0;
    while (delta > ((base - tMin) * tMax) ~/ 2) {
      delta ~/= base - tMin;
      k += base;
    }
    return k + (base - tMin + 1) * delta ~/ (delta + skew);
  }

  String digit(int d) => String.fromCharCode(d < 26 ? 0x61 + d : 0x30 + d - 26);
  while (h < cps.length) {
    var m = 0x7fffffff;
    for (final c in cps) {
      if (c >= n && c < m) m = c;
    }
    if ((m - n) > (0x7fffffff - delta) ~/ (h + 1)) return null;
    delta += (m - n) * (h + 1);
    n = m;
    for (final c in cps) {
      if (c < n) delta++;
      if (c == n) {
        var q = delta;
        for (var k = base;; k += base) {
          final t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias);
          if (q < t) break;
          out.write(digit(t + (q - t) % (base - t)));
          q = (q - t) ~/ (base - t);
        }
        out.write(digit(q));
        bias = adapt(delta, h + 1, h == b);
        delta = 0;
        h++;
      }
    }
    delta++;
    n++;
  }
  return out.toString();
}
