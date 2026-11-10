// SPDX-License-Identifier: Apache-2.0
// The app's files sealed at rest (lib/src/sealed_file.dart, MetaStore sealed, ContactStore
// sealed): header checks, the address book's AES-GCM and its associated data, per-wallet wraps,
// copy-then-switch migration with a kill at every step, and the merge of a plain file an older
// build changed. A stand-in sealer plays LEPIC's sealAppData (its own crypto is LEPIC's, tested
// there). Synthetic data.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/sealed_file.dart';
import 'package:epic_wallet/src/wallet_service.dart' show WalletError;
import 'package:flutter_test/flutter_test.dart';

const _a = 'esWNvLomAJ2SHT6CU1F4ok2URGQnmUmCAp9XNwEP4N8JS4Ve8qcx@epicbox.example.com';
const _b = 'es7jHnbVkZzE2UGWUkzWrc4y4VoKZbg7FBaPUo2vXhJpe4jgXAA7@epicbox.example.com';
const _idA = '0123456789abcdef0123456789abcdef';
const _idB = 'fedcba9876543210fedcba9876543210';
const _idA2 = '00000000000000000000000000000001';

/// sealAppData's stand-in: a marker, the seed's byte, the payload masked by it, a checksum.
/// Another seed's file is `foreign`, a changed one `damaged`, anything else `notOurs`.
class FakeSealer implements AppDataSealer {
  FakeSealer(this.seed);

  final int seed;

  static int _sum(List<int> b) => b.fold(0, (a, x) => (a + x) & 0xff);

  @override
  Future<Uint8List> seal(Uint8List payload) async =>
      Uint8List.fromList([0x57, seed, for (final b in payload) b ^ seed, _sum(payload)]);

  @override
  Future<Uint8List> open(Uint8List file) async {
    if (file.length < 3 || file[0] != 0x57) throw const SealedOpenError(SealedOpenProblem.notOurs);
    if (file[1] != seed) throw const SealedOpenError(SealedOpenProblem.foreign);
    final body = Uint8List.fromList([for (final b in file.sublist(2, file.length - 1)) b ^ seed]);
    if (_sum(body) != file.last) throw const SealedOpenError(SealedOpenProblem.damaged);
    return body;
  }
}

class _Killed implements Exception {}

/// Stops the next write to a file ending in [name] at [step], as a kill would.
void killAt(String name, String step) {
  SealedFile.killPoint = (path, s) {
    if (path.endsWith(name) && s == step) {
      SealedFile.killPoint = null;
      throw _Killed();
    }
  };
}

const _steps = ['tmp-written', 'verified', 'switched'];

