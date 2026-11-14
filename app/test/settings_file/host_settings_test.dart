// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/settings_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_settings.dart';

String get _defaultText => File('assets/config/settings.default.toml').readAsStringSync();
String get _configText => File('assets/config/app-config.toml').readAsStringSync();

void main() {
  group('the shipped pair', () {
    test('the default copy has every key of settings.toml, all good, and nothing else', () {
      final doc = parseSettingsToml(_defaultText);
      for (final k in settingsKeys) {
        // An optional key (the built-in node's ports) is in the file only while set.
        expect(rawValue(doc, k.path), k.byDefault == null ? isNotNull : isNull, reason: k.path);
      }
      final s = HostSettings.fromText(_defaultText, config: AppConfig.fromText(_configText));
      expect(s.localNodePortsSet, isFalse);
      expect(s.localNodeApiPort, s.config.localNodeApiPort, reason: 'the built-in node ports come from app-config.toml');
      expect(s.localNodeP2pPort, s.config.localNodeP2pPort);
      final read = readSettings(_defaultText, shipped: s);
      expect(read.issues, isEmpty);
      expect(read.unknown, isEmpty);
      expect(s.statusEnabled && s.updatesCheck && s.priceEnabled, isTrue);
    });

    test('app-config.toml has every key, all good', () {
      final doc = parseSettingsToml(_configText);
      for (final k in configKeys) {
        if (k.byDefault == null) expect(rawValue(doc, k.path), isNotNull, reason: k.path);
      }
      final c = AppConfig.fromText(_configText);
      expect(c.torOnions.where((o) => !o.tls).single.onionPort, 80);
      expect(c.updateManifests, hasLength(3));
      expect(c.supportDonation, isNotNull);
      expect(c.explorerBlock(3774693), endsWith('/3774693'));
      expect(c.explorerIndexed(3774693), endsWith('/blockchain_block/3774693'));
      expect(c.statusReach(3415), contains('port=3415'));
      expect(c.localNodeApiPort, isNot(c.localNodeP2pPort));
    });

    test('an app-config.toml with the retired watch keys still loads; watch_for_s is capped at 600', () {
      const old = 'watch_fast_every_s = 4\nwatch_fast_for_s = 120\nwatch_slow_every_s = 10\n';
      final withOld = _configText.replaceFirst('watch_for_s', '${old}watch_for_s');
      expect(withOld, isNot(_configText));
      expect(AppConfig.fromText(withOld).watchFor, const Duration(seconds: 300));
      final tooLong = _configText.replaceFirst(RegExp(r'watch_for_s = \d+'), 'watch_for_s = 601');
      expect(() => AppConfig.fromText(tooLong), throwsStateError);
    });

    test('the first entry of each list is in use; the next node is the fallback', () {
      final s = HostSettings.fromText(_defaultText, config: AppConfig.fromText(_configText));
      expect(s.nodeUse, s.nodeUrls.first);
      expect(s.nodeFallback, s.nodeUrls[1]);
      expect(s.epicboxUse, s.epicboxServers.first.label);
      expect(s.pairingServers, [for (final b in s.epicboxServers.take(s.config.pairingServerCount)) b.label]);
      expect(s.deviceLinkServers, hasLength(s.config.linkServerCount));
      expect(s.nodeServers.first.operator, isNotNull, reason: 'operators by domain');
    });
  });

  group('the test pair', () {
    test('has the shipped layout with example hosts only', () {
      final s = testSettings();
      final shipped = HostSettings.fromText(_defaultText, config: AppConfig.fromText(_configText));
      expect(s.values.keys.toSet(), shipped.values.keys.toSet());
      expect(s.config.values.keys.toSet(), shipped.config.values.keys.toSet());
      for (final h in s.allHosts) {
        final ok =
            h.endsWith('.invalid') ||
            h.startsWith('192.0.2.') ||
            h.startsWith('198.51.100.') ||
            h.startsWith('203.0.113.') ||
            h.endsWith('.onion');
        expect(ok, isTrue, reason: h);
      }
      expect(hostSettings.nodeUse, s.nodeUse, reason: 'flutter_test_config loads it');
    });
  });

  group('readSettings', () {
    final shipped = testSettings();

    test('a missing key reads as the default copy; nothing is merged', () {
      final r = readSettings('[node]\nservers = ["https://n.example.invalid"]\n', shipped: shipped);
      expect(r.settings.nodeUse, 'https://n.example.invalid');
      expect(r.settings.nodeUrls, ['https://n.example.invalid'], reason: 'no default server joins');
      expect(r.settings.epicboxServers, shipped.epicboxServers);
      expect(r.settings.statusEnabled, shipped.statusEnabled);
      expect(r.issues, isEmpty);
    });

    test('a bad value is skipped with its line and problem; the last good value is used', () {
      const text = '[node]\nservers = ["ftp://n.example.invalid"]\n\n[online]\nstatus_site = "yes"\n';
      final lastGood = shipped.withValues({'node.servers': ['https://good.example.invalid']});
      final r = readSettings(text, shipped: shipped, lastGood: lastGood);
      expect(r.issues, [
        const ValueIssue('node.servers', 2, ValueProblem.notNodeAddress),
        const ValueIssue('online.status_site', 5, ValueProblem.notSwitch),
      ]);
      expect(r.settings.nodeUse, 'https://good.example.invalid');
      expect(r.settings.statusEnabled, shipped.statusEnabled);
    });

    test('listener_challenge_rounds is 3 as shipped; 2 to 10 load, 0, 1 and 11 do not', () {
      expect(AppConfig.fromText(_configText).listenerChallengeRounds, 3);
      String rounds(int n) => _configText.replaceFirst('listener_challenge_rounds = 3', 'listener_challenge_rounds = $n');
      for (final good in [2, 10]) {
        expect(AppConfig.fromText(rounds(good)).listenerChallengeRounds, good);
      }
      for (final bad in [0, 1, 11]) {
        expect(() => AppConfig.fromText(rounds(bad)), throwsStateError, reason: '$bad');
      }
    });

    test('[local_node] sets the built-in node ports; a port under 1024 or equal text is skipped', () {
      final r = readSettings('[local_node]\napi_port = 13413\np2p_port = 13414\n', shipped: shipped);
      expect(r.issues, isEmpty);
      expect(r.unknown, isEmpty);
      expect(r.settings.localNodePortsSet, isTrue);
      expect(r.settings.localNodeApiPort, 13413);
      expect(r.settings.localNodeP2pPort, 13414);
      expect(r.settings.nodeUrls, shipped.nodeUrls, reason: 'the rest reads as the default copy');

      final bad = readSettings('[local_node]\napi_port = 80\np2p_port = "x"\n', shipped: shipped);
      expect(bad.issues, [const ValueIssue('local_node.api_port', 2, ValueProblem.notPort), const ValueIssue('local_node.p2p_port', 3, ValueProblem.notPort)]);
      expect(bad.settings.localNodeApiPort, shipped.config.localNodeApiPort);
      expect(bad.settings.localNodeP2pPort, shipped.config.localNodeP2pPort);

      final one = readSettings('[local_node]\napi_port = 13413\n', shipped: shipped);
      expect(one.settings.localNodeApiPort, 13413);
      expect(one.settings.localNodeP2pPort, shipped.config.localNodeP2pPort, reason: 'a key left out keeps the default');
    });

    test('localNodePortValues writes a port only while it differs from the default', () {
      final v = localNodePortValues(shipped, api: shipped.config.localNodeApiPort, p2p: 13414);
      expect(v, {'local_node.api_port': notSet, 'local_node.p2p_port': 13414});
      expect(checkAppValue('local_node.api_port', notSet), notSet, reason: 'the "not set" value passes as a removal');
      expect(() => checkAppValue('local_node.api_port', 80), throwsArgumentError);
    });

    test('a bad Epicbox server is not used', () {
      final r = readSettings('[epicbox]\nservers = ["a.example.invalid", "b.example.invalid:99999"]\n', shipped: shipped);
      expect(r.issues.single, const ValueIssue('epicbox.servers', 2, ValueProblem.notEpicboxServer));
      expect(r.settings.epicboxServers, shipped.epicboxServers);
    });

    test('empty lists are read as none configured, without a crash', () {
      final r = readSettings('[node]\nservers = []\n[epicbox]\nservers = []\n', shipped: shipped);
      expect(r.issues, isEmpty);
      expect(r.settings.hasNode, isFalse);
      expect(r.settings.nodeUse, '');
      expect(r.settings.nodeFallback, '');
      expect(r.settings.hasEpicbox, isFalse);
      expect(r.settings.epicboxUse, '');
      expect(r.settings.pairingServers, isEmpty);
      expect(r.settings.deviceLinkServers, isEmpty);
    });

    test('unknown keys are named with their lines; old layouts too', () {
      const text = 'version = 1\n[node]\nuse = "https://a.example.invalid"\n[future]\nx = 1\n';
      final r = readSettings(text, shipped: shipped);
      expect(r.unknown.map((u) => '${u.key}@${u.line}'), ['version@1', 'node.use@3', 'future@4']);
    });

    test('a syntax error names its line', () {
      expect(
        () => readSettings('[node\nservers = []\n', shipped: shipped),
        throwsA(isA<SettingsSyntaxError>().having((e) => e.line, 'line', 1)),
      );
      expect(
        () => readSettings('[online]\nprice = true\nprice = false\n', shipped: shipped),
        throwsA(isA<SettingsSyntaxError>().having((e) => e.line, 'line', 3)),
      );
    });
  });

  group('values', () {
    final s = testSettings();

    test('withValues checks what the app sets', () {
      final n = s.withValues({'epicbox.servers': ['n.example.invalid:8443']});
      expect(n.epicboxServers.single.label, 'n.example.invalid:8443');
      expect(n.epicboxUse, 'n.example.invalid:8443');
      expect(() => s.withValues({'node.servers': ['not a url']}), throwsArgumentError);
      expect(() => s.withValues({'node.use': 'https://a.example.invalid'}), throwsArgumentError);
      expect(s.withValues({'node.check_timeout_s': 3}).config.nodeCheckTimeout, const Duration(seconds: 3));
    });

    test('operators come from app-config.toml by domain, the longest first', () {
      expect(s.config.operatorOf('node.lab.invalid'), 'BT Labs');
      expect(s.config.operatorOf('deep.box.net.invalid'), 'EpicNet');
      expect(s.config.operatorOf('lab.invalid'), 'BT Labs');
      expect(s.config.operatorOf('other.invalid'), isNull);
      expect(s.nodeServers.last.operator, 'Test LAN');
    });

    test('allHosts names every host and leaves domain lists out', () {
      final hosts = s.allHosts;
      expect(hosts, containsAll(['node.lab.invalid', 'box.epic.invalid', '192.0.2.10']));
      expect(hosts, contains('statusaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.onion'));
      expect(hosts, isNot(contains('.vpn.invalid')));
      expect(hosts, isNot(contains('BT Labs')));
    });

    test('the explorer link fills its placeholder', () {
      expect(s.explorerBlock(12), endsWith('/blockdetail/12'));
    });
  });

  group('an entry left out of app-config.toml is not configured', () {
    AppConfig without(List<String> keys) => AppConfig.fromText(testConfigWithout(keys));

    test('donation', () => expect(without(['donation']).supportDonation, isNull));
    test('explorer', () {
      final c = without(['[explorer]']);
      expect([c.explorerBlock(1), c.explorerIndexed(1)], everyElement(isNull));
    });
    test('the whole status site', () {
      final c = without(['[status]']);
      expect([c.statusDirectory, c.statusIcons, c.statusPrice, c.statusIp, c.statusReach(1)], everyElement(isNull));
    });
    test('one status address', () {
      final c = without(['icons']);
      expect(c.statusIcons, isNull);
      expect(c.statusDirectory, isNotNull);
    });
    test('the reach check', () => expect(without(['ip', 'reach', 'reach_timeout_s']).statusIp, isNull));
    test('the price source', () => expect(without(['source']).priceSource, isNull));
    test('the update manifests', () {
      final c = AppConfig.fromText(testConfigText().replaceFirst(RegExp(r'manifests = \[[^\]]*\]'), 'manifests = []'));
      expect(c.updateManifests, isEmpty);
    });
    test('support report', () {
      final c = without(['report']);
      expect(c.supportReport, isNull);
    });
    test('each link', () {
      final c = without(['website', 'community']);
      expect(c.linkWebsite, isNull);
      expect(c.linkCommunity, isNull);
      expect(c.linkSource, isNotNull);
    });
    test('a timing key is needed while its address is there', () {
      expect(() => without(['timeout_s']), throwsStateError, reason: 'status, price, updates, support timeouts with their addresses');
      expect(() => without(['[status]', 'reach_timeout_s']), returnsNormally);
    });
    test('[contacts] reads as 7 days and 120 s', () {
      final c = without(['[contacts]']);
      expect(c.contactsStaleAfter, const Duration(days: 7));
      expect(c.contactsCheckWait, const Duration(seconds: 120));
    });
    test('a required key is still required', () {
      expect(() => without(['listen_port']), throwsStateError);
    });
  });
}
