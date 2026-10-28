// SPDX-License-Identifier: Apache-2.0
// Fails on text the user reads that is written into a desktop screen instead of the ARB files
// (lib/l10n/desk/, merged by tool/desk_l10n.py): every string literal under lib/src/desktop that
// reads like words, outside log calls, keys and other technical places.
//
// A literal that is not for the user (a file name, a protocol word, a format) stays when its line
// ends with `// l10n-ok` (add the reason after it when it is not obvious). A file that holds no
// user text at all (mock data, screenshot fixtures) is listed in [_skipped].
//
//   flutter test test/desktop/desk_strings_lint_test.dart
//   DESK_L10N_LINT=lib/src/desktop/screens/wallet flutter test test/desktop/desk_strings_lint_test.dart
//     (lists what is left under that path, pending or not)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _root = 'lib/src/desktop';

/// Files with no text for the user: fixtures, mock data, developer screens.
const _skipped = <String>{
  'data/mock_wallet.dart',
  'data/mock_devices.dart', // the prototype's phone for the tour and the tests
  'data/mock_invoices.dart',
  'screens/debug/',
  'screens/invoices/proto_panel.dart', // the mock wallet's prototype panel: never ships
  'app/shots.dart',
  'screens/invoices/shots.dart',
  'screens/invoices/shots_core.dart',
  'screens/invoices/shots_help.dart',
  'screens/invoices/shots_pay.dart',
  'screens/invoices/shots_req.dart',
  'screens/devices/shots.dart',
  'screens/onboarding/shots.dart',
  'screens/settings/shots.dart',
  'screens/settings/help_places.dart', // English help place targets, the keys links resolve by
  'screens/transfer/shots.dart',
  'screens/wallet/shots.dart',
  'theme/',
};

/// Files not converted yet. Remove a file once it is clean; the test fails on a pending file
/// that has nothing left, so this list only shrinks.
const _pending = <String>{
  // PENDING-START
  // PENDING-END
};

/// Calls whose string arguments are never shown: logs, keys, patterns, programmer errors.
const _technicalCalls = <String>{
  'logWarn', 'logInfo', 'logDebug', 'logError', 'logSize', 'log', 'debugPrint', 'print',
  'Key', 'ValueKey', 'GlobalKey', 'ObjectKey', 'PageStorageKey', 'LocalKey',
  'assert', 'StateError', 'ArgumentError', 'UnimplementedError', 'UnsupportedError', 'AssertionError',
  'RegExp', 'DateFormat', 'NumberFormat', 'Uri', 'parse', 'tryParse', 'Locale',
  'Platform', 'environment', 'MethodChannel', 'EventChannel', 'fromEnvironment',
  'Process', 'run', 'start', 'File', 'Directory', 'Link', 'join', 'basename',
  'jsonDecode', 'jsonEncode', 'startsWith', 'endsWith', 'contains', 'split', 'replaceAll',
  'getString', 'setString', 'getBool', 'setBool', 'getInt', 'setInt', 'read', 'write', 'delete',
  'debugLabel', 'restorationId', 'Semantics_identifier', 'identifier',
};

/// Named arguments whose strings are never shown.
const _technicalNames = <String>{
  'debugLabel', 'restorationId', 'identifier', 'fontFamily', 'package', 'id', 'route', 'name_',
  'key', 'tourId', 'target', 'heroTag', 'mime', 'extension', 'fileName', 'suggestedName',
};

typedef Finding = ({String file, int line, String text});

