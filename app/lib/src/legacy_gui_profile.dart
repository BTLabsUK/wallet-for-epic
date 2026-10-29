// SPDX-License-Identifier: Apache-2.0
/// What the Import wizard brings across from an older Epic GUI besides the wallet itself: its
/// label, node, Epicbox server and contacts, as GUI 6.1.6's own importer brings them
/// (epic-gui-wallet src/shared/importer.js at release 6.1.6). Its language and built-in node
/// choice are not read: nothing in this app would apply them. Read only: files are opened for
/// reading and nothing is created, locked, renamed or written in any folder read. Plain Dart
/// (dart:io), no Flutter.
///
/// Where it is (see legacy_wallets.dart for finding the wallets themselves):
///
/// ```text
///     GUI 6.1   <root>/settings.json   wallets[] {id, label, dataDir, settings{check_node_api_http_addr,
///                                      nodeInternal, epicbox_domain}}, app.locale, myNodes
///               <root>/app/IndexedDB/app_._0.indexeddb.leveldb   contacts: User.account = the wallet id
///     GUI ≤6.0  <wallet>/config.json   check_node_api_http_addr, epicbox_domain, locale
///               <appData>/EpicWallet (≤5.3.1), <appData>/epic-desktop-wallet (6.0)   Electron profiles:
///                                      IndexedDB Epicwallet, User.account = the account name
///     CLI       <wallet>/epic-wallet.toml   check_node_api_http_addr, [epicbox] domain and port
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'legacy/gui_rules.dart';
import 'legacy/indexeddb.dart';
import 'legacy_wallets.dart';

export 'legacy/gui_rules.dart' show cleanNodeAddress, fallbackNodeAddress, importerNodeAddress, cleanEpicbox;

/// The IndexedDB database of every GUI (idbService.js dbname).
const String guiDbName = 'Epicwallet';

/// The Electron profiles older GUIs used, newest first (legacyProfile.js PROFILE_NAMES; the newer
/// profile's User row wins in mergeProfiles).
const List<(String app, String folder)> guiProfiles = [('6.0+', 'epic-desktop-wallet'), ('≤5.3.1', 'EpicWallet')];

const int _maxJsonBytes = 4 << 20;
const int _maxTomlBytes = 1 << 20;
const int _maxContacts = 10000;
const int _maxField = 4096;

/// One contact of an old GUI's address book (the Addressbook row: externalOne is the Epicbox
/// address, externalTwo the HTTP(S) address, notice the note, onion a Tor address older versions
/// kept). Empty fields are null.
class LegacyContact {
  const LegacyContact({required this.name, this.epicboxAddress, this.httpAddress, this.onion, this.note});

  final String name;
  final String? epicboxAddress;
  final String? httpAddress;
  final String? onion;
  final String? note;

  @override
  String toString() => 'LegacyContact($name, epicbox: $epicboxAddress, http: $httpAddress, onion: $onion, note: $note)';
}

/// A node the user saved in GUI 6.1.6's "My nodes".
class LegacyNode {
  const LegacyNode({required this.address, required this.label});
  final String address;
  final String label;
}

/// What GUI 6.1 keeps for the whole app.
class LegacyGuiGlobal {
  const LegacyGuiGlobal({this.myNodes = const {}, this.notes = const []});

  /// Network ('mainnet', 'floonet', 'usernet') → its saved nodes, cleaned as myNodes.js does.
  final Map<String, List<LegacyNode>> myNodes;
  final List<String> notes;
}

/// Everything found for one old wallet folder.
class LegacyGuiImport {
  const LegacyGuiImport({
    this.label,
    this.nodeUrl,
    this.epicboxDomain,
    this.epicboxPort,
    this.contacts = const [],
    this.addressBookDamaged = false,
    this.notes = const [],
  });

  /// The wallet's name in the old GUI (cleaned as settingsStore.js cleanLabel); null when none.
  final String? label;

  /// The node address, cleaned as importer.js does; null when the old GUI had none (its default).
  final String? nodeUrl;

  /// The Epicbox domain, cleaned (a renamed server becomes its new name); null when none.
  final String? epicboxDomain;

  /// The Epicbox port: 443 unless the wallet's toml says otherwise; null with no [epicboxDomain].
  final int? epicboxPort;

  final List<LegacyContact> contacts;

  /// The old address book was found but could not be read whole (a damaged file): [contacts]
  /// may lack some.
  final bool addressBookDamaged;

  /// What could not be read, and why, for the log or a quiet line in the wizard.
  final List<String> notes;
}

