// SPDX-License-Identifier: Apache-2.0
// Export and Import contacts (contacts_file.dart): the file, its refusals, and the import's
// rules (the GUI import's planner: nothing saved changes, a match only gains what it lacks).
import 'dart:convert';

import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/contacts_file.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/legacy/gui_contacts.dart';
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:flutter_test/flutter_test.dart';

final String _anna = 'es${'a' * 50}@epicbox.epiccash.com';
final String _tom = 'es${'b' * 50}@epicbox.epicnet.us';
final String _floonet = 'zz${'c' * 50}@flooepicbox.btlabs.uk';
final String _onion = '${'t' * 55}d.onion';
const String _http = 'https://pay.example.net:3415';

final _checks = AddressChecks(
  epicbox: (a) => RegExp(r'^es[1-9A-HJ-NP-Za-km-z]{50}@[a-z0-9.]+(:\d+)?$').hasMatch(a),
  onion: (a) => RegExp(r'^[a-z2-7]{55}d\.onion$').hasMatch(a),
);

bool _otherChain(String a) => a.startsWith('zz');

ContactsImportPlan _plan(List<int> bytes, List<ContactFields> saved, {String network = 'mainnet'}) =>
    planContactsFile(readContactsFile(bytes), saved, _checks, network: network, otherChain: _otherChain);

List<int> _file(Object json) => utf8.encode(jsonEncode(json));

Matcher _refused(ContactsFileProblem p) => throwsA(isA<ContactsFileError>().having((e) => e.problem, 'problem', p));

