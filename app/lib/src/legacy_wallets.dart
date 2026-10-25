/// Finds the Epic Cash wallets older programs left on a desktop, for the Import wizard's Find and
/// Choose steps. Read only: nothing here creates, moves, renames, locks or deletes a file in a
/// scanned folder. Plain Dart (dart:io), no Flutter.
///
/// Where wallets are (ported from the GUI 6.1.6 rules, legacyScan.js and walletFolder.js):
///
/// ```text
///     <home>/.epic-gui              GUI 6.1 (never public): not searched; a folder picked by hand
///                                   is read (settings.json {wallets: [...]}, wallets/<id>)
///     <home>/.epic/epic_3-0-0_config.json account_dirs [{account, userhomedir, network}]
///     <home>/.epic/<main|floo|user>                       the epic program's, and GUIs 4.x-6.x
///     <home>/.epic/<account>/<net>, <home>/.epic/<net>/<account>   older GUI layouts
/// ```
///
/// A wallet is a folder holding wallet_data/wallet.seed.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// LEPIC refuses a wallet.seed larger than this.
const int maxSeedBytes = 4096;

/// The text the wizard shows for a folder that is chain data only.
const String chainOnlyText = 'Blockchain data, not a wallet.';

/// The text for a folder with nothing to import.
const String noWalletText = 'No wallet in this folder. A wallet folder contains wallet_data/wallet.seed.';

/// The text for a wallet folder with links in it (B15).
const String linksText = "This wallet's folder has links in it, so it is not imported. Restore it from the recovery phrase.";

/// The text for a wallet folder that could not be read to the end.
const String incompleteText = "This wallet's folder could not be read completely, so it is not imported. Restore it from the recovery phrase.";

/// The text for a wallet.seed LEPIC would refuse.
const String seedTooLargeText = 'The wallet.seed file is too large to be a wallet seed.';

// A size estimate or a link check must never stall the first start.
const int _chainWalkLimit = 20000;
const int _walletWalkLimit = 200000;
const int _readLimit = 400;

enum LegacyNetwork {
  main('main', 'mainnet', null),
  floo('floo', 'floonet', 'Floonet'),
  user('user', 'usernet', 'Usernet');

  const LegacyNetwork(this.folder, this.guiName, this.tag);

  /// The folder name epic and the older GUIs use.
  final String folder;

  /// The name in the GUIs' settings files.
  final String guiName;

  /// The row's network tag; null for mainnet (no tag).
  final String? tag;

  static LegacyNetwork? fromFolder(String name) {
    for (final n in values) {
      if (n.folder == name) return n;
    }
    return null;
  }

  static LegacyNetwork? fromGui(String? name) {
    for (final n in values) {
      if (n.guiName == name) return n;
    }
    return null;
  }

  /// chain_type as epic-wallet writes it: Mainnet, Floonet, UserTesting (Usernet in some old files).
  static LegacyNetwork? fromChainType(String t) => switch (t.trim().toLowerCase()) {
        'mainnet' => main,
        'floonet' => floo,
        'usertesting' || 'usernet' => user,
        _ => null,
      };
}

/// The groups of the Find step.
enum LegacySource {
  /// "Older Epic Wallet": the GUI (any version, 6.1 included).
  gui('Older Epic Wallet'),

  /// "The epic program": `~/.epic/<net>`, the CLI's own folder.
  cli('The epic program'),

  /// A folder chosen by hand.
  picked('Chosen folders');

  const LegacySource(this.title);
  final String title;
}

/// Why a wallet cannot be copied; null on a copyable wallet.
enum LegacyRefusal {
  /// A symlink, junction or other non-regular file inside the wallet.
  links(linksText),

  /// The wallet's folders are too big to check, or a part could not be read.
  incomplete(incompleteText),

  /// wallet.seed is larger than LEPIC accepts.
  seedTooLarge(seedTooLargeText);

  const LegacyRefusal(this.text);
  final String text;
}

/// A wallet that is running or not, as far as can be told without touching its files.
enum InUse { free, inUse, unknown }

/// Where to look. Tests pass temp dirs; [LegacyRoots.current] reads the real machine.
class LegacyRoots {
  const LegacyRoots({required this.home, this.userProfile, this.appData, this.guiHome});

  /// The user's home dir.
  final String home;

  /// Windows %USERPROFILE%, when it differs from [home].
  final String? userProfile;

  /// Electron's appData dir (~/.config, %APPDATA%, ~/Library/Application Support).
  final String? appData;

  /// EPIC_GUI_HOME, when set (GUI 6.1's own root).
  final String? guiHome;

