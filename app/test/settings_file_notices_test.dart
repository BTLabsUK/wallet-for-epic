// SPDX-License-Identifier: Apache-2.0
// Settings file notices the user cannot act on go to the log, not the screen.
import 'package:epic_wallet/src/settings_file/settings_notice.dart';
import 'package:epic_wallet/src/ui/settings_file_notices.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unknownKey, recreated, brokenSaved and conflict are logged only', () {
    for (final k in [
      SettingsNoticeKind.unknownKey,
      SettingsNoticeKind.recreated,
      SettingsNoticeKind.brokenSaved,
      SettingsNoticeKind.conflict,
    ]) {
      expect(settingsNoticeLogOnly(SettingsNotice(k, file: 'settings.toml')), isTrue, reason: k.name);
    }
  });

  test('the kinds the user can fix still show', () {
    for (final k in [SettingsNoticeKind.syntaxError, SettingsNoticeKind.readFailed, SettingsNoticeKind.writeFailed, SettingsNoticeKind.badValue]) {
      expect(settingsNoticeLogOnly(SettingsNotice(k, file: 'settings.toml')), isFalse, reason: k.name);
    }
  });
}
