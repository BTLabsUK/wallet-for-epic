// SPDX-License-Identifier: Apache-2.0
/// The address book every wallet on this device shares: `<app data>/contacts.json`. A contact is
/// a name, at most one address of each kind (Epicbox, Link · HTTP, Link · Tor) and a note. What
/// belongs to one wallet (a pairing, whether a contact is trusted or may send invoices, the
/// payments made) stays in that wallet and points here by the contact's id.
///
/// Protection: sealed at rest when a wallet opens it ([ContactStore.openSealed]): AES-256-GCM
/// in `contacts.sealed` under a random key each wallet keeps sealed by itself in
/// `contacts.keys/<walletId>.key`. `contacts.json`, the plain book older builds read, stays where
/// it is until a later release retires it; it is never written again. Every file is readable by
/// the user only (mode 600 on Linux and macOS; the per-user app folder on Windows, Android and
/// iOS). Every change is written atomically (a temp file in the same folder, flushed, renamed
/// over the old one); changes run one at a time per file. A file that does not parse is moved
/// aside, never overwritten; a file of a newer version is read but never rewritten.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart' show visibleForTesting;

import 'log.dart';
import 'recipient.dart';
import 'sealed_file.dart';
import 'wallet_service.dart' show WalletError, WalletErrorKind;

const String contactsFileName = 'contacts.json';

/// The version this app writes. A file with a higher one is read-only.
const int contactsFileVersion = 1;

/// One address book entry as stored.
class ContactFields {
  const ContactFields({this.id = '', required this.name, this.epicbox, this.http, this.tor, this.note});

  /// Empty for a contact not saved yet.
  final String id;
  final String name;

  /// `<key>@<relay>`.
  final String? epicbox;

  /// The wallet URL.
  final String? http;

  /// `<56 characters>.onion`, lower case.
  final String? tor;
  final String? note;


  String? of(RecipientKind kind) => switch (kind) {
    RecipientKind.epicbox => epicbox,
    RecipientKind.http => http,
    RecipientKind.tor => tor,
  };

  List<String> get addresses => [?epicbox, ?http, ?tor];

  ContactFields copyWith({String? id, String? epicbox, String? http, String? tor, String? note}) => ContactFields(
    id: id ?? this.id,
    name: name,
    epicbox: epicbox ?? this.epicbox,
    http: http ?? this.http,
    tor: tor ?? this.tor,
    note: note ?? this.note,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (epicbox != null) 'epicbox': epicbox,
    if (http != null) 'http': http,
    if (tor != null) 'tor': tor,
    if (note != null) 'note': note,
  };

  /// Null for an entry of the wrong shape.
  static ContactFields? fromJson(Object? j) {
    if (j is! Map) return null;
    String? opt(String k) => j[k] is String && (j[k] as String).trim().isNotEmpty ? j[k] as String : null;
    final id = opt('id'), name = opt('name');
    if (id == null || name == null) return null;
    return ContactFields(id: id, name: name, epicbox: opt('epicbox'), http: opt('http'), tor: opt('tor'), note: opt('note'));
  }

  @override
  bool operator ==(Object other) =>
      other is ContactFields &&
      other.id == id &&
      other.name == name &&
      other.epicbox == epicbox &&
      other.http == http &&
      other.tor == tor &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, name, epicbox, http, tor, note);

  @override
  String toString() => 'ContactFields($id, $name, epicbox: $epicbox, http: $http, tor: $tor, note: $note)';
}

WalletError _io(String message) => WalletError(kind: WalletErrorKind.io, message: message);

WalletError _invalid(String message) => WalletError(kind: WalletErrorKind.invalidArgument, message: message);

