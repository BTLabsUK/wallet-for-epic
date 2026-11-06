// SPDX-License-Identifier: Apache-2.0
// The check of a contact's claimed domain (`domain_check.dart`): the file is fetched with no
// redirect and a 4096-byte cap, only a 200 answer reaches the core, and every other outcome
// leaves the claim as it was. When a check is due, and what is kept.
import 'dart:async';
import 'dart:typed_data';

import 'package:epic_wallet/src/domain_check.dart';
import 'package:epic_wallet/src/history/domain_check_book.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryDomainCheckLog log;
  late DateTime now;
  late List<Uri> fetched;
  late List<({String id, Uint8List file})> verified;
  late List<bool> followed;
  late Future<HttpBytes> Function() reply;
  var verdict = (proven: true, refused: null as String?);

  DomainCheck check() => DomainCheck(
    log: log,
    now: () => now,
    verify: (id, file) async {
      verified.add((id: id, file: file));
      return verdict;
    },
    fetch: (url, {required timeout, required maxBytes, required followRedirects}) {
      fetched.add(url);
      followed.add(followRedirects);
      expect(maxBytes, 4096);
      expect(timeout, const Duration(seconds: 15));
      return reply();
    },
  );

  PairingRecord claim({String domain = 'shop.example', List<int> attestation = const [1, 2, 3]}) => PairingRecord(
    id: 'p1',
    state: PairingState.verified,
    way: PairingWay.link,
    inviter: false,
    createdAt: DateTime(2026, 11, 1),
    peerDomain: domain,
    peerDomainAttestation: Uint8List.fromList(attestation),
  );

  setUp(() {
    log = MemoryDomainCheckLog();
    now = DateTime(2026, 11, 6, 12);
    fetched = [];
    verified = [];
    followed = [];
    verdict = (proven: true, refused: null);
    reply = () async => HttpBytes(200, Uint8List.fromList([123, 125]));
  });

  group('run', () {
    test('a 200 answer the core proves: proven, from the well-known file, no redirect followed', () async {
      final status = await check().run(claim());
      expect(status, DomainStatus.proven);
      expect(fetched.single.toString(), 'https://shop.example/.well-known/epic-wallet.json');
      expect(followed, [false]);
      expect(verified.single.id, 'p1');
      expect(verified.single.file, [123, 125]);
      expect(log.book.checks['p1']!.status, DomainStatus.proven);
      expect(log.book.checks['p1']!.reason, isNull);
    });

    test('a 200 answer the core refuses: refused, with the core\'s reason', () async {
      verdict = (proven: false, refused: 'no_key_matches');
      expect(await check().run(claim()), DomainStatus.refused);
      expect(log.book.checks['p1']!.reason, 'no_key_matches');
    });

    test('a 301 is not followed and is not handed to the core: claimed', () async {
      reply = () async => HttpBytes(301, Uint8List(0));
      expect(await check().run(claim()), DomainStatus.claimed);
      expect(verified, isEmpty);
      expect(log.book.checks['p1']!.status, DomainStatus.claimed);
      expect(log.book.checks['p1']!.reason, 'http 301');
    });

    test('a 404 is claimed, not refused', () async {
      reply = () async => HttpBytes(404, Uint8List(0));
      expect(await check().run(claim()), DomainStatus.claimed);
      expect(verified, isEmpty);
    });

    test('a body of 4097 bytes is refused without calling the core', () async {
      reply = () async => HttpBytes(200, Uint8List(4097));
      expect(await check().run(claim()), DomainStatus.refused);
      expect(verified, isEmpty);
      expect(log.book.checks['p1']!.reason, domainFileTooLarge);
    });

    test('the transport stopping one byte past the cap is refused the same way', () async {
      reply = () async => throw const NetTooLarge(4096);
      expect(await check().run(claim()), DomainStatus.refused);
      expect(verified, isEmpty);
      expect(log.book.checks['p1']!.reason, domainFileTooLarge);
    });

    test('a network error is claimed, the error kept', () async {
      reply = () async => throw const NetError('connection refused');
      expect(await check().run(claim()), DomainStatus.claimed);
      expect(verified, isEmpty);
      expect(log.book.checks['p1']!.reason, 'connection refused');
    });

    test('a timeout is claimed', () async {
      reply = () async => throw TimeoutException('slow');
      expect(await check().run(claim()), DomainStatus.claimed);
      expect(log.book.checks['p1']!.reason, 'timeout');
    });

    test('the network mode refusing, or Tor not ready, is no check: nothing kept, due again', () async {
      for (final message in [netModeError, 'Tor not connected']) {
        reply = () async => throw NetError(message);
        expect(await check().run(claim()), DomainStatus.claimed);
        expect(log.book.checks, isEmpty);
        expect(check().due(claim()), isTrue);
      }
    });

    test('a core that throws leaves the claim claimed', () async {
      final broken = DomainCheck(
        log: log,
        now: () => now,
        verify: (_, _) async => throw StateError('core'),
        fetch: (u, {required timeout, required maxBytes, required followRedirects}) async => HttpBytes(200, Uint8List(2)),
      );
      expect(await broken.run(claim()), DomainStatus.claimed);
    });

    test('a contact with no domain is not fetched', () async {
      final none = PairingRecord(id: 'p2', state: PairingState.verified, way: PairingWay.link, inviter: false, createdAt: now);
      expect(await check().run(none), DomainStatus.claimed);
      expect(fetched, isEmpty);
    });
  });

  group('due', () {
    test('never checked: due; checked within a day: not; a day on: due', () async {
      final c = check();
      expect(c.due(claim()), isTrue);
      await c.run(claim());
      expect(c.due(claim()), isFalse);
      now = now.add(const Duration(hours: 23));
      expect(c.due(claim()), isFalse);
      now = now.add(const Duration(hours: 1));
      expect(c.due(claim()), isTrue);
    });

    test('a changed attestation or domain is due at once; a changed domain shows claimed until checked', () async {
      final c = check();
      await c.run(claim());
      expect(c.statusOf('p1', 'shop.example'), DomainStatus.proven);
      expect(c.due(claim(attestation: const [9])), isTrue);
      expect(c.due(claim(domain: 'other.example')), isTrue);
      expect(c.statusOf('p1', 'other.example'), DomainStatus.claimed);
    });

    test('a claim of the same domain signed again keeps its status until checked, then takes the new one', () async {
      // The peer signs its claim again in each contact update, the one that brings a relay
      // move as well: a proven contact must stay domain-backed while that update is settled.
      final c = check();
      await c.run(claim());
      final resigned = claim(attestation: const [9]);
      expect(c.statusOf('p1', 'shop.example'), DomainStatus.proven);
      expect(c.due(resigned), isTrue);
      verdict = (proven: false, refused: 'domain_mismatch');
      expect(await c.run(resigned), DomainStatus.refused);
      expect(c.statusOf('p1', 'shop.example'), DomainStatus.refused);
      expect(c.due(resigned), isFalse);
    });

    test('an ended pairing and a contact with no domain are never due', () {
      final ended = PairingRecord(id: 'p4', state: PairingState.ended, way: PairingWay.link, inviter: false, createdAt: now, peerDomain: 'shop.example');
      expect(check().due(ended), isFalse);
      expect(check().due(PairingRecord(id: 'p3', state: PairingState.verified, way: PairingWay.link, inviter: false, createdAt: now)), isFalse);
      expect(check().statusOf('p1', null), isNull);
    });
  });

  group('the book', () {
    test('reads back what it wrote', () {
      final book = DomainCheckBook(
        checks: {'p1': const DomainCheckRec(status: DomainStatus.refused, checkedAt: 1792900000000, reason: 'domain_mismatch', attestation: 'ab12')},
      );
      final back = DomainCheckBook.fromJson(book.toJson());
      expect(back.checks['p1'], book.checks['p1']);
      expect(DomainCheckBook.fromJson(null).isEmpty, isTrue);
    });
  });
}
