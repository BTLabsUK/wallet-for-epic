// SPDX-License-Identifier: Apache-2.0
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:epic_wallet/src/support_report.dart';
import 'package:flutter_test/flutter_test.dart';

// Made by the Electron GUI's own `buildBundle` (src/shared/supportBundle.js, feat/support-logs)
// with a throwaway key pair, so these tests check the format against the GUI, not against itself.
const _guiPublic = 'Is9AqX6g7jHdGmYxF1/G77NCTANVARUWkqoifVBV0VY=';
const _guiPrivate = 'QIpzy1LBRhbLstwLTCKnxvaKyrWEVulXPxGTpUE5yHk=';
const _guiKeyId = '45571bfef5f71942';
const _guiBundle =
    'RVBJQ1NVUDFFVxv+9fcZQuViT2LA8ucsT6nDOQagFAx4fcOvNlM2mLGl3vcM0zsFsXebQN95oTv0p5qY/nkOmgebtTZ2VX2/1bL5IHHUivVa2uSJL7RnCmpU4l4w3/IvS7CxY9W05UU5+8hwxEuqkhMg52kpMYis5JjoPn3Jk25tqqy3sxRqJNpzLXz0nIaF+9itmOUN2VIgKKqvujVjjQSeXJ0NueYpIPwFDy1LW6HvUVZFPAC3FtCzr37PNrU52kGr/QMGv8J/bZDQ9B8tCPeNr17kziXBzLke6ljvfpat9QOoDwN61wuSkxBvZtRRwPzcqEb6os6T+oYjMM6cIW6lEBYAvbXRWMsUz0fE2V7rseoHNuDq';

SupportReport _report({List<SupportFile> files = const []}) => SupportReport(
  created: DateTime.utc(2026, 10, 22, 10),
  description: '  Zażółć gęślą jaźń\u0007\u0000 ',
  contact: '@tester',
  app: {'version': 'wfe-0.1.0', 'ui': 'desktop', 'platform': 'linux'},
  files: files,
);

