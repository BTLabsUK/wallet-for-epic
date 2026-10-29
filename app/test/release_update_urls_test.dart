// SPDX-License-Identifier: Apache-2.0
// Audit 26.10.24: tool/release_android.sh signed a manifest whose file URLs were off the folder
// the apps hold them to, which makes every app reject the whole file. tool/check_update_urls.sh
// now stops it before signing.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _base = 'https://downloads.example.invalid/releases/downloads';

Map<String, Object?> _payload({String? apk, String? notorApk, String? desktop}) => {
  'apks': [
    {'abi': 'arm64-v8a', 'url': apk ?? '$_base/epic-cash-mobile-1.0.1-arm64-v8a.apk'},
  ],
  'desktop': {
    'linux': {'version': '1.0.1', 'url': desktop ?? '$_base/EpicCashDesktop-1.0.1-x86_64.AppImage'},
  },
  'notor': {
    'apks': [
      {'abi': 'arm64-v8a', 'url': notorApk ?? '$_base/epic-cash-mobile-1.0.1-notor-arm64-v8a.apk'},
    ],
  },
};

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('update_urls'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<ProcessResult> check(Map<String, Object?> payload, {String base = '$_base/'}) {
    final file = File('${dir.path}/payload.json')..writeAsStringSync(jsonEncode(payload));
    return Process.run('bash', ['tool/check_update_urls.sh', file.path, base]);
  }

  test('passes when every file URL is a file name under the folder, with or without a slash', () async {
    for (final base in ['$_base/', _base]) {
      final r = await check(_payload(), base: base);
      expect(r.exitCode, 0, reason: '${r.stderr}');
    }
  });

  test('fails loudly on any URL off the folder, in any part', () async {
    for (final payload in [
      _payload(apk: 'https://other.example.invalid/releases/downloads/a.apk'),
      _payload(notorApk: 'https://examples.example.invalid/old/downloads/a.apk'),
      _payload(desktop: '$_base/sub/EpicCashDesktop.AppImage'),
      _payload(apk: '$_base/'),
      _payload(desktop: '$_base/a.AppImage?x=1'),
    ]) {
      final r = await check(payload);
      expect(r.exitCode, 1, reason: jsonEncode(payload));
      expect(r.stderr, contains('file URLs not under $_base/'));
    }
  });

  test('a payload with no file URLs fails', () async {
    final r = await check({'apks': <Object?>[]});
    expect(r.exitCode, 1);
  });

  test('the release script runs the check on both payloads before signing', () {
    final script = File('tool/release_android.sh').readAsStringSync();
    final sign = script.indexOf(r'"${sign[@]}"');
    for (final call in [
      r'tool/check_update_urls.sh" "$payload" "$old_base"',
      r'tool/check_update_urls.sh" "$payload2" "$base2"',
    ]) {
      final at = script.indexOf(call);
      expect(at, isNonNegative, reason: call);
      expect(at, lessThan(sign), reason: call);
    }
  });
}
