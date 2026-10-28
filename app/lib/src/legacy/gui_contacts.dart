// SPDX-License-Identifier: Apache-2.0
/// How an old Epic GUI's address book comes into the app's contacts: each GUI contact cleaned,
/// its addresses read by what they are (not by the field they were typed in), and then added,
/// merged into a saved contact, or skipped, never overwriting what the user saved. Pure Dart: the
/// caller reads the GUI (legacy_gui_profile.dart), passes the saved contacts and the address
/// checks, and saves what [planGuiContacts] returns.
///
/// The GUI's Addressbook row (every version from 5.0 to 6.1.6, idbService.js): `name`,
/// `externalOne` (labelled "Epicbox Address"), `externalTwo` ("External Address": an HTTP(S)
/// address, sometimes another Epicbox or Tor address), `onion` (a Tor address; hidden since
/// 6.1), `notice` (the note), and fields with no place here: `keybase`, `proofaddr`,
/// `alwaysproof`, `gender`, `country`, `city` (6.1.6 hides them too).
library;

import '../contact_store.dart';
import '../recipient.dart';
import 'gui_rules.dart' show guiDefaultEpicbox;

/// A contact name: at most this many characters (code points).
const int guiContactNameMax = 64;

/// A contact note: at most this many characters (code points).
const int guiContactNoteMax = 1000;

/// One GUI contact as read: its fields as typed, untrusted.
class GuiContactRow {
  const GuiContactRow({required this.name, this.externalOne, this.externalTwo, this.onion, this.note});

  final String name;
  final String? externalOne;
  final String? externalTwo;
  final String? onion;
  final String? note;
}

/// The address checks of the wallet (LEPIC's checksums), passed in so this file stays pure.
class AddressChecks {
  const AddressChecks({required this.epicbox, required this.onion, this.http = httpAddressComplete});

  /// A whole `<key>@<relay>` Epicbox address.
  final bool Function(String address) epicbox;

  /// A `<56 characters>.onion` address.
  final bool Function(String address) onion;
  final bool Function(String url) http;
}

/// What the import does: [add] new contacts, [update] saved ones (by id) with the addresses or
/// note they lacked, and the counts the wizard shows.
class GuiContactPlan {
  GuiContactPlan();

  final List<ContactFields> add = [];
  final List<ContactFields> update = [];

  /// Old contacts that matched a saved contact and gave it an address or note it lacked.
  int merged = 0;

  /// Old contacts already saved, with nothing to add.
  int alreadySaved = 0;

  /// Old contacts with no address the app can send to (empty, or none valid).
  int skippedNoAddress = 0;

  /// Valid addresses not saved: the contact already has a different one of that kind, or the
  /// address belongs to another saved contact.
  int addressesLeftOut = 0;

  /// Every address the import adds to a contact already saved, by kind: the confirm lists each
  /// one, as a file can name a saved contact's public Epicbox address and add an address of its
  /// author's own.
  final List<({String name, RecipientKind kind, String address})> addedToSaved = [];

  int get added => add.length;
}

/// A GUI contact's addresses, by kind, as the app keeps them. [epicboxDomain] (and a port other
/// than 443) completes a bare Epicbox key, as the epic wallet did with its own domain when it
/// sent to one. The first valid address of a kind wins; [extra] counts the other valid ones.
({Map<RecipientKind, String> byKind, int extra}) guiContactAddresses(
  GuiContactRow row,
  AddressChecks checks, {
  String? epicboxDomain,
  int? epicboxPort,
}) {
  final byKind = <RecipientKind, String>{};
  var extra = 0;
  for (final raw in [row.externalOne, row.externalTwo, row.onion]) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) continue;
    final a = _address(text, checks, epicboxDomain: epicboxDomain, epicboxPort: epicboxPort);
    if (a == null) continue;
    final have = byKind[a.kind];
    if (have == null) {
      byKind[a.kind] = a.address;
    } else if (!_same(a.kind, have, a.address)) {
      extra++;
    }
  }
  return (byKind: byKind, extra: extra);
}

/// [text] as an address of its kind, or null when it is none the wallet would send to.
Recipient? _address(String text, AddressChecks checks, {String? epicboxDomain, int? epicboxPort}) {
  // A Tor address older versions kept without `.onion`: parseRecipient reads it as an onion.
  final r = parseRecipient(text);
  switch (r.kind) {
    case RecipientKind.tor:
      return checks.onion(r.address) ? r : null;
    case RecipientKind.http:
      return checks.http(r.address) ? r : null;
    case RecipientKind.epicbox:
      var a = r.address;
      if (!a.contains('@')) {
        final domain = (epicboxDomain ?? '').trim().isEmpty ? guiDefaultEpicbox : epicboxDomain!.trim().toLowerCase();
        final port = epicboxPort == null || epicboxPort == 443 ? '' : ':$epicboxPort';
        a = '$a@$domain$port';
      }
      return checks.epicbox(a) ? Recipient(RecipientKind.epicbox, a) : null;
  }
}

/// Two addresses of [kind] reach the same wallet: an Epicbox key at any relay, an onion in any
/// case, a URL without a trailing slash.
bool _same(RecipientKind kind, String a, String b) => _key(kind, a) == _key(kind, b);

