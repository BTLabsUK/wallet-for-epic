/// Pairing links found on the clipboard (Pairing UX plan, section 5): when the wallet may read
/// it, what it offers, and the once-set that keeps each link to one offer. Plain Dart, so the
/// phone, the desktop and the tests share the rules; each app brings its [ClipboardProbe].
///
/// The text read is never logged, stored or sent: only its link's SHA-256 is kept.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart' as hash;

import 'models.dart';
import 'pairing_api.dart';

/// Why the clipboard is looked at: the app came to the front, or Pair or Contacts opened.
enum PairingClipTrigger { resume, screen }

/// What the system says about the clip without handing over its text (no Android 12+ toast).
class ClipStamp {
  const ClipStamp({this.time, required this.hasText});

  /// When the clip was made (Android 8+ `ClipDescription.getTimestamp`), null where the
  /// system cannot tell one clip from the next.
  final int? time;
  final bool hasText;
}

/// The clipboard of one app.
abstract interface class ClipboardProbe {
  /// The clip's stamp, or null when there is no clipboard to read (web, tests).
  Future<ClipStamp?> stamp();

  /// The clip's text, or null.
  Future<String?> read();
}

/// What this wallet waits for, which decides what a found link may offer.
class PairingClipPending {
  const PairingClipPending({this.openInvite = false, this.waitsFinish = false, this.cardOpen = false});

  /// From the wallet's [records] at [now]; [cardOpen] while the Pair screen's in-person panel
  /// is up.
  factory PairingClipPending.of(Iterable<PairingRecord> records, {required DateTime now, bool cardOpen = false}) => PairingClipPending(
    openInvite: records.any((r) => r.state == PairingState.pendingInvite && !r.expiredAt(now)),
    waitsFinish: records.any((r) => r.state == PairingState.pendingReply),
    cardOpen: cardOpen,
  );

  /// An invite of this wallet nobody answered yet: a reply may be offered.
  final bool openInvite;

  /// An answer of this wallet waiting for its finish link: a finish link may be offered.
  final bool waitsFinish;

  /// The in-person panel is open: the other wallet's code link may be offered.
  final bool cardOpen;
}

/// The SHA-256 of [link], as the once-set keeps it.
String pairingClipHash(String link) => hash.sha256.convert(utf8.encode(link.trim())).toString();

/// The links offered once already, or shared from this wallet, as hashes, newest last; at most
/// [cap] are kept.
class PairingClipSeen {
  const PairingClipSeen([this.hashes = const []]);

  /// From [text] as [encode] wrote it; anything else reads as empty.
  factory PairingClipSeen.decode(String? text) => PairingClipSeen([
    for (final h in (text ?? '').split(','))
      if (RegExp(r'^[0-9a-f]{64}$').hasMatch(h)) h,
  ]);

  static const int cap = 32;

  final List<String> hashes;

  bool has(String link) => hashes.contains(pairingClipHash(link));

  /// With [link] added (moved to the end when it was there), the oldest dropped past [cap].
  PairingClipSeen add(String link) {
    final h = pairingClipHash(link);
    final next = [for (final x in hashes) if (x != h) x, h];
    return PairingClipSeen(next.length > cap ? next.sublist(next.length - cap) : next);
  }

  String encode() => hashes.join(',');
}

/// The link in [text] to offer, with its kind, or null: an invite always, a reply only while
/// an invite is open, a finish link only while an answer waits for it, a code only while the
/// in-person panel is open; never one in [seen].
({PairingLinkKind kind, String link})? pairingClipOffer(String text, {required PairingClipPending pending, required PairingClipSeen seen}) {
  final link = pairingLinkIn(text);
  final kind = pairingLinkKind(text);
  if (link == null || kind == null || seen.has(link)) return null;
  final offered = switch (kind) {
    PairingLinkKind.invite => true,
    PairingLinkKind.reply => pending.openInvite,
    PairingLinkKind.confirm => pending.waitsFinish,
    PairingLinkKind.card => pending.cardOpen,
  };
  return offered ? (kind: kind, link: link) : null;
}

/// Looks at the clipboard on a [PairingClipTrigger] and says what to offer. One reader per
/// app: it remembers the last clip it read, so the same clip is read once.
class PairingClipReader {
  PairingClipReader(this.probe);

  final ClipboardProbe probe;
  int? _lastTime;

  /// The link to offer now, or null. [allowed] is false while Pairing is off, the wallet is
  /// locked or not open, or a dialog or sheet is up: nothing is read then. A clip without a
  /// stamp (the desktop, Android 7) is read on a [PairingClipTrigger.screen] only: reading on
  /// every resume would read whatever another app put there, a password for example.
  Future<({PairingLinkKind kind, String link})?> look({
    required PairingClipTrigger trigger,
    required bool allowed,
    required PairingClipPending pending,
    required PairingClipSeen seen,
  }) async {
    if (!allowed) return null;
    final ClipStamp? stamp;
    try {
      stamp = await probe.stamp();
    } on Object {
      return null;
    }
    if (stamp == null || !stamp.hasText) return null;
    final time = stamp.time;
    if (time == null) {
      if (trigger == PairingClipTrigger.resume) return null;
    } else {
      if (time == _lastTime) return null;
      _lastTime = time;
    }
    final String? text;
    try {
      text = await probe.read();
    } on Object {
      return null;
    }
    if (text == null || text.isEmpty) return null;
    return pairingClipOffer(text, pending: pending, seen: seen);
  }
}