/// Reads GUI 6.1's app-wide settings, from the root [wallet] was picked in: "My nodes". Nothing
/// without such a root. Never throws.
Future<LegacyGuiGlobal> readGuiGlobal(LegacyWallet wallet) async {
  final notes = <String>[];
  for (final root in [?guiRootOfWallet(wallet.path)]) {
    final s = await _readJson(_join(root, 'settings.json'), notes);
    if (s == null) continue;
    return LegacyGuiGlobal(myNodes: _myNodes(s['myNodes']), notes: notes);
  }
  return LegacyGuiGlobal(notes: notes);
}

/// myNodes.js normalizeMyNodes for the three networks.
Map<String, List<LegacyNode>> _myNodes(Object? raw) {
  final out = <String, List<LegacyNode>>{};
  if (raw is! Map) return out;
  for (final net in const ['mainnet', 'floonet', 'usernet']) {
    final list = raw[net];
    if (list is! List) continue;
    final nodes = <LegacyNode>[];
    final seen = <String>{};
    for (final e in list) {
      if (e is! Map) continue;
      final address = nodeCheckAddress(e['address'] is String ? e['address'] as String : '');
      if (address.isEmpty || !seen.add(nodeAddressKey(address))) continue;
      final label = e['label'] is String ? cleanGuiLabel(e['label'] as String, max: guiNodeLabelMax) : '';
      nodes.add(LegacyNode(address: address, label: label));
      if (nodes.length >= guiMyNodesMax) break;
    }
    if (nodes.isNotEmpty) out[net] = nodes;
  }
  return out;
}

/// Reads what the old GUI kept for [wallet]: from GUI 6.1's settings.json when it lists the
/// wallet's folder, else from the wallet's config.json and the older Electron profiles, else (the
/// epic program's wallets) from its epic-wallet.toml. Never throws.
///
/// [scratch] is not written to: every format here is read in place. It is taken so a later reader
/// that needs a copy has a place of the caller's for it.
Future<LegacyGuiImport> readGuiImport(LegacyRoots roots, LegacyWallet wallet, {Directory? scratch}) async {
  final notes = <String>[];
  try {
    for (final root in [?guiRootOfWallet(wallet.path)]) {
      final s = await _readJson(_join(root, 'settings.json'), notes);
      final list = s?['wallets'];
      if (list is! List) continue;
      for (final w in list) {
        if (w is Map && w['dataDir'] is String && await _samePath(w['dataDir'] as String, wallet.path)) {
          return await _from61(root, s!, w, wallet, notes);
        }
      }
    }
    // ~/.epic/main is the epic program's folder and the older GUIs' 'default' account: a GUI
    // left its config.json there
    final cli = wallet.source == LegacySource.cli || wallet.app == 'CLI';
    if (cli && !await File(_join(wallet.path, 'config.json')).exists()) return await _fromToml(wallet, notes);
    return await _fromOlderGui(roots, wallet, notes);
  } catch (e) {
    notes.add('Could not read the old settings: $e');
    return LegacyGuiImport(notes: notes);
  }
}

// ---- GUI 6.1

Future<LegacyGuiImport> _from61(String root, Map s, Map w, LegacyWallet wallet, List<String> notes) async {
  final id = w['id'] is String ? w['id'] as String : '';
  final set = w['settings'] is Map ? w['settings'] as Map : const {};
  final network = w['network'] is String ? w['network'] as String : wallet.network.guiName;

  var damaged = false;
  final read = await _readProfile(_join(root, 'app'), '6.1', notes, damaged: () => damaged = true);
  final user = read == null ? null : _userOf(read, id);
  final contacts = read == null || user == null ? <LegacyContact>[] : _contactsOf([(read, user)]);
  if (read != null && user == null && id.isNotEmpty) notes.add('GUI 6.1 has no address book for wallet $id.');

  final label = w['label'] is String ? cleanGuiLabel(w['label'] as String) : '';
  final toml = await _readToml(w['configDir'] is String ? w['configDir'] as String : wallet.path, notes);
  final node = _node(_str(set['check_node_api_http_addr']), network, notes);
  final box = _str(set['epicbox_domain']).trim();
  return LegacyGuiImport(
    label: label.isEmpty ? null : label,
    nodeUrl: node,
    epicboxDomain: box.isEmpty ? null : cleanEpicbox(box),
    epicboxPort: box.isEmpty ? null : (toml.epicboxPort ?? 443),
    contacts: contacts,
    addressBookDamaged: damaged,
    notes: notes,
  );
}

// ---- GUI up to 6.0

