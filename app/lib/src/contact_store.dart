/// The address book every wallet on this device shares: `<app data>/contacts.json`. A contact is
/// a name, at most one address of each kind (Epicbox, Link · HTTP, Link · Tor) and a note. What
/// belongs to one wallet (a pairing, whether a contact is trusted or may send invoices, the
/// payments made) stays in that wallet and points here by the contact's id.
///
/// Protection: plain JSON, as each wallet's `wfe_meta.json` kept contacts before, but readable by
/// the user only (mode 600 on Linux and macOS; the per-user app folder on Windows, Android and
/// iOS). Every change is written atomically (a temp file in the same folder, flushed, renamed
/// over the old one); changes run one at a time per file. A file that does not parse is moved
/// aside, never overwritten; a file of a newer version is read but never rewritten.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'log.dart';
import 'recipient.dart';
import 'wallet_service.dart' show WalletError, WalletErrorKind;

const String contactsFileName = 'contacts.json';

/// The version this app writes. A file with a higher one is read-only.
const int contactsFileVersion = 1;

/// One address book entry as stored.
class ContactFields {
  const ContactFields({this.id = '', required this.name, this.epicbox, this.http, this.tor, this.note, this.invoiceAddress});

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

  /// Their invoice address, where requests to them go; null when not known.
  final String? invoiceAddress;

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
    invoiceAddress: invoiceAddress,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (epicbox != null) 'epicbox': epicbox,
    if (http != null) 'http': http,
    if (tor != null) 'tor': tor,
    if (note != null) 'note': note,
    if (invoiceAddress != null) 'invoice_address': invoiceAddress,
  };

  /// Null for an entry of the wrong shape.
  static ContactFields? fromJson(Object? j) {
    if (j is! Map) return null;
    String? opt(String k) => j[k] is String && (j[k] as String).trim().isNotEmpty ? j[k] as String : null;
    final id = opt('id'), name = opt('name');
    if (id == null || name == null) return null;
    return ContactFields(id: id, name: name, epicbox: opt('epicbox'), http: opt('http'), tor: opt('tor'), note: opt('note'), invoiceAddress: opt('invoice_address'));
  }

  @override
  bool operator ==(Object other) =>
      other is ContactFields &&
      other.id == id &&
      other.name == name &&
      other.epicbox == epicbox &&
      other.http == http &&
      other.tor == tor &&
      other.note == note &&
      other.invoiceAddress == invoiceAddress;

  @override
  int get hashCode => Object.hash(id, name, epicbox, http, tor, note, invoiceAddress);

  @override
  String toString() => 'ContactFields($id, $name, epicbox: $epicbox, http: $http, tor: $tor, note: $note)';
}

WalletError _io(String message) => WalletError(kind: WalletErrorKind.io, message: message);

WalletError _invalid(String message) => WalletError(kind: WalletErrorKind.invalidArgument, message: message);

String _randomHex(int bytes) {
  final r = Random.secure();
  return [for (var i = 0; i < bytes; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
}

/// The shared address book over one file. [open] gives the one store of a folder in this
/// process, so every wallet's session writes through the same queue.
class ContactStore {
  ContactStore._(this.path, this._contacts, {required this.readOnly});

  /// A store that keeps nothing on disk (tests, the demo).
  ContactStore.memory() : path = null, _contacts = [], readOnly = false;

  static final Map<String, Future<ContactStore>> _open = {};

  /// The store of `<dir>/contacts.json`, loaded once per process.
  static Future<ContactStore> open(String dir) {
    final path = File('$dir${Platform.pathSeparator}$contactsFileName').absolute.path;
    return _open[path] ??= _load(path).catchError((Object e) {
      _open.remove(path);
      throw e;
    });
  }

  /// Forgets the loaded stores (tests that delete their folder).
  static void forgetAll() => _open.clear();

  final String? path;
  List<ContactFields> _contacts;

  /// The file was written by a newer version of the app: read, never rewritten.
  final bool readOnly;
  Future<void> _tail = Future.value();

  static Future<ContactStore> _load(String path) async {
    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      try {
        final j = jsonDecode(utf8.decode(bytes));
        if (j is! Map || j['version'] is! int || j['contacts'] is! List) throw const FormatException();
        final list = [
          for (final c in j['contacts'] as List) ?ContactFields.fromJson(c),
        ];
        return ContactStore._(path, list, readOnly: (j['version'] as int) > contactsFileVersion);
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

  /// Every contact, sorted by name.
  List<ContactFields> list() => [..._contacts]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// Adds (empty id) or replaces a contact. Needs a name and an address.
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
    final out = ContactFields(id: c.id.trim(), name: name, epicbox: t(c.epicbox), http: t(c.http), tor: t(c.tor), note: t(c.note), invoiceAddress: t(c.invoiceAddress));
    if (out.addresses.isEmpty) throw _invalid('the contact needs an address');
    return out;
  }

  /// Applies [change] to a copy and persists it; the contacts change only if the write
  /// succeeds. Nothing is written when [change] leaves them as they were.
  Future<R> update<R>(R Function(List<ContactFields> contacts) change) {
    final result = _tail.then((_) => _apply(change));
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<R> _apply<R>(R Function(List<ContactFields> contacts) change) async {
    if (readOnly) throw _io('$path was written by a newer version of the app; update the app to change contacts');
    final next = [..._contacts];
    final out = change(next);
    if (!_sameList(next, _contacts)) {
      final p = path;
      if (p != null) await _write(p, utf8.encode(jsonEncode({'version': contactsFileVersion, 'contacts': [for (final c in next) c.toJson()]})));
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
