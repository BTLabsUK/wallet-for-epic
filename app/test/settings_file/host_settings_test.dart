// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/settings_layout.dart';
import 'package:epic_wallet/src/settings_file/settings_merge.dart';
import 'package:epic_wallet/src/settings_file/toml_scan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_settings.dart';

String get _shippedText => File('assets/settings/settings.toml').readAsStringSync();

void main() {
  group('the shipped file', () {
    test('parses, has every key the model reads, and every value is good', () {
      final doc = parseSettingsToml(_shippedText);
      for (final k in settingsKeys) {
        expect(rawValue(doc, k.path), isNotNull, reason: k.path);
      }
      final s = HostSettings.fromText(_shippedText);
      final read = readSettings(_shippedText, shipped: s);
      expect(read.issues, isEmpty);
      expect(read.unknown, isEmpty);
      expect(s.version, 1);
      expect(s.nodeServers, isNotEmpty);
      expect(s.nodeServers.map((n) => n.url), contains(s.nodeUse));
      expect(s.epicboxServers.map((e) => e.label), contains(s.epicboxUse));
      expect(s.statusEnabled, isTrue);
      expect(s.updatesCheck, isTrue);
      expect(s.torOnions.where((o) => !o.tls).single.onionPort, 80);
      expect(s.explorerKernel('k'), isNull);
    });

    test('has a comment over every key', () {
      final scan = TomlScan(_shippedText);
      for (final st in scan.stmts) {
        if (st.kind != TomlStmtKind.keyValue || st.path.contains('#0') || st.path.any((p) => p.startsWith('#'))) {
          continue;
        }
        expect(scan.attachedComments(st), isNotEmpty, reason: '${st.dotted} has no comment');
      }
    });
  });

  group('the test file', () {
    test('has the shipped layout with example hosts only', () {
      final s = testSettings();
      expect(s.values.keys.toSet(), HostSettings.fromText(_shippedText).values.keys.toSet());
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

    test('a missing key reads as shipped', () {
      final r = readSettings('version = 1\n[node]\nuse = "https://n.example.invalid"\n', shipped: shipped);
      expect(r.settings.nodeUse, 'https://n.example.invalid');
      expect(r.settings.epicboxServers, shipped.epicboxServers);
      expect(r.issues, isEmpty);
    });

    test('a bad value is skipped with its line and problem; the last good value is used', () {
      const text = 'version = 1\n[node]\nuse = "ftp://n.example.invalid"\n\n[status]\nenabled = "yes"\n';
      final lastGood = shipped.withValues({'node.use': 'https://good.example.invalid'});
      final r = readSettings(text, shipped: shipped, lastGood: lastGood);
      expect(r.issues, [
        const ValueIssue('node.use', 3, ValueProblem.notNodeAddress),
        const ValueIssue('status.enabled', 6, ValueProblem.notSwitch),
      ]);
      expect(r.settings.nodeUse, 'https://good.example.invalid');
      expect(r.settings.statusEnabled, shipped.statusEnabled);
    });

    test('a bad server entry names the line of its field', () {
      const text = '[[epicbox.servers]]\nhost = "a.example.invalid"\n\n[[epicbox.servers]]\nhost = "b.example.invalid"\nport = 99999\n';
      final r = readSettings(text, shipped: shipped);
      expect(r.issues.single, const ValueIssue('epicbox.servers', 6, ValueProblem.notPort));
      expect(r.settings.epicboxServers, shipped.epicboxServers);
    });

    test('unknown keys are named with their lines, values kept out', () {
      const text = '[epicbox]\ndefualt = "x"\n[[node.servers]]\nurl = "https://a.example.invalid"\nweight = 3\n[future]\nx = 1\n';
      final r = readSettings(text, shipped: shipped);
      expect(r.unknown.map((u) => '${u.key}@${u.line}'), [
        'epicbox.defualt@2',
        'node.servers.weight@5',
        'future@6',
      ]);
      expect(r.settings.nodeServers.single.url, 'https://a.example.invalid');
    });

    test('a syntax error names its line', () {
      expect(
        () => readSettings('version = 1\n[node\nuse = "x"\n', shipped: shipped),
        throwsA(isA<SettingsSyntaxError>().having((e) => e.line, 'line', 2)),
      );
      expect(
        () => readSettings('[node]\nuse = "a"\nuse = "b"\n', shipped: shipped),
        throwsA(isA<SettingsSyntaxError>().having((e) => e.line, 'line', 3)),
      );
    });
  });

  group('values', () {
    final s = testSettings();

    test('withValues checks what the app sets', () {
      final n = s.withValues({
        'epicbox.servers': [const EpicboxServer(host: 'n.example.invalid', port: 8443)],
      });
      expect(n.epicboxServers.single.label, 'n.example.invalid:8443');
      expect(() => s.withValues({'node.use': 'not a url'}), throwsArgumentError);
      expect(() => s.withValues({'node.nope': 'x'}), throwsArgumentError);
    });

    test('allHosts names every host and leaves domain lists out', () {
      final hosts = s.allHosts;
      expect(hosts, containsAll(['node.lab.example.invalid', 'epicbox.epic.example.invalid', '192.0.2.10']));
      expect(hosts, contains('lab.example.invalid'), reason: 'the e-mail host');
      expect(hosts, contains('statusaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.onion'));
      expect(hosts, isNot(contains('.vpn.invalid')));
      expect(hosts, isNot(contains('BT Labs')));
    });

    test('explorer links fill their placeholder', () {
      expect(s.explorerBlock(12), endsWith('/block/12'));
    });
  });

  group('version merge', () {
    const shipped = '''
version = 2

[node]
# Use.
use = "https://a.example.invalid"
removed = []

# The list.
[[node.servers]]
url = "https://a.example.invalid"

# New in 2.
[[node.servers]]
url = "https://new.example.invalid"

[[node.servers]]
url = "https://gone.example.invalid"

[pairing]
servers = ["p1.example.invalid", "p2.example.invalid"]

# Status.
[status]

# On.
enabled = true
''';

    test('adds what is missing, appends new servers, keeps everything of the user', () {
      const user = '''
version = 1

[node]
use = "https://mine.example.invalid" # mine
removed = ["gone.example.invalid:443"]

[[node.servers]]
url = "https://mine.example.invalid"

[[node.servers]]
url = "https://a.example.invalid"

[pairing]
servers = ["p1.example.invalid"]
''';
      final merged = mergeShippedVersion(user, shipped)!;
      expect(merged, '''
version = 2

[node]
use = "https://mine.example.invalid" # mine
removed = ["gone.example.invalid:443"]

[[node.servers]]
url = "https://mine.example.invalid"

[[node.servers]]
url = "https://a.example.invalid"

# New in 2.
[[node.servers]]
url = "https://new.example.invalid"

[pairing]
servers = ["p1.example.invalid"]

# Status.
[status]

# On.
enabled = true
''');
      expect(mergeShippedVersion(merged, shipped), isNull);
    });

    test('a file at the shipped version or newer is left alone', () {
      expect(mergeShippedVersion('version = 2\n', shipped), isNull);
      expect(mergeShippedVersion('version = 3\n', shipped), isNull);
    });

    test('removed matches Epicbox by host on 443', () {
      expect(isRemovedServer('epicbox.servers', {'host': 'a.example.invalid', 'port': 443}, ['a.example.invalid']), isTrue);
      expect(isRemovedServer('epicbox.servers', {'host': 'a.example.invalid', 'port': 8443}, ['a.example.invalid']), isFalse);
      expect(isRemovedServer('node.servers', {'url': 'https://a.example.invalid'}, ['a.example.invalid:443']), isTrue);
    });
  });
}
