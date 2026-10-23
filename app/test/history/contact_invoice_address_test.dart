// A contact's invoice address in the shared record: written only when set, round trips through
// the file, and a file written before it still reads.
import 'dart:convert';

import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a record without the field reads, and writes back without it', () {
    final old = jsonDecode('{"version":1,"contacts":[{"id":"1","name":"Bob","address":"addr"}]}');
    final meta = Meta.fromJson(old);
    expect(meta.contacts.single.invoiceAddress, isNull);
    expect((meta.toJson()['contacts'] as List).single, {'id': '1', 'name': 'Bob', 'address': 'addr'});
  });

  test('the invoice address round trips through the file text', () {
    final meta = Meta(contacts: [ContactRec(id: '1', name: 'Bob', address: 'a', invoiceAddress: 'inv@relay')]);
    final back = Meta.fromJson(jsonDecode(encodeJson(meta.toJson())));
    expect(back.contacts.single.invoiceAddress, 'inv@relay');
    expect(encodeJson(meta.toJson()), contains('"invoice_address":"inv@relay"'));
  });

  test('a bad type in the field is refused', () {
    expect(
      () => Meta.fromJson({'contacts': [{'id': '1', 'name': 'B', 'address': 'a', 'invoice_address': 5}]}),
      throwsA(anything),
    );
  });

  test('saving keeps, trims and clears it; the history copy and a Contact compare by it', () async {
    final history = WalletHistory.memory();
    final saved = await history.saveContact(const Contact(id: '', name: 'Bob', address: 'a', invoiceAddress: ' inv@relay '));
    expect(saved.invoiceAddress, 'inv@relay');
    expect(history.contacts().single.invoiceAddress, 'inv@relay');
    final cleared = await history.saveContact(Contact(id: saved.id, name: 'Bob', address: 'a', invoiceAddress: '  '));
    expect(cleared.invoiceAddress, isNull);
    expect(const Contact(id: '1', name: 'B', address: 'a', invoiceAddress: 'x'), isNot(const Contact(id: '1', name: 'B', address: 'a')));
  });
}
