// SPDX-License-Identifier: Apache-2.0
// An update manifest that carries two valid signatures (rank 1 and rank 2, the test keys) is
// accepted, its signer is the rank-2 key, and moving between one and two signatures keeps the
// serial rule: what a 2-of-n rollout would publish (docs/RELEASING.md, "Update-trust proposals").
// The verifiers of the apps up to 26.10.23 were checked the same way from their tags.
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:epic_wallet/src/btlabs_public.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/btlabs_sign.dart';
import 'support/test_settings.dart';

const _fixtures = 'test/fixtures/btlabs';

void main() {
  useShippedSettings();
  late Keyring keyring;
  late SimpleKeyPair a, b;
  late String ida, idb;
  late Map<String, dynamic> base;
  late DateTime now;

  setUpAll(() async {
    keyring = Keyring.parse(File('$_fixtures/test-keyring.json').readAsStringSync());
    a = await testKeyFromPem(File('$_fixtures/test-a.key').readAsStringSync());
    b = await testKeyFromPem(File('$_fixtures/test-b.key').readAsStringSync());
    ida = await testKeyid(a);
    idb = await testKeyid(b);
    expect(keyring.byKeyid(ida)!.rank, 1);
    expect(keyring.byKeyid(idb)!.rank, 2);
    final vectors = jsonDecode(File('$_fixtures/update-v2-vectors.json').readAsStringSync()) as Map<String, dynamic>;
    final c = (vectors['cases'] as List).cast<Map<String, dynamic>>().firstWhere(
      (c) => c['name'] == 'valid-signed-by-a',
    );
    final env = jsonDecode(c['envelope'] as String) as Map<String, dynamic>;
    base = jsonDecode(utf8.decode(base64.decode(env['payload'] as String))) as Map<String, dynamic>;
    now = DateTime.parse(c['now'] as String);
  });

  List<int> payload(int serial) => utf8.encode(jsonEncode({...base, 'serial': serial}));
  Future<String> sign(int serial, List<SimpleKeyPair> keys) =>
      signBtlabsEnvelope(payload(serial), keys, payloadType: walletUpdateType);
  ManifestState state(int serial, String keyid) =>
      ManifestState.fromJson({'serial': serial, 'keyid': keyid, 'digest': '0' * 64, 'revoked': <String>[]})!;
  Future<VerifyResult<WalletUpdate>> verify(String env, [ManifestState? s]) =>
      verifyWalletUpdate(env, keyring: keyring, state: s, now: now);

  test('two valid signatures are accepted, in either order; the rank-2 key is the signer', () async {
    final serial = base['serial'] as int;
    for (final keys in [
      [a, b],
      [b, a],
    ]) {
      final r = await verify(await sign(serial, keys));
      expect(r, isA<Accepted<WalletUpdate>>());
      expect((r as Accepted<WalletUpdate>).signer, idb);
      expect(r.state.keyid, idb);
    }
  });

  test('an install that accepted a rank-1 file takes the next file with two signatures', () async {
    final serial = base['serial'] as int;
    final r = await verify(await sign(serial + 1, [a, b]), state(serial, ida));
    expect(r, isA<Accepted<WalletUpdate>>());
    expect((r as Accepted<WalletUpdate>).state.serial, serial + 1);
  });

  test('after a two-signature file, a rank-1 file is accepted only with a higher serial', () async {
    final serial = base['serial'] as int;
    final after = state(serial, idb);
    expect(await verify(await sign(serial + 1, [a]), after), isA<Accepted<WalletUpdate>>());
    final older = await verify(await sign(serial - 1, [a]), after);
    expect((older as Rejected<WalletUpdate>).reason, RejectReason.rollback);
  });

  test('a broken second signature does not reject a file the rank-1 key signed', () async {
    final env = jsonDecode(await sign(base['serial'] as int, [a, b])) as Map<String, dynamic>;
    ((env['signatures'] as List)[1] as Map<String, dynamic>)['sig'] = base64.encode(List.filled(64, 7));
    final r = await verify(jsonEncode(env));
    expect((r as Accepted<WalletUpdate>).signer, ida);
  });
}
