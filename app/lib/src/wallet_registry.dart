/// The desktop's list of wallets: several named wallets, each with its own data directory and
/// store keys (D9; phones keep one). Pure Dart over `dart:io`, no Flutter.
///
/// The list is `wallets.json` in the app support directory ([WalletRegistry.root]). It holds
/// labels, chains and folders only: never a phrase, password or key. Wallet folders are
/// `<root>/wallets/<id>/<chain>`; the single wallet a 0.1.0 install made sits at
/// `<root>/wallets/<chain>` and is listed as `legacy-<chain>` ([WalletRegistry.adoptLegacy]).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'log.dart';
import 'wallet_service.dart';

/// What the registry refuses to do, with a message safe to show.
class WalletRegistryException implements Exception {
  const WalletRegistryException(this.message);

  final String message;

  @override
  String toString() => 'WalletRegistryException: $message';
}

/// A wallet's folder is not somewhere the registry may delete from. Nothing was deleted.
class UnsafeWalletPathException extends WalletRegistryException {
  const UnsafeWalletPathException(super.message);
}

/// One wallet in the list.
class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.label,
    required this.chain,
    required this.dataDir,
    required this.createdAt,
    this.lastOpenedAt,
  });

  /// Random 16-byte hex, or `legacy-<chain>` for the wallet a 0.1.0 install made.
  final String id;
  final String label;
  final Chain chain;

  /// Absolute folder of the wallet ([WalletConfig.dataDir]).
  final String dataDir;
  final DateTime createdAt;
  final DateTime? lastOpenedAt;

  bool get isLegacy => id.startsWith(WalletRegistry.legacyPrefix);

  WalletEntry copyWith({String? label, DateTime? lastOpenedAt}) => WalletEntry(
    id: id,
    label: label ?? this.label,
    chain: chain,
    dataDir: dataDir,
    createdAt: createdAt,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'chain': chain.name,
    'dataDir': dataDir,
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (lastOpenedAt != null)
      'lastOpenedAt': lastOpenedAt!.toUtc().toIso8601String(),
  };

  /// Null when [json] is not a well-formed entry.
  static WalletEntry? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final label = json['label'];
    final dataDir = json['dataDir'];
    final created = json['createdAt'];
    final opened = json['lastOpenedAt'];
    final chain = Chain.values.asNameMap()[json['chain']];
    if (id is! String || id.isEmpty || label is! String || chain == null) {
      return null;
    }
    if (dataDir is! String || dataDir.isEmpty || created is! String) {
      return null;
    }
    final createdAt = DateTime.tryParse(created);
    if (createdAt == null) return null;
    return WalletEntry(
      id: id,
      label: label,
      chain: chain,
      dataDir: dataDir,
      createdAt: createdAt,
      lastOpenedAt: opened is String ? DateTime.tryParse(opened) : null,
    );
  }
}

class WalletRegistry {
  /// [root] is the app support directory; tests pass a temp directory.
  WalletRegistry(String root, {DateTime Function()? now, Random? random})
    : root = _normalize(root),
      _now = now ?? DateTime.now,
      _random = random ?? Random.secure();

  /// Id prefix of a wallet made before the registry, at its old path with its old store keys.
  static const String legacyPrefix = 'legacy-';
  static const String fileName = 'wallets.json';
  static const int maxLabelLength = 32;

  final String root;
  final DateTime Function() _now;
  final Random _random;

  final List<WalletEntry> _entries = [];
  String? _lastUsedId;
  Future<void> _queue = Future.value();

  static final String _sep = Platform.pathSeparator;

  String get _wallets => '$root${_sep}wallets';
  File get _file => File('$root$_sep$fileName');

  /// Entries in the order they were added.
  List<WalletEntry> list() => List.unmodifiable(_entries);

