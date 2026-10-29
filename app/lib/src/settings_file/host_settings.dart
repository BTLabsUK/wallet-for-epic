// SPDX-License-Identifier: Apache-2.0
/// The settings file's values as the app reads them: [HostSettings], immutable, one typed
/// getter per key, every key filled (from the file when its value is good, else the last
/// good value, else the shipped file's). [readSettings] turns a text into one and says what
/// it could not use.
library;

import 'package:toml/toml.dart';

import 'settings_layout.dart';
import 'toml_edit.dart';
import 'toml_scan.dart';

/// A node of the Node list.
class NodeServer {
  const NodeServer({required this.url, this.operator});
  final String url;
  final String? operator;

  Map<String, Object?> toEntry() => {'url': url, 'operator': ?operator};

  @override
  bool operator ==(Object other) => other is NodeServer && other.url == url && other.operator == operator;
  @override
  int get hashCode => Object.hash(url, operator);
  @override
  String toString() => 'NodeServer($url)';
}

/// A server of the Epicbox list.
class EpicboxServer {
  const EpicboxServer({required this.host, this.port = 443, this.operator});
  final String host;
  final int port;
  final String? operator;

  /// `host` on 443, else `host:port`: how an address names it.
  String get label => epicboxLabel(host, port);

  Map<String, Object?> toEntry() => {'host': host, 'port': port, 'operator': ?operator};

  @override
  bool operator ==(Object other) =>
      other is EpicboxServer && other.host == host && other.port == port && other.operator == operator;
  @override
  int get hashCode => Object.hash(host, port, operator);
  @override
  String toString() => 'EpicboxServer($label)';
}

/// A server's onion address, used instead of the host with Tor on.
class OnionRoute {
  const OnionRoute({required this.host, this.port = 443, required this.onion, this.onionPort = 443, this.tls = true});
  final String host;
  final int port;
  final String onion;
  final int onionPort;

  /// Whether the onion speaks TLS for the host's name.
  final bool tls;

  Map<String, Object?> toEntry() => {'host': host, 'port': port, 'onion': onion, 'onion_port': onionPort, 'tls': tls};

  @override
  bool operator ==(Object other) =>
      other is OnionRoute &&
      other.host == host &&
      other.port == port &&
      other.onion == onion &&
      other.onionPort == onionPort &&
      other.tls == tls;
  @override
  int get hashCode => Object.hash(host, port, onion, onionPort, tls);
}

/// The values of `settings.toml`. Every key of [settingsKeys] has a value.
class HostSettings {
  HostSettings._(Map<String, Object> values) : _values = Map.unmodifiable(values);

  /// A complete file (the shipped one, or a test's): every key present and good, or it throws
  /// [StateError] naming what is wrong. Its own values are its fallback.
  factory HostSettings.fromText(String text) {
    final doc = parseSettingsToml(text);
    final scan = TomlScan(text);
    final values = <String, Object>{};
    for (final key in settingsKeys) {
      final raw = rawValue(doc, key.path);
      if (raw == null) throw StateError('settings: ${key.path} is missing');
      final c = checkValue(key.kind, raw);
      if (!c.ok) {
        throw StateError('settings, line ${_problemLine(scan, key, c)}: ${key.path} is ${c.problem!.name}');
      }
      values[key.path] = c.value!;
    }
    return HostSettings._(values);
  }

  final Map<String, Object> _values;

  /// The value of [path] in the model's shape (see [checkValue]).
  Object value(String path) => _values[path] ?? (throw ArgumentError.value(path, 'path', 'not a settings key'));

  Map<String, Object> get values => _values;

  /// These settings with [changes] (paths to values in the model's shape, entries as maps).
  /// Throws [ArgumentError] for an unknown key or a value its key refuses.
  HostSettings withValues(Map<String, Object> changes) {
    final next = {..._values};
    changes.forEach((path, v) => next[path] = checkAppValue(path, v));
    return HostSettings._(next);
  }

  int get version => value('version') as int;

  // [node]
  String get nodeUse => value('node.use') as String;
  String get nodeFallback => value('node.fallback') as String;
  List<String> get nodeRemoved => _texts('node.removed');
  List<NodeServer> get nodeServers => [
    for (final e in _entries('node.servers')) NodeServer(url: e['url'] as String, operator: e['operator'] as String?),
  ];

