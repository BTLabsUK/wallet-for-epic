// SPDX-License-Identifier: Apache-2.0
/// The two files' values as the app reads them (docs/settings-file.md):
///
/// - [AppConfig]: `app-config.toml`, shipped read-only with the app: every address, timeout,
///   interval, port and limit that is not the user's. Never written, never in a backup.
/// - [HostSettings]: the user's `settings.toml` (the Node and Epicbox lists, three switches)
///   over the [AppConfig] it came with. Immutable, one typed getter per value, every key
///   filled (from the file when its value is good, else the last good value, else the default
///   copy's). The first entry of each list is the one in use.
///
/// [readSettings] turns a text into one and says what it could not use.
library;

import 'package:toml/toml.dart';

import 'settings_layout.dart';
import 'toml_edit.dart';
import 'toml_scan.dart';

/// A node of the Node list.
class NodeServer {
  const NodeServer({required this.url, this.operator});
  final String url;

  /// Who runs it: `[operators]` of `app-config.toml` by its domain; null when that names none.
  final String? operator;

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

  /// `host` on 443, else `host:port`: how an address and the file name it.
  String get label => epicboxLabel(host, port);

  /// [label] (`host` or `host:port`) as a server, or null when it is not one.
  static EpicboxServer? parse(String label, {String? operator}) {
    if (checkEpicboxServer(label) != null) return null;
    final i = label.lastIndexOf(':');
    if (i < 0) return EpicboxServer(host: label.toLowerCase(), operator: operator);
    return EpicboxServer(host: label.substring(0, i).toLowerCase(), port: int.parse(label.substring(i + 1)), operator: operator);
  }

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

/// Reads every key of [layout] from [doc]: good, or its `byDefault`, or left out (a key only
/// [SettingsKey.requiredWith] others that are all unset), or [StateError] naming the key and
/// line ([text] gives the line).
Map<String, Object> _complete(List<SettingsKey> layout, Map<String, dynamic> doc, String text, String file) {
  final scan = TomlScan(text);
  final values = <String, Object>{};
  for (final key in layout) {
    final raw = rawValue(doc, key.path);
    if (raw == null) {
      if (key.byDefault case final d?) values[key.path] = d;
      if (key.byDefault == null && key.requiredWith == null) throw StateError('$file: ${key.path} is missing');
      continue;
    }
    final c = checkValue(key.kind, raw);
    if (!c.ok) throw StateError('$file, line ${_problemLine(scan, key, c)}: ${key.path} is ${c.problem!.name}');
    values[key.path] = c.value!;
  }
  for (final key in layout) {
    final needs = key.requiredWith;
    if (needs == null || values.containsKey(key.path)) continue;
    final set = needs.where((p) => switch (values[p]) {
      final String s => s.isNotEmpty,
      final List l => l.isNotEmpty,
      _ => false,
    });
    if (set.isNotEmpty) throw StateError('$file: ${key.path} is missing (needed with ${set.first})');
  }
  return values;
}

/// Empty text as null: an entry left out of `app-config.toml` is not configured.
String? _orNull(String v) => v.isEmpty ? null : v;

// --- app-config.toml ------------------------------------------------------------------------

/// `app-config.toml`: the read-only configuration shipped with the app. Every key of
/// [configKeys] has a value.
class AppConfig {
  AppConfig._(Map<String, Object> values) : _values = Map.unmodifiable(values);

  /// The file's name, as messages name it.
  static const String fileName = 'app-config.toml';

  /// A complete file: every required key present and good, or [StateError] naming what is
  /// wrong. A table the layout does not know (a dev chain's `[demo]`) is ignored.
  factory AppConfig.fromText(String text) =>
      AppConfig._(_complete(configKeys, parseSettingsToml(text, file: fileName), text, fileName));

  final Map<String, Object> _values;

  /// The value of [path] in the model's shape (see [checkValue]).
  Object value(String path) =>
      _values[path] ?? (throw ArgumentError.value(path, 'path', 'not an app-config key'));

  Map<String, Object> get values => _values;

