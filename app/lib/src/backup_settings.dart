// SPDX-License-Identifier: Apache-2.0
/// The settings a history backup (`.wfeh` v2) carries, and how an import takes them back.
///
/// One portable map for the phone and the desktop, written by each app's glue
/// (`ui/backup_settings_phone.dart`, `desktop/data/backup_settings_desk.dart`) and sealed into
/// the file as an opaque JSON object (`HistoryPayload.settings`):
///
/// ```json
/// {"v": 1, "from": "mobile",
///  "theme": "dark", "language": "pl", "helpLanguage": null, "hideBalances": false,
///  "statusSite": true, "autoLock": 15, "advanced": {...}, "payments": {...},
///  "sendStrategy": "smallest", "splitChange": true, "fiat": "usd", "showFiat": true,
///  "node": {"mainnet": "https://..."}, "relay": {"mainnet": "epicbox.epiccash.com"},
///  "nodeList": {"mainnet": {"entries": [...], "removed": [...]}}, "relayList": {...},
///  "tor": false, "seenAs": "Alice",
///  "desktop": {"nodes": [{"url": "...", "label": "home"}], "invoiceExpiry": 86400,
///              "seedsDeleted": ["btlabs"], "ownRelay": null, "epicboxAutostart": true}}
/// ```
///
/// Never in it: push on/off and tokens (turning push on contacts Google and asks the OS), the
/// desktop's HTTP public mode and port (public mode opens the wallet to the internet; only the
/// guide's explicit choice sets it), the built-in node's settings and paths (this machine's
/// folders), the interface scale (this screen's), the PIN, password and remembered password,
/// and the tour, tips, reminder and update bookkeeping.
///
/// [planBackupSettings] is pure: given this app's current values, a fresh install's and the
/// file's, it says which settings are taken silently and which are real conflicts. The glue
/// applies [BackupSettingsPlan.values] through each app's own setters.
library;

import 'dart:convert';

import 'advanced.dart';
import 'l10n.dart' show appLanguages;
import 'models.dart' show SelectionStrategy;
import 'net/local_address.dart' show isLocalNodeUrl;
import 'payment_prefs.dart';
import 'server_list.dart';
import 'settings.dart' show autoLockChoice;

/// The map's version. A file with a newer one is skipped whole: its keys may mean other things.
const int backupSettingsVersion = 1;

/// Which app wrote the map (`from`).
enum BackupPlatform { mobile, desktop }

/// The map's keys. Node, relay and the lists are maps by chain name; [desktop] holds the
/// desktop-only items under [BackupKey.deskNodes] and the others below it.
abstract final class BackupKey {
  static const v = 'v';
  static const from = 'from';
  static const theme = 'theme';
  static const language = 'language';
  static const helpLanguage = 'helpLanguage';
  static const hideBalances = 'hideBalances';
  static const statusSite = 'statusSite';
  static const autoLock = 'autoLock';
  static const advanced = 'advanced';
  static const payments = 'payments';
  static const sendStrategy = 'sendStrategy';
  static const splitChange = 'splitChange';
  static const fiat = 'fiat';
  static const showFiat = 'showFiat';
  static const node = 'node';
  static const relay = 'relay';
  static const nodeList = 'nodeList';
  static const relayList = 'relayList';
  static const tor = 'tor';
  static const seenAs = 'seenAs';
  static const desktop = 'desktop';

  // In [desktop].
  static const deskNodes = 'nodes';
  static const invoiceExpiry = 'invoiceExpiry';
  static const seedsDeleted = 'seedsDeleted';
  static const ownRelay = 'ownRelay';
  static const epicboxAutostart = 'epicboxAutostart';

  /// [autoLock]'s value for never.
  static const never = 'never';
}

