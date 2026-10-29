// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/settings_layout.dart';
import 'package:epic_wallet/src/settings_file/toml_edit.dart';
import 'package:epic_wallet/src/settings_file/toml_scan.dart';
import 'package:flutter_test/flutter_test.dart';

const _doc = '''# Top comment
version = 1

[node]
# my node, keep this
use = "https://a.example.invalid" # trailing, keep
weird = "has # and [brackets] in it"
removed = [
  "x.example.invalid:443", # inside the array
  "y.example.invalid:443",
]

# The list
[[node.servers]]
url = "https://a.example.invalid"
operator = "A"
mine = true

# B is mine
[[node.servers]]
url = "https://b.example.invalid"
operator = "B"

[[node.servers]]
url = "https://c.example.invalid"

[epicbox]
use = "e.example.invalid"
renamed = { "o.example.invalid" = "n.example.invalid", "q" = "r" }
multi = """
line # not a comment
[not a table]
"""
''';

/// An array of tables as the editor still sets them (the onion routes of app-config.toml are
/// one); these two are the tests' own.
String _nodeIdentity(Map<String, Object?> e) => '${e['url'] ?? ''}'.toLowerCase().replaceFirst(RegExp(r'/$'), '');
String _epicboxIdentity(Map<String, Object?> e) => epicboxLabel('${e['host'] ?? ''}', e['port'] is int ? e['port']! as int : 443);

const nodeServersKind = TablesKind([
  EntryField('url', TextKind(checkNodeAddress), required: true),
  EntryField('operator', TextKind(anyText)),
], _nodeIdentity);

const epicboxServersKind = TablesKind(
  [
    EntryField('host', TextKind(checkEpicboxServer), required: true),
    EntryField('port', IntKind(min: 1, max: 65535, problem: ValueProblem.notPort), byDefault: 443),
    EntryField('operator', TextKind(anyText)),
  ],
  _epicboxIdentity,
  omitDefaults: {'port'},
);

List<Map<String, Object?>> _servers(String text) => [
  for (final e in rawValue(parseSettingsToml(text), 'node.servers')! as List) Map<String, Object?>.from(e as Map),
];

