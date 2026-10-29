// SPDX-License-Identifier: Apache-2.0
/// Cleans text before it goes into a problem report: the Electron GUI's `logSanitize.js` rules,
/// then the app's own [redact]. On top of what [redact] does for every log line, a report loses:
///
/// - slatepacks, and slates line by line (not the rest of the log after one)
/// - recovery phrases of 8 or more words, in any case and with any separators, one typo allowed
/// - values after password / secret / token / seed / key / nonce / cookie… and `--password`,
///   `Basic` / `Bearer` credentials, and `user:password@` in URLs
/// - home folders (`/home/<user>`, `C:\Users\<user>`, UNC `\\host\`) → `~`, and the user and
///   computer names when given
/// - onion addresses, Epicbox addresses and other base58 keys (whole, and the 6 characters
///   [redact] keeps), emails, IP addresses (not loopback), and host names that are not a known
///   public node, Epicbox or service host → `<onion-n>`, `<address-n>`, `<email-n>`, `<ip-n>`,
///   `<host-n>`. The same value is the same name in one report, and nothing of it is kept.
/// - long hex → `<hex-n>`, long base64 → `<blob>`
///
/// Kept on purpose, as in the GUI: amounts, heights, times, ports, versions and error texts.
library;

import 'bip39_words.dart';
import 'redact.dart';
import 'settings_file/host_settings.dart' show hostSettings, shippedHostSettings;

/// Hosts kept as they are: every host the shipped files name (the default copy's servers and
/// `app-config.toml`'s sites), and `report.keep_hosts`. A server the user added to
/// `settings.toml` (a home node, a private relay) is not public and is redacted like any other.
Set<String> get knownPublicHosts => {...shippedHostSettings.allHosts, ...hostSettings.reportKeepHosts};

List<String> get _keepDomains => hostSettings.reportKeepDomains;

const Set<String> _commonNames = {
  'user', 'users', 'admin', 'administrator', 'test', 'server', 'root', 'home', 'epic', 'wallet',
  'node', 'owner', 'guest', 'default', 'public', 'pc', 'desktop', 'laptop', 'local', 'localhost',
  'main', 'info', 'debug', 'error', 'warn', 'app', 'data', 'log', 'logs', 'system', 'windows',
  'linux', 'mac', 'host',
};

/// Who is reporting, so their home folder and names come out too. All optional.
class CleanContext {
  const CleanContext({this.home, this.username, this.hostname});

  final String? home;
  final String? username;
  final String? hostname;
}

/// The pseudonyms of one report: `<ip-1>`, `<address-2>`…
class CleanIds {
  final Map<String, String> _names = {};
  final Map<String, int> _counts = {};

  String of(String kind, String value) => _names.putIfAbsent(
    '$kind ${value.toLowerCase()}',
    () => '<$kind-${_counts[kind] = (_counts[kind] ?? 0) + 1}>',
  );
}

const int _maxLine = 8000;

