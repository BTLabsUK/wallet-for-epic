// SPDX-License-Identifier: Apache-2.0
/// The wallet level (the view): how much of the app a user sees. A fresh install starts in the
/// basic view ([WalletLevel.justSendReceive]) when its first step is answered; Settings ›
/// Advanced changes it any time.
///
/// Presentation only: a level never changes wallet data, keys, addresses or funds, and never
/// rewrites another setting by itself (`level_features.dart` turns a level into what is drawn).
/// One model for the phone and the desktop: pure Dart, stored as one string under [levelKey]
/// in whatever key/value store the app keeps its preferences in.
///
/// Existing installs keep today's app: an install updating to a build with levels is read as
/// [WalletLevel.everything] (today's screens, today's words) and is never sent through the
/// first-start step. Only a fresh install waits for its first step ([LevelChoice.pending]).
library;

/// The three levels, shallow to deep.
enum WalletLevel {
  /// 1, "Just send and receive": Epicbox (unnamed) and QR Payment, no server names, no
  /// expert switches.
  justSendReceive(1),

  /// 2, "Not too techy, but tell me what's happening": today's app with the Advanced switches
  /// as the user sets them, in casual words.
  casual(2),

  /// 3, "Let me explore everything": today's app and words. Existing installs land here.
  everything(3);

  const WalletLevel(this.number);

  /// 1, 2 or 3, as stored and as the UI numbers it.
  final int number;

  static WalletLevel? ofNumber(int? n) {
    for (final l in values) {
      if (l.number == n) return l;
    }
    return null;
  }
}

/// The level an install that ran before levels existed is stored as: today's screens and
/// words. Settled once ([settleLevelChoice]) and never asked.
const WalletLevel existingInstallLevel = WalletLevel.everything;

/// The level a fresh install starts in when its first step is answered: the basic view. The
/// view picker is not a first step (the owner); Settings › Advanced changes it.
const WalletLevel firstStartLevel = WalletLevel.justSendReceive;

/// The preference key, new and additive: no existing key, file or folder changes.
const String levelKey = 'app.level';

/// Stored while a fresh install has not answered the first-start step yet.
const String levelPendingValue = 'ask';

/// What [levelKey] holds: a level, or the first-start step still to answer.
sealed class LevelChoice {
  const LevelChoice();

  /// The stored text: '1', '2', '3' or [levelPendingValue].
  String encode();

  /// [raw] as stored; null for a value this build does not know (read as no value, so an
  /// unknown later level never locks the app).
  static LevelChoice? decode(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return null;
    if (t == levelPendingValue) return const LevelPending();
    final level = WalletLevel.ofNumber(int.tryParse(t));
    return level == null ? null : LevelChosen(level);
  }
}

/// A fresh install that has not passed the first-start step: nothing may connect yet.
final class LevelPending extends LevelChoice {
  const LevelPending();

  @override
  String encode() => levelPendingValue;

  @override
  bool operator ==(Object other) => other is LevelPending;

  @override
  int get hashCode => 0;
}

final class LevelChosen extends LevelChoice {
  const LevelChosen(this.level);

  final WalletLevel level;

  @override
  String encode() => '${level.number}';

  @override
  bool operator ==(Object other) => other is LevelChosen && other.level == level;

  @override
  int get hashCode => level.hashCode;
}

/// The keys only an install that ran before levels existed can hold: the network choice, the
/// settings migration marker every launch writes, a sealed wallet PIN on any chain, the tour
/// mark. Any one present means "existing install".
const List<String> existingInstallMarkers = [
  'app.network',
  'app.qr_method_seen',
  'app.advanced_prefs',
  'app.phone_tour_seen',
  'wallet.mainnet.pinSealed',
  'wallet.floonet.pinSealed',
  'wallet.usernet.pinSealed',
];

/// The level choice at launch, read from [read] and settled once through [write]:
/// a stored value as it is; with none, an existing install ([markers] has a value) becomes
/// [existingInstallLevel] and a fresh one [LevelPending]. Written at once, so a fresh install
/// killed on the first screen still asks next launch, and an existing one is never asked even
/// after its marker keys are written by the new build.
Future<LevelChoice> settleLevelChoice({
  required Future<String?> Function(String key) read,
  required Future<void> Function(String key, String value) write,
  List<String> markers = existingInstallMarkers,
}) async {
  final stored = LevelChoice.decode(await read(levelKey));
  if (stored != null) return stored;
  var existing = false;
  for (final k in markers) {
    if ((await read(k)) != null) {
      existing = true;
      break;
    }
  }
  final settled = existing ? const LevelChosen(existingInstallLevel) : const LevelPending();
  await write(levelKey, settled.encode());
  return settled;
}
