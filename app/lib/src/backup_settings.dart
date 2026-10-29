// SPDX-License-Identifier: Apache-2.0
/// The settings a history backup (`.wfeh` v2) carries, and how an import takes them back.
///
/// One portable map for the phone and the desktop, written by each app's glue
/// (`ui/backup_settings_phone.dart`, `desktop/data/backup_settings_desk.dart`) and sealed into
/// the file as an opaque JSON object (`HistoryPayload.settings`):
///
/// ```json
/// {"v": 2, "from": "mobile",
///  "theme": "dark", "language": "pl", "helpLanguage": null, "hideBalances": false,
///  "autoLock": 15, "advanced": {...}, "payments": {...},
///  "sendStrategy": "smallest", "splitChange": true, "fiat": "usd", "showFiat": true,
///  "tor": false, "seenAs": "Alice",
///  "servers": {"node": ["https://...", ...], "epicbox": ["host", "host:port", ...]},
///  "online": {"status_site": true, "update_check": true, "price": true},
///  "desktop": {"invoiceExpiry": 86400, "seedsDeleted": ["btlabs"], "epicboxAutostart": true}}
/// ```
///
/// `servers` and `online` are `settings.toml`'s Node and Epicbox lists, in its order (the first
/// is in use), and its `[online]` switches. `app-config.toml` is never in it.
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
import 'server_list_file.dart' show withFirst;
import 'settings.dart' show autoLockChoice;
import 'settings_file/host_settings.dart' show HostSettings;

/// The map's version. A file with a newer one is skipped whole: its keys may mean other things.
/// 2: the servers and switches of `settings.toml` (1 had per-chain servers and keyed lists, now
/// skipped as unknown keys).
const int backupSettingsVersion = 2;

/// Which app wrote the map (`from`).
enum BackupPlatform { mobile, desktop }

/// The map's keys. [servers] holds the two lists, [online] the three switches by their
/// `settings.toml` names; [desktop] holds the desktop-only items.
abstract final class BackupKey {
  static const v = 'v';
  static const from = 'from';
  static const theme = 'theme';
  static const language = 'language';
  static const helpLanguage = 'helpLanguage';
  static const hideBalances = 'hideBalances';
  static const autoLock = 'autoLock';
  static const advanced = 'advanced';
  static const payments = 'payments';
  static const sendStrategy = 'sendStrategy';
  static const splitChange = 'splitChange';
  static const fiat = 'fiat';
  static const showFiat = 'showFiat';
  static const tor = 'tor';
  static const seenAs = 'seenAs';
  static const servers = 'servers';
  static const online = 'online';
  static const desktop = 'desktop';

  // In [servers].
  static const node = 'node';
  static const epicbox = 'epicbox';

  // In [online].
  static const statusSite = 'status_site';
  static const updateCheck = 'update_check';
  static const price = 'price';

  // In [desktop].
  static const invoiceExpiry = 'invoiceExpiry';
  static const seedsDeleted = 'seedsDeleted';
  static const epicboxAutostart = 'epicboxAutostart';

  /// [autoLock]'s value for never.
  static const never = 'never';
}

/// What a plan names each setting by ([BackupSettingItem.key], [BackupSettingsPlan.values]).
/// The Advanced page is three: its features, its network mode and node failover, so a stricter
/// mode is never held back by a feature switch, nor one taken with it. The lists and switches
/// are named by their `settings.toml` keys, and their values are that file's.
abstract final class BackupItem {
  static const theme = BackupKey.theme;
  static const language = BackupKey.language;
  static const helpLanguage = BackupKey.helpLanguage;
  static const hideBalances = BackupKey.hideBalances;
  static const autoLock = BackupKey.autoLock;
  static const features = 'advanced.features';
  static const networkMode = 'advanced.networkMode';
  static const nodeFailover = 'advanced.nodeFailover';
  static const payments = BackupKey.payments;
  static const sendStrategy = BackupKey.sendStrategy;
  static const splitChange = BackupKey.splitChange;
  static const fiat = BackupKey.fiat;
  static const showFiat = BackupKey.showFiat;
  static const tor = BackupKey.tor;
  static const seenAs = BackupKey.seenAs;
  static const nodeServers = 'node.servers';
  static const epicboxServers = 'epicbox.servers';
  static const statusSite = 'online.status_site';
  static const updateCheck = 'online.update_check';
  static const price = 'online.price';
  static const invoiceExpiry = 'desktop.invoiceExpiry';
  static const seedsDeleted = 'desktop.seedsDeleted';
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

/// A server list from the map, in its order: entries that are no server address of [kind] are
/// dropped, and a repeat of one before; Epicbox entries as their labels (`host`, `host:port`).
/// Null when [j] is no list.
List<String>? serverValuesFromJson(ServerKind kind, Object? j) {
  if (j is! List) return null;
  final out = <String>[];
  final keys = <String>{};
  for (final e in j) {
    final v = e is String && e.length <= 300 ? typedServerValue(kind, e) : null;
    if (v != null && keys.add(serverKeyOf(kind, v))) out.add(v);
  }
  return out;
}

/// One setting in a [BackupSettingsPlan]: [mine] is the value here, [backup] the one the import
/// would set (the file's, mapped to this app).
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
  const BackupSettingsPlan({
    this.take = const [],
    this.conflicts = const [],
    this.servers = const [],
    this.refused = const [],
    this.skipped = const [],
  });

