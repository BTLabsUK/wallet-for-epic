// SPDX-License-Identifier: Apache-2.0
/// The keys of the two files (docs/settings-file.md): [settingsKeys], the user's
/// `settings.toml` (the server lists and three switches, kept in step with the app), and
/// [configKeys], the read-only `app-config.toml` shipped with the app (every other address,
/// timeout, interval, port and limit). Each key has its path, the kind of value it holds and
/// what makes a value good. A key of `settings.toml` the layout lacks is unknown (kept in the
/// file, named once in a notice).
library;

/// Why a value was not used. Each has its own sentence in the notices.
enum ValueProblem {
  notText,
  notNumber,
  notSwitch,
  notList,
  notNodeAddress,
  notEpicboxServer,
  notHostName,
  notWebAddress,
  notOnion,
  notPort,
  notEmail,
  notEpicboxAddress,
}

/// Checks one text value; null when it is good.
typedef TextCheck = ValueProblem? Function(String value);

sealed class ValueKind {
  const ValueKind();
}

class TextKind extends ValueKind {
  const TextKind(this.check);
  final TextCheck check;
}

class IntKind extends ValueKind {
  const IntKind({this.min = 0, this.max = 1 << 31, this.problem = ValueProblem.notNumber});
  final int min;
  final int max;
  final ValueProblem problem;
}

class BoolKind extends ValueKind {
  const BoolKind();
}

class TextListKind extends ValueKind {
  const TextListKind(this.check, {this.minLength = 0});
  final TextCheck check;

  /// The fewest items a good list has (a server list needs the one in use).
  final int minLength;
}

/// A list of whole numbers (`start_backoff_s = [2, 10, 30, 60]`), each in [min]..[max].
class IntListKind extends ValueKind {
  const IntListKind({this.min = 0, this.max = 1 << 31});
  final int min;
  final int max;
}

/// A text-to-text inline table (`renamed_epicbox = { "old" = "new" }`): keys checked by
/// [keyCheck] (else [check]), values by [check].
class TextMapKind extends ValueKind {
  const TextMapKind(this.check, {this.keyCheck});
  final TextCheck check;
  final TextCheck? keyCheck;
}

/// One field of an array of tables' entry.
class EntryField {
  const EntryField(this.name, this.kind, {this.required = false, this.byDefault});
  final String name;
  final ValueKind kind;
  final bool required;

  /// The value an entry has when the field is left out.
  final Object? byDefault;
}

/// An array of tables (`onions = [{ … }, …]`): entries with [fields], told apart by [identity].
class TablesKind extends ValueKind {
  const TablesKind(this.fields, this.identity, {this.omitDefaults = const {}});
  final List<EntryField> fields;
  final String Function(Map<String, Object?> entry) identity;

  /// Fields a new block leaves out when they hold their default.
  final Set<String> omitDefaults;

  EntryField? field(String name) {
    for (final f in fields) {
      if (f.name == name) return f;
    }
    return null;
  }
}

class SettingsKey {
  const SettingsKey(this.path, this.kind, {this.byDefault, this.requiredWith});
  final String path;
  final ValueKind kind;

  /// The value of an optional key a file leaves out (`app-config.toml` only): empty text or an
  /// empty list, which reads as "not configured" (the feature is hidden). Null: required.
  final Object? byDefault;

  /// A key needed only while one of these keys is set (not empty): the timing of a service
  /// whose address may be left out. Without them it may be missing too, and is never read.
  final List<String>? requiredWith;

  List<String> get parts => path.split('.');
}

// --- checks ---------------------------------------------------------------------------------

final RegExp _label = RegExp(r'^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$');
final RegExp _ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
final RegExp _onion = RegExp(r'^[a-z2-7]{56}\.onion$');
final RegExp _email = RegExp(r'^[A-Za-z0-9._%+\-]+@([^@\s]+)$');
final RegExp _epicboxAddress = RegExp(r'^es[1-9A-HJ-NP-Za-km-z]{30,80}@(.+)$');

/// A host name (labels of letters, digits and `-`) or an IPv4 address.
bool isHostName(String v) {
  if (v.isEmpty || v.length > 253) return false;
  final ip = _ipv4.firstMatch(v);
  if (ip != null) {
    return [for (var i = 1; i <= 4; i++) int.parse(ip.group(i)!)].every((n) => n <= 255);
  }
  return v.split('.').every(_label.hasMatch);
}

