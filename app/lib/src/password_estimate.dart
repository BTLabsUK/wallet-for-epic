// SPDX-License-Identifier: Apache-2.0
// The crack-time estimate under a new wallet password: zxcvbnm (a Dart port of zxcvbn-ts) with
// the word lists in assets/passwords. Pure Dart; computed on the device only. The password and
// its estimate are never logged, stored or sent.
//
// zxcvbnm 1.1.1's `Zxcvbnm.call` copies its Options on every call, and the copy re-ranks every
// dictionary (about 200 ms a keystroke). [PasswordEstimator] keeps one Options, so the ranking
// is built once and each call only matches. Same steps as `Zxcvbnm.async`, minus the copy. It
// imports zxcvbnm's src/, which is why the version is pinned exactly in pubspec.yaml.
// ignore_for_file: implementation_imports

import 'dart:math' as math;

import 'package:zxcvbnm/src/helper.dart';
import 'package:zxcvbnm/src/matching.dart';
import 'package:zxcvbnm/src/options.dart';
import 'package:zxcvbnm/src/scoring.dart';

/// Guesses a second an offline attacker gets against a stolen wallet file.
///
/// LEPIC seals the seed with Argon2id v0x13, m = 64 MiB, t = 3, p = 1
/// (`KdfParams::DEFAULT`, lepic-keychain/src/vault/kdf.rs). hashcat 7.0.0 (mode 34000) runs
/// exactly those settings at about 1,700 guesses/s on one RTX 4090; the attack is bound by
/// memory bandwidth (about 0.6 GB read and written a guess against about 1 TB/s). 1e5/s is
/// about 60 such GPUs, some $20 an hour rented. If the KDF cost changes, scale this by the
/// ratio: doubling the memory or the passes halves it.
const double attackerGuessesPerSecond = 1e5;

/// Words of this app a targeted attacker tries first.
const List<String> appWords = ['epic', 'epiccash', 'epic cash', 'wallet', 'lepic', 'blacktyger'];

/// The kinds of list in the asset files, by the name after `@`.
const Map<String, Dictionary> _kinds = {
  'passwords': Dictionary.passwords,
  'diceware': Dictionary.diceware,
  'commonWords': Dictionary.commonWords,
  'names': Dictionary.names,
  'wikipedia': Dictionary.wikipedia,
};

/// Reads one word-list file (tool/password_lists.sh): a line `@<kind>` starts a list of that
/// kind, ranked by order. Unknown kinds are skipped.
Set<Dictionaries> parseWordLists(String text) {
  final out = <Dictionaries>{};
  List<String>? list;
  for (final line in text.split('\n')) {
    if (line.startsWith('@')) {
      final kind = _kinds[line.substring(1)];
      list = kind == null ? null : <String>[];
      if (kind != null) out.add({kind: list!});
    } else if (line.isNotEmpty) {
      list?.add(line);
    }
  }
  return out;
}

class PasswordEstimator {
  /// Ranks [dictionaries] and [userInputs] now (a fraction of a second for all five
  /// languages), so that each call only matches.
  PasswordEstimator(Set<Dictionaries> dictionaries, {List<String> userInputs = appWords})
    : _options = Options(
        dictionaries: {
          ...dictionaries,
          {Dictionary.userInputs: userInputs},
        },
      ) {
    _options.rankedDictionaries;
    _options.trieNodeRoot;
  }

  final Options _options;

  /// zxcvbn's estimate of the guesses needed. Only the first 256 characters count.
  double guesses(String password) {
    final used = password.length > _options.maxLength ? password.substring(0, _options.maxLength) : password;
    final matches = synchronousMatches(OmniMatcher(_options).match(used));
    return mostGuessableMatchSequence(used, matches).guesses;
  }

  /// The time line for [password], e.g. "about 300 years to crack".
  String crackTime(String password) => crackTimeText(guesses(password) / attackerGuessesPerSecond);
}

/// "1 character", "14 characters".
String characterCount(int n) => n == 1 ? '1 character' : '$n characters';

const double _minute = 60, _hour = 3600, _day = 86400, _month = 2629800, _year = 31557600;

/// The displayed time for [seconds] of guessing: under a minute, about N minutes, hours, days,
/// months or years (one significant figure), or more than 1,000 years. Rounding up to the next
/// unit's size moves to that unit: 59.6 minutes reads "about 1 hour".
String crackTimeText(double seconds) {
  if (seconds.isNaN || seconds < _minute) return 'under a minute to crack';
  if (seconds >= 1000 * _year) return 'more than 1,000 years to crack';
  const units = [(_minute, 'minute', 60), (_hour, 'hour', 24), (_day, 'day', 30), (_month, 'month', 12), (_year, 'year', 0)];
  for (var i = 0; i < units.length; i++) {
    final (size, name, next) = units[i];
    final nextSize = i + 1 < units.length ? units[i + 1].$1 : double.infinity;
    if (seconds >= nextSize) continue;
    final value = seconds / size;
    final n = _roughly(value);
    if (next > 0 && (n >= next || value.round() >= next)) return 'about 1 ${units[i + 1].$2} to crack';
    final shown = n >= 1000 ? '1,000' : '$n';
    return 'about $shown ${n == 1 ? name : '${name}s'} to crack';
  }
  return 'more than 1,000 years to crack';
}

/// One significant figure: 7, 30, 300. The estimate is no more precise than that.
int _roughly(double value) {
  if (value < 1) return 1;
  final magnitude = math.pow(10, (math.log(value) / math.ln10).floor()).toInt();
  return math.max(1, (value / magnitude).round()) * magnitude;
}
