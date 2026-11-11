// SPDX-License-Identifier: Apache-2.0
/// The phone's quiet line while an in-person answer goes through an Epicbox server, and its
/// details sheet with "Cancel online reply".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../common.dart' show tipHeight;
import '../method_icons.dart';
import '../phone_sheet.dart';
import '../status.dart';
import '../theme/tokens.dart';
import 'in_person_logic.dart';

/// The status line, for tests.
const Key inPersonOnlineKey = ValueKey('inPersonOnline');

/// The details sheet's "Cancel online reply", for tests.
const Key inPersonOnlineCancelKey = ValueKey('inPersonOnlineCancel');

/// The details sheet's step value, for tests.
const Key inPersonOnlineStepKey = ValueKey('inPersonOnlineStep');

/// The dot of [step]: blue while it runs, green once through, amber when the server failed.
StatusDot inPersonOnlineDot(InPersonOnlineStep step) => switch (step) {
  InPersonOnlineStep.posting || InPersonOnlineStep.waiting => StatusDot.busy,
  InPersonOnlineStep.sent || InPersonOnlineStep.received => StatusDot.ok,
  InPersonOnlineStep.failed => StatusDot.warn,
  InPersonOnlineStep.cancelled => StatusDot.off,
};

/// The words of [step] in the details.
String inPersonOnlineStepText(AppLocalizations l, InPersonOnlineStep step) => switch (step) {
  InPersonOnlineStep.posting => l.deskIpStepPosting,
  InPersonOnlineStep.sent => l.deskIpStepSent,
  InPersonOnlineStep.waiting => l.deskIpWaiting,
  InPersonOnlineStep.received => l.deskIpStepReceived,
  InPersonOnlineStep.failed => l.deskIpStepDown,
  InPersonOnlineStep.cancelled => l.deskIpStepCancelled,
};

/// The answering side's step words: a failed post did not go through (the code side keeps
/// trying).
String _stepText(AppLocalizations l, InPersonOnline online) =>
    online is InPersonAnswerPost && online.step == InPersonOnlineStep.failed
    ? l.deskIpStepFailed
    : inPersonOnlineStepText(l, online.step);

/// "Cancel online reply" is offered: the code side while it waits, the answering side while
/// it sends.
bool inPersonOnlineCancellable(InPersonOnline online) => switch (online) {
  InPersonAnswerPost() => online.step == InPersonOnlineStep.posting,
  _ => online.step == InPersonOnlineStep.waiting || online.step == InPersonOnlineStep.failed,
};

/// The line's words: the code side waits ("Answer comes back online · host") or finds the
/// server down; the answering side sends.
String inPersonOnlineLineText(AppLocalizations l, InPersonOnline online) => switch (online.step) {
  InPersonOnlineStep.posting => l.deskIpOnlineSending,
  InPersonOnlineStep.failed when online is! InPersonAnswerPost => l.deskIpOnlineDown,
  _ => l.deskIpOnlineLine(online.host),
};

/// One quiet line: the Epicbox glyph with its state dot (breathing a few times, then still)
/// and the step. A tap opens [showInPersonOnlineSheet].
class InPersonOnlineLine extends StatelessWidget {
  const InPersonOnlineLine({super.key, required this.online});

  final InPersonOnline online;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: online,
      builder: (context, _) {
        final step = online.step;
        final dot = inPersonOnlineDot(step);
        final text = inPersonOnlineLineText(l, online);
        void open() => showInPersonOnlineSheet(context, online);
        return Semantics(
          key: inPersonOnlineKey,
          container: true,
          button: true,
          liveRegion: true,
          label: text,
          hint: l.deskIpOnlineDetails,
          excludeSemantics: true,
          onTap: open,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: open,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    children: [
                      Pulse(
                        active: dot == StatusDot.busy,
                        child: StatusGlyph(
                          icon: MethodIcons.epicbox,
                          enabled: true,
                          dot: dot,
                          ring: theme.scaffoldBackgroundColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.info_outline, size: 18, color: t.dim),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The details of [online]: the server, the step as it goes, the time left, and "Cancel online
/// reply" while it can still be cancelled.
Future<void> showInPersonOnlineSheet(BuildContext context, InPersonOnline online) =>
    showPhoneSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OnlineSheet(online: online),
    );

class _OnlineSheet extends ConsumerWidget {
  const _OnlineSheet({required this.online});

  final InPersonOnline online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final tip = tipHeight(ref);
    return ListenableBuilder(
      listenable: online,
      builder: (context, _) {
        final step = online.step;
        final left = inPersonMinutesLeft(online.cutoff, tip);
        final cancellable = inPersonOnlineCancellable(online);
        final answering = online is InPersonAnswerPost;
        Widget row(String label, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
              ),
              const SizedBox(width: 12),
              Expanded(child: value),
            ],
          ),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(header: true, child: Text(l.deskIpOnlineTitle, style: theme.textTheme.titleLarge)),
              const SizedBox(height: 12),
              row(
                l.deskIpOnlineServer,
                Text(online.host, style: theme.textTheme.bodyMedium, softWrap: true),
              ),
              row(
                l.deskIpOnlineStatus,
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Pulse(
                        active: inPersonOnlineDot(step) == StatusDot.busy,
                        child: StateDot(dot: inPersonOnlineDot(step), size: 10, ring: theme.colorScheme.surface),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_stepText(l, online), key: inPersonOnlineStepKey, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
              row(
                l.deskIpOnlineTimeLeft,
                Text(left == null ? l.commonUnknown : l.deskIpOnlineMinutes(left), style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(height: 16),
              if (cancellable) ...[
                OutlinedButton(
                  key: inPersonOnlineCancelKey,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () {
                    online.cancelOnline();
                    Navigator.of(context).pop();
                  },
                  child: Text(l.deskIpOnlineCancel),
                ),
                const SizedBox(height: 8),
                Text(
                  answering ? l.deskIpOnlineCancelAnswer : l.deskIpOnlineCancelCode,
                  style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.commonClose),
              ),
            ],
          ),
        );
      },
    );
  }
}