/// What a plan names each setting by ([BackupSettingItem.key], [BackupSettingsPlan.values]).
/// The Advanced page is three: its features, its network mode and node failover, so a stricter
/// mode is never held back by a feature switch, nor one taken with it.
abstract final class BackupItem {
  static const theme = BackupKey.theme;
  static const language = BackupKey.language;
  static const helpLanguage = BackupKey.helpLanguage;
  static const hideBalances = BackupKey.hideBalances;
  static const statusSite = BackupKey.statusSite;
  static const autoLock = BackupKey.autoLock;
  static const features = 'advanced.features';
  static const networkMode = 'advanced.networkMode';
  static const nodeFailover = 'advanced.nodeFailover';
  static const payments = BackupKey.payments;
  static const sendStrategy = BackupKey.sendStrategy;
  static const splitChange = BackupKey.splitChange;
  static const fiat = BackupKey.fiat;
  static const showFiat = BackupKey.showFiat;
  static const node = BackupKey.node;
  static const relay = BackupKey.relay;
  static const nodeList = BackupKey.nodeList;
  static const relayList = BackupKey.relayList;
  static const tor = BackupKey.tor;
  static const seenAs = BackupKey.seenAs;
  static const deskNodes = 'desktop.nodes';
  static const invoiceExpiry = 'desktop.invoiceExpiry';
  static const seedsDeleted = 'desktop.seedsDeleted';
  static const ownRelay = 'desktop.ownRelay';
  static const epicboxAutostart = 'desktop.epicboxAutostart';
  static const walletName = 'walletName';
}

/// The Advanced features only one app has: the phone's File switch, the desktop's built-in
/// node. A file from the other app neither sets nor clears them.
const Map<BackupPlatform, Set<AdvancedFeature>> platformOnlyFeatures = {
  BackupPlatform.mobile: {AdvancedFeature.transactionFiles},
  BackupPlatform.desktop: {AdvancedFeature.builtInNode},
};

/// The longest invoice expiry the desktop keeps (its `maxInvoiceExpiry`), in seconds.
const int maxBackupInvoiceExpirySecs = 48 * 3600;

/// A desktop wallet name the app gave itself ("Main wallet", "Wallet 1", "Wallet 2"…): a
/// file's name replaces it without asking.
bool isDefaultWalletName(String name) {
  final t = name.trim();
  return t.isEmpty || t == 'Main wallet' || RegExp(r'^Wallet \d+$').hasMatch(t); // l10n-ok: the names the app stores
}

/// [m] as a [ServerList] JSON object (`{"entries": [...], "removed": [...]}`), for the map.
Map<String, Object?> serverListJson(ServerList list) => {
  'entries': [...list.entries],
  'removed': [...list.removed]..sort(),
};

/// A list from the map: entries that are no server address of [kind] are dropped; null when
/// [j] is no list object.
ServerList? serverListFromJson(ServerKind kind, Object? j) {
  if (j is! Map) return null;
  final entries = <String>[];
  final keys = <String>{};
  final raw = j['entries'];
  if (raw is List) {
    for (final e in raw) {
      final v = e is String ? typedServerValue(kind, e) : null;
      if (v != null && keys.add(serverKeyOf(kind, v))) entries.add(v);
    }
  }
  final removed = j['removed'];
  return ServerList(
    entries: entries,
    removed: {
      if (removed is List)
        for (final e in removed)
          if (e is String && e.isNotEmpty && e.length <= 300) e,
    },
  );
}

/// [mine] with what [file] adds: its entries this list lacks (and did not remove here) at the
/// end, in its order, and its removals of servers this list does not show. Nothing of [mine]
/// is ever dropped.
ServerList mergeServerLists(ServerKind kind, ServerList mine, ServerList file) {
  final merged = mine.absorb(kind, file.entries);
  final removed = {...merged.removed};
  for (final k in file.removed) {
    if (!merged.entries.any((e) => serverKeyOf(kind, e) == k)) removed.add(k);
  }
  return ServerList(entries: merged.entries, removed: removed);
}

/// One setting in a [BackupSettingsPlan]: [mine] is the value here, [backup] the one the import
/// would set (the file's, mapped to this app; for a list, the merge).
class BackupSettingItem {
  const BackupSettingItem(this.key, {required this.mine, required this.backup});

  /// A [BackupItem] name.
  final String key;
  final Object? mine;
  final Object? backup;

  @override
  String toString() => '$key: ${jsonEncode(mine)} → ${jsonEncode(backup)}';
}

/// What an import does with a file's settings.
class BackupSettingsPlan {
  const BackupSettingsPlan({this.take = const [], this.conflicts = const [], this.refused = const [], this.skipped = const []});

  /// No settings in the file, or none this app reads.
  static const BackupSettingsPlan empty = BackupSettingsPlan();

  /// Set without asking: the value here is a fresh install's, or a list gains entries.
  final List<BackupSettingItem> take;

