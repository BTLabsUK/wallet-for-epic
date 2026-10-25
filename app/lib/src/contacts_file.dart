/// Export and Import contacts: the shared address book as a small JSON file, on the phone and
/// the desktop. The file holds names, at most one address per kind and notes; never a pairing,
/// trust, a star, a picture or anything else of one wallet. Import plans through the GUI
/// import's rules (`legacy/gui_contacts.dart` [planGuiContacts]): nothing saved is changed, a
/// match only gains the kinds and the note it lacks, an Epicbox key at any relay is the same
/// contact. Pure Dart: the screens pick and save the file and pass the address checks.
///
/// ```json
/// { "format": "epic-cash-contacts", "version": 1, "network": "mainnet",
///   "exported": "2026-10-25T14:02:11Z",
///   "contacts": [ { "name": "Anna", "epicbox": "es…@epicbox.epiccash.com", "note": "Flatmate" } ] }
/// ```
///
/// A device's own `contacts.json` imports too (no marker, same keys). The file is untrusted:
/// at most [maxContactsFileBytes], unknown fields ignored, names and notes cleaned and capped,
/// every address checked as the contact form checks it.
library;

import 'dart:convert';

import 'contact_store.dart' show ContactFields;
import 'l10n.dart';
import 'legacy/gui_contacts.dart';
import 'recipient.dart';

/// The file's marker.
const String contactsFileFormat = 'epic-cash-contacts';

/// The version this app writes; a file of a higher one is refused.
const int contactsExportVersion = 1;

/// A contacts file is a few kilobytes; anything far larger is not one.
const int maxContactsFileBytes = 1 << 20;

/// An address longer than this is none the wallet sends to (an onion URL is under 100).
const int _addressMax = 512;

/// `epic-cash-contacts-<yyyy-mm-dd>.json`, dated [day] in local time.
String contactsExportFileName(DateTime day) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'epic-cash-contacts-${day.year}-${two(day.month)}-${two(day.day)}.json';
}

/// The contacts an export writes: those with an address. A contact without one is the contact
/// of a pairing, and the file carries no pairing.
List<ContactFields> exportableContacts(Iterable<ContactFields> contacts) => [
  for (final c in contacts)
    if (c.addresses.isNotEmpty) c,
];

