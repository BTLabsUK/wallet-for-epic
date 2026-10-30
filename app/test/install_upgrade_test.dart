// SPDX-License-Identifier: Apache-2.0
// An install of 26.10.23 (test/fixtures/install_26_10_23) opened by this app: the startup code
// finds its data folder, its wallets, its node, its store keys and its files where 26.10.23 left
// them, and keeps them. The test the install contract names (tools/install-contract.json,
// docs/install-contract.md): 26.10.24 renamed wallets/<chain> to wallet and opened an empty
// wallet beside the real one.
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
const _addedId = '0123456789abcdef0123456789abcdef';
final _sep = Platform.pathSeparator;

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
    // The fixture copied as an install leaves it: absolute paths in wallets.json and the store.
    final src = Directory('$_fixture/home');
    for (final e in src.listSync(recursive: true)) {
      if (e is! File) continue;
      final rel = e.path.substring(src.path.length + 1);
      final out = File('$home$_sep$rel')..parent.createSync(recursive: true);
      e.copySync(out.path);
    }
    data = desktopDataFolder({'HOME': home}, windows: false)!;
    final list = File('$data${_sep}wallets.json');
    list.writeAsStringSync(list.readAsStringSync().replaceAll('@DATA@', data.replaceAll(r'\', r'\\')));
    final values = (jsonDecode(File('$_fixture/store.json').readAsStringSync()) as Map).cast<String, String>();
    store = MemorySecretStore({for (final e in values.entries) e.key: e.value.replaceAll('@DATA@', data)});
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
    expect(c.settings.nodeUse, 'https://node.own.invalid:3413');
    expect(c.settings.epicboxUse, 'box.stack.invalid');
    expect(c.settings.statusEnabled, isFalse);
    for (final e in before.entries) {
      expect(store.values[e.key], e.value, reason: '${e.key} is never deleted');
    }
    expect(store.values[legacyImportedKey], isNotNull);
  });
}