/// `host` or `host:port`.
bool isHostPort(String v) {
  final i = v.lastIndexOf(':');
  if (i < 0) return isHostName(v);
  final port = int.tryParse(v.substring(i + 1));
  return isHostName(v.substring(0, i)) && port != null && port > 0 && port < 65536;
}

/// An `http(s)://host[:port][/path][?query]` address with a host and no user name.
bool isWebAddress(String v) {
  final uri = Uri.tryParse(v);
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) return false;
  if (uri.userInfo.isNotEmpty || uri.hasFragment) return false;
  return isHostName(uri.host);
}

ValueProblem? checkNodeAddress(String v) {
  if (!isWebAddress(v)) return ValueProblem.notNodeAddress;
  final uri = Uri.parse(v);
  if (uri.hasQuery || (uri.path.isNotEmpty && uri.path != '/')) return ValueProblem.notNodeAddress;
  return null;
}

ValueProblem? checkEpicboxServer(String v) => isHostPort(v) ? null : ValueProblem.notEpicboxServer;

ValueProblem? checkHostName(String v) => isHostName(v) ? null : ValueProblem.notHostName;

ValueProblem? checkHostPort(String v) => isHostPort(v) ? null : ValueProblem.notHostName;

/// A domain suffix such as `.ts.net` (the leading dot is optional).
ValueProblem? checkSuffix(String v) =>
    isHostName(v.startsWith('.') ? v.substring(1) : v) ? null : ValueProblem.notHostName;

ValueProblem? checkWebAddress(String v) => isWebAddress(v) ? null : ValueProblem.notWebAddress;

/// A web address with `{name}` in it; empty is allowed when [optional].
TextCheck checkTemplate(String name, {bool optional = false}) => (v) {
  if (v.isEmpty && optional) return null;
  if (!v.contains('{$name}')) return ValueProblem.notWebAddress;
  return isWebAddress(v.replaceAll('{$name}', '0')) ? null : ValueProblem.notWebAddress;
};

ValueProblem? checkOnion(String v) => _onion.hasMatch(v) ? null : ValueProblem.notOnion;

ValueProblem? checkEmail(String v) {
  final m = _email.firstMatch(v);
  return m != null && isHostName(m.group(1)!) ? null : ValueProblem.notEmail;
}

ValueProblem? checkEpicboxAddress(String v) {
  final m = _epicboxAddress.firstMatch(v);
  return m != null && isHostPort(m.group(1)!) ? null : ValueProblem.notEpicboxAddress;
}

ValueProblem? anyText(String v) => null;

// --- identities -----------------------------------------------------------------------------

/// The host of a web address, lower case; the text itself when it has none.
String hostOf(String address) {
  final uri = Uri.tryParse(address);
  if (uri != null && uri.host.isNotEmpty) return uri.host.toLowerCase();
  final i = address.lastIndexOf(':');
  return (i < 0 ? address : address.substring(0, i)).toLowerCase();
}

/// `host:port` of a node address, the port filled in from the scheme.
String nodeHostPort(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return url.toLowerCase();
  final port = uri.hasPort ? uri.port : (uri.scheme == 'http' ? 80 : 443);
  return '${uri.host.toLowerCase()}:$port';
}

/// `host` on 443, else `host:port`: an Epicbox server's label, as an address names it.
String epicboxLabel(String host, int port) => port == 443 ? host.toLowerCase() : '${host.toLowerCase()}:$port';

/// An onion route's identity: `host:port`.
String onionIdentity(Map<String, Object?> e) {
  final port = e['port'];
  return '${'${e['host'] ?? ''}'.toLowerCase()}:${port is int ? port : 443}';
}

// --- the layout -----------------------------------------------------------------------------

const _port = IntKind(min: 1, max: 65535, problem: ValueProblem.notPort);
const _url = TextKind(checkWebAddress);
const _urls = TextListKind(checkWebAddress);
const _seconds = IntKind(min: 1, max: 86400);
const _ms = IntKind(min: 1, max: 600000);
const _count = IntKind(min: 1, max: 100000);

const torOnionsKind = TablesKind([
  EntryField('host', TextKind(checkHostName), required: true),
  EntryField('port', _port, byDefault: 443),
  EntryField('onion', TextKind(checkOnion), required: true),
  EntryField('onion_port', _port, byDefault: 443),
  EntryField('tls', BoolKind(), byDefault: true),
], onionIdentity);