void main() {
  test('desktop screens read their text from the ARB files', () {
    final only = Platform.environment['DESK_L10N_LINT'];
    final findings = <Finding>[];
    final emptyPending = <String>[];
    for (final file in _dartFiles()) {
      final rel = file.path.substring(_root.length + 1);
      if (_skipped.any((s) => s.endsWith('/') ? rel.startsWith(s) : rel == s)) continue;
      if (only != null && !file.path.startsWith(only)) continue;
      final found = scanDartSource(file.readAsStringSync(), rel);
      final pending = _pending.contains(rel);
      if (pending && only == null) {
        if (found.isEmpty) emptyPending.add(rel);
        continue;
      }
      findings.addAll(found);
    }
    final report = StringBuffer();
    for (final f in findings) {
      report.writeln('$_root/${f.file}:${f.line}  ${f.text}');
    }
    if (findings.isNotEmpty) {
      final byFile = <String, int>{};
      for (final f in findings) {
        byFile[f.file] = (byFile[f.file] ?? 0) + 1;
      }
      report.writeln('\n${findings.length} literals in ${byFile.length} files:');
      for (final e in (byFile.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))) {
        report.writeln('  ${e.value.toString().padLeft(4)}  ${e.key}');
      }
    }
    expect(emptyPending, isEmpty, reason: 'clean now: remove from _pending: ${emptyPending.join(', ')}');
    expect(findings, isEmpty, reason: 'hard-coded text (move it to lib/l10n/desk/, or end the line with // l10n-ok):\n$report');
  });

  test('the lexer finds prose and leaves technical strings', () {
    final f = scanDartSource(r"""
import 'package:x/y.dart';
const a = 'Send';
final b = Text('Wallet $name is ready');
logWarn('desk', 'send ended with $e');
final c = 'wallet_id';
final d = json['createdAt'];
final e = 'EPIC'; final g = 'https://epic.tech/x';
final h = 'Not a file'; // l10n-ok
final i = Key('Some key');
final j = '${a.b} ${c}';
final k = '''
Multi line text
''';
/* 'Not code' */ // 'Not code either'
final m = '中文';
""", 'x.dart');
    expect([for (final x in f) x.text], ['Send', r'Wallet {} is ready', '\nMulti line text\n']);
  });
}

Iterable<File> _dartFiles() => Directory(_root)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList()
  ..sort((a, b) => a.path.compareTo(b.path));

/// Whether [text] (a literal with its interpolations as `{}`) reads like words for a person.
bool looksLikeProse(String text) {
  final t = text.replaceAll('{}', ' ').trim();
  if (t.isEmpty) return false;
  if (RegExp(r'^[a-z]+://').hasMatch(t) || t.startsWith('/') || t.startsWith('package:')) return false;
  final words = RegExp(r'[A-Za-z][A-Za-z’\x27]+').allMatches(t).map((m) => m[0]!).toList();
  if (words.isEmpty) return false;
  final spaced = RegExp(r'[A-Za-z]{2,}[,.;:!?’)]*\s+\(?[A-Za-z0-9]').hasMatch(t);
  if (spaced) return true;
  // One word: a capitalised word (Send, Cancel) is text; lowercase, ALLCAPS, camelCase,
  // snake_case and dotted names are identifiers.
  if (t.contains(RegExp(r'[_=/\\<>{}\[\]#@$|]')) || RegExp(r'^\w+\.\w').hasMatch(t)) return false;
  return RegExp(r'^[A-Z][a-z’]+(?:[ -][A-Za-z][a-z’]*)*[.!?:…]*$').hasMatch(t);
}

