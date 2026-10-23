// The onion mapping: the built-in copy until a verified btlabs.json lists onions; entries are
// parsed leniently (a bad one is skipped, never a reason to reject the file).
import 'package:epic_wallet/src/btlabs_onions.dart';
import 'package:epic_wallet/src/btlabs_public.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/btlabs_public_file.dart';

void main() {
  final d = [donation('btlabs', 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.stackwallet.com')];

  Future<BtlabsPublic> file({List<Object?>? onions}) async => verified(await signedPublicFile(d, serial: 3, onions: onions));

  Future<VerifyResult<BtlabsPublic>> verify(String body) =>
      verifyBtlabsPublic(body, keyring: testKeyring(), now: DateTime.utc(2026, 11));

  test('nothing fetched: the built-in copy', () {
    final o = OnionDirectory();
    expect(o.entries, builtInOnions);
    final e = o.onionFor('flooepicbox.btlabs.uk', 443)!;
    expect(e.onion, 'j2xf5rizkow5jtrdf6edotk5qam4kohavip23dqeuih5bq4yqisbz5ad.onion');
    expect(e.tls, isTrue);
    final s = o.onionFor('status.btlabs.uk')!;
    expect((s.onionPort, s.tls), (80, false));
    expect(o.onionFor('example.com', 443), isNull);
    expect(o.onionFor('node.btlabs.uk', 8080), isNull);
  });

  test('the built-in entries match the field rules', () {
    for (final e in builtInOnions) {
      expect(RegExp(r'^[a-z2-7]{56}\.onion$').hasMatch(e.onion), isTrue, reason: e.id);
    }
  });

  test('a verified file with onions replaces the built-in copy', () async {
    final o = OnionDirectory()..adopt(await file(onions: [onionEntry('node.btlabs.uk', id: 'n', service: 'node')]));
    expect(o.entries.map((e) => e.host), ['node.btlabs.uk']);
    expect(o.onionFor('flooepicbox.btlabs.uk'), isNull);
    expect(o.onionFor('node.btlabs.uk')!.onion, '${'a' * 56}.onion');
  });

  test('a verified file without the field keeps the built-in copy', () async {
    final o = OnionDirectory()..adopt(await file());
    expect(o.entries, builtInOnions);
  });

  test('an invalid entry is skipped, the rest is used, the file is still accepted', () async {
    final f = await file(
      onions: [
        onionEntry('good.btlabs.uk', id: 'good'),
        onionEntry('badonion.btlabs.uk', id: 'b1', onion: 'short.onion'),
        onionEntry('badservice.btlabs.uk', id: 'b2', service: 'mail'),
        onionEntry('badport.btlabs.uk', id: 'b3', port: 70000),
        {...onionEntry('notls.btlabs.uk', id: 'b4'), 'tls': 'yes'},
        'junk',
        onionEntry('dup.btlabs.uk', id: 'd1', onion: '${'b' * 56}.onion'),
        onionEntry('dup.btlabs.uk', id: 'd2', onion: '${'c' * 56}.onion'),
      ],
    );
    final o = OnionDirectory()..adopt(f);
    expect(o.entries.map((e) => e.host), ['good.btlabs.uk', 'dup.btlabs.uk']);
    expect(o.onionFor('dup.btlabs.uk')!.onion, '${'b' * 56}.onion', reason: 'the first duplicate wins');
  });

  test('a forged signature is rejected, so nothing can be adopted', () async {
    final good = await signedPublicFile(d, serial: 3, onions: [onionEntry('node.btlabs.uk')]);
    expect(await verify(good), isA<Accepted<BtlabsPublic>>());
    expect(await verify(good.replaceFirst('"sig": "', '"sig": "Z')), isA<Rejected<BtlabsPublic>>());
  });

  test('an unsigned payload is rejected', () async {
    final raw = String.fromCharCodes(publicPayload(d, serial: 3, onions: [onionEntry('node.btlabs.uk')]));
    expect(await verify(raw), isA<Rejected<BtlabsPublic>>());
  });

  test("only BT Labs' own hosts may be mapped to an onion", () async {
    final f = await file(
      onions: [
        onionEntry('btlabs.uk', id: 'apex'),
        onionEntry('node.btlabs.uk', id: 'node'),
        onionEntry('evil.btlabs.uk.attacker.com', id: 'e1'),
        onionEntry('xbtlabs.uk', id: 'e2'),
        onionEntry('example.com', id: 'e3'),
        onionEntry('btlabs.uk.example', id: 'e4'),
        onionEntry('status.btlabs.uk', id: 'status', onionPort: 80, tls: false),
      ],
    );
    final o = OnionDirectory()..adopt(f);
    expect(o.entries.map((e) => e.host), ['btlabs.uk', 'node.btlabs.uk', 'status.btlabs.uk']);
    expect(o.onionFor('status.btlabs.uk')!.tls, isFalse, reason: 'the plain status onion is still listed');
    expect(isBtlabsHost('a.b.btlabs.uk'), isTrue);
    expect(isBtlabsHost('btlabs.uk.'), isFalse);
    expect(isBtlabsHost('notbtlabs.uk'), isFalse);
  });
}
