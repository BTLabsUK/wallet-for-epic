// SPDX-License-Identifier: Apache-2.0
/// Where each statement of a TOML text sits, line by line: tables, arrays of tables and
/// keys with their values (multi-line arrays, inline tables and strings with `#` or brackets
/// in them included). The values themselves come from `package:toml`; this scan only says
/// where they are, so the editor can replace a key's lines and keep everything else.
library;

/// What a statement is.
enum TomlStmtKind { table, arrayTable, keyValue }

/// One statement: a `[table]` or `[[array]]` header, or a `key = value` with every line
/// its value spans. Lines are 0-based indexes into [TomlScan.lines].
class TomlStmt {
  TomlStmt({
    required this.kind,
    required this.path,
    required this.start,
    required this.end,
    this.prefix = '',
    this.comment,
    this.section = -1,
  });

  final TomlStmtKind kind;

  /// A header's table path; a key's full path from the document root, where an array of
  /// tables' entry is `#<index>` (`node.servers.#2.url`).
  final List<String> path;

  final int start;
  final int end;

  /// A key's line up to its value: indentation, the key as written, `=` and the spaces.
  final String prefix;

  /// A one-line key's trailing comment (`# …`), kept when the value is replaced.
  final String? comment;

  /// The index in [TomlScan.stmts] of the header this key sits under, -1 for the root.
  final int section;

  String get dotted => path.join('.');
}

/// A scanned TOML text. It never throws: text the scan cannot follow ends the statement at
/// the end of its line, and the TOML parser reports the error.
class TomlScan {
  TomlScan._(this.lines, this.eol, this.finalNewline, this.stmts);

  factory TomlScan(String text) {
    final eol = text.contains('\r\n') ? '\r\n' : '\n';
    final finalNewline = text.endsWith('\n');
    final body = finalNewline ? text.substring(0, text.length - (text.endsWith('\r\n') ? 2 : 1)) : text;
    final lines = text.isEmpty ? <String>[] : body.split('\n').map(_chompCr).toList();
    return TomlScan._(lines, eol, finalNewline, _Scanner(lines.join('\n')).run());
  }

  final List<String> lines;
  final String eol;
  final bool finalNewline;
  final List<TomlStmt> stmts;

  /// Lines back to text, with the original line ending.
  static String join(List<String> lines, String eol, {bool finalNewline = true}) {
    if (lines.isEmpty) return '';
    return lines.join(eol) + (finalNewline ? eol : '');
  }

  /// The key statement at [path] (`node.use`, `node.servers.#0.url`), or null.
  TomlStmt? key(List<String> path) {
    for (final s in stmts) {
      if (s.kind == TomlStmtKind.keyValue && _samePath(s.path, path)) return s;
    }
    return null;
  }

  /// The 1-based line of [path], or of the nearest enclosing key or header that has one.
  int? lineOf(List<String> path) {
    for (var n = path.length; n > 0; n--) {
      final head = path.sublist(0, n);
      final k = key(head);
      if (k != null) return k.start + 1;
      final h = header(head);
      if (h != null) return h.start + 1;
    }
    return null;
  }

  /// The header statement whose table is [path]: `[node]`, or the `#i` entry of `[[node.servers]]`.
  TomlStmt? header(List<String> path) {
    if (path.isNotEmpty && path.last.startsWith('#')) {
      final index = int.tryParse(path.last.substring(1));
      final blocks = arrayBlocks(path.sublist(0, path.length - 1));
      if (index == null || index >= blocks.length) return null;
      return stmts[blocks[index]];
    }
    for (final s in stmts) {
      if (s.kind == TomlStmtKind.table && _samePath(s.path, path)) return s;
    }
    return null;
  }

  /// The indexes in [stmts] of every `[[path]]` header, in order.
  List<int> arrayBlocks(List<String> path) => [
    for (var i = 0; i < stmts.length; i++)
      if (stmts[i].kind == TomlStmtKind.arrayTable && _samePath(stmts[i].path, path)) i,
  ];

