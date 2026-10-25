// The address book every wallet shares (lib/src/contact_store.dart) and WalletHistory over it:
// one file in a temp folder, two wallets' histories reading and writing it. Synthetic data.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/history/export.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _a = 'esWNvLomAJ2SHT6CU1F4ok2URGQnmUmCAp9XNwEP4N8JS4Ve8qcx@epicbox.example.com';
const _b = 'es7jHnbVkZzE2UGWUkzWrc4y4VoKZbg7FBaPUo2vXhJpe4jgXAA7@epicbox.example.com';

void main() {
  late Directory tmp;
  File file() => File('${tmp.path}/$contactsFileName');

  setUp(() async {
    ContactStore.forgetAll();
    tmp = await Directory.systemTemp.createTemp('contact_store_');
  });
  tearDown(() async {
    ContactStore.forgetAll();
    await tmp.delete(recursive: true);
  });

  Future<ContactStore> reopen() {
    ContactStore.forgetAll();
    return ContactStore.open(tmp.path);
  }

  group('the store', () {
    test('saves, lists by name, replaces, deletes; refuses what is not a contact', () async {
      final s = await ContactStore.open(tmp.path);
      final bob = await s.save(const ContactFields(name: ' bob ', epicbox: _a));
      expect(bob.id, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(bob.name, 'bob');
      await s.save(const ContactFields(name: 'Alice', http: 'https://alice.example'));
      expect([for (final c in s.list()) c.name], ['Alice', 'bob']);
      await s.save(ContactFields(id: bob.id, name: 'Bob', epicbox: _a, tor: 'x.onion'));
      expect(s.list().last.tor, 'x.onion');
      await expectLater(s.save(const ContactFields(id: 'gone', name: 'X', epicbox: _a)), throwsA(isA<WalletError>()));
      await expectLater(s.save(const ContactFields(name: '  ', epicbox: _a)), throwsA(isA<WalletError>()));
      // No address: a contact a pairing pays.
      final paired = await s.save(const ContactFields(name: 'No address'));
      expect(paired.addresses, isEmpty);
      await s.delete(paired.id);
      await s.delete(bob.id);
      expect([for (final c in s.list()) c.name], ['Alice']);
    });

    test('one store per folder; what is saved is read back from the file, readable by the user only', () async {
      final s = await ContactStore.open(tmp.path);
      expect(identical(s, await ContactStore.open(tmp.path)), isTrue);
      await s.saveAll(add: const [
        ContactFields(name: 'Alice', epicbox: _a, note: 'line 1\nline 2'),
        ContactFields(name: 'Bob', http: 'https://bob.example'),
      ]);
      final json = jsonDecode(await file().readAsString()) as Map<String, dynamic>;
      expect(json['version'], 1);
      expect((json['contacts'] as List).first, containsPair('epicbox', _a));
      expect(((json['contacts'] as List).last as Map).containsKey('invoice_address'), isFalse);
      expect(await File('${file().path}.tmp').exists(), isFalse);
      final again = await reopen();
      expect(again.list(), s.list());
      if (Platform.isLinux || Platform.isMacOS) {
        final mode = (await Process.run('stat', [if (Platform.isMacOS) ...['-f', '%Lp'] else ...['-c', '%a'], file().path])).stdout;
        expect(mode.toString().trim(), '600');
      }
    });

    test('saveAll adds and replaces in one write', () async {
      final s = await ContactStore.open(tmp.path);
      final a = await s.save(const ContactFields(name: 'Alice', epicbox: _a));
      final added = await s.saveAll(
        add: const [ContactFields(name: 'Bob', epicbox: _b)],
        replace: [a.copyWith(note: 'met at the meetup')],
      );
      expect(added.single.id, isNotEmpty);
      expect((await reopen()).list().map((c) => (c.name, c.note)), [('Alice', 'met at the meetup'), ('Bob', null)]);
    });

    test('a damaged file is moved aside and the book starts empty', () async {
      await file().writeAsString('{"version": 1, "contacts": [ broken');
      final s = await ContactStore.open(tmp.path);
      expect(s.list(), isEmpty);
      final aside = tmp.listSync().where((e) => e.path.contains('$contactsFileName.corrupt-'));
      expect(aside, hasLength(1));
      await s.save(const ContactFields(name: 'Alice', epicbox: _a));
      expect((await reopen()).list(), hasLength(1));
    });

    test('a file of a newer version is read, never rewritten', () async {
      await file().writeAsString(jsonEncode({
        'version': 2,
        'contacts': [
          {'id': 'c1', 'name': 'Alice', 'epicbox': _a, 'newer': true},
          {'name': 'no id'},
        ],
      }));
      final before = await file().readAsString();
      final s = await ContactStore.open(tmp.path);
      expect(s.readOnly, isTrue);
      expect([for (final c in s.list()) c.name], ['Alice']);
      await expectLater(s.save(const ContactFields(name: 'Bob', epicbox: _b)), throwsA(isA<WalletError>()));
      expect(await file().readAsString(), before);
    });
  });

  group('shared by every wallet', () {
    WalletHistory wallet(ContactStore s, {Chain chain = Chain.mainnet}) =>
        WalletHistory(MetaStore.memory(), chain: chain, contacts: s);

    test('a contact one wallet saves is the other\'s too; a delete removes it for both', () async {
      final s = await ContactStore.open(tmp.path);
      final one = wallet(s), two = wallet(s);
      final c = await one.saveContact(Contact(id: '', name: 'Alice', epicbox: _a, note: 'n'));
      expect([for (final x in two.contacts()) (x.id, x.name, x.epicbox, x.note)], [(c.id, 'Alice', _a, 'n')]);
      await two.saveContact(Contact(id: c.id, name: 'Alice', epicbox: _a, http: 'https://alice.example'));
      expect(one.contacts().single.http, 'https://alice.example');
      await one.deleteContact(c.id);
      expect(two.contacts(), isEmpty);
      expect(one.meta.contacts, isEmpty, reason: 'the wallet\'s own archive holds no contacts');
      expect((await reopen()).list(), isEmpty);
    });

    test('a history file carries the shared book and brings its contacts back into it', () async {
      final s = await ContactStore.open(tmp.path);
      final one = wallet(s);
      await one.saveContact(Contact(id: '', name: 'Alice', epicbox: _a));
      await one.saveContact(Contact(id: '', name: 'Bob', http: 'https://bob.example'));
      final payload = one.exportPayload(const [], walletFp: 'fp', appVersion: 'test');
      expect([for (final c in payload.contacts) c.name], ['Alice', 'Bob']);

      // Another device: Alice is there already (by her address), Bob is not.
      ContactStore.forgetAll();
      final other = await Directory('${tmp.path}/other').create();
      final s2 = await ContactStore.open(other.path);
      await s2.save(const ContactFields(name: 'Alice here', epicbox: _a));
      final back = HistoryPayload.decode(payload.encode());
      final report = await wallet(s2).importPayload(back, const [], walletFp: 'fp');
      expect(report.contactsAdded, 1);
      expect([for (final c in s2.list()) c.name], ['Alice here', 'Bob']);
    });
  });
}
