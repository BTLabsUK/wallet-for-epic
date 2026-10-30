// SPDX-License-Identifier: Apache-2.0
// An install of 26.10.23 (test/fixtures/install_26_10_23) opened by this app: the startup code
// finds its data folder, its wallets, its node, its store keys and its files where 26.10.23 left
// them, and keeps them. The test the install contract names (tools/install-contract.json,
// docs/install-contract.md): 26.10.24 renamed wallets/<chain> to wallet and opened an empty
// wallet beside the real one. The same install after 26.10.24-r2 ran
// (test/fixtures/install_26_10_24_r2) gets its servers back: r2 wrote the default settings.toml
// and read none of the stored servers (#143).
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/app_log_io.dart' show logFileName;
import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/contact_store.dart' show contactsFileName;
import 'package:epic_wallet/src/data_folder_io.dart' show desktopDataFolder;
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart' show LepicDeskWallet;
import 'package:epic_wallet/src/history/meta_store.dart' show metaFileName;
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings_file/legacy_import.dart';
import 'package:epic_wallet/src/settings_file/settings_backend.dart' show settingsFileName;
import 'package:epic_wallet/src/settings_file/settings_backend_io.dart';
import 'package:epic_wallet/src/settings_file/settings_controller.dart';
import 'package:epic_wallet/src/wallet_registry.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_settings.dart';

const _fixture = 'test/fixtures/install_26_10_23';
const _fixtureR2 = 'test/fixtures/install_26_10_24_r2';
const _addedId = '0123456789abcdef0123456789abcdef';
final _sep = Platform.pathSeparator;

// The fixtures' servers: the test default copy's (test/settings/settings.default.toml), the
// user's own, and the two in use (a default server further down the list, as most users pick).
const _lab = 'https://node.lab.invalid';
const _epic = 'https://node.epic.invalid:3413';
const _net = 'https://node.net.invalid:3413';
const _stack = 'https://node.stack.invalid:3413';
const _testLan = 'http://192.0.2.10:3413';
const _ownNode = 'https://node.own.invalid:3413';
const _homeNode = 'http://node.home.invalid:3413';
const _ownBox = 'box.own.invalid:3420';
const _walletBox = 'box.old.invalid';