  // [epicbox]
  String get epicboxUse => value('epicbox.use') as String;
  String get epicboxDefault => value('epicbox.default') as String;
  List<String> get epicboxRemoved => _texts('epicbox.removed');
  List<EpicboxServer> get epicboxServers => [
    for (final e in _entries('epicbox.servers'))
      EpicboxServer(host: e['host'] as String, port: e['port'] as int, operator: e['operator'] as String?),
  ];

  List<String> get pairingServers => _texts('pairing.servers');
  List<String> get deviceLinkServers => _texts('devices.link_servers');

  // [tor]
  List<String> get torOnionOnlyDomains => _texts('tor.onion_only_domains');
  List<OnionRoute> get torOnions => [
    for (final e in _entries('tor.onions'))
      OnionRoute(
        host: e['host'] as String,
        port: e['port'] as int,
        onion: e['onion'] as String,
        onionPort: e['onion_port'] as int,
        tls: e['tls'] as bool,
      ),
  ];

  // [status]
  bool get statusEnabled => value('status.enabled') as bool;
  String get statusDirectory => value('status.directory') as String;
  String get statusIcons => value('status.icons') as String;
  String get statusPrice => value('status.price') as String;

  String get priceSource => value('price.source') as String;

  // [updates]
  bool get updatesCheck => value('updates.check') as bool;
  List<String> get updateManifests => _texts('updates.manifests');
  String get updateDownloads => value('updates.downloads') as String;
  String get releasesPage => value('updates.releases_page') as String;
  List<String> get updatePages => _texts('updates.pages');

  // [support]
  String get supportReport => value('support.report') as String;
  String get supportEmail => value('support.email') as String;
  String get supportDonation => value('support.donation') as String;
  String get supportDirectory => value('support.directory') as String;

  // [links]
  String get linkWebsite => value('links.website') as String;
  String get linkCommunity => value('links.community') as String;
  String get linkSource => value('links.source') as String;

  /// The explorer's page of the block at [height].
  String explorerBlock(int height) => (value('links.explorer_block') as String).replaceAll('{height}', '$height');

  /// The explorer's page of [kernel], or null when the file names none.
  String? explorerKernel(String kernel) {
    final t = value('links.explorer_kernel') as String;
    return t.isEmpty ? null : t.replaceAll('{kernel}', Uri.encodeComponent(kernel));
  }

  // [reach]
  String get reachIpLookup => value('reach.ip_lookup') as String;
  String get reachPortCheck => value('reach.port_check') as String;

  // [import]
  String get importGuiNode => value('import.gui_node') as String;
  String get importGuiEpicbox => value('import.gui_epicbox') as String;
  String get importOldEpicbox => value('import.old_epicbox') as String;
  Map<String, String> get importRenamedEpicbox => value('import.renamed_epicbox') as Map<String, String>;
  List<String> get importDeadFallbacks => _texts('import.dead_fallbacks');

  // [report]
  List<String> get reportKeepHosts => _texts('report.keep_hosts');
  List<String> get reportKeepDomains => _texts('report.keep_domains');

  // [network]
  List<String> get vpnSuffixes => _texts('network.vpn_suffixes');

  /// Every host the file names (servers, sites, onions, the e-mail and donation hosts, the
  /// kept hosts), lower case: what a report keeps besides [reportKeepDomains]. Domain and
  /// suffix lists (`onion_only_domains`, `keep_domains`, `vpn_suffixes`) are not hosts.
  Set<String> get allHosts {
    const notHosts = {'tor.onion_only_domains', 'report.keep_domains', 'network.vpn_suffixes'};
    final out = <String>{};
    void add(String v) {
      if (v.isEmpty) return;
      final at = v.lastIndexOf('@');
      final h = hostOf(at >= 0 ? v.substring(at + 1) : v.replaceAll(RegExp(r'\{[a-z]+\}'), '0'));
      if (isHostName(h)) out.add(h);
    }

    void walk(Object? v) {
      switch (v) {
        case String s:
          add(s);
        case List l:
          l.forEach(walk);
        case Map m:
          for (final e in m.entries) {
            if (m.containsKey('url') || m.containsKey('host')) {
              if (e.key == 'operator') continue;
            } else {
              walk('${e.key}');
            }
            walk(e.value);
          }
      }
    }

    for (final k in settingsKeys) {
      if (!notHosts.contains(k.path)) walk(_values[k.path]);
    }
    return out;
  }