  /// Changed here by the user and different in the file: set only when the user takes the
  /// backup's ("Use the settings from this backup?").
  final List<BackupSettingItem> conflicts;

  /// Kept out for safety, whatever the user answers: a node in the file on this computer, the
  /// local network or a tailnet is never made the node in use (its list entry stays).
  final List<BackupSettingItem> refused;

  /// Keys the file had that this app does not read, or whose value was not valid (or the whole
  /// map, `v`, when it is newer or not one).
  final List<String> skipped;

  bool get hasConflicts => conflicts.isNotEmpty;

  /// Nothing would change.
  bool get isEmpty => take.isEmpty && conflicts.isEmpty;

  /// The settings to apply, by [BackupItem] name: every [take], and the [conflicts] when
  /// [takeConflicts].
  Map<String, Object?> values({required bool takeConflicts}) => {
    for (final i in take) i.key: i.backup,
    if (takeConflicts)
      for (final i in conflicts) i.key: i.backup,
  };

  @override
  String toString() => 'BackupSettingsPlan(take: $take, conflicts: $conflicts, refused: $refused, skipped: $skipped)';
}

/// Marks a key this map does not have (null is a value: "follow the system").
const Object _absent = Object();

/// Plans the import of [file], a backup's settings map, into this app ([here]) on [chain]
/// ([Chain.name]). [mine] is what this app has now and [defaults] what a fresh install has,
/// both in the map's own form (the glue writes them with the same encoder as the export);
/// a key [mine] lacks is not read here. For each setting the file has, mapped to this app:
/// - the same as here: nothing;
/// - here a fresh install's value: taken ([BackupSettingsPlan.take]);
/// - here changed by the user and different: a conflict ([BackupSettingsPlan.conflicts]).
/// The Node and Epicbox lists, own nodes and deleted seed contacts merge instead (never a
/// conflict, nothing here dropped). The network mode follows the same rule, so a less strict
/// mode never replaces a stricter one the user chose without asking. A node on this computer,
/// the local network or a tailnet is never planned as the node in use. Unknown keys and bad
/// values are skipped; a newer [backupSettingsVersion] skips the whole map. Never throws.
///
/// The desktop passes [fileWalletName] (the file's) and [myWalletName]: a name the app gave
/// ([isDefaultWalletName]) is replaced, a name the user gave is a conflict.
BackupSettingsPlan planBackupSettings({
  required BackupPlatform here,
  required String chain,
  required Map<String, Object?> mine,
  required Map<String, Object?> defaults,
  required Object? file,
  String? fileWalletName,
  String? myWalletName,
}) {
  try {
    return _plan(here, chain, mine, defaults, file, fileWalletName, myWalletName);
  } on Object {
    // A value of a shape no check foresaw: nothing from this file.
    return const BackupSettingsPlan(skipped: [BackupKey.v]);
  }
}

