// The phone seeds the BT Labs contact once per wallet into the shared address book.
import 'dart:io';

import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/seed_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  setUp(() async {
    ContactStore.forgetAll();
    tmp = await Directory.systemTemp.createTemp('seed_contacts_');
  });
  tearDown(() async {
    ContactStore.forgetAll();
    await tmp.delete(recursive: true);
  });

  Future<WalletHistory> open(String wallet, ContactStore book) async {
    final dir = Directory('${tmp.path}/$wallet')..createSync();
    return WalletHistory.open(dir.path, Chain.mainnet, contacts: book);
  }

  test('a wallet gets BT Labs once; a deleted one is not added again', () async {
    final book = await ContactStore.open(tmp.path);
    var h = await open('w1', book);
    await h.seedContacts(bundledSeedContacts);
    expect(book.list().map((c) => c.name), ['BT Labs']);
    expect(book.list().single.epicbox, btLabsContact.address);
    await h.deleteContact(book.list().single.id);
    h.close();
    h = await open('w1', book);
    await h.seedContacts(bundledSeedContacts);
    expect(book.list(), isEmpty);
    h.close();
  });

  test('an edited contact is left alone, a second wallet adds no duplicate', () async {
    final book = await ContactStore.open(tmp.path);
    final h1 = await open('w1', book);
    await h1.seedContacts(bundledSeedContacts);
    final c = book.list().single;
    await book.save(ContactFields(id: c.id, name: 'Donate', epicbox: c.epicbox, note: 'mine'));
    await h1.seedContacts(bundledSeedContacts);
    final h2 = await open('w2', book);
    await h2.seedContacts(bundledSeedContacts);
    expect(book.list().map((c) => c.name), ['Donate']);
    h1.close();
    h2.close();
  });

  test('a book that has the address already gets nothing added', () async {
    final book = await ContactStore.open(tmp.path);
    await book.save(const ContactFields(name: 'Imported', epicbox: 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com'));
    final h = await open('w1', book);
    await h.seedContacts(bundledSeedContacts);
    expect(book.list().map((c) => c.name), ['Imported']);
    h.close();
  });
}