void main() {
  late Directory tmp;
  final seedA = FakeSealer(0x5a);
  final seedB = FakeSealer(0x3c);

  setUp(() async {
    ContactStore.forgetAll();
    SealedFile.killPoint = null;
    tmp = await Directory.systemTemp.createTemp('sealed_app_files_');
  });
  tearDown(() async {
    ContactStore.forgetAll();
    SealedFile.killPoint = null;
    await tmp.delete(recursive: true);
  });

  File at(String name) => File('${tmp.path}/$name');

  group('sealed payloads', () {
    test('open to what was sealed, and only as their kind and wallet', () async {
      final path = '${tmp.path}/x.sealed';
      final p = SealedPayload(kind: sealedKindMeta, walletId: _idA, plain: const PlainRecord(size: 3, sha256Hex: 'ab'), body: utf8.encode('{"v":1}'));
      await SealedFile.writeSealed(path, seedA, p);
      final back = (await SealedFile.readSealed(path, seedA, kind: sealedKindMeta, walletId: _idA))!;
      expect(utf8.decode(back.body), '{"v":1}');
      expect(back.plain, const PlainRecord(size: 3, sha256Hex: 'ab'));
      expect(File(SealedFile.tmpOf(path)).existsSync(), isFalse);
      // Another kind, another wallet id, another seed: refused.
      Future<void> refused(Future<Object?> f, SealedOpenProblem why) =>
          expectLater(f, throwsA(isA<SealedOpenError>().having((e) => e.problem, 'problem', why)));
      await refused(SealedFile.readSealed(path, seedA, kind: sealedKindContactsKey, walletId: _idA), SealedOpenProblem.notOurs);
      await refused(SealedFile.readSealed(path, seedA, kind: sealedKindMeta, walletId: _idB), SealedOpenProblem.notOurs);
      await refused(SealedFile.readSealed(path, seedB, kind: sealedKindMeta, walletId: _idA), SealedOpenProblem.foreign);
      expect(isSealedAppPayload(await seedA.open(File(path).readAsBytesSync())), isTrue);
      expect(isSealedAppPayload(utf8.encode('{"format":"wfe-history"}')), isFalse);
    });

    test('the address book opens only with its key, its version and its associated data', () async {
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      final payload = Uint8List.fromList(utf8.encode('book'));
      final sealed = await sealContactsBook(key, payload);
      expect(await openContactsBook(key, sealed), payload);
      expect(utf8.decode(sealed, allowMalformed: true), isNot(contains('book')));
      final otherKey = Uint8List.fromList(List.generate(32, (i) => 31 - i));
      await expectLater(openContactsBook(otherKey, sealed), throwsA(isA<SealedOpenError>()));
      // The version byte is bound by the associated data: a file claiming version 0 fails.
      final older = Uint8List.fromList(sealed)..[4] = 0;
      await expectLater(
        openContactsBook(key, older),
        throwsA(isA<SealedOpenError>().having((e) => e.problem, 'problem', SealedOpenProblem.damaged)),
      );
      final newer = Uint8List.fromList(sealed)..[4] = 2;
      await expectLater(
        openContactsBook(key, newer),
        throwsA(isA<SealedOpenError>().having((e) => e.problem, 'problem', SealedOpenProblem.newer)),
      );
      await expectLater(openContactsBook(key, await seedA.seal(payload)), throwsA(isA<SealedOpenError>()));
    });
  });

  group('wfe_meta', () {
    const plainText = '{"version":1,"notes":{"tx-1":"Rent October"}}';

    Future<MetaStore> openA() => MetaStore.open(tmp.path, sealer: seedA, walletId: _idA);

    test('is sealed beside the plain file, which stays as it was', () async {
      at(metaFileName).writeAsStringSync(plainText);
      final store = await openA();
      expect(store.snapshot.notes, {'tx-1': 'Rent October'});
      expect(at(metaSealedFileName).existsSync(), isTrue);
      expect(at(metaFileName).readAsStringSync(), plainText);
      expect(String.fromCharCodes(at(metaSealedFileName).readAsBytesSync()), isNot(contains('Rent')));
      await store.update((m) => m.notes['tx-2'] = 'Gift');
      store.close();
      expect(at(metaFileName).readAsStringSync(), plainText);
      final again = await openA();
      expect(again.snapshot.notes, {'tx-1': 'Rent October', 'tx-2': 'Gift'});
      again.close();
    });

    test('a new wallet writes only the sealed file', () async {
      final store = await openA();
      expect(at(metaSealedFileName).existsSync(), isFalse);
      await store.update((m) => m.notes['k'] = 'n');
      expect(at(metaSealedFileName).existsSync(), isTrue);
      expect(at(metaFileName).existsSync(), isFalse);
      store.close();
    });

    for (final step in _steps) {
      test('a kill at "$step" of the first sealing loses nothing and the next open completes', () async {
        at(metaFileName).writeAsStringSync(plainText);
        killAt(metaSealedFileName, step);
        await expectLater(openA(), throwsA(isA<_Killed>()));
        expect(at(metaFileName).readAsStringSync(), plainText);
        final store = await openA();
        expect(store.snapshot.notes, {'tx-1': 'Rent October'});
        expect(at(metaSealedFileName).existsSync(), isTrue);
        expect(File(SealedFile.tmpOf(at(metaSealedFileName).path)).existsSync(), isFalse);
        store.close();
      });

      test('a kill at "$step" of a later change keeps the note before it', () async {
        final store = await openA();
        await store.update((m) => m.notes['a'] = 'first');
        killAt(metaSealedFileName, step);
        await expectLater(store.update((m) => m.notes['b'] = 'second'), throwsA(isA<_Killed>()));
        store.close();
        final again = await openA();
        expect(again.snapshot.notes['a'], 'first');
        // The note written up to the kill is there only if the switch happened.
        expect(again.snapshot.notes.containsKey('b'), step == 'switched');
        again.close();
      });
    }

    test('a plain file an older build changed is merged in: only added, the sealed side wins', () async {
      at(metaFileName).writeAsStringSync(plainText);
      final store = await openA();
      await store.update((m) => m.notes['tx-1'] = 'Rent (edited)');
      store.close();
      // An older build, after a rollback, writes the plain file.
      at(metaFileName).writeAsStringSync('{"version":1,"notes":{"tx-1":"Rent October","tx-9":"Old build note"}}');
      final again = await openA();
      expect(again.snapshot.notes, {'tx-1': 'Rent (edited)', 'tx-9': 'Old build note'});
      again.close();
      // Merged once: the record moved, so an edit after it is not undone by the same plain file.
      final third = await openA();
      await third.update((m) => m.notes.remove('tx-9'));
      third.close();
      final fourth = await openA();
      expect(fourth.snapshot.notes, {'tx-1': 'Rent (edited)'});
      fourth.close();
    });

    test('another kind of sealed file is never opened or overwritten as the archive', () async {
      // A wrap of the address book's key, put where the archive goes.
      await SealedFile.writeSealed(
        at(metaSealedFileName).path,
        seedA,
        SealedPayload(kind: sealedKindContactsKey, walletId: _idA, body: utf8.encode('AAAA')),
      );
      final before = at(metaSealedFileName).readAsBytesSync();
      final store = await openA();
      expect(store.readOnly, isTrue);
      await expectLater(store.update((m) => m.notes['x'] = 'y'), throwsA(isA<WalletError>()));
      expect(at(metaSealedFileName).readAsBytesSync(), before);
      store.close();
    });

    test('another wallet\'s archive is never overwritten', () async {
      final b = await MetaStore.open(tmp.path, sealer: seedB, walletId: _idA);
      await b.update((m) => m.notes['x'] = 'theirs');
      b.close();
      final before = at(metaSealedFileName).readAsBytesSync();
      final store = await openA();
      expect(store.readOnly, isTrue);
      expect(store.snapshot.notes, isEmpty);
      store.close();
      expect(at(metaSealedFileName).readAsBytesSync(), before);
    });

    test('a delete removes the sealed archive too', () async {
      at(metaFileName).writeAsStringSync(plainText);
      (await openA()).close();
      await MetaStore.deleteFiles(tmp.path);
      expect(at(metaSealedFileName).existsSync(), isFalse);
      expect(at(metaFileName).existsSync(), isFalse);
    });
  });

  group('the address book', () {
    const plainBook = '{"version":1,"contacts":[{"id":"c1","name":"Anna","epicbox":"$_a"}]}';
    File wrap(String id) => File('${tmp.path}/$contactsKeysDirName/$id.key');
    File book() => at(contactsSealedFileName);

    Future<ContactStore> openAs(String id, FakeSealer s) => ContactStore.openSealed(tmp.path, id, s);

    test('is sealed from contacts.json, which stays as it was, with this wallet\'s wrap', () async {
      at(contactsFileName).writeAsStringSync(plainBook);
      final s = await openAs(_idA, seedA);
      expect(s.available, isTrue);
      expect([for (final c in s.list()) c.name], ['Anna']);
      expect(book().existsSync(), isTrue);
      expect(wrap(_idA).existsSync(), isTrue);
      expect(String.fromCharCodes(book().readAsBytesSync()), isNot(contains('Anna')));
      await s.save(const ContactFields(name: 'Ben', epicbox: _b));
      expect(at(contactsFileName).readAsStringSync(), plainBook);
      await s.detach(_idA, seedA);
      expect(s.list(), isEmpty);
      ContactStore.forgetAll();
      final again = await openAs(_idA, seedA);
      expect([for (final c in again.list()) c.name], ['Anna', 'Ben']);
    });

    test('opens from any wallet with a wrap; a wallet without one gets it while another is open', () async {
      at(contactsFileName).writeAsStringSync(plainBook);
      final s = await openAs(_idA, seedA);
      await openAs(_idB, seedB);
      expect(wrap(_idB).existsSync(), isTrue);
      await s.detach(_idA, seedA);
      await s.detach(_idB, seedB);
      ContactStore.forgetAll();
      final byB = await openAs(_idB, seedB);
      expect(byB.available, isTrue);
      expect([for (final c in byB.list()) c.name], ['Anna']);
    });

    group('a book per network (a phone opens one network\'s wallet at a time)', () {
      const testId = 'legacy-floonet';
      String own() => contactsDirOf(tmp.path, 'floonet');
      File ownWrap(String id) => File('${own()}/$contactsKeysDirName/$id.key');

      test('mainnet keeps the app folder; another network gets a folder of its own', () {
        expect(contactsDirOf(tmp.path, 'mainnet'), tmp.path);
        expect(contactsDirOf(tmp.path, 'floonet'), isNot(tmp.path));
        expect(contactsDirOf(tmp.path, 'floonet'), startsWith(tmp.path));
      });

      test('a test-network wallet opening after a mainnet wallet closed finds its own book open', () async {
        at(contactsFileName).writeAsStringSync(plainBook);
        await (await openAs(_idA, seedA)).detach(_idA, seedA);
        ContactStore.forgetAll();
        // The bug: in the one shared book a wallet without a wrap found it closed.
        expect((await openAs(testId, seedB)).available, isFalse);
        await ContactStore.moveFromShared(tmp.path, own(), testId);
        final s = await ContactStore.openSealed(own(), testId, seedB);
        expect(s.available, isTrue);
        expect(s.list(), isEmpty, reason: 'mainnet contacts stay in the mainnet book');
        expect(ownWrap(testId).existsSync(), isTrue);
        await s.save(const ContactFields(name: 'Ben', epicbox: _b));
        await s.detach(testId, seedB);
        ContactStore.forgetAll();
        expect([for (final c in (await openAs(_idA, seedA)).list()) c.name], ['Anna']);
      });

      test('a test-network wallet with a wrap in the shared book takes the book along, sealed, and leaves it to mainnet', () async {
        at(contactsFileName).writeAsStringSync(plainBook);
        final s = await openAs(_idA, seedA);
        await openAs(testId, seedB);
        await s.detach(_idA, seedA);
        await s.detach(testId, seedB);
        ContactStore.forgetAll();
        final sealedBook = book().readAsBytesSync();
        await ContactStore.moveFromShared(tmp.path, own(), testId);
        expect(File('${own()}/$contactsSealedFileName').readAsBytesSync(), sealedBook);
        expect(wrap(testId).existsSync(), isFalse);
        expect(File('${own()}/$contactsFileName').existsSync(), isFalse);
        final t = await ContactStore.openSealed(own(), testId, seedB);
        expect([for (final c in t.list()) c.name], ['Anna']);
        await t.save(const ContactFields(name: 'Ben', epicbox: _b));
        // Again: the book in its folder stays as it is.
        await ContactStore.moveFromShared(tmp.path, own(), testId);
        expect([for (final c in t.list()) c.name], ['Anna', 'Ben']);
        final m = await openAs(_idA, seedA);
        expect([for (final c in m.list()) c.name], ['Anna']);
      });

      test('a shared book only a test-network wallet could open goes with its last wrap, so a mainnet wallet starts one', () async {
        at(contactsFileName).writeAsStringSync(plainBook);
        await (await openAs(testId, seedB)).detach(testId, seedB);
        ContactStore.forgetAll();
        await ContactStore.moveFromShared(tmp.path, own(), testId);
        expect(book().existsSync(), isFalse);
        expect((await ContactStore.openSealed(own(), testId, seedB)).list().single.name, 'Anna');
        final m = await openAs(_idA, seedA);
        expect(m.available, isTrue);
        expect(m.list().single.name, 'Anna', reason: 'sealed again from contacts.json');
      });
    });

    test('a restored wallet of the same phrase opens another id\'s wrap and gets its own', () async {
      at(contactsFileName).writeAsStringSync(plainBook);
      await (await openAs(_idA, seedA)).detach(_idA, seedA);
      ContactStore.forgetAll();
      final s = await openAs(_idA2, seedA);
      expect(s.available, isTrue);
      expect(wrap(_idA2).existsSync(), isTrue);
    });

    test('is closed, not empty, for a wallet without a wrap, writes nothing, and opens once a wallet with one does', () async {
      at(contactsFileName).writeAsStringSync(plainBook);
      await (await openAs(_idA, seedA)).detach(_idA, seedA);
      ContactStore.forgetAll();
      final bookBefore = book().readAsBytesSync();
      final s = await openAs(_idB, seedB);
      expect(s.available, isFalse);
      expect(s.list(), isEmpty);
      await expectLater(s.save(const ContactFields(name: 'Ben', epicbox: _b)), throwsA(isA<WalletError>()));
      expect(book().readAsBytesSync(), bookBefore);
      expect(wrap(_idB).existsSync(), isFalse);
      // A opens: the book opens, and B, open meanwhile, gets its wrap.
      await openAs(_idA, seedA);
      expect(s.available, isTrue);
      expect(wrap(_idB).existsSync(), isTrue);
    });

    test('a deleted wallet loses only its wrap; the last one takes the book with it', () async {
      at(contactsFileName).writeAsStringSync(plainBook);
      final s = await openAs(_idA, seedA);
      await openAs(_idB, seedB);
      await s.detach(_idA, seedA);
      await s.detach(_idB, seedB);
      await ContactStore.removeWalletKey(tmp.path, _idA);
      expect(wrap(_idA).existsSync(), isFalse);
      expect(wrap(_idB).existsSync(), isTrue);
      expect(book().existsSync(), isTrue);
      ContactStore.forgetAll();
      expect((await openAs(_idB, seedB)).list().single.name, 'Anna');
      await (await openAs(_idB, seedB)).detach(_idB, seedB);
      await ContactStore.removeWalletKey(tmp.path, _idB);
      expect(book().existsSync(), isFalse);
      expect(at(contactsFileName).readAsStringSync(), plainBook);
    });

    for (final name in ['.key', contactsSealedFileName]) {
      for (final step in _steps) {
        test('a kill at "$step" of ${name == '.key' ? 'the wrap' : 'the book'} on the first unlock loses no contact', () async {
          at(contactsFileName).writeAsStringSync(plainBook);
          killAt(name, step);
          await expectLater(openAs(_idA, seedA), throwsA(isA<_Killed>()));
          expect(at(contactsFileName).readAsStringSync(), plainBook);
          ContactStore.forgetAll();
          final s = await openAs(_idA, seedA);
          expect(s.available, isTrue);
          expect([for (final c in s.list()) c.name], ['Anna']);
          expect(book().existsSync(), isTrue);
          expect(wrap(_idA).existsSync(), isTrue);
          expect(File(SealedFile.tmpOf(book().path)).existsSync(), isFalse);
          // The book opens with the wrap on disk, from another wallet too.
          await openAs(_idB, seedB);
          await s.detach(_idA, seedA);
          await s.detach(_idB, seedB);
          ContactStore.forgetAll();
          expect((await openAs(_idB, seedB)).list().single.name, 'Anna');
        });
      }
    }

    test('a contacts.json an older build changed is merged in: only added, the sealed side wins', () async {
      at(contactsFileName).writeAsStringSync(plainBook);
      final s = await openAs(_idA, seedA);
      final anna = s.list().single;
      await s.save(ContactFields(id: anna.id, name: 'Anna K', epicbox: _a));
      await s.detach(_idA, seedA);
      at(contactsFileName).writeAsStringSync(
        '{"version":1,"contacts":[{"id":"c1","name":"Anna","epicbox":"$_a"},{"id":"c2","name":"Old build","epicbox":"$_b"}]}',
      );
      ContactStore.forgetAll();
      final again = await openAs(_idA, seedA);
      expect([for (final c in again.list()) c.name], ['Anna K', 'Old build']);
      // Once merged, a delete sticks.
      await again.delete('c2');
      await again.detach(_idA, seedA);
      ContactStore.forgetAll();
      expect([for (final c in (await openAs(_idA, seedA)).list()) c.name], ['Anna K']);
    });
  });
}
