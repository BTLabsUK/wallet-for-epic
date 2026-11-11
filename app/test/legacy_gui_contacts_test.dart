// SPDX-License-Identifier: Apache-2.0
// How an old Epic GUI's address book maps into the app's contacts (lib/src/legacy/gui_contacts.dart):
// kinds read from the content, bare keys completed, untrusted text cleaned, matches merged without
// changing what is saved. Synthetic names and addresses only.
import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/legacy/gui_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/test_settings.dart';

const _a = 'esWNvLomAJ2SHT6CU1F4ok2URGQnmUmCAp9XNwEP4N8JS4Ve8qcx';
const _b = 'es7jHnbVkZzE2UGWUkzWrc4y4VoKZbg7FBaPUo2vXhJpe4jgXAA7';
const _onion = '2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid';
final _link = 'epic:epic1${'q' * 58}?epicbox=epicbox.epiccash.com';

final _checks = AddressChecks(
  epicbox: (a) => RegExp(r'^es[1-9A-HJ-NP-Za-km-z]{50}@[a-z0-9.-]+(:\d+)?$').hasMatch(a),
  onion: (a) => RegExp(r'^[a-z2-7]{55}d\.onion$').hasMatch(a),
);

GuiContactPlan plan(List<GuiContactRow> rows, [List<ContactFields> saved = const [], String? domain, int? port]) =>
    planGuiContacts(rows, saved, _checks, epicboxDomain: domain, epicboxPort: port);

String ch(int code) => String.fromCharCode(code);

