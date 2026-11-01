// SPDX-License-Identifier: Apache-2.0
// Requests to pair and the address book: a request is dismissed as a stranger's only once the
// book is known. One that came while the book was loading or closed is kept, then listed when
// the book holds its sender and dismissed when it does not. A stranger's request goes to the
// linked device before it is dismissed here.
import 'dart:async';

import 'package:epic_wallet/src/contacts.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/pairing_providers.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final String _anna = 'es${'a' * 50}@epicbox.epiccash.com';
final String _tom = 'es${'t' * 50}@epicbox.epiccash.com';

/// An address book whose first read waits for [open].
class _SlowBook implements ContactBook {
  _SlowBook(this.contacts);

  final List<Contact> contacts;
  final Completer<void> _open = Completer<void>();

  void open() => _open.complete();

  @override
  Future<List<Contact>> list() async {
    await _open.future;
    return [...contacts];
  }

  @override
  Future<Contact> save(Contact contact) async => contact;

  @override
  Future<void> delete(String id) async {}
}

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

void main() {
  late FakeWalletSession session;
  late FakePairing api;

  setUp(() {
    session = FakeWalletSession();
    api = session.pairing..clock = () => DateTime(2026, 11, 1, 12);
  });

  ProviderContainer containerWith(ContactBook book) {
    final c = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => _Open(session)),
        pairingApiProvider.overrideWithValue(api),
        contactBookProvider.overrideWithValue(book),
      ],
    );
    addTearDown(c.dispose);
    c.listen(pairRequestsProvider, (_, _) {});
    return c;
  }

  Future<List<PairRequest>> listed(ProviderContainer c) async {
    await pumpEventQueue();
    final shown = await c.read(pairRequestsProvider.future);
    await pumpEventQueue();
    return shown;
  }

  final anna = Contact(id: 'c1', name: 'Anna', epicbox: _anna);

  test('the book loaded first: a contact\'s request is listed, a stranger\'s dismissed', () async {
    final book = _SlowBook([anna])..open();
    final c = containerWith(book);
    await listed(c);
    final a = api.receiveRequest(from: _anna, name: 'Anna')!;
    final t = api.receiveRequest(from: _tom, name: 'Tom')!;
    expect((await listed(c)).map((r) => r.id), [a.id]);
    expect(api.dismissedRequests, {t.id});
  });

  test('a request before the book loads is kept; the book then holds its sender: listed', () async {
    final book = _SlowBook([anna]);
    final c = containerWith(book);
    final a = api.receiveRequest(from: _anna, name: 'Anna')!;
    await pumpEventQueue();
    expect(api.dismissedRequests, isEmpty, reason: 'the book is not known yet');
    book.open();
    expect((await listed(c)).map((r) => r.id), [a.id]);
    expect(api.dismissedRequests, isEmpty);
  });

  test('a request before the book loads, the book without its sender: dismissed once loaded', () async {
    final book = _SlowBook(const []);
    final c = containerWith(book);
    final t = api.receiveRequest(from: _tom, name: 'Tom')!;
    await pumpEventQueue();
    expect(api.dismissedRequests, isEmpty);
    book.open();
    expect(await listed(c), isEmpty);
    expect(api.dismissedRequests, {t.id});
  });

  test('the shared book closed to this wallet: nothing is dismissed or listed', () async {
    session.contactsAvailableValue = false;
    final c = containerWith(_SlowBook(const [])..open());
    final t = api.receiveRequest(from: _tom, name: 'Tom')!;
    expect(await listed(c), isEmpty);
    expect(api.dismissedRequests, isEmpty);
    expect((await api.requests()).single.id, t.id);
  });

  test('a stranger\'s request goes to the linked device before it is dismissed here', () async {
    final c = containerWith(_SlowBook(const [])..open());
    final seen = <(String, bool)>[];
    c.read(requestPassOnProvider).run = (r) async {
      // Still there when it is passed on: the forward carries the whole request.
      seen.add((r.id, (await api.requests()).any((q) => q.id == r.id)));
    };
    await listed(c);
    final t = api.receiveRequest(from: _tom, name: 'Tom')!;
    await listed(c);
    expect(seen, [(t.id, true)]);
    expect(api.dismissedRequests, {t.id});
  });

  test('a request event counts as a contact\'s only with the book known', () {
    final e = PairingEvent(PairingEventKind.requested, requestId: '1', sender: _anna, name: 'Anna');
    expect(requestFromContact(null, e), isFalse);
    expect(requestFromContact({epicboxKey(_anna)}, e), isTrue);
    expect(requestFromContact({epicboxKey(_tom)}, e), isFalse);
    expect(phoneContactKeys(const AsyncLoading<List<Contact>>()), isNull);
    expect(phoneContactKeys(AsyncData([anna]), closed: true), isNull);
    expect(phoneContactKeys(AsyncData([anna])), {epicboxKey(_anna)});
  });
}
