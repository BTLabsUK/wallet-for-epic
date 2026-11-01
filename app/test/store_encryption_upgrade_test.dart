// SPDX-License-Identifier: Apache-2.0
// The first unlock of a 26.10.23 install (test/fixtures/install_26_10_23) and of a real
// 26.10.24-r2 data folder (test/fixtures/install_26_10_24_r2) by the build that encrypts the
// wallet records: the test the install contract names for that change
// (tools/install-contract.json, docs/install-contract.md).
//
// LEPIC's copy-then-switch of the database runs here as [_FakeLepicOpen], the file steps of
// its migration on a stand-in database (the real one is tested in LEPIC); the app's own files
// are sealed by the real MetaStore and ContactStore under a stand-in sealer. Checked: every file
// the update must keep is kept, byte for byte where it is never written again; the new file set
// is there; a rollback to the plain build and back finds everything; a kill at any step of the
// first open leaves a folder the next open completes; a second app process on the same folder
// waits for the address book or leaves it closed, never writing it at the same time.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart' show lepicAfterRollbackPrefix, lepicEncryptedStoreFile, lepicPlainStoreFile, lepicPreEncryptionFile, lepicStoreCheckFile;
import 'package:epic_wallet/src/sealed_file.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sealed_app_files_test.dart' show FakeSealer;

const _second = '0123456789abcdef0123456789abcdef';
final _sep = Platform.pathSeparator;

// LEPIC's names in a wallet's `lepic` folder.
const _plain = lepicPlainStoreFile;
const _enc = lepicEncryptedStoreFile;
const _check = lepicStoreCheckFile;
const _tmp = '$lepicEncryptedStoreFile.tmp';
const _pre = lepicPreEncryptionFile;

class _Killed implements Exception {
  const _Killed(this.at);
  final String at;
}

/// The file steps of LEPIC's open (§9.2, §9.4) on a stand-in database: "encryption" is a XOR
/// under the wallet's key byte. [killAt] stops it at a step as a kill would; [fail] makes the
/// copy fail (disk full) so the session stays on the plain file.
class _FakeLepicOpen {
  _FakeLepicOpen(this.key);

  final int key;
  String? killAt;
  bool fail = false;
  final progress = <StoreMigrationProgress>[];
  bool restoreScanRequired = false;

  void _step(String name) {
    if (killAt == name) {
      killAt = null;
      throw _Killed(name);
    }
  }

  Uint8List _seal(List<int> b) => Uint8List.fromList([for (final x in b) x ^ key]);

  StoreOpenOutcome open(String lepicDir, {int rows = 3}) {
    File f(String n) => File('$lepicDir$_sep$n');
    if (f(_enc).existsSync() && f(_check).existsSync()) {
      if (f(_check).readAsStringSync() != 'check-$key') {
        throw const WalletError(kind: WalletErrorKind.wrongKey, message: 'key check');
      }
      final p = f(_plain);
      if (p.existsSync()) {
        final source = f('$_enc.from').existsSync() ? f('$_enc.from').readAsStringSync() : null;
        if (source == base64.encode(p.readAsBytesSync())) {
          // A kill between the switch and the rename: finish the rename.
          _setAside(lepicDir);
        } else {
          // A plain file an older build made after a rollback.
          p.renameSync('$lepicDir$_sep$lepicAfterRollbackPrefix${DateTime.now().millisecondsSinceEpoch ~/ 1000}');
          for (final x in ['-wal', '-shm']) {
            if (f('$_plain$x').existsSync()) f('$_plain$x').deleteSync();
          }
          restoreScanRequired = true;
        }
      }
      return StoreOpenOutcome.encrypted;
    }
    if (!f(_plain).existsSync()) {
      f(_enc).writeAsBytesSync(_seal(utf8.encode('new')));
      f(_check).writeAsStringSync('check-$key');
      return StoreOpenOutcome.encrypted;
    }
    for (final x in ['', '-wal', '-shm']) {
      if (f('$_tmp$x').existsSync()) f('$_tmp$x').deleteSync();
    }
    final source = [...f(_plain).readAsBytesSync(), if (f('$_plain-wal').existsSync()) ...f('$_plain-wal').readAsBytesSync()];
    for (var i = 1; i <= rows; i++) {
      progress.add(StoreMigrationProgress(done: i, total: rows));
    }
    if (fail) return StoreOpenOutcome.plainFallback;
    f(_tmp).writeAsBytesSync(_seal(source), flush: true);
    _step('copied');
    f('$_enc.from').writeAsStringSync(base64.encode(f(_plain).readAsBytesSync()));
    f('$_check.tmp').writeAsStringSync('check-$key', flush: true);
    f('$_check.tmp').renameSync(f(_check).path);
    _step('checked');
    f(_tmp).renameSync(f(_enc).path);
    _step('switched');
    _setAside(lepicDir);
    return StoreOpenOutcome.migratedNow;
  }