  WalletEntry? byId(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// The wallet opened last, if it is still listed.
  String? get lastUsedId =>
      _lastUsedId != null && byId(_lastUsedId!) != null ? _lastUsedId : null;

  /// Runs [action] after every earlier call, so writes never interleave.
  Future<T> _locked<T>(Future<T> Function() action) {
    final done = _queue.then((_) => action());
    _queue = done.then<void>((_) {}, onError: (Object _) {});
    return done;
  }

  /// Reads `wallets.json`. A missing file is an empty list. A file that does not parse is
  /// renamed to `wallets.json.damaged-<millis>` (never deleted) and the list rebuilt from the
  /// folders on disk ([rescan]), so no wallet is lost from view.
  Future<void> load() => _locked(() async {
    _entries.clear();
    _lastUsedId = null;
    final file = _file;
    if (!file.existsSync()) return;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map || json['wallets'] is! List) {
        throw const FormatException('not a wallet list');
      }
      for (final raw in json['wallets'] as List) {
        final entry = WalletEntry.tryParse(raw);
        if (entry == null) throw const FormatException('bad wallet entry');
        if (_entries.every((e) => e.id != entry.id)) _entries.add(entry);
      }
      final last = json['lastUsedId'];
      _lastUsedId = last is String ? last : null;
    } on FormatException {
      _entries.clear();
      _lastUsedId = null;
      final aside = '${file.path}.damaged-${_now().millisecondsSinceEpoch}';
      await file.rename(aside);
      logWarn('wallets', 'wallets.json did not parse; kept as $aside');
      _entries.addAll(await _scan());
      await _save();
    }
  });

  /// A new wallet folder `<root>/wallets/<id>/<chain>`, created empty, and its entry.
  /// Without [label] the entry is called "Wallet N", N the lowest free number.
  Future<WalletEntry> add({required Chain chain, String? label}) =>
      _locked(() async {
        final name = label == null ? _nextLabel() : _checkLabel(label);
        final id = _newId();
        final dir = Directory('$_wallets$_sep$id$_sep${chain.name}')
          ..createSync(recursive: true);
        final entry = WalletEntry(
          id: id,
          label: name,
          chain: chain,
          dataDir: dir.path,
          createdAt: _now(),
        );
        _entries.add(entry);
        await _save();
        return entry;
      });

  /// Lists the wallet a 0.1.0 install made at `<root>/wallets/<chain>` as `legacy-<chain>`,
  /// at that same path (so its pinned store prefix still applies). Returns the entry, or null
  /// when it is already listed or no wallet is there. [exists] decides whether one is; the
  /// default looks for LEPIC's `lepic` folder.
  Future<WalletEntry?> adoptLegacy(
    Chain chain, {
    Future<bool> Function(String dataDir)? exists,
  }) => _locked(() async {
    final id = '$legacyPrefix${chain.name}';
    if (byId(id) != null) return null;
    final dir = '$_wallets$_sep${chain.name}';
    final found = await (exists ?? _hasLepicFolder)(dir);
    if (!found) return null;
    final entry = WalletEntry(
      id: id,
      label: _nextLabel(),
      chain: chain,
      dataDir: dir,
      createdAt: _statTime(dir),
    );
    _entries.add(entry);
    await _save();
    return entry;
  });

  static Future<bool> _hasLepicFolder(String dir) async =>
      Directory('$dir${_sep}lepic').existsSync();

  /// Renames to [label], trimmed, 1 to 32 characters. Duplicates are allowed.
  Future<WalletEntry> rename(String id, String label) => _locked(() async {
    final name = _checkLabel(label);
    final i = _indexOf(id);
    final entry = _entries[i].copyWith(label: name);
    _entries[i] = entry;
    await _save();
    return entry;
  });

  /// Records that [id] was opened now, and that it is the one to open next time.
  Future<WalletEntry> markOpened(String id) => _locked(() async {
    final i = _indexOf(id);
    final entry = _entries[i].copyWith(lastOpenedAt: _now());
    _entries[i] = entry;
    _lastUsedId = id;
    await _save();
    return entry;
  });

  /// "Remove from list": drops the entry only. Files and store keys stay, and [rescan] finds
  /// an id wallet again.
  Future<void> forget(String id) => _locked(() async {
    _entries.removeAt(_indexOf(id));
    if (_lastUsedId == id) _lastUsedId = null;
    await _save();
  });

  /// True when the wallet's folder is gone (moved, or a drive unplugged), A12.
  bool folderMissing(WalletEntry entry) =>
      !Directory(entry.dataDir).existsSync();

  /// Wallet folders `<root>/wallets/<id>/<chain>` that hold a wallet and are not listed.
  /// Adds nothing; pass a candidate to [restore].
  Future<List<WalletEntry>> rescan() => _locked(_scan);

  /// Puts a [rescan] candidate in the list.
  Future<WalletEntry> restore(WalletEntry candidate) => _locked(() async {
    final existing = byId(candidate.id);
    if (existing != null) return existing;
    _entries.add(candidate);
    await _save();
    return candidate;
  });

  /// "Delete wallet": has [service] remove the wallet's vault keys and database, then removes
  /// its `lepic` folder and the empty folders around it, then drops the entry.
  ///
  /// The folder must be exactly `<root>/wallets/<id>/<chain>` (or `<root>/wallets/<chain>` for
  /// a legacy wallet), with no link on the way down; otherwise [UnsafeWalletPathException] is
  /// thrown before anything is touched. `wallet_data/` (epic-wallet seed files) is never
  /// deleted: if one is there the folder stays.
  Future<void> delete(
    String id, {
    required WalletService service,
    required WalletConfig config,
  }) => _locked(() async {
    final i = _indexOf(id);
    final entry = _entries[i];
    if (config.walletId != id || config.dataDir != entry.dataDir) {
      throw const UnsafeWalletPathException(
        'the wallet config does not match the listed wallet',
      );
    }
    final folders = _safeFolders(entry);
    await service.deleteWallet(config: config);
    final lepicDir = Directory('${entry.dataDir}${_sep}lepic');
    if (!_isLink(lepicDir.path) && lepicDir.existsSync()) {
      await lepicDir.delete(recursive: true);
    }
    for (final dir in folders) {
      try {
        await Directory(dir).delete(); // only when empty
      } on FileSystemException {
        break; // not empty (wallet_data, other files) or already gone
      }
    }
    _entries.removeAt(i);
    if (_lastUsedId == id) _lastUsedId = null;
    await _save();
  });

  /// The folders to remove once empty, innermost first, after checking [entry]'s path.
  List<String> _safeFolders(WalletEntry entry) {
    final dir = _normalize(entry.dataDir);
    final prefix = '$_wallets$_sep';
    if (!dir.startsWith(prefix)) {
      throw UnsafeWalletPathException(
        '${entry.label} is outside the wallets folder',
      );
    }
    final parts = dir.substring(prefix.length).split(_sep);
    final expected = entry.isLegacy
        ? [entry.chain.name]
        : [entry.id, entry.chain.name];
    if (parts.length != expected.length ||
        [for (var i = 0; i < parts.length; i++) parts[i] == expected[i]]
            .contains(false)) {
      throw UnsafeWalletPathException(
        '${entry.label} is not in the folder the registry made for it',
      );
    }
    var path = _wallets;
    if (_isLink(path)) {
      throw const UnsafeWalletPathException('the wallets folder is a link');
    }
    final chain = <String>[];
    for (final part in parts) {
      path = '$path$_sep$part';
      if (_isLink(path)) {
        throw UnsafeWalletPathException('${entry.label} is behind a link');
      }
      chain.add(path);
    }
    return chain.reversed.toList();
  }

  static bool _isLink(String path) =>
      FileSystemEntity.typeSync(path, followLinks: false) ==
      FileSystemEntityType.link;

  /// Collapses `.` and `..` and repeated separators; no file system access.
  static String _normalize(String path) {
    final absolute = path.startsWith(_sep);
    final out = <String>[];
    for (final part in path.split(_sep == '\\' ? RegExp(r'[\\/]') : _sep)) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (out.isNotEmpty) out.removeLast();
      } else {
        out.add(part);
      }
    }
    return '${absolute ? _sep : ''}${out.join(_sep)}';
  }

  Future<List<WalletEntry>> _scan() async {
    final found = <WalletEntry>[];
    final top = Directory(_wallets);
    if (!top.existsSync()) return found;
    final idPattern = RegExp(r'^[0-9a-f]{32}$');
    for (final idDir in top.listSync(followLinks: false)) {
      if (idDir is! Directory) continue;
      final id = idDir.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (!idPattern.hasMatch(id) || byId(id) != null) continue;
      for (final chain in Chain.values) {
        final dir = '${idDir.path}$_sep${chain.name}';
        if (_isLink(dir) || !await _hasLepicFolder(dir)) continue;
        found.add(
          WalletEntry(
            id: id,
            label: _nextLabel(taken: found.map((e) => e.label)),
            chain: chain,
            dataDir: dir,
            createdAt: _statTime(dir),
          ),
        );
      }
    }
    return found;
  }

  DateTime _statTime(String dir) {
    try {
      return Directory(dir).statSync().modified;
    } on FileSystemException {
      return _now();
    }
  }

  int _indexOf(String id) {
    final i = _entries.indexWhere((e) => e.id == id);
    if (i < 0) throw WalletRegistryException('no wallet with id $id');
    return i;
  }

  String _checkLabel(String label) {
    final name = label.trim();
    final length = name.runes.length;
    if (length < 1 || length > maxLabelLength) {
      throw const WalletRegistryException(
        'a wallet name is 1 to $maxLabelLength characters',
      );
    }
    return name;
  }

  /// "Wallet N" with the lowest N no listed wallet (or [taken] label) uses.
  String _nextLabel({Iterable<String> taken = const []}) {
    final used = {..._entries.map((e) => e.label), ...taken};
    var n = 1;
    while (used.contains('Wallet $n')) {
      n++;
    }
    return 'Wallet $n';
  }

  String _newId() => [
    for (var i = 0; i < 16; i++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();

  /// Writes a temp file beside `wallets.json`, flushes it, and renames it over the list.
  Future<void> _save() async {
    Directory(root).createSync(recursive: true);
    final tmp = File('${_file.path}.tmp');
    final json = const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'lastUsedId': lastUsedId,
      'wallets': [for (final e in _entries) e.toJson()],
    });
    final sink = tmp.openWrite();
    try {
      sink.write(json);
      await sink.flush();
    } finally {
      await sink.close();
    }
    await tmp.rename(_file.path);
  }
}
