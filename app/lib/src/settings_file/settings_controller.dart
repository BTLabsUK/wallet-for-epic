// SPDX-License-Identifier: Apache-2.0
/// Keeps the app and `settings.toml` in step, both ways (docs/settings-file.md): writes the
/// default copy on the first start (nothing is ever merged into an existing file), writes
/// every change the app makes at once (a per-key merge with hand edits made meanwhile), and on
/// the desktop reloads the file live when it is edited. A broken file is never rewritten
/// unless the app must write, and then it is saved aside first.
library;

import 'dart:async';

import '../log.dart';
import 'host_settings.dart';
import 'settings_backend.dart';
import 'settings_layout.dart';
import 'settings_notice.dart';
import 'toml_edit.dart';

class SettingsFileController {
  SettingsFileController._(this.backend, this.shippedText, this.shipped, this._publishGlobal, this._clock)
    : _settings = shipped;

  /// Opens the settings: on the first start writes [shippedText] (the default copy) as it is
  /// (a file backend), then reads; a key the file lacks reads as the default copy's. [config]
  /// is `app-config.toml`, read-only. With [watch], follows
  /// edits of the file ([debounce] after the last change). With [publishGlobal], keeps the
  /// process-wide [hostSettings] current. Throws [StateError] when [shippedText] itself is not
  /// a complete, good file.
  static Future<SettingsFileController> open({
    required SettingsBackend backend,
    required String shippedText,
    required AppConfig config,
    bool watch = false,
    bool publishGlobal = false,
    Duration debounce = const Duration(milliseconds: 500),
    DateTime Function() clock = DateTime.now,
  }) async {
    final shipped = HostSettings.fromText(shippedText, config: config);
    final c = SettingsFileController._(backend, shippedText, shipped, publishGlobal, clock);
    if (publishGlobal) {
      hostSettings = shipped;
      shippedHostSettings = shipped;
    }
    await c._queued(c._open);
    if (watch) {
      c._watch = backend.changes()?.listen((_) {
        c._debounce?.cancel();
        c._debounce = Timer(debounce, () => unawaited(c.reload()));
      });
    }
    return c;
  }

  final SettingsBackend backend;
  final String shippedText;

  /// The default copy's settings: "Reset to defaults" takes these.
  final HostSettings shipped;

  final bool _publishGlobal;
  final DateTime Function() _clock;

  HostSettings _settings;

  /// The last good text read or written: the base of the per-key merge. Null while there is
  /// no stored text (the web before its first change, or a file that could not be read).
  String? _base;

  /// A broken text already reported, so the same text is not reported again.
  String? _broken;

  Set<ValueIssue> _issuesShown = {};
  final Set<String> _unknownShown = {};
  final List<SettingsNotice> _notices = [];
  final _noticeCtl = StreamController<SettingsNotice>.broadcast(sync: true);
  final _changeCtl = StreamController<SettingsChange>.broadcast(sync: true);
  final _useCtl = StreamController<UseChange>.broadcast(sync: true);
  StreamSubscription<void>? _watch;
  Timer? _debounce;
  Future<void> _queue = Future.value();
  bool _closed = false;

  /// The settings in use.
  HostSettings get settings => _settings;

  /// Every notice of this run, oldest first.
  List<SettingsNotice> get notices => List.unmodifiable(_notices);

  Stream<SettingsNotice> get noticeStream => _noticeCtl.stream;

  /// Every change of the settings in use, from the app or the file.
  Stream<SettingsChange> get changes => _changeCtl.stream;

  /// Changes of the node in use (reconnect) and the Epicbox server in use (every wallet's
  /// address names the new server: the relay-change notice, and every open wallet's listener
  /// restarts): the first entry of either list, from the app or a hand edit.
  Stream<UseChange> get useChanges => _useCtl.stream;

  /// Sets one key; see [setAll].
  Future<void> set(String path, Object value) => setAll({path: value});

  /// Writes the app's changes to the file at once. [values] maps keys (`node.servers`) to
  /// values: bools and text lists. Throws [ArgumentError] for an unknown key
  /// or a bad value. A key the file changed since it was last read keeps the file's value
  /// (a conflict notice says so).
  Future<void> setAll(Map<String, Object> values) {
    final checked = {for (final e in values.entries) e.key: checkAppValue(e.key, e.value)};
    return _queued(() => _write(checked));
  }

