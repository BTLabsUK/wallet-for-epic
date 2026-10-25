// End to end: an old Epic GUI's profile (the fixtures of test/fixtures/legacy_gui, IndexedDB
// files real Chromium wrote) imported through LepicDeskWallet into the address book every
// wallet shares (`<support>/contacts.json`), then read back by a fresh instance. The wallet
// itself is FakeWalletService's; its contacts go through WalletHistory and ContactStore as
// LepicWalletService's do. Everything lives in a temp dir; the names and addresses are
// synthetic.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/contact_store.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/legacy_wallets.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _old = 'old password';
const _keyA = 'esWNvLomAJ2SHT6CU1F4ok2URGQnmUmCAp9XNwEP4N8JS4Ve8qcx';
const _keyB = 'es7jHnbVkZzE2UGWUkzWrc4y4VoKZbg7FBaPUo2vXhJpe4jgXAA7';
const _onion = '2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion';

/// A session whose address book is the shared store, as LepicWalletSession's is.
class _SharedBookSession extends core.FakeWalletSession {
  _SharedBookSession(ContactStore store) : _history = WalletHistory.memory(contacts: store);

  final WalletHistory _history;

  @override
  Future<List<core.Contact>> contacts() async => _history.contacts();

  @override
  Future<core.Contact> saveContact({required core.Contact contact}) => _history.saveContact(contact);

  @override
  Future<void> deleteContact({required String id}) => _history.deleteContact(id);
}