/// The fixture [name] copied as an install leaves it under [home]: absolute paths in
/// wallets.json and the store filled in. Returns the data folder and the store.
(String, MemorySecretStore) _install(String name, String home) {
  final src = Directory('$name/home');
  for (final e in src.listSync(recursive: true)) {
    if (e is! File) continue;
    final rel = e.path.substring(src.path.length + 1);
    final out = File('$home$_sep$rel')..parent.createSync(recursive: true);
    e.copySync(out.path);
  }
  final data = desktopDataFolder({'HOME': home}, windows: false)!;
  final list = File('$data${_sep}wallets.json');
  list.writeAsStringSync(list.readAsStringSync().replaceAll('@DATA@', data.replaceAll(r'\', r'\\')));
  final values = (jsonDecode(File('$name/store.json').readAsStringSync()) as Map).cast<String, String>();
  return (data, MemorySecretStore({for (final e in values.entries) e.key: e.value.replaceAll('@DATA@', data)}));
}

/// Every file and folder under [root], relative, sorted.
List<String> _tree(String root) => [
  for (final e in Directory(root).listSync(recursive: true)) e.path.substring(root.length + 1).replaceAll(r'\', '/'),
]..sort();

void main() {
  late Directory tmp;
  late String home;
  late String data;
  late MemorySecretStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('install_upgrade_test');
    home = '${tmp.path}${_sep}home';
    (data, store) = _install(_fixture, home);
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('the data folder is <home>/.epic_cash_desktop on every desktop system', () {
    expect(data, '$home/.epic_cash_desktop');
    expect(Directory(data).existsSync(), isTrue);
    expect(desktopDataFolder({'USERPROFILE': r'C:\Users\tester'}, windows: true), r'C:\Users\tester\.epic_cash_desktop');
  });

  test('both wallets are found where 26.10.23 left them, and nothing new appears beside them', () async {
    final before = _tree(data);
    final registry = WalletRegistry(data);
    await registry.load();

    expect([for (final e in registry.list()) e.id], ['legacy-mainnet', _addedId]);
    final first = registry.byId('legacy-mainnet')!;
    final added = registry.byId(_addedId)!;
    expect(first.dataDir, WalletRegistry.firstWalletDir(data, Chain.mainnet));
    expect(first.dataDir, '$data${_sep}wallets${_sep}mainnet');
    expect(added.dataDir, WalletRegistry.walletDirOf(data, Chain.mainnet, _addedId));
    for (final e in [first, added]) {
      expect(registry.folderMissing(e), isFalse, reason: e.dataDir);
      expect(Directory('${e.dataDir}${_sep}lepic').existsSync(), isTrue, reason: e.dataDir);
    }
    expect(File('${first.dataDir}$_sep$metaFileName').existsSync(), isTrue);
    expect(File('${first.dataDir}$_sep${LepicDeskWallet.setupDoneFileName}').existsSync(), isTrue);
    expect(WalletRegistry.rootOf(first.dataDir, Chain.mainnet), data);

    // What the startup does next: Wallet 1 is listed already, no other wallet waits unlisted.
    expect(await registry.adoptLegacy(Chain.mainnet), isNull);
    expect(await registry.rescan(), isEmpty);
    expect(_tree(data), before, reason: 'no empty wallet folder made, nothing moved or removed');
  });

  test('without wallets.json (made before the list) the first wallet is adopted and the added one offered', () async {
    File('$data${_sep}wallets.json').deleteSync();
    final registry = WalletRegistry(data);
    await registry.load();
    final first = await registry.adoptLegacy(Chain.mainnet);
    expect(first?.dataDir, '$data${_sep}wallets${_sep}mainnet');
    final found = await registry.rescan();
    expect([for (final e in found) e.dataDir], ['$data${_sep}wallets$_sep$_addedId${_sep}mainnet']);
  });

  test("the wallets' store keys still name the folders the app opens", () {
    final pinned = store.values[LepicWalletService.storePrefixKey(Chain.mainnet)];
    expect(pinned, 'lepic:mainnet:${WalletRegistry.firstWalletDir(data, Chain.mainnet)}:');
    expect(store.values[DeskStore.walletMetaKey('mainnet', null)], isNotNull);
    expect(store.values[DeskStore.walletMetaKey('mainnet', _addedId)], isNotNull);
  });

  test('the built-in node finds its folder and toml', () {
    final node = BuiltInNode(root: '$data${_sep}node', binary: 'epic', chain: Chain.mainnet, autoPoll: false);
    expect(node.folder, '$data${_sep}node${_sep}main');
    expect(File(node.tomlPath).existsSync(), isTrue);
    expect(Directory('${node.folder}${_sep}chain_data').existsSync(), isTrue);
  });

  test('contacts and the log are where the app reads them', () {
    expect(File('$data$_sep$contactsFileName').existsSync(), isTrue);
    expect(File('$data${_sep}logs$_sep$logFileName').existsSync(), isTrue);
  });

  test("26.10.23's stored servers join a new settings.toml once; the store keeps them", () async {
    expect(File('$data$_sep$settingsFileName').existsSync(), isFalse);
    final before = Map.of(store.values);
    final c = await SettingsFileController.open(
      backend: FileSettingsBackend(Directory(data)),
      shippedText: testSettingsText(),
      config: testConfig(),
    );
    addTearDown(c.close);
    await importLegacySettings(store, c, walletIds: () async => [_addedId]);

    expect(File('$data$_sep$settingsFileName').existsSync(), isTrue);
    expect(c.settings.nodeUse, _net);
    expect(c.settings.epicboxUse, 'box.stack.invalid');
    expect(c.settings.statusEnabled, isFalse);
    for (final e in before.entries) {
      expect(store.values[e.key], e.value, reason: '${e.key} is never deleted');
    }
    expect(store.values[legacyImportedKey], isNotNull);
  });

  // #143: the user's own node and Epicbox servers and the two in use, from 26.10.23 and from an
  // install that already ran 26.10.24-r2 (default settings.toml, the old records still stored).
  for (final (name, fixture) in [('26.10.23', _fixture), ('26.10.24-r2', _fixtureR2)]) {
    test('$name: every own node and Epicbox server is kept, and the two in use stay in use', () async {
      final at = '${tmp.path}${_sep}from-${name.replaceAll('.', '_')}';
      final (data, store) = _install(fixture, at);
      final settings = File('$data$_sep$settingsFileName');
      expect(settings.existsSync(), fixture == _fixtureR2, reason: 'r2 wrote the default copy, 26.10.23 had none');
      final before = Map.of(store.values);
      Future<SettingsFileController> start() async {
        final c = await SettingsFileController.open(
          backend: FileSettingsBackend(Directory(data)),
          shippedText: testSettingsText(),
          config: testConfig(),
        );
        await importLegacySettings(store, c, walletIds: () async => [_addedId]);
        return c;
      }

      final c = await start();
      expect(c.settings.nodeUrls, [_net, _ownNode, _lab, _epic, _homeNode, _stack, _testLan]);
      expect([for (final b in c.settings.epicboxServers) b.label], [
        'box.stack.invalid',
        'box.epic.invalid',
        'box.net.invalid',
        'box.lab.invalid',
        _ownBox,
        _walletBox,
      ]);
      expect(c.settings.nodeUse, _net);
      expect(c.settings.epicboxUse, 'box.stack.invalid');
      await c.close();
      for (final e in before.entries) {
        expect(store.values[e.key], e.value, reason: '${e.key} is never deleted');
      }

      // Once: the next start reads the same file and writes nothing.
      final text = settings.readAsStringSync();
      final again = await start();
      addTearDown(again.close);
      expect(settings.readAsStringSync(), text);
    });
  }

  test('26.10.24-r2 and the user changed the node list since: that change stays, own servers join it', () async {
    final at = '${tmp.path}${_sep}from-r2-changed';
    final (data, store) = _install(_fixtureR2, at);
    // On r2 the user put a new node of their own in use.
    final settings = File('$data$_sep$settingsFileName');
    const fresh = 'https://node.fresh.invalid';
    settings.writeAsStringSync(settings.readAsStringSync().replaceFirst('servers = [\n', 'servers = [\n  "$fresh",\n'));
    final c = await SettingsFileController.open(
      backend: FileSettingsBackend(Directory(data)),
      shippedText: testSettingsText(),
      config: testConfig(),
    );
    addTearDown(c.close);
    await importLegacySettings(store, c, walletIds: () async => [_addedId]);
    expect(c.settings.nodeUrls, [fresh, _lab, _epic, _net, _stack, _testLan, _ownNode, _homeNode]);
    expect(c.settings.nodeUse, fresh, reason: 'the newer pick stays in use');
    expect(c.settings.epicboxUse, 'box.stack.invalid', reason: 'the Epicbox list was untouched');
    expect([for (final b in c.settings.epicboxServers) b.label], containsAll([_ownBox, _walletBox]));
  });
}
