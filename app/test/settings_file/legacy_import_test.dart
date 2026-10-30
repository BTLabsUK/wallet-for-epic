// SPDX-License-Identifier: Apache-2.0
// The one-time import of 26.10.23's stored servers and choices into settings.toml
// (legacy_import.dart), per old store shape, and for installs that already ran 26.10.24.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/legacy_import.dart';
import 'package:epic_wallet/src/settings_file/settings_backend_io.dart';
import 'package:epic_wallet/src/settings_file/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_settings.dart';

// The test default copy's servers (test/settings/settings.default.toml).
const _lab = 'https://node.lab.invalid';
const _epic = 'https://node.epic.invalid:3413';
const _net = 'https://node.net.invalid:3413';
const _stack = 'https://node.stack.invalid:3413';
const _testLan = 'http://192.0.2.10:3413';
const _defaultNodes = [_lab, _epic, _net, _stack, _testLan];
const _defaultBoxes = ['box.epic.invalid', 'box.stack.invalid', 'box.net.invalid', 'box.lab.invalid'];

// The user's own.
const _lan = 'http://198.51.100.7:3413';
const _ownBox = 'box.own.invalid:8443';

String _list(List<String> entries, {List<String> removed = const [], List<String> added = const []}) =>
    jsonEncode({'entries': entries, 'removed': removed, if (added.isNotEmpty) 'added': added});

