// SPDX-License-Identifier: Apache-2.0
/// Edits a TOML text in place: replaces a key's lines, adds a missing key after the last key
/// of its table, sets an array of tables block by block. Every line the edit does not need
/// stays as the user wrote it: comments, unknown keys, order, blank lines, line endings.
library;

import 'settings_layout.dart';
import 'toml_scan.dart';

/// A value as TOML text: strings (escaped), ints, bools, lists of those, text tables inline.
/// [multiline] puts a list's items one per line, as the shipped file writes long lists.
String encodeTomlValue(Object? value, {bool multiline = false}) {
  switch (value) {
    case String s:
      return encodeTomlString(s);
    case int i:
      return '$i';
    case bool b:
      return '$b';
    case List l:
      if (l.isEmpty) return '[]';
      if (multiline) return '[\n${l.map((v) => '  ${encodeTomlValue(v)},\n').join()}]';
      return '[${l.map(encodeTomlValue).join(', ')}]';
    case Map m:
      if (m.isEmpty) return '{}';
      return '{ ${m.entries.map((e) => '${encodeTomlKey('${e.key}')} = ${encodeTomlValue(e.value)}').join(', ')} }';
    default:
      throw ArgumentError.value(value, 'value', 'not a settings value');
  }
}

String encodeTomlString(String s) {
  final b = StringBuffer('"');
  for (final r in s.runes) {
    switch (r) {
      case 0x22:
        b.write(r'\"');
      case 0x5C:
        b.write(r'\\');
      case 0x0A:
        b.write(r'\n');
      case 0x0D:
        b.write(r'\r');
      case 0x09:
        b.write(r'\t');
      case 0x08:
        b.write(r'\b');
      case 0x0C:
        b.write(r'\f');
      default:
        if (r < 0x20 || r == 0x7F) {
          b.write('\\u${r.toRadixString(16).padLeft(4, '0').toUpperCase()}');
        } else {
          b.writeCharCode(r);
        }
    }
  }
  b.write('"');
  return b.toString();
}

/// A key bare when it can be, quoted otherwise.
String encodeTomlKey(String k) => RegExp(r'^[A-Za-z0-9_\-]+$').hasMatch(k) ? k : encodeTomlString(k);

/// Longer than this on one line, a new list value is written one item per line.
const int _lineLimit = 100;

/// The working text of one edit session. Each edit rescans, so edits compose.
class TomlEditor {
  TomlEditor(String text, {String? shipped}) : _text = text, _shipped = shipped == null ? null : TomlScan(shipped);

  String _text;
  final TomlScan? _shipped;

  String get text => _text;

  void _apply(TomlScan scan, List<String> lines) {
    _text = TomlScan.join(lines, scan.eol, finalNewline: scan.finalNewline || lines.isNotEmpty);
  }

  /// Sets the plain key [path] (`version`, `node.use`, `import.renamed_epicbox`) to [value].
  /// An existing key keeps its line's start (indentation, spelling) and trailing comment; a
  /// missing one goes after the last key of its table, with the shipped file's comment above
  /// it; a missing table is added at the end, with the shipped file's comments above it.
  void setValue(String path, Object value) {
    final parts = path.split('.');
    final scan = TomlScan(_text);
    final lines = [...scan.lines];
    final existing = scan.key(parts);
    if (existing != null) {
      final wasMultiline = existing.end > existing.start;
      lines.replaceRange(existing.start, existing.end + 1, _keyLines(existing.prefix, value, existing.comment, wasMultiline));
      _apply(scan, lines);
      return;
    }
    final table = parts.sublist(0, parts.length - 1);
    final key = parts.last;
    final shippedKey = _shipped?.key(parts);
    final comments = shippedKey == null ? keyComments[path] ?? const <String>[] : _shipped!.attachedComments(shippedKey);
    final prefix = shippedKey?.prefix ?? '${encodeTomlKey(key)} = ';
    final newLines = _keyLines(prefix, value, null, shippedKey != null && shippedKey.end > shippedKey.start);

    final section = table.isEmpty ? -1 : scan.tableIndex(table);
    if (table.isNotEmpty && section < 0) {
      _appendTable(scan, lines, table, [...comments, ...newLines]);
      return;
    }
    final keys = scan.keysOf(section);
    int at;
    if (keys.isNotEmpty) {
      at = keys.last.end + 1;
    } else if (section >= 0) {
      at = scan.stmts[section].start + 1;
    } else {
      // A root key in a file without one: right before the first table and its comments.
      final first = scan.nextHeader(-1);
      at = first == null ? lines.length : scan.attachedStart(scan.stmts[first].start);
      lines.insertAll(at, [...comments, ...newLines, '']);
      _apply(scan, lines);
      return;
    }
    lines.insertAll(at, [if (comments.isNotEmpty) '', ...comments, ...newLines]);
    _apply(scan, lines);
  }