  /// No settings in the file, or none this app reads.
  static const BackupSettingsPlan empty = BackupSettingsPlan();

  /// Set without asking: the value here is a fresh install's, or the file's servers and
  /// switches where no other wallet shares them.
  final List<BackupSettingItem> take;

  /// Changed here by the user and different in the file: set only when the user takes the
  /// backup's ("Use the settings from this backup?").
  final List<BackupSettingItem> conflicts;

  /// The Node and Epicbox lists ([BackupItem.nodeServers], [BackupItem.epicboxServers]) the file
  /// has otherwise, on a desktop whose other wallets share them (the first Epicbox entry is
  /// every wallet's address): set only when the user takes the backup's servers.
  final List<BackupSettingItem> servers;

  /// Kept out for safety, whatever the user answers: a node in the file on this computer, the
  /// local network or a tailnet is never made the node in use (it stays in the list, after the
  /// first public one; a list of such nodes only is not taken).
  final List<BackupSettingItem> refused;

  /// Keys the file had that this app does not read, or whose value was not valid (or the whole
  /// map, `v`, when it is newer or not one).
  final List<String> skipped;

  bool get hasConflicts => conflicts.isNotEmpty;

  /// The servers question: keep this computer's, or use the backup's.
  bool get asksServers => servers.isNotEmpty;

  /// Nothing would change.
  bool get isEmpty => take.isEmpty && conflicts.isEmpty && servers.isEmpty;

  /// The settings to apply, by [BackupItem] name: every [take], the [conflicts] when
  /// [takeConflicts] and the [servers] when [takeServers].
  Map<String, Object?> values({required bool takeConflicts, bool takeServers = false}) => {
    for (final i in take) i.key: i.backup,
    if (takeConflicts)
      for (final i in conflicts) i.key: i.backup,
    if (takeServers)
      for (final i in servers) i.key: i.backup,
  };

  @override
  String toString() =>
      'BackupSettingsPlan(take: $take, conflicts: $conflicts, servers: $servers, refused: $refused, skipped: $skipped)';
}

/// Marks a key this map does not have (null is a value: "follow the system").
const Object _absent = Object();

/// Plans the import of [file], a backup's settings map, into this app ([here]). [mine] is what
/// this app has now and [defaults] what a fresh install has, both in the map's own form (the
/// glue writes them with the same encoder as the export); a key [mine] lacks is not read here.
/// For each setting the file has, mapped to this app:
/// - the same as here: nothing;
/// - here a fresh install's value: taken ([BackupSettingsPlan.take]);
/// - here changed by the user and different: a conflict ([BackupSettingsPlan.conflicts]).
/// The network mode follows the same rule, so a less strict mode never replaces a stricter one
/// the user chose without asking. Deleted seed contacts merge.
///
/// The Node and Epicbox lists compare in order (the first is the one in use). Where no other
/// wallet uses them (a phone; a desktop with no other wallet on this network) the file's lists
/// and `[online]` switches are taken as they are. With [sharedServers] (other wallets here) a
/// list that differs goes to [BackupSettingsPlan.servers], one question for both, and the
/// switches follow the rule above. A node on this computer, the local network or a tailnet is
/// never planned as the node in use. Unknown keys and bad values are skipped; a newer
/// [backupSettingsVersion] skips the whole map. Never throws.
///
/// The desktop passes [fileWalletName] (the file's) and [myWalletName]: a name the app gave
/// ([isDefaultWalletName]) is replaced, a name the user gave is a conflict.
BackupSettingsPlan planBackupSettings({
  required BackupPlatform here,
  required Map<String, Object?> mine,
  required Map<String, Object?> defaults,
  required Object? file,
  bool sharedServers = false,
  String? fileWalletName,
  String? myWalletName,
}) {
  try {
    return _plan(here, mine, defaults, file, sharedServers, fileWalletName, myWalletName);
  } on Object {
    // A value of a shape no check foresaw: nothing from this file.
    return const BackupSettingsPlan(skipped: [BackupKey.v]);
  }
}

