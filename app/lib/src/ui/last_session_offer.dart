// SPDX-License-Identifier: Apache-2.0
/// The phone's "The app stopped responding last time. Send the log?" notice (`last_session.dart`):
/// shown once per incident on Home after unlock, never over the unlock itself. Send opens Send
/// feedback with that session's log; nothing leaves until the user sends the report there.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feedback.dart' show lastSessionProvider;
import '../l10n.dart';
import '../last_session.dart';
import 'feedback_screen.dart' show openFeedback;
import 'notices.dart';

/// Shows the notice when a kept last session waits for it, and marks it offered.
Future<void> offerLastSessionReport(BuildContext context, WidgetRef ref) async {
  final source = ref.read(lastSessionProvider);
  if (source == null || !source.due) return;
  final kept = await source.read();
  if (kept == null || !context.mounted) return;
  // Offered once, whatever the answer: no second notice for the same end.
  source.offered();
  final l = context.l10n;
  ref
      .read(noticeProvider.notifier)
      .show(
        kept.end == LastSessionEnd.froze ? l.deskLastSessionFroze : l.deskLastSessionClosed,
        level: NoticeLevel.info,
        persistent: true,
        secondary: NoticeAction(l.deskLastSessionNotNow, () {}),
        action: NoticeAction(l.deskLastSessionSend, () {
          if (context.mounted) openFeedback(context, lastSession: kept);
        }),
      );
}
