// Pairing links on the clipboard (Pairing UX plan 5): what is offered for each kind and pending
// state, the once-set, links this wallet sent, and when nothing is read at all.
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/pairing_api.dart';
import 'package:epic_wallet/src/pairing_clipboard.dart';
import 'package:epic_wallet/src/pairing_fake.dart' show fakePairingLink;
import 'package:flutter_test/flutter_test.dart';

/// A clipboard whose clip and stamp the test sets, counting reads.
class _Clip implements ClipboardProbe {
  String? text;
  int? time;
  bool stamps = true;
  int reads = 0;

  void put(String t, int at) {
    text = t;
    time = at;
  }

  @override
  Future<ClipStamp?> stamp() async => ClipStamp(time: stamps ? time : null, hasText: text != null);

  @override
  Future<String?> read() async {
    reads++;
    return text;
  }
}

final _invite = fakePairingLink('pair', {'t': 'i1', 'n': 'Anna'});
final _reply = fakePairingLink('pair-reply', {'t': 'i1', 'n': 'Ola'});
final _finish = fakePairingLink('pair-confirm', {'t': 'p1', 'n': 'Anna'});
final _card = fakePairingLink('contact', {'c': 'c1', 'n': 'Anna'});

const _none = PairingClipPending();
const _all = PairingClipPending(openInvite: true, waitsFinish: true, cardOpen: true);

