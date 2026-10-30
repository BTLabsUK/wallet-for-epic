// SPDX-License-Identifier: Apache-2.0
// The network mode in settings.toml (network_mode_file.dart): written only while it is not
// Normal, with its comment, taken out again for Normal; a hand edit applies to the gate at
// once; the one-time move of the store's old mode (Offline lands in Node only), and the start
// that applies the file's mode before anything can connect.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings_file/network_mode_file.dart';
import 'package:epic_wallet/src/settings_file/settings_backend_io.dart';
import 'package:epic_wallet/src/settings_file/settings_controller.dart';
import 'package:epic_wallet/src/settings_file/settings_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_settings.dart';

void main() {
  late Directory dir;
  late File file;
  final shippedText = testSettingsText();
  final config = testConfig();
  final opened = <SettingsFileController>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('network_mode_file_test');
    file = File('${dir.path}/settings.toml');
  });

  tearDown(() async {
    for (final c in opened) {
      await c.close();
    }
    opened.clear();
    NetGate.set(NetworkMode.standard);
    await dir.delete(recursive: true);
  });

  Future<SettingsFileController> open() async {
    final c = await SettingsFileController.open(backend: FileSettingsBackend(dir), shippedText: shippedText, config: config);
    opened.add(c);
    return c;
  }

  group('settings.toml', () {
    test('Normal writes nothing; another mode adds [network] with its comment; Normal takes it out', () async {
      final c = await open();
      expect(networkModeIn(c.settings), NetworkMode.standard);
      expect(file.readAsStringSync(), isNot(contains('[network]')));
      for (final m in [NetworkMode.nodeOnly, NetworkMode.killSwitch, NetworkMode.torOnly]) {
        await saveNetworkMode(m, c.setAll);
        final text = file.readAsStringSync();
        expect(text, contains('[network]'));
        expect(text, contains('# Network mode: tor_only, node_only or kill_switch'));
        expect(text, contains('mode = "${networkModeText(m)}"'));
        expect(networkModeIn(c.settings), m);
      }
      await saveNetworkMode(NetworkMode.standard, c.setAll);
      final text = file.readAsStringSync();
      expect(text, isNot(contains('[network]')));
      expect(text, isNot(contains('Network mode')));
      expect(text, shippedText, reason: 'back to the default copy as it was');
    });

    test('a hand edit is read as the mode; an unknown value is refused with a notice', () async {
      final c = await open();
      file.writeAsStringSync('${file.readAsStringSync()}\n[network]\nmode = "kill_switch"\n');
      await c.reload();
      expect(networkModeIn(c.settings), NetworkMode.killSwitch);
      file.writeAsStringSync(file.readAsStringSync().replaceAll('kill_switch', 'off'));
      await c.reload();
      expect(c.notices, isNotEmpty);
      expect(networkModeIn(c.settings), NetworkMode.killSwitch, reason: 'the last good value stays');
    });

    test('a hand edit reaches the gate at once through the opened file', () async {
      final store = MemorySecretStore();
      final c = await openAppSettingsOn(backend: FileSettingsBackend(dir), store: store, shippedText: shippedText, configText: testConfigText());
      opened.add(c);
      expect(NetGate.mode, NetworkMode.standard);
      file.writeAsStringSync('${file.readAsStringSync()}\n[network]\nmode = "node_only"\n');
      await c.reload();
      expect(NetGate.mode, NetworkMode.nodeOnly);
      file.writeAsStringSync(shippedText);
      await c.reload();
      expect(NetGate.mode, NetworkMode.standard);
    });

    test('old names: offline is Node only everywhere it was stored', () {
      expect(networkModeNamed('offline'), NetworkMode.nodeOnly);
      expect(AdvancedPrefs.decode('outputs|offline').networkMode, NetworkMode.nodeOnly);
      expect(AdvancedPrefs.fromJson({'networkMode': 'offline'}).networkMode, NetworkMode.nodeOnly);
      expect(networkModeNamed('kill_switch'), NetworkMode.killSwitch);
      expect(networkModeNamed('nonsense'), isNull);
      expect(AdvancedPrefs.decode('outputs|killSwitch').encode(mode: false), 'outputs|standard');
      expect(AdvancedPrefs.none.withMode(NetworkMode.nodeOnly).toJson(mode: false), isNot(contains('networkMode')));
    });
  });

  group('the move of the store\'s old mode', () {
    Future<(SettingsFileController, MemorySecretStore)> run(Map<String, String> stored) async {
      final store = MemorySecretStore()..values.addAll(stored);
      final c = await open();
      await importNetworkMode(store, c);
      return (c, store);
    }

    test('phone Offline lands in Node only; the features stay where they were', () async {
      final (c, store) = await run({'app.advanced_prefs': 'outputs,technicalDetails|offline|noFailover'});
      expect(networkModeIn(c.settings), NetworkMode.nodeOnly);
      expect(file.readAsStringSync(), contains('mode = "node_only"'));
      expect(store.values['app.advanced_prefs'], 'outputs,technicalDetails|offline|noFailover', reason: 'never rewritten');
      expect(store.values[networkModeMovedKey], isNotNull);
    });

    test('desktop Offline lands in Node only, Tor only stays Tor only', () async {
      final (c, _) = await run({
        'desk.settings': jsonEncode({
          'theme': 'dark',
          'advanced': {'features': ['logs'], 'networkMode': 'offline'},
        }),
      });
      expect(networkModeIn(c.settings), NetworkMode.nodeOnly);
      // Another install: its file still the default copy.
      await saveNetworkMode(NetworkMode.standard, c.setAll);
      final (t, _) = await run({'app.advanced_prefs': '|torOnly'});
      expect(networkModeIn(t.settings), NetworkMode.torOnly);
    });

    test('Normal or nothing stored: nothing written, marked', () async {
      for (final stored in [<String, String>{}, {'app.advanced_prefs': 'outputs|standard'}]) {
        final before = file.existsSync() ? file.readAsStringSync() : null;
        final (c, store) = await run(stored);
        expect(networkModeIn(c.settings), NetworkMode.standard);
        if (before != null) expect(file.readAsStringSync(), before);
        expect(store.values[networkModeMovedKey], isNotNull);
      }
    });

    test('a second run never overrides a later choice of the user', () async {
      final (c, store) = await run({'app.advanced_prefs': '|offline'});
      expect(networkModeIn(c.settings), NetworkMode.nodeOnly);
      // The user picks Normal later; the old record is still there.
      await saveNetworkMode(NetworkMode.standard, c.setAll);
      await importNetworkMode(store, c);
      expect(networkModeIn(c.settings), NetworkMode.standard);
      expect(file.readAsStringSync(), isNot(contains('[network]')));
    });

    test('a file that already names a mode keeps it', () async {
      final store = MemorySecretStore()..values['app.advanced_prefs'] = '|offline';
      final c = await open();
      await saveNetworkMode(NetworkMode.killSwitch, c.setAll);
      await importNetworkMode(store, c);
      expect(networkModeIn(c.settings), NetworkMode.killSwitch);
      expect(store.values[networkModeMovedKey], isNotNull);
    });

    test('a store that cannot be read is tried again at the next start, unmarked', () async {
      final c = await open();
      final store = _BrokenStore();
      await importNetworkMode(store, c);
      expect(store.values[networkModeMovedKey], isNull);
      expect(networkModeIn(c.settings), NetworkMode.standard);
    });
  });

  group('start', () {
    test('the file\'s mode reaches the gate before openAppSettings returns, the old mode moved first', () async {
      final store = MemorySecretStore()..values['app.advanced_prefs'] = '|offline';
      // The data folder's own file: the move runs.
      final c = await openAppSettingsOn(backend: FileSettingsBackend(dir), store: store, configText: testConfigText(), bundle: _Bundle(shippedText));
      opened.add(c);
      expect(NetGate.mode, NetworkMode.nodeOnly);
      // So the first request of the app (the price, the status site, an update check) is
      // refused before a connection is made.
      await expectLater(httpGet(Uri.parse('https://status.example.invalid/x')), throwsA(isA<NetError>().having((e) => e.message, 'm', netModeError)));
    });

    test('both mains open the settings (and so apply the mode) before anything that connects', () {
      void order(String path, List<String> after) {
        final text = File(path).readAsStringSync();
        final open = text.indexOf(path.endsWith('main.dart') ? 'await _openSettings(store)' : 'openAppSettings(');
        expect(open, greaterThan(0), reason: path);
        for (final a in after) {
          final at = text.indexOf(a);
          expect(at, greaterThan(open), reason: '$path: $a before the settings opened');
        }
      }

      order('lib/main.dart', ['phoneTorAtLaunch(', 'TorNet.hold', 'statusSite.followSettings()', 'runApp(']);
      order('lib/main_desktop.dart', ['statusSite.followSettings()', 'relayDirectoryProvider', 'LepicDeskWallet(', 'resumeBuiltInNode()']);
    });
  });

}

class _BrokenStore extends MemorySecretStore {
  @override
  Future<String?> read(String key) async => throw const FileSystemException('store locked');
}

/// The default copy and app-config.toml as assets.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.settings);
  final String settings;

  @override
  Future<ByteData> load(String key) async => throw UnimplementedError(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      key == defaultSettingsAsset ? settings : key == appConfigAsset ? testConfigText() : throw StateError(key);
}