  factory LegacyRoots.current() {
    final env = Platform.environment;
    final home = env['HOME'] ?? env['USERPROFILE'] ?? '';
    return LegacyRoots(
      home: home,
      userProfile: Platform.isWindows ? env['USERPROFILE'] : null,
      appData: Platform.isWindows
          ? (env['APPDATA'] ?? _join(home, 'AppData\\Roaming'))
          : Platform.isMacOS
              ? _join(home, 'Library/Application Support')
              : _xdgConfig(env['XDG_CONFIG_HOME']) ?? _join(home, '.config'),
      guiHome: env['EPIC_GUI_HOME'],
    );
  }

  /// Electron's appData on Linux: $XDG_CONFIG_HOME when it is an absolute path, else ~/.config.
  static String? _xdgConfig(String? v) => v != null && v.startsWith('/') ? v : null;

  List<String> get _homes {
    final out = <String>[];
    for (final h in [userProfile, home]) {
      if (h != null && h.isNotEmpty && !out.contains(h)) out.add(h);
    }
    return out;
  }
}

/// A chain_data folder (lmdb/ inside).
class LegacyChain {
  const LegacyChain({required this.path, required this.network, required this.sizeBytes});
  final String path;
  final LegacyNetwork? network;
  final int sizeBytes;
}

/// An older Electron profile (contacts and labels live in its IndexedDB). Only reported, not read.
class LegacyProfile {
  const LegacyProfile({required this.app, required this.path});
  final String app;
  final String path;
}

/// One wallet folder.
class LegacyWallet {
  const LegacyWallet({
    required this.path,
    required this.seedPath,
    required this.network,
    required this.networkKnown,
    required this.label,
    required this.source,
    required this.sizeBytes,
    required this.lastUsed,
    required this.contacts,
    required this.seedFingerprint,
    required this.hasLinks,
    required this.seedBytes,
    required this.legacyDb,
    required this.app,
    this.chain,
    this.incomplete = false,
    this.account = '',
  });

  final String path;
  final String seedPath;

  /// Main when neither the folder names nor the toml tell ([networkKnown] false).
  final LegacyNetwork network;
  final bool networkKnown;

  /// The GUI's label from its settings, else the account name, else the folder name.
  final String label;
  final LegacySource source;

  /// wallet_data and wallet_tor, in bytes.
  final int sizeBytes;

  /// Newest modification time under wallet_data.
  final DateTime? lastUsed;

  /// Null: no readable contacts file. GUIs keep contacts in their Electron profile's IndexedDB,
  /// which is not read (opening it could change it).
  final int? contacts;

  /// sha256 (hex) of the wallet.seed file bytes; null when the seed is too large to read.
  final String? seedFingerprint;

  /// A symlink, junction or non-regular file inside wallet_data or wallet_tor, or the wallet
  /// folder, wallet_data or wallet_tor itself a link.
  final bool hasLinks;

  /// The walk of wallet_data or wallet_tor hit its limit or could not read a part.
  final bool incomplete;
  final int seedBytes;

  /// The old LMDB database (epic-wallet 3.x), not SQLite.
  final bool legacyDb;

  /// Which program wrote it, as far as its files say: '3.0.x', '4.x–5.x', '6.x' or '6.1' / 'CLI'.
  final String app;
  final LegacyChain? chain;

  /// The older GUIs' account name ('default' for `~/.epic/<net>`); '' when the folder does not say.
  /// Their Electron profile keys a wallet's contacts and settings by it.
  final String account;

  bool get seedTooLarge => seedBytes > maxSeedBytes;

  /// [label] as the wizard shows it: a label that is only a network folder name (main, floo,
  /// user) reads "Wallet (the epic program)" and the like.
  String get displayLabel {
    if (LegacyNetwork.fromFolder(label) == null) return label;
    return switch (source) {
      LegacySource.cli => 'Wallet (epic program)',
      LegacySource.gui => 'Wallet (older Epic Wallet)',
      LegacySource.picked => 'Wallet (chosen folder)',
    };
  }

  LegacyRefusal? get refusal => hasLinks
      ? LegacyRefusal.links
      : incomplete
          ? LegacyRefusal.incomplete
          : seedTooLarge
          ? LegacyRefusal.seedTooLarge
          : null;

  /// Whether the wizard may copy it.
  bool get copyable => refusal == null;
}

/// The result of [findLegacyWallets].
class LegacyScan {
  const LegacyScan({required this.wallets, required this.chains, required this.profiles});

  final List<LegacyWallet> wallets;
  final List<LegacyChain> chains;
  final List<LegacyProfile> profiles;

