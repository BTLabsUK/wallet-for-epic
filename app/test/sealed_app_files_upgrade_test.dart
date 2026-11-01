// SPDX-License-Identifier: Apache-2.0
// The app's files of a real 26.10.24-r2 data folder (test/fixtures/install_26_10_24_r2) on their
// first unlock by this build: each wallet's wfe_meta.json and the shared contacts.json are sealed
// beside the plain files, which stay byte for byte as they were. The fixture's archive and book
// are empty, so a copy with a note and a contact written in, as 26.10.24-r2 writes them, is run
// too. Synthetic data.
import 'dart:io';

import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/sealed_file.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sealed_app_files_test.dart' show FakeSealer;

const _fixture = 'test/fixtures/install_26_10_24_r2/home/.epic_cash_desktop';
const _second = '0123456789abcdef0123456789abcdef';

void _copy(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final e in from.listSync()) {
    final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (e is Directory) {
      _copy(e, Directory('${to.path}/$name'));
    } else if (e is File) {
      e.copySync('${to.path}/$name');
    }
  }
}

void main() {
  late Directory data;
  final seed1 = FakeSealer(0x5a);
  final seed2 = FakeSealer(0x3c);

  setUp(() async {
    ContactStore.forgetAll();
    data = await Directory.systemTemp.createTemp('sealed_upgrade_');
    _copy(Directory(_fixture), data);
  });
  tearDown(() async {
    ContactStore.forgetAll();
    await data.delete(recursive: true);
  });

  String wallet1() => '${data.path}/wallets/mainnet';
  String wallet2() => '${data.path}/wallets/$_second/mainnet';

  Future<void> unlockBoth() async {
    for (final (dir, id, s) in [
      (wallet1(), sealedWalletId(null, 'mainnet'), seed1),
      (wallet2(), _second, seed2),
    ]) {
      final book = await ContactStore.openSealed(data.path, id, s);
      expect(book.available, isTrue);
      (await MetaStore.open(dir, sealer: s, walletId: id)).close();
    }
  }

  test('the fixture as 26.10.24-r2 left it', () async {
    final meta1 = File('${wallet1()}/$metaFileName').readAsBytesSync();
    final book = File('${data.path}/$contactsFileName').readAsBytesSync();
    await unlockBoth();
    expect(File('${wallet1()}/$metaFileName').readAsBytesSync(), meta1);
    expect(File('${data.path}/$contactsFileName').readAsBytesSync(), book);
    expect(File('${wallet1()}/$metaSealedFileName').existsSync(), isTrue);
    // The second wallet had no archive: nothing to seal until it has a note.
    expect(File('${wallet2()}/$metaSealedFileName').existsSync(), isFalse);
    expect(File('${data.path}/$contactsSealedFileName').existsSync(), isTrue);
    expect(File('${data.path}/$contactsKeysDirName/legacy-mainnet.key').existsSync(), isTrue);
    expect(File('${data.path}/$contactsKeysDirName/$_second.key').existsSync(), isTrue);
  });

  test('with a note and a contact, as 26.10.24-r2 writes them', () async {
    const note = '{"version":1,"notes":{"slate-1":"Rent"},"contacts":[],"annotations":{},"records":[],"block_times":{},"kernel_heights":{}}';
    const contacts = '{"version":1,"contacts":[{"id":"c1","name":"Anna","epicbox":"esWNvLomAJ2SHT6CU1F4ok2URGQnmUmCAp9XNwEP4N8JS4Ve8qcx@epicbox.example.invalid","note":"Flatmate"}]}';
    File('${wallet1()}/$metaFileName').writeAsStringSync(note);
    File('${data.path}/$contactsFileName').writeAsStringSync(contacts);
    await unlockBoth();
    ContactStore.forgetAll();
    // The first wallet again: sealed files only are read.
    final meta = await MetaStore.open(wallet1(), sealer: seed1, walletId: 'legacy-mainnet');
    expect(meta.snapshot.notes, {'slate-1': 'Rent'});
    meta.close();
    final book = await ContactStore.openSealed(data.path, _second, seed2);
    expect([for (final c in book.list()) (c.name, c.note)], [('Anna', 'Flatmate')]);
    expect(File('${wallet1()}/$metaFileName').readAsStringSync(), note);
    expect(File('${data.path}/$contactsFileName').readAsStringSync(), contacts);
    for (final f in [File('${wallet1()}/$metaSealedFileName'), File('${data.path}/$contactsSealedFileName')]) {
      final text = String.fromCharCodes(f.readAsBytesSync());
      expect(text, isNot(contains('Rent')));
      expect(text, isNot(contains('Anna')));
    }
  });
}