BackupSettingsPlan _plan(
  BackupPlatform here,
  String chain,
  Map<String, Object?> mine,
  Map<String, Object?> defaults,
  Object? file,
  String? fileWalletName,
  String? myWalletName,
) {
  final take = <BackupSettingItem>[];
  final conflicts = <BackupSettingItem>[];
  final refused = <BackupSettingItem>[];
  final skipped = <String>[];

  void decide(String key, Object? m, Object? d, Object? target) {
    if (_same(target, m)) return;
    final item = BackupSettingItem(key, mine: m, backup: target);
    (_same(m, d) ? take : conflicts).add(item);
  }

  void merged(String key, Object? m, Object? target) {
    if (!_same(target, m)) take.add(BackupSettingItem(key, mine: m, backup: target));
  }

  final name = fileWalletName?.trim() ?? '';
  // A name the old app gave itself is no choice: it never replaces one here.
  if (myWalletName != null && name.isNotEmpty && name.length <= 32 && !isDefaultWalletName(name)) {
    if (name != myWalletName.trim()) {
      final item = BackupSettingItem(BackupItem.walletName, mine: myWalletName, backup: name);
      (isDefaultWalletName(myWalletName) ? take : conflicts).add(item);
    }
  }

  if (file is! Map) return BackupSettingsPlan(take: take, conflicts: conflicts);
  final f = Map<String, Object?>.from(file);
  final version = f[BackupKey.v];
  final from = BackupPlatform.values.where((p) => p.name == f[BackupKey.from]).firstOrNull;
  if (version is! int || version < 1 || version > backupSettingsVersion || from == null) {
    return BackupSettingsPlan(take: take, conflicts: conflicts, skipped: const [BackupKey.v]);
  }
  final other = from != here;

  // The keys the map can hold; anything else in the file is skipped.
  const known = {
    BackupKey.v, BackupKey.from, BackupKey.theme, BackupKey.language, BackupKey.helpLanguage,
    BackupKey.hideBalances, BackupKey.statusSite, BackupKey.autoLock, BackupKey.advanced,
    BackupKey.payments, BackupKey.sendStrategy, BackupKey.splitChange, BackupKey.fiat,
    BackupKey.showFiat, BackupKey.node, BackupKey.relay, BackupKey.nodeList, BackupKey.relayList,
    BackupKey.tor, BackupKey.seenAs, BackupKey.desktop,
  };
  for (final k in f.keys) {
    if (!known.contains(k)) skipped.add(k);
  }

  /// One plain setting: the file's value read by [read] (null when not valid), compared with
  /// this app's; a key this app does not have is not planned.
  void plain(String key, Object? Function(Object? raw) read, {Object? Function(Object? value)? map}) {
    if (!f.containsKey(key)) return;
    if (!mine.containsKey(key)) {
      skipped.add(key);
      return;
    }
    final value = read(f[key]);
    if (identical(value, _absent)) {
      skipped.add(key);
      return;
    }
    final target = map == null ? value : map(value);
    if (identical(target, _absent)) return;
    Object? held(Object? raw) {
      final x = read(raw);
      return identical(x, _absent) ? null : x;
    }

    decide(key, held(mine[key]), held(defaults[key]), target);
  }

  // Display.
  plain(BackupKey.theme, _theme, map: (v) => other && v == _defaultTheme[from] ? _absent : v);
  plain(BackupKey.language, _language);
  plain(BackupKey.helpLanguage, _language);
  plain(BackupKey.hideBalances, _bool);
  plain(BackupKey.statusSite, _bool);
  plain(BackupKey.autoLock, _autoLock);
  plain(BackupKey.sendStrategy, _strategy);
  plain(BackupKey.splitChange, _bool);
  plain(BackupKey.fiat, _fiat);
  plain(BackupKey.showFiat, _bool);
  plain(BackupKey.tor, _bool);
  plain(BackupKey.seenAs, _seenAs, map: (v) => v == '' ? _absent : v);

  // Advanced: features, network mode and failover each on their own.
  if (f.containsKey(BackupKey.advanced)) {
    final raw = f[BackupKey.advanced];
    if (raw is! Map || !mine.containsKey(BackupKey.advanced)) {
      skipped.add(BackupKey.advanced);
    } else {
      final file = AdvancedPrefs.fromJson(raw);
      final m = AdvancedPrefs.fromJson(mine[BackupKey.advanced]);
      final d = AdvancedPrefs.fromJson(defaults[BackupKey.advanced]);
      if (raw['features'] is List) {
        var features = file.features;
        if (other) {
          final own = platformOnlyFeatures[here]!;
          features = {...features.difference(own).difference(platformOnlyFeatures[from]!), ...m.features.intersection(own)};
        }
        // Linked devices is this install's own choice: a file neither sets nor clears it.
        features = {...features.where((f) => f != AdvancedFeature.linkedDevices), if (m.linkedDevicesOn) AdvancedFeature.linkedDevices};
        decide(BackupItem.features, _names(m.features), _names(d.features), _names(features));
      }
      if (NetworkMode.values.any((x) => x.name == raw['networkMode'])) {
        decide(BackupItem.networkMode, m.networkMode.name, d.networkMode.name, file.networkMode.name);
      }
      if (raw['nodeFailover'] is bool) {
        decide(BackupItem.nodeFailover, m.nodeFailover, d.nodeFailover, file.nodeFailover);
      }
    }
  }

  // Payment methods, mapped to this app: a flag whose default differs between the apps is
  // taken only when the file's app had it changed; QR Payment never crosses.
  if (f.containsKey(BackupKey.payments)) {
    final raw = f[BackupKey.payments];
    if (raw is! Map || !mine.containsKey(BackupKey.payments)) {
      skipped.add(BackupKey.payments);
    } else {
      final m = PaymentPrefs.fromJson(mine[BackupKey.payments]);
      final d = PaymentPrefs.fromJson(defaults[BackupKey.payments]);
      var target = PaymentPrefs.fromJson(raw);
      if (other) {
        final source = from == BackupPlatform.mobile ? PaymentPrefs.phoneDefaults : PaymentPrefs.defaults;
        target = target.copyWith(
          directQr: m.directQr,
          directFile: target.directFile != source.directFile ? target.directFile : m.directFile,
          defaultMethod: target.defaultMethod == MethodKind.directQr ? m.defaultMethod : null,
        );
      }
      if (target.on.isEmpty) {
        skipped.add(BackupKey.payments);
      } else {
        decide(BackupItem.payments, m.toJson(), d.toJson(), target.toJson());
      }
    }
  }

  // The node and Epicbox server in use, this chain's.
  Object? perChain(Map<String, Object?> m, String key) {
    final j = m[key];
    return j is Map ? (j.containsKey(chain) ? j[chain] : _absent) : _absent;
  }

  void server(String key, ServerKind kind) {
    if (!f.containsKey(key)) return;
    final raw = perChain(f, key);
    if (identical(raw, _absent)) return;
    final value = raw is String ? typedServerValue(kind, raw) : null;
    if (value == null || !mine.containsKey(key)) {
      skipped.add(key);
      return;
    }
    final m = perChain(mine, key);
    final d = perChain(defaults, key);
    if (kind == ServerKind.node && isLocalNodeUrl(value)) {
      if (!_same(value, m)) refused.add(BackupSettingItem(key, mine: m, backup: value));
      return;
    }
    decide(key, identical(m, _absent) ? null : m, identical(d, _absent) ? null : d, value);
  }

  server(BackupKey.node, ServerKind.node);
  server(BackupKey.relay, ServerKind.relay);

  // The lists merge.
  void list(String key, ServerKind kind) {
    if (!f.containsKey(key)) return;
    final raw = perChain(f, key);
    if (identical(raw, _absent)) return;
    final file = serverListFromJson(kind, raw);
    if (file == null || !mine.containsKey(key)) {
      skipped.add(key);
      return;
    }
    final m = serverListFromJson(kind, perChain(mine, key)) ?? const ServerList();
    merged(key, serverListJson(m), serverListJson(mergeServerLists(kind, m, file)));
  }

  list(BackupKey.nodeList, ServerKind.node);
  list(BackupKey.relayList, ServerKind.relay);

  // The desktop's own items.
  final deskRaw = f[BackupKey.desktop];
  final deskMine = mine[BackupKey.desktop];
  if (f.containsKey(BackupKey.desktop)) {
    if (deskRaw is! Map || deskMine is! Map) {
      skipped.add(BackupKey.desktop);
    } else {
      final deskDefaults = defaults[BackupKey.desktop] is Map ? defaults[BackupKey.desktop] as Map : const {};
      void desk(String key, String item, Object? Function(Object? raw) read) {
        if (!deskRaw.containsKey(key) || !deskMine.containsKey(key)) return;
        final value = read(deskRaw[key]);
        if (identical(value, _absent)) {
          skipped.add('${BackupKey.desktop}.$key');
          return;
        }
        Object? held(Object? raw) {
          final x = read(raw);
          return identical(x, _absent) ? null : x;
        }

        decide(item, held(deskMine[key]), held(deskDefaults[key]), value);
      }

      desk(BackupKey.invoiceExpiry, BackupItem.invoiceExpiry, _expiry);
      desk(BackupKey.epicboxAutostart, BackupItem.epicboxAutostart, _bool);
      desk(BackupKey.ownRelay, BackupItem.ownRelay, (v) => v == null ? null : (v is String ? typedRelayLabel(v) ?? _absent : _absent));
      if (deskRaw.containsKey(BackupKey.deskNodes) && deskMine.containsKey(BackupKey.deskNodes)) {
        final m = _ownNodes(deskMine[BackupKey.deskNodes]);
        final out = [...m];
        for (final n in _ownNodes(deskRaw[BackupKey.deskNodes])) {
          if (!out.any((o) => sameServer(ServerKind.node, o['url']!, n['url']!))) out.add(n);
        }
        merged(BackupItem.deskNodes, m, out);
      }
      if (deskRaw.containsKey(BackupKey.seedsDeleted) && deskMine.containsKey(BackupKey.seedsDeleted)) {
        final m = _ids(deskMine[BackupKey.seedsDeleted]);
        merged(BackupItem.seedsDeleted, m, ({...m, ..._ids(deskRaw[BackupKey.seedsDeleted])}.toList()..sort()));
      }
      for (final k in deskRaw.keys) {
        if (!const {BackupKey.deskNodes, BackupKey.invoiceExpiry, BackupKey.seedsDeleted, BackupKey.ownRelay, BackupKey.epicboxAutostart}.contains(k)) {
          skipped.add('${BackupKey.desktop}.$k');
        }
      }
    }
  }

  return BackupSettingsPlan(take: take, conflicts: conflicts, refused: refused, skipped: skipped);
}