void main() {
  group('removeValue', () {
    test('a key goes with its comment; the last key takes its table along; a missing key is nothing', () {
      final e = TomlEditor('[node]\nuse = "a"\n\n# the ports\n[local_node]\n# mine\napi_port = 13413\np2p_port = 13414\n');
      e.removeValue('local_node.api_port');
      expect(e.text, '[node]\nuse = "a"\n\n# the ports\n[local_node]\np2p_port = 13414\n');
      e.removeValue('local_node.p2p_port');
      expect(e.text, '[node]\nuse = "a"\n');
      e.removeValue('local_node.p2p_port');
      expect(e.text, '[node]\nuse = "a"\n');
    });

    test('a table in the middle goes without leaving two blank lines', () {
      final e = TomlEditor('[local_node]\napi_port = 13413\n\n[node]\nuse = "a"\n');
      e.removeValue('local_node.api_port');
      expect(e.text, '[node]\nuse = "a"\n');
      final m = TomlEditor('[a]\nx = 1\n\n[local_node]\napi_port = 13413\n\n[node]\nuse = "a"\n');
      m.removeValue('local_node.api_port');
      expect(m.text, '[a]\nx = 1\n\n[node]\nuse = "a"\n');
    });
  });

  group('scan', () {
    test('finds keys, tables, blocks and multi-line values', () {
      final scan = TomlScan(_doc);
      expect(scan.key(['version'])!.start, 1);
      final use = scan.key(['node', 'use'])!;
      expect(use.start, 5);
      expect(use.comment, '# trailing, keep');
      expect(use.prefix, 'use = ');
      expect(scan.key(['node', 'weird'])!.end, 6);
      final removed = scan.key(['node', 'removed'])!;
      expect((removed.start, removed.end), (7, 10));
      expect(scan.arrayBlocks(['node', 'servers']), hasLength(3));
      expect(scan.key(['node', 'servers', '#1', 'operator'])!.start, 21);
      final multi = scan.key(['epicbox', 'multi'])!;
      expect(multi.end - multi.start, 3);
      expect(scan.header(['epicbox'])!.start, 26);
      // "[not a table]" sits in a string: no header there.
      expect(scan.stmts.where((s) => s.kind == TomlStmtKind.table), hasLength(2));
      expect(scan.lineOf(['node', 'servers', '#2', 'url']), 25);
    });

    test('keeps CRLF line endings', () {
      final text = _doc.replaceAll('\n', '\r\n');
      final e = TomlEditor(text)..setValue('node.use', 'https://z.example.invalid');
      expect(e.text, contains('use = "https://z.example.invalid" # trailing, keep\r\n'));
      expect(e.text.replaceAll('\r\n', ''), isNot(contains('\n')));
    });
  });

  group('encode', () {
    test('escapes strings and writes lists and inline tables', () {
      expect(encodeTomlValue('a"b\\c\n\u0001'), r'"a\"b\\c\n\u0001"');
      expect(encodeTomlValue(['a', 'b']), '["a", "b"]');
      expect(encodeTomlValue({'x.y': 'z', 'k': 'v'}), '{ "x.y" = "z", k = "v" }');
      expect(encodeTomlValue(true), 'true');
      expect(encodeTomlValue(443), '443');
      expect(encodeTomlValue(['a'], multiline: true), '[\n  "a",\n]');
      final back = parseSettingsToml('k = ${encodeTomlValue('q"\\\n\t#[]')}');
      expect(back['k'], 'q"\\\n\t#[]');
    });
  });

  group('setValue', () {
    test('replaces only the key, keeping its comment and every other line', () {
      final e = TomlEditor(_doc)..setValue('node.use', 'https://z.example.invalid');
      expect(e.text, _doc.replaceFirst('use = "https://a.example.invalid" # trailing', 'use = "https://z.example.invalid" # trailing'));
    });

    test('a multi-line list stays multi-line', () {
      final e = TomlEditor(_doc)..setValue('node.removed', ['p.example.invalid:443']);
      expect(e.text, contains('removed = [\n  "p.example.invalid:443",\n]\n\n# The list'));
      expect(parseSettingsToml(e.text)['node']['removed'], ['p.example.invalid:443']);
    });

    test('a missing key goes after the last key of its table, with the shipped comment', () {
      const shipped = '[node]\n\n# The fallback node.\nfallback = "https://f.example.invalid"\n';
      final e = TomlEditor(_doc, shipped: shipped)..setValue('node.fallback', 'https://g.example.invalid');
      expect(
        e.text,
        contains('  "y.example.invalid:443",\n]\n\n# The fallback node.\nfallback = "https://g.example.invalid"\n\n# The list'),
      );
      parseSettingsToml(e.text);
    });

    test('a missing table is added at the end with its comments', () {
      const shipped = '# --- Status ---\n[status]\n\n# On or off.\nenabled = true\n';
      final e = TomlEditor(_doc, shipped: shipped)..setValue('status.enabled', false);
      expect(e.text, endsWith('"""\n\n# --- Status ---\n[status]\n\n# On or off.\nenabled = false\n'));
      expect(parseSettingsToml(e.text)['status']['enabled'], false);
    });

    test('a root key goes before the first table', () {
      final e = TomlEditor('# head\n\n[node]\nuse = "x"\n')..setValue('version', 2);
      expect(e.text, '# head\n\nversion = 2\n\n[node]\nuse = "x"\n');
    });

    test('an inline table value is replaced in place', () {
      final e = TomlEditor(_doc)..setValue('epicbox.renamed', {'a.example.invalid': 'b.example.invalid'});
      expect(e.text, contains('renamed = { "a.example.invalid" = "b.example.invalid" }\nmulti'));
    });
  });

  group('setTables', () {
    test('reorders blocks, keeping their text, comments and unknown keys', () {
      final cur = _servers(_doc);
      final e = TomlEditor(_doc)..setTables('node.servers', nodeServersKind, [cur[2], cur[0], cur[1]], current: cur);
      expect(e.text, contains('''
# The list
[[node.servers]]
url = "https://c.example.invalid"

[[node.servers]]
url = "https://a.example.invalid"
operator = "A"
mine = true

# B is mine
[[node.servers]]
url = "https://b.example.invalid"
operator = "B"

[epicbox]'''));
      expect(_servers(e.text).map((s) => s['url']), [
        'https://c.example.invalid',
        'https://a.example.invalid',
        'https://b.example.invalid',
      ]);
    });

    test('removes a block with its comment and adds a new one at the end', () {
      final cur = _servers(_doc);
      final e = TomlEditor(_doc)
        ..setTables('node.servers', nodeServersKind, [
          cur[0],
          cur[2],
          {'url': 'https://d.example.invalid', 'operator': 'D'},
        ], current: cur);
      expect(e.text, isNot(contains('B is mine')));
      expect(e.text, contains('''
[[node.servers]]
url = "https://c.example.invalid"

[[node.servers]]
url = "https://d.example.invalid"
operator = "D"

[epicbox]'''));
      expect(e.text, contains('mine = true'));
    });

    test('changes only the field that changed inside a kept block', () {
      final cur = _servers(_doc);
      final changed = {...cur[0], 'operator': 'A2'};
      final e = TomlEditor(_doc)..setTables('node.servers', nodeServersKind, [changed, cur[1], cur[2]], current: cur);
      expect(e.text, _doc.replaceFirst('operator = "A"', 'operator = "A2"'));
    });

    test('an operator left out is removed; an unknown key stays', () {
      final cur = _servers(_doc);
      final e = TomlEditor(_doc)
        ..setTables('node.servers', nodeServersKind, [
          {'url': 'https://a.example.invalid'},
          cur[1],
          cur[2],
        ], current: cur);
      expect(e.text, _doc.replaceFirst('operator = "A"\n', ''));
    });

    test('Epicbox port 443 is not written; another port is', () {
      const text = '[epicbox]\nuse = "e"\n';
      final e = TomlEditor(text)
        ..setTables('epicbox.servers', epicboxServersKind, [
          {'host': 'a.example.invalid', 'port': 443, 'operator': 'A'},
          {'host': 'b.example.invalid', 'port': 8443},
        ]);
      expect(
        e.text,
        '[epicbox]\nuse = "e"\n\n[[epicbox.servers]]\nhost = "a.example.invalid"\noperator = "A"\n\n'
        '[[epicbox.servers]]\nhost = "b.example.invalid"\nport = 8443\n',
      );
    });

    test('an empty list is written as key = [] and gives way to blocks again', () {
      final cur = _servers(_doc);
      final e = TomlEditor(_doc)..setTables('node.servers', nodeServersKind, const [], current: cur);
      expect(e.text, isNot(contains('[[node.servers]]')));
      expect(rawValue(parseSettingsToml(e.text), 'node.servers'), isEmpty);
      expect(e.text, contains('# The list\n'));
      e.setTables('node.servers', nodeServersKind, [
        {'url': 'https://n.example.invalid'},
      ]);
      expect(e.text, isNot(contains('servers = []')));
      expect(_servers(e.text).single['url'], 'https://n.example.invalid');
    });

    test('a table without blocks gets them after its keys', () {
      const text = '[node]\nuse = "https://a.example.invalid"\n\n[epicbox]\nuse = "e"\n';
      final e = TomlEditor(text)
        ..setTables('node.servers', nodeServersKind, [
          {'url': 'https://a.example.invalid'},
        ]);
      expect(
        e.text,
        '[node]\nuse = "https://a.example.invalid"\n\n[[node.servers]]\nurl = "https://a.example.invalid"\n\n[epicbox]\nuse = "e"\n',
      );
    });
  });
}