  List<String> _texts(String path) => value(path) as List<String>;
  List<Map<String, Object?>> _entries(String path) => value(path) as List<Map<String, Object?>>;

  @override
  bool operator ==(Object other) =>
      other is HostSettings && settingsKeys.every((k) => deepEquals(_values[k.path], other._values[k.path]));

  @override
  int get hashCode => Object.hashAll([for (final k in settingsKeys) '${_values[k.path]}']);
}

/// Checks a value the app sets; throws [ArgumentError] when [path] is not a key or refuses it.
/// Entries may be maps or [NodeServer], [EpicboxServer] and [OnionRoute].
Object checkAppValue(String path, Object value) {
  final key = settingsKeysByPath[path];
  if (key == null) throw ArgumentError.value(path, 'path', 'not a settings key');
  final c = checkValue(key.kind, toRawValue(value));
  if (!c.ok) throw ArgumentError.value(value, path, c.problem!.name);
  return c.value!;
}

/// [NodeServer], [EpicboxServer] and [OnionRoute] (alone or in a list) as entry maps.
Object toRawValue(Object value) => switch (value) {
  NodeServer s => s.toEntry(),
  EpicboxServer s => s.toEntry(),
  OnionRoute s => s.toEntry(),
  List l => [for (final v in l) v is Object ? toRawValue(v) : v],
  _ => value,
};

// --- the process-wide settings ----------------------------------------------------------------

HostSettings? _current;

/// The settings in use, for code without a `ref`: set at start, replaced on every change.
/// Tests get `test/settings/test.toml` (`flutter_test_config.dart`).
HostSettings get hostSettings =>
    _current ?? (throw StateError('settings.toml is not loaded yet: open it at start (openAppSettings)'));

set hostSettings(HostSettings s) => _current = s;

bool get hostSettingsLoaded => _current != null;

HostSettings? _shippedCurrent;

/// The shipped file's settings of the file in use ("Reset to defaults", "Restore removed", the
/// public servers); [hostSettings] where none was opened (tests).
HostSettings get shippedHostSettings => _shippedCurrent ?? hostSettings;

set shippedHostSettings(HostSettings s) => _shippedCurrent = s;

// --- reading a text ------------------------------------------------------------------------

/// The text is not valid TOML: nothing of it is used.
class SettingsSyntaxError implements Exception {
  const SettingsSyntaxError(this.line, this.message);

  /// 1-based.
  final int line;
  final String message;

  @override
  String toString() => 'settings.toml, line $line: $message';
}

/// A key whose value was not used, and why.
class ValueIssue {
  const ValueIssue(this.key, this.line, this.problem);
  final String key;
  final int? line;
  final ValueProblem problem;

  @override
  bool operator ==(Object other) =>
      other is ValueIssue && other.key == key && other.line == line && other.problem == problem;
  @override
  int get hashCode => Object.hash(key, line, problem);
  @override
  String toString() => 'line $line: $key ${problem.name}';
}

/// A key the layout does not have (a newer wallet's, or a typo), kept in the file.
class UnknownKey {
  const UnknownKey(this.key, this.line);
  final String key;
  final int? line;
  @override
  String toString() => 'line $line: unknown $key';
}

class SettingsRead {
  const SettingsRead(this.settings, this.issues, this.unknown, this.doc);
  final HostSettings settings;
  final List<ValueIssue> issues;
  final List<UnknownKey> unknown;

  /// The parsed text as `package:toml` gives it.
  final Map<String, dynamic> doc;
}