/// The theme each app starts with: the phone follows the system, the desktop is dark.
const Map<BackupPlatform, String> _defaultTheme = {BackupPlatform.mobile: 'system', BackupPlatform.desktop: 'dark'};

Object? _theme(Object? v) => const {'system', 'dark', 'light'}.contains(v) ? v : _absent;

Object? _language(Object? v) => v == null || appLanguages.any((a) => a.code == v) ? v : _absent;

Object? _bool(Object? v) => v is bool ? v : _absent;

Object? _autoLock(Object? v) => v == BackupKey.never
    ? v
    : v is int && v >= 0 && v <= 24 * 60
    ? autoLockChoice(v)
    : _absent;

Object? _strategy(Object? v) => SelectionStrategy.values.any((s) => s.name == v) ? v : _absent;

Object? _fiat(Object? v) => v is String && RegExp(r'^[a-z]{2,10}$').hasMatch(v.trim().toLowerCase()) ? v.trim().toLowerCase() : _absent;

Object? _seenAs(Object? v) {
  if (v is! String) return _absent;
  final t = v.trim();
  return utf8.encode(t).length <= 48 ? t : _absent;
}

Object? _expiry(Object? v) => v is int && v > 0 ? (v > maxBackupInvoiceExpirySecs ? maxBackupInvoiceExpirySecs : v) : _absent;