String _key(RecipientKind kind, String a) => switch (kind) {
  RecipientKind.epicbox => a.trim().split('@').first,
  RecipientKind.tor => a.trim().toLowerCase(),
  RecipientKind.http => a.trim().replaceFirst(RegExp(r'/+$'), '').toLowerCase(),
};

/// A contact name from another app: control, zero-width, line-separator and bidi characters
/// dropped, whitespace runs folded, trimmed, at most [guiContactNameMax] characters.
String cleanContactName(String? text) => _cut(_line(text ?? ''), guiContactNameMax);

/// A note from another app: the same, but line breaks kept (at most two in a row).
String cleanContactNote(String? text) {
  final lines = (text ?? '').replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n').map(_line).toList();
  final joined = lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  return _cut(joined, guiContactNoteMax);
}

String _line(String s) => s
    .replaceAll(RegExp('[\u0000-\u0009\u000b-\u001f\u007f-\u009f\u2028\u2029]'), ' ')
    .replaceAll(RegExp('[\u00ad\u061c\u180e\u200b-\u200f\u202a-\u202e\u2060-\u2064\u2066-\u2069\ufeff]'), '')
    .replaceAll(RegExp('[ \t\u00a0\u3000]+'), ' ')
    .trim();

String _cut(String s, int max) {
  final runes = s.runes.toList();
  return runes.length <= max ? s : String.fromCharCodes(runes.sublist(0, max)).trim();
}

/// Plans the import of [rows] into [saved]. An old contact matches a saved one (or one added
/// earlier in this run) that has any of its addresses, an Epicbox address by its key at any
/// relay. A match gains the kinds it lacks and a note when it had none; its name, its addresses
/// and its note are never changed. An address already saved on another contact is left out, so
/// no address ends up on two contacts. A contact with no name is named by its first address.
GuiContactPlan planGuiContacts(
  Iterable<GuiContactRow> rows,
  Iterable<ContactFields> saved,
  AddressChecks checks, {
  String? epicboxDomain,
  int? epicboxPort,
}) {
  final plan = GuiContactPlan();
  // Saved contacts and those this run adds ([_Entry.added] = its index in plan.add).
  final book = [for (final c in saved) _Entry(c)];
  for (final row in rows) {
    final found = guiContactAddresses(row, checks, epicboxDomain: epicboxDomain, epicboxPort: epicboxPort);
    if (found.byKind.isEmpty) {
      plan.skippedNoAddress++;
      continue;
    }
    plan.addressesLeftOut += found.extra;
    final note = cleanContactNote(row.note);

    int owner(RecipientKind kind, String address) =>
        book.indexWhere((e) => e.c.of(kind) != null && _same(kind, e.c.of(kind)!, address));
    // The first contact holding any of the addresses, in kind order.
    var match = -1;
    for (final e in found.byKind.entries) {
      match = owner(e.key, e.value);
      if (match >= 0) break;
    }

    if (match < 0) {
      final byKind = found.byKind;
      final name = cleanContactName(row.name);
      final first = byKind[RecipientKind.epicbox] ?? byKind[RecipientKind.http] ?? byKind[RecipientKind.tor]!;
      final c = ContactFields(
        name: name.isEmpty ? _cut(first, guiContactNameMax) : name,
        epicbox: byKind[RecipientKind.epicbox],
        http: byKind[RecipientKind.http],
        tor: byKind[RecipientKind.tor],
        note: note.isEmpty ? null : note,
      );
      book.add(_Entry(c, added: plan.add.length));
      plan.add.add(c);
      continue;
    }

    final entry = book[match];
    var c = entry.c;
    var changed = false;
    for (final e in found.byKind.entries) {
      final have = c.of(e.key);
      if (have != null) {
        if (!_same(e.key, have, e.value)) plan.addressesLeftOut++;
        continue;
      }
      final elsewhere = owner(e.key, e.value);
      if (elsewhere >= 0 && elsewhere != match) {
        plan.addressesLeftOut++;
        continue;
      }
      c = switch (e.key) {
        RecipientKind.epicbox => c.copyWith(epicbox: e.value),
        RecipientKind.http => c.copyWith(http: e.value),
        RecipientKind.tor => c.copyWith(tor: e.value),
      };
      if (entry.added == null) plan.addedToSaved.add((name: c.name, kind: e.key, address: e.value));
      changed = true;
    }
    if (note.isNotEmpty && (c.note ?? '').trim().isEmpty) {
      c = c.copyWith(note: note);
      changed = true;
    }
    if (!changed) {
      plan.alreadySaved++;
      continue;
    }
    plan.merged++;
    entry.c = c;
    final added = entry.added;
    if (added != null) {
      plan.add[added] = c;
    } else if (entry.updated != null) {
      plan.update[entry.updated!] = c;
    } else {
      entry.updated = plan.update.length;
      plan.update.add(c);
    }
  }
  return plan;
}

/// A contact of the book while planning: a saved one, or one this run adds.
class _Entry {
  _Entry(this.c, {this.added});

  ContactFields c;

  /// Its index in [GuiContactPlan.add], for one this run adds.
  final int? added;

  /// Its index in [GuiContactPlan.update], once a saved one changed.
  int? updated;
}