/// Every key of the user's `settings.toml`, in the default copy's order. The first entry of
/// each server list is the one in use; an empty list means none is configured.
const List<SettingsKey> settingsKeys = [
  SettingsKey('node.servers', TextListKind(checkNodeAddress)),
  SettingsKey('epicbox.servers', TextListKind(checkEpicboxServer)),
  SettingsKey('online.status_site', BoolKind()),
  SettingsKey('online.update_check', BoolKind()),
  SettingsKey('online.price', BoolKind()),
];

/// Every key of `app-config.toml`, in its order. Read-only: the app never writes it.
const List<SettingsKey> configKeys = [
  SettingsKey('operators', TextMapKind(anyText, keyCheck: checkHostName)),
  // [node]: the wallet core's node client (LEPIC's tuning), then the app's own checks.
  SettingsKey('node.connect_timeout_s', _seconds),
  SettingsKey('node.request_timeout_s', _seconds),
  SettingsKey('node.idle_timeout_s', _seconds),
  SettingsKey('node.retry_attempts', IntKind(max: 100)),
  SettingsKey('node.retry_backoff_min_ms', _ms),
  SettingsKey('node.retry_backoff_max_ms', _ms),
  SettingsKey('node.outputs_per_request', _count),
  SettingsKey('node.concurrent_requests', IntKind(min: 1, max: 64)),
  SettingsKey('node.check_timeout_s', _seconds),
  SettingsKey('node.tor_check_timeout_s', _seconds),
  SettingsKey('node.tip_check_s', _seconds),
  SettingsKey('node.poll_s', _seconds),
  SettingsKey('node.refresh_s', _seconds),
  SettingsKey('node.recheck_s', _seconds),
  SettingsKey('node.stale_after_s', _seconds),
  SettingsKey('node.failover_after_s', _seconds),
  SettingsKey('node.failover_probe_s', _seconds),
  SettingsKey('node.own_node_ask_s', _seconds),
  SettingsKey('node.local.api_port', _port),
  SettingsKey('node.local.p2p_port', _port),
  // [epicbox]
  SettingsKey('epicbox.address_default', TextKind(checkEpicboxServer)),
  SettingsKey('epicbox.pairing_servers', IntKind(min: 1, max: 10)),
  SettingsKey('epicbox.link_servers', IntKind(min: 1, max: 10)),
  SettingsKey('epicbox.connect_timeout_s', _seconds),
  SettingsKey('epicbox.response_timeout_s', _seconds),
  SettingsKey('epicbox.ping_interval_s', _seconds),
  SettingsKey('epicbox.reconnect_min_s', _seconds),
  SettingsKey('epicbox.reconnect_max_s', _seconds),
  SettingsKey('epicbox.drain_timeout_s', _seconds),
  SettingsKey('epicbox.tor_connect_timeout_s', _seconds),
  SettingsKey('epicbox.onion_discovery_timeout_s', _seconds),
  SettingsKey('epicbox.onion_discovery_retry_s', _seconds),
  SettingsKey('epicbox.listener_heal_after_s', _seconds),
  SettingsKey('epicbox.listener_heal_max_s', _seconds),
  // [http]: the Link · HTTP listener and HTTP sends.
  SettingsKey('http.listen_port', _port),
  SettingsKey('http.header_timeout_s', _seconds),
  SettingsKey('http.body_timeout_s', _seconds),
  SettingsKey('http.request_timeout_s', _seconds),
  SettingsKey('http.answer_timeout_s', _seconds),
  SettingsKey('http.max_connections', _count),
  SettingsKey('http.max_connections_per_address', _count),
  SettingsKey('http.requests_per_minute', _count),
  SettingsKey('http.receives_per_minute', _count),
  SettingsKey('http.send_connect_timeout_s', _seconds),
  SettingsKey('http.send_request_timeout_s', _seconds),
  // [tor]
  SettingsKey('tor.start_backoff_s', IntListKind(min: 1, max: 3600)),
  SettingsKey('tor.send_wait_s', _seconds),
  SettingsKey('tor.onion_retry_s', _seconds),
  SettingsKey('tor.bootstrap_timeout_s', _seconds),
  SettingsKey('tor.cold_bootstrap_timeout_s', _seconds),
  SettingsKey('tor.stall_timeout_s', _seconds),
  SettingsKey('tor.cold_stall_timeout_s', _seconds),
  SettingsKey('tor.publish_timeout_s', _seconds),
  SettingsKey('tor.connect_timeout_s', _seconds),
  SettingsKey('tor.request_timeout_s', _seconds),
  SettingsKey('tor.onion_only_domains', TextListKind(checkHostName)),
  SettingsKey('tor.onions', torOnionsKind),
  // [status]
  SettingsKey('status.timeout_s', _seconds, requiredWith: _statusSite),
  SettingsKey('status.tor_timeout_s', _seconds, requiredWith: _statusSite),
  SettingsKey('status.fresh_s', _seconds, requiredWith: _statusSite),
  SettingsKey('status.directory', _url, byDefault: ''),
  SettingsKey('status.icons', _url, byDefault: ''),
  SettingsKey('status.price', _url, byDefault: ''),
  SettingsKey('status.ip', _url, byDefault: ''),
  SettingsKey('status.reach', TextKind(_reachTemplate), byDefault: ''),
  SettingsKey('status.reach_timeout_s', _seconds, requiredWith: ['status.ip', 'status.reach']),
  // [price]
  SettingsKey('price.refresh_min', IntKind(min: 1, max: 1440), requiredWith: ['price.source', 'status.price']),
  SettingsKey('price.timeout_s', _seconds, requiredWith: ['price.source']),
  SettingsKey('price.fallback_timeout_s', _seconds, requiredWith: ['status.price']),
  SettingsKey('price.max_age_min', IntKind(min: 1, max: 10080), requiredWith: ['price.source', 'status.price']),
  SettingsKey('price.source', _url, byDefault: ''),
  // [updates]
  SettingsKey('updates.first_check_s', _seconds, requiredWith: ['updates.manifests']),
  SettingsKey('updates.check_every_h', IntKind(min: 1, max: 720), requiredWith: ['updates.manifests']),
  SettingsKey('updates.timeout_s', _seconds, requiredWith: ['updates.manifests']),
  SettingsKey('updates.download_stall_s', _seconds, requiredWith: ['updates.downloads']),
  SettingsKey('updates.manifests', _urls, byDefault: <String>[]),
  SettingsKey('updates.downloads', _url, byDefault: ''),
  SettingsKey('updates.releases_page', _url, byDefault: ''),
  SettingsKey('updates.pages', _urls, byDefault: <String>[]),
  // [support]
  SettingsKey('support.timeout_s', _seconds, requiredWith: ['support.report']),
  SettingsKey('support.report', _url, byDefault: ''),
  SettingsKey('support.email', TextKind(_optionalEmail), byDefault: ''),
  SettingsKey('support.donation', TextKind(_donation), byDefault: ''),
  SettingsKey('support.signed_file', _url, byDefault: ''),
  // [links]
  SettingsKey('links.website', _url, byDefault: ''),
  SettingsKey('links.community', _url, byDefault: ''),
  SettingsKey('links.source', _url, byDefault: ''),
  SettingsKey('links.privacy', _url, byDefault: ''),
  // [explorer]: a block by its height; no kernel page.
  SettingsKey('explorer.block', TextKind(_explorerBlock), byDefault: ''),
  // [import]
  SettingsKey('import.gui_node', TextKind(checkNodeAddress)),
  SettingsKey('import.gui_epicbox', TextKind(checkEpicboxServer)),
  SettingsKey('import.old_epicbox', TextKind(checkEpicboxServer)),
  SettingsKey('import.renamed_epicbox', TextMapKind(checkEpicboxServer)),
  SettingsKey('import.dead_fallbacks', TextListKind(checkHostName)),
  // [report]
  SettingsKey('report.keep_hosts', TextListKind(checkHostName)),
  SettingsKey('report.keep_domains', TextListKind(checkHostName)),
  // [network]
  SettingsKey('network.vpn_suffixes', TextListKind(checkSuffix)),
  // [payments]
  SettingsKey('payments.watch_fast_every_s', _seconds),
  SettingsKey('payments.watch_fast_for_s', _seconds),
  SettingsKey('payments.watch_slow_every_s', _seconds),
  // Above the 180 s the network holds a new transaction (Dandelion's embargo).
  SettingsKey('payments.watch_for_s', IntKind(min: 181, max: 86400)),
  SettingsKey('payments.repost_waits_min', IntListKind(min: 1, max: 1440)),
  SettingsKey('payments.answer_resend_waits_min', IntListKind(min: 1, max: 1440)),
];

