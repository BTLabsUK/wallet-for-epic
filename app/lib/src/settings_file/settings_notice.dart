// SPDX-License-Identifier: Apache-2.0
/// What the settings file tells the app: notices for the person (a bad line, a conflict, a
/// broken file saved aside) and change events for the code that follows the settings.
library;

import 'host_settings.dart';
import 'settings_layout.dart';

enum SettingsNoticeKind {
  /// Not valid TOML: nothing of the file is used; the last good settings are.
  syntaxError,

  /// A key's value was not used ([SettingsNotice.problem]); the last good value is.
  badValue,

  /// A key the layout does not have, kept in the file. Once per key per run.
  unknownKey,

  /// The app and a hand edit changed the same key; the file's value was kept.
  conflict,

  /// The app had to write while the file was broken: the broken file was saved as
  /// [SettingsNotice.backup] and a good one written.
  brokenSaved,

  /// The file was gone and was written again from the settings in use.
  recreated,

  /// The file could not be written; the change holds until the app closes.
  writeFailed,

  /// The file could not be read; the built-in settings are in use.
  readFailed,
}

/// One notice. The text for the person is `settingsNoticeText` (settings_notice_text.dart),
/// in the app's language.
class SettingsNotice {
  const SettingsNotice(this.kind, {required this.file, this.line, this.key, this.problem, this.backup});

  final SettingsNoticeKind kind;

  /// The file's name (`settings.toml`).
  final String file;

  /// 1-based, where the notice has one.
  final int? line;

  /// The dotted key (`node.servers`), for [SettingsNoticeKind.badValue], `unknownKey` and
  /// `conflict`.
  final String? key;

  final ValueProblem? problem;

  /// The name the broken file was saved under (`settings.toml.bad-20261029-141500`).
  final String? backup;

  @override
  bool operator ==(Object other) =>
      other is SettingsNotice &&
      other.kind == kind &&
      other.file == file &&
      other.line == line &&
      other.key == key &&
      other.problem == problem &&
      other.backup == backup;

  @override
  int get hashCode => Object.hash(kind, file, line, key, problem, backup);

  /// English, for the log.
  @override
  String toString() => [
    '$file${line == null ? '' : ', line $line'}: ${kind.name}',
    ?key,
    ?problem?.name,
    ?backup,
  ].join(' ');
}

/// The settings changed, from the app ([appKeys]) or the file (the other keys of [keys]).
class SettingsChange {
  const SettingsChange(this.before, this.after, this.keys, {this.appKeys = const {}});
  final HostSettings before;
  final HostSettings after;

  /// Every key whose value changed.
  final Set<String> keys;

  /// The keys the app set in this change; the rest came from the file.
  final Set<String> appKeys;

  bool get nodeUseChanged => keys.contains('node.use');
  bool get epicboxUseChanged => keys.contains('epicbox.use');
}

/// The node or Epicbox server every wallet uses changed ([key] is `node.use` or
/// `epicbox.use`): the node to reconnect to, or the server every wallet's address now names.
class UseChange {
  const UseChange(this.key, this.from, this.to, {required this.fromApp});
  final String key;
  final String from;
  final String to;

  /// Set in the app; false for a hand edit of the file.
  final bool fromApp;

  bool get isNode => key == 'node.use';
  bool get isEpicbox => key == 'epicbox.use';

  @override
  String toString() => 'UseChange($key: $from -> $to, ${fromApp ? 'app' : 'file'})';
}
