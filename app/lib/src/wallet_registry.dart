/// The desktop's list of wallets: several named wallets, each with its own data directory and
/// store keys (D9; phones keep one). Pure Dart over `dart:io`, no Flutter.
///
/// The list is `wallets.json` in the app support directory ([WalletRegistry.root]). It holds
/// labels, chains and folders only: never a phrase, password or key. Wallet folders are
/// `<root>/wallets/<id>/<chain>`; the single wallet a 0.1.0 install made sits at
/// `<root>/wallets/<chain>` and is listed as `legacy-<chain>` ([WalletRegistry.adoptLegacy]).
///
/// Wallet 1 has two spellings and they mean the same: the registry hands out the id
/// `legacy-<chain>`, but its [WalletConfig.walletId] is null ([WalletEntry.walletId]), and
/// `LepicWalletService` treats `legacy-…` exactly like null. Configs for wallet 1 must use null.
///
/// Registry wallets must not use `WalletVault` until it keys by wallet id (it keys by chain).
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

/// `wallets.json` was written by a newer version of the app; this one will not overwrite it.
class WalletRegistryVersionException extends WalletRegistryException {
  const WalletRegistryVersionException(super.message);
}

/// No wallet with that id is listed.
class WalletNotListedException extends WalletRegistryException {
  const WalletNotListedException(super.message);
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
    this.phraseFingerprint,
  });

  /// Random 16-byte hex, or `legacy-<chain>` for the wallet a 0.1.0 install made.
  final String id;
  final String label;
  final Chain chain;

  /// Absolute folder of the wallet ([WalletConfig.dataDir]).
  final String dataDir;
  final DateTime createdAt;
  final DateTime? lastOpenedAt;

  /// A one-way fingerprint of the recovery phrase (64 lowercase hex), written when the app
  /// creates or restores the wallet; null for wallets made before the app kept one. Restore
  /// compares it to find a wallet that is already listed. The phrase cannot be recovered from
  /// it (see `phraseFingerprint` in the desktop data layer).
  final String? phraseFingerprint;

  bool get isLegacy => id.startsWith(WalletRegistry.legacyPrefix);

  /// The [WalletConfig.walletId] for this wallet: null for wallet 1 (`legacy-<chain>`).
  String? get walletId => isLegacy ? null : id;

  WalletEntry copyWith({String? label, DateTime? lastOpenedAt, String? phraseFingerprint}) => WalletEntry(
    id: id,
    label: label ?? this.label,
    chain: chain,
    dataDir: dataDir,
    createdAt: createdAt,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    phraseFingerprint: phraseFingerprint ?? this.phraseFingerprint,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'chain': chain.name,
    'dataDir': dataDir,
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (lastOpenedAt != null)
      'lastOpenedAt': lastOpenedAt!.toUtc().toIso8601String(),
    if (phraseFingerprint != null) 'phraseFingerprint': phraseFingerprint,
  };

  static final RegExp _idPattern = RegExp(r'^[0-9a-f]{32}$');
  static final RegExp _fingerprintPattern = RegExp(r'^[0-9a-f]{64}$');

  /// Null when [json] is not a well-formed entry: the id is 32 lowercase hex characters, or
  /// `legacy-<chain>` of the entry's own chain.
  static WalletEntry? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final label = json['label'];
    final dataDir = json['dataDir'];
    final created = json['createdAt'];
    final opened = json['lastOpenedAt'];
    final fingerprint = json['phraseFingerprint'];
    final chain = Chain.values.asNameMap()[json['chain']];
    if (id is! String || label is! String || chain == null) return null;
    if (!_idPattern.hasMatch(id) &&
        id != '${WalletRegistry.legacyPrefix}${chain.name}') {
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
      // A malformed fingerprint is left out, never matched.
      phraseFingerprint: fingerprint is String && _fingerprintPattern.hasMatch(fingerprint) ? fingerprint : null,
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

  /// The `version` this code writes.
  static const int fileVersion = 1;

  final String root;
  final DateTime Function() _now;
  final Random _random;

  final List<WalletEntry> _entries = [];

  /// Entries in the file that this code could not read; written back unchanged.
  List<Object?> _foreign = [];
  int? _newerVersion;
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

  /// Throws before a mutation touches anything when the file is from a newer version.
  void _requireWritable() {
    final newer = _newerVersion;
    if (newer != null) {
      throw WalletRegistryVersionException(
        'wallets.json is from a newer version of the app (version $newer); '
        'update the app to change the wallet list',
      );
    }
  }

  /// Runs [action] after every earlier call, so writes never interleave.
  Future<T> _locked<T>(Future<T> Function() action) {
    final done = _queue.then((_) => action());
    _queue = done.then<void>((_) {}, onError: (Object _) {});
    return done;
  }

  /// Reads `wallets.json`. A missing file is an empty list. A file that does not parse (or is
  /// not UTF-8) is renamed to `wallets.json.damaged-<millis>` (never removed) and the list
  /// rebuilt from the folders on disk ([rescan]) and the 0.1.0 wallets ([adoptLegacy]), so no
  /// wallet is lost from view (except a legacy wallet in [skipLegacy], which the user took off
  /// the list). One bad entry does not damage the file: it is skipped, kept as
  /// it was, and written back unchanged. A file with a newer `version` is read as far as
  /// possible but never written: saving throws [WalletRegistryVersionException].
  Future<void> load({Set<Chain> skipLegacy = const {}}) => _locked(() async {
    _entries.clear();
    _foreign = [];
    _newerVersion = null;
    _lastUsedId = null;
    final file = _file;
    if (!file.existsSync()) return;
    final String text;
    try {
      text = utf8.decode(await file.readAsBytes());
    } on FormatException {
      return _rebuild(file, skipLegacy);
    } on FileSystemException catch (e) {
      throw WalletRegistryException(
        'wallets.json could not be read (${e.osError?.message ?? e.message})',
      );
    }
    try {
      final json = jsonDecode(text);
      if (json is! Map || json['wallets'] is! List) {
        throw const FormatException('not a wallet list');
      }
      final version = json['version'];
      if (version is int && version > fileVersion) _newerVersion = version;
      for (final raw in json['wallets'] as List) {
        final entry = WalletEntry.tryParse(raw);
        if (entry == null || _entries.any((e) => e.id == entry.id)) {
          _foreign.add(raw);
        } else {
          _entries.add(entry);
        }
      }
      final last = json['lastUsedId'];
      _lastUsedId = last is String ? last : null;
    } on FormatException {
      await _rebuild(file, skipLegacy);
    }
  });

  Future<void> _rebuild(File file, Set<Chain> skipLegacy) async {
    _entries.clear();
    _foreign = [];
    _lastUsedId = null;
    final aside = '${file.path}.damaged-${_now().millisecondsSinceEpoch}';
    await file.rename(aside);
    logWarn('wallets', 'wallets.json did not parse; kept as $aside');
    final entries = [...await _scan()];
    for (final chain in Chain.values) {
      if (skipLegacy.contains(chain)) continue;
      final found = await _hasLepicFolder(_legacyDir(chain));
      final legacy = _legacyEntry(chain, found);
      if (legacy != null) entries.add(legacy);
    }
    await _save(entries, null);
    _entries.addAll(entries);
  }

  /// A new wallet folder `<root>/wallets/<id>/<chain>`, created empty, and its entry.
  /// Without [label] the entry is called "Wallet N", N the lowest free number.
  Future<WalletEntry> add({required Chain chain, String? label}) =>
      _locked(() async {
        _requireWritable();
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
        await _save([..._entries, entry], _lastUsedId);
        _entries.add(entry);
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
    _requireWritable();
    final found = await (exists ?? _hasLepicFolder)(_legacyDir(chain));
    final entry = _legacyEntry(chain, found);
    if (entry == null) return null;
    await _save([..._entries, entry], _lastUsedId);
    _entries.add(entry);
    return entry;
  });

  String _legacyDir(Chain chain) => '$_wallets$_sep${chain.name}';

  /// The `legacy-<chain>` entry when [found] and not listed yet.
  WalletEntry? _legacyEntry(Chain chain, bool found) {
    final id = '$legacyPrefix${chain.name}';
    if (!found || byId(id) != null) return null;
    final dir = _legacyDir(chain);
    return WalletEntry(
      id: id,
      label: _nextLabel(),
      chain: chain,
      dataDir: dir,
      createdAt: _statTime(dir),
    );
  }

  static Future<bool> _hasLepicFolder(String dir) async =>
      Directory('$dir${_sep}lepic').existsSync();

  /// Renames to [label], trimmed, 1 to 32 characters. Duplicates are allowed.
  Future<WalletEntry> rename(String id, String label) => _locked(() async {
    _requireWritable();
    final name = _checkLabel(label);
    final i = _indexOf(id);
    final entry = _entries[i].copyWith(label: name);
    await _save([..._entries]..[i] = entry, _lastUsedId);
    _entries[i] = entry;
    return entry;
  });

  /// Records that [id] was opened now, and that it is the one to open next time.
  Future<WalletEntry> markOpened(String id) => _locked(() async {
    _requireWritable();
    final i = _indexOf(id);
    final entry = _entries[i].copyWith(lastOpenedAt: _now());
    await _save([..._entries]..[i] = entry, id);
    _entries[i] = entry;
    _lastUsedId = id;
    return entry;
  });

  /// Keeps the recovery phrase fingerprint of [id] ([WalletEntry.phraseFingerprint]).
  Future<WalletEntry> setPhraseFingerprint(String id, String fingerprint) => _locked(() async {
    _requireWritable();
    if (!WalletEntry._fingerprintPattern.hasMatch(fingerprint)) {
      throw const WalletRegistryException('fingerprint is not 64 lowercase hex characters');
    }
    final i = _indexOf(id);
    final entry = _entries[i].copyWith(phraseFingerprint: fingerprint);
    await _save([..._entries]..[i] = entry, _lastUsedId);
    _entries[i] = entry;
    return entry;
  });

  /// The listed wallet whose [WalletEntry.phraseFingerprint] is [fingerprint], if any.
  WalletEntry? byPhraseFingerprint(String fingerprint) =>
      _entries.where((e) => e.phraseFingerprint == fingerprint).firstOrNull;

  /// Makes [id] the wallet to open next time, without touching its last-opened time.
  Future<void> setLastUsed(String id) => _locked(() async {
    _requireWritable();
    _indexOf(id);
    await _save([..._entries], id);
    _lastUsedId = id;
  });

  /// "Remove from list": drops the entry only. Files and store keys stay, and [rescan] finds
  /// an id wallet again.
  Future<void> forget(String id) => _locked(() async {
    _requireWritable();
    final i = _indexOf(id);
    final last = _lastUsedId == id ? null : _lastUsedId;
    await _save([..._entries]..removeAt(i), last);
    _entries.removeAt(i);
    _lastUsedId = last;
  });

  /// True when the wallet's folder is gone (moved, or a drive unplugged), A12.
  bool folderMissing(WalletEntry entry) =>
      !Directory(entry.dataDir).existsSync();

  /// Wallet folders `<root>/wallets/<id>/<chain>` that hold a wallet and are not listed.
  /// Adds nothing; pass a candidate to [restore].
  Future<List<WalletEntry>> rescan() => _locked(_scan);

  /// Puts a [rescan] candidate in the list.
  Future<WalletEntry> restore(WalletEntry candidate) => _locked(() async {
    _requireWritable();
    final existing = byId(candidate.id);
    if (existing != null) return existing;
    await _save([..._entries, candidate], _lastUsedId);
    _entries.add(candidate);
    return candidate;
  });

  /// "Delete wallet": has [service] remove the wallet's vault keys and database, then removes
  /// its `lepic` folder and the empty folders around it, then drops the entry.
  ///
  /// The folder must be exactly `<root>/wallets/<id>/<chain>` (or `<root>/wallets/<chain>` for
  /// a legacy wallet), spelled exactly so in both the entry and [config], with no link on the
  /// way down; otherwise [UnsafeWalletPathException] is thrown before anything is touched.
  /// Only that built path is ever removed from. `wallet_data/` (epic-wallet seed files) is
  /// never removed: if one is there the folder stays. The [config] of wallet 1 has a null
  /// walletId.
  Future<void> delete(
    String id, {
    required WalletService service,
    required WalletConfig config,
  }) => _locked(() async {
    _requireWritable();
    final i = _indexOf(id);
    final entry = _entries[i];
    final expected = entry.isLegacy
        ? _legacyDir(entry.chain)
        : '$_wallets$_sep${entry.id}$_sep${entry.chain.name}';
    if (config.walletId != entry.walletId || config.chain != entry.chain) {
      throw const UnsafeWalletPathException(
        'the wallet config does not match the listed wallet',
      );
    }
    if (entry.dataDir != expected || config.dataDir != expected) {
      throw UnsafeWalletPathException(
        '${entry.label} is not in the folder the registry made for it',
      );
    }
    final folders = _safeFolders(entry, expected);
    await service.deleteWallet(
      config: WalletConfig(
        dataDir: expected,
        chain: config.chain,
        nodeUrl: config.nodeUrl,
        nodeApiSecret: config.nodeApiSecret,
        epicboxDomain: config.epicboxDomain,
        epicboxPort: config.epicboxPort,
        walletId: config.walletId,
      ),
    );
    final lepicDir = Directory('$expected${_sep}lepic');
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
    final last = _lastUsedId == id ? null : _lastUsedId;
    await _save([..._entries]..removeAt(i), last);
    _entries.removeAt(i);
    _lastUsedId = last;
  });

  /// The folders to remove once empty, innermost first; none of them may be a link.
  List<String> _safeFolders(WalletEntry entry, String expected) {
    var path = _wallets;
    if (_isLink(path)) {
      throw const UnsafeWalletPathException('the wallets folder is a link');
    }
    final parts = expected.substring('$_wallets$_sep'.length).split(_sep);
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
    if (i < 0) throw WalletNotListedException('no wallet with id $id');
    return i;
  }

  /// Control characters, line and paragraph separators, bidi marks, embeddings, overrides and
  /// isolates.
  static final RegExp _forbiddenInLabel = RegExp(
    r'[\p{Cc}\u2028\u2029\u200E\u200F\u202A-\u202E\u2066-\u2069]',
    unicode: true,
  );

  String _checkLabel(String label) {
    final name = label.trim();
    if (_forbiddenInLabel.hasMatch(name)) {
      throw const WalletRegistryException(
        'a wallet name cannot hold control or direction characters',
      );
    }
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

  /// Writes [entries] to a temp file beside `wallets.json`, fsyncs it, and renames it over the
  /// list. Memory is only changed by the caller, after this returns. Entries this code could
  /// not read are written back unchanged.
  Future<void> _save(List<WalletEntry> entries, String? lastUsedId) async {
    _requireWritable();
    Directory(root).createSync(recursive: true);
    final tmp = File('${_file.path}.tmp');
    final json = const JsonEncoder.withIndent('  ').convert({
      'version': fileVersion,
      'lastUsedId': entries.any((e) => e.id == lastUsedId) ? lastUsedId : null,
      'wallets': [for (final e in entries) e.toJson(), ..._foreign],
    });
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(_file.path);
  }
}