  /// The index in [stmts] of the `[path]` header, or -1.
  int tableIndex(List<String> path) {
    for (var i = 0; i < stmts.length; i++) {
      if (stmts[i].kind == TomlStmtKind.table && _samePath(stmts[i].path, path)) return i;
    }
    return -1;
  }

  /// The keys directly under the header at [section] (-1: the root), in order.
  List<TomlStmt> keysOf(int section) => [
    for (final s in stmts)
      if (s.kind == TomlStmtKind.keyValue && s.section == section) s,
  ];

  /// The index in [stmts] of the header after [section], or null at the end.
  int? nextHeader(int section) {
    for (var i = section + 1; i < stmts.length; i++) {
      if (stmts[i].kind != TomlStmtKind.keyValue) return i;
    }
    return null;
  }

  /// The first line of the comments right above [line] (no blank line between), or [line].
  int attachedStart(int line) {
    var i = line;
    while (i > 0 && _isComment(lines[i - 1])) {
      i--;
    }
    return i;
  }

  /// The comment lines right above [stmt].
  List<String> attachedComments(TomlStmt stmt) => lines.sublist(attachedStart(stmt.start), stmt.start);

  /// The last line of the section that starts at header [section], before the next header's
  /// attached comments and the blank lines before them; -1 when the root has no lines.
  int sectionEnd(int section) {
    final next = nextHeader(section);
    var end = next == null ? lines.length - 1 : attachedStart(stmts[next].start) - 1;
    final floor = section < 0 ? -1 : stmts[section].start;
    while (end > floor && lines[end].trim().isEmpty) {
      end--;
    }
    return end;
  }

  /// The 1-based line where [path] is written a second time, for a redefinition error.
  int? duplicateLine() {
    final seen = <String>{};
    for (final s in stmts) {
      if (s.kind == TomlStmtKind.arrayTable) continue;
      final k = s.dotted;
      if (!seen.add('${s.kind.name}:$k')) return s.start + 1;
      if (s.kind == TomlStmtKind.keyValue && seen.contains('table:$k')) return s.start + 1;
      if (s.kind == TomlStmtKind.table && seen.contains('keyValue:$k')) return s.start + 1;
    }
    return null;
  }
}