/// Parses [text]; throws [SettingsSyntaxError] with the line when it is not valid TOML.
Map<String, dynamic> parseSettingsToml(String text) {
  try {
    return TomlDocument.parse(text).toMap();
  } on TomlParserException catch (e) {
    throw SettingsSyntaxError(_firstBadLine(text) ?? e.line, e.message);
  } on TomlException catch (e) {
    throw SettingsSyntaxError(_firstBadLine(text) ?? TomlScan(text).duplicateLine() ?? 1, e.message);
  }
}

/// The 1-based line where [text] stops being valid TOML: the shortest start of the text, cut
/// between statements, that does not parse ends on it. The parser's own position can point
/// at an earlier line (the last place it could still go on).
int? _firstBadLine(String text) {
  final scan = TomlScan(text);
  final inside = <int>{};
  for (final s in scan.stmts) {
    for (var l = s.start; l < s.end; l++) {
      inside.add(l);
    }
  }
  final cuts = [
    for (var l = 0; l < scan.lines.length; l++)
      if (!inside.contains(l)) l,
  ];
  bool parses(int cut) {
    try {
      TomlDocument.parse(scan.lines.sublist(0, cut + 1).join('\n'));
      return true;
    } on TomlException {
      return false;
    }
  }

  var lo = 0, hi = cuts.length - 1;
  if (hi < 0 || parses(cuts[hi])) return null;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (parses(cuts[mid])) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  final line = cuts[lo];
  for (final s in scan.stmts) {
    if (s.end == line) return s.start + 1;
  }
  return line + 1;
}

/// The raw value at the dotted [path] of a parsed document, or null.
Object? rawValue(Map<String, dynamic> doc, String path) {
  Object? cur = doc;
  for (final p in path.split('.')) {
    if (cur is! Map) return null;
    cur = cur[p];
  }
  return cur;
}

/// Reads [text] over [shipped]: a good value from the file, else [lastGood]'s, else the
/// shipped one; missing keys read as shipped. Throws [SettingsSyntaxError].
SettingsRead readSettings(String text, {required HostSettings shipped, HostSettings? lastGood}) {
  final doc = parseSettingsToml(text);
  final scan = TomlScan(text);
  final values = <String, Object>{};
  final issues = <ValueIssue>[];
  for (final key in settingsKeys) {
    final raw = rawValue(doc, key.path);
    if (raw == null) {
      values[key.path] = shipped.value(key.path);
      continue;
    }
    final c = checkValue(key.kind, raw);
    if (c.ok) {
      values[key.path] = c.value!;
    } else {
      issues.add(ValueIssue(key.path, _problemLine(scan, key, c), c.problem!));
      values[key.path] = (lastGood ?? shipped).value(key.path);
    }
  }
  return SettingsRead(HostSettings._(values), issues, _unknownKeys(doc, scan), doc);
}

int? _problemLine(TomlScan scan, SettingsKey key, Checked c) {
  final path = [...key.parts, if (c.entry != null) '#${c.entry}', ?c.field];
  return scan.lineOf(path);
}

List<UnknownKey> _unknownKeys(Map<String, dynamic> doc, TomlScan scan) {
  final out = <UnknownKey>[];
  for (final e in doc.entries) {
    final top = e.key;
    // The web demo's own table (faucet, page hosts): its server reads it, the wallet does not.
    if (top == 'demo') continue;
    if (settingsKeysByPath.containsKey(top)) continue;
    if (!settingsTables.contains(top) || e.value is! Map) {
      out.add(UnknownKey(top, scan.lineOf([top])));
      continue;
    }
    for (final k in (e.value as Map<String, dynamic>).entries) {
      final path = '$top.${k.key}';
      final key = settingsKeysByPath[path];
      if (key == null) {
        out.add(UnknownKey(path, scan.lineOf([top, k.key])));
        continue;
      }
      if (key.kind case TablesKind kind when k.value is List) {
        final entries = k.value as List;
        final named = <String>{};
        for (var i = 0; i < entries.length; i++) {
          final entry = entries[i];
          if (entry is! Map) continue;
          for (final f in entry.keys) {
            if (kind.field('$f') == null && named.add('$path.$f')) {
              out.add(UnknownKey('$path.$f', scan.lineOf([top, k.key, '#$i', '$f'])));
            }
          }
        }
      }
    }
  }
  return out;
}