final _ipv4 = RegExp(
  r'(?<![\w.])(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?![\w.]*\d)',
);
final _ipv6 = RegExp(r'(?<![\w:])(?:[0-9A-Fa-f]{0,4}:){2,7}(?:[0-9A-Fa-f]{1,4}|:)?(?![\w:])');
final _secretKey = RegExp(
  r'''\b((?:wallet[_ ]?)?(?:pass(?:word|phrase)?|secret|api[_-]?secret|owner[_-]?api[_-]?secret|token|seed|mnemonic|recovery[_ ]phrase|phrase|private[_ ]?key|priv[_ ]?key|secret[_ ]?key|blind(?:ing)?(?:[_ ]?factor)?|nonce|authorization|cookie))(\s*["']?\s*[:=]\s*|\s+(?=["']))(?!["']?<redacted>|(?:Basic|Bearer) <redacted>)("(?:[^"\\\r\n]|\\.)*"|'(?:[^'\\\r\n]|\\.)*'|[^\s"',;})\]]+)''',
  caseSensitive: false,
);
final _passArg = RegExp(r'''(--pass(?:word)?(?:\s+|=))(?!<redacted>)("[^"]*"|'[^']*'|\S+)''');
final _auth = RegExp(r'\b(Basic|Bearer)\s+(?!<redacted>)[A-Za-z0-9+/=._~-]{6,}');
final _userinfo = RegExp(r'''\b([a-z][a-z0-9+.-]{1,15}://)[^/\s@"'<>]{1,200}@''', caseSensitive: false);
final _urlHost = RegExp(r'''\b([a-z][a-z0-9+.-]{1,15}://)(\[[0-9A-Fa-f:.]+\]|[^/\s:?#"'<>\][]+)''', caseSensitive: false);
final _slateKeys = RegExp(
  r'"(?:participant_data|num_participants|part_sig|public_blind_excess|blinding_factor|sta|tx|offset|kernels)"\s*:',
);
final _winHome = RegExp(
  r'''(?:\b[A-Za-z]:|\\\\[^\\/\s"'<>|]+\\{1,2}[^\\/\s"'<>|]+)?(\\{1,2}|/)(?:Users|Documents and Settings)(?:\\{1,2}|/)(?!<user>)(?:[^\\/"'<>|*?\r\n:]{1,64}?(?=\\)|[^\\/\s"'<>|*?:,;)\]]+)''',
);
final _unixHome = RegExp(r'''(?<![\w.~-])/(?:home|Users|var/home)/(?!<user>)[^/\s"'<>|*?:,;)\]]+|(?<![\w.~-])/root(?=/|\b)''');
final _unc = RegExp(r'\\\\(?!<host>)([A-Za-z0-9][A-Za-z0-9._$-]{0,62})(?=\\)');
final _onion = RegExp(r'\b[a-z2-7]{56}(\.onion)?\b');
final _base58 = RegExp(r'(?<![\w…<-])[1-9A-HJ-NP-Za-km-z]{46,}(?![\w…])(@[A-Za-z0-9.-]+(?::\d+)?)?');
// What [redact] leaves of an address: its first 6 characters and an ellipsis.
final _base58Kept = RegExp(r'(?<![\w…<-])[1-9A-HJ-NP-Za-km-z]{6}…(@[A-Za-z0-9.-]+(?::\d+)?)?');
final _hex = RegExp(r'(?<![\w…<-])[0-9a-fA-F]{32,}(?![\w…])');
final _base64 = RegExp(r'(?<![\w+/…<])[A-Za-z0-9+/]{48,}={0,2}(?![\w+/=…])');
final _email = RegExp(
  r'(?<![\w.%+-])[A-Za-z0-9._%+-]{1,64}@[A-Za-z0-9-]{1,63}(?:\.[A-Za-z0-9-]{1,63})*\.[A-Za-z]{2,24}\b',
);
final _hostPort = RegExp(r'(?<![\w.@/<-])((?:[A-Za-z0-9-]{1,63}\.)+[A-Za-z]{2,24})(?=:\d{2,5}\b)');
final _localHost = RegExp(r'(?<![\w.@/<-])[A-Za-z0-9-]{1,63}\.(?:lan|local|home|internal|localdomain)\b', caseSensitive: false);

bool _isKnownHost(String host) {
  final h = host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
  if (const {'localhost', '127.0.0.1', '[::1]', '::1', '0.0.0.0'}.contains(h) || h.startsWith('127.')) return true;
  if (knownPublicHosts.contains(h)) return true;
  return _keepDomains.any((d) => h == d || h.endsWith('.$d'));
}

String _escape(String s) => s.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m[0]}');

/// A bare host name for a report: kept when public, else `<host-n>` (or `<ip-n>`).
String cleanHost(String host, CleanIds ids) {
  final h = host.trim();
  if (h.isEmpty || _isKnownHost(h)) return h;
  return ids.of(_ipv4.hasMatch(h) || h.contains(':') ? 'ip' : 'host', h);
}