  /// This configuration with [changes] (tests: a short timeout, another port). Throws
  /// [ArgumentError] for an unknown key or a value its key refuses.
  AppConfig withValues(Map<String, Object> changes) {
    final next = {..._values};
    changes.forEach((path, v) {
      final key = configKeysByPath[path];
      if (key == null) throw ArgumentError.value(path, 'path', 'not an app-config key');
      final c = checkValue(key.kind, toRawValue(v));
      if (!c.ok) throw ArgumentError.value(v, path, c.problem!.name);
      next[path] = c.value!;
    });
    return AppConfig._(next);
  }

  int _int(String path) => value(path) as int;
  Duration _s(String path) => Duration(seconds: _int(path));
  List<String> _texts(String path) => value(path) as List<String>;
  String _text(String path) => value(path) as String;

  /// Whole seconds (or a count) of an `_s`, `_ms` or number key, for the wallet core's tuning.
  int number(String path) => _int(path);

  // [operators]

  /// Who runs servers under each domain.
  Map<String, String> get operators => value('operators') as Map<String, String>;

  /// Who runs [host] (or a server under it): the longest domain of [operators] that is [host]
  /// or ends it; null when none is.
  String? operatorOf(String host) {
    final h = host.toLowerCase();
    String? best;
    String? name;
    for (final e in operators.entries) {
      final d = e.key.toLowerCase();
      if ((h == d || h.endsWith('.$d')) && (best == null || d.length > best.length)) {
        best = d;
        name = e.value;
      }
    }
    return name;
  }

  // [node]
  Duration get nodeCheckTimeout => _s('node.check_timeout_s');
  Duration get nodeTorCheckTimeout => _s('node.tor_check_timeout_s');
  Duration get nodeTipCheck => _s('node.tip_check_s');
  Duration get nodePoll => _s('node.poll_s');
  Duration get nodeRefresh => _s('node.refresh_s');
  Duration get nodeRecheck => _s('node.recheck_s');
  Duration get nodeStaleAfter => _s('node.stale_after_s');
  Duration get nodeFailoverAfter => _s('node.failover_after_s');
  Duration get nodeFailoverProbe => _s('node.failover_probe_s');
  Duration get ownNodeAsk => _s('node.own_node_ask_s');
  int get localNodeApiPort => _int('node.local.api_port');
  int get localNodeP2pPort => _int('node.local.p2p_port');

  // [epicbox]
  String get epicboxAddressDefault => _text('epicbox.address_default');
  int get pairingServerCount => _int('epicbox.pairing_servers');
  int get linkServerCount => _int('epicbox.link_servers');
  Duration get listenerHealAfter => _s('epicbox.listener_heal_after_s');
  Duration get listenerHealMax => _s('epicbox.listener_heal_max_s');

  // [http]
  int get httpListenPort => _int('http.listen_port');

  // [tor]
  List<Duration> get torStartBackoff => [for (final s in value('tor.start_backoff_s') as List<int>) Duration(seconds: s)];
  Duration get torSendWait => _s('tor.send_wait_s');
  Duration get onionRetry => _s('tor.onion_retry_s');
  List<String> get torOnionOnlyDomains => _texts('tor.onion_only_domains');
  List<OnionRoute> get torOnions => [
    for (final e in value('tor.onions') as List<Map<String, Object?>>)
      OnionRoute(
        host: e['host'] as String,
        port: e['port'] as int,
        onion: e['onion'] as String,
        onionPort: e['onion_port'] as int,
        tls: e['tls'] as bool,
      ),
  ];

  // [status]: each address null when the file leaves it out (that part is not shown).
  Duration get statusTimeout => _s('status.timeout_s');
  Duration get statusTorTimeout => _s('status.tor_timeout_s');
  Duration get statusFresh => _s('status.fresh_s');
  String? get statusDirectory => _orNull(_text('status.directory'));
  String? get statusIcons => _orNull(_text('status.icons'));
  String? get statusPrice => _orNull(_text('status.price'));