  /// Reads the file now and applies a hand edit (the watcher calls this).
  Future<void> reload() => _queued(_reload);

  Future<void> close() async {
    _closed = true;
    _debounce?.cancel();
    await _watch?.cancel();
    await _queue;
    await _noticeCtl.close();
    await _changeCtl.close();
    await _useCtl.close();
  }

  Future<void> _queued(Future<void> Function() body) {
    final next = _queue.then((_) async {
      if (!_closed) await body();
    });
    _queue = next.catchError((Object e, StackTrace s) => logError('settings', e, s));
    return next;
  }

  // --- start ---------------------------------------------------------------------------------

  Future<void> _open() async {
    String? text;
    try {
      text = await backend.locked(() async {
        final t = await backend.read();
        if (t == null) {
          if (!backend.writesShippedFirst) return null;
          await backend.write(shippedText);
          logInfo('settings', '${backend.fileName} written from the default copy');
          return shippedText;
        }
        return t;
      });
    } on Object catch (e) {
      logWarn('settings', '${backend.fileName} could not be read: $e');
      _notice(SettingsNotice(SettingsNoticeKind.readFailed, file: backend.fileName));
      return;
    }
    if (text != null) _take(text);
  }

  // --- file → app ---------------------------------------------------------------------------

  Future<void> _reload() async {
    String? text;
    try {
      text = await backend.read();
    } on Object catch (e) {
      logWarn('settings', '${backend.fileName} could not be read: $e');
      return;
    }
    if (text == null) {
      if (!backend.writesShippedFirst || _base == null) return;
      await _recreate();
      return;
    }
    if (text == _base || text == _broken) return;
    _take(text);
  }

  Future<void> _recreate() async {
    try {
      final written = await backend.locked(() async {
        if (await backend.read() != null) return null;
        final t = _goodText();
        await backend.write(t);
        return t;
      });
      if (written == null) {
        // Another process wrote it meanwhile: read what it wrote.
        await _reload();
        return;
      }
      _base = written;
      logInfo('settings', '${backend.fileName} was missing, written again');
      _notice(SettingsNotice(SettingsNoticeKind.recreated, file: backend.fileName));
    } on Object catch (e) {
      logWarn('settings', '${backend.fileName} could not be written: $e');
      _notice(SettingsNotice(SettingsNoticeKind.writeFailed, file: backend.fileName));
    }
  }

  /// Uses a text read from the backend or just written. False when it is broken.
  bool _take(String text, {Set<String> appKeys = const {}}) {
    final SettingsRead read;
    try {
      read = readSettings(text, shipped: shipped, lastGood: _base == null ? null : _settings);
    } on SettingsSyntaxError catch (e) {
      if (_broken != text) {
        logWarn('settings', '$e');
        _notice(SettingsNotice(SettingsNoticeKind.syntaxError, file: backend.fileName, line: e.line));
      }
      _broken = text;
      return false;
    }
    _broken = null;
    _base = text;
    final issues = read.issues.toSet();
    for (final i in read.issues) {
      if (_issuesShown.contains(i)) continue;
      logWarn('settings', '${backend.fileName}, $i');
      _notice(
        SettingsNotice(SettingsNoticeKind.badValue, file: backend.fileName, line: i.line ?? 1, key: i.key, problem: i.problem),
      );
    }
    _issuesShown = issues;
    for (final u in read.unknown) {
      if (!_unknownShown.add(u.key)) continue;
      logWarn('settings', '${backend.fileName}, $u');
      _notice(SettingsNotice(SettingsNoticeKind.unknownKey, file: backend.fileName, line: u.line ?? 1, key: u.key));
    }
    _use(read.settings, appKeys);
    return true;
  }

  void _use(HostSettings next, Set<String> appKeys) {
    final before = _settings;
    final keys = {
      for (final k in settingsKeys)
        if (!deepEquals(before.value(k.path), next.value(k.path))) k.path,
    };
    if (keys.isEmpty) return;
    _settings = next;
    if (_publishGlobal) hostSettings = next;
    final applied = appKeys.intersection(keys);
    _changeCtl.add(SettingsChange(before, next, keys, appKeys: applied));
    // The one in use is the first of its list: a pick, a reorder or a removal can change it.
    final uses = [
      (UseChange.node, before.nodeUse, next.nodeUse, 'node.servers'),
      (UseChange.epicbox, before.epicboxUse, next.epicboxUse, 'epicbox.servers'),
    ];
    for (final (key, from, to, list) in uses) {
      if (from == to) continue;
      final change = UseChange(key, from, to, fromApp: applied.contains(list));
      logInfo('settings', '$change');
      _useCtl.add(change);
    }
  }