/// [text] cleaned for a report. Pass one [ids] for every text of one report, so the same
/// address has the same name in all of them.
String cleanForReport(String text, {CleanContext context = const CleanContext(), CleanIds? ids}) {
  final names = ids ?? CleanIds();
  var t = text;
  String sub(RegExp re, String Function(Match m) fn) => t = t.replaceAllMapped(re, fn);

  // No pattern works on more than _maxLine characters at once.
  sub(
    RegExp('[^\\r\\n]{$_maxLine}[^\\r\\n]+'),
    (m) => '${m[0]!.substring(0, _maxLine)} [rest of a long line left out]',
  );

  // Whole blocks: slatepacks, slates, recovery phrases.
  t = _cutSlatepacks(t);
  sub(RegExp(r'[^\r\n]*\{[^\r\n]*'), (m) {
    final line = m[0]!;
    return _slateKeys.hasMatch(line) ? '${line.substring(0, line.indexOf('{'))}[slate removed]' : line;
  });
  t = _cutPhrases(t, 8);

  // Secret-looking values.
  sub(_passArg, (m) => '${m[1]}<redacted>');
  sub(_auth, (m) => '${m[1]} <redacted>');
  sub(_secretKey, (m) {
    final value = m[3]!;
    if (RegExp(r'''^["']?(?:true|false|null|none|set|unset|\*+|<[a-z]+>)["']?$''', caseSensitive: false).hasMatch(value)) {
      return m[0]!;
    }
    final quote = value.startsWith('"') || value.startsWith("'") ? value[0] : '';
    return '${m[1]}${m[2]}$quote<redacted>$quote';
  });
  sub(_userinfo, (m) => m[1]!);

  // Home folders and names.
  final home = context.home?.replaceFirst(RegExp(r'[\\/]+$'), '') ?? '';
  if (home.length >= 3) {
    final variants = {home, if (home.contains('\\')) ...[home.replaceAll('\\', '\\\\'), home.replaceAll('\\', '/')]}.toList()
      ..sort((a, b) => b.length - a.length);
    final windows = RegExp(r'^[A-Za-z]:|\\').hasMatch(home);
    for (final v in variants) {
      sub(RegExp('${_escape(v)}(?![\\w\\u00C0-\\uFFFF])', caseSensitive: !windows), (_) => '~');
    }
  }
  sub(_winHome, (_) => '~');
  sub(_unixHome, (_) => '~');
  sub(_unc, (_) => r'\\<host>');
  for (final (name, mark) in [(context.username, '<user>'), (context.hostname, '<host>')]) {
    final n = (name ?? '').trim();
    if (n.length < 3 || _commonNames.contains(n.toLowerCase())) continue;
    sub(
      RegExp('(?<![\\p{L}\\p{N}_<])${_escape(n)}(?![\\p{L}\\p{N}_>])', caseSensitive: false, unicode: true),
      (_) => mark,
    );
  }

  // Addresses: onion, Epicbox and base58 keys with their domain, emails, then hosts and IPs.
  String host(String h) => _isKnownHost(h) ? h : names.of('host', h);
  String address(Match m) {
    final at = m[1];
    final key = at == null ? m[0]! : m[0]!.substring(0, m[0]!.length - at.length);
    // All digits or all letters is not a key (a long number, a word).
    if (RegExp(r'^[0-9]+$').hasMatch(key) || RegExp(r'^[A-Za-z]+$').hasMatch(key)) return m[0]!;
    var domain = '';
    if (at != null) {
      final parts = at.substring(1).split(':');
      domain = '@${host(parts[0])}${parts.length > 1 ? ':${parts[1]}' : ''}';
    }
    return '${names.of('address', key)}$domain';
  }

  sub(_onion, (m) => '${names.of('onion', m[0]!.replaceFirst(RegExp(r'\.onion$'), ''))}${m[1] ?? ''}');
  sub(_base58, address);
  sub(_email, (m) => names.of('email', m[0]!));
  sub(_urlHost, (m) {
    final h = m[2]!;
    final bare = h.replaceAll(RegExp(r'^\[|\]$'), '');
    if (_isKnownHost(bare) || RegExp(r'^<[a-z]+(-\d+)?>$').hasMatch(h) || RegExp(r'^[\d.]+$|^\[').hasMatch(h)) {
      return m[0]!;
    }
    return '${m[1]}${names.of('host', h)}';
  });
  sub(_hostPort, (m) => RegExp(r'^[\d.]+$').hasMatch(m[0]!) ? m[0]! : host(m[0]!));
  sub(_localHost, (m) => names.of('host', m[0]!));
  sub(_ipv4, (m) => RegExp(r'^(127\.|0\.0\.0\.0$)').hasMatch(m[0]!) ? m[0]! : names.of('ip', m[0]!));
  sub(_ipv6, (m) {
    final s = m[0]!;
    final colons = ':'.allMatches(s).length;
    final ip = s.contains('::')
        ? RegExp('[0-9a-f]', caseSensitive: false).hasMatch(s) || s == '::'
        : colons >= 5 && RegExp('[a-f]', caseSensitive: false).hasMatch(s) || colons == 7;
    if (!ip || s == '::1' || s == '::' || RegExp(r'^[0-9:]+$').hasMatch(s) && !s.contains('::')) return s;
    return names.of('ip', s);
  });

  // Long hex (commitments and kernels are on the chain) and blobs.
  sub(_hex, (m) => names.of('hex', m[0]!));
  sub(_base64, (m) => RegExp('[0-9]').hasMatch(m[0]!) && RegExp('[A-Za-z]').hasMatch(m[0]!) ? '<blob>' : m[0]!);

  // The app's own rules, line by line (its slate rule would take the rest of the text), then
  // what they keep of an address.
  t = t.split('\n').map(redact).join('\n');
  sub(_base58Kept, address);
  return t;
}

String _cutSlatepacks(String t) {
  const begin = 'BEGINSLATEPACK.', end = 'ENDSLATEPACK.';
  final out = StringBuffer();
  var at = 0;
  for (var i = t.indexOf(begin); i >= 0; i = t.indexOf(begin, at)) {
    final e = t.indexOf(end, i + begin.length);
    final nl = t.indexOf('\n', i);
    final next = t.indexOf(begin, i + begin.length);
    final int stop;
    if (e >= 0 && (next < 0 || e < next)) {
      stop = e + end.length;
    } else {
      stop = nl >= 0 ? nl : t.length;
    }
    out
      ..write(t.substring(at, i))
      ..write('[slatepack removed]');
    at = stop;
  }
  out.write(t.substring(at));
  return out.toString();
}

/// Runs of recovery-phrase words in any case, separated by anything but letters, with at most
/// one other word inside (a typo): (start, end) of each run of at least [min] words (the GUI's
/// `phraseRuns`).
List<(int, int)> phraseRuns(String s, {int min = 12}) {
  final runs = <(int, int)>[];
  int? start;
  var end = 0, words = 0, misses = 0;
  var typo = false;
  void close() {
    if (start != null && words + (typo ? 1 : 0) >= min) runs.add((start!, end));
    start = null;
  }

  var prevEnd = 0;
  for (final m in RegExp('[A-Za-z]+').allMatches(s)) {
    final w = m[0]!.toLowerCase();
    final gap = m.start - prevEnd;
    prevEnd = m.end;
    // A long gap (a new paragraph of other text) ends a run.
    if (start != null && gap > 12) close();
    if (bip39Words.contains(w)) {
      if (start == null) {
        start = m.start;
        words = 0;
        misses = 0;
        typo = false;
      }
      if (misses > 0) typo = true;
      words++;
      end = m.end;
    } else if (start != null && misses == 0 && w.length >= 3 && w.length <= 8) {
      misses++;
    } else {
      close();
    }
  }
  close();
  return runs;
}

/// Whether [text] holds what looks like a recovery phrase: 8 or more words.
bool looksLikePhrase(String text) => phraseRuns(text, min: 8).isNotEmpty;

String _cutPhrases(String t, int min) {
  final runs = phraseRuns(t, min: min);
  if (runs.isEmpty) return t;
  final out = StringBuffer();
  var at = 0;
  for (final (a, b) in runs) {
    out
      ..write(t.substring(at, a))
      ..write('[recovery phrase removed]');
    at = b;
  }
  out.write(t.substring(at));
  return out.toString();
}