  bool get isEmpty => wallets.isEmpty;

  /// Wallets of one group, in the order found.
  List<LegacyWallet> of(LegacySource s) => [for (final w in wallets) if (w.source == s) w];

  /// Non-empty groups in screen order.
  Map<LegacySource, List<LegacyWallet>> get groups => {
        for (final s in LegacySource.values)
          if (of(s).isNotEmpty) s: of(s),
      };
}

/// What the wizard learns from "Choose a folder…".
class FolderPick {
  const FolderPick({required this.picked, required this.wallets, required this.chainOnly});
  final String picked;
  final List<LegacyWallet> wallets;

  /// Blockchain data, not a wallet.
  final bool chainOnly;

  /// The note to show when there is nothing to choose; null when [wallets] is not empty.
  String? get message => wallets.isNotEmpty ? null : (chainOnly ? chainOnlyText : noWalletText);
}

class ScanProgress {
  const ScanProgress({required this.checked, required this.found, this.current});

  /// Candidate folders looked at.
  final int checked;

  /// Wallets found so far.
  final int found;
  final String? current;
}

/// Why a wallet matches another: "Already in the app as <label>" or "Same wallet as <label>".
class SameWallet {
  const SameWallet(this.label, {required this.inApp});
  final String label;
  final bool inApp;
  String get text => inApp ? 'Already in the app as $label' : 'Same wallet as $label';
}

/// Finds wallets whose seed files are identical: equal bytes mean the same wallet and password.
/// [inApp] maps seed fingerprint → label of a wallet the app already holds. A wallet is matched
/// against the app first, then against an earlier row; the earliest row of a set has no note.
Map<String, SameWallet> findSameWallets(List<LegacyWallet> wallets, {Map<String, String> inApp = const {}}) {
  final out = <String, SameWallet>{};
  final firstOf = <String, LegacyWallet>{};
  for (final w in wallets) {
    final fp = w.seedFingerprint;
    if (fp == null) continue;
    final app = inApp[fp];
    if (app != null) {
      out[w.path] = SameWallet(app, inApp: true);
    } else if (firstOf[fp] != null) {
      out[w.path] = SameWallet(firstOf[fp]!.label, inApp: false);
    } else {
      firstOf[fp] = w;
    }
  }
  return out;
}

// ---------------------------------------------------------------------------------------------
// Scan

/// Looks in every place the older programs kept wallets. Never throws for a missing or unreadable
/// folder; never writes.
Future<LegacyScan> findLegacyWallets({required LegacyRoots roots, void Function(ScanProgress)? progress}) async {
  final s = _Scanner(roots, progress);
  await s.run();
  return LegacyScan(wallets: s.wallets, chains: s.chains.values.toList(), profiles: s.profiles);
}

class _Scanner {
  _Scanner(this.roots, this.progress);

  final LegacyRoots roots;
  final void Function(ScanProgress)? progress;
  final wallets = <LegacyWallet>[];
  final chains = <String, LegacyChain>{};
  final profiles = <LegacyProfile>[];
  final _seen = <String>{};
  int _checked = 0;

  Set<String> _epicDirs = {};

  Future<void> run() async {
    _epicDirs = {for (final h in roots._homes) _join(h, '.epic')};

    // 1. The older GUIs' account list: the account name and network are what the user knew it by.
    for (final epic in _epicDirs) {
      for (final e in await _accountDirs(_join(epic, 'epic_3-0-0_config.json'))) {
        await _fromAccountEntry(e);
      }
    }
    // 2. The folders in ~/.epic, for wallets the list lost or never had.
    for (final epic in _epicDirs) {
      for (final sub in await _subdirs(epic)) {
        final name = _base(sub);
        if (LegacyNetwork.fromFolder(name) != null) {
          await _consider(sub);
          for (final acc in await _subdirs(sub)) {
            await _consider(acc);
          }
        } else {
          for (final n in LegacyNetwork.values) {
            await _consider(_join(sub, n.folder));
          }
        }
      }
      // 3. The CLI's chain data without a wallet next to it.
      for (final n in LegacyNetwork.values) {
        await _addChain(_join(epic, n.folder, 'chain_data'), n);
      }
    }
    // 4. Older Electron profiles.
    final data = roots.appData;
    if (data != null) {
      for (final (app, name) in const [('≤5.3.1', 'EpicWallet'), ('6.0+', 'epic-desktop-wallet')]) {
        final p = _join(data, name);
        if (await _isDir(_join(p, 'IndexedDB'))) profiles.add(LegacyProfile(app: app, path: p));
      }
    }
  }

