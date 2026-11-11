// SPDX-License-Identifier: Apache-2.0
// Signed announcements (announcements spec §2 to §7): the verifier on the publisher's fixtures
// and on files signed here with a generated key, the parser's refusals, and the service's
// live / seen / dismissed / prune logic with a fake clock and a fake fetch.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/announcements/announcements_service.dart';
import 'package:epic_wallet/src/btlabs_keys.dart';
import 'package:epic_wallet/src/btlabs_public.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/providers.dart' show secretStoreProvider;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/btlabs_sign.dart';

const _fixtures = 'test/fixtures/announcements';
const _feedUrl = 'https://pages.example.invalid/announcements.json';

/// A PNG header the verifier accepts: signature, IHDR of [w] x [h], IEND. (No pixel data: the
/// checks look at the signature and the IHDR only.)
Uint8List _png(int w, int h) {
  final b = BytesBuilder();
  b.add([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  b.add([0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52]);
  for (final v in [w, h]) {
    b.add([(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255]);
  }
  b.add([8, 0, 0, 0, 0, 0, 0, 0, 0]);
  b.add([0, 0, 0, 0, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82]);
  return b.toBytes();
}

class _Flag extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool v) => state = v;
}

final _flag = NotifierProvider<_Flag, bool>(_Flag.new);

Map<String, dynamic> _msg(String id, {Map<String, dynamic>? extra}) => {
  'id': id,
  'text': 'Message $id.',
  ...?extra,
};

void main() {
  late SimpleKeyPair key;
  late Keyring ring;
  late String keyid;
  final now = DateTime.utc(2026, 11, 11, 12);

  setUpAll(() async {
    // The in-test fallback: a generated key and a keyring that names it.
    key = await testKeyFromSeed(List<int>.generate(32, (i) => i + 1));
    keyid = await testKeyid(key);
    final pub = base64.encode((await key.extractPublicKey()).bytes);
    ring = Keyring.parse(jsonEncode({
      'keys': [
        {'keyid': keyid, 'rank': 1, 'public_key': pub, 'label': 'generated'},
      ],
    }));
  });

  Map<String, dynamic> payload({
    int serial = 100,
    List<Map<String, dynamic>>? messages,
    DateTime? issued,
    DateTime? expires,
  }) {
    final i = issued ?? now.subtract(const Duration(hours: 1));
    final e = expires ?? i.add(const Duration(days: 30));
    String t(DateTime d) => '${d.toIso8601String().split('.').first}Z';
    return {
      'schema': 1,
      'serial': serial,
      'issued_at': t(i),
      'expires_at': t(e),
      'messages': messages ?? [_msg('one')],
      'revoked_keys': <String>[],
    };
  }

  Future<String> sign(Map<String, dynamic> p, {String type = announcementsType}) =>
      signBtlabsEnvelope(utf8.encode(jsonEncode(p)), [key], payloadType: type);

  Future<VerifyResult<AnnouncementsFeed>> verify(String env, {ManifestState? state}) =>
      verifyAnnouncements(env, keyring: ring, state: state, now: now);

  Future<void> expectRejected(Map<String, dynamic> p, RejectReason reason) async {
    final r = await verify(await sign(p));
    expect(r, isA<Rejected<AnnouncementsFeed>>(), reason: jsonEncode(p));
    expect((r as Rejected<AnnouncementsFeed>).reason, reason);
  }

  group('the publisher\'s fixtures', () {
    final fixtureRing = Keyring.parse(File('$_fixtures/keyring.json').readAsStringSync());

    test('the bundled keyring is the production pair, never the test keys', () {
      expect(announcementsKeyring.keys.map((k) => k.keyid), ['8d85230d01812375', '5536e619d3a69009']);
      for (final k in fixtureRing.keys) {
        expect(announcementsKeyring.keys.map((b) => b.keyid), isNot(contains(k.keyid)));
      }
    });

    test('the first production feed verifies with the bundled keyring', () async {
      final text = File('$_fixtures/production.json').readAsStringSync();
      final payloadJson = jsonDecode(utf8.decode(base64.decode((jsonDecode(text) as Map)['payload'] as String))) as Map;
      final issued = DateTime.parse(payloadJson['issued_at'] as String);
      final r = await verifyAnnouncements(text, keyring: announcementsKeyring, now: issued.add(const Duration(hours: 1)));
      expect(r, isA<Accepted<AnnouncementsFeed>>());
      expect((r as Accepted<AnnouncementsFeed>).signer, '8d85230d01812375');
    });

    test('announcements.json verifies', () async {
      final text = File('$_fixtures/announcements.json').readAsStringSync();
      final payloadJson = jsonDecode(utf8.decode(base64.decode((jsonDecode(text) as Map)['payload'] as String))) as Map;
      final issued = DateTime.parse(payloadJson['issued_at'] as String);
      final r = await verifyAnnouncements(
        text,
        keyring: fixtureRing,
        now: issued.add(const Duration(hours: 1)),
      );
      expect(r, isA<Accepted<AnnouncementsFeed>>());
      final feed = (r as Accepted<AnnouncementsFeed>).manifest;
      expect(feed.messages, isNotEmpty);
      expect(feed.messages.first.imagePng, isNotNull);
      expect(r.signer, '9df7615cea67d189');
    });

    test('bad-signature.json, wrong-type.json and oversized-image.json are refused', () async {
      for (final (name, reason) in [
        ('bad-signature.json', RejectReason.badSignature),
        ('wrong-type.json', RejectReason.wrongType),
        ('oversized-image.json', null),
      ]) {
        final text = File('$_fixtures/$name').readAsStringSync();
        final p = jsonDecode(utf8.decode(base64.decode((jsonDecode(text) as Map)['payload'] as String))) as Map;
        final at = DateTime.parse(p['issued_at'] as String).add(const Duration(hours: 1));
        final r = await verifyAnnouncements(text, keyring: fixtureRing, now: at);
        expect(r, isA<Rejected<AnnouncementsFeed>>(), reason: name);
        if (reason != null) expect((r as Rejected<AnnouncementsFeed>).reason, reason, reason: name);
      }
    });
  });

  group('the verifier, with a generated key', () {
    test('a good file is accepted, with its image, link and platforms', () async {
      final p = payload(
        messages: [
          _msg(
            'full',
            extra: {
              'link': {'label': 'Open', 'url': 'https://example.com/a'},
              'image': {'png': base64.encode(_png(64, 64))},
              'starts_at': '2026-11-11T00:00:00Z',
              'ends_at': '2026-11-20T00:00:00Z',
              'platforms': ['desktop'],
            },
          ),
          _msg('epic', extra: {
            'link': {'label': 'Pay', 'url': 'epic:abc'},
          }),
        ],
      );
      final r = await verify(await sign(p));
      expect(r, isA<Accepted<AnnouncementsFeed>>());
      final m = (r as Accepted<AnnouncementsFeed>).manifest.messages;
      expect(m.length, 2);
      expect(m[0].imagePng, hasLength(_png(64, 64).length));
      expect(m[0].link!.url, 'https://example.com/a');
      expect(m[0].platforms, {'desktop'});
      expect(m[1].platforms, isNull);
      expect(m[1].link!.url, 'epic:abc');
    });

    test('an empty list is accepted: it clears every message', () async {
      final r = await verify(await sign(payload(messages: [])));
      expect((r as Accepted<AnnouncementsFeed>).manifest.messages, isEmpty);
    });

    test('a wrong payload type is refused', () async {
      final r = await verify(await sign(payload(), type: btlabsPublicType));
      expect((r as Rejected<AnnouncementsFeed>).reason, RejectReason.wrongType);
    });

    test('a file signed by a key not in the keyring is refused', () async {
      final other = await testKeyFromSeed(List<int>.filled(32, 9));
      final env = await signBtlabsEnvelope(utf8.encode(jsonEncode(payload())), [other], payloadType: announcementsType);
      expect(((await verify(env)) as Rejected<AnnouncementsFeed>).reason, RejectReason.unknownKey);
    });

    test('a changed payload fails the signature', () async {
      final env = jsonDecode(await sign(payload())) as Map<String, dynamic>;
      env['payload'] = base64.encode(utf8.encode(jsonEncode(payload(messages: [_msg('forged')]))));
      expect(((await verify(jsonEncode(env))) as Rejected<AnnouncementsFeed>).reason, RejectReason.badSignature);
    });

    test('an old serial is a rollback; the same bytes again are unchanged', () async {
      final first = await verify(await sign(payload(serial: 200))) as Accepted<AnnouncementsFeed>;
      final older = await verify(await sign(payload(serial: 150)), state: first.state);
      expect((older as Rejected<AnnouncementsFeed>).reason, RejectReason.rollback);
      final again = await verify(await sign(payload(serial: 200)), state: first.state);
      expect(again, isA<Accepted<AnnouncementsFeed>>());
    });

    test('an expired file is refused', () async {
      final p = payload(issued: now.subtract(const Duration(days: 40)), expires: now.subtract(const Duration(days: 1)));
      await expectRejected(p, RejectReason.expired);
    });

    test('a file valid for more than 45 days is refused', () async {
      final p = payload(expires: now.add(const Duration(days: 46)));
      await expectRejected(p, RejectReason.malformed);
    });

    test('the cached envelope is re-checked on load', () async {
      final env = await sign(payload());
      final ok = await verify(env) as Accepted<AnnouncementsFeed>;
      expect(await loadCachedAnnouncements(env, keyring: ring, state: ok.state), isNotNull);
      final other = await sign(payload(messages: [_msg('swapped')]));
      expect(await loadCachedAnnouncements(other, keyring: ring, state: ok.state), isNull);
    });
  });

  group('the parser\'s refusals', () {
    test('text of 141 code points, a line feed, a bidi mark', () async {
      await expectRejected(payload(messages: [_msg('long', extra: {'text': 'a' * 141})]), RejectReason.malformed);
      await expectRejected(payload(messages: [_msg('lf', extra: {'text': 'two\nlines'})]), RejectReason.malformed);
      await expectRejected(payload(messages: [_msg('bidi', extra: {'text': 'abc\u202edef'})]), RejectReason.malformed);
      await expectRejected(payload(messages: [_msg('empty', extra: {'text': ''})]), RejectReason.malformed);
    });

    test('140 code points are accepted', () async {
      final r = await verify(await sign(payload(messages: [_msg('max', extra: {'text': 'a' * 140})])));
      expect(r, isA<Accepted<AnnouncementsFeed>>());
    });

    test('an http link, a link with user info, an upper-case host, a long link, a long label', () async {
      for (final url in [
        'http://example.com/a',
        'https://user@example.com/a',
        'https://Example.com/a',
        'https://example.com/${'a' * 520}',
        'javascript:alert(1)',
      ]) {
        await expectRejected(
          payload(messages: [
            _msg('l', extra: {
              'link': {'label': 'Open', 'url': url},
            }),
          ]),
          RejectReason.malformed,
        );
      }
      await expectRejected(
        payload(messages: [
          _msg('l', extra: {
            'link': {'label': 'x' * 25, 'url': 'https://example.com/a'},
          }),
        ]),
        RejectReason.malformed,
      );
    });

    test('a bad PNG, a non-square PNG, a PNG outside 32 to 192 px, an oversized PNG', () async {
      Future<void> image(List<int> bytes) => expectRejected(
        payload(messages: [
          _msg('img', extra: {
            'image': {'png': base64.encode(bytes)},
          }),
        ]),
        RejectReason.malformed,
      );
      await image(utf8.encode('this is not a png at all, only text of a fitting length'));
      await image(_png(64, 48));
      await image(_png(31, 31));
      await image(_png(193, 193));
      await image([..._png(64, 64), ...List<int>.filled(9000, 0)]);
      await expectRejected(
        payload(messages: [
          _msg('img', extra: {
            'image': {'png': 'not base64 !!'},
          }),
        ]),
        RejectReason.malformed,
      );
    });

    test('5 messages, a repeated id, a bad id', () async {
      await expectRejected(payload(messages: [for (var i = 0; i < 5; i++) _msg('m$i')]), RejectReason.malformed);
      await expectRejected(payload(messages: [_msg('same'), _msg('same')]), RejectReason.malformed);
      await expectRejected(payload(messages: [_msg('Upper')]), RejectReason.malformed);
      await expectRejected(payload(messages: [_msg('-dash')]), RejectReason.malformed);
      final four = await verify(await sign(payload(messages: [for (var i = 0; i < 4; i++) _msg('m$i')])));
      expect(four, isA<Accepted<AnnouncementsFeed>>());
    });

    test('starts_at not before ends_at, a bad platform, a third platform', () async {
      await expectRejected(
        payload(messages: [_msg('t', extra: {'starts_at': '2026-11-20T00:00:00Z', 'ends_at': '2026-11-19T00:00:00Z'})]),
        RejectReason.malformed,
      );
      await expectRejected(
        payload(messages: [_msg('p', extra: {'platforms': ['tablet']})]),
        RejectReason.malformed,
      );
      await expectRejected(
        payload(messages: [_msg('p', extra: {'platforms': ['desktop', 'phone', 'desktop']})]),
        RejectReason.malformed,
      );
    });

    test('an envelope over the cap is too large', () async {
      final r = await verify('x' * (btlabsMaxEnvelopeBytes + 1));
      expect((r as Rejected<AnnouncementsFeed>).reason, RejectReason.tooLarge);
    });
  });

  group('the service', () {
    late DateTime clock;
    late MemorySecretStore store;
    late int fetches;
    late String? body;
    late bool switchOn;
    late String platform;
    late Uri? feed;
    late ProviderContainer container;

    const schedule = (first: Duration(seconds: 45), every: Duration(hours: 6), timeout: Duration(seconds: 5));

    ProviderContainer make({bool listen = true}) {
      final c = ProviderContainer(
        overrides: [
          secretStoreProvider.overrideWithValue(store),
          announcementsFeedProvider.overrideWith((ref) => feed),
          announcementsOnProvider.overrideWith((ref) => switchOn),
          announcementsScheduleProvider.overrideWithValue(schedule),
          announcementsPlatformProvider.overrideWithValue(platform),
          announcementsKeyringProvider.overrideWithValue(ring),
          announcementsClockProvider.overrideWithValue(() => clock),
          announcementsTimersProvider.overrideWithValue(true),
          announcementsFetchProvider.overrideWithValue((url, timeout) async {
            fetches++;
            return body;
          }),
        ],
      );
      addTearDown(c.dispose);
      if (listen) c.listen(announcementsProvider, (_, _) {});
      return c;
    }

    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    AnnouncementsNotifier notifier() => container.read(announcementsProvider.notifier);
    List<String> live() => container.read(announcementsProvider).live.map((m) => m.id).toList();

    setUp(() {
      clock = now;
      store = MemorySecretStore();
      fetches = 0;
      body = null;
      switchOn = true;
      platform = 'phone';
      feed = Uri.parse(_feedUrl);
      NetGate.set(NetworkMode.standard);
    });
    tearDown(() => NetGate.set(NetworkMode.standard));

    test('a fetch shows the live messages of this platform, not an ended or future one', () async {
      body = await sign(
        payload(messages: [
          _msg('both'),
          _msg('phone-only', extra: {'platforms': ['phone']}),
          _msg('desk-only', extra: {'platforms': ['desktop']}),
          _msg('ended', extra: {'ends_at': '2026-11-11T11:00:00Z'}),
        ]),
      );
      container = make();
      await notifier().checkNow();
      await settle();
      expect(live(), ['both', 'phone-only']);
    });

    test('a message becomes live when its start comes and is gone when its end comes', () async {
      body = await sign(
        payload(messages: [
          _msg('soon', extra: {'starts_at': '2026-11-11T12:30:00Z', 'ends_at': '2026-11-11T13:00:00Z'}),
        ]),
      );
      container = make();
      await notifier().checkNow();
      expect(live(), isEmpty);
      clock = DateTime.utc(2026, 11, 11, 12, 30);
      await settle();
      // The edge timer is real time here: ask for the recompute through a second accepted fetch.
      body = await sign(
        payload(serial: 101, messages: [
          _msg('soon', extra: {'starts_at': '2026-11-11T12:30:00Z', 'ends_at': '2026-11-11T13:00:00Z'}),
        ]),
      );
      await notifier().checkNow();
      expect(live(), ['soon']);
      clock = DateTime.utc(2026, 11, 11, 13);
      body = await sign(
        payload(serial: 102, messages: [
          _msg('soon', extra: {'starts_at': '2026-11-11T12:30:00Z', 'ends_at': '2026-11-11T13:00:00Z'}),
        ]),
      );
      await notifier().checkNow();
      expect(live(), isEmpty);
    });

    test('an expired feed shows nothing', () async {
      body = await sign(payload(expires: now.add(const Duration(hours: 2))));
      container = make();
      await notifier().checkNow();
      expect(live(), ['one']);
      // A new container, three hours later, reads the kept file: past its expires_at.
      container.dispose();
      clock = now.add(const Duration(hours: 3));
      container = make();
      await settle();
      expect(live(), isEmpty);
    });

    test('seen is kept once; dismissed hides the message and survives a restart', () async {
      body = await sign(payload(messages: [_msg('a'), _msg('b')]));
      container = make();
      await notifier().checkNow();
      expect(container.read(announcementsProvider).unseen.map((m) => m.id), ['a', 'b']);
      await notifier().markSeen('a');
      final firstSeen = container.read(announcementsProvider).seen['a'];
      expect(firstSeen, now);
      clock = now.add(const Duration(minutes: 5));
      await notifier().markSeen('a');
      expect(container.read(announcementsProvider).seen['a'], firstSeen, reason: 'first time only');
      expect(container.read(announcementsProvider).unseen.map((m) => m.id), ['b']);
      await notifier().markSeen('unknown');
      expect(container.read(announcementsProvider).seen.keys, ['a']);

      await notifier().dismiss('b');
      expect(live(), ['a']);

      container.dispose();
      fetches = 0;
      container = make();
      await settle();
      expect(live(), ['a'], reason: 'the kept file, seen and dismissed come back');
      expect(container.read(announcementsProvider).isSeen('a'), isTrue);
      expect(fetches, 0, reason: 'the first check waits first_check_s');
    });

    test('ids no longer in the accepted feed are pruned from seen and dismissed', () async {
      body = await sign(payload(messages: [_msg('a'), _msg('b')]));
      container = make();
      await notifier().checkNow();
      await notifier().markSeen('a');
      await notifier().dismiss('b');
      body = await sign(payload(serial: 101, messages: [_msg('c')]));
      await notifier().checkNow();
      expect(live(), ['c']);
      expect(container.read(announcementsProvider).seen, isEmpty);
      final kept = jsonDecode((await store.read(announcementsPhoneKey))!) as Map;
      expect(kept['seen'], isEmpty);
      expect(kept['dismissed'], isEmpty);
      // The id comes back later: it is new again.
      body = await sign(payload(serial: 102, messages: [_msg('b')]));
      await notifier().checkNow();
      expect(live(), ['b']);
    });

    test('the desktop keeps its state under its own key and shows its own messages', () async {
      platform = 'desktop';
      body = await sign(
        payload(messages: [
          _msg('phone-only', extra: {'platforms': ['phone']}),
          _msg('desk-only', extra: {'platforms': ['desktop']}),
        ]),
      );
      container = make();
      await notifier().checkNow();
      expect(live(), ['desk-only']);
      expect(store.values.keys, [announcementsDeskKey]);
    });

    test('a rejected file keeps the last accepted one', () async {
      body = await sign(payload(serial: 300, messages: [_msg('keep')]));
      container = make();
      await notifier().checkNow();
      expect(live(), ['keep']);
      body = await sign(payload(serial: 299, messages: [_msg('rolled-back')]));
      await notifier().checkNow();
      expect(live(), ['keep']);
      body = '{"not":"an envelope"}';
      await notifier().checkNow();
      expect(live(), ['keep']);
      body = null; // offline
      await notifier().checkNow();
      expect(live(), ['keep']);
    });

    test('a kept file that fails the check is not shown', () async {
      body = await sign(payload(messages: [_msg('a')]));
      container = make();
      await notifier().checkNow();
      container.dispose();
      final kept = jsonDecode((await store.read(announcementsPhoneKey))!) as Map<String, dynamic>;
      final env = jsonDecode(kept['envelope'] as String) as Map<String, dynamic>;
      env['payload'] = base64.encode(utf8.encode(jsonEncode(payload(messages: [_msg('forged')]))));
      kept['envelope'] = jsonEncode(env);
      store.values[announcementsPhoneKey] = jsonEncode(kept);
      container = make();
      await settle();
      expect(live(), isEmpty);
    });

    test('switch off: no fetch, nothing shown, the kept file stays; on again fetches once at once', () async {
      body = await sign(payload(messages: [_msg('a')]));
      container = ProviderContainer(
        overrides: [
          secretStoreProvider.overrideWithValue(store),
          announcementsFeedProvider.overrideWith((ref) => feed),
          announcementsOnProvider.overrideWith((ref) => ref.watch(_flag)),
          announcementsScheduleProvider.overrideWithValue(schedule),
          announcementsKeyringProvider.overrideWithValue(ring),
          announcementsClockProvider.overrideWithValue(() => clock),
          announcementsTimersProvider.overrideWithValue(true),
          announcementsFetchProvider.overrideWithValue((url, timeout) async {
            fetches++;
            return body;
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(announcementsProvider, (_, _) {});
      await notifier().checkNow();
      expect(fetches, 1);
      expect(live(), ['a']);

      container.read(_flag.notifier).set(false);
      await settle();
      expect(live(), isEmpty);
      await notifier().checkNow();
      expect(fetches, 1, reason: 'a fetch with the switch off does nothing');
      expect(store.values[announcementsPhoneKey], isNotNull, reason: 'the kept file stays');

      container.read(_flag.notifier).set(true);
      await settle();
      expect(fetches, 2, reason: 'switching on fetches once at once');
      expect(live(), ['a']);
    });

    test('switch off at start: nothing is read, nothing is fetched', () async {
      switchOn = false;
      body = await sign(payload());
      container = make();
      await notifier().checkNow();
      await settle();
      expect(fetches, 0);
      expect(live(), isEmpty);
    });

    test('no feed configured: nothing is fetched', () async {
      feed = null;
      body = await sign(payload());
      container = make();
      await notifier().checkNow();
      expect(fetches, 0);
      expect(live(), isEmpty);
    });

    test('Node only and Kill switch fetch nothing; standard fetches', () async {
      body = await sign(payload());
      container = make();
      for (final m in [NetworkMode.nodeOnly, NetworkMode.killSwitch]) {
        NetGate.set(m);
        await notifier().checkNow();
        expect(fetches, 0, reason: m.name);
      }
      NetGate.set(NetworkMode.standard);
      await notifier().checkNow();
      expect(fetches, 1);
      expect(live(), ['one']);
    });

    test('the request is a plain GET of the feed URL with the configured timeout', () async {
      Uri? asked;
      Duration? waited;
      body = await sign(payload());
      container = ProviderContainer(
        overrides: [
          secretStoreProvider.overrideWithValue(store),
          announcementsFeedProvider.overrideWith((ref) => feed),
          announcementsOnProvider.overrideWith((ref) => true),
          announcementsScheduleProvider.overrideWithValue(schedule),
          announcementsKeyringProvider.overrideWithValue(ring),
          announcementsClockProvider.overrideWithValue(() => clock),
          announcementsTimersProvider.overrideWithValue(true),
          announcementsFetchProvider.overrideWithValue((url, timeout) async {
            asked = url;
            waited = timeout;
            return body;
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(announcementsProvider, (_, _) {});
      await notifier().checkNow();
      expect(asked.toString(), _feedUrl);
      expect(asked!.hasQuery, isFalse);
      expect(waited, const Duration(seconds: 5));
    });
  });

  group('the schedule', () {
    test('first check after first_check_s, then every check_every_h; none in the background', () async {
      final fetched = <DateTime>[];
      final store = MemorySecretStore();
      final text = await sign(payload());
      var clock = now;
      final c = ProviderContainer(
        overrides: [
          secretStoreProvider.overrideWithValue(store),
          announcementsFeedProvider.overrideWith((ref) => Uri.parse(_feedUrl)),
          announcementsOnProvider.overrideWith((ref) => true),
          announcementsScheduleProvider.overrideWithValue((
            first: const Duration(milliseconds: 40),
            every: const Duration(milliseconds: 200),
            timeout: const Duration(seconds: 1),
          )),
          announcementsKeyringProvider.overrideWithValue(ring),
          announcementsClockProvider.overrideWithValue(() => clock),
          announcementsTimersProvider.overrideWithValue(true),
          announcementsFetchProvider.overrideWithValue((url, timeout) async {
            fetched.add(clock);
            return text;
          }),
        ],
      );
      addTearDown(c.dispose);
      c.listen(announcementsProvider, (_, _) {});
      NetGate.set(NetworkMode.standard);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fetched, isEmpty, reason: 'not before first_check_s');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(fetched.length, 1);
      clock = clock.add(const Duration(hours: 6));
      c.read(announcementsProvider.notifier).setForeground(false);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(fetched.length, 1, reason: 'never in the background');
      c.read(announcementsProvider.notifier).setForeground(true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(fetched.length, 2, reason: 'back in the front: the interval has run out, so it is due');
    });
  });

  group('the setting and the config', () {
    test('the bundled keyring has a rank-1 and a rank-2 key; the type name is the spec\'s', () {
      expect(announcementsKeyring.keys.map((k) => k.rank), [1, 2]);
      expect(announcementsType, 'application/vnd.btlabs.wallet-for-epic.announcements+json');
    });
  });
}