BackupSettingsPlan _plan(
  BackupPlatform here,
  Map<String, Object?> mine,
  Map<String, Object?> defaults,
  Object? file,
  bool sharedServers,
  String? fileWalletName,
  String? myWalletName,
) {
  final take = <BackupSettingItem>[];
  final conflicts = <BackupSettingItem>[];
  final servers = <BackupSettingItem>[];
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
    BackupKey.hideBalances, BackupKey.autoLock, BackupKey.advanced, BackupKey.payments,
    BackupKey.sendStrategy, BackupKey.splitChange, BackupKey.fiat, BackupKey.showFiat,
    BackupKey.tor, BackupKey.seenAs, BackupKey.servers, BackupKey.online, BackupKey.desktop,
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

  // settings.toml's lists, in order: the first is the one in use.
  final fileServers = f[BackupKey.servers];
  if (f.containsKey(BackupKey.servers)) {
    final mineServers = mine[BackupKey.servers];
    if (fileServers is! Map || mineServers is! Map) {
      skipped.add(BackupKey.servers);
    } else {
      for (final (key, item, kind) in [
        (BackupKey.node, BackupItem.nodeServers, ServerKind.node),
        (BackupKey.epicbox, BackupItem.epicboxServers, ServerKind.relay),
      ]) {
        if (!fileServers.containsKey(key)) continue;
        var target = serverValuesFromJson(kind, fileServers[key]);
        final m = serverValuesFromJson(kind, mineServers[key]) ?? const <String>[];
        // An empty list would leave this app with no server at all.
        if (target == null || target.isEmpty) {
          skipped.add('${BackupKey.servers}.$key');
          continue;
        }
        if (kind == ServerKind.node && isLocalNodeUrl(target.first)) {
          final public = target.where((u) => !isLocalNodeUrl(u)).firstOrNull;
          refused.add(BackupSettingItem(item, mine: m.firstOrNull, backup: target.first));
          if (public == null) continue;
          target = withFirst(kind, target, public);
        }
        if (_same(target, m)) continue;
        (sharedServers ? servers : take).add(BackupSettingItem(item, mine: m, backup: target));
      }
      for (final k in fileServers.keys) {
        if (k != BackupKey.node && k != BackupKey.epicbox) skipped.add('${BackupKey.servers}.$k');
      }
    }
  }

  // settings.toml's switches: as they are where no other wallet shares them, else the rule.
  final fileOnline = f[BackupKey.online];
  if (f.containsKey(BackupKey.online)) {
    final mineOnline = mine[BackupKey.online];
    final defaultOnline = defaults[BackupKey.online] is Map ? defaults[BackupKey.online] as Map : const {};
    if (fileOnline is! Map || mineOnline is! Map) {
      skipped.add(BackupKey.online);
    } else {
      for (final (key, item) in [
        (BackupKey.statusSite, BackupItem.statusSite),
        (BackupKey.updateCheck, BackupItem.updateCheck),
        (BackupKey.price, BackupItem.price),
      ]) {
        if (!fileOnline.containsKey(key) || !mineOnline.containsKey(key)) continue;
        final value = fileOnline[key];
        if (value is! bool) {
          skipped.add('${BackupKey.online}.$key');
          continue;
        }
        final m = mineOnline[key];
        if (sharedServers) {
          decide(item, m, defaultOnline[key], value);
        } else {
          merged(item, m, value);
        }
      }
      for (final k in fileOnline.keys) {
        if (!const {BackupKey.statusSite, BackupKey.updateCheck, BackupKey.price}.contains(k)) skipped.add('${BackupKey.online}.$k');
      }
    }
  }

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
      if (deskRaw.containsKey(BackupKey.seedsDeleted) && deskMine.containsKey(BackupKey.seedsDeleted)) {
        final m = _ids(deskMine[BackupKey.seedsDeleted]);
        merged(BackupItem.seedsDeleted, m, ({...m, ..._ids(deskRaw[BackupKey.seedsDeleted])}.toList()..sort()));
      }
      for (final k in deskRaw.keys) {
        if (!const {BackupKey.invoiceExpiry, BackupKey.seedsDeleted, BackupKey.epicboxAutostart}.contains(k)) {
          skipped.add('${BackupKey.desktop}.$k');
        }
      }
    }
  }

  return BackupSettingsPlan(take: take, conflicts: conflicts, servers: servers, refused: refused, skipped: skipped);
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

/// `settings.toml`'s lists and switches in [s] as the map holds them: [BackupKey.servers] and
/// [BackupKey.online], to spread into either app's map.
Map<String, Object?> backupHostSettings(HostSettings s) => {
  BackupKey.servers: {
    BackupKey.node: [...s.nodeUrls],
    BackupKey.epicbox: [for (final b in s.epicboxServers) b.label],
  },
  BackupKey.online: {
    BackupKey.statusSite: s.statusEnabled,
    BackupKey.updateCheck: s.updatesCheck,
    BackupKey.price: s.priceEnabled,
  },
};

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
