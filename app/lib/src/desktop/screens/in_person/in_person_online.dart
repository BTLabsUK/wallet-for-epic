// SPDX-License-Identifier: Apache-2.0
/// The desktop's quiet line while an in-person answer goes through an Epicbox server, and its
/// details dialog with "Cancel online reply". The words and steps are the phone's
/// (ui/in_person/in_person_online.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/in_person/in_person_logic.dart';
import '../../../ui/in_person/in_person_online.dart'
    show inPersonOnlineCancellable, inPersonOnlineDot, inPersonOnlineLineText, inPersonOnlineStepText;
import '../../../ui/status.dart' show StatusDot;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// The status line, for tests.
const Key deskInPersonOnlineKey = ValueKey('desk-ip-online');

/// The dialog's "Cancel online reply", for tests.
const Key deskInPersonOnlineCancelKey = ValueKey('desk-ip-online-cancel');

/// The dialog's step value, for tests.
const Key deskInPersonOnlineStepKey = ValueKey('desk-ip-online-step');

/// The desktop state of [step]'s dot.
EState deskInPersonOnlineState(InPersonOnlineStep step) => switch (inPersonOnlineDot(step)) {
  StatusDot.busy => EState.active,
  StatusDot.ok => EState.ok,
  StatusDot.warn => EState.warn,
  StatusDot.bad => EState.risk,
  StatusDot.off => EState.off,
};

/// The answering side's step words: a failed post did not go through.
String _stepText(AppLocalizations l, InPersonOnline online) =>
    online is InPersonAnswerPost && online.step == InPersonOnlineStep.failed
    ? l.deskIpStepFailed
    : inPersonOnlineStepText(l, online.step);

/// One quiet line: the Epicbox glyph with its state dot and the step. A click opens
/// [showDeskInPersonOnlineDialog].
class DeskInPersonOnlineLine extends StatelessWidget {
  const DeskInPersonOnlineLine({super.key, required this.online});

  final InPersonOnline online;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    return ListenableBuilder(
      listenable: online,
      builder: (context, _) {
        final text = inPersonOnlineLineText(l, online);
        void open() => showDeskInPersonOnlineDialog(context, online);
        return Semantics(
          key: deskInPersonOnlineKey,
          container: true,
          button: true,
          liveRegion: true,
          label: text,
          hint: l.deskIpOnlineDetails,
          excludeSemantics: true,
          onTap: open,
          child: Material(
            type: MaterialType.transparency,
            child: EInkWell(
              onTap: open,
              borderRadius: BorderRadius.circular(Rad.sm),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Sp.x1, vertical: Sp.x1),
                child: Row(
                  children: [
                    EStatusGlyph(icon: EIcons.epicbox, state: deskInPersonOnlineState(online.step), label: text),
                    SizedBox(width: Sp.x2),
                    Expanded(child: Text(text, style: ts.bodyDim)),
                    SizedBox(width: Sp.x2),
                    Icon(EIcons.info, size: Ctl.iconSm, color: c.dim),
                  ],
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
Future<void> showDeskInPersonOnlineDialog(BuildContext context, InPersonOnline online) =>
    showEDialog<void>(context, builder: (_) => _OnlineDialog(online: online));

class _OnlineDialog extends ConsumerWidget {
  const _OnlineDialog({required this.online});

  final InPersonOnline online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final tip = ref.watch(deskProvider.select((s) => s.status?.nodeHeight));
    return ListenableBuilder(
      listenable: online,
      builder: (context, _) {
        final step = online.step;
        final left = inPersonMinutesLeft(online.cutoff, tip == null ? null : BigInt.from(tip));
        final cancellable = inPersonOnlineCancellable(online);
        final answering = online is InPersonAnswerPost;
        return EDialog(
          title: l.deskIpOnlineTitle,
          icon: EIcons.epicbox,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              EFacts([
                (l.deskIpOnlineServer, Text(online.host, style: ts.body)),
                (
                  l.deskIpOnlineStatus,
                  Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        EStateDot(deskInPersonOnlineState(step)),
                        SizedBox(width: Sp.x2),
                        Expanded(child: Text(_stepText(l, online), key: deskInPersonOnlineStepKey, style: ts.body)),
                      ],
                    ),
                  ),
                ),
                (l.deskIpOnlineTimeLeft, Text(left == null ? l.commonUnknown : l.deskIpOnlineMinutes(left), style: ts.body)),
              ]),
              if (cancellable) ...[
                SizedBox(height: Sp.x3),
                Text(answering ? l.deskIpOnlineCancelAnswer : l.deskIpOnlineCancelCode, style: ts.bodyDim),
              ],
            ],
          ),
          actions: [
            EButton(label: l.commonClose, onPressed: () => Navigator.of(context).pop()),
            if (cancellable)
              EButton(
                key: deskInPersonOnlineCancelKey,
                label: l.deskIpOnlineCancel,
                onPressed: () {
                  online.cancelOnline();
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }
}
