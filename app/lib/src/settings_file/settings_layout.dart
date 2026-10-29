// SPDX-License-Identifier: Apache-2.0
/// The keys of `settings.toml` (version 1): each key's path, the kind of value it holds and
/// what makes a value good. The model reads only these; any other key is unknown (kept in the
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
  const TextListKind(this.check);
  final TextCheck check;
}

/// A text-to-text inline table (`renamed_epicbox = { "old" = "new" }`), both sides checked.
class TextMapKind extends ValueKind {
  const TextMapKind(this.check);
  final TextCheck check;
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

/// An array of tables (`[[node.servers]]`): entries with [fields], told apart by [identity].
class TablesKind extends ValueKind {
  const TablesKind(this.fields, this.identity, {this.omitDefaults = const {}});
  final List<EntryField> fields;
  final String Function(Map<String, Object?> entry) identity;

  /// Fields a new block leaves out when they hold their default (`port = 443` for Epicbox).
  final Set<String> omitDefaults;

  EntryField? field(String name) {
    for (final f in fields) {
      if (f.name == name) return f;
    }
    return null;
  }
}

class SettingsKey {
  const SettingsKey(this.path, this.kind);
  final String path;
  final ValueKind kind;

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

/// `host:port` of a node address (`node.removed` names them this way).
String nodeHostPort(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return url.toLowerCase();
  final port = uri.hasPort ? uri.port : (uri.scheme == 'http' ? 80 : 443);
  return '${uri.host.toLowerCase()}:$port';
}

/// A node entry's identity: its address, without a trailing `/`, host in lower case.
String nodeIdentity(Map<String, Object?> e) {
  final url = '${e['url'] ?? ''}';
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return url;
  return uri.replace(host: uri.host.toLowerCase()).toString().replaceFirst(RegExp(r'/$'), '');
}

/// `host` on 443, else `host:port`: an Epicbox server's label and identity.
String epicboxLabel(String host, int port) => port == 443 ? host.toLowerCase() : '${host.toLowerCase()}:$port';

String epicboxIdentity(Map<String, Object?> e) {
  final port = e['port'];
  return epicboxLabel('${e['host'] ?? ''}', port is int ? port : 443);
}

/// An onion route's identity: `host:port`.
String onionIdentity(Map<String, Object?> e) {
  final port = e['port'];
  return '${'${e['host'] ?? ''}'.toLowerCase()}:${port is int ? port : 443}';
}

// --- the layout -----------------------------------------------------------------------------

const _port = IntKind(min: 1, max: 65535, problem: ValueProblem.notPort);
const _url = TextKind(checkWebAddress);
const _urls = TextListKind(checkWebAddress);

const nodeServersKind = TablesKind([
  EntryField('url', TextKind(checkNodeAddress), required: true),
  EntryField('operator', TextKind(anyText)),
], nodeIdentity);

const epicboxServersKind = TablesKind(
  [
    EntryField('host', TextKind(checkEpicboxServer), required: true),
    EntryField('port', _port, byDefault: 443),
    EntryField('operator', TextKind(anyText)),
  ],
  epicboxIdentity,
  omitDefaults: {'port'},
);

const torOnionsKind = TablesKind([
  EntryField('host', TextKind(checkHostName), required: true),
  EntryField('port', _port, byDefault: 443),
  EntryField('onion', TextKind(checkOnion), required: true),
  EntryField('onion_port', _port, byDefault: 443),
  EntryField('tls', BoolKind(), byDefault: true),
], onionIdentity);

/// Every key the app reads, in the shipped file's order.
const List<SettingsKey> settingsKeys = [
  SettingsKey('version', IntKind(min: 1)),
  SettingsKey('node.use', TextKind(checkNodeAddress)),
  SettingsKey('node.fallback', TextKind(checkNodeAddress)),
  SettingsKey('node.removed', TextListKind(checkHostPort)),
  SettingsKey('node.servers', nodeServersKind),
  SettingsKey('epicbox.use', TextKind(checkEpicboxServer)),
  SettingsKey('epicbox.default', TextKind(checkEpicboxServer)),
  SettingsKey('epicbox.removed', TextListKind(checkEpicboxServer)),
  SettingsKey('epicbox.servers', epicboxServersKind),
  SettingsKey('pairing.servers', TextListKind(checkEpicboxServer)),
  SettingsKey('devices.link_servers', TextListKind(checkEpicboxServer)),
  SettingsKey('tor.onion_only_domains', TextListKind(checkHostName)),
  SettingsKey('tor.onions', torOnionsKind),
  SettingsKey('status.enabled', BoolKind()),
  SettingsKey('status.directory', _url),
  SettingsKey('status.icons', _url),
  SettingsKey('status.price', _url),
  SettingsKey('price.source', _url),
  SettingsKey('updates.check', BoolKind()),
  SettingsKey('updates.manifests', _urls),
  SettingsKey('updates.downloads', _url),
  SettingsKey('updates.releases_page', _url),
  SettingsKey('updates.pages', _urls),
  SettingsKey('support.report', _url),
  SettingsKey('support.email', TextKind(checkEmail)),
  SettingsKey('support.donation', TextKind(checkEpicboxAddress)),
  SettingsKey('support.directory', _url),
  SettingsKey('links.website', _url),
  SettingsKey('links.community', _url),
  SettingsKey('links.source', _url),
  SettingsKey('links.explorer_block', TextKind(_explorerBlock)),
  SettingsKey('links.explorer_kernel', TextKind(_explorerKernel)),
  SettingsKey('reach.ip_lookup', _url),
  SettingsKey('reach.port_check', _url),
  SettingsKey('import.gui_node', TextKind(checkNodeAddress)),
  SettingsKey('import.gui_epicbox', TextKind(checkEpicboxServer)),
  SettingsKey('import.old_epicbox', TextKind(checkEpicboxServer)),
  SettingsKey('import.renamed_epicbox', TextMapKind(checkEpicboxServer)),
  SettingsKey('import.dead_fallbacks', TextListKind(checkHostName)),
  SettingsKey('report.keep_hosts', TextListKind(checkHostName)),
  SettingsKey('report.keep_domains', TextListKind(checkHostName)),
  SettingsKey('network.vpn_suffixes', TextListKind(checkSuffix)),
];

ValueProblem? _explorerBlock(String v) => checkTemplate('height')(v);
ValueProblem? _explorerKernel(String v) => checkTemplate('kernel', optional: true)(v);

final Map<String, SettingsKey> settingsKeysByPath = {for (final k in settingsKeys) k.path: k};

/// The tables the layout has (`node`, `epicbox`, …).
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
/// shape: `String`, `int`, `bool`, `List<String>`, `Map<String, String>` or
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
    case TextListKind(:final check):
      if (raw is! List) return const Checked.bad(ValueProblem.notList);
      final out = <String>[];
      for (final v in raw) {
        if (v is! String) return const Checked.bad(ValueProblem.notList);
        final p = check(v);
        if (p != null) return Checked.bad(p);
        out.add(v);
      }
      return Checked.good(List<String>.unmodifiable(out));
    case TextMapKind(:final check):
      if (raw is! Map) return const Checked.bad(ValueProblem.notList);
      final out = <String, String>{};
      for (final e in raw.entries) {
        final v = e.value;
        if (v is! String) return const Checked.bad(ValueProblem.notText);
        final p = check('${e.key}') ?? check(v);
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