void main() {
  final book = [
    ContactFields(id: 'id-anna', name: 'Anna Kowalska', epicbox: _anna, http: _http, note: 'Flatmate'),
    ContactFields(id: 'id-tom', name: 'Tom', epicbox: _tom),
    // A pairing's contact: no address, so only its name and note go.
    const ContactFields(id: 'id-paired', name: 'Northwind', note: 'Paired in person'),
  ];
  final exported = utf8.encode(encodeContactsFile(book, network: 'mainnet', now: DateTime.utc(2026, 10, 25, 14, 2, 11)));

  test('export writes the marker, version, network and only name, addresses and note', () {
    final j = jsonDecode(utf8.decode(exported)) as Map<String, dynamic>;
    expect(j['format'], 'epic-cash-contacts');
    expect(j['version'], 1);
    expect(j['network'], 'mainnet');
    expect(j['exported'], '2026-10-25T14:02:11Z');
    expect(j['contacts'], [
      {'name': 'Anna Kowalska', 'epicbox': _anna, 'http': _http, 'note': 'Flatmate'},
      {'name': 'Tom', 'epicbox': _tom},
      {'name': 'Northwind', 'note': 'Paired in person'},
    ]);
    // Never a key, a pairing or an id.
    expect(utf8.decode(exported), isNot(contains('id-')));
    expect(contactsExportFileName(DateTime(2026, 3, 7)), 'epic-cash-contacts-2026-03-07.json');
  });

  test('its own export into an empty book adds every contact, a paired one by name and note', () {
    final plan = _plan(exported, const []);
    expect(plan.add.map((c) => (c.name, c.epicbox, c.http, c.note)), [
      ('Anna Kowalska', _anna, _http, 'Flatmate'),
      ('Tom', _tom, null, null),
      ('Northwind', null, null, 'Paired in person'),
    ]);
    expect(plan.add.every((c) => c.id.isEmpty), isTrue, reason: 'ids are given on save');
    expect(plan.update, isEmpty);
    expect((plan.same, plan.leftOut, plan.otherNetwork), (0, 0, 0));
  });

  test('into a book holding all three: 3 already here, nothing changes', () {
    final saved = [
      ContactFields(id: 'x1', name: 'Anna (work)', epicbox: _anna, note: 'Mine'),
      ContactFields(id: 'x2', name: 'T.', epicbox: 'es${'b' * 50}@epicbox.epiccash.com'),
      // A paired contact is matched by its name.
      const ContactFields(id: 'x3', name: 'Northwind'),
    ];
    final plan = _plan(exported, saved);
    // Anna gains the HTTP address she lacked; her name and note stay.
    expect(plan.update.single, ContactFields(id: 'x1', name: 'Anna (work)', epicbox: _anna, http: _http, note: 'Mine'));
    // Tom's key at another relay is the same contact, with nothing to add.
    expect(plan.same, 2);
    expect(plan.add, isEmpty);
    final full = [saved.first.copyWith(http: _http), ...saved.skip(1)];
    final again = _plan(exported, full);
    expect((again.same, again.hasChanges), (3, false));
  });

  test('a contact that gains a Tor address keeps its name and note', () {
    final file = _file({
      'format': 'epic-cash-contacts',
      'version': 1,
      'contacts': [
        {'name': 'Someone else', 'epicbox': _tom, 'tor': _onion, 'note': 'other note', 'picture': 'ignored'},
      ],
    });
    final plan = _plan(file, [ContactFields(id: 'x', name: 'Tom', epicbox: _tom, note: 'mine')]);
    expect(plan.update.single, ContactFields(id: 'x', name: 'Tom', epicbox: _tom, tor: _onion, note: 'mine'));
  });

  test('a book of paired contacts only exports, and a name already here is not added twice', () {
    final only = [const ContactFields(id: 'p', name: 'Bob Stone')];
    expect(exportableContacts(only), only);
    final file = utf8.encode(encodeContactsFile(only, network: 'mainnet', now: DateTime.utc(2026, 10, 27)));
    expect(_plan(file, const []).add.single.name, 'Bob Stone');
    final again = _plan(file, [const ContactFields(id: 'x', name: 'bob stone')]);
    expect(again.add, isEmpty);
    expect((again.same, again.leftOut), (1, 0));
  });

  test('rows without a usable address are left out; other-network ones are counted apart', () {
    final file = _file({
      'format': 'epic-cash-contacts',
      'version': 1,
      'contacts': [
        {'name': 'Good', 'epicbox': _anna},
        {'name': 'Broken', 'epicbox': 'es123@nowhere'},
        {'name': 'Floonet', 'epicbox': _floonet},
        {'name': 'Huge', 'http': 'https://example.net/${'x' * 600}'},
      ],
    });
    final plan = _plan(file, const []);
    expect(plan.add.single.name, 'Good');
    expect((plan.leftOut, plan.otherNetwork), (2, 1));
  });

  test("another network's contact the shared book holds as it is: already here, not left out", () {
    final saved = [ContactFields(id: 'f', name: 'F', epicbox: _floonet)];
    final file = _file({
      'version': 1,
      'contacts': [
        {'id': 'f', 'name': 'F', 'epicbox': _floonet},
        {'id': 'g', 'name': 'Good', 'epicbox': _anna},
      ],
    });
    final plan = _plan(file, saved);
    expect(plan.add.single.name, 'Good');
    expect((plan.same, plan.leftOut, plan.otherNetwork), (1, 0, 0));
    // Only that one in the file: nothing to import, and it is not refused as another network.
    final only = _plan(_file({'version': 1, 'contacts': [{'id': 'f', 'name': 'F', 'epicbox': _floonet}]}), saved);
    expect((only.hasChanges, only.same, only.leftOut, only.otherNetwork), (false, 1, 0, 0));
  });

  test('a floonet book on mainnet is refused as another network', () {
    final floonet = utf8.encode(
      encodeContactsFile([ContactFields(id: 'f', name: 'F', epicbox: _floonet)], network: 'floonet', now: DateTime(2026)),
    );
    expect(() => _plan(floonet, const []), _refused(ContactsFileProblem.otherNetwork));
    // Without a network named, the addresses decide.
    final unnamed = _file({
      'version': 1,
      'contacts': [
        {'id': 'f', 'name': 'F', 'epicbox': _floonet},
      ],
    });
    expect(() => _plan(unnamed, const []), _refused(ContactsFileProblem.otherNetwork));
  });

  test('a contacts.json from another install imports (ids ignored)', () {
    final raw = _file({
      'version': 1,
      'contacts': [
        {'id': 'abc', 'name': 'Anna', 'epicbox': _anna},
      ],
    });
    final plan = _plan(raw, const []);
    expect(plan.add.single.id, isEmpty);
    expect(plan.add.single.name, 'Anna');
  });

  test('names and notes are cleaned and capped as the contact editor does', () {
    final file = _file({
      'format': 'epic-cash-contacts',
      'version': 1,
      'contacts': [
        {'name': 'An\u202ena\u0000 ${'x' * 300}', 'epicbox': _anna, 'note': 'n' * 5000},
      ],
    });
    final c = _plan(file, const []).add.single;
    expect(c.name.runes.length, lessThanOrEqualTo(guiContactNameMax));
    expect(c.name, startsWith('Anna '));
    expect(c.note!.length, guiContactNoteMax);
  });

  group('refusals', () {
    test('not JSON, JSON of another kind, or too large: not a contacts file', () {
      expect(() => readContactsFile(utf8.encode('name,address\n')), _refused(ContactsFileProblem.notFile));
      expect(() => readContactsFile([0xff, 0xfe, 0x00]), _refused(ContactsFileProblem.notFile));
      expect(() => readContactsFile(_file([1, 2])), _refused(ContactsFileProblem.notFile));
      expect(() => readContactsFile(_file({'format': 'epic-history', 'version': 1, 'contacts': []})), _refused(ContactsFileProblem.notFile));
      expect(() => readContactsFile(_file({'notes': {}})), _refused(ContactsFileProblem.notFile));
      expect(() => readContactsFile(List.filled(maxContactsFileBytes + 1, 0x20)), _refused(ContactsFileProblem.notFile));
    });

    test('a contacts file without its list, or with a row without a name: damaged', () {
      expect(() => readContactsFile(_file({'format': 'epic-cash-contacts', 'version': 1})), _refused(ContactsFileProblem.damaged));
      expect(
        () => readContactsFile(_file({'format': 'epic-cash-contacts', 'version': 1, 'contacts': [{'epicbox': _anna}]})),
        _refused(ContactsFileProblem.damaged),
      );
      expect(() => readContactsFile(_file({'format': 'epic-cash-contacts', 'contacts': []})), _refused(ContactsFileProblem.damaged));
    });

    test('a version 2 file: newer; an empty list: empty', () {
      expect(() => readContactsFile(_file({'format': 'epic-cash-contacts', 'version': 2, 'contacts': []})), _refused(ContactsFileProblem.newer));
      expect(() => readContactsFile(_file({'format': 'epic-cash-contacts', 'version': 1, 'contacts': []})), _refused(ContactsFileProblem.empty));
    });
  });

  test('applying saves the new contacts, then what saved ones gain', () async {
    final plan = _plan(exported, [ContactFields(id: 'x1', name: 'Anna', epicbox: _anna)]);
    final saved = <ContactFields>[];
    expect(await applyContactsImport(plan, (c) async => saved.add(c)), 3);
    expect(saved.map((c) => (c.id, c.name)), [('', 'Tom'), ('', 'Northwind'), ('x1', 'Anna')]);
  });

  test('a star is per wallet: the shared book has none, another wallet sees none', () async {
    final shared = ContactStore.memory();
    final a = WalletHistory.memory(contacts: shared);
    final b = WalletHistory.memory(chain: Chain.mainnet, contacts: shared);
    final c = await shared.save(ContactFields(name: 'Anna', epicbox: _anna));
    await a.setFavourite(c.id, true);
    expect(a.favourites(), {c.id});
    expect(b.favourites(), isEmpty);
    expect(a.meta.toJson()['favourites'], [c.id]);
    expect(Meta.fromJson(a.meta.toJson()).favourites, {c.id});
    // Deleting the contact here drops this wallet's star.
    await a.deleteContact(c.id);
    expect(a.favourites(), isEmpty);
    expect(a.meta.toJson().containsKey('favourites'), isFalse, reason: 'written only when not empty');
  });
}