  /// The status server's answer with the address it sees this device at; null: no reach check.
  String? get statusIp => _orNull(_text('status.ip'));

  /// The status server's check that [port] of this device's own address answers from outside;
  /// null: no reach check.
  String? statusReach(int port) => _orNull(_text('status.reach'))?.replaceAll('{port}', '$port');
  Duration get reachTimeout => _s('status.reach_timeout_s');

  // [price]: no source and no status-site price, no fiat value.
  Duration get priceRefresh => Duration(minutes: _int('price.refresh_min'));
  Duration get priceTimeout => _s('price.timeout_s');
  Duration get priceFallbackTimeout => _s('price.fallback_timeout_s');
  Duration get priceMaxAge => Duration(minutes: _int('price.max_age_min'));
  String? get priceSource => _orNull(_text('price.source'));

  // [updates]: no manifests, no update check.
  Duration get updatesFirstCheck => _s('updates.first_check_s');
  Duration get updatesEvery => Duration(hours: _int('updates.check_every_h'));
  Duration get updatesTimeout => _s('updates.timeout_s');
  Duration get updatesDownloadStall => _s('updates.download_stall_s');
  List<String> get updateManifests => _texts('updates.manifests');
  String? get updateDownloads => _orNull(_text('updates.downloads'));
  String? get releasesPage => _orNull(_text('updates.releases_page'));
  List<String> get updatePages => _texts('updates.pages');

  // [support]
  Duration get supportTimeout => _s('support.timeout_s');

  /// Where a report is sent; null: no Send report.
  String? get supportReport => _orNull(_text('support.report'));

  /// The support e-mail address; null: none shown.
  String? get supportEmail => _orNull(_text('support.email'));

  /// BT Labs' donation contact, or null when the file leaves it out: no donation entry anywhere.
  String? get supportDonation => _orNull(_text('support.donation'));

  /// BT Labs' signed public file; null: not read.
  String? get supportSignedFile => _orNull(_text('support.signed_file'));

  // [links]: each null when left out (its link is not shown).
  String? get linkWebsite => _orNull(_text('links.website'));
  String? get linkCommunity => _orNull(_text('links.community'));
  String? get linkSource => _orNull(_text('links.source'));
  String? get linkPrivacy => _orNull(_text('links.privacy'));

  // [explorer]

  /// The explorer's page of the block at [height]; null when no explorer is configured.
  String? explorerBlock(int height) => _orNull(_text('explorer.block'))?.replaceAll('{height}', '$height');

  // [import]
  String get importGuiNode => _text('import.gui_node');
  String get importGuiEpicbox => _text('import.gui_epicbox');
  String get importOldEpicbox => _text('import.old_epicbox');
  Map<String, String> get importRenamedEpicbox => value('import.renamed_epicbox') as Map<String, String>;
  List<String> get importDeadFallbacks => _texts('import.dead_fallbacks');

  // [report]
  List<String> get reportKeepHosts => _texts('report.keep_hosts');
  List<String> get reportKeepDomains => _texts('report.keep_domains');

  // [network]
  List<String> get vpnSuffixes => _texts('network.vpn_suffixes');

  // [payments]
  Duration get watchFastEvery => _s('payments.watch_fast_every_s');
  Duration get watchFastFor => _s('payments.watch_fast_for_s');
  Duration get watchSlowEvery => _s('payments.watch_slow_every_s');
  Duration get watchFor => _s('payments.watch_for_s');
  List<Duration> get repostWaits => [for (final m in value('payments.repost_waits_min') as List<int>) Duration(minutes: m)];
  List<Duration> get answerResendWaits => [
    for (final m in value('payments.answer_resend_waits_min') as List<int>) Duration(minutes: m),
  ];

  @override
  bool operator ==(Object other) =>
      other is AppConfig && configKeys.every((k) => deepEquals(_values[k.path], other._values[k.path]));

