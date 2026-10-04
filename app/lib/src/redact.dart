/// Scrubs secrets from text before it is logged or put in a feedback report.
///
/// It runs at the call (`AppLog`) and again at the log file sink (`FileLogSink` in
/// `app_log.dart`). The Rust twin `rust/src/core/redact.rs` applies the same rules in the same
/// order to the old core's lines until R-01 removes it; each has tests:
///
/// 1. A slate (text with `"participant_data"`, `"public_blind_excess"` or `"part_sig"`) becomes
///    `[slate]` from its first `{` on.
/// 2. A run of [phraseRun] or more recovery-phrase words, separated only by spaces, digits and
///    list punctuation, becomes `[words]`.
/// 3. The value after a secret key (`password=`, `pin: `, `"token":"`, `Bearer `) becomes
///    `[redacted]`, and so does a 4 to 8 digit number right after `pin`.
/// 4. A UUID keeps its first 8 characters and gets `…`. 32 or more hex digits become `[hex]`.
///    Any other run of 64 or more token characters that is not a URL path becomes `[redacted]`
///    (FCM tokens, JWTs, base64). 40 or more base58 characters, an epicbox address key, keep the
///    first 6 and get `…`, so `es…@relay` stays readable.
library;

import 'bip39_words.dart';

/// Wordlist words in a row that count as a recovery phrase.
const int phraseRun = 8;

const String redacted = '[redacted]';

const List<String> _secretKeys = [
  'password',
  'passphrase',
  'pin',
  'mnemonic',
  'phrase',
  'seed',
  'mask',
  'token',
  'secret',
  'api_key',
  'apikey',
  'authorization',
];

const List<String> _authSchemes = ['bearer', 'basic'];

const List<String> _slateMarkers = [
  '"participant_data"',
  '"public_blind_excess"',
  '"part_sig"',
];

/// [text] with every secret the rules above recognise replaced.
String redact(String text) {
  var out = _redactSlate(text);
  out = _redactPhrases(out);
  out = _redactKeyed(out);
  out = out.replaceAllMapped(
    RegExp(r'[A-Za-z0-9-]+'),
    (m) => _uuid.hasMatch(m[0]!) ? '${m[0]!.substring(0, 8)}…' : m[0]!,
  );
  out = out.replaceAllMapped(
    RegExp(r'[A-Za-z0-9]+'),
    (m) => m[0]!.length >= 32 && _hex.hasMatch(m[0]!) ? '[hex]' : m[0]!,
  );
  out = out.replaceAllMapped(
    RegExp(r'[A-Za-z0-9_\-+/=:.~]+'),
    (m) => m[0]!.length >= 64 && !m[0]!.contains('//') ? redacted : m[0]!,
  );
  return out.replaceAllMapped(
    RegExp(r'[A-Za-z0-9]+'),
    (m) => m[0]!.length >= 40 && _base58.hasMatch(m[0]!)
        ? '${m[0]!.substring(0, 6)}…'
        : m[0]!,
  );
}

final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
final RegExp _hex = RegExp(r'^[0-9a-fA-F]+$');
final RegExp _base58 = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$');

String _redactSlate(String text) {
  if (!_slateMarkers.any(text.contains)) return text;
  final brace = text.indexOf('{');
  return brace < 0 ? '[slate]' : '${text.substring(0, brace)}[slate]';
}

final RegExp _word = RegExp(r'[A-Za-z]+');
final RegExp _join = RegExp(r'^[\s0-9,.;:)(-]+$');

bool _isPhraseWord(String word) =>
    word.length >= 3 &&
    word.length <= 8 &&
    bip39Words.contains(word.toLowerCase());

String _redactPhrases(String text) {
  final spans = <(int, int, int)>[]; // start, end, words
  (int, int, int)? run;
  RegExpMatch? previous;
  for (final m in _word.allMatches(text)) {
    if (!_isPhraseWord(m[0]!)) {
      if (run != null) spans.add(run);
      run = null;
    } else {
      final current = run;
      final continues =
          current != null &&
          previous != null &&
          _join.hasMatch(text.substring(previous.end, m.start));
      if (current != null && continues) {
        run = (current.$1, m.end, current.$3 + 1);
      } else {
        if (current != null) spans.add(current);
        run = (m.start, m.end, 1);
      }
    }
    previous = m;
  }
  if (run != null) spans.add(run);
  final out = StringBuffer();
  var at = 0;
  for (final (start, end, count) in spans) {
    if (count < phraseRun) continue;
    out
      ..write(text.substring(at, start))
      ..write('[words]');
    at = end;
  }
  out.write(text.substring(at));
  return out.toString();
}

bool _isWordChar(int c) =>
    (c >= 0x30 && c <= 0x39) ||
    (c >= 0x41 && c <= 0x5a) ||
    (c >= 0x61 && c <= 0x7a);

bool _endsValue(int c) => ' \t\r\n"\',;})]&<'.codeUnits.contains(c);

int _skip(String text, int i, bool Function(int) what) {
  while (i < text.length && what(text.codeUnitAt(i))) {
    i++;
  }
  return i;
}

bool _quoteOrSpace(int c) => c == 0x22 || c == 0x27 || c == 0x20 || c == 0x09;

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

(int, int)? _keyedValue(String key, String text, int after) {
  var i = _skip(text, after, _quoteOrSpace);
  final int start;
  if (_authSchemes.contains(key)) {
    if (i == after || i >= text.length) return null;
    start = i;
  } else if (i < text.length && (text[i] == ':' || text[i] == '=')) {
    i = _skip(text, i + 1, _quoteOrSpace);
    start = i;
  } else if (key == 'pin') {
    final end = _skip(text, i, _isDigit);
    final digits = end - i;
    final bounded = end >= text.length || !_isWordChar(text.codeUnitAt(end));
    return digits >= 4 && digits <= 8 && bounded ? (i, end) : null;
  } else {
    return null;
  }
  final end = _skip(text, start, (c) => !_endsValue(c));
  return end > start ? (start, end) : null;
}

String _redactKeyed(String text) {
  // ASCII-only lowercasing keeps every index, which toLowerCase does not promise.
  final haystack = String.fromCharCodes(
    text.codeUnits.map((c) => c >= 0x41 && c <= 0x5a ? c + 32 : c),
  );
  final spans = <(int, int)>[];
  for (final key in [..._secretKeys, ..._authSchemes]) {
    var from = 0;
    while (true) {
      final at = haystack.indexOf(key, from);
      if (at < 0) break;
      final after = at + key.length;
      from = after;
      final startsWord = at == 0 || !_isWordChar(text.codeUnitAt(at - 1));
      final endsWord =
          after >= text.length || !_isWordChar(text.codeUnitAt(after));
      if (!startsWord || !endsWord) continue;
      final span = _keyedValue(key, text, after);
      if (span != null && text.substring(span.$1, span.$2) != redacted) {
        spans.add(span);
      }
    }
  }
  spans.sort((a, b) => a.$1.compareTo(b.$1));
  final out = StringBuffer();
  var at = 0;
  for (final (start, end) in spans) {
    if (start < at) continue;
    out
      ..write(text.substring(at, start))
      ..write(redacted);
    at = end;
  }
  out.write(text.substring(at));
  return out.toString();
}