  /// Removes the plain key [path] with the comments right above it; a table left with no key
  /// goes too, with its comments. Nothing happens when the key is not there.
  void removeValue(String path) {
    final parts = path.split('.');
    final scan = TomlScan(_text);
    final existing = scan.key(parts);
    if (existing == null) return;
    final lines = [...scan.lines];
    final section = existing.section;
    if (section >= 0 && scan.keysOf(section).length == 1) {
      final header = scan.stmts[section];
      final start = scan.attachedStart(header.start);
      final end = scan.sectionEnd(section);
      lines.removeRange(start, end + 1);
      // No blank line left at the top, and no two in a row where the table was.
      while (start < lines.length && lines[start].trim().isEmpty && (start == 0 || lines[start - 1].trim().isEmpty)) {
        lines.removeAt(start);
      }
      while (lines.isNotEmpty && lines.last.trim().isEmpty) {
        lines.removeLast();
      }
      _apply(scan, lines);
      return;
    }
    lines.removeRange(scan.attachedStart(existing.start), existing.end + 1);
    _apply(scan, lines);
  }

  List<String> _keyLines(String prefix, Object value, String? comment, bool multiline) {
    var encoded = encodeTomlValue(value, multiline: multiline && value is List && value.isNotEmpty);
    if (!multiline && value is List && value.isNotEmpty && prefix.length + encoded.length > _lineLimit) {
      encoded = encodeTomlValue(value, multiline: true);
    }
    final out = '$prefix$encoded'.split('\n');
    if (comment != null) out[out.length - 1] = '${out.last} $comment';
    return out;
  }