/// The file for [contacts] ([exportableContacts] of them) of a wallet on [network], made at
/// [now]. No ids: they belong to this device.
String encodeContactsFile(Iterable<ContactFields> contacts, {required String network, required DateTime now}) {
  final out = {
    'format': contactsFileFormat,
    'version': contactsExportVersion,
    'network': network,
    'exported': '${now.toUtc().toIso8601String().split('.').first}Z',
    'contacts': [
      for (final c in exportableContacts(contacts))
        {
          'name': c.name,
          if (c.epicbox != null) 'epicbox': c.epicbox,
          if (c.http != null) 'http': c.http,
          if (c.tor != null) 'tor': c.tor,
          if (c.note != null) 'note': c.note,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(out);
}

/// Why a file was refused.
enum ContactsFileProblem {
  /// Not JSON, or JSON of another kind.
  notFile,

  /// A contacts file without its list, or with a row that is not a contact.
  damaged,

  /// Made by a newer app.
  newer,

  /// No contacts in it.
  empty,

  /// Every contact is for another network.
  otherNetwork,
}

class ContactsFileError implements Exception {
  const ContactsFileError(this.problem);

  final ContactsFileProblem problem;

  /// The sentence the user reads.
  String text(AppLocalizations l) => switch (problem) {
    ContactsFileProblem.notFile => l.contactsImportNotFile,
    ContactsFileProblem.damaged => l.contactsImportDamaged,
    ContactsFileProblem.newer => l.contactsImportNewer,
    ContactsFileProblem.empty => l.contactsImportEmpty,
    ContactsFileProblem.otherNetwork => l.contactsImportAllOtherNet,
  };

  @override
  String toString() => 'ContactsFileError(${problem.name})';
}

/// A contacts file as read: its rows, untrusted, and the network it names (null when it names
/// none, as a `contacts.json` does).
class ContactsFile {
  const ContactsFile({required this.rows, this.network});

  final List<GuiContactRow> rows;
  final String? network;
}

/// Reads [bytes] as a contacts file. Throws [ContactsFileError] for one that is not, is
/// damaged, newer or empty.
ContactsFile readContactsFile(List<int> bytes) {
  if (bytes.length > maxContactsFileBytes) throw const ContactsFileError(ContactsFileProblem.notFile);
  final Object? j;
  try {
    j = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    throw const ContactsFileError(ContactsFileProblem.notFile);
  }
  if (j is! Map) throw const ContactsFileError(ContactsFileProblem.notFile);
  final format = j['format'];
  // Without the marker, only the shape of a `contacts.json` counts as a contacts file.
  if (format != null && format != contactsFileFormat) throw const ContactsFileError(ContactsFileProblem.notFile);
  if (format == null && (j['contacts'] is! List || j['version'] is! int)) {
    throw const ContactsFileError(ContactsFileProblem.notFile);
  }
  final version = j['version'];
  if (version is! int) throw const ContactsFileError(ContactsFileProblem.damaged);
  if (version > contactsExportVersion) throw const ContactsFileError(ContactsFileProblem.newer);
  final list = j['contacts'];
  if (list is! List) throw const ContactsFileError(ContactsFileProblem.damaged);
  if (list.isEmpty) throw const ContactsFileError(ContactsFileProblem.empty);
  String? field(Map row, String key, int max) {
    final v = row[key];
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty || t.length > max ? null : t;
  }

  final rows = <GuiContactRow>[];
  for (final row in list) {
    if (row is! Map || row['name'] is! String || (row['name'] as String).trim().isEmpty) {
      throw const ContactsFileError(ContactsFileProblem.damaged);
    }
    rows.add(
      GuiContactRow(
        // Cleaned and capped by the planner; cut here only so a huge one costs nothing.
        name: (row['name'] as String).length > 4 * guiContactNameMax
            ? (row['name'] as String).substring(0, 4 * guiContactNameMax)
            : row['name'] as String,
        externalOne: field(row, 'epicbox', _addressMax),
        externalTwo: field(row, 'http', _addressMax),
        onion: field(row, 'tor', _addressMax),
        note: field(row, 'note', 8 * guiContactNoteMax),
      ),
    );
  }
  final network = j['network'];
  return ContactsFile(rows: rows, network: network is String && network.isNotEmpty ? network : null);
}

/// What an import does, with the counts the confirm sheet shows.
class ContactsImportPlan {
  ContactsImportPlan(this._plan, {required this.otherNetwork, required this.leftOut, this.savedAsIs = 0});

  final GuiContactPlan _plan;

  /// New contacts to add.
  List<ContactFields> get add => _plan.add;

  /// Saved contacts (by id) with the kinds and the note they gain; nothing else of them changes.
  List<ContactFields> get update => _plan.update;

  /// Contacts already here, with nothing to add.
  int get same => _plan.alreadySaved + savedAsIs;

  /// Contacts whose address this wallet cannot send to but that the book already holds as
  /// they are (another network's address saved from the shared book): already here, not left
  /// out.
  final int savedAsIs;

  /// Contacts with no address this wallet can send to.
  final int leftOut;

  /// Contacts whose address is for another network.
  final int otherNetwork;

  /// Whether Import has anything to do.
  bool get hasChanges => add.isNotEmpty || update.isNotEmpty;
}

/// Plans the import of [file] into [saved] for a wallet on [network]. [otherChain] says an
/// Epicbox address is for the other network (`epicboxAddressOtherChain`). A file that names
/// another network, or whose every contact is for another network, throws
/// [ContactsFileProblem.otherNetwork].
ContactsImportPlan planContactsFile(
  ContactsFile file,
  Iterable<ContactFields> saved,
  AddressChecks checks, {
  required String network,
  required bool Function(String epicbox) otherChain,
}) {
  if (file.network != null && file.network != network) throw const ContactsFileError(ContactsFileProblem.otherNetwork);
  // The shared book holds every network's contacts, so a row this wallet cannot send to may
  // already be saved exactly as it is: that one is already here, not left out.
  final savedAddresses = {
    for (final c in saved)
      for (final a in [c.epicbox, c.http, c.tor])
        if (a != null) a.trim().toLowerCase(),
  };
  var otherNetwork = 0;
  var savedAsIs = 0;
  for (final row in file.rows) {
    if (guiContactAddresses(row, checks).byKind.isNotEmpty) continue;
    final raw = [row.externalOne, row.externalTwo, row.onion].whereType<String>().map((a) => a.trim().toLowerCase());
    if (raw.isNotEmpty && raw.every(savedAddresses.contains)) {
      savedAsIs++;
      continue;
    }
    final epicbox = row.externalOne;
    if (epicbox != null && parseRecipient(epicbox).kind == RecipientKind.epicbox && otherChain(epicbox)) otherNetwork++;
  }
  if (otherNetwork == file.rows.length) throw const ContactsFileError(ContactsFileProblem.otherNetwork);
  final plan = planGuiContacts(file.rows, saved, checks);
  return ContactsImportPlan(
    plan,
    otherNetwork: otherNetwork,
    savedAsIs: savedAsIs,
    leftOut: plan.skippedNoAddress - otherNetwork - savedAsIs,
  );
}

/// Saves [plan] through [save]: the new contacts (empty id), then the saved ones that gain a
/// kind or a note (their own id; name, addresses and note as saved). Returns how many it saved.
Future<int> applyContactsImport(ContactsImportPlan plan, Future<void> Function(ContactFields contact) save) async {
  var saved = 0;
  for (final c in [...plan.add, ...plan.update]) {
    await save(c);
    saved++;
  }
  return saved;
}

/// The notice after an import: the contacts added (a saved one that gained something counts
/// as added; the confirm had the detail) and those already there.
String contactsImportedText(AppLocalizations l, ContactsImportPlan plan) {
  final added = plan.add.length + plan.update.length;
  return plan.same == 0 ? l.contactsImportedAdded(added) : l.contactsImported(added, plan.same);
}