List<String> _names(Set<AdvancedFeature> features) => features.map((f) => f.name).toList()..sort();

/// The desktop's own nodes (`desk.nodes`): url and label, valid node addresses only.
List<Map<String, String>> _ownNodes(Object? j) => [
  if (j is List)
    for (final o in j)
      if (o is Map && o['url'] is String && typedNodeUrl(o['url'] as String) != null)
        {'url': o['url'] as String, 'label': o['label'] is String ? (o['label'] as String) : ''},
];

List<String> _ids(Object? j) => [
  if (j is List)
    for (final e in j)
      if (e is String && e.isNotEmpty && e.length <= 64) e,
]..sort();

/// Deep equality of JSON values; a map's key order does not count.
bool _same(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !_same(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_same(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

// ---- Reading a plan's values back, for the glue.

/// [current] with the Advanced parts in [values] ([BackupItem.features], [BackupItem.networkMode],
/// [BackupItem.nodeFailover]); [current] itself when none is there.
AdvancedPrefs advancedFromBackup(AdvancedPrefs current, Map<String, Object?> values) {
  var next = current;
  final features = values[BackupItem.features];
  if (features is List) {
    next = AdvancedPrefs(
      features: {
        for (final n in features)
          for (final f in AdvancedFeature.values)
            if (f.name == n && f != AdvancedFeature.linkedDevices) f,
        // This install's own choice, never from a file.
        if (current.linkedDevicesOn) AdvancedFeature.linkedDevices,
      },
      networkMode: next.networkMode,
      nodeFailover: next.nodeFailover,
    );
  }
  final mode = NetworkMode.values.where((m) => m.name == values[BackupItem.networkMode]).firstOrNull;
  if (mode != null) next = next.withMode(mode);
  final failover = values[BackupItem.nodeFailover];
  if (failover is bool) next = next.withNodeFailover(failover);
  return next;
}

/// The auto-lock value of the map as minutes, null for never.
int? autoLockFromBackup(Object? v) => v is int ? v : null;

/// The map's auto-lock value for [minutes] (null: never).
Object autoLockToBackup(int? minutes) => minutes ?? BackupKey.never;