void main() {
  // These tests read the old GUI's real data against the shipped defaults.
  useShippedSettings();

  group('addresses by what they are', () {
    test('an Epicbox address in the External field, a URL in the Epicbox field, an onion in either field', () {
      final p = plan([
        GuiContactRow(name: 'One', externalOne: 'https://one.example:3415', externalTwo: '$_a@epicbox.example.com'),
        GuiContactRow(name: 'Two', externalTwo: 'http://${_onion.toUpperCase()}.onion:80/', externalOne: 'epicbox://$_b@epicbox.example.com'),
        GuiContactRow(name: 'Three', onion: _onion),
      ]);
      expect([for (final c in p.add) (c.name, c.epicbox, c.http, c.tor)], [
        ('One', '$_a@epicbox.example.com', 'https://one.example:3415', null),
        ('Two', '$_b@epicbox.example.com', null, '$_onion.onion'),
      ]);
      // Three has Two's onion: the same contact, nothing new.
      expect(p.alreadySaved, 1);
    });

    test('a bare key gets the wallet\'s Epicbox domain, a port only when not 443', () {
      expect(plan([GuiContactRow(name: 'x', externalOne: _a)], const [], 'EPICBOX.Example.ORG').add.single.epicbox, '$_a@epicbox.example.org');
      expect(plan([GuiContactRow(name: 'x', externalOne: _a)], const [], 'epicbox.example.org', 443).add.single.epicbox, '$_a@epicbox.example.org');
      expect(plan([GuiContactRow(name: 'x', externalOne: _a)], const [], 'epicbox.example.org', 8443).add.single.epicbox, '$_a@epicbox.example.org:8443');
      expect(plan([GuiContactRow(name: 'x', externalOne: _a)]).add.single.epicbox, '$_a@epicbox.epiccash.com');
    });

    test('the first valid address of a kind wins; another of that kind is left out; junk is ignored', () {
      final p = plan([
        GuiContactRow(name: 'x', externalOne: 'not an address!!', externalTwo: '$_a@relay.example.com', onion: '$_b@relay.example.com'),
      ]);
      expect(p.add.single.epicbox, '$_a@relay.example.com');
      expect(p.addressesLeftOut, 1);
      // The same key at another relay is no second address.
      expect(plan([GuiContactRow(name: 'x', externalOne: '$_a@one.example', externalTwo: '$_a@two.example')]).addressesLeftOut, 0);
    });

    test('no address, or none valid: skipped', () {
      final p = plan(const [
        GuiContactRow(name: 'empty'),
        GuiContactRow(name: 'junk', externalOne: 'hello', externalTwo: 'ftp://files.example', onion: 'short.onion'),
        GuiContactRow(name: 'blank', externalOne: '   '),
      ]);
      expect(p.add, isEmpty);
      expect(p.skippedNoAddress, 3);
    });
  });

  group('untrusted text', () {
    test('names lose control, direction and zero-width characters, fold spaces, stop at 64', () {
      expect(cleanContactName('  Ali${ch(0x202E)}ce\t\u0000 ${ch(0x200B)}Smith  '), 'Alice Smith');
      expect(cleanContactName('a${ch(0x2028)}b${ch(0x2066)}c${ch(0xFEFF)}'), 'a bc');
      expect(cleanContactName('李' * 70).runes.length, 64);
      expect(cleanContactName('💰' * 65), '💰' * 64);
      expect(cleanContactName(null), '');
    });

    test('notes keep their lines, at most one blank line in a row, stop at 1000', () {
      expect(cleanContactNote('line 1\r\nline 2\n\n\n\n\nline 3${ch(0x202E)}'), 'line 1\nline 2\n\nline 3');
      expect(cleanContactNote('x' * 1200).length, 1000);
    });

    test('a contact with no name is named by its first address', () {
      final p = plan([GuiContactRow(name: ' ${ch(0x202E)} ', externalTwo: 'https://shop.example')]);
      expect(p.add.single.name, 'https://shop.example');
    });

    test('a note is cleaned on the way in', () {
      final p = plan([GuiContactRow(name: 'x', externalOne: _a, note: ' paid\u0007 ${ch(0x202E)}twice ')]);
      expect(p.add.single.note, 'paid twice');
    });
  });

  group('merging with saved contacts', () {
    const saved = [
      ContactFields(id: 's1', name: 'Shop', epicbox: '$_a@epicbox.epiccash.com', note: 'mine'),
      ContactFields(id: 's2', name: 'Friend', http: 'https://friend.example'),
    ];

    test('the same key at another relay is the same contact; nothing to add is already saved', () {
      final p = plan([GuiContactRow(name: 'Shop (old)', externalOne: '$_a@epicbox.other.example')], saved);
      expect(p.alreadySaved, 1);
      expect(p.add, isEmpty);
      expect(p.update, isEmpty);
    });

    test('a match gains the kinds it lacks, and a note only when it had none; its name stays', () {
      final p = plan([
        GuiContactRow(name: 'Shopkeeper', externalOne: _a, externalTwo: 'https://shop.example', note: 'theirs'),
        GuiContactRow(name: 'Friend renamed', externalTwo: 'https://friend.example/', onion: _onion, note: 'a note'),
      ], saved);
      expect(p.merged, 2);
      expect(p.update, [
        const ContactFields(id: 's1', name: 'Shop', epicbox: '$_a@epicbox.epiccash.com', http: 'https://shop.example', note: 'mine'),
        const ContactFields(id: 's2', name: 'Friend', http: 'https://friend.example', tor: '$_onion.onion', note: 'a note'),
      ]);
    });

    test('a different address of a kind the contact has is left out, the saved one kept', () {
      final p = plan([GuiContactRow(name: 'Friend', externalOne: 'https://friend.example', externalTwo: 'https://other.example')], saved);
      // externalOne is the match; externalTwo is a second HTTP address of the same old contact
      expect(p.addressesLeftOut, 1);
      expect(p.alreadySaved, 1);
      final q = plan([GuiContactRow(name: 'Shop', externalOne: _a, externalTwo: 'https://friend.example')], saved);
      // matched by Shop's key; the HTTP address is Friend's: not copied onto Shop
      expect(q.addressesLeftOut, 1);
      expect(q.update, isEmpty);
      expect(q.alreadySaved, 1);
    });

    test('an epic1 link: gained when missing, kept as its own contact when it differs', () {
      final saved = [ContactFields(id: 's', name: 'Shop', epicbox: '$_a@epicbox.epiccash.com')];
      final gain = plan([GuiContactRow(name: 'Shop', externalOne: _a, epic1: _link)], saved);
      expect(gain.update.single.epic1, _link);
      final other = _link.replaceFirst('q', 'z');
      final keep = plan([GuiContactRow(name: 'Shop 2', externalOne: _a, epic1: other)], [gain.update.single]);
      expect(keep.update, isEmpty);
      expect(keep.add.map((c) => (c.name, c.epicbox, c.epic1)), [('Shop 2', null, other)]);
      expect(keep.addressesLeftOut, 0);
      // The same rows again add nothing.
      final again = plan([GuiContactRow(name: 'Shop 2', externalOne: _a, epic1: other)], [gain.update.single, keep.add.single.copyWith(id: 'k')]);
      expect(again.add, isEmpty);
      expect(again.update, isEmpty);
    });

    test('two old rows for one person: the second merges into the first one added', () {
      final p = plan([
        GuiContactRow(name: 'Carol', externalOne: _b),
        GuiContactRow(name: 'Carol (shop)', externalOne: _b, externalTwo: 'https://carol.example'),
      ]);
      expect(p.add, [const ContactFields(name: 'Carol', epicbox: '$_b@epicbox.epiccash.com', http: 'https://carol.example')]);
      expect(p.merged, 1);
      expect(p.update, isEmpty);
    });

    test('the same rows again add nothing', () {
      final rows = [
        GuiContactRow(name: 'One', externalOne: _a, externalTwo: 'https://one.example', note: 'n'),
        GuiContactRow(name: 'Two', onion: _onion),
      ];
      final first = plan(rows);
      var n = 0;
      final stored = [for (final c in first.add) c.copyWith(id: 'id${n++}')];
      final again = plan(rows, stored);
      expect(again.add, isEmpty);
      expect(again.update, isEmpty);
      expect(again.alreadySaved, 2);
    });
  });
}
