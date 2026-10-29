// SPDX-License-Identifier: Apache-2.0
// The vendored verifier (lib/src/btlabs_public.dart, from btlabs-public's dart/btlabs_public)
// must reproduce btlabs-public's shared vectors, for the public file and for update-v2.json, the
// signed update manifest this app reads. update-vectors.json (update.json, the old format with
// links in the old folders) is not here: only installed apps up to 26.10.23 read it, with
// btlabs-public's own verifier, whose tests run those vectors.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/btlabs_public.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/btlabs_sign.dart';
import 'support/test_settings.dart';

const _fixtures = 'test/fixtures/btlabs';

Future<VerifyResult<Object?>> _run(Map<String, dynamic> c, Keyring keyring) {
  final stateJson = c['state'];
  final state = stateJson == null ? null : ManifestState.fromJson(stateJson);
  final env = c['envelope'] as String;
  final now = DateTime.parse(c['now'] as String);
  final type = c['payloadType'] as String;
  if (type == walletUpdateType) {
    return verifyWalletUpdate(env, keyring: keyring, state: state, now: now);
  }
  return verifyBtlabsPublic(env, keyring: keyring, state: state, now: now, payloadType: type);
}

void main() {
  for (final name in ['vectors.json', 'update-v2-vectors.json']) {
    group(name, () {
      final vectors = jsonDecode(File('$_fixtures/$name').readAsStringSync()) as Map<String, dynamic>;
      final keyring = Keyring.parse(jsonEncode(vectors['keyring']));
      final cases = (vectors['cases'] as List).cast<Map<String, dynamic>>();

      test('has cases', () => expect(cases, isNotEmpty));

      if (vectors.containsKey('downloads')) {
        // The update vectors are made for the folders of the shipped app-config.toml, read as
        // the app reads them; regenerate them in btlabs-public when [updates] changes.
        useShippedSettings();
        test('made for [updates] of the shipped app-config.toml', () {
          expect(vectors['downloads'], hostSettings.updateDownloads);
          expect(vectors['pages'], hostSettings.updatePages);
        });
      }

      for (final c in cases) {
        test(c['name'] as String, () async {
          if (c['state'] != null) expect(ManifestState.fromJson(c['state']), isNotNull);
          final r = await _run(c, keyring);
          final expected = c['expect'] as Map<String, dynamic>;
          if (expected['outcome'] == 'rejected') {
            expect(r, isA<Rejected<Object?>>());
            expect((r as Rejected<Object?>).reason.code, expected['reason']);
          } else {
            expect(r, isA<Accepted<Object?>>());
            r as Accepted<Object?>;
            expect(r.unchanged, expected['outcome'] == 'unchanged');
            expect(r.state.toJson(), expected['state']);
          }
        });
      }
    });
  }

  test('the test signer reproduces the Python tool byte for byte', () async {
    final vectors = jsonDecode(File('$_fixtures/vectors.json').readAsStringSync()) as Map<String, dynamic>;
    final c = (vectors['cases'] as List).cast<Map<String, dynamic>>().firstWhere(
      (c) => c['name'] == 'valid-signed-by-a',
    );
    final env = jsonDecode(c['envelope'] as String) as Map<String, dynamic>;
    final payload = base64.decode(env['payload'] as String);
    final keyA = await testKeyFromPem(File('$_fixtures/test-a.key').readAsStringSync());
    expect(await signBtlabsEnvelope(payload, [keyA]), c['envelope']);
  });
}
