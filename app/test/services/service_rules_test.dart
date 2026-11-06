// SPDX-License-Identifier: Apache-2.0
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/scan/scan_text.dart';
import 'package:epic_wallet/src/services/service_check.dart';
import 'package:epic_wallet/src/services/service_folder_io.dart';
import 'package:epic_wallet/src/services/service_loader.dart';
import 'package:epic_wallet/src/services/service_rules.dart';
import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample_services.dart';

const _key = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK';
const _plain = '$_key@box.epic.invalid';
const _hint = 'exchange_check_note';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

String _file(String id, {String relay = 'box.other.invalid', Map<String, Object?> extra = const {}}) => jsonEncode({
  'schema': 1,
  'id': id,
  'rules': [
    {'kind': relayNeedsNote, 'relay': relay, 'hint': _hint},
  ],
  ...extra,
});

/// A bundle holding [files] under `assets/services/`.
final class _Bundle extends CachingAssetBundle {
  _Bundle(Map<String, String> files) : _files = {for (final e in files.entries) '$bundledServicesFolder${e.key}': e.value};
  final Map<String, String> _files;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final path in _files.keys)
          path: [
            {'asset': path},
          ],
      })!;
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(_files[key]!)));
  }
}

final class _Source implements ServiceSource {
  _Source(this.files);
  final Map<String, List<int>> files;

  @override
  String get label => 'test';

  @override
  Future<List<ServiceBytes>> read() async => [for (final e in files.entries) ServiceBytes(e.key, e.value)];
}

final class _Broken implements ServiceSource {
  @override
  String get label => 'broken';

  @override
  Future<List<ServiceBytes>> read() => throw const FileSystemException('no');
}