ValueProblem? _explorerBlock(String v) => checkTemplate('height', optional: true)(v);
ValueProblem? _optionalEmail(String v) => v.isEmpty ? null : checkEmail(v);
ValueProblem? _reachTemplate(String v) => checkTemplate('port', optional: true)(v);

/// The status site's addresses: its timing keys are needed only with one of them.
const _statusSite = ['status.directory', 'status.icons', 'status.price'];

/// An Epicbox address, or empty: no donation entry.
ValueProblem? _donation(String v) => v.isEmpty ? null : checkEpicboxAddress(v);

final Map<String, SettingsKey> settingsKeysByPath = {for (final k in settingsKeys) k.path: k};

final Map<String, SettingsKey> configKeysByPath = {for (final k in configKeys) k.path: k};

/// The tables `settings.toml` has (`node`, `epicbox`, `online`).
final Set<String> settingsTables = {
  for (final k in settingsKeys)
    if (k.path.contains('.')) k.path.split('.').first,
};

// --- reading one value ----------------------------------------------------------------------

/// A checked value, or the problem that keeps it out (with the entry index and field for an
/// array of tables, so the problem can name its line).
class Checked {
  const Checked.good(this.value) : problem = null, entry = null, field = null;
  const Checked.bad(this.problem, {this.entry, this.field}) : value = null;
  final Object? value;
  final ValueProblem? problem;
  final int? entry;
  final String? field;
  bool get ok => problem == null;
}