void main() {
  group('what is offered', () {
    test('an invite always; the link inside a chat message is found', () {
      final found = pairingClipOffer('Pair with me in Epic Cash: $_invite', pending: _none, seen: const PairingClipSeen());
      expect(found?.kind, PairingLinkKind.invite);
      expect(found?.link, _invite);
    });

    test('a reply only while an invite is open', () {
      expect(pairingClipOffer(_reply, pending: _none, seen: const PairingClipSeen()), isNull);
      expect(pairingClipOffer(_reply, pending: const PairingClipPending(openInvite: true), seen: const PairingClipSeen())?.kind, PairingLinkKind.reply);
    });

    test('a finish link only while an answer waits for one', () {
      expect(pairingClipOffer(_finish, pending: const PairingClipPending(openInvite: true), seen: const PairingClipSeen()), isNull);
      expect(pairingClipOffer(_finish, pending: const PairingClipPending(waitsFinish: true), seen: const PairingClipSeen())?.kind, PairingLinkKind.confirm);
    });

    test('a code only while the in-person panel is open', () {
      expect(pairingClipOffer(_card, pending: const PairingClipPending(openInvite: true, waitsFinish: true), seen: const PairingClipSeen()), isNull);
      expect(pairingClipOffer(_card, pending: const PairingClipPending(cardOpen: true), seen: const PairingClipSeen())?.kind, PairingLinkKind.card);
    });

    test('anything else: nothing', () {
      expect(pairingClipOffer('epic:esABC@epicbox.epiccash.com?amount=1', pending: _all, seen: const PairingClipSeen()), isNull);
      expect(pairingClipOffer('hello', pending: _all, seen: const PairingClipSeen()), isNull);
    });

    test('pending from the records: an expired invite takes no reply', () {
      final now = DateTime(2026, 10, 27, 12);
      PairingRecord r(PairingState s, {DateTime? expires}) =>
          PairingRecord(id: 'x', state: s, way: PairingWay.link, inviter: s == PairingState.pendingInvite, createdAt: now, expiresAt: expires);
      expect(PairingClipPending.of([r(PairingState.pendingInvite, expires: now.add(const Duration(hours: 1)))], now: now).openInvite, isTrue);
      expect(PairingClipPending.of([r(PairingState.pendingInvite, expires: now.subtract(const Duration(minutes: 1)))], now: now).openInvite, isFalse);
      expect(PairingClipPending.of([r(PairingState.pendingReply)], now: now).waitsFinish, isTrue);
      expect(PairingClipPending.of([r(PairingState.verified)], now: now).waitsFinish, isFalse);
    });
  });

  group('once', () {
    test('a link in the set is never offered; only its hash is kept', () {
      final seen = const PairingClipSeen().add(_invite);
      expect(pairingClipOffer(_invite, pending: _all, seen: seen), isNull);
      expect(seen.encode(), isNot(contains('epiccash')));
      expect(PairingClipSeen.decode(seen.encode()).has(_invite), isTrue);
    });

    test('links this wallet shared are added when shared, so its own invite never comes back', () {
      final shared = const PairingClipSeen().add(_finish);
      expect(pairingClipOffer('Finish our Epic Cash pairing: $_finish', pending: _all, seen: shared), isNull);
    });

    test('keeps the last 32', () {
      var seen = const PairingClipSeen();
      for (var i = 0; i < 40; i++) {
        seen = seen.add(fakePairingLink('pair', {'t': 'i$i'}));
      }
      expect(seen.hashes, hasLength(PairingClipSeen.cap));
      expect(seen.has(fakePairingLink('pair', {'t': 'i0'})), isFalse);
      expect(seen.has(fakePairingLink('pair', {'t': 'i39'})), isTrue);
    });

    test('garbage in the stored set reads as empty', () {
      expect(PairingClipSeen.decode('nope,epiccash://pair/1/x').hashes, isEmpty);
      expect(PairingClipSeen.decode(null).hashes, isEmpty);
    });
  });

  group('the reader', () {
    test('nothing is read while not allowed (Pairing off, locked, a dialog up)', () async {
      final clip = _Clip()..put(_invite, 1);
      final reader = PairingClipReader(clip);
      final found = await reader.look(trigger: PairingClipTrigger.resume, allowed: false, pending: _all, seen: const PairingClipSeen());
      expect(found, isNull);
      expect(clip.reads, 0);
    });

    test('each clip is read once: an unchanged clip on the next resume is not read again (no second toast)', () async {
      final clip = _Clip()..put(_invite, 1);
      final reader = PairingClipReader(clip);
      final first = await reader.look(trigger: PairingClipTrigger.resume, allowed: true, pending: _none, seen: const PairingClipSeen());
      expect(first?.kind, PairingLinkKind.invite);
      final again = await reader.look(trigger: PairingClipTrigger.screen, allowed: true, pending: _none, seen: const PairingClipSeen());
      expect(again, isNull);
      expect(clip.reads, 1);
      clip.put(_reply, 2);
      final next = await reader.look(trigger: PairingClipTrigger.resume, allowed: true, pending: const PairingClipPending(openInvite: true), seen: const PairingClipSeen());
      expect(next?.kind, PairingLinkKind.reply);
      expect(clip.reads, 2);
    });

    test('no text on the clipboard: nothing is read', () async {
      final clip = _Clip();
      final found = await PairingClipReader(clip).look(trigger: PairingClipTrigger.screen, allowed: true, pending: _all, seen: const PairingClipSeen());
      expect(found, isNull);
      expect(clip.reads, 0);
    });

    test('Android 7 (no stamp): read when Pair or Contacts opens, never on resume', () async {
      final clip = _Clip()
        ..put(_invite, 1)
        ..stamps = false;
      final reader = PairingClipReader(clip);
      expect(await reader.look(trigger: PairingClipTrigger.resume, allowed: true, pending: _none, seen: const PairingClipSeen()), isNull);
      expect(clip.reads, 0);
      expect((await reader.look(trigger: PairingClipTrigger.screen, allowed: true, pending: _none, seen: const PairingClipSeen()))?.kind, PairingLinkKind.invite);
    });

    test('the desktop (no stamp) never reads on resume; the once-set keeps a screen read to one offer', () async {
      final clip = _Clip()
        ..put(_invite, 1)
        ..stamps = false;
      final reader = PairingClipReader(clip);
      expect(await reader.look(trigger: PairingClipTrigger.resume, allowed: true, pending: _none, seen: const PairingClipSeen()), isNull);
      expect(clip.reads, 0);
      final found = await reader.look(trigger: PairingClipTrigger.screen, allowed: true, pending: _none, seen: const PairingClipSeen());
      expect(found?.kind, PairingLinkKind.invite);
      final seen = const PairingClipSeen().add(found!.link);
      expect(await reader.look(trigger: PairingClipTrigger.screen, allowed: true, pending: _none, seen: seen), isNull);
    });
  });
}