  void _setAside(String lepicDir) {
    File f(String n) => File('$lepicDir$_sep$n');
    f(_plain).renameSync(f(_pre).path);
    if (f('$_plain-wal').existsSync()) f('$_plain-wal').renameSync(f('$_pre-wal').path);
    if (f('$_plain-shm').existsSync()) f('$_plain-shm').deleteSync();
  }

  /// What the encrypted store holds, read back.
  String read(String lepicDir) => utf8.decode(_seal(File('$lepicDir$_sep$_enc').readAsBytesSync()));
}

void _copy(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final e in from.listSync()) {
    final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (e is Directory) {
      _copy(e, Directory('${to.path}$_sep$name'));
    } else if (e is File) {
      e.copySync('${to.path}$_sep$name');
    }
  }
}

/// Every file under [root] with its bytes, by relative path.
Map<String, String> _files(String root) => {
  for (final e in Directory(root).listSync(recursive: true))
    if (e is File) e.path.substring(root.length + 1).replaceAll(r'\', '/'): base64.encode(e.readAsBytesSync()),
};

void main() {
  for (final fixture in ['install_26_10_23', 'install_26_10_24_r2']) {
    group(fixture, () {
      late Directory data;
      final seal1 = FakeSealer(0x5a);
      final seal2 = FakeSealer(0x3c);
      late _FakeLepicOpen lepic1;
      late _FakeLepicOpen lepic2;

      String wallet1() => '${data.path}${_sep}wallets${_sep}mainnet';
      String wallet2() => '${data.path}${_sep}wallets$_sep$_second${_sep}mainnet';
      String lepicOf(String w) => '$w${_sep}lepic';

      const note = '{"version":1,"notes":{"slate-1":"Rent"},"contacts":[],"annotations":{},"records":[],"block_times":{},"kernel_heights":{}}';
      const contacts = '{"version":1,"contacts":[{"id":"c1","name":"Anna","epicbox":"esWNvLomAJ2SHT6CU1F4ok2URGQnmUmCAp9XNwEP4N8JS4Ve8qcx@epicbox.example.invalid","note":"Flatmate"}]}';

      setUp(() async {
        ContactStore.forgetAll();
        data = await Directory.systemTemp.createTemp('store_enc_');
        _copy(Directory('test/fixtures/$fixture/home/.epic_cash_desktop'), data);
        // The plain database each wallet has (the fixture's lepic/FIXTURE stands for it),
        // WAL content not yet checkpointed, and a note and a contact as the old build writes them.
        for (final (w, rows) in [(wallet1(), 'tx-1,tx-2,tx-3'), (wallet2(), 'tx-9')]) {
          File('${lepicOf(w)}$_sep$_plain').writeAsStringSync('SQLite format 3 $rows');
          File('${lepicOf(w)}$_sep$_plain-wal').writeAsStringSync(' wal:tx-4');
          File('${lepicOf(w)}$_sep$_plain-shm').writeAsStringSync('shm');
        }
        File('${wallet1()}$_sep$metaFileName').writeAsStringSync(note);
        File('${data.path}$_sep$contactsFileName').writeAsStringSync(contacts);
        lepic1 = _FakeLepicOpen(0x11);
        lepic2 = _FakeLepicOpen(0x22);
      });
      tearDown(() async {
        SealedFile.killPoint = null;
        ContactStore.forgetAll();
        await data.delete(recursive: true);
      });

      /// One unlock as the app runs it: LEPIC's open, then the app's sealed files.
      Future<StoreOpenOutcome> unlock(String w, String id, FakeSealer s, _FakeLepicOpen lepic, {bool close = true}) async {
        final outcome = lepic.open(lepicOf(w));
        final book = await ContactStore.openSealed(data.path, id, s);
        (await MetaStore.open(w, sealer: s, walletId: id)).close();
        if (close) await book.detach(id, s);
        return outcome;
      }

      // Both open together, so the second wallet gets its key to the shared book.
      Future<void> unlockBoth() async {
        await unlock(wallet1(), 'legacy-mainnet', seal1, lepic1, close: false);
        await unlock(wallet2(), _second, seal2, lepic2, close: false);
        ContactStore.forgetAll();
      }

      // Kept byte for byte: everything outside the two lepic folders, the plain app files among
      // them (they stay in place until the release after this one).
      Map<String, String> kept(Map<String, String> files) =>
          {for (final e in files.entries) if (!e.key.contains('/lepic/')) e.key: e.value};

      test('every file the update keeps is kept; the new file set is there', () async {
        final before = _files(data.path);
        await unlockBoth();
        final after = _files(data.path);
        for (final e in kept(before).entries) {
          expect(after[e.key], e.value, reason: '${e.key} changed or went');
        }
        for (final w in [wallet1(), wallet2()]) {
          final names = Directory(lepicOf(w)).listSync().map((e) => e.uri.pathSegments.last).toSet();
          expect(names, containsAll([_enc, _check, _pre, '$_pre-wal']));
          expect(names, isNot(contains(_plain)));
          expect(names, isNot(contains('$_plain-wal')));
          expect(names, isNot(contains('$_plain-shm')));
          expect(names, isNot(contains(_tmp)));
          expect(names, contains('FIXTURE'), reason: 'nothing else in the folder touched');
        }
        expect(lepic1.read(lepicOf(wallet1())), 'SQLite format 3 tx-1,tx-2,tx-3 wal:tx-4');
        // The pre-encryption copy is the plain database exactly.
        expect(File('${lepicOf(wallet1())}$_sep$_pre').readAsStringSync(), 'SQLite format 3 tx-1,tx-2,tx-3');
        expect(File('${wallet1()}$_sep$metaSealedFileName').existsSync(), isTrue);
        expect(File('${data.path}$_sep$contactsSealedFileName').existsSync(), isTrue);
        expect(File('${data.path}$_sep$contactsKeysDirName${_sep}legacy-mainnet.key').existsSync(), isTrue);
        expect(File('${data.path}$_sep$contactsKeysDirName$_sep$_second.key').existsSync(), isTrue);
        // Notes and contacts open from the sealed files; nothing readable in them.
        final meta = await MetaStore.open(wallet1(), sealer: seal1, walletId: 'legacy-mainnet');
        expect(meta.snapshot.notes, {'slate-1': 'Rent'});
        meta.close();
        final book = await ContactStore.openSealed(data.path, _second, seal2);
        expect([for (final c in book.list()) c.name], ['Anna']);
        for (final f in [File('${wallet1()}$_sep$metaSealedFileName'), File('${data.path}$_sep$contactsSealedFileName')]) {
          final text = latin1.decode(f.readAsBytesSync());
          expect(text, isNot(contains('Rent')));
          expect(text, isNot(contains('Anna')));
        }
      });

      test('the copy reports its progress, and a second open copies nothing', () async {
        expect(await unlock(wallet1(), 'legacy-mainnet', seal1, lepic1), StoreOpenOutcome.migratedNow);
        expect(lepic1.progress.last, const StoreMigrationProgress(done: 3, total: 3));
        lepic1.progress.clear();
        expect(await unlock(wallet1(), 'legacy-mainnet', seal1, lepic1), StoreOpenOutcome.encrypted);
        expect(lepic1.progress, isEmpty);
      });

      test('a copy that fails keeps the plain files in use and tries again next time', () async {
        lepic1.fail = true;
        final before = _files(lepicOf(wallet1()));
        expect(await unlock(wallet1(), 'legacy-mainnet', seal1, lepic1), StoreOpenOutcome.plainFallback);
        expect(_files(lepicOf(wallet1())), before);
        lepic1.fail = false;
        expect(await unlock(wallet1(), 'legacy-mainnet', seal1, lepic1), StoreOpenOutcome.migratedNow);
      });

      test('the wrong key changes nothing', () async {
        await unlockBoth();
        final before = _files(data.path);
        expect(() => _FakeLepicOpen(0x99).open(lepicOf(wallet1())), throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.wrongKey)));
        expect(_files(data.path), before);
      });

      for (final step in ['copied', 'checked', 'switched']) {
        test('a kill after LEPIC\'s step "$step" leaves a folder the next open completes', () async {
          lepic1.killAt = step;
          expect(() => lepic1.open(lepicOf(wallet1())), throwsA(isA<_Killed>()));
          // Before the switch the plain database is as it was.
          if (step != 'switched') {
            expect(File('${lepicOf(wallet1())}$_sep$_plain').readAsStringSync(), 'SQLite format 3 tx-1,tx-2,tx-3');
          }
          await unlock(wallet1(), 'legacy-mainnet', seal1, lepic1);
          expect(lepic1.read(lepicOf(wallet1())), 'SQLite format 3 tx-1,tx-2,tx-3 wal:tx-4');
          expect(File('${lepicOf(wallet1())}$_sep$_plain').existsSync(), isFalse);
          expect(File('${lepicOf(wallet1())}$_sep$_pre').existsSync(), isTrue);
          expect(File('${lepicOf(wallet1())}$_sep$_tmp').existsSync(), isFalse);
          expect(lepic1.restoreScanRequired, isFalse);
        });
      }

      for (final (file, step) in [
        (metaSealedFileName, 'tmp-written'),
        (metaSealedFileName, 'verified'),
        ('legacy-mainnet.key', 'verified'),
        (contactsSealedFileName, 'tmp-written'),
        (contactsSealedFileName, 'verified'),
      ]) {
        test('a kill while sealing $file ($step) leaves the plain file in use; the next unlock seals it', () async {
          SealedFile.killPoint = (path, s) {
            if (path.endsWith(file) && s == step) {
              SealedFile.killPoint = null;
              throw _Killed(step);
            }
          };
          await expectLater(unlock(wallet1(), 'legacy-mainnet', seal1, lepic1), throwsA(anything));
          ContactStore.forgetAll();
          expect(File('${wallet1()}$_sep$metaFileName').readAsStringSync(), note);
          expect(File('${data.path}$_sep$contactsFileName').readAsStringSync(), contacts);
          await unlock(wallet1(), 'legacy-mainnet', seal1, lepic1);
          final meta = await MetaStore.open(wallet1(), sealer: seal1, walletId: 'legacy-mainnet');
          expect(meta.snapshot.notes, {'slate-1': 'Rent'});
          meta.close();
          final book = await ContactStore.openSealed(data.path, 'legacy-mainnet', seal1);
          expect([for (final c in book.list()) c.name], ['Anna']);
          expect(File('${wallet1()}$_sep$metaSealedFileName.tmp').existsSync(), isFalse);
          expect(File('${data.path}$_sep$contactsSealedFileName.tmp').existsSync(), isFalse);
        });
      }

      test('rollback to the plain build, then forward again', () async {
        await unlockBoth();
        ContactStore.forgetAll();
        // The older build: no wallet.sqlite3, so it makes an empty one and scans; it reads and
        // writes the plain app files, which are still in place.
        final lepicDir = lepicOf(wallet1());
        File('$lepicDir$_sep$_plain').writeAsStringSync('SQLite format 3 scanned');
        expect(File('${wallet1()}$_sep$metaFileName').readAsStringSync(), note);
        const later = '{"version":1,"notes":{"slate-1":"Rent","slate-7":"Gift"},"contacts":[],"annotations":{},"records":[],"block_times":{},"kernel_heights":{}}';
        File('${wallet1()}$_sep$metaFileName').writeAsStringSync(later);
        final grown = (jsonDecode(contacts) as Map)..['contacts'] = [
          ...((jsonDecode(contacts) as Map)['contacts'] as List),
          {'id': 'c2', 'name': 'Ben', 'epicbox': 'esBen@epicbox.example.invalid'},
        ];
        File('${data.path}$_sep$contactsFileName').writeAsStringSync(jsonEncode(grown));

        // Forward: the encrypted store opens with everything; the older build's file is set
        // aside and a restore scan is owed; the changed plain app files are merged in.
        expect(await unlock(wallet1(), 'legacy-mainnet', seal1, lepic1), StoreOpenOutcome.encrypted);
        expect(lepic1.read(lepicDir), 'SQLite format 3 tx-1,tx-2,tx-3 wal:tx-4');
        expect(lepic1.restoreScanRequired, isTrue);
        final names = Directory(lepicDir).listSync().map((e) => e.uri.pathSegments.last).toList();
        expect(names.where((n) => n.startsWith(lepicAfterRollbackPrefix)), hasLength(1));
        expect(names, isNot(contains(_plain)));
        expect(names, contains(_pre));
        final meta = await MetaStore.open(wallet1(), sealer: seal1, walletId: 'legacy-mainnet');
        expect(meta.snapshot.notes, {'slate-1': 'Rent', 'slate-7': 'Gift'});
        meta.close();
        final book = await ContactStore.openSealed(data.path, _second, seal2);
        expect([for (final c in book.list()) c.name], ['Anna', 'Ben']);
        // The plain files are still where the older build left them.
        expect(File('${wallet1()}$_sep$metaFileName').readAsStringSync(), later);
      });
    });
  }

  group('two app processes on one data folder', () {
    late Directory data;
    final seal = FakeSealer(0x5a);
    Process? holder;

    setUp(() async {
      ContactStore.forgetAll();
      data = await Directory.systemTemp.createTemp('store_enc_lock_');
      File('${data.path}$_sep$contactsFileName').writeAsStringSync('{"version":1,"contacts":[{"id":"c1","name":"Anna"}]}');
    });
    tearDown(() async {
      holder?.kill();
      await holder?.exitCode;
      holder = null;
      ContactStore.claimWait = const Duration(seconds: 3);
      ContactStore.forgetAll();
      await data.delete(recursive: true);
    });

    /// Another process holding the book's lock, as a second instance of the app would.
    Future<Process> hold() async {
      final p = await Process.start('python3', [
        '-c',
        'import fcntl,sys\n'
            'f=open(sys.argv[1],"a")\n'
            'fcntl.lockf(f,fcntl.LOCK_EX)\n'
            'print("held",flush=True)\n'
            'sys.stdin.read()\n',
        '${data.path}$_sep$contactsLockFileName',
      ]);
      await p.stdout.transform(utf8.decoder).firstWhere((l) => l.contains('held'));
      return p;
    }

    test('while another process has the book, it stays closed here and nothing is written', () async {
      holder = await hold();
      ContactStore.claimWait = const Duration(milliseconds: 300);
      final book = await ContactStore.openSealed(data.path, 'legacy-mainnet', seal);
      expect(book.available, isFalse);
      expect(book.list(), isEmpty);
      expect(File('${data.path}$_sep$contactsSealedFileName').existsSync(), isFalse);
      expect(Directory('${data.path}$_sep$contactsKeysDirName').existsSync(), isFalse);
      await expectLater(book.save(const ContactFields(id: '', name: 'Ben')), throwsA(isA<WalletError>()));
      await book.detach('legacy-mainnet', seal);

      // The other process ends: the next unlock opens the book.
      holder!.kill();
      await holder!.exitCode;
      holder = null;
      final again = await ContactStore.openSealed(data.path, 'legacy-mainnet', seal);
      expect(again.available, isTrue);
      expect([for (final c in again.list()) c.name], ['Anna']);
    }, testOn: '!windows');

    test('an unlock waits for a process that lets go of the book in time', () async {
      holder = await hold();
      final p = holder!;
      unawaited(Future<void>.delayed(const Duration(milliseconds: 400), () => p.stdin.close()));
      final book = await ContactStore.openSealed(data.path, 'legacy-mainnet', seal);
      expect(book.available, isTrue);
      expect(File('${data.path}$_sep$contactsSealedFileName').existsSync(), isTrue);
    }, testOn: '!windows');
  });
}