  @override
  int get hashCode => Object.hashAll([for (final k in configKeys) '${_values[k.path]}']);
}

// --- settings.toml --------------------------------------------------------------------------

/// The user's `settings.toml` over the [config] it came with. Every key of [settingsKeys] has a
/// value. The getters that are not the user's ([statusDirectory], …) read [config].
class HostSettings {
  HostSettings._(Map<String, Object> values, this.config) : _values = Map.unmodifiable(values);

  /// A complete user file (the default copy, or a test's) over [config]: every key present
  /// and good, or [StateError] naming what is wrong.
  factory HostSettings.fromText(String text, {required AppConfig config}) =>
      HostSettings._(_complete(settingsKeys, parseSettingsToml(text), text, 'settings.toml'), config);

  final Map<String, Object> _values;

  /// `app-config.toml`, read-only.
  final AppConfig config;

  /// The value of [path] (a `settings.toml` key, else an `app-config.toml` one) in the model's
  /// shape (see [checkValue]).
  Object value(String path) => _values[path] ?? config.value(path);

  /// The `settings.toml` values.
  Map<String, Object> get values => _values;

  /// These settings with [changes] (paths to values in the model's shape). A path of
  /// `app-config.toml` changes [config] (tests only: the app never writes it). Throws
  /// [ArgumentError] for an unknown key or a value its key refuses.
  HostSettings withValues(Map<String, Object> changes) {
    final next = {..._values};
    final configChanges = <String, Object>{};
    changes.forEach((path, v) {
      if (configKeysByPath.containsKey(path)) {
        configChanges[path] = v;
      } else {
        next[path] = checkAppValue(path, v);
      }
    });
    return HostSettings._(next, configChanges.isEmpty ? config : config.withValues(configChanges));
  }

  /// These settings over another [config] (a dev chain's).
  HostSettings withConfig(AppConfig config) => HostSettings._(_values, config);

  // [node]

  /// The Node list's addresses, in order; the first is in use.
  List<String> get nodeUrls => _texts('node.servers');

  /// The Node list, in order, each with its operator from `[operators]`.
  List<NodeServer> get nodeServers => [for (final u in nodeUrls) NodeServer(url: u, operator: config.operatorOf(hostOf(u)))];

  /// Whether the Node list has a node (an empty list: none is configured).
  bool get hasNode => nodeUrls.isNotEmpty;

  /// The node in use: the first of the list; empty text when the list is empty.
  String get nodeUse => nodeUrls.firstOrNull ?? '';

  /// The node tried when the one in use does not answer: the next of the list (the one in use
  /// when it is the only one).
  String get nodeFallback => nodeUrls.length > 1 ? nodeUrls[1] : nodeUse;

  // [epicbox]

  /// The Epicbox list's labels (`host`, or `host:port` off 443), in order; the first is in use.
  List<String> get epicboxLabels => _texts('epicbox.servers');

  List<EpicboxServer> get epicboxServers => [
    for (final l in epicboxLabels)
      if (EpicboxServer.parse(l) case final s?) EpicboxServer(host: s.host, port: s.port, operator: config.operatorOf(s.host)),
  ];

  /// Whether the Epicbox list has a server (an empty list: none is configured).
  bool get hasEpicbox => epicboxServers.isNotEmpty;

  /// The server every wallet's Epicbox address names: the first of the list; empty text when
  /// the list is empty.
  String get epicboxUse => epicboxServers.firstOrNull?.label ?? '';

  /// The server of an Epicbox address written without one (`app-config.toml`).
  String get epicboxDefault => config.epicboxAddressDefault;

  /// Where two wallets meet by spoken words: the first `epicbox.pairing_servers` of the list.
  List<String> get pairingServers => [for (final s in epicboxServers.take(config.pairingServerCount)) s.label];

  /// The servers linked devices use: the first `epicbox.link_servers` of the list.
  List<String> get deviceLinkServers => [for (final s in epicboxServers.take(config.linkServerCount)) s.label];

  // [network]: the network mode (`network_mode_file.dart` reads it as a NetworkMode).

  /// `network.mode` as written: `tor_only`, `node_only`, `kill_switch`, or empty for Normal.
  String get networkModeText => value('network.mode') as String;