Future<LegacyGuiImport> _fromOlderGui(LegacyRoots roots, LegacyWallet wallet, List<String> notes) async {
  final cfg = await _readJson(_join(wallet.path, 'config.json'), notes) ?? const {};
  final account = wallet.account;
  final network = wallet.network.guiName;

  // mergeProfiles: the newest profile's User row wins; contacts of both, a repeat once
  final found = <(IdbRead, Map)>[];
  var damaged = false;
  final data = roots.appData;
  if (data != null && account.isNotEmpty) {
    for (final (app, folder) in guiProfiles) {
      final read = await _readProfile(_join(data, folder), app, notes, damaged: () => damaged = true);
      if (read == null) continue;
      final u = _userOf(read, account);
      if (u != null) found.add((read, u));
    }
    if (found.isEmpty) notes.add('No contacts or settings for account "$account" in the older GUI profiles.');
  } else if (account.isEmpty) {
    notes.add("The wallet's account name is not known, so its contacts could not be matched.");
  }
  final user = found.isEmpty ? const {} : found.first.$2;

  // importer.js scan(): the label is the User row's name, else the account unless 'default'
  final name = _str(user['name']).trim();
  final label = cleanGuiLabel(name.isNotEmpty ? name : (account == 'default' ? '' : account));
  final box = _str(user['epicbox_domain']).isNotEmpty ? _str(user['epicbox_domain']) : _str(cfg['epicbox_domain']);
  final toml = await _readToml(wallet.path, notes);
  return LegacyGuiImport(
    label: label.isEmpty ? null : label,
    nodeUrl: _node(_str(cfg['check_node_api_http_addr']), network, notes),
    epicboxDomain: box.trim().isEmpty ? null : cleanEpicbox(box),
    epicboxPort: box.trim().isEmpty ? null : (toml.epicboxPort ?? 443),
    contacts: _contactsOf(found),
    addressBookDamaged: damaged,
    notes: notes,
  );
}

// ---- the epic program

Future<LegacyGuiImport> _fromToml(LegacyWallet wallet, List<String> notes) async {
  final t = await _readToml(wallet.path, notes);
  final box = (t.epicboxDomain ?? '').trim();
  return LegacyGuiImport(
    nodeUrl: _node(t.node ?? '', wallet.network.guiName, notes),
    epicboxDomain: box.isEmpty ? null : cleanEpicbox(box),
    epicboxPort: box.isEmpty ? null : (t.epicboxPort ?? 443),
    notes: notes,
  );
}

// ---- helpers

/// importer.js cleanNode; null for an empty address (the old GUI's default) and for one that is no
/// http(s) address after cleaning (GUI 6.1 would keep it, and fail to reach it).
String? _node(String saved, String network, List<String> notes) {
  if (saved.trim().isEmpty) return null;
  final url = importerNodeAddress(saved, network: network);
  if (nodeCheckAddress(url) != url) {
    notes.add('The saved node address "${_short(saved)}" is not a node address; it was left out.');
    return null;
  }
  return url;
}

/// The IndexedDB of an Electron profile (or GUI 6.1's `<root>/app`): the app://. origin's folder,
/// else another origin's that holds the GUI's database (a development build). Null with a note.
/// [damaged] is called when the folder or the database is there but could not be read whole.
Future<IdbRead?> _readProfile(String profile, String app, List<String> notes, {required void Function() damaged}) async {
  final idb = _join(profile, 'IndexedDB');
  if (!await Directory(idb).exists()) return null;
  final dirs = <String>[];
  try {
    var n = 0;
    await for (final e in Directory(idb).list(followLinks: false)) {
      if (++n > 200) break;
      final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (e is Directory && name.endsWith('.indexeddb.leveldb')) dirs.add(name);
    }
  } catch (e) {
    notes.add('GUI $app profile: the IndexedDB folder could not be listed.');
    damaged();
    return null;
  }
  dirs.sort((a, b) => a == 'app_._0.indexeddb.leveldb' ? -1 : (b == 'app_._0.indexeddb.leveldb' ? 1 : a.compareTo(b)));
  for (final d in dirs.take(10)) {
    final r = await readIdbStores(_join(idb, d), guiDbName, {'User', 'Addressbook'});
    if (!r.found) {
      if (r.notes.isNotEmpty) damaged();
      continue;
    }
    for (final n in r.notes) {
      notes.add('GUI $app profile: $n');
    }
    if (r.notes.isNotEmpty) damaged();
    return r;
  }
  notes.add('GUI $app profile: no address book found in its IndexedDB.');
  return null;
}

/// The User row of [account] (importer.js matches User.account).
Map? _userOf(IdbRead r, String account) {
  for (final u in r.stores['User'] ?? const <IdbRecord>[]) {
    final v = u.value;
    if (v is Map && v['account'] == account) return {...v, 'id': u.key};
  }
  return null;
}