  void _appendTable(TomlScan scan, List<String> lines, List<String> table, List<String> body) {
    final shippedHeader = _shipped?.header(table);
    final headerComments = shippedHeader == null ? const <String>[] : _shipped!.attachedComments(shippedHeader);
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }
    if (lines.isNotEmpty) lines.add('');
    lines.addAll([...headerComments, '[${table.map(encodeTomlKey).join('.')}]']);
    if (body.isNotEmpty && body.first.trimLeft().startsWith('#')) lines.add('');
    lines.addAll(body);
    _apply(scan, lines);
  }

  /// Sets the array of tables [path] (`node.servers`) to [entries], in that order. A block
  /// whose identity ([kind]'s) is in [entries] keeps its text, comments and unknown keys,
  /// with only the fields that changed rewritten; a block not in [entries] goes; a new entry
  /// is written as a new block. The first block's comments above it describe the list and
  /// stay where the list starts. An empty list is written as `key = []`.
  void setTables(String path, TablesKind kind, List<Map<String, Object?>> entries, {List<Map<String, Object?>>? current}) {
    final parts = path.split('.');
    final table = parts.sublist(0, parts.length - 1);
    var scan = TomlScan(_text);

    // `servers = [...]` written inline: it gives way to blocks (or holds the empty list).
    final inline = scan.key(parts);
    if (inline != null) {
      if (entries.isEmpty) {
        setValue(path, const <Object>[]);
        return;
      }
      final lines = [...scan.lines]..removeRange(inline.start, inline.end + 1);
      _apply(scan, lines);
      scan = TomlScan(_text);
    }

    final blocks = scan.arrayBlocks(parts);
    if (entries.isEmpty) {
      _removeBlocks(scan, blocks);
      setValue(path, const <Object>[]);
      return;
    }

    final ids = [for (final b in blocks) kind.identity(_blockValues(scan, b, current, blocks.indexOf(b)))];
    final used = <int>{};
    final rendered = <List<String>>[];
    for (final e in entries) {
      final id = kind.identity(e);
      var match = -1;
      for (var i = 0; i < ids.length; i++) {
        if (!used.contains(i) && ids[i] == id) {
          match = i;
          break;
        }
      }
      if (match >= 0) {
        used.add(match);
        rendered.add(_editBlock(scan, blocks, match, kind, e, current));
      } else {
        rendered.add(_newBlock(parts, kind, e));
      }
    }

    final lines = [...scan.lines];
    final region = <String>[];
    for (var i = 0; i < rendered.length; i++) {
      if (i > 0) region.add('');
      region.addAll(rendered[i]);
    }

    if (blocks.isEmpty) {
      final section = scan.tableIndex(table);
      if (section < 0) {
        _appendTable(scan, lines, table, const []);
        final again = TomlScan(_text);
        final l2 = [...again.lines, '', ...region];
        _apply(again, l2);
        return;
      }
      final end = scan.sectionEnd(section);
      lines.insertAll(end + 1, ['', ...region]);
      _apply(scan, lines);
      return;
    }

    // Remove the later blocks (bottom up), then put the region where the first block was.
    for (var i = blocks.length - 1; i >= 1; i--) {
      final r = _blockSpan(scan, blocks[i]);
      var from = r.$1;
      while (from > 0 && lines[from - 1].trim().isEmpty) {
        from--;
      }
      lines.removeRange(from, r.$2 + 1);
    }
    final first = scan.stmts[blocks.first];
    lines.replaceRange(first.start, _blockSpan(scan, blocks.first).$2 + 1, region);
    _apply(scan, lines);
  }

  void _removeBlocks(TomlScan scan, List<int> blocks) {
    if (blocks.isEmpty) return;
    final lines = [...scan.lines];
    for (var i = blocks.length - 1; i >= 0; i--) {
      final r = _blockSpan(scan, blocks[i]);
      var from = i == 0 ? scan.stmts[blocks[i]].start : r.$1;
      while (from > 0 && lines[from - 1].trim().isEmpty) {
        from--;
      }
      lines.removeRange(from, r.$2 + 1);
    }
    _apply(scan, lines);
  }

  /// The lines a block owns: its attached comments (not for the list's first block), the
  /// header and its keys, up to the next header's comments.
  (int, int) _blockSpan(TomlScan scan, int header) {
    final s = scan.stmts[header];
    return (scan.attachedStart(s.start), scan.sectionEnd(header));
  }

  Map<String, Object?> _blockValues(TomlScan scan, int header, List<Map<String, Object?>>? current, int index) {
    if (current != null && index < current.length) return current[index];
    // Without parsed values, read the identity fields straight from the scanned text.
    final out = <String, Object?>{};
    for (final k in scan.keysOf(header)) {
      final raw = scan.lines.sublist(k.start, k.end + 1).join('\n').substring(k.prefix.length).trim();
      final v = raw.replaceFirst(RegExp(r'\s#.*$'), '');
      if (v.startsWith('"') && v.endsWith('"') && v.length >= 2) {
        out[k.path.last] = v.substring(1, v.length - 1);
      } else if (int.tryParse(v) != null) {
        out[k.path.last] = int.parse(v);
      }
    }
    return out;
  }

  List<String> _editBlock(
    TomlScan scan,
    List<int> blocks,
    int i,
    TablesKind kind,
    Map<String, Object?> e,
    List<Map<String, Object?>>? current,
  ) {
    final header = blocks[i];
    final span = _blockSpan(scan, header);
    final s = scan.stmts[header];
    final ownStart = i == 0 ? s.start : span.$1;
    var block = scan.lines.sublist(ownStart, span.$2 + 1);
    final have = current != null && i < current.length ? current[i] : _blockValues(scan, header, null, i);

    // Edit within the block as its own small document, so the scan sees only its keys.
    final headerAt = s.start - ownStart;
    final sub = TomlEditor(TomlScan.join(block.sublist(headerAt), '\n'));
    final path = '${s.dotted}.#0';
    for (final f in e.entries) {
      if (f.value == null) continue;
      if (_deepEquals(have[f.key], f.value) && _hasKey(sub, path, f.key)) continue;
      if (!_hasKey(sub, path, f.key)) {
        final field = kind.field(f.key);
        if (field != null && field.byDefault == f.value) continue;
      }
      sub._setInBlock(path, f.key, f.value!);
    }
    for (final f in kind.fields) {
      if (e.containsKey(f.name) && e[f.name] != null) continue;
      if (!_hasKey(sub, path, f.name)) continue;
      if (f.byDefault != null && _deepEquals(have[f.name], f.byDefault)) continue;
      sub._removeInBlock(path, f.name);
    }
    final edited = TomlScan(sub.text).lines;
    block = [...block.sublist(0, headerAt), ...edited];
    return block;
  }

  static bool _hasKey(TomlEditor sub, String blockPath, String key) =>
      TomlScan(sub.text).key([...blockPath.split('.'), key]) != null;

  void _setInBlock(String blockPath, String key, Object value) {
    final scan = TomlScan(_text);
    final lines = [...scan.lines];
    final k = scan.key([...blockPath.split('.'), key]);
    if (k != null) {
      lines.replaceRange(k.start, k.end + 1, _keyLines(k.prefix, value, k.comment, k.end > k.start));
    } else {
      final keys = scan.keysOf(0);
      final at = keys.isEmpty ? 1 : keys.last.end + 1;
      lines.insertAll(at, _keyLines('${encodeTomlKey(key)} = ', value, null, false));
    }
    _apply(scan, lines);
  }

  void _removeInBlock(String blockPath, String key) {
    final scan = TomlScan(_text);
    final k = scan.key([...blockPath.split('.'), key]);
    if (k == null) return;
    final lines = [...scan.lines]..removeRange(k.start, k.end + 1);
    _apply(scan, lines);
  }

  List<String> _newBlock(List<String> parts, TablesKind kind, Map<String, Object?> e) {
    final comments = _shippedBlockComments(parts, kind, e);
    final out = <String>[...comments, '[[${parts.map(encodeTomlKey).join('.')}]]'];
    final names = [
      for (final f in kind.fields) f.name,
      for (final k in e.keys)
        if (kind.field(k) == null) k,
    ];
    for (final name in names) {
      final v = e[name];
      if (v == null) continue;
      if (kind.omitDefaults.contains(name) && kind.field(name)?.byDefault == v) continue;
      out.addAll(_keyLines('${encodeTomlKey(name)} = ', v, null, false));
    }
    return out;
  }

  /// The shipped file's comments above the block with this identity, unless it is the
  /// shipped list's first (whose comments describe the list).
  List<String> _shippedBlockComments(List<String> parts, TablesKind kind, Map<String, Object?> e) {
    final shipped = _shipped;
    if (shipped == null) return const [];
    final blocks = shipped.arrayBlocks(parts);
    final id = kind.identity(e);
    for (var i = 1; i < blocks.length; i++) {
      final values = _blockValues(shipped, blocks[i], null, i);
      if (kind.identity(values) == id) return shipped.attachedComments(shipped.stmts[blocks[i]]);
    }
    return const [];
  }
}

bool _deepEquals(Object? a, Object? b) => deepEquals(a, b);

/// Structural equality of settings values (lists, maps, scalars).
bool deepEquals(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !deepEquals(a[k], b[k])) return false;
    }
    return true;
  }
  return a == b;
}
