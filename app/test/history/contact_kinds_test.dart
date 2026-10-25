// A contact holds one address of each kind (RFC 0002 17.2): the model sorts an address into
// its kind, the file keeps one address as the old core wrote it and several by kind, and the
// history keeps them through a save and a history file.
import 'dart:convert';

import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/contacts.dart';
import 'package:epic_wallet/src/history/export.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:flutter_test/flutter_test.dart';

const _box = 'esKJdaBi1W1eHJFeV6HAPCM63Us2983Gqa5gFSXNsE3ascRpFxfc@epicbox.epiccash.com';
const _http = 'https://pay.example.net:3415';
const _onion = 'mbkzvq3uyx7nqk2ahtr4oewl6jx5fdcpsy3givn2rw7bmkhq5ufk7uyd.onion';

void main() {
  test('an address goes into the field of its kind', () {
    expect(Contact(id: '', name: 'A', address: _box).epicbox, _box);
    expect(Contact(id: '', name: 'A', address: _http).http, _http);
    expect(Contact(id: '', name: 'A', address: _onion).tor, _onion);
    final c = Contact(id: '', name: 'A', epicbox: _box, tor: _onion);
    expect(c.kinds, [RecipientKind.epicbox, RecipientKind.tor]);
    expect(c.address, _box, reason: 'Epicbox first');
    expect(c.withAddress(RecipientKind.epicbox, null).address, _onion);
    expect(contactFor([c], _onion), c);
  });

  test('a payment to a wallet URL names the contact saved without its endpoint', () {
    final c = Contact(id: '', name: 'Multi', address: 'http://10.0.2.2:3416');
    expect(contactFor([c], 'http://10.0.2.2:3416/v2/foreign'), c);
    expect(contactFor([c], 'http://10.0.2.2:3416/'), c);
    expect(contactFor([c], 'http://10.0.2.2:3417/v2/foreign'), isNull);
  });

  test('one address writes as before; several write each kind and read back', () {
    final one = Meta(
      contacts: [ContactRec(id: '1', name: 'B', address: _box)],
    );
    expect((one.toJson()['contacts'] as List).single, {'id': '1', 'name': 'B', 'address': _box});
    final several = Meta(
      contacts: [ContactRec(id: '1', name: 'B', epicbox: _box, http: _http)],
    );
    final back = Meta.fromJson(jsonDecode(encodeJson(several.toJson()))).contacts.single;
    expect([back.epicbox, back.http, back.tor], [_box, _http, null]);
    expect((several.toJson()['contacts'] as List).single['address'], _box);
  });

  test('a saved contact keeps every address, and a history file brings them back', () async {
    final history = WalletHistory.memory();
    final saved = await history.saveContact(
      Contact(id: '', name: 'Anna', epicbox: _box, http: _http, tor: _onion),
    );
    expect(saved.addresses, [_box, _http, _onion]);
    final payload = history.exportPayload(const [], walletFp: 'fp', appVersion: 't');
    final other = WalletHistory.memory();
    final report = await other.importPayload(payload, const [], walletFp: 'fp');
    expect(report.contactsAdded, 1);
    expect(other.contacts().single.addresses, [_box, _http, _onion]);
    // A contact holding one of the same addresses already is not added twice.
    final again = await other.importPayload(payload, const [], walletFp: 'fp');
    expect(again.contactsAdded, 0);
  });

  test('a contact needs a name; one without an address is a pairing\'s, kept by its id', () async {
    expect(
      () => WalletHistory.memory().saveContact(Contact(id: '', name: ' ')),
      throwsA(anything),
    );
    final history = WalletHistory.memory();
    final paired = await history.saveContact(Contact(id: '', name: 'Northwind'));
    expect(paired.addresses, isEmpty);
    final payload = history.exportPayload(const [], walletFp: 'fp', appVersion: 't');
    final other = WalletHistory.memory();
    expect((await other.importPayload(payload, const [], walletFp: 'fp')).contactsAdded, 1);
    // The pairing names the contact by its id: restored under it, and only once.
    expect(other.contacts().single.id, paired.id);
    expect((await other.importPayload(payload, const [], walletFp: 'fp')).contactsAdded, 0);
  });

  // R33: a contact the device knows by one address gains the kinds the backup adds, by the
  // contacts file's rules, in the archive's own list and in the shared address book.
  for (final shared in [false, true]) {
    final where = shared ? 'shared book' : 'archive';

    test('a backup gives a known contact the address kinds it lacks ($where)', () async {
      final from = WalletHistory.memory();
      await from.saveContact(Contact(id: '', name: 'Anna', epicbox: _box, tor: _onion));
      final payload = from.exportPayload(const [], walletFp: 'fp', appVersion: 't');

      final here = WalletHistory.memory(contacts: shared ? ContactStore.memory() : null);
      final known = await here.saveContact(Contact(id: '', name: 'Anna here', epicbox: _box));
      final report = await here.importPayload(payload, const [], walletFp: 'fp');
      expect(report.contactsAdded, 1, reason: 'the known contact gained a kind');
      final after = here.contacts().single;
      expect(after.id, known.id);
      expect(after.name, 'Anna here', reason: 'nothing saved is changed');
      expect([after.epicbox, after.tor], [_box, _onion]);
      // A second import changes nothing.
      expect((await here.importPayload(payload, const [], walletFp: 'fp')).contactsAdded, 0);
    });

    // R14: the stars travel with the contacts they belong to.
    test('stars travel in the backup to the contacts they became ($where)', () async {
      final from = WalletHistory.memory(contacts: shared ? ContactStore.memory() : null);
      final anna = await from.saveContact(Contact(id: '', name: 'Anna', epicbox: _box));
      await from.saveContact(Contact(id: '', name: 'Bob', http: _http));
      await from.setFavourite(anna.id, true);
      final payload = from.exportPayload(const [], walletFp: 'fp', appVersion: 't');
      expect(payload.favourites, [anna.id]);
      // Read back from the file's JSON, as an import does.
      final read = HistoryPayload.fromJson(jsonDecode(utf8.decode(payload.encode())));

      final here = WalletHistory.memory(contacts: shared ? ContactStore.memory() : null);
      final known = await here.saveContact(Contact(id: '', name: 'Anna', epicbox: _box));
      await here.importPayload(read, const [], walletFp: 'fp');
      expect(here.favourites(), {known.id});
    });
  }

  test('a file without stars stays as older apps wrote it, and older files read', () {
    final payload = WalletHistory.memory().exportPayload(const [], walletFp: 'fp', appVersion: 't');
    expect(payload.toJson().containsKey('favourites'), isFalse);
    expect(payload.toJson()['version'], 2);
    final old = HistoryPayload.fromJson({
      'format': 'wfe-history',
      'version': 1,
      'chain': 'Mainnet',
      'wallet_fp': 'fp',
      'exported_at_unix': 1,
      'app_version': 'old',
      'txs': <Object?>[],
      'contacts': <Object?>[],
    });
    expect(old.favourites, isEmpty);
  });
}