void main() {
  final private = base64.decode(_guiPrivate);

  test('opens a report the GUI sealed', () async {
    final sealed = base64.decode(_guiBundle);
    expect(ascii.decode(sealed.sublist(0, 8)), 'EPICSUP1');
    expect(hex(sealed.sublist(8, 16)), _guiKeyId);
    final report = await openSupportBundle(sealed, private);
    expect(report['v'], 1);
    expect(report['created'], '2026-10-22T10:00:00.000Z');
    expect(report['description'], 'Vector from the GUI');
    expect(report['contact'], '@tester');
    expect(report['app'], {'version': '6.1.6', 'platform': 'linux'});
    expect(report['files'], [
      {'name': 'app/main.log', 'bytes': 14, 'text': 'line 1\nline 2\n', 'cut': false},
    ]);
    expect(report['dropped'], isEmpty);
  });

  test('seals in the GUI layout, and only the private key opens it', () async {
    final plain = utf8.encode('zażółć report');
    final a = await sealSupport(plain, _guiPublic);
    final b = await sealSupport(plain, _guiPublic);
    expect(a.length, plain.length + 60 + 16);
    expect(ascii.decode(a.sublist(0, 8)), 'EPICSUP1');
    expect(hex(a.sublist(8, 16)), _guiKeyId);
    // A fresh ephemeral key and nonce each time.
    expect(hex(a.sublist(16, 60)), isNot(hex(b.sublist(16, 60))));
    expect(await openSupport(a, private), plain);
    // Any changed byte, header or body, is refused.
    for (final i in [9, 20, 50, 61, a.length - 1]) {
      final t = [...a]..[i] ^= 1;
      await expectLater(openSupport(t, private), throwsA(anything), reason: 'byte $i');
    }
    await expectLater(openSupport(utf8.encode('EPICSUP2${'x' * 100}'), private), throwsFormatException);
  });

  test('the embedded key is the GUI key with its published id', () {
    expect(hex(supportKeyIdOf(rawSupportKey(supportPublicKey))), supportKeyId);
    expect(hex(supportKeyIdOf(rawSupportKey(_guiPublic))), _guiKeyId);
    expect(() => rawSupportKey('AAAA'), throwsArgumentError);
  });

  test('a report round-trips with the GUI fields, trimmed and capped', () async {
    final bundle = await buildSupportBundle(
      _report(files: [const SupportFile(name: 'app/wfe.log', text: 'line 1\nline 2\n')]),
      publicKey: _guiPublic,
    );
    final opened = await openSupportBundle(bundle, private);
    expect(opened.keys, ['v', 'created', 'app', 'description', 'contact', 'files', 'dropped']);
    expect(opened['description'], 'Zażółć gęślą jaźń');
    expect(opened['contact'], '@tester');
    expect(opened['app'], {'version': 'wfe-0.1.0', 'ui': 'desktop', 'platform': 'linux'});
    expect(opened['files'], [
      {'name': 'app/wfe.log', 'bytes': 14, 'text': 'line 1\nline 2\n', 'cut': false},
    ]);
    final long = SupportReport(created: DateTime.utc(2026), description: 'x' * 3000, contact: 'y' * 200, app: const {});
    expect(long.description.length, maxSupportDescription);
    expect(long.contact.length, maxSupportContact);

    // For the format check against the GUI's own openBundle (see the report): set the variable to
    // a file path and open it with node.
    final out = Platform.environment['SUPPORT_VECTOR_OUT'];
    if (out != null) File(out).writeAsStringSync(base64.encode(bundle));
  });

  test('keeps the tail of a long log, and drops files that do not fit', () async {
    final log = StringBuffer();
    for (var i = 0; log.length < 600 * 1024; i++) {
      log.writeln('line $i ${'lorem ' * 9}');
    }
    final file = tailFile('app/wfe.log', log.toString());
    expect(file.cut, isTrue);
    expect(file.text, startsWith('[… earlier lines left out …]\nline '));
    expect(file.bytes, lessThanOrEqualTo(maxSupportFileText + 40));
    expect(log.toString().endsWith(file.text.substring(file.text.indexOf('\n') + 1)), isTrue);

    // Random bytes do not compress: two 300 KB files in a 400 KB cap leave one.
    String noise(int seed) {
      final random = Random(seed);
      return base64.encode(List.generate(225 * 1024, (_) => random.nextInt(256)));
    }

    final bundle = await buildSupportBundle(
      _report(files: [SupportFile(name: 'a.log', text: noise(1)), SupportFile(name: 'b.log', text: noise(2))]),
      publicKey: _guiPublic,
      max: 400 * 1024,
    );
    final opened = await openSupportBundle(bundle, private);
    expect([for (final f in opened['files'] as List) f['name']], ['a.log']);
    expect(opened['dropped'], ['b.log']);
  });

  test('the request and the intake answers', () {
    final body = jsonDecode(supportRequestBody([1, 2, 3], 'wfe-0.1.0')) as Map;
    expect(body, {'v': 2, 'bundle': 'AQID', 'app': 'wfe-0.1.0'});
    expect(supportReportId(200, '{"ok":true,"id":"ab12cd34"}'), 'ab12cd34');
    expect(() => supportReportId(413, ''), throwsA(isA<SupportSendError>().having((e) => e.reason, 'reason', SupportFailure.tooBig)));
    expect(() => supportReportId(429, ''), throwsA(isA<SupportSendError>().having((e) => e.reason, 'reason', SupportFailure.rate)));
    expect(() => supportReportId(200, 'nope'), throwsA(isA<SupportSendError>().having((e) => e.reason, 'reason', SupportFailure.server)));
  });

  test('the preview text holds everything that is sealed', () {
    final text = _report(files: [const SupportFile(name: 'app/wfe.log', text: 'WARN x: y')]).text;
    for (final part in ['2026-10-22T10:00:00.000Z', '@tester', 'version: wfe-0.1.0', 'Zażółć gęślą jaźń', '== app/wfe.log ==', 'WARN x: y']) {
      expect(text, contains(part));
    }
    expect(_report().text, contains('Logs: none attached'));
  });
}

String hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