  // --- app → file ---------------------------------------------------------------------------

  Future<void> _write(Map<String, Object> values) async {
    final wanted = {
      for (final e in values.entries)
        if (!deepEquals(_settings.value(e.key), e.value)) e.key: e.value,
    };
    if (wanted.isEmpty) return;
    final notes = <SettingsNotice>[];
    final ({String text, Set<String> applied}) result;
    try {
      result = await backend.locked(() async {
        final text = await backend.read();
        String working;
        Map<String, dynamic>? fileDoc;
        if (text == null) {
          if (backend.writesShippedFirst && _base != null) {
            notes.add(SettingsNotice(SettingsNoticeKind.recreated, file: backend.fileName));
          }
          working = _goodText();
        } else {
          try {
            fileDoc = parseSettingsToml(text);
            working = text;
          } on SettingsSyntaxError {
            final name = await backend.saveBroken(text, _clock());
            logWarn('settings', '${backend.fileName} had errors, saved as $name');
            notes.add(SettingsNotice(SettingsNoticeKind.brokenSaved, file: backend.fileName, backup: name));
            working = _goodText();
          }
        }
        final base = _base;
        final baseDoc = base == null || fileDoc == null || text == base ? null : parseSettingsToml(base);
        final editor = TomlEditor(working, shipped: shippedText);
        final applied = <String>{};
        for (final e in wanted.entries) {
          if (baseDoc != null) {
            final fileValue = rawValue(fileDoc!, e.key);
            if (!deepEquals(fileValue, rawValue(baseDoc, e.key))) {
              // A hand edit changed this key too: the file's value stays.
              if (!_sameValue(e.key, fileValue, e.value)) {
                logWarn('settings', '${backend.fileName} edited at the same time: ${e.key} kept');
                notes.add(SettingsNotice(SettingsNoticeKind.conflict, file: backend.fileName, key: e.key));
              }
              continue;
            }
          }
          _edit(editor, e.key, e.value);
          applied.add(e.key);
        }
        if (editor.text != text) await backend.write(editor.text);
        return (text: editor.text, applied: applied);
      });
    } on Object catch (e) {
      logWarn('settings', '${backend.fileName} could not be written: $e');
      _notice(SettingsNotice(SettingsNoticeKind.writeFailed, file: backend.fileName));
      _use(_settings.withValues(wanted), wanted.keys.toSet());
      return;
    }
    _broken = null;
    _take(result.text, appKeys: result.applied);
    notes.forEach(_notice);
  }

  bool _sameValue(String path, Object? raw, Object value) {
    if (raw == null) return false;
    final c = checkValue(settingsKeysByPath[path]!.kind, raw);
    return c.ok && deepEquals(c.value, value);
  }

  /// Sets [path] in [editor]'s text to [value] (the model's shape).
  void _edit(TomlEditor editor, String path, Object value) {
    final kind = settingsKeysByPath[path]!.kind;
    if (kind is TablesKind) {
      final raw = rawValue(parseSettingsToml(editor.text), path);
      final current = raw is List ? [for (final e in raw.whereType<Map>()) Map<String, Object?>.from(e)] : null;
      editor.setTables(path, kind, [for (final e in value as List) Map<String, Object?>.from(e as Map)], current: current);
    } else {
      editor.setValue(path, value);
    }
  }

  /// A good text holding the settings in use: the last good text (else the shipped one) with
  /// every key that differs from them set.
  String _goodText() {
    final start = _base ?? shippedText;
    final from = readSettings(start, shipped: shipped).settings;
    final editor = TomlEditor(start, shipped: shippedText);
    for (final k in settingsKeys) {
      if (!deepEquals(from.value(k.path), _settings.value(k.path))) _edit(editor, k.path, _settings.value(k.path));
    }
    return editor.text;
  }

  void _notice(SettingsNotice n) {
    _notices.add(n);
    if (!_noticeCtl.isClosed) _noticeCtl.add(n);
  }
}
