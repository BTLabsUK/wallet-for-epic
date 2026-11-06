// SPDX-License-Identifier: Apache-2.0
/// Level 1 payment details: a finished payment is one sentence and "Show the steps"; one under
/// way shows the live timeline. The Details sheet (⋮) holds payment ID, method, times and
/// confirmations. Cancel is the only action; no explorer link and no labels.
library;

import '../phone_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../wallet_service.dart';
import '../../settings.dart' show clockProvider;
import '../common.dart';
import '../method_names.dart';
import '../theme/tokens.dart';
import '../tx_details_screen.dart' show txPrivateNoteKey;
import 'payment_steps.dart';
import '../inline_button.dart';

/// Keys for tests.
const Key payShowStepsKey = ValueKey('pay-show-steps');
const Key payDetailsMenuKey = ValueKey('pay-details-menu');

/// The one sentence of a finished payment: "Sent. Done: 27 Oct." (or Today, Yesterday) Null while it is open.
String? plainSentence(AppLocalizations l, TxEntry tx, BigInt? tip, {required int target, required DateTime now}) {
  final phase = txPhase(tx, tip, target: target);
  final when = dayLabel(l, localTime(tx.blockTimeUnix ?? tx.timeUnix), now);
  return switch (phase) {
    TxPhase.completed => txAmount(tx).outgoing ? l.lvPayDoneSent(when) : l.lvPayDoneReceived(when),
    TxPhase.cancelled => l.txStatusCancelled,
    _ => null,
  };
}

/// The body of the screen at level 1.
class PlainTxDetails extends ConsumerStatefulWidget {
  const PlainTxDetails({
    super.key,
    required this.tx,
    required this.name,
    required this.busy,
    required this.onNote,
    this.onCancel,
    this.cancelNote,
  });

  final TxEntry tx;

  /// The other side's name or short address, when known.
  final String? name;
  final bool busy;
  final VoidCallback onNote;

  /// Null when Cancel is not offered.
  final VoidCallback? onCancel;

  /// The line that says when Cancel comes, while it is held back.
  final String? cancelNote;

  @override
  ConsumerState<PlainTxDetails> createState() => _PlainTxDetailsState();
}

class _PlainTxDetailsState extends ConsumerState<PlainTxDetails> {
  bool _steps = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final tx = widget.tx;
    final tip = tipHeight(ref);
    final target = confirmationsTargetOf(ref);
    final now = ref.watch(clockProvider)();
    final outgoing = txAmount(tx).outgoing;
    final sentence = plainSentence(l, tx, tip, target: target, now: now);
    final note = tx.note;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 220);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sentence != null) ...[
          Text(sentence, style: theme.textTheme.titleMedium),
          if (tx.status != TxStatus.cancelled)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: InlineTextButton(
                key: payShowStepsKey,
                onPressed: () => setState(() => _steps = !_steps),
                child: Text(_steps ? l.lvPayHideSteps : l.lvPayShowSteps),
              ),
            ),
          AnimatedSize(
            duration: duration,
            curve: _steps ? Curves.easeOut : Curves.easeIn,
            alignment: Alignment.topCenter,
            child: _steps ? PaymentTimeline(tx: tx) : const SizedBox(width: double.infinity),
          ),
        ] else ...[
          Text(paymentStepWordOf(ref, tx, tip), style: theme.textTheme.titleMedium?.copyWith(color: t.info)),
          // A maturing reward has no steps: the maturity line the full screen shows instead.
          if (rewardBlocksLeft(tx, tip) case final blocks?) ...[
            const SizedBox(height: 8),
            if (rewardMaturityOf(tx) case final maturity?) Text(l.deskTxNowImmature(maturity)),
            Text(l.deskTxStepBlocksToGo(blocks), style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
          ],
          const SizedBox(height: 12),
          PaymentTimeline(tx: tx),
        ],
        const SizedBox(height: 8),
        if (widget.name != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(outgoing ? l.txDetailsSentTo : l.txDetailsReceivedFrom),
            subtitle: Text(widget.name!),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.lvPayStarted),
          subtitle: Text(formatDateTime(l, localTime(tx.createdAtUnix))),
        ),
        ListTile(
          key: txPrivateNoteKey,
          contentPadding: EdgeInsets.zero,
          title: Text(l.txDetailsPrivateNoteLabel),
          subtitle: Text(note ?? l.txDetailsNoNote),
          trailing: IconButton(
            tooltip: note == null ? l.txDetailsAddNote : l.txDetailsEditNote,
            icon: Icon(note == null ? Icons.note_add_outlined : Icons.edit),
            onPressed: widget.busy ? null : widget.onNote,
          ),
        ),
        if (widget.onCancel != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: DangerButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: Text(l.txDetailsCancelPayment),
              onPressed: widget.busy ? null : widget.onCancel,
            ),
          ),
        ],
        if (widget.cancelNote case final line?) ...[
          const SizedBox(height: 8),
          Text(line, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
        ],
      ],
    );
  }
}

/// The ⋮ menu: opens the Details sheet.
class PlainDetailsMenu extends ConsumerWidget {
  const PlainDetailsMenu({super.key, required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return IconButton(
      key: payDetailsMenuKey,
      tooltip: l.lvPayDetails,
      icon: const Icon(Icons.more_vert),
      onPressed: () => showPhoneSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _DetailsSheet(tx: tx),
      ),
    );
  }
}

class _DetailsSheet extends ConsumerWidget {
  const _DetailsSheet({required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tip = tipHeight(ref);
    final target = confirmationsTargetOf(ref);
    final confirmations = txConfirmations(tx, tip);
    final rows = <(String, String)>[
      if (tx.slateId case final id?) (l.lvPayPaymentId, id),
      if (tx.transport != null) (l.sendMethodLabel, txMethodWord(l, tx.transport)),
      (l.lvPayStarted, formatDateTime(l, localTime(tx.createdAtUnix))),
      if (tx.finalizedAtUnix case final at?) (l.lvPayPosted, formatDateTime(l, localTime(at))),
      if (tx.blockTimeUnix case final at?) (l.txDetailsDate, formatDateTime(l, localTime(at))),
      if (confirmations != null) (l.lvPayConfirmations, l.lvPayOf(confirmations, target)),
      if (tx.fee != null && txAmount(tx).outgoing) (l.txDetailsFee, epicExact(l, tx.fee!)),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.lvPayDetails, style: Theme.of(context).textTheme.titleMedium),
            for (final (label, value) in rows)
              ListTile(contentPadding: EdgeInsets.zero, title: Text(label), subtitle: SelectableText(value)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: Text(l.lvPayCopyDetails),
              onPressed: () => copyText(
                context,
                [for (final (label, value) in rows) '$label: $value'].join('\n'),
                l.lvPayDetailsCopied,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
