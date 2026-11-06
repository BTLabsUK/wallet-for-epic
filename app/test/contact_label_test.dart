// SPDX-License-Identifier: Apache-2.0
// The contact label (lib/src/contact_label.dart): local to the user, optional on the address
// book entry, carried by the backup and the contacts file. Synthetic data.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/contact_label.dart';
import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/contacts_file.dart';
import 'package:epic_wallet/src/history/export.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/legacy/gui_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

final String _anna = 'es${'a' * 50}@epicbox.epiccash.com';
final String _tom = 'es${'b' * 50}@epicbox.epicnet.us';

final _checks = AddressChecks(
  epicbox: (a) => RegExp(r'^es[1-9A-HJ-NP-Za-km-z]{50}@[a-z0-9.]+(:\d+)?$').hasMatch(a),
  onion: (a) => RegExp(r'^[a-z2-7]{55}d\.onion$').hasMatch(a),
);

void main() {
  late Directory tmp;
  File file() => File('${tmp.path}/$contactsFileName');

  setUp(() async {
    ContactStore.forgetAll();
    tmp = await Directory.systemTemp.createTemp('contact_label_');
  });
  tearDown(() async {
    ContactStore.forgetAll();
    await tmp.delete(recursive: true);
  });

  Future<ContactStore> reopen() {
    ContactStore.forgetAll();
    return ContactStore.open(tmp.path);
  }

  Future<void> writeBook(List<Map<String, Object?>> contacts) async {
    final s = await ContactStore.open(tmp.path);
    await s.save(const ContactFields(name: 'seed', epicbox: 'x'));
    final j = jsonDecode(await file().readAsString()) as Map<String, dynamic>;
    j['contacts'] = contacts;
    await file().writeAsString(jsonEncode(j));
  }

  group('the store', () {
    test('a book written before labels loads, every contact the default', () async {
      await writeBook([
        {'id': 'a1', 'name': 'Anna', 'epicbox': _anna},
      ]);
      final s = await reopen();
      expect(s.list().single.label, ContactLabel.wallet);
    });

    test('an unknown label reads as the default', () async {
      await writeBook([
        {'id': 'a1', 'name': 'Anna', 'epicbox': _anna, 'label': 'spaceship'},
        {'id': 'a2', 'name': 'Tom', 'epicbox': _tom, 'label': 7},
      ]);
      final s = await reopen();
      expect(s.list().map((c) => c.label), [ContactLabel.wallet, ContactLabel.wallet]);
    });

    test('a label round-trips; the default is never written', () async {
      final s = await ContactStore.open(tmp.path);
      await s.save(ContactFields(name: 'Anna', epicbox: _anna, label: ContactLabel.exchange));
      await s.save(ContactFields(name: 'Tom', epicbox: _tom));
      final back = await reopen();
      expect(back.list().map((c) => (c.name, c.label)), [('Anna', ContactLabel.exchange), ('Tom', ContactLabel.wallet)]);
      final raw = jsonDecode(await file().readAsString()) as Map<String, dynamic>;
      final rows = (raw['contacts'] as List).cast<Map<String, dynamic>>();
      expect(rows.firstWhere((r) => r['name'] == 'Anna')['label'], 'exchange');
      expect(rows.firstWhere((r) => r['name'] == 'Tom').containsKey('label'), isFalse);
    });
  });

  group('the backup', () {
    test('a contact record without label loads as the default; one with it keeps it', () {
      final old = ContactRec.fromJson({'id': '1', 'name': 'B', 'address': _anna});
      expect(old.label, isNull);
      expect(old.toJson().containsKey('label'), isFalse);
      expect(ContactRec.fromJson({'id': '1', 'name': 'B', 'address': _anna, 'label': 'bogus'}).label, isNull);
      final vendor = ContactRec.fromJson({'id': '1', 'name': 'B', 'address': _anna, 'label': 'vendor'});
      expect(ContactRec.fromJson(vendor.toJson()).label, 'vendor');
    });

    test('export then restore keeps the label; a saved contact gains it only if it has none', () async {
      final book = ContactStore.memory();
      await book.save(ContactFields(name: 'Anna', epicbox: _anna, label: ContactLabel.service));
      final h = WalletHistory.memory(contacts: book);
      final payload = HistoryPayload.decode(h.exportPayload(const [], walletFp: 'fp', appVersion: 't').encode());
      expect(payload.contacts.single.label, 'service');

      final fresh = ContactStore.memory();
      await WalletHistory.memory(contacts: fresh).importPayload(payload, const [], walletFp: 'fp');
      expect(fresh.list().single.label, ContactLabel.service);

      final unlabelled = ContactStore.memory();
      await unlabelled.save(ContactFields(name: 'A.', epicbox: _tom));
      final labelled = ContactStore.memory();
      await labelled.save(ContactFields(name: 'A.', epicbox: _anna, label: ContactLabel.vendor));
      await WalletHistory.memory(contacts: unlabelled).importPayload(
        HistoryPayload.decode(
          HistoryPayload(chain: 'Mainnet', walletFp: 'fp', exportedAtUnix: 1, appVersion: 't', contacts: [ContactRec(id: 'c', name: 'A.', epicbox: _tom, label: 'exchange')]).encode(),
        ),
        const [],
        walletFp: 'fp',
      );
      expect(unlabelled.list().single.label, ContactLabel.exchange);
      await WalletHistory.memory(contacts: labelled).importPayload(payload, const [], walletFp: 'fp');
      expect(labelled.list().firstWhere((c) => c.epicbox == _anna).label, ContactLabel.vendor);
    });
  });

  group('the contacts file', () {
    test('export then import keeps the label; the default is not written', () {
      final book = [
        ContactFields(id: 'x', name: 'Anna', epicbox: _anna, label: ContactLabel.exchange),
        ContactFields(id: 'y', name: 'Tom', epicbox: _tom),
      ];
      final bytes = utf8.encode(encodeContactsFile(book, network: 'mainnet', now: DateTime.utc(2026, 11, 5)));
      final rows = (jsonDecode(utf8.decode(bytes))['contacts'] as List).cast<Map<String, dynamic>>();
      expect(rows[0]['label'], 'exchange');
      expect(rows[1].containsKey('label'), isFalse);
      final plan = planContactsFile(readContactsFile(bytes), const [], _checks, network: 'mainnet', otherChain: (_) => false);
      expect(plan.add.map((c) => (c.name, c.label)), [('Anna', ContactLabel.exchange), ('Tom', ContactLabel.wallet)]);
    });

    test('a file made before labels imports as the default', () {
      final bytes = utf8.encode(jsonEncode({
        'format': 'epic-cash-contacts',
        'version': 1,
        'exported': '2026-10-25T14:02:11Z',
        'contacts': [
          {'name': 'Tom', 'epicbox': _tom},
        ],
      }));
      final plan = planContactsFile(readContactsFile(bytes), const [], _checks, network: 'mainnet', otherChain: (_) => false);
      expect(plan.add.single.label, ContactLabel.wallet);
    });
  });
}