/// Checks a raw value from the TOML parser against [kind] and returns it in the model's
/// shape: `String`, `int`, `bool`, `List<String>`, `List<int>`, `Map<String, String>` or
/// `List<Map<String, Object?>>` with every default filled in and unknown fields kept.
Checked checkValue(ValueKind kind, Object? raw) {
  switch (kind) {
    case TextKind(:final check):
      if (raw is! String) return const Checked.bad(ValueProblem.notText);
      final p = check(raw);
      return p == null ? Checked.good(raw) : Checked.bad(p);
    case IntKind(:final min, :final max, :final problem):
      if (raw is! int) return Checked.bad(problem);
      return raw >= min && raw <= max ? Checked.good(raw) : Checked.bad(problem);
    case BoolKind():
      return raw is bool ? Checked.good(raw) : const Checked.bad(ValueProblem.notSwitch);
    case TextListKind(:final check, :final minLength):
      if (raw is! List) return const Checked.bad(ValueProblem.notList);
      final out = <String>[];
      for (final v in raw) {
        if (v is! String) return const Checked.bad(ValueProblem.notList);
        final p = check(v);
        if (p != null) return Checked.bad(p);
        out.add(v);
      }
      if (out.length < minLength) return const Checked.bad(ValueProblem.notList);
      return Checked.good(List<String>.unmodifiable(out));
    case IntListKind(:final min, :final max):
      if (raw is! List || raw.isEmpty) return const Checked.bad(ValueProblem.notList);
      final out = <int>[];
      for (final v in raw) {
        if (v is! int || v < min || v > max) return const Checked.bad(ValueProblem.notNumber);
        out.add(v);
      }
      return Checked.good(List<int>.unmodifiable(out));
    case TextMapKind(:final check, :final keyCheck):
      if (raw is! Map) return const Checked.bad(ValueProblem.notList);
      final out = <String, String>{};
      for (final e in raw.entries) {
        final v = e.value;
        if (v is! String) return const Checked.bad(ValueProblem.notText);
        final p = (keyCheck ?? check)('${e.key}') ?? check(v);
        if (p != null) return Checked.bad(p);
        out['${e.key}'] = v;
      }
      return Checked.good(Map<String, String>.unmodifiable(out));
    case TablesKind(:final fields):
      if (raw is! List) return const Checked.bad(ValueProblem.notList);
      final out = <Map<String, Object?>>[];
      for (var i = 0; i < raw.length; i++) {
        final entry = raw[i];
        if (entry is! Map) return Checked.bad(ValueProblem.notList, entry: i);
        final m = <String, Object?>{};
        for (final f in fields) {
          final v = entry[f.name];
          if (v == null) {
            if (f.required) {
              final p = switch (f.kind) {
                TextKind(:final check) => check('') ?? ValueProblem.notText,
                _ => ValueProblem.notText,
              };
              return Checked.bad(p, entry: i, field: f.name);
            }
            if (f.byDefault != null) m[f.name] = f.byDefault;
            continue;
          }
          final c = checkValue(f.kind, v);
          if (!c.ok) return Checked.bad(c.problem, entry: i, field: f.name);
          m[f.name] = c.value;
        }
        for (final e in entry.entries) {
          m.putIfAbsent('${e.key}', () => e.value);
        }
        out.add(Map<String, Object?>.unmodifiable(m));
      }
      return Checked.good(List<Map<String, Object?>>.unmodifiable(out));
  }
}
