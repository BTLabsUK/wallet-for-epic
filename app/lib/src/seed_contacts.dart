/// Contacts every new wallet starts with (F31, D-10): the bundled list, and the small JSON on
/// the BTLabs-EPIC website that may replace it later. Pure Dart, shared by the phone and the
/// desktop; the seeding rule (insert once, never re-add a deleted one, leave an edited one
/// alone) lives with each app's contacts store.
library;

import 'dart:convert';

/// One contact a new wallet starts with. [id] stays the same when the website changes the
/// address, so an update can find the contact it seeded.
class SeedContact {
  const SeedContact({required this.id, required this.name, required this.address, required this.note});

  final String id;
  final String name;
  final String address;
  final String note;

  @override
  bool operator ==(Object other) =>
      other is SeedContact && other.id == id && other.name == name && other.address == address && other.note == note;

  @override
  int get hashCode => Object.hash(id, name, address, note);

  @override
  String toString() => 'SeedContact($id, $name, $address)';
}

/// BT Labs' donation address.
const btLabsContact = SeedContact(
  id: 'btlabs',
  name: 'BT Labs',
  address: 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com',
  note: 'Donations support development of this wallet.',
);

/// What the app ships with; used whenever the website cannot be read.
const List<SeedContact> bundledSeedContacts = [btLabsContact];

/// The website's copy: `{"version": 1, "contacts": [{"id", "name", "address", "note"}]}`.
const String seedContactsUrl = 'https://btlabs-epic.github.io/contacts.json';

/// The contacts in [body], the website's JSON, keeping only entries with every field and an
/// address [validAddress] accepts (the caller checks it with the wallet core, e.g. the Epicbox
/// checksum). Null when [body] is not that format, so the caller keeps what it has: a bad or
/// unknown file never removes a contact.
List<SeedContact>? parseSeedContacts(String body, {required bool Function(String address) validAddress}) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (json is! Map || json['version'] != 1 || json['contacts'] is! List) return null;
  final out = <SeedContact>[];
  final seen = <String>{};
  for (final c in json['contacts'] as List) {
    if (c is! Map) continue;
    final id = c['id'], name = c['name'], address = c['address'], note = c['note'];
    if (id is! String || name is! String || address is! String || note is! String) continue;
    final a = address.trim();
    if (id.isEmpty || name.trim().isEmpty || !validAddress(a) || !seen.add(id)) continue;
    out.add(SeedContact(id: id, name: name.trim(), address: a, note: note.trim()));
  }
  return out;
}
