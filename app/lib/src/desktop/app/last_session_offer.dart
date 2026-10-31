// SPDX-License-Identifier: Apache-2.0
/// The desktop's "The app closed unexpectedly last time. Send the log?" toast
/// (`last_session.dart`): once per incident, when the shell first shows after unlock. Send opens
/// Report a problem with that session's log; nothing leaves until the user sends it there. The
/// toast leaving on its own is the "Not now".
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feedback.dart' show lastSessionProvider;
import '../../last_session.dart';
import '../desk_l10n.dart';
import '../screens/settings/report_problem.dart' show showReportProblemDialog;
import '../widgets/kit.dart';

/// Shows the toast when a kept last session waits for it, and marks it offered.
Future<void> offerDeskLastSessionReport(BuildContext context, WidgetRef ref) async {
  final source = ref.read(lastSessionProvider);
  if (source == null || !source.due) return;
  final kept = await source.read();
  if (kept == null || !context.mounted) return;
  // Offered once, whatever the answer: no second toast for the same end.
  source.offered();
  final l = context.l10n;
  showEToast(
    context,
    kept.end == LastSessionEnd.froze ? l.deskLastSessionFroze : l.deskLastSessionClosed,
    tone: ETone.info,
    action: (
      label: l.deskLastSessionSend,
      run: () {
        if (context.mounted) showReportProblemDialog(context, lastSession: kept);
      },
    ),
  );
}
