// SPDX-License-Identifier: Apache-2.0
/// The settings file's notices on the phone (`settings_file/`): each shown once as a notice
/// ([noticeProvider]), then dismissed. On the phone only the app writes the file, so they are
/// rare: a file that could not be read or written, one written again.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../settings_file/settings_notice.dart';
import '../settings_file/settings_notice_text.dart';
import '../settings_file/settings_providers.dart';
import 'notices.dart';

/// How much a settings notice matters: the file not used or not written is an error, the rest
/// warn (a line skipped, a value kept).
NoticeLevel settingsNoticeLevel(SettingsNotice n) => switch (n.kind) {
  SettingsNoticeKind.syntaxError ||
  SettingsNoticeKind.readFailed ||
  SettingsNoticeKind.writeFailed => NoticeLevel.error,
  _ => NoticeLevel.warning,
};

/// Shows the settings notices over [child]; needs the app's localizations above it.
class SettingsFileNotices extends ConsumerStatefulWidget {
  const SettingsFileNotices({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SettingsFileNotices> createState() => _SettingsFileNoticesState();
}

class _SettingsFileNoticesState extends ConsumerState<SettingsFileNotices> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(settingsNoticesProvider, (_, notices) {
      if (notices.isEmpty) return;
      // After this frame: a provider is not changed while another one notifies, and the
      // localizations are there.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final l = context.l10n;
        for (final n in notices) {
          ref.read(noticeProvider.notifier).show(settingsNoticeText(l, n), level: settingsNoticeLevel(n));
          ref.read(settingsNoticesProvider.notifier).dismiss(n);
        }
      });
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