  Future<List<Map>> _accountDirs(String file) async {
    try {
      final j = jsonDecode(await File(file).readAsString());
      final list = j is Map && j['account_dirs'] is List ? j['account_dirs'] as List : const [];
      return [
        for (final e in list)
          if (e is Map && e['userhomedir'] is String && (e['userhomedir'] as String).isNotEmpty && _isAbs(e['userhomedir'] as String)) e
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _fromAccountEntry(Map e) async {
    final home = e['userhomedir'] as String;
    final net = LegacyNetwork.fromGui(e['network'] as String?);
    final acc = e['account'] is String ? e['account'] as String : '';
    for (final n in net != null ? [net] : LegacyNetwork.values) {
      await _consider(_join(home, n.folder), account: acc, network: net);
      if (acc.isNotEmpty && acc != 'default') {
        await _consider(_join(home, n.folder, acc), account: acc, network: net, layout30: true);
        // a 3.0 entry whose folder 4.x moved without updating the entry
        await _consider(_join(home, acc, n.folder), account: acc, network: net);
      }
    }
  }

  Future<void> _consider(String dir,
      {LegacySource? source, String? label, String account = '', LegacyNetwork? network, bool layout30 = false}) async {
    progress?.call(ScanProgress(checked: ++_checked, found: wallets.length, current: dir));
    if (!await File(_join(dir, 'wallet_data', 'wallet.seed')).exists()) return;
    final key = await _realKey(dir);
    if (!_seen.add(key)) return;
    final w = await _describe(dir,
        source: source, label: label, account: account, network: network, layout30: layout30, real: key);
    if (w == null) return;
    wallets.add(w);
    if (w.chain != null) chains[w.chain!.path] = w.chain!;
    progress?.call(ScanProgress(checked: _checked, found: wallets.length, current: dir));
  }

  Future<void> _addChain(String dir, LegacyNetwork net) async {
    if (!await _isDir(_join(dir, 'lmdb'))) return;
    final key = await _realKey(dir);
    for (final c in chains.values) {
      if (await _realKey(c.path) == key) return;
    }
    chains[dir] = LegacyChain(path: dir, network: net, sizeBytes: await _chainBytes(dir));
  }

  Future<LegacyWallet?> _describe(String dir,
      {LegacySource? source,
      String? label,
      String account = '',
      LegacyNetwork? network,
      bool layout30 = false,
      required String real}) async {
    final base = _base(dir), parent = _dirname(dir);
    final parentBase = _base(parent);
    final isNetDir = LegacyNetwork.fromFolder(base) != null;
    final lay30 = layout30 || (!isNetDir && LegacyNetwork.fromFolder(parentBase) != null);
    var known = true;
    var net = network ?? LegacyNetwork.fromFolder(base) ?? LegacyNetwork.fromFolder(parentBase);
    net ??= await _tomlNetwork(dir);
    if (net == null) {
      net = LegacyNetwork.main;
      known = false;
    }
    final isCli = isNetDir && _epicDirs.any((e) => _norm(e) == _norm(parent));
    var acc = account;
    if (acc.isEmpty) acc = lay30 ? base : (isCli ? 'default' : (isNetDir ? parentBase : ''));
    final name = label ?? (acc.isNotEmpty && acc != 'default' ? acc : base);

    final seedPath = _join(dir, 'wallet_data', 'wallet.seed');
    final int seedBytes;
    try {
      seedBytes = (await File(seedPath).stat()).size;
    } catch (_) {
      return null;
    }
    if (seedBytes <= 0) return null; // an empty seed file is no wallet
    String? fp;
    if (seedBytes <= maxSeedBytes) {
      try {
        fp = sha256.convert(await File(seedPath).readAsBytes()).toString();
      } catch (_) {
        return null;
      }
    }

    final walk = await _walkWallet(dir);
    if (await _folderIsLink(dir)) walk.links = true;
    final wd = _join(dir, 'wallet_data');
    final legacyDb = await _isDir(_join(wd, 'db', 'lmdb')) || !await _isDir(_join(wd, 'db', 'sqlite'));
    final chainDir = _join(dir, 'chain_data');
    LegacyChain? chain;
    if (await _isDir(_join(chainDir, 'lmdb'))) {
      chain = LegacyChain(path: chainDir, network: net, sizeBytes: await _chainBytes(chainDir));
    }
    return LegacyWallet(
      path: dir,
      seedPath: seedPath,
      network: net,
      networkKnown: known,
      label: name,
      source: source ?? (isCli ? LegacySource.cli : LegacySource.gui),
      sizeBytes: walk.bytes,
      lastUsed: walk.newest,
      contacts: null,
      seedFingerprint: fp,
      hasLinks: walk.links,
      incomplete: walk.incomplete,
      seedBytes: seedBytes,
      legacyDb: legacyDb,
      app: isCli ? 'CLI' : await _guessApp(dir, lay30),
      chain: chain,
      account: acc,
    );
  }

  Future<String> _guessApp(String dir, bool layout30) async {
    String? version;
    try {
      final j = jsonDecode(await File(_join(dir, 'config.json')).readAsString());
      if (j is Map && j['version'] is String) version = j['version'] as String;
    } catch (_) {}
    if (layout30 || (version?.startsWith('3.') ?? false)) return '3.0.x';
    var toml = '';
    try {
      toml = await File(_join(dir, 'epic-wallet.toml')).readAsString();
    } catch (_) {}
    if (RegExp(r'^\s*owner_api_interface\s*=', multiLine: true).hasMatch(toml) || await _isDir(_join(dir, 'wallet_tor'))) {
      return '6.x';
    }
    return '4.x–5.x';
  }
}

/// The GUI 6.1 root a wallet folder sits in (`<root>/wallets/<id>`), or null. Nothing is searched:
/// only the folder the user picked, so a GUI 6.1 folder is read when they choose it.
String? guiRootOfWallet(String walletPath) {
  final parent = _dirname(walletPath);
  if (_base(parent) != 'wallets') return null;
  final root = _dirname(parent);
  return root == parent ? null : root;
}

// ---------------------------------------------------------------------------------------------
// Choose a folder

/// What a folder picked by hand holds: a wallet, wallets below it (~/.epic, a folder of wallets),
/// "Blockchain data, not a wallet.", or nothing ([FolderPick.message] says which).
/// Reads only.
Future<FolderPick> inspectFolder(String path) async {
  final dir = _normalizePath(path);
  final s = _Scanner(const LegacyRoots(home: ''), null).._epicDirs = {};
  Future<bool> isWallet(String d) => File(_join(d, 'wallet_data', 'wallet.seed')).exists();
  var reads = 0;
  Future<List<String>> subs(String d) async => ++reads > _readLimit ? const [] : await _subdirs(d);

  Future<FolderPick> done(bool chainOnly) async => FolderPick(picked: dir, wallets: s.wallets, chainOnly: chainOnly);
  Future<void> add(String d) => s._consider(d, source: LegacySource.picked);

  final base = _base(dir);
  if (!await isWallet(dir) && (base == 'chain_data' || await _isDir(_join(dir, 'lmdb')))) {
    final parent = _dirname(dir);
    if (parent != dir && await isWallet(parent)) await add(parent);
    return done(true);
  }
  if (await isWallet(dir)) {
    await add(dir);
    return done(false);
  }
  const parts = ['wallet_data', 'chain_data', 'wallet_tor'];
  if (!parts.contains(base)) {
    // the wallets one and two levels down (two only through a network folder)
    for (final child in await subs(dir)) {
      final name = _base(child);
      if (await isWallet(child)) await add(child);
      for (final grand in await subs(child)) {
        // GUI 6.1's root: its wallets/<id>
        if ((name == 'wallets' || LegacyNetwork.fromFolder(name) != null || LegacyNetwork.fromFolder(_base(grand)) != null) && await isWallet(grand)) {
          await add(grand);
        }
      }
    }
    if (s.wallets.isNotEmpty) return done(false);
  }
  // a folder inside a wallet (wallet_data, wallet_data/db, wallet_tor, ...): the nearest wallet above
  var d = dir;
  for (var i = 0; i < 4; i++) {
    final up = _dirname(d);
    if (up == d) break;
    d = up;
    if (await isWallet(d)) {
      await add(d);
      break;
    }
  }
  return done(false);
}

// ---------------------------------------------------------------------------------------------
// In use

/// A running program, as far as the platform tells.
class RunningProcess {
  const RunningProcess({required this.pid, required this.name, required this.args, this.cwd, this.argsKnown = true});
  final int pid;
  final String name;
  final List<String> args;

  /// False when the platform would not give the arguments ([args] is then empty).
  final bool argsKnown;

  /// Null when the platform would not tell.
  final String? cwd;
}

/// Lists the running programs; null when the platform gives no list.
typedef ProcessLister = Future<List<RunningProcess>?> Function();

const _walletPrograms = {'epic-wallet', 'epic-wallet.exe', 'epic', 'epic.exe'};

/// Whether a running `epic-wallet` or `epic` names this wallet's folder as its working directory
/// or in its arguments. Lock files are not looked at: they stay on disk after a program exits.
/// Creates and locks nothing. [InUse.unknown] when the platform gives no process list, or a
/// wallet program runs whose folder cannot be told.
Future<InUse> checkInUse(LegacyWallet w, {ProcessLister? listProcesses}) async {
  List<RunningProcess>? procs;
  try {
    procs = await (listProcesses ?? _listProcesses)();
  } catch (_) {
    procs = null;
  }
  if (procs == null) return InUse.unknown;
  final target = _norm(await _realKey(w.path));
  var unclear = false;
  for (final p in procs) {
    if (!_walletPrograms.contains(_base(p.name).toLowerCase())) continue;
    var named = false;
    final cwd = p.cwd;
    if (cwd != null && _within(_norm(cwd), target)) return InUse.inUse;
    if (cwd == null) unclear = true;
    if (!p.argsKnown) {
      unclear = true;
      continue;
    }
    for (var i = 0; i < p.args.length; i++) {
      final a = p.args[i];
      if (a.isEmpty || a.startsWith('-') && !a.contains('/') && !a.contains('\\')) continue;
      // a bare word is a path only as the value of the flag before it; otherwise a subcommand
      final isValue = i > 0 && p.args[i - 1].startsWith('-') && !p.args[i - 1].contains('=');
      if (!a.startsWith('-') && !a.contains('/') && !a.contains('\\') && !isValue) continue;
      final v = a.contains('=') && a.startsWith('-') ? a.substring(a.indexOf('=') + 1) : a;
      final abs = _isAbs(v) ? v : (cwd != null ? _join(cwd, v) : null);
      if (abs == null) continue;
      named = true;
      if (_within(_norm(_normalizePath(abs)), target)) return InUse.inUse;
    }
    if (named && cwd == null) unclear = true;
    if (!named && cwd != null && _base(_dirname(w.path)) == '.epic' && !File(_join(cwd, 'epic-wallet.toml')).existsSync()) {
      // No folder given and none in the working directory: the epic program falls back to
      // ~/.epic/<main|floo|user> by its network flags.
      final flags = p.args.map((a) => a.toLowerCase());
      final net = flags.contains('--floonet') ? LegacyNetwork.floo : flags.contains('--usernet') ? LegacyNetwork.user : LegacyNetwork.main;
      if (_base(w.path) == net.folder) return InUse.inUse;
    }
  }
  return unclear ? InUse.unknown : InUse.free;
}

/// Whether [path] is [folder] or inside it, both resolved through links when they exist.
Future<bool> isWithin(String path, String folder) async => _within(await _realKey(path), await _realKey(folder));

bool _within(String candidate, String folder) =>
    candidate == folder || candidate.startsWith(folder.endsWith(_sep) ? folder : folder + _sep);

Future<List<RunningProcess>?> _listProcesses() async {
  if (Platform.isLinux) {
    final proc = Directory('/proc');
    if (!await proc.exists()) return null;
    final out = <RunningProcess>[];
    await for (final e in proc.list(followLinks: false)) {
      final pid = int.tryParse(_base(e.path));
      if (pid == null) continue;
      try {
        final raw = await File('${e.path}/cmdline').readAsBytes();
        if (raw.isEmpty) continue;
        final parts = utf8.decode(raw, allowMalformed: true).split('\u0000')..removeWhere((x) => x.isEmpty);
        if (parts.isEmpty) continue;
        String? cwd;
        try {
          cwd = await Link('${e.path}/cwd').target();
        } catch (_) {}
        out.add(RunningProcess(pid: pid, name: parts.first, args: parts.sublist(1), cwd: cwd));
      } catch (_) {/* gone, or another user's */}
    }
    return out;
  }
  if (Platform.isMacOS) {
    // Paths may hold spaces, so the arguments are not split out of ps: the program name comes
    // from comm and the working directory from lsof; the arguments stay unknown.
    final ps = await Process.run('ps', ['-axo', 'pid=,comm=']);
    if (ps.exitCode != 0) return null;
    final out = <RunningProcess>[];
    for (final line in const LineSplitter().convert(ps.stdout as String)) {
      final m = RegExp(r'^\s*(\d+)\s+(.*)$').firstMatch(line);
      if (m == null) continue;
      final name = m.group(2)!;
      if (!_walletPrograms.contains(_base(name))) continue;
      String? cwd;
      try {
        final l = await Process.run('lsof', ['-a', '-p', m.group(1)!, '-d', 'cwd', '-Fn']);
        for (final r in const LineSplitter().convert(l.stdout as String)) {
          if (r.startsWith('n')) cwd = r.substring(1);
        }
      } catch (_) {}
      out.add(RunningProcess(pid: int.parse(m.group(1)!), name: name, args: const [], cwd: cwd, argsKnown: false));
    }
    return out;
  }
  return null; // Windows: no cheap read-only answer
}

// ---------------------------------------------------------------------------------------------
// Folder hash

/// Files up to this size (not databases) are hashed by content.
const int _hashContentLimit = 64 * 1024;

/// Database and LMDB files: a program holding them open may lock them on Windows, so they are
/// never opened, only stat'ed.
bool _isDatabaseFile(String rel) {
  final parts = rel.split('/');
  final name = parts.last;
  if (name == 'lock.mdb' || ['.db', '-wal', '-shm', '-journal', '.mdb'].any(name.endsWith)) return true;
  for (var i = 0; i < parts.length - 1; i++) {
    if (parts[i] == 'chain_data' || (parts[i] == 'wallet_data' && i + 1 < parts.length - 1 && parts[i + 1] == 'db')) return true;
  }
  return false;
}

/// A stable sha256 (hex) over every entry under [path]: relative path, kind, size, modification
/// time and, for small files that are not databases, contents (a link's target). Database files
/// are never opened. Changes when anything in the folder changes, or when an entry vanishes
/// during the walk. Reads only.
Future<String> folderHash(String path) async {
  final root = _normalizePath(path);
  final rows = <String>[];
  Future<void> walk(String dir, String rel) async {
    final list = <FileSystemEntity>[];
    try {
      await for (final e in Directory(dir).list(followLinks: false)) {
        list.add(e);
      }
    } catch (_) {
      rows.add('$rel\tunreadable');
      return;
    }
    list.sort((a, b) => _base(a.path).compareTo(_base(b.path)));
    for (final e in list) {
      final name = _base(e.path);
      final r = rel.isEmpty ? name : '$rel/$name';
      try {
        final type = await FileSystemEntity.type(e.path, followLinks: false);
        final st = await e.stat();
        if (st.type == FileSystemEntityType.notFound) throw const FileSystemException('gone');
        switch (type) {
          case FileSystemEntityType.directory:
            rows.add('$r\td\t${st.modified.millisecondsSinceEpoch}');
            await walk(e.path, r);
          case FileSystemEntityType.link:
            String t;
            try {
              t = await Link(e.path).target();
            } catch (_) {
              t = '?';
            }
            rows.add('$r\tl\t$t');
          case FileSystemEntityType.file:
            final isSeed = r == 'wallet_data/wallet.seed';
            final byContent = !_isDatabaseFile(r) && (isSeed ? st.size <= maxSeedBytes : st.size <= _hashContentLimit);
            String h = '-';
            if (byContent) {
              try {
                h = sha256.convert(await File(e.path).readAsBytes()).toString();
              } catch (_) {
                h = 'unreadable';
              }
            }
            rows.add('$r\tf\t${st.size}\t${st.modified.millisecondsSinceEpoch}\t$h');
          default:
            rows.add('$r\tother');
        }
      } on FileSystemException {
        rows.add('$r\tvanished'); // gone mid-walk: the hash differs from the complete folder's
      }
    }
  }

  await walk(root, '');
  return sha256.convert(utf8.encode(rows.join('\n'))).toString();
}

// ---------------------------------------------------------------------------------------------
// Helpers

class _Walk {
  int bytes = 0;
  DateTime? newest;
  bool links = false;
  bool incomplete = false;
}

bool _isLinkNow(String p) => FileSystemEntity.typeSync(p, followLinks: false) == FileSystemEntityType.link;

/// The wallet folder, wallet_data or wallet_tor is itself a symlink or junction: its own type
/// says link, or it resolves to somewhere other than where its parent's real path puts it.
Future<bool> _folderIsLink(String dir) async {
  if (_isLinkNow(dir)) return true;
  String real;
  try {
    real = await Directory(dir).resolveSymbolicLinks();
  } catch (_) {
    return false;
  }
  for (final name in const ['wallet_data', 'wallet_tor']) {
    final sub = _join(dir, name);
    if (_isLinkNow(sub)) return true;
    if (!await _isDir(sub)) continue;
    try {
      if (_norm(await Directory(sub).resolveSymbolicLinks()) != _norm(_join(real, name))) return true;
    } catch (_) {
      return true;
    }
  }
  return false;
}

/// wallet_data and wallet_tor: size, newest mtime (wallet_data only), links. lstat only.
Future<_Walk> _walkWallet(String dir) async {
  final out = _Walk();
  var seen = 0;
  Future<void> walk(String d, bool data) async {
    try {
      await for (final e in Directory(d).list(followLinks: false)) {
        if (++seen > _walletWalkLimit) {
          out.incomplete = true;
          return;
        }
        final t = await FileSystemEntity.type(e.path, followLinks: false);
        if (t == FileSystemEntityType.directory) {
          await walk(e.path, data);
        } else if (t == FileSystemEntityType.file) {
          final st = await e.stat();
          out.bytes += st.size;
          if (data && (out.newest == null || st.modified.isAfter(out.newest!))) out.newest = st.modified;
        } else if (t != FileSystemEntityType.notFound) {
          out.links = true;
        }
      }
    } catch (_) {
      out.incomplete = true; // unreadable part: counted as far as read, and the wallet refused
    }
  }

  await walk(_join(dir, 'wallet_data'), true);
  if (await _isDir(_join(dir, 'wallet_tor'))) await walk(_join(dir, 'wallet_tor'), false);
  return out;
}

Future<int> _chainBytes(String chainDir) async {
  var bytes = 0, seen = 0;
  Future<void> walk(String d, int depth) async {
    try {
      await for (final e in Directory(d).list(followLinks: false)) {
        if (++seen > _chainWalkLimit) return;
        final t = await FileSystemEntity.type(e.path, followLinks: false);
        if (t == FileSystemEntityType.directory) {
          if (depth < 4) await walk(e.path, depth + 1);
        } else if (t == FileSystemEntityType.file) {
          bytes += (await e.stat()).size;
        }
      }
    } catch (_) {}
  }

  for (final sub in const ['lmdb', 'txhashset', 'header']) {
    await walk(_join(chainDir, sub), 0);
  }
  return bytes;
}

Future<LegacyNetwork?> _tomlNetwork(String dir) async {
  try {
    final t = await File(_join(dir, 'epic-wallet.toml')).readAsString();
    final m = RegExp(r'^\s*chain_type\s*=\s*"([^"]*)"', multiLine: true).firstMatch(t);
    return m == null ? null : LegacyNetwork.fromChainType(m.group(1)!);
  } catch (_) {
    return null;
  }
}

Future<List<String>> _subdirs(String dir) async {
  final out = <String>[];
  try {
    await for (final e in Directory(dir).list(followLinks: false)) {
      if (e is Directory) out.add(e.path);
    }
  } catch (_) {}
  out.sort();
  return out;
}

Future<bool> _isDir(String p) => FileSystemEntity.isDirectory(p);

Future<String> _realKey(String p) async {
  try {
    return _norm(await Directory(p).resolveSymbolicLinks());
  } catch (_) {
    return _norm(_normalizePath(p));
  }
}

String get _sep => Platform.pathSeparator;

/// Windows paths are case-insensitive.
String _norm(String p) => Platform.isWindows ? p.toLowerCase() : p;

bool _isAbs(String p) => Platform.isWindows ? RegExp(r'^([A-Za-z]:[\\/]|\\\\)').hasMatch(p) : p.startsWith('/');

String _join(String a, [String? b, String? c, String? d]) {
  final parts = [a, ?b, ?c, ?d];
  var out = parts.first;
  for (final p in parts.skip(1)) {
    out = out.endsWith('/') || out.endsWith('\\') ? '$out$p' : '$out$_sep$p';
  }
  return out;
}

String _base(String p) {
  final t = p.length > 1 && (p.endsWith('/') || p.endsWith('\\')) ? p.substring(0, p.length - 1) : p;
  final i = t.lastIndexOf(Platform.isWindows ? RegExp(r'[\\/]') : '/');
  return i < 0 ? t : t.substring(i + 1);
}

String _dirname(String p) {
  final t = p.length > 1 && (p.endsWith('/') || p.endsWith('\\')) ? p.substring(0, p.length - 1) : p;
  final i = t.lastIndexOf(Platform.isWindows ? RegExp(r'[\\/]') : '/');
  return i < 0 ? '.' : (i == 0 ? t.substring(0, 1) : t.substring(0, i));
}

/// Absolute-ish path without a trailing separator or `.`/`..` segments.
String _normalizePath(String p) {
  final abs = _isAbs(p) ? p : _join(Directory.current.path, p);
  final out = Uri.file(abs, windows: Platform.isWindows)
      .toFilePath(windows: Platform.isWindows)
      .replaceFirst(RegExp(r'[\\/]+$'), '');
  return out.isEmpty ? _sep : out;
}