Future<ServiceRules> _load(Map<String, String> files) =>
    loadServices([_Source({for (final e in files.entries) e.key: utf8.encode(e.value)})]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('matchService', () {
    final rules = ServiceRules.from([parseServiceFile(sampleServiceFile)]);
    bool hits(String to) => matchService(to, rules)?.hints.contains(ServiceHint.exchangeCheckNote) ?? false;

    test('the relay matches whole, without case or port', () {
      expect(hits('$_key@$sampleRelay'), isTrue);
      expect(hits('$_key@EPICBOX.Exchange.Invalid'), isTrue);
      expect(hits('$_key@$sampleRelay:443'), isTrue);
    });

    test('near misses do not match', () {
      expect(hits('$_key@$sampleRelay.evil.invalid'), isFalse);
      expect(hits('$_key@x.$sampleRelay'), isFalse);
      expect(hits('$_key@${sampleRelay}x'), isFalse);
      expect(hits(_plain), isFalse);
      expect(hits(sampleRelay), isFalse);
      expect(hits(''), isFalse);
    });

    test('the text after the last @ is the relay', () {
      expect(hits('$sampleRelay@box.epic.invalid'), isFalse);
      expect(hits('x@y@$sampleRelay'), isTrue);
    });

    test('guidance is read-only', () {
      final guidance = matchService('$_key@$sampleRelay', rules)!;
      expect(() => guidance.hints.clear(), throwsUnsupportedError);
    });
  });

  group('noteWarning', () {
    test('a service hint shows while the message is empty', () {
      useSampleServices();
      const to = '$_key@$sampleRelay';
      expect(noteWarning(_l, to, '', codeAsks: false), _l.serviceHintExchangeCheckNote);
      expect(noteWarning(_l, to, '   ', codeAsks: false), _l.serviceHintExchangeCheckNote);
      expect(noteWarning(_l, to, '1', codeAsks: false), isNull);
      expect(noteWarning(_l, _plain, '', codeAsks: false), isNull);
    });

    test('a code asks on any relay, with or without service files', () {
      expect(noteWarning(_l, _plain, '', codeAsks: true), _l.sendNoteMissingCode);
      expect(noteWarning(_l, _plain, '1', codeAsks: true), isNull);
      useSampleServices();
      expect(noteWarning(_l, '$_key@$sampleRelay', '', codeAsks: true), _l.sendNoteMissingCode);
    });
  });

  group('parseServiceFile', () {
    test('unknown fields and rule kinds are ignored without a word', () {
      final file = parseServiceFile(jsonEncode({
        'schema': 1,
        'id': 'grown',
        'added_later': {'any': 'thing'},
        'rules': [
          {'kind': 'later_kind', 'anything': 1},
          {'kind': relayNeedsNote, 'relay': 'box.grown.invalid', 'hint': _hint, 'more': true},
        ],
      }));
      expect(file.rules.single.relay, 'box.grown.invalid');
      expect(file.skipped, isEmpty);
    });

    test('a rule that fails is left out, its neighbours stay', () {
      for (final relay in ['Box.Upper.invalid', '*.wild.invalid', 'box.port.invalid:443', 'https://box.url.invalid', 'nodot', 'bøx.ascii.invalid', '', 1]) {
        final file = parseServiceFile(jsonEncode({
          'schema': 1,
          'id': 'mixed',
          'rules': [
            {'kind': relayNeedsNote, 'relay': relay, 'hint': _hint},
            {'kind': relayNeedsNote, 'relay': 'box.good.invalid', 'hint': _hint},
          ],
        }));
        expect(file.rules.single.relay, 'box.good.invalid', reason: '$relay');
        expect(file.skipped, hasLength(1), reason: '$relay');
      }
    });

    test('an unknown hint leaves the rule out', () {
      final file = parseServiceFile(jsonEncode({
        'schema': 1,
        'id': 'mixed',
        'rules': [
          {'kind': relayNeedsNote, 'relay': 'box.good.invalid', 'hint': 'pay_here_instead'},
        ],
      }));
      expect(file.rules, isEmpty);
      expect(file.skipped, hasLength(1));
    });

    test('rules past the limit are left out', () {
      final file = parseServiceFile(jsonEncode({
        'schema': 1,
        'id': 'many',
        'rules': [
          for (var i = 0; i < maxServiceRules + 5; i++) {'kind': relayNeedsNote, 'relay': 'box$i.many.invalid', 'hint': _hint},
        ],
      }));
      expect(file.rules, hasLength(maxServiceRules));
    });

    test('a file with no usable shape is refused', () {
      for (final text in ['', 'nope', '[]', '{}', '{"schema":"1","id":"a","rules":[]}', '{"schema":1,"id":"A B","rules":[]}', '{"schema":1,"id":"a"}', '{"schema":${serviceSchema + 1},"id":"a","rules":[]}']) {
        expect(() => parseServiceFile(text), throwsA(isA<ServiceFileRefused>()), reason: text);
      }
    });
  });

  group('loadServices', () {
    test('no sources, no files: no rules', () async {
      expect(matchService('$_key@$sampleRelay', await loadServices(const [])), isNull);
      expect(matchService('$_key@$sampleRelay', await _load(const {})), isNull);
    });

    test('a bad file never stops the others', () async {
      final rules = await loadServices([
        _Broken(),
        _Source({
          'bad.json': utf8.encode('{'),
          'binary.json': [0xff, 0xfe, 0x00],
          'huge.json': utf8.encode(_file('huge', extra: {'pad': 'x' * maxServiceFileBytes})),
          'newer.json': utf8.encode('{"schema":${serviceSchema + 1},"id":"newer","rules":[]}'),
          'sample.json': utf8.encode(sampleServiceFile),
        }),
      ]);
      expect(matchService('$_key@$sampleRelay', rules), isNotNull);
    });

    test('a later source can add a rule and never replace one', () async {
      final bundled = _Source({'sample.json': utf8.encode(sampleServiceFile)});
      final rules = await loadServices([
        bundled,
        _Source({
          // The same id: skipped whole, its own relay too.
          'taken.json': utf8.encode(_file('sample-exchange', relay: 'box.taken.invalid')),
          // Fields that try to switch the bundled rule off do nothing.
          'off.json': utf8.encode(jsonEncode({
            'schema': 1,
            'id': 'off',
            'off': ['sample-exchange'],
            'rules': [
              {'kind': 'silence', 'relay': sampleRelay},
              {'kind': relayNeedsNote, 'relay': sampleRelay, 'hint': 'nothing'},
            ],
          })),
          'added.json': utf8.encode(_file('added', relay: 'box.added.invalid')),
        }),
      ]);
      expect(matchService('$_key@$sampleRelay', rules), isNotNull);
      expect(matchService('$_key@box.added.invalid', rules), isNotNull);
      expect(matchService('$_key@box.taken.invalid', rules), isNull);
    });
  });

  group('sources', () {
    test('bundled: only the .json files directly in the folder', () async {
      final rules = await loadServices([
        BundledServices(_Bundle({'.gitkeep': '', 'a.json': _file('a', relay: 'box.a.invalid'), 'deep/b.json': _file('b', relay: 'box.b.invalid'), 'c.txt': _file('c', relay: 'box.c.invalid')})),
      ]);
      expect(matchService('$_key@box.a.invalid', rules), isNotNull);
      expect(matchService('$_key@box.b.invalid', rules), isNull);
      expect(matchService('$_key@box.c.invalid', rules), isNull);
    });

    test('bundled: more files than the limit are left out', () async {
      final rules = await loadServices([
        BundledServices(_Bundle({for (var i = 100; i < 100 + maxServiceFiles + 3; i++) '$i.json': _file('s$i', relay: 'box$i.many.invalid')})),
      ]);
      expect(matchService('$_key@box100.many.invalid', rules), isNotNull);
      expect(matchService('$_key@box${100 + maxServiceFiles}.many.invalid', rules), isNull);
    });

    group('dropped folder', () {
      late Directory dir;

      setUp(() {
        dir = Directory.systemTemp.createTempSync('wfe-services');
        addTearDown(() => dir.deleteSync(recursive: true));
      });

      void write(String name, String text) => File('${dir.path}/$name').writeAsStringSync(text);

      test('no folder, no files', () async {
        expect(await DroppedServices(Directory('${dir.path}/none')).read(), isEmpty);
      });

      test('reads the .json files; the rest stay out', () async {
        write('good.json', sampleServiceFile);
        write('notes.txt', _file('notes', relay: 'box.notes.invalid'));
        Directory('${dir.path}/deep').createSync();
        write('deep/nested.json', _file('nested', relay: 'box.nested.invalid'));
        final rules = await loadServices([DroppedServices(dir)]);
        expect(matchService('$_key@$sampleRelay', rules), isNotNull);
        expect(matchService('$_key@box.notes.invalid', rules), isNull);
        expect(matchService('$_key@box.nested.invalid', rules), isNull);
      });

      test('a huge file is read only past the limit, then refused', () async {
        write('huge.json', ' ' * (maxServiceFileBytes * 4));
        final read = await DroppedServices(dir).read();
        expect(read.single.bytes.length, maxServiceFileBytes + 1);
        expect(matchService('$_key@$sampleRelay', await loadServices([DroppedServices(dir)])), isNull);
      });
    });
  });

  group('checkServiceFile', () {
    test('the sample passes', () {
      expect(checkServiceFile('sample-exchange.json', sampleServiceFile), isEmpty);
    });

    test('what the app forgives, the check names', () {
      expect(checkServiceFile('other.json', sampleServiceFile), contains('the file should be named sample-exchange.json'));
      expect(checkServiceFile('a.json', _file('a', extra: {'link': 'https://x.invalid'})), contains('file: unknown field link'));
      expect(checkServiceFile('a.json', '{"schema":1,"id":"a","rules":[{"kind":"later"}]}'), contains('rule 1: unknown kind later'));
      expect(checkServiceFile('a.json', '{"schema":1,"id":"a","rules":[]}'), contains('no rules'));
      expect(checkServiceFile('a.json', _file('a', extra: {'name': 'Bïg'})).join(), contains('ASCII'));
      expect(checkServiceFile('a.json', '{'), contains('not JSON'));
    });

    test('two files naming one relay is a mistake', () {
      final taken = <String>{};
      expect(checkServiceFile('a.json', _file('a', relay: 'box.one.invalid'), taken: taken), isEmpty);
      expect(checkServiceFile('b.json', _file('b', relay: 'box.one.invalid'), taken: taken), contains('box.one.invalid is already in another file'));
    });
  });
}