void main() {
  late Directory dir;
  late File file;
  final shippedText = testSettingsText();
  final config = testConfig();
  final opened = <SettingsFileController>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('legacy_import_test');
    file = File('${dir.path}/settings.toml');
  });

  tearDown(() async {
    for (final c in opened) {
      await c.close();
    }
    opened.clear();
    await dir.delete(recursive: true);
  });

  Future<SettingsFileController> open() async {
    final c = await SettingsFileController.open(backend: FileSettingsBackend(dir), shippedText: shippedText, config: config);
    opened.add(c);
    return c;
  }

  List<String> boxes(HostSettings s) => [for (final b in s.epicboxServers) b.label];

  test('phone 26.10.23: lists, the node and Epicbox server in use, the status-site switch', () async {
    final store = MemorySecretStore()
      ..values.addAll({
        'app.serverList.node.mainnet': _list([_lab, _epic, _net, _stack, _lan], added: ['198.51.100.7:3413']),
        'app.node.mainnet': _lan,
        'app.serverList.relay.mainnet': _list([..._defaultBoxes, _ownBox]),
        'app.relay.mainnet': _ownBox,
        'app.status_site': 'false',
        // A dev network's records stay apart.
        'app.node.floonet': 'https://floo.invalid',
        'app.serverList.node.floonet': _list(['https://floo.invalid']),
      });
    final before = Map.of(store.values);
    final c = await open();
    await importLegacySettings(store, c);

    expect(c.settings.nodeUrls, [_lan, _lab, _epic, _net, _stack, _testLan]);
    expect(c.settings.nodeUse, _lan);
    expect(boxes(c.settings), [_ownBox, ..._defaultBoxes]);
    expect(c.settings.epicboxUse, _ownBox);
    expect(c.settings.statusEnabled, isFalse);
    // Written to the file, the old records kept and marked.
    final again = HostSettings.fromText(await file.readAsString(), config: config);
    expect(again.nodeUrls.first, _lan);
    expect(again.epicboxServers.first.label, _ownBox);
    for (final e in before.entries) {
      expect(store.values[e.key], e.value, reason: '${e.key} is never deleted');
    }
    expect(store.values[legacyImportedKey], isNotNull);
  });

  test('desktop 26.10.23: removed defaults stay removed, a wallet own server and Connection servers are kept', () async {
    final store = MemorySecretStore()
      ..values.addAll({
        'desk.serverList.node.mainnet': _list([_epic, _lan, _lab], removed: ['node.net.invalid:3413']),
        'app.node.mainnet': _lan,
        'desk.serverList.relay.mainnet': _list(['box.stack.invalid', 'box.epic.invalid'], removed: ['box.lab.invalid']),
        'app.relay.mainnet': 'box.stack.invalid',
        'desk.settings': jsonEncode({'useStatusSite': false, 'theme': 'dark'}),
        'desk.wallet.mainnet.0123456789abcdef0123456789abcdef': jsonEncode({'name': 'Old', 'epicbox': 'box.old.invalid'}),
        'desk.pairingRelays.mainnet': jsonEncode(['box.meet.invalid']),
      });
    final c = await open();
    await importLegacySettings(store, c, walletIds: () async => ['0123456789abcdef0123456789abcdef']);

    expect(c.settings.nodeUrls, [_lan, _epic, _lab, _stack, _testLan]);
    expect(boxes(c.settings), ['box.stack.invalid', 'box.epic.invalid', 'box.old.invalid', 'box.meet.invalid', 'box.net.invalid']);
    expect(c.settings.statusEnabled, isFalse);
  });

  test('older shapes: desktop My nodes with removedNodes, phone myNodes and myRelays', () async {
    final desk = MemorySecretStore()
      ..values.addAll({
        'desk.nodes': jsonEncode([
          {'url': _lan, 'label': 'Home'},
        ]),
        'desk.prefs': jsonEncode({'removedNodes': [_stack]}),
        'app.node.mainnet': _net,
      });
    final c = await open();
    await importLegacySettings(desk, c);
    expect(c.settings.nodeUrls, [_net, _lan, _lab, _epic, _testLan]);
    expect(boxes(c.settings), _defaultBoxes, reason: 'nothing stored for Epicbox: the default list');
    await c.close();
    opened.clear();
    await file.delete();

    final phone = MemorySecretStore()
      ..values.addAll({
        'app.myNodes.mainnet': jsonEncode([_lan]),
        'app.myRelays.mainnet': jsonEncode([_ownBox]),
      });
    final p = await open();
    await importLegacySettings(phone, p);
    expect(p.settings.nodeUrls, [_lan, ..._defaultNodes], reason: 'no node was picked: the first stays the own one');
    expect(boxes(p.settings), [_ownBox, ..._defaultBoxes]);
  });

  test('already ran 26.10.24 with the default copy untouched: imported as on a first start', () async {
    // 26.10.24 wrote the default copy and kept running on it.
    await (await open()).close();
    opened.clear();
    expect(await file.readAsString(), shippedText);
    final store = MemorySecretStore()
      ..values.addAll({
        'desk.serverList.node.mainnet': _list([..._defaultNodes, _lan]),
        'app.node.mainnet': _lan,
        'app.relay.mainnet': _ownBox,
      });
    final c = await open();
    await importLegacySettings(store, c);
    expect(c.settings.nodeUrls, [_lan, ..._defaultNodes]);
    expect(boxes(c.settings), [_ownBox, ..._defaultBoxes]);
  });

  test('already ran 26.10.24 and the user changed a list since: that change stays, own servers join its end', () async {
    await (await open()).close();
    opened.clear();
    // On 26.10.24 the user picked another default node and dropped one.
    final text = await file.readAsString();
    await file.writeAsString(
      text.replaceFirst(RegExp(r'\[node\][\s\S]*?\]\n'), '[node]\nservers = [\n  "$_stack",\n  "$_lab",\n  "$_epic",\n]\n'),
    );
    final store = MemorySecretStore()
      ..values.addAll({
        'desk.serverList.node.mainnet': _list([_lan, ..._defaultNodes]),
        'app.node.mainnet': _lan,
        'app.relay.mainnet': _ownBox,
        'desk.settings': jsonEncode({'useStatusSite': false}),
      });
    final c = await open();
    expect(c.settings.nodeUrls, [_stack, _lab, _epic]);
    await importLegacySettings(store, c);
    expect(c.settings.nodeUrls, [_stack, _lab, _epic, _lan], reason: 'the newer pick stays in use; dropped defaults stay out');
    expect(boxes(c.settings), [_ownBox, ..._defaultBoxes], reason: 'the Epicbox list was untouched');
    expect(c.settings.statusEnabled, isFalse);
  });

  test('once: a later start leaves the file alone, even after the user changes it', () async {
    final store = MemorySecretStore()
      ..values.addAll({'app.node.mainnet': _lan, 'app.relay.mainnet': _ownBox});
    final c = await open();
    await importLegacySettings(store, c);
    expect(c.settings.nodeUse, _lan);
    await c.setAll({'node.servers': [_lab]});
    await importLegacySettings(store, c);
    expect(c.settings.nodeUrls, [_lab]);
  });

  test('nothing stored: the default copy stays byte for byte, and the import is marked done', () async {
    final store = MemorySecretStore();
    final c = await open();
    await importLegacySettings(store, c);
    expect(await file.readAsString(), shippedText);
    expect(store.values.keys, [legacyImportedKey]);
  });

  test('values the file would refuse are left out; a store that cannot be read is tried again', () async {
    final store = MemorySecretStore()
      ..values.addAll({
        'app.serverList.node.mainnet': _list(['not a node', _lan]),
        'app.node.mainnet': 'https://node.invalid/path?x=1',
        'app.relay.mainnet': 'bad host name!',
      });
    final c = await open();
    await importLegacySettings(store, c);
    expect(c.settings.nodeUrls, [_lan, ..._defaultNodes]);
    expect(boxes(c.settings), _defaultBoxes);

    final broken = _FailingStore();
    final d = await open();
    await importLegacySettings(broken, d);
    expect(broken.written, isEmpty, reason: 'not marked: the next start tries again');
  });
}

class _FailingStore implements SecretStore {
  final written = <String>[];

  @override
  Future<String?> read(String key) async => throw const FileSystemException('locked');

  @override
  Future<void> write(String key, String value) async => written.add(key);

  @override
  Future<void> delete(String key) async {}
}