  // [local_node]: the built-in node's ports, the user's over `[node.local]` of app-config.toml.

  /// The built-in node's API port: `local_node.api_port` when set, else `node.local.api_port`.
  int get localNodeApiPort => _portOr('local_node.api_port', config.localNodeApiPort);

  /// The built-in node's P2P port: `local_node.p2p_port` when set, else `node.local.p2p_port`.
  int get localNodeP2pPort => _portOr('local_node.p2p_port', config.localNodeP2pPort);

  /// Whether the user set a port of the built-in node (the file has a `[local_node]` key).
  bool get localNodePortsSet => value('local_node.api_port') != notSet || value('local_node.p2p_port') != notSet;

  int _portOr(String path, int byDefault) {
    final v = value(path) as int;
    return v == notSet ? byDefault : v;
  }

  // [invite]

  /// `invite.page`: the page an invite's https link opens; empty shares the bare invite.
  String get invitePage => value('invite.page') as String;

  // [online]
  bool get statusEnabled => value('online.status_site') as bool;
  bool get updatesCheck => value('online.update_check') as bool;
  bool get priceEnabled => value('online.price') as bool;

  // app-config.toml, by the names the app has always read them under.
  List<String> get torOnionOnlyDomains => config.torOnionOnlyDomains;
  List<OnionRoute> get torOnions => config.torOnions;
  String? get statusDirectory => config.statusDirectory;
  String? get statusIcons => config.statusIcons;
  String? get statusPrice => config.statusPrice;
  String? get priceSource => config.priceSource;
  List<String> get updateManifests => config.updateManifests;
  String? get updateDownloads => config.updateDownloads;
  String? get releasesPage => config.releasesPage;
  List<String> get updatePages => config.updatePages;
  String? get supportReport => config.supportReport;
  String? get supportEmail => config.supportEmail;
  String? get supportDonation => config.supportDonation;
  String? get supportDirectory => config.supportSignedFile;
  String? get linkWebsite => config.linkWebsite;
  String? get linkCommunity => config.linkCommunity;
  String? get linkSource => config.linkSource;
  String? get linkPrivacy => config.linkPrivacy;
  String? explorerBlock(int height) => config.explorerBlock(height);
  String get importGuiNode => config.importGuiNode;
  String get importGuiEpicbox => config.importGuiEpicbox;
  String get importOldEpicbox => config.importOldEpicbox;
  Map<String, String> get importRenamedEpicbox => config.importRenamedEpicbox;
  List<String> get importDeadFallbacks => config.importDeadFallbacks;
  List<String> get reportKeepHosts => config.reportKeepHosts;
  List<String> get reportKeepDomains => config.reportKeepDomains;
  List<String> get vpnSuffixes => config.vpnSuffixes;

  /// Every host the two files name (servers, sites, onions, the e-mail and donation hosts, the
  /// kept hosts, the operators' domains), lower case: on the default copy, what a report keeps
  /// besides [reportKeepDomains]. Domain and suffix lists (`onion_only_domains`, `keep_domains`,
  /// `vpn_suffixes`) are not hosts.
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
            if (!m.containsKey('host')) walk('${e.key}');
            walk(e.value);
          }
      }
    }

    for (final k in settingsKeys) {
      walk(_values[k.path]);
    }
    for (final k in configKeys) {
      if (k.path == 'operators') {
        // Domains, not hosts; their names are not addresses.
        continue;
      }
      if (!notHosts.contains(k.path)) walk(config.values[k.path]);
    }
    return out;
  }

  List<String> _texts(String path) => value(path) as List<String>;

  @override
  bool operator ==(Object other) =>
      other is HostSettings &&
      other.config == config &&
      settingsKeys.every((k) => deepEquals(_values[k.path], other._values[k.path]));

  @override
  int get hashCode => Object.hash(config, Object.hashAll([for (final k in settingsKeys) '${_values[k.path]}']));
}

