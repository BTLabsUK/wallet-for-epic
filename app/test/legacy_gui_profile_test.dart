import 'dart:io';

import 'package:epic_wallet/src/l10n.dart' show appLanguages;
import 'package:epic_wallet/src/legacy/gui_rules.dart';
import 'package:epic_wallet/src/legacy_gui_profile.dart';
import 'package:epic_wallet/src/legacy_wallets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fixture trees of test/fixtures/legacy_gui are copied to a temp home per test (their paths
/// filled in), with the IndexedDB folders real Chromium wrote (tool/legacy_gui_fixtures.py) put
/// where each GUI keeps them. No real wallet or profile is ever opened.
void main() {
  const fixtures = 'test/fixtures/legacy_gui';
  late Directory tmp;
  late String home;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('legacy_gui_');
    home = '${tmp.path}/home';
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> copyTree(String from, String to) async {
    await for (final e in Directory(from).list(recursive: true, followLinks: false)) {
      if (e is! File) continue;
      final dest = File('$to${e.path.substring(from.length)}');
      await dest.parent.create(recursive: true);
      if (e.path.endsWith('.json')) {
        final text = (await e.readAsString()).replaceAll('@HOME@', home).replaceAll('@ROOT@', '$home/.epic-gui');
        await dest.writeAsString(text);
      } else {
        await e.copy(dest.path);
      }
    }
  }

  Future<void> idb(String fixture, String profile) =>
      copyTree('$fixtures/idb/$fixture', '$profile/IndexedDB');

  LegacyRoots roots() => LegacyRoots(home: home, appData: '$home/.config');

  Future<LegacyWallet> walletAt(String path) async {
    final scan = await findLegacyWallets(roots: roots());
    return scan.wallets.firstWhere((w) => w.path == path, orElse: () => throw StateError('no wallet at $path'));
  }

  Future<Map<String, String>> hashes(List<String> dirs) async => {for (final d in dirs) d: await folderHash(d)};

  Future<void> expectUnchanged(Map<String, String> before) async {
    for (final e in before.entries) {
      expect(await folderHash(e.key), e.value, reason: '${e.key} changed');
      await for (final f in Directory(e.key).list(recursive: true)) {
        expect(f.path.endsWith('${Platform.pathSeparator}LOCK'), isFalse, reason: 'a LOCK was made: ${f.path}');
      }
    }
  }

  List<String> names(LegacyGuiImport r) => [for (final c in r.contacts) c.name];

  group('GUI 6.1.6', () {
    setUp(() async {
      await copyTree('$fixtures/gui616', home);
      await idb('gui616_log', '$home/.epic-gui/app');
    });

    test('a created wallet: label, node, Epicbox, the app language, its contacts', () async {
      final before = await hashes([home]);
      final w = await walletAt('$home/.epic-gui/wallets/w1');
      final r = await readGuiImport(roots(), w, scratch: tmp);

      expect(r.label, 'Główny portfel'); // trimmed, the U+202E override dropped (cleanLabel)
      expect(r.nodeUrl, 'https://node.epiccash.com:3413');
      expect(r.builtInNode, isFalse);
      expect(r.epicboxDomain, 'epicbox.epiccash.com');
      expect(r.epicboxPort, 443);
      expect(r.language, 'de'); // app.locale wins over the User row's 'pl'
      // Bob was deleted, Carol updated, the second Alice is a repeat of [name, onion]
      expect(names(r), ['Alice', 'Zoë 李雷', 'Carol']);
      final alice = r.contacts[0], zoe = r.contacts[1], carol = r.contacts[2];
      expect(alice.epicboxAddress, 'esWNvLomAJ2SHT6CU1F4ok2URGQnmUmCAp9XNwEP4N8JS4Ve8qcx@epicbox.epiccash.com');
      expect(alice.httpAddress, 'https://alice.example:3415');
      expect(alice.note, 'paid for coffee');
      expect(alice.onion, isNull);
      expect(zoe.onion, '2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion');
      expect(zoe.note, '日本語のメモ ✓');
      expect(zoe.httpAddress, isNull);
      expect(carol.note, 'updated note');
      expect(carol.httpAddress, 'https://carol.example:3415');
      expect(r.notes, isEmpty);
      await expectUnchanged(before);
    });

    test('a floonet wallet: a mainnet node becomes the local one, the old Epicbox renamed, the toml port', () async {
      final w = await walletAt('$home/.epic-gui/wallets/w2');
      final r = await readGuiImport(roots(), w);
      expect(r.label, isNull);
      expect(r.nodeUrl, 'http://127.0.0.1:3413');
      expect(r.builtInNode, isTrue);
      expect(r.epicboxDomain, 'epicbox.epiccash.com');
      expect(r.epicboxPort, 8443);
      expect(names(r), ['Dave']);
      expect(r.contacts.single.httpAddress, 'http://10.100.10.20:3415');
    });

    test('the app settings: locale and My nodes, cleaned as myNodes.js does', () async {
      final before = await hashes([home]);
      final g = await readGuiGlobal(roots());
      expect(g.appLocale, 'de');
      expect(g.myNodes.keys, ['mainnet', 'floonet']);
      expect([for (final n in g.myNodes['mainnet']!) (n.address, n.label)], [
        ('https://node.example.com:3413', 'Home node'),
        ('http://10.0.1.5:3413', 'LAN'),
      ]);
      expect(g.myNodes['floonet']!.single.address, 'http://127.0.0.1:13413');
      await expectUnchanged(before);
    });

    test('without the IndexedDB: the settings, no contacts', () async {
      await Directory('$home/.epic-gui/app').delete(recursive: true);
      final r = await readGuiImport(roots(), await walletAt('$home/.epic-gui/wallets/w1'));
      expect(r.label, 'Główny portfel');
      expect(r.contacts, isEmpty);
    });
  });

  group('GUI 5.3.1 and 6.0', () {
    setUp(() async {
      await copyTree('$fixtures/gui531', home);
      await idb('gui531_table', '$home/.config/EpicWallet');
      await idb('gui600_log', '$home/.config/epic-desktop-wallet');
    });

    test("the 'default' account in ~/.epic/main: config.json and the 5.3.1 profile", () async {
      final before = await hashes([home]);
      final w = await walletAt('$home/.epic/main');
      expect(w.account, 'default');
      final r = await readGuiImport(roots(), w);
      expect(r.label, isNull); // no name, and 'default' is no label
      expect(r.nodeUrl, 'https://node.epiccash.com:3413'); // fastepic.eu is gone
      expect(r.builtInNode, isFalse);
      expect(r.epicboxDomain, 'epicbox.epiccash.com'); // config.json's epicbox.epic.tech, renamed
      expect(r.epicboxPort, 443);
      expect(r.language, 'de'); // config.json locale '' → the User row's
      expect(names(r), ['Eve']);
      expect(r.contacts.single.epicboxAddress, 'esWNvLomAJ2SHT6CU1F4ok2URGQnmUmCAp9XNwEP4N8JS4Ve8qcx');
      await expectUnchanged(before);
    });

    test('an account in both profiles: the 6.0 row wins, contacts of both merged', () async {
      final before = await hashes([home]);
      final w = await walletAt('$home/.epic/alpha/main');
      expect(w.account, 'alpha');
      final r = await readGuiImport(roots(), w);
      expect(r.label, 'Alpha (6.0)');
      expect(r.builtInNode, isFalse); // 6.0's row; 5.3.1 said true
      expect(r.epicboxDomain, 'epicbox.fastepic.eu'); // the User row before config.json
      expect(r.language, 'bg'); // config.json's locale before the row's
      expect(r.nodeUrl, 'http://10.100.10.20:3413'); // a LAN host gets http, slashes and spaces go
      // 6.0 first; 5.3.1's 'Shared' is a repeat; Frank and Heidi were written to the log after
      // the table was compacted, Bob deleted before it
      expect(names(r), ['Shared', 'Grace', 'Frank', 'Carol', 'Heidi']);
      expect(r.contacts[0].note, 'in 6.0');
      expect(r.contacts[2].note, 'changed after compaction');
      expect(r.contacts[3].note, 'updated note');
      expect(r.notes, isEmpty);
      await expectUnchanged(before);
    });

    test('only the 5.3.1 profile: its row', () async {
      await Directory('$home/.config/epic-desktop-wallet').delete(recursive: true);
      final r = await readGuiImport(roots(), await walletAt('$home/.epic/alpha/main'));
      expect(r.label, 'Alpha');
      expect(r.builtInNode, isTrue);
      expect(r.epicboxDomain, 'epicbox.epiccash.com'); // the row's epicbox.epic.tech, renamed
      expect(names(r), ['Frank', 'Shared', 'Carol', 'Heidi']);
    });

    test('a damaged profile: notes, the settings still read, no throw', () async {
      final dir = Directory('$home/.config/EpicWallet/IndexedDB/app_._0.indexeddb.leveldb');
      final table = File('${dir.path}/000005.ldb');
      final bytes = await table.readAsBytes();
      bytes[bytes.length ~/ 3] ^= 0xff;
      await table.writeAsBytes(bytes);
      await Directory('$home/.config/epic-desktop-wallet').delete(recursive: true);
      final r = await readGuiImport(roots(), await walletAt('$home/.epic/alpha/main'));
      expect(r.notes.join('\n'), contains('damaged block'));
      expect(r.language, 'bg');
      expect(r.nodeUrl, 'http://10.100.10.20:3413');
    });

    test('no global settings without GUI 6.1', () async {
      final g = await readGuiGlobal(roots());
      expect(g.appLocale, isNull);
      expect(g.myNodes, isEmpty);
    });
  });

  test('the epic program: only its toml', () async {
    await copyTree('$fixtures/cli', home);
    final before = await hashes([home]);
    final w = await walletAt('$home/.epic/main');
    expect(w.source, LegacySource.cli);
    final r = await readGuiImport(roots(), w);
    expect(r.label, isNull);
    expect(r.nodeUrl, 'https://mynode.example:3413');
    expect(r.builtInNode, isNull);
    expect(r.epicboxDomain, 'epicbox.epiccash.com');
    expect(r.epicboxPort, 1443);
    expect(r.language, isNull);
    expect(r.contacts, isEmpty);
    await expectUnchanged(before);
  });

  group('importer.js rules', () {
    test('cleanNodeAddress', () {
      expect(cleanNodeAddress(''), '');
      expect(cleanNodeAddress('http://'), 'http://');
      expect(cleanNodeAddress(' node.example.com:3413/ '), 'https://node.example.com:3413');
      expect(cleanNodeAddress('10.0.0.5:3413'), 'http://10.0.0.5:3413');
      expect(cleanNodeAddress('localhost:3413'), 'http://localhost:3413');
      expect(cleanNodeAddress('HTTPS://Node.Example.com:443/'), 'https://node.example.com');
      expect(cleanNodeAddress('https://node.example.com:3413/api/?x#y'), 'https://node.example.com:3413/api');
      expect(cleanNodeAddress('http://fastepic.eu:3413'), guiDefaultNode);
      expect(cleanNodeAddress('https://node.fastepic.eu'), guiDefaultNode);
      expect(cleanNodeAddress('116.203.211.229:3413'), guiDefaultNode);
      expect(cleanNodeAddress('https://node.epiccash.com:3413', network: 'floonet'), guiLocalNode);
      expect(cleanNodeAddress('http://fastepic.eu', network: 'usernet'), guiLocalNode);
      expect(cleanNodeAddress('https://user:pw@node.example.com'), 'https://user:pw@node.example.com');
      expect(cleanNodeAddress('ftp://node.example.com'), 'ftp://node.example.com');
      expect(cleanNodeAddress('http://[::1]:3413'), 'http://[::1]:3413');
      expect(cleanNodeAddress('10.0.0.2:3413'), 'http://10.0.0.2:3413');
      expect(cleanNodeAddress('10.100.1.1:3413'), 'http://10.100.1.1:3413');
      expect(cleanNodeAddress('172.32.0.1:3413'), 'https://172.32.0.1:3413');
    });

    test('fallbackNodeAddress and the importer chain', () {
      expect(fallbackNodeAddress(''), guiDefaultNode);
      expect(fallbackNodeAddress('', network: 'floonet'), 'http://127.0.0.1:13413');
      expect(fallbackNodeAddress('', network: 'usernet'), 'http://127.0.0.1:23413');
      expect(fallbackNodeAddress('127.0.0.1:3413/'), 'http://127.0.0.1:3413');
      expect(fallbackNodeAddress('node.example.com'), 'https://node.example.com');
      expect(fallbackNodeAddress('ftp://x'), guiDefaultNode);
      expect(importerNodeAddress(null), guiDefaultNode);
      // as in JS: cleanNodeAddress gives the untrimmed '  ' back, which is a non-empty string
      expect(importerNodeAddress('  '), '  ');
      expect(importerNodeAddress('', network: 'floonet'), 'http://127.0.0.1:13413');
      expect(importerNodeAddress('node.example.com/'), 'https://node.example.com');
    });

    test('cleanEpicbox', () {
      expect(cleanEpicbox(null), 'epicbox.epiccash.com');
      expect(cleanEpicbox(''), 'epicbox.epiccash.com');
      expect(cleanEpicbox(' EpicBox.Epic.Tech '), 'epicbox.epiccash.com');
      expect(cleanEpicbox('epicbox.example.org'), 'epicbox.example.org');
    });

    test('labels', () {
      expect(cleanGuiLabel('  a\tb\u0000c  '), 'a b c');
      expect(cleanGuiLabel('x\u200ey\u202ez\u2066'), 'xyz');
      expect(cleanGuiLabel('💰' * 40), '💰' * 32);
      expect(cleanGuiLabel('a' * 31 + '  b'), 'a' * 31);
    });

    test('languages: the GUI fallback and the app codes', () {
      expect(guiSupportedLocale('cz'), 'cz');
      expect(guiSupportedLocale('ru'), 'en');
      expect(appLanguageForGui('de'), 'de');
      expect(appLanguageForGui(' PL '), 'pl');
      expect(appLanguageForGui('ru'), 'ru');
      expect(appLanguageForGui('cz'), isNull);
      expect(appLanguageForGui('bg'), isNull);
      expect(appLanguageForGui(null), isNull);
      expect(appLanguageCodes, [for (final l in appLanguages) l.code]);
    });

    test('node keys and checks (myNodes.js)', () {
      expect(nodeAddressKey('node.example.com/'), nodeAddressKey('HTTPS://Node.Example.com:443'));
      expect(nodeCheckAddress('https://node.example.com?x=1'), '');
      expect(nodeCheckAddress('https://a:b@node.example.com'), '');
      expect(nodeCheckAddress('ftp://node.example.com'), '');
    });
  });
}
