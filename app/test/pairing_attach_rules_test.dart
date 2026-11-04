// SPDX-License-Identifier: Apache-2.0
// Attaching a finished pairing to a contact the user picked (26.10.25): one rule for every
// contact. A contact holds one Epicbox address and "Verified" is only ever about it: no
// Epicbox address, the pairing's fills it; the same key (any relay), it attaches; another one,
// or one the pairing cannot confirm, is refused and never overwritten. A contact with a pairing
// already attaches through the key check (RFC 7.8).
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/pairing_text.dart' show isUnnamed, sameNamedContact, unnamedPeerName;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _key = 'esAaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _otherKey = 'esBbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _http = 'https://wallet.example.org';
const _tor = 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcd.onion';

Matcher _refused = throwsA(isA<WalletError>().having(pairingFailureOf, 'failure', PairingFailure.otherAddress));

void main() {
  late FakeWalletSession session;
  late FakePairing api;

  setUp(() {
    session = FakeWalletSession();
    api = session.pairing;
  });

  Future<Contact> save(Contact c) => session.saveContact(contact: c);
  Contact book(String id) => session.contactsValue.singleWhere((c) => c.id == id);

  test('1: no Epicbox address: it attaches; the proven address is the app\'s to write at Verified, HTTP and Tor stay', () async {
    final c = await save(Contact(id: '', name: 'Ana', http: _http, tor: _tor));
    final r = api.seedPaired(name: 'Ana', paymentsAddress: '$_key@epicbox.example.org');

    final attached = await api.attach(r.id, c.id, contactAddress: c.epicbox);

    expect(attached.contactId, c.id);
    expect((book(c.id).epicbox, book(c.id).http, book(c.id).tor), (null, _http, _tor));
    expect(pairingVouchesFor(attached, book(c.id).epicbox), isTrue);
  });

  test('2: the same Epicbox key at another relay: it attaches, verified, the address kept', () async {
    final c = await save(Contact(id: '', name: 'Ana', epicbox: '$_key@relay.example.net'));
    final r = api.seedPaired(name: 'Ana', paymentsAddress: '$_key@epicbox.example.org');

    final attached = await api.attach(r.id, c.id, contactAddress: c.epicbox);

    expect(attached.contactId, c.id);
    expect(book(c.id).epicbox, '$_key@relay.example.net');
    expect(pairingVouchesFor(attached, book(c.id).epicbox), isTrue);
  });

  test('3: another Epicbox address: refused, nothing attached or overwritten', () async {
    final c = await save(Contact(id: '', name: 'BT Labs', epicbox: '$_otherKey@epicbox.example.org'));
    final r = api.seedPaired(name: 'the owner PC', paymentsAddress: '$_key@epicbox.example.org');

    await expectLater(api.attach(r.id, c.id, contactAddress: c.epicbox), _refused);

    expect((await api.pairing(r.id))!.contactId, isNull);
    expect(book(c.id).epicbox, '$_otherKey@epicbox.example.org');
  });

  test('3: a pairing that brought no Epicbox address cannot confirm the one the contact has', () {
    final c = Contact(id: 'c1', name: 'Ana', epicbox: '$_key@epicbox.example.org');
    final r = PairingRecord(id: 'p1', state: PairingState.verified, way: PairingWay.link, inviter: false, createdAt: DateTime(2026, 10, 1));

    expect(() => contactForPairing(c, r), _refused);
    expect(contactForPairing(Contact(id: 'c2', name: 'Ana', http: _http), r), isNull, reason: 'attaches, nothing to fill');
  });

  test('4: a contact with a pairing already: no silent replace, the key check decides', () async {
    final c = await save(Contact(id: '', name: 'Ana', epicbox: '$_key@epicbox.example.org'));
    final old = api.seedPaired(name: 'Ana', contactId: c.id, paymentsAddress: '$_key@epicbox.example.org');
    final other = api.seedPaired(name: 'Ana', paymentsAddress: '$_otherKey@epicbox.example.org');
    final again = api.seedPaired(name: 'Ana', paymentsAddress: '$_key@epicbox.example.org');

    // Someone else's pairing is refused by the address, the old one untouched.
    await expectLater(api.attach(other.id, c.id, contactAddress: c.epicbox), _refused);
    expect((await api.pairing(old.id))!.contactId, c.id);

    // The same wallet again (a restore): the key check runs, its mismatch asks the user.
    api.keyCheckFindsOldKeys = false;
    final changed = await api.attach(again.id, c.id, contactAddress: c.epicbox);
    expect(changed.state, PairingState.keysChanged);
  });

  test('Verified only on the Epicbox address the pairing delivered', () {
    final r = PairingRecord(
      id: 'p1',
      state: PairingState.verified,
      way: PairingWay.link,
      inviter: false,
      createdAt: DateTime(2026, 10, 1),
      paymentsAddress: '$_key@epicbox.example.org',
    );
    expect(pairingVouchesFor(r, '$_key@other.example.net'), isTrue);
    expect(pairingVouchesFor(r, '$_otherKey@epicbox.example.org'), isFalse);
    expect(pairingVouchesFor(r, null), isTrue, reason: 'no Epicbox address to mark');
    final none = PairingRecord(id: 'p2', state: PairingState.verified, way: PairingWay.link, inviter: false, createdAt: DateTime(2026, 10, 1));
    expect(pairingVouchesFor(none, '$_key@epicbox.example.org'), isFalse);
  });

  test('the same-name offer never names a contact attaching would refuse', () {
    final r = PairingRecord(id: 'p1', state: PairingState.verified, way: PairingWay.link, inviter: false, createdAt: DateTime(2026, 10, 1), name: 'BT Labs');
    final named = Contact(id: 'c1', name: 'BT Labs', epicbox: '$_otherKey@epicbox.example.org');
    expect(sameNamedContact<Contact>(r, [named], (c) => c.name, paired: (_) => false, epicboxOf: (c) => c.epicbox), isNull);
    final bare = Contact(id: 'c2', name: 'BT Labs');
    expect(sameNamedContact<Contact>(r, [bare], (c) => c.name, paired: (_) => false, epicboxOf: (c) => c.epicbox), bare);
  });

  test('the no-name word is no name, and no contact is suggested by it', () {
    expect(unnamedPeerName, 'BT Wallet');
    expect([isUnnamed(null), isUnnamed(''), isUnnamed('  '), isUnnamed(' BT Wallet '), isUnnamed(unnamedPeerName)], everyElement(isTrue));
    expect([isUnnamed('BT Labs'), isUnnamed('bt wallet'), isUnnamed('BT Wallet 2')], everyElement(isFalse));
    final r = PairingRecord(id: 'p2', state: PairingState.verified, way: PairingWay.link, inviter: false, createdAt: DateTime(2026, 10, 1), name: unnamedPeerName);
    final same = Contact(id: 'c3', name: 'BT Wallet');
    expect(sameNamedContact<Contact>(r, [same], (c) => c.name, paired: (_) => false, epicboxOf: (c) => c.epicbox), isNull);
  });
}