/// The prose literals in a Dart [source], with their lines.
List<Finding> scanDartSource(String source, String file) {
  final out = <Finding>[];
  final lines = source.split('\n');
  var i = 0;
  var line = 1;
  // The call or named argument each open `(` or `[`/`{` belongs to.
  final stack = <String>[];
  var lastIdent = '';
  var pendingName = '';

  bool technical() =>
      stack.any((c) => _technicalCalls.contains(c) || (c.startsWith('=') && _technicalNames.contains(c.substring(1)))) ||
      _technicalNames.contains(pendingName);

  String peek(int n) => i + n < source.length ? source[i + n] : '';

  // Reads a string literal starting at [i] (at its quote, or its `r`); returns its text.
  String readString() {
    var raw = false;
    if (source[i] == 'r') {
      raw = true;
      i++;
    }
    final q = source[i];
    final triple = peek(1) == q && peek(2) == q;
    final close = triple ? '$q$q$q' : q;
    i += triple ? 3 : 1;
    final text = StringBuffer();
    while (i < source.length) {
      if (source.startsWith(close, i)) {
        i += close.length;
        return text.toString();
      }
      final c = source[i];
      if (c == '\n') line++;
      if (!raw && c == '\\') {
        text.write(peek(1) == 'n' ? '\n' : peek(1));
        i += 2;
        continue;
      }
      if (!raw && c == r'$') {
        if (peek(1) == '{') {
          i += 2;
          var depth = 1;
          while (i < source.length && depth > 0) {
            final d = source[i];
            if (d == '{') depth++;
            if (d == '}') depth--;
            if (d == '\'' || d == '"') {
              readString();
              continue;
            }
            if (d == '\n') line++;
            i++;
          }
        } else {
          i++;
          while (i < source.length && RegExp(r'\w').hasMatch(source[i])) {
            i++;
          }
        }
        text.write('{}');
        continue;
      }
      text.write(c);
      i++;
    }
    return text.toString();
  }

  var directive = false;
  while (i < source.length) {
    final c = source[i];
    if (c == '\n') {
      line++;
      directive = false;
      i++;
      continue;
    }
    if (c == '/' && peek(1) == '/') {
      while (i < source.length && source[i] != '\n') {
        i++;
      }
      continue;
    }
    if (c == '/' && peek(1) == '*') {
      final end = source.indexOf('*/', i + 2);
      final stop = end < 0 ? source.length : end + 2;
      line += '\n'.allMatches(source.substring(i, stop)).length;
      i = stop;
      continue;
    }
    if (c == '\'' || c == '"' || (c == 'r' && (peek(1) == '\'' || peek(1) == '"') && !RegExp(r'\w').hasMatch(i > 0 ? source[i - 1] : ' '))) {
      final start = line;
      final text = readString();
      final marked = lines[start - 1].contains('// l10n-ok');
      if (!directive && !marked && !technical() && looksLikeProse(text)) {
        out.add((file: file, line: start, text: text));
      }
      pendingName = '';
      continue;
    }
    if (RegExp(r'[A-Za-z_$]').hasMatch(c)) {
      final m = RegExp(r'[A-Za-z_$][\w$]*').matchAsPrefix(source, i)!;
      final word = m[0]!;
      if (word == 'import' || word == 'export' || word == 'part' || word == 'library') {
        final before = source.lastIndexOf('\n', i > 0 ? i - 1 : 0);
        if (source.substring(before + 1, i).trim().isEmpty) directive = true;
      }
      lastIdent = word;
      i = m.end;
      // `name:` starts a named argument.
      final rest = RegExp(r'\s*:(?!:)').matchAsPrefix(source, i);
      if (rest != null && !source.startsWith('?', i)) pendingName = word;
      continue;
    }
    if (c == '@') {
      // Annotations: skip `@name(...)` arguments by treating them as technical calls.
      final m = RegExp(r'@[\w.]+').matchAsPrefix(source, i);
      if (m != null) {
        lastIdent = 'assert';
        i = m.end;
        continue;
      }
    }
    if (c == '(' || c == '[' || c == '{') {
      stack.add(c == '(' ? lastIdent : (pendingName.isEmpty ? '' : '=$pendingName'));
      lastIdent = '';
      pendingName = '';
      i++;
      continue;
    }
    if (c == ')' || c == ']' || c == '}') {
      if (stack.isNotEmpty) stack.removeLast();
      lastIdent = '';
      pendingName = '';
      i++;
      continue;
    }
    if (c == ',' || c == ';') pendingName = '';
    if (!RegExp(r'\s').hasMatch(c)) lastIdent = c == '.' ? lastIdent : '';
    i++;
  }
  return out;
}