/// The `[local_node]` values to write for the built-in node's ports [api] and [p2p]: a port
/// equal to `app-config.toml`'s is written as [notSet], which takes its key out of the file.
Map<String, Object> localNodePortValues(HostSettings s, {required int api, required int p2p}) => {
  'local_node.api_port': api == s.config.localNodeApiPort ? notSet : api,
  'local_node.p2p_port': p2p == s.config.localNodeP2pPort ? notSet : p2p,
};

/// Checks a `settings.toml` value the app sets; throws [ArgumentError] when [path] is not a key
/// of it or refuses [value].
Object checkAppValue(String path, Object value) {
  final key = settingsKeysByPath[path];
  if (key == null) throw ArgumentError.value(path, 'path', 'not a settings key');
  // An optional key at its "not set" value: left out of the file, the default applies.
  if (key.byDefault != null && deepEquals(value, key.byDefault)) return key.byDefault!;
  final c = checkValue(key.kind, toRawValue(value));
  if (!c.ok) throw ArgumentError.value(value, path, c.problem!.name);
  return c.value!;
}

/// [OnionRoute] (alone or in a list) as entry maps.
Object toRawValue(Object value) => switch (value) {
  OnionRoute s => s.toEntry(),
  List l => [for (final v in l) v is Object ? toRawValue(v) : v],
  _ => value,
};

// --- the process-wide settings ----------------------------------------------------------------

HostSettings? _current;

/// The settings in use, for code without a `ref`: set at start, replaced on every change.
/// Tests get `test/settings/` (`flutter_test_config.dart`).
HostSettings get hostSettings =>
    _current ?? (throw StateError('settings.toml is not loaded yet: open it at start (openAppSettings)'));

set hostSettings(HostSettings s) => _current = s;

bool get hostSettingsLoaded => _current != null;

/// `app-config.toml` in use: [hostSettings]'s.
AppConfig get appConfig => hostSettings.config;

HostSettings? _shippedCurrent;

/// The default copy (`settings.default.toml`) over the configuration in use: "Reset to
/// defaults" and the built-in servers; [hostSettings] where none was opened (tests).
HostSettings get shippedHostSettings => _shippedCurrent ?? hostSettings;

set shippedHostSettings(HostSettings s) => _shippedCurrent = s;

// --- reading a text ------------------------------------------------------------------------

/// The text is not valid TOML: nothing of it is used.
class SettingsSyntaxError implements Exception {
  const SettingsSyntaxError(this.line, this.message, {this.file = 'settings.toml'});

  /// 1-based.
  final int line;
  final String message;

  /// The file's name.
  final String file;

  @override
  String toString() => '$file, line $line: $message';
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
Map<String, dynamic> parseSettingsToml(String text, {String file = 'settings.toml'}) {
  try {
    return TomlDocument.parse(text).toMap();
  } on TomlParserException catch (e) {
    throw SettingsSyntaxError(_firstBadLine(text) ?? e.line, e.message, file: file);
  } on TomlException catch (e) {
    throw SettingsSyntaxError(_firstBadLine(text) ?? TomlScan(text).duplicateLine() ?? 1, e.message, file: file);
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

/// Reads [text] over [shipped] (the default copy, with the configuration in use): a good value
/// from the file, else [lastGood]'s, else the default copy's; a missing key reads as the
/// default copy's. Throws [SettingsSyntaxError].
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
      // A network mode the app can't read, with no good one before it, fails closed: the user
      // asked for some mode, so nothing connects until the file names one it can read.
      values[key.path] = lastGood?.value(key.path) ??
          (key.path == 'network.mode' ? 'kill_switch' : shipped.value(key.path));
    }
  }
  return SettingsRead(HostSettings._(values, shipped.config), issues, _unknownKeys(doc, scan), doc);
}

int? _problemLine(TomlScan scan, SettingsKey key, Checked c) {
  final path = [...key.parts, if (c.entry != null) '#${c.entry}', ?c.field];
  return scan.lineOf(path);
}

List<UnknownKey> _unknownKeys(Map<String, dynamic> doc, TomlScan scan) {
  final out = <UnknownKey>[];
  for (final e in doc.entries) {
    final top = e.key;
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