bool _samePath(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _isComment(String line) => line.trimLeft().startsWith('#');

String _chompCr(String line) => line.endsWith('\r') ? line.substring(0, line.length - 1) : line;

class _Scanner {
  _Scanner(this.text) {
    _lineStarts.add(0);
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) _lineStarts.add(i + 1);
    }
  }

  final String text;
  final List<int> _lineStarts = [];
  int pos = 0;
  final List<TomlStmt> out = [];
  int _section = -1;
  List<String> _sectionPath = const [];
  final Map<String, int> _arrayCounts = {};

  int lineAt(int offset) {
    var lo = 0, hi = _lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  bool get atEnd => pos >= text.length;
  String get ch => text[pos];

  List<TomlStmt> run() {
    while (!atEnd) {
      _skipBlank();
      if (atEnd) break;
      if (ch == '\n') {
        pos++;
      } else if (ch == '#') {
        _toEol();
      } else if (ch == '[') {
        _header();
      } else {
        _keyValue();
      }
    }
    return out;
  }

  void _skipBlank() {
    while (!atEnd && (ch == ' ' || ch == '\t')) {
      pos++;
    }
  }

  void _toEol() {
    while (!atEnd && ch != '\n') {
      pos++;
    }
  }

  void _header() {
    final startLine = lineAt(pos);
    final array = text.startsWith('[[', pos);
    pos += array ? 2 : 1;
    final path = _keyPath(array ? ']]' : ']');
    if (text.startsWith(array ? ']]' : ']', pos)) pos += array ? 2 : 1;
    _toEol();
    final kind = array ? TomlStmtKind.arrayTable : TomlStmtKind.table;
    out.add(TomlStmt(kind: kind, path: path, start: startLine, end: startLine));
    _section = out.length - 1;
    if (array) {
      final k = path.join('.');
      final index = _arrayCounts[k] ?? 0;
      _arrayCounts[k] = index + 1;
      _sectionPath = [...path, '#$index'];
    } else {
      _sectionPath = path;
    }
  }

  void _keyValue() {
    final lineStart = _lineStarts[lineAt(pos)];
    final startLine = lineAt(pos);
    final key = _keyPath('=');
    _skipBlank();
    if (atEnd || ch != '=') {
      // Not a key: the parser reports it.
      _toEol();
      return;
    }
    pos++;
    _skipBlank();
    final prefix = text.substring(lineStart, pos);
    _value();
    final valueEndLine = lineAt(pos);
    _skipBlank();
    String? comment;
    if (!atEnd && ch == '#') {
      final c0 = pos;
      _toEol();
      if (valueEndLine == startLine) comment = text.substring(c0, pos).trimRight();
    } else {
      _toEol();
    }
    out.add(
      TomlStmt(
        kind: TomlStmtKind.keyValue,
        path: [..._sectionPath, ...key],
        start: startLine,
        end: lineAt(atEnd ? text.length : pos),
        prefix: prefix,
        comment: comment,
        section: _section,
      ),
    );
  }

  /// A dotted key up to [stop] (`=` or `]`), bare and quoted parts.
  List<String> _keyPath(String stop) {
    final parts = <String>[];
    while (!atEnd) {
      _skipBlank();
      if (atEnd || ch == '\n' || text.startsWith(stop, pos)) break;
      if (ch == '"') {
        parts.add(_basicString());
      } else if (ch == "'") {
        parts.add(_literalString());
      } else {
        final s = pos;
        while (!atEnd && RegExp(r'[A-Za-z0-9_\-]').hasMatch(ch)) {
          pos++;
        }
        if (pos == s) {
          // Not a key character: let the parser say what is wrong.
          pos++;
          continue;
        }
        parts.add(text.substring(s, pos));
      }
      _skipBlank();
      if (!atEnd && ch == '.') pos++;
    }
    return parts;
  }

  String _basicString() {
    pos++; // "
    final b = StringBuffer();
    while (!atEnd && ch != '"' && ch != '\n') {
      if (ch == r'\' && pos + 1 < text.length) {
        final n = text[pos + 1];
        b.write(switch (n) {
          'n' => '\n',
          't' => '\t',
          'r' => '\r',
          'b' => '\b',
          'f' => '\f',
          _ => n,
        });
        pos += 2;
        continue;
      }
      b.write(ch);
      pos++;
    }
    if (!atEnd && ch == '"') pos++;
    return b.toString();
  }

  String _literalString() {
    pos++; // '
    final s = pos;
    while (!atEnd && ch != "'" && ch != '\n') {
      pos++;
    }
    final v = text.substring(s, pos);
    if (!atEnd && ch == "'") pos++;
    return v;
  }

  /// Moves past a value, stopping at the newline (or `#`) that ends it outside brackets.
  void _value() {
    var depth = 0;
    while (!atEnd) {
      final c = ch;
      if (c == '"' || c == "'") {
        _skipString(c);
        continue;
      }
      if (c == '[' || c == '{') {
        depth++;
      } else if (c == ']' || c == '}') {
        if (depth > 0) depth--;
      } else if (c == '#') {
        if (depth == 0) return;
        _toEol();
        continue;
      } else if (c == '\n') {
        if (depth == 0) return;
      }
      pos++;
    }
  }

  void _skipString(String q) {
    final triple = text.startsWith('$q$q$q', pos);
    if (triple) {
      pos += 3;
      while (!atEnd) {
        if (q == '"' && ch == r'\') {
          pos += 2;
          continue;
        }
        if (text.startsWith('$q$q$q', pos)) {
          pos += 3;
          // Up to two quotes of the content may sit right before the closing three.
          var extra = 0;
          while (!atEnd && ch == q && extra < 2) {
            pos++;
            extra++;
          }
          return;
        }
        pos++;
      }
      return;
    }
    pos++;
    while (!atEnd && ch != '\n') {
      if (q == '"' && ch == r'\') {
        pos += 2;
        continue;
      }
      if (ch == q) {
        pos++;
        return;
      }
      pos++;
    }
  }
}