/// The contacts of each (profile, User row), newest profile first, a [name, onion] repeat once
/// (legacyProfile.js mergeProfiles, importer.js dedupeKey).
List<LegacyContact> _contactsOf(List<(IdbRead, Map)> found) {
  final out = <LegacyContact>[];
  final seen = <String>{};
  for (final (read, user) in found) {
    final uid = user['id'];
    for (final r in read.stores['Addressbook'] ?? const <IdbRecord>[]) {
      final c = r.value;
      if (c is! Map || uid == null || !_sameId(c['user_id'], uid)) continue;
      final key = jsonEncode([_str(c['name']), _str(c['onion'])]);
      if (!seen.add(key)) continue;
      out.add(LegacyContact(
        name: _field(c['name']) ?? '',
        epicboxAddress: _field(c['externalOne']),
        httpAddress: _field(c['externalTwo']),
        onion: _field(c['onion']),
        note: _field(c['notice']),
      ));
      if (out.length >= _maxContacts) return out;
    }
  }
  return out;
}

bool _sameId(Object? a, Object? b) => a is num && b is num ? a == b : a == b;

String _str(Object? v) => v is String ? v : '';

String? _field(Object? v) {
  final s = _str(v).trim();
  if (s.isEmpty) return null;
  return s.length > _maxField ? s.substring(0, _maxField) : s;
}

String _short(String s) => s.length > 60 ? '${s.substring(0, 57)}...' : s;

Future<Map?> _readJson(String path, List<String> notes) async {
  final f = File(path);
  try {
    if (!await f.exists()) return null;
    if (await f.length() > _maxJsonBytes) {
      notes.add('${_name(path)} is too large to read.');
      return null;
    }
    final j = jsonDecode(utf8.decode(await f.readAsBytes(), allowMalformed: true));
    if (j is Map) return j;
    notes.add('${_name(path)} holds no settings.');
  } catch (e) {
    notes.add('${_name(path)} could not be read.');
  }
  return null;
}

class _Toml {
  const _Toml({this.node, this.epicboxDomain, this.epicboxPort});
  final String? node;
  final String? epicboxDomain;
  final int? epicboxPort;
}

/// The few keys of epic-wallet.toml read here: check_node_api_http_addr (in [wallet]),
/// epicbox_domain and epicbox_port (in [epicbox]). Line by line, as the GUIs patch it.
Future<_Toml> _readToml(String dir, List<String> notes) async {
  final f = File(_join(dir, 'epic-wallet.toml'));
  String text;
  try {
    if (!await f.exists()) return const _Toml();
    if (await f.length() > _maxTomlBytes) {
      notes.add('epic-wallet.toml is too large to read.');
      return const _Toml();
    }
    text = utf8.decode(await f.readAsBytes(), allowMalformed: true);
  } catch (_) {
    notes.add('epic-wallet.toml could not be read.');
    return const _Toml();
  }
  String? node, domain;
  int? port;
  var section = '';
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trim();
    final sec = RegExp(r'^\[([^\]]+)\]').firstMatch(line);
    if (sec != null) {
      section = sec[1]!.trim();
      continue;
    }
    final kv = RegExp(r'^([A-Za-z0-9_]+)\s*=\s*(.*)$').firstMatch(line);
    if (kv == null) continue;
    final value = _tomlValue(kv[2]!);
    switch ((section, kv[1])) {
      case ('wallet', 'check_node_api_http_addr'):
        node = value;
      case ('epicbox', 'epicbox_domain'):
        domain = value;
      case ('epicbox', 'epicbox_port'):
        final p = int.tryParse(value);
        if (p != null && p > 0 && p <= 65535) port = p;
    }
  }
  return _Toml(node: node, epicboxDomain: domain, epicboxPort: port);
}

String _tomlValue(String v) {
  var s = v.trim();
  final q = RegExp(r'''^("([^"\\]|\\.)*"|'[^']*')''').firstMatch(s);
  if (q != null) {
    final body = q[0]!.substring(1, q[0]!.length - 1);
    if (q[0]!.startsWith("'")) return body;
    try {
      return jsonDecode(q[0]!) as String;
    } catch (_) {
      return body;
    }
  }
  final hash = s.indexOf('#');
  if (hash >= 0) s = s.substring(0, hash);
  return s.trim();
}

Future<bool> _samePath(String a, String b) async {
  if (a.isEmpty || b.isEmpty) return false;
  Future<String> canon(String p) async {
    var x = p;
    try {
      x = await Directory(p).resolveSymbolicLinks();
    } catch (_) {/* missing: compare as written */}
    x = x.replaceAll('\\', '/').replaceFirst(RegExp(r'/+$'), '');
    return Platform.isWindows ? x.toLowerCase() : x;
  }

  return await canon(a) == await canon(b);
}

String _join(String a, String b) {
  final sep = Platform.pathSeparator;
  return a.endsWith(sep) || a.endsWith('/') ? '$a$b' : '$a$sep$b';
}

String _name(String p) => p.replaceAll('\\', '/').split('/').last;