void main() {
  const fixtures = 'test/fixtures/legacy_gui';
  late Directory tmp;
  late String home;
  late Directory support;
  late LepicDeskWallet wallet;

  Future<void> copyTree(String from, String to) async {
    await for (final e in Directory(from).list(recursive: true, followLinks: false)) {
      if (e is! File) continue;
      final dest = File('$to${e.path.substring(from.length)}');
      await dest.parent.create(recursive: true);
      if (e.path.endsWith('.json')) {
        await dest.writeAsString((await e.readAsString()).replaceAll('@HOME@', home).replaceAll('@ROOT@', '$home/.epic-gui'));
      } else {
        await e.copy(dest.path);
      }
    }
  }

  /// A fresh app on [support]: the store loaded from disk again.
  Future<(LepicDeskWallet, ContactStore)> freshApp() async {
    ContactStore.forgetAll();
    final store = await ContactStore.open(support.path);
    final service = core.FakeWalletService(password: 'test-pass-1234', session: _SharedBookSession(store));
    final w = LepicDeskWallet(
      service: service,
      walletDir: (chain) async {
        final d = Directory('${support.path}/wallets/${chain.name}');
        await d.create(recursive: true);
        return d.path;
      },
      secrets: MemorySecretStore(),
      filesDir: () async => tmp,
      nodePoll: const Duration(hours: 1),
      legacyRoots: () => LegacyRoots(home: home, appData: '$home/.config'),
      listProcesses: () async => const [],
    );
    return (w, store);
  }

  late ContactStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('desk-gui-contacts-');
    home = '${tmp.path}/home';
    support = await Directory('${tmp.path}/support').create();
    // GUI 6.1.6 (its root and IndexedDB) and the older GUIs' ~/.epic with both Electron profiles.
    await copyTree('$fixtures/gui616', home);
    await copyTree('$fixtures/idb/gui616_log', '$home/.epic-gui/app/IndexedDB');
    await copyTree('$fixtures/gui531', home);
    await copyTree('$fixtures/idb/gui531_table', '$home/.config/EpicWallet/IndexedDB');
    await copyTree('$fixtures/idb/gui600_log', '$home/.config/epic-desktop-wallet/IndexedDB');
    // The two old wallets are different wallets here.
    await File('$home/.epic/alpha/main/wallet_data/wallet.seed').writeAsString('{"fixture":"alpha"}');
    (wallet, store) = await freshApp();
  });

  tearDown(() async {
    await wallet.dispose();
    ContactStore.forgetAll();
    await tmp.delete(recursive: true);
  });

  Future<ImportedWallet> importAt(String folder) async {
    final old = (await wallet.findOldWallets()).firstWhere((w) => w.folder == folder);
    return wallet.importOldWallet(old.id, oldPassword: _old);
  }

  List<(String, bool)> contactLines(ImportedWallet r) => [
    for (final p in r.proof)
      if (p.text.contains('contact') || p.text.contains('address')) (p.text, p.ok),
  ];

  Map<String, ContactFields> byName(ContactStore s) => {for (final c in s.list()) c.name: c};

  test('GUI 6.1.6: each address by its kind, a bare key at the wallet\'s Epicbox, saved on disk for every wallet', () async {
    final before = await folderHash(home);
    final r = await importAt('$home/.epic-gui/wallets/w1');
    expect(contactLines(r), [('3 contacts added', true)]);

    // A fresh app reads the same book from <support>/contacts.json.
    await wallet.dispose();
    (wallet, store) = await freshApp();
    final book = byName(store);
    expect(book.keys, ['Alice', 'Carol', 'Zoë 李雷']);
    expect(book['Alice']!.epicbox, '$_keyA@epicbox.epiccash.com');
    expect(book['Alice']!.http, 'https://alice.example:3415');
    expect(book['Alice']!.note, 'paid for coffee');
    expect(book['Zoë 李雷']!.epicbox, '$_keyB@epicbox.epiccash.com', reason: 'the bare key, at the wallet\'s Epicbox domain');
    expect(book['Zoë 李雷']!.tor, _onion);
    expect(book['Carol']!.http, 'https://carol.example:3415');
    expect(book['Carol']!.note, 'updated note');

    final file = File('${support.path}/$contactsFileName');
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(json['version'], 1);
    expect(json['contacts'], hasLength(3));
    if (Platform.isLinux) {
      expect((await Process.run('stat', ['-c', '%a', file.path])).stdout.toString().trim(), '600');
    }
    // No per-wallet copy: the wallet folders hold no contacts file of their own.
    expect(await folderHash(home), before, reason: 'the old GUI\'s folders are only read');
  });

  test('a saved contact is merged, never overwritten; a second wallet\'s contacts are already saved or left out', () async {
    // The user already has Alice's HTTP address under another name, with a note of their own.
    await store.save(const ContactFields(name: 'Ally (shop)', http: 'https://alice.example:3415', note: 'mine'));
    final r1 = await importAt('$home/.epic-gui/wallets/w1');
    expect(contactLines(r1), [('2 contacts added', true), ('1 contact merged with an existing one', true)]);
    final ally = byName(store)['Ally (shop)']!;
    expect(ally.epicbox, '$_keyA@epicbox.epiccash.com', reason: 'the Epicbox address it lacked');
    expect(ally.http, 'https://alice.example:3415');
    expect(ally.note, 'mine', reason: 'the user\'s note stays');
    expect(byName(store).containsKey('Alice'), isFalse, reason: 'its name stays too');

    // GUI 6.0 + 5.3.1, account alpha: Shared has Zoë's bare key (at this wallet's
    // epicbox.fastepic.eu), Grace has Alice's key with another HTTP address, Carol is saved
    // already; Frank and Heidi are new.
    final r2 = await importAt('$home/.epic/alpha/main');
    expect(contactLines(r2), [
      ('2 contacts added', true),
      ('3 contacts already saved', true),
      ('1 address not added: it conflicts with a saved contact', false),
    ]);
    final book = byName(store);
    expect(book.keys, ['Ally (shop)', 'Carol', 'Frank', 'Heidi', 'Zoë 李雷']);
    expect(book['Ally (shop)']!.http, 'https://alice.example:3415', reason: 'Grace\'s HTTP address did not replace it');
    expect(book['Zoë 李雷']!.epicbox, '$_keyB@epicbox.epiccash.com', reason: 'the same key at another relay is the same contact');
    expect(book['Frank']!.http, 'http://frank.example:3415');
    expect(book['Frank']!.note, 'changed after compaction');
  });

  test('importing the same wallet\'s contacts again adds nothing', () async {
    await importAt('$home/.epic-gui/wallets/w1');
    final first = store.list();
    // The same GUI wallet again, as another app would after deleting the imported wallet.
    final r = await importGuiContactsAgain(wallet, home);
    expect(r, isNotNull);
    expect(store.list(), first);
  });
}

/// Imports the GUI 6.1 wallet w1's contacts a second time through a new wallet made from another
/// seed file in the same folder; returns its proof.
Future<ImportedWallet?> importGuiContactsAgain(LepicDeskWallet wallet, String home) async {
  await File('$home/.epic-gui/wallets/w1/wallet_data/wallet.seed').writeAsString('{"fixture":"w1-again"}');
  final old = (await wallet.findOldWallets()).firstWhere((w) => w.folder == '$home/.epic-gui/wallets/w1');
  final r = await wallet.importOldWallet(old.id, oldPassword: _old);
  expect([for (final p in r.proof) if (p.text.contains('contact')) p.text], ['3 contacts already saved']);
  return r;
}
