// SPDX-License-Identifier: Apache-2.0
/// A settings notice in the app's language.
library;

import '../../l10n/app_localizations.dart';
import 'settings_layout.dart';
import 'settings_notice.dart';

String settingsNoticeText(AppLocalizations l, SettingsNotice n) {
  final file = n.file;
  final line = n.line ?? 1;
  final key = n.key ?? '';
  return switch (n.kind) {
    SettingsNoticeKind.syntaxError => l.settingsFileSyntaxError(file, line),
    SettingsNoticeKind.badValue => _problemText(l, n.problem ?? ValueProblem.notText, file, line),
    SettingsNoticeKind.unknownKey => l.settingsFileUnknownKey(file, line, key),
    SettingsNoticeKind.conflict => l.settingsFileConflict(file, key),
    SettingsNoticeKind.brokenSaved => l.settingsFileBrokenSaved(file, n.backup ?? ''),
    SettingsNoticeKind.recreated => l.settingsFileRecreated(file),
    SettingsNoticeKind.writeFailed => l.settingsFileWriteFailed(file),
    SettingsNoticeKind.readFailed => l.settingsFileReadFailed(file),
  };
}

String _problemText(AppLocalizations l, ValueProblem p, String file, int line) => switch (p) {
  ValueProblem.notText => l.settingsFileNotText(file, line),
  ValueProblem.notNumber => l.settingsFileNotNumber(file, line),
  ValueProblem.notSwitch => l.settingsFileNotSwitch(file, line),
  ValueProblem.notList => l.settingsFileNotList(file, line),
  ValueProblem.notNodeAddress => l.settingsFileNotNodeAddress(file, line),
  ValueProblem.notEpicboxServer => l.settingsFileNotEpicboxServer(file, line),
  ValueProblem.notHostName => l.settingsFileNotHostName(file, line),
  ValueProblem.notWebAddress => l.settingsFileNotWebAddress(file, line),
  ValueProblem.notOnion => l.settingsFileNotOnion(file, line),
  ValueProblem.notPort => l.settingsFileNotPort(file, line),
  ValueProblem.notEpicboxAddress => l.settingsFileNotEpicboxAddress(file, line),
};
