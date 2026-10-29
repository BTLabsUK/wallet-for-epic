// SPDX-License-Identifier: Apache-2.0
/// Bringing a user's file up to a newer shipped `version`: what the shipped file has and the
/// user's lacks is added; nothing the user has is changed, reordered or removed.
library;

import 'host_settings.dart';
import 'settings_layout.dart';
import 'toml_edit.dart';

/// [fileText] brought up to [shippedText]'s version, or null when it already is (or is newer).
/// Adds every missing key and table with the shipped value and comments, appends each shipped
/// server (node, Epicbox, onion route) whose identity the file's list lacks and its `removed`
/// list does not name, then sets `version`. Plain lists (`pairing.servers`, …) are values: a
/// list the file has is kept as it is. Throws [SettingsSyntaxError] for a broken file.
String? mergeShippedVersion(String fileText, String shippedText) {
  final file = parseSettingsToml(fileText);
  final shipped = parseSettingsToml(shippedText);
  final shippedVersion = shipped['version'];
  final fileVersion = file['version'];
  if (shippedVersion is! int) return null;
  if (fileVersion is int && fileVersion >= shippedVersion) return null;

  final editor = TomlEditor(fileText, shipped: shippedText);
  for (final top in shipped.entries) {
    if (top.key == 'version') continue;
    final value = top.value;
    if (value is Map<String, dynamic> && !_isInlineValue(top.key)) {
      for (final k in value.entries) {
        _mergeKey(editor, file, '${top.key}.${k.key}', k.value);
      }
    } else {
      _mergeKey(editor, file, top.key, value);
    }
  }
  editor.setValue('version', shippedVersion);
  return editor.text;
}

bool _isInlineValue(String path) => settingsKeysByPath[path]?.kind is TextMapKind;

void _mergeKey(TomlEditor editor, Map<String, dynamic> file, String path, Object? shippedValue) {
  if (shippedValue == null) return;
  final have = rawValue(file, path);
  final kind = settingsKeysByPath[path]?.kind;
  if (kind is TablesKind && shippedValue is List) {
    final shippedEntries = [for (final e in shippedValue.whereType<Map>()) Map<String, Object?>.from(e)];
    if (have == null) {
      editor.setTables(path, kind, shippedEntries);
      return;
    }
    if (have is! List) return;
    final current = [for (final e in have.whereType<Map>()) Map<String, Object?>.from(e)];
    final ids = {for (final e in current) kind.identity(e)};
    final removed = rawValue(file, '${path.split('.').first}.removed');
    final out = [
      for (final e in shippedEntries)
        if (!ids.contains(kind.identity(e)) && !isRemovedServer(path, e, removed is List ? removed : const [])) e,
    ];
    if (out.isEmpty) return;
    editor.setTables(path, kind, [...current, ...out], current: current);
    return;
  }
  if (have == null) editor.setValue(path, shippedValue);
}

/// Whether [removed] (a `removed` list: `host:port`, or `host` for Epicbox on 443) names
/// the server [entry] of the list at [path].
bool isRemovedServer(String path, Map<String, Object?> entry, List<Object?> removed) {
  final names = {for (final r in removed) '$r'.toLowerCase()};
  switch (path) {
    case 'node.servers':
      final hp = nodeHostPort('${entry['url'] ?? ''}');
      return names.contains(hp) || (hp.endsWith(':443') && names.contains(hp.substring(0, hp.length - 4)));
    case 'epicbox.servers':
      final id = epicboxIdentity(entry);
      return names.contains(id) || (!id.contains(':') && names.contains('$id:443'));
  }
  return false;
}