String _randomHex(int bytes) {
  final r = Random.secure();
  return [for (var i = 0; i < bytes; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
}

/// The sealed book beside the plain one, and the folder of its key's wraps.
const String contactsSealedFileName = 'contacts.sealed';
const String contactsKeysDirName = 'contacts.keys';

/// The OS lock on the sealed book: held by the one app process that has the book open, so a
/// second process (another instance, where the system lets one start) never seals, merges or
/// writes it at the same time. Never deleted: two openers must lock the same file.
const String contactsLockFileName = 'contacts.lock';

/// The sealed book's format version: in its header and in the AES-GCM associated data.
const int contactsSealedVersion = 1;

const List<int> _sealedMagic = [0x57, 0x46, 0x45, 0x43]; // "WFEC"
const String _sealedAadLabel = 'wfe-contacts/1';

/// The header's wallet id of the shared book, which no one wallet owns.
const String _sharedBookId = 'shared';

/// Associated data of the sealed book: `"wfe-contacts/1"` then the version byte, so a file of
/// another kind or version sealed under the same key never opens as this one.
List<int> _sealedAad(int version) => [...utf8.encode(_sealedAadLabel), version];

final AesGcm _aes = AesGcm.with256bits();

/// The book sealed under [key]: `WFEC`, the version byte, the 12-byte nonce, the text, the
/// 16-byte tag.
Future<Uint8List> sealContactsBook(List<int> key, Uint8List payload) async {
  final box = await _aes.encrypt(
    payload,
    secretKey: SecretKey(key),
    nonce: _aes.newNonce(),
    aad: _sealedAad(contactsSealedVersion),
  );
  return Uint8List.fromList([..._sealedMagic, contactsSealedVersion, ...box.nonce, ...box.cipherText, ...box.mac.bytes]);
}

/// Opens a book from [sealContactsBook]. Throws [SealedOpenError]: `notOurs` for anything else,
/// `newer` for a later version, `damaged` when the key or the text does not match.
Future<Uint8List> openContactsBook(List<int> key, Uint8List file) async {
  const head = 4 + 1 + 12, tag = 16;
  if (file.length < head + tag || !_sealedMagic.indexed.every((e) => file[e.$1] == e.$2)) {
    throw const SealedOpenError(SealedOpenProblem.notOurs);
  }
  final version = file[4];
  if (version > contactsSealedVersion) throw const SealedOpenError(SealedOpenProblem.newer);
  try {
    return Uint8List.fromList(
      await _aes.decrypt(
        SecretBox(file.sublist(head, file.length - tag), nonce: file.sublist(5, head), mac: Mac(file.sublist(file.length - tag))),
        secretKey: SecretKey(key),
        aad: _sealedAad(version),
      ),
    );
  } on SecretBoxAuthenticationError {
    throw const SealedOpenError(SealedOpenProblem.damaged);
  }
}

/// Adds to [into] the contacts of [plain] whose id it lacks: a plain `contacts.json` an older
/// build changed after the book was sealed. Only adds; the sealed side wins a shared id.
bool mergePlainContacts(List<ContactFields> into, Iterable<ContactFields> plain) {
  var added = false;
  for (final c in plain) {
    if (into.any((e) => e.id == c.id)) continue;
    into.add(c);
    added = true;
  }
  return added;
}

/// The shared address book over one file. [open] gives the one store of a folder in this
/// process, so every wallet's session writes through the same queue.
///
/// Sealed ([openSealed], every LEPIC session): the book is `contacts.sealed`, AES-256-GCM under
/// a random content key, and each wallet keeps that key sealed by itself in
/// `contacts.keys/<walletId>.key`. A wallet's unlock tries every wrap; any one that opens opens
/// the book, and then every open wallet without a wrap gets one. A wallet that opens none while
/// a book exists finds the book closed ([available] false): it reads no contacts and writes
/// nothing until a wallet with a wrap opens. The key is held in memory only while a wallet
/// that is attached is open. `contacts.json` is only read: sealed on the first unlock, left
/// where it is, and merged in again (adding only) when its size or hash changed since.
class ContactStore {
  ContactStore._(this.path, this._contacts, {required this._readOnly}) : _dir = null;

  ContactStore._sealed(String dir)
    : _dir = dir,
      path = File('$dir${Platform.pathSeparator}$contactsFileName').absolute.path,
      _contacts = [],
      _readOnly = false;

  /// A store that keeps nothing on disk (tests, the web preview).
  ContactStore.memory() : path = null, _contacts = [], _readOnly = false, _dir = null;

  static final Map<String, Future<ContactStore>> _open = {};
  static final Map<String, ContactStore> _sealedOpen = {};

  /// The store of `<dir>/contacts.json`, loaded once per process.
  static Future<ContactStore> open(String dir) {
    final path = File('$dir${Platform.pathSeparator}$contactsFileName').absolute.path;
    return _open[path] ??= _load(path).catchError((Object e) {
      _open.remove(path);
      throw e;
    });
  }

  /// The sealed book of [dir], one per folder in this process, with the wallet [walletId]
  /// (sealing with [sealer]) attached until [detach].
  static Future<ContactStore> openSealed(String dir, String walletId, AppDataSealer sealer) async {
    if (!sealedWalletIdPattern.hasMatch(walletId)) throw _invalid('not a wallet id');
    final key = Directory(dir).absolute.path;
    final store = _sealedOpen[key] ??= ContactStore._sealed(key);
    await store._queue(() async {
      try {
        await store._attach(walletId, sealer);
      } on Object {
        store._wallets.remove(walletId);
        if (store._wallets.isEmpty) store._lock();
        rethrow;
      }
    });
    return store;
  }

  /// Removes the wrap of [walletId] from the book of [dir] (the wallet was deleted). When no
  /// wrap is left the book can never open again: it goes too. `contacts.json` stays.
  static Future<void> removeWalletKey(String dir, String walletId) async {
    if (!sealedWalletIdPattern.hasMatch(walletId)) throw _invalid('not a wallet id');
    final abs = Directory(dir).absolute.path;
    final store = _sealedOpen[abs] ??= ContactStore._sealed(abs);
    await store._queue(() async {
      store._wallets.remove(walletId);
      final claimed = await store._takeClaim();
      try {
        final wrap = store._wrapPath(walletId);
        await _deleteIfThere(wrap);
        await _deleteIfThere(SealedFile.tmpOf(wrap));
        // The book itself only under the lock: another process may be adding a wrap.
        if (claimed && (await store._wraps()).isEmpty) {
          await _deleteIfThere(store._sealedPath);
          await _deleteIfThere(SealedFile.tmpOf(store._sealedPath));
          store._lock();
        }
      } finally {
        if (store._wallets.isEmpty) store._lock();
      }
    });
  }

  /// Forgets the loaded stores (tests that delete their folder).
  static void forgetAll() {
    _open.clear();
    for (final s in _sealedOpen.values) {
      s._release();
    }
    _sealedOpen.clear();
  }

  /// How long an unlock waits for another process to let go of the book before it leaves the
  /// book closed for this session.
  @visibleForTesting
  static Duration claimWait = const Duration(seconds: 3);

  /// This process's lock on [contactsLockFileName], while the book is in use here.
  RandomAccessFile? _claim;

  String get _claimPath => '$_dir${Platform.pathSeparator}$contactsLockFileName';

  /// Takes the book's OS lock, waiting up to [claimWait] for another process to release it.
  /// False when it stays held there.
  Future<bool> _takeClaim() async {
    if (_claim != null) return true;
    final RandomAccessFile file;
    try {
      await Directory(_dir!).create(recursive: true);
      file = await File(_claimPath).open(mode: FileMode.append);
    } on FileSystemException catch (e) {
      throw _io('opening $_claimPath: ${e.message}');
    }
    final until = DateTime.now().add(claimWait);
    while (true) {
      try {
        await file.lock(FileLock.exclusive);
        _claim = file;
        return true;
      } on FileSystemException {
        if (DateTime.now().isAfter(until)) {
          await file.close();
          return false;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// Lets another process have the book.
  void _release() {
    final c = _claim;
    _claim = null;
    if (c == null) return;
    try {
      c.closeSync();
    } on FileSystemException {
      // Closed with the process at the latest.
    }
  }

  /// `contacts.json`; null for [ContactStore.memory].
  final String? path;
  List<ContactFields> _contacts;

  /// The folder of a sealed book; null for a plain one.
  final String? _dir;

  /// The content key of an open sealed book, in memory only while a wallet is attached.
  Uint8List? _key;
  bool _loaded = false;

  /// The plain file as it was when last sealed or merged.
  PlainRecord? _plain;

  /// The wallets attached to a sealed book, by id.
  final Map<String, AppDataSealer> _wallets = {};

  /// The file was written by a newer version of the app: read, never rewritten.
  bool get readOnly => _readOnly;
  bool _readOnly;
  Future<void> _tail = Future.value();

  bool get sealed => _dir != null;

  /// False for a sealed book none of the open wallets has a key to: its contacts are not shown
  /// (not "none") and nothing is written.
  bool get available => !sealed || _loaded;

  String get _sealedPath => '$_dir${Platform.pathSeparator}$contactsSealedFileName';
  String get _keysDir => '$_dir${Platform.pathSeparator}$contactsKeysDirName';
  String _wrapPath(String walletId) => '$_keysDir${Platform.pathSeparator}$walletId.key';

  static Future<ContactStore> _load(String path) async {
    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      try {
        final list = _parse(bytes);
        return ContactStore._(path, list.contacts, readOnly: list.version > contactsFileVersion);
      } on FormatException {
        // Never the exception's text: it quotes the file, which holds names and addresses.
        final aside = '$path.corrupt-${DateTime.now().millisecondsSinceEpoch}';
        logWarn('contacts', '$contactsFileName is unreadable; moved aside');
        try {
          await file.rename(aside);
        } on FileSystemException catch (e) {
          throw _io('moving $path: ${e.message}');
        }
      }
    } on PathNotFoundException {
      // No contacts yet.
    } on FileSystemException catch (e) {
      throw _io('reading $path: ${e.message}');
    }
    return ContactStore._(path, [], readOnly: false);
  }

  /// `{"version", "contacts"}` as `contacts.json` holds it; throws [FormatException].
  static ({int version, List<ContactFields> contacts}) _parse(List<int> bytes) {
    final j = jsonDecode(utf8.decode(bytes));
    if (j is! Map || j['version'] is! int || j['contacts'] is! List) throw const FormatException();
    return (version: j['version'] as int, contacts: [for (final c in j['contacts'] as List) ?ContactFields.fromJson(c)]);
  }

  static Uint8List _encode(List<ContactFields> list) =>
      utf8.encode(jsonEncode({'version': contactsFileVersion, 'contacts': [for (final c in list) c.toJson()]}));

  static Future<void> _deleteIfThere(String path) async {
    try {
      await File(path).delete();
    } on PathNotFoundException {
      // None.
    } on FileSystemException catch (e) {
      throw _io('deleting $path: ${e.message}');
    }
  }

  Future<R> _queue<R>(Future<R> Function() job) {
    final result = _tail.then((_) => job());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Ends [walletId]'s use of the book. With no wallet left attached the key and the contacts
  /// leave memory.
  /// A wallet opened again (a server switch) attaches its new session first: the old one's
  /// [sealer] then no longer counts and its detach changes nothing.
  Future<void> detach(String walletId, AppDataSealer sealer) => _queue(() async {
    if (!identical(_wallets[walletId], sealer)) return;
    _wallets.remove(walletId);
    if (_wallets.isEmpty) _lock();
  });

  void _lock() {
    _release();
    final k = _key;
    if (k != null) k.fillRange(0, k.length, 0);
    _key = null;
    _loaded = false;
    _contacts = [];
    _plain = null;
    _readOnly = false;
  }

  /// The wrap files on disk, by wallet id.
  Future<List<String>> _wraps() async {
    final ids = <String>[];
    try {
      await for (final e in Directory(_keysDir).list()) {
        final name = e.uri.pathSegments.last;
        if (e is! File || !name.endsWith('.key')) continue;
        final id = name.substring(0, name.length - '.key'.length);
        if (sealedWalletIdPattern.hasMatch(id)) ids.add(id);
      }
    } on PathNotFoundException {
      // No wraps yet.
    } on FileSystemException catch (e) {
      throw _io('listing $_keysDir: ${e.message}');
    }
    return ids..sort();
  }

  /// The content key in the wrap of [id], if [sealer] opens it.
  Future<Uint8List?> _openWrap(String id, AppDataSealer sealer) async {
    try {
      final p = await SealedFile.readSealed(_wrapPath(id), sealer, kind: sealedKindContactsKey, walletId: id);
      if (p == null) return null;
      final key = base64.decode(utf8.decode(p.body));
      return key.length == 32 ? key : null;
    } on SealedOpenError catch (e) {
      // Another wallet's wrap is the usual case; a damaged one is worth a line.
      if (e.problem != SealedOpenProblem.foreign) logWarn('contacts', 'a key of the address book does not open (${e.problem.name})');
      return null;
    } on FormatException {
      logWarn('contacts', 'a key of the address book holds no key');
      return null;
    } on FileSystemException catch (e) {
      throw _io('reading ${_wrapPath(id)}: ${e.message}');
    }
  }

  Future<void> _writeWrap(String id, AppDataSealer sealer, Uint8List key) async {
    try {
      await SealedFile.writeSealed(
        _wrapPath(id),
        sealer,
        SealedPayload(kind: sealedKindContactsKey, walletId: id, body: utf8.encode(base64.encode(key))),
      );
    } on FileSystemException catch (e) {
      throw _io('writing ${_wrapPath(id)}: ${e.message}');
    } on SealedOpenError catch (e) {
      throw _io('writing ${_wrapPath(id)}: the sealed copy did not open (${e.problem.name})');
    }
  }

  /// Attaches [walletId] and opens the book if it can. Each step leaves a state the next unlock
  /// completes, and `contacts.json` is never written:
  /// 1. a `.tmp` beside the book is a write a crash cut short: deleted;
  /// 2. every wrap is tried, this wallet's first; one that opens gives the key;
  /// 3. none opens and there are no wraps at all (a first unlock, or a book whose last wrap
  ///    went): a book left without wraps is deleted (no one can open it), a new key is made and
  ///    this wallet's wrap written before anything is sealed under it;
  /// 4. none opens but other wallets have wraps: the book stays closed for now;
  /// 5. with the key, the book is opened or, when there is none, sealed from `contacts.json`
  ///    copy-then-switch; a `contacts.json` changed since is merged in (adding only);
  /// 6. every attached wallet without a wrap gets one.
  Future<void> _attach(String walletId, AppDataSealer sealer) async {
    _wallets[walletId] = sealer;
    // Another process has the book open: closed here for this session, nothing read or written.
    if (!await _takeClaim()) {
      logWarn('contacts', 'the address book is open in another instance of the app; closed here');
      return;
    }
    if (_key == null) {
      try {
        await SealedFile.dropTmp(_sealedPath);
      } on FileSystemException catch (e) {
        throw _io('deleting ${SealedFile.tmpOf(_sealedPath)}: ${e.message}');
      }
      final wraps = await _wraps();
      final order = [if (wraps.contains(walletId)) walletId, ...wraps.where((w) => w != walletId)];
      Uint8List? key;
      for (final id in order) {
        key = await _openWrap(id, sealer);
        if (key != null) break;
      }
      if (key == null && wraps.isEmpty) {
        await _deleteIfThere(_sealedPath);
        final r = Random.secure();
        key = Uint8List.fromList([for (var i = 0; i < 32; i++) r.nextInt(256)]);
        await _writeWrap(walletId, sealer, key);
        logInfo('contacts', 'address book key made');
      }
      if (key == null) {
        logWarn('contacts', 'the address book stays closed until a wallet with its key opens');
        return;
      }
      _key = key;
    }
    if (!_loaded) await _loadBook();
    if (!_loaded) return;
    final wraps = (await _wraps()).toSet();
    for (final e in _wallets.entries) {
      if (wraps.contains(e.key)) continue;
      await _writeWrap(e.key, e.value, _key!);
      logInfo('contacts', 'address book key added for a wallet');
    }
  }

  /// Opens the sealed book with [_key], or seals it from `contacts.json` when there is none.
  Future<void> _loadBook() async {
    final key = _key!;
    final plainRec = await PlainRecord.ofFile(path!);
    final Uint8List? file;
    try {
      file = await SealedFile.read(_sealedPath);
    } on FileSystemException catch (e) {
      throw _io('reading $_sealedPath: ${e.message}');
    }
    if (file == null) {
      final plain = plainRec == null ? null : await _readPlainList();
      final list = plain ?? <ContactFields>[];
      _contacts = list;
      _loaded = true;
      try {
        await _writeBook(list, plainRec);
        logInfo('contacts', plainRec == null ? 'address book started' : '$contactsFileName sealed');
      } on WalletError {
        // Disk full or the like: this session keeps the list in memory, and the next change or
        // the next unlock seals it. The plain file is still there.
        _plain = plainRec;
        logWarn('contacts', '$contactsFileName could not be sealed yet');
      }
      return;
    }
    final SealedPayload payload;
    final ({int version, List<ContactFields> contacts}) book;
    try {
      payload = SealedPayload.decode(await openContactsBook(key, file), kind: sealedKindContacts, walletId: _sharedBookId);
      book = _parse(payload.body);
    } on SealedOpenError catch (e) {
      // Never set aside or overwritten: a key that does not match must not cost the book.
      logWarn('contacts', 'the address book does not open (${e.problem.name}); kept closed');
      return;
    } on FormatException {
      logWarn('contacts', 'the address book holds no contacts list; kept closed');
      return;
    }
    _contacts = book.contacts;
    _plain = payload.plain;
    _readOnly = payload.version > sealedHeaderVersion || book.version > contactsFileVersion;
    _loaded = true;
    if (plainRec != null && plainRec != payload.plain && !_readOnly) {
      final next = [..._contacts];
      mergePlainContacts(next, await _readPlainList() ?? const []);
      try {
        await _writeBook(next, plainRec);
        _contacts = next;
        logInfo('contacts', '$contactsFileName changed since it was sealed; merged in');
      } on WalletError {
        logWarn('contacts', '$contactsFileName changed since it was sealed; not merged yet');
      }
    }
  }

  /// `contacts.json`'s list, left as it is: empty for one that does not parse.
  Future<List<ContactFields>?> _readPlainList() async {
    try {
      return _parse(await File(path!).readAsBytes()).contacts;
    } on PathNotFoundException {
      return null;
    } on FormatException {
      logWarn('contacts', '$contactsFileName is unreadable; not merged');
      return const [];
    } on FileSystemException catch (e) {
      throw _io('reading $path: ${e.message}');
    }
  }

  /// Seals [list] with the record [plain] into the book, copy-then-switch.
  Future<void> _writeBook(List<ContactFields> list, PlainRecord? plain) async {
    final key = _key!;
    final payload = SealedPayload(kind: sealedKindContacts, walletId: _sharedBookId, plain: plain, body: _encode(list)).encode();
    try {
      await SealedFile.write(
        _sealedPath,
        await sealContactsBook(key, payload),
        verify: (onDisk) async {
          final back = await openContactsBook(key, onDisk);
          if (base64.encode(back) != base64.encode(payload)) throw FileSystemException('the sealed copy differs', _sealedPath);
        },
      );
    } on FileSystemException catch (e) {
      throw _io('writing $_sealedPath: ${e.message}');
    } on SealedOpenError catch (e) {
      throw _io('writing $_sealedPath: the sealed copy did not open (${e.problem.name})');
    }
    _plain = plain;
  }

  /// Every contact, sorted by name. None while the book is closed ([available]).
  List<ContactFields> list() => [..._contacts]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// Adds (empty id) or replaces a contact. Needs a name; a contact without an address is one
  /// a pairing pays (RFC 0002: the pairing's mailbox is never shown as an address).
  Future<ContactFields> save(ContactFields contact) async {
    final c = _clean(contact);
    final saved = c.id.isEmpty ? c.copyWith(id: _randomHex(16)) : c;
    await update((list) {
      final i = list.indexWhere((e) => e.id == saved.id);
      if (i >= 0) {
        list[i] = saved;
      } else if (c.id.isEmpty) {
        list.add(saved);
      } else {
        throw _invalid('no contact with id ${saved.id}');
      }
    });
    return saved;
  }

  Future<void> delete(String id) => update((list) => list.removeWhere((c) => c.id == id));

  /// Adds [add] (new ids given) and replaces [replace] (by id; one that is gone is left out), in
  /// one write. Returns the added contacts with their ids.
  Future<List<ContactFields>> saveAll({Iterable<ContactFields> add = const [], Iterable<ContactFields> replace = const []}) async {
    final added = [for (final c in add) _clean(c).copyWith(id: _randomHex(16))];
    final changed = [for (final c in replace) _clean(c)];
    await update((list) {
      for (final c in changed) {
        final i = list.indexWhere((e) => e.id == c.id);
        if (i >= 0) list[i] = c;
      }
      list.addAll(added);
    });
    return added;
  }

  static ContactFields _clean(ContactFields c) {
    String? t(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
    final name = t(c.name);
    if (name == null) throw _invalid('the contact needs a name');
    return ContactFields(id: c.id.trim(), name: name, epicbox: t(c.epicbox), http: t(c.http), tor: t(c.tor), note: t(c.note));
  }

  /// Applies [change] to a copy and persists it; the contacts change only if the write
  /// succeeds. Nothing is written when [change] leaves them as they were.
  Future<R> update<R>(R Function(List<ContactFields> contacts) change) => _queue(() => _apply(change));

  Future<R> _apply<R>(R Function(List<ContactFields> contacts) change) async {
    if (!available) throw _io('the address book is closed until a wallet with its key is open');
    if (readOnly) throw _io('$path was written by a newer version of the app; update the app to change contacts');
    final next = [..._contacts];
    final out = change(next);
    if (!_sameList(next, _contacts)) {
      final p = path;
      if (sealed) {
        await _writeBook(next, _plain);
      } else if (p != null) {
        await _write(p, _encode(next));
      }
      _contacts = next;
    }
    return out;
  }

  static bool _sameList(List<ContactFields> a, List<ContactFields> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Writes [bytes] so a crash leaves the old file or the new one, readable by the user only.
  static Future<void> _write(String path, List<int> bytes) async {
    final file = File(path);
    final tmp = File('$path.tmp');
    try {
      await file.parent.create(recursive: true);
      await tmp.writeAsBytes(bytes, flush: true);
      if (Platform.isLinux || Platform.isMacOS) {
        final r = await Process.run('chmod', ['600', tmp.path]);
        if (r.exitCode != 0) throw FileSystemException('chmod failed', tmp.path);
      }
      await tmp.rename(path);
    } on FileSystemException catch (e) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } on FileSystemException {
        // Left for the next write to replace.
      }
      throw _io('writing $path: ${e.message}');
    }
  }
}
