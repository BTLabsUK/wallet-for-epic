// SPDX-License-Identifier: Apache-2.0
// The onion mapping: the built-in copy until a verified btlabs.json lists onions; entries are
// parsed leniently (a bad one is skipped, never a reason to reject the file).
import 'package:epic_wallet/src/btlabs_onions.dart';
import 'package:epic_wallet/src/btlabs_public.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/btlabs_public_file.dart';

void main() {
  final d = [donation('btlabs', 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@box.stack.invalid')];

  Future<BtlabsPublic> file({List<Object?>? onions}) async => verified(await signedPublicFile(d, serial: 3, onions: onions));

  Future<VerifyResult<BtlabsPublic>> verify(String body) =>
      verifyBtlabsPublic(body, keyring: testKeyring(), now: DateTime.utc(2026, 11));

  test('nothing fetched: the built-in copy', () {
    final o = OnionDirectory();
    expect(o.entries, builtInOnions);
    final e = o.onionFor('box.lab.invalid', 443)!;
    expect(e.onion, hostSettings.torOnions.firstWhere((r) => r.host == 'box.lab.invalid').onion);
    expect(e.tls, isTrue);
    final s = o.onionFor('status.lab.invalid')!;
    expect((s.onionPort, s.tls), (80, false));
    expect(o.onionFor('example.com', 443), isNull);
    expect(o.onionFor('node.lab.invalid', 8080), isNull);
  });

  test('the built-in entries match the field rules', () {
    for (final e in builtInOnions) {
      expect(RegExp(r'^[a-z2-7]{56}\.onion$').hasMatch(e.onion), isTrue, reason: e.id);
    }
  });

  test('a verified file with onions replaces the built-in copy', () async {
    final o = OnionDirectory()..adopt(await file(onions: [onionEntry('node.lab.invalid', id: 'n', service: 'node')]));
    expect(o.entries.map((e) => e.host), ['node.lab.invalid']);
    expect(o.onionFor('box.lab.invalid'), isNull);
    expect(o.onionFor('node.lab.invalid')!.onion, '${'a' * 56}.onion');
  });

  test('a verified file without the field keeps the built-in copy', () async {
    final o = OnionDirectory()..adopt(await file());
    expect(o.entries, builtInOnions);
  });

  test('an invalid entry is skipped, the rest is used, the file is still accepted', () async {
    final f = await file(
      onions: [
        onionEntry('good.lab.invalid', id: 'good'),
        onionEntry('badonion.lab.invalid', id: 'b1', onion: 'short.onion'),
        onionEntry('badservice.lab.invalid', id: 'b2', service: 'mail'),
        onionEntry('badport.lab.invalid', id: 'b3', port: 70000),
        {...onionEntry('notls.lab.invalid', id: 'b4'), 'tls': 'yes'},
        'junk',
        onionEntry('dup.lab.invalid', id: 'd1', onion: '${'b' * 56}.onion'),
        onionEntry('dup.lab.invalid', id: 'd2', onion: '${'c' * 56}.onion'),
      ],
    );
    final o = OnionDirectory()..adopt(f);
    expect(o.entries.map((e) => e.host), ['good.lab.invalid', 'dup.lab.invalid']);
    expect(o.onionFor('dup.lab.invalid')!.onion, '${'b' * 56}.onion', reason: 'the first duplicate wins');
  });

  test('a forged signature is rejected, so nothing can be adopted', () async {
    final good = await signedPublicFile(d, serial: 3, onions: [onionEntry('node.lab.invalid')]);
    expect(await verify(good), isA<Accepted<BtlabsPublic>>());
    expect(await verify(good.replaceFirst('"sig": "', '"sig": "Z')), isA<Rejected<BtlabsPublic>>());
  });

  test('an unsigned payload is rejected', () async {
    final raw = String.fromCharCodes(publicPayload(d, serial: 3, onions: [onionEntry('node.lab.invalid')]));
    expect(await verify(raw), isA<Rejected<BtlabsPublic>>());
  });

  test("only BT Labs' own hosts may be mapped to an onion", () async {
    final f = await file(
      onions: [
        onionEntry('lab.invalid', id: 'apex'),
        onionEntry('node.lab.invalid', id: 'node'),
        onionEntry('evil.lab.invalid.attacker.com', id: 'e1'),
        onionEntry('xlab.invalid', id: 'e2'),
        onionEntry('example.com', id: 'e3'),
        onionEntry('lab.invalid.example', id: 'e4'),
        onionEntry('status.lab.invalid', id: 'status', onionPort: 80, tls: false),
      ],
    );
    final o = OnionDirectory()..adopt(f);
    expect(o.entries.map((e) => e.host), ['lab.invalid', 'node.lab.invalid', 'status.lab.invalid']);
    expect(o.onionFor('status.lab.invalid')!.tls, isFalse, reason: 'the plain status onion is still listed');
    expect(isBtlabsHost('a.b.lab.invalid'), isTrue);
    expect(isBtlabsHost('lab.invalid.'), isFalse);
    expect(isBtlabsHost('notlab.invalid'), isFalse);
  });
}
