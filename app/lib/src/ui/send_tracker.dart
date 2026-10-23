/// The progress tracker Send shows once a payment is out: round step markers that move as
/// both wallets finish, driven by the real transaction ([sendTrackerAt]).
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'theme/protocol.dart'
    show TimelineState, TimelineStep, currentMarkEdge, currentMarkHalo;
import 'theme/tokens.dart';

/// Where an epicbox send stands on the tracker's four steps: sent to them, their wallet
/// signed, sent to the network, confirmed.
enum SendTrack {
  /// Waiting for their wallet: step 2 is current.
  waitingRecipient,

  /// Signed and handed to the network; waiting for confirmations: step 4 is current.
  confirming,

  /// Every step done.
  completed,

  /// Finished, but the network has not taken it yet; the payment can be posted again.
  notPosted,

  /// Cancelled, or expired before their wallet answered.
  cancelled,
}

/// [tx]'s place on the tracker. The listener finishes the payment as soon as their reply
/// comes, so "signed" and "on the network" pass together when it leaves
/// [TxStatus.awaitingRecipient].
SendTrack sendTrackerAt(TxEntry tx, BigInt? tip, {required int target}) {
  if (tx.repostable) return SendTrack.notPosted;
  return switch (txPhase(tx, tip, target: target)) {
    TxPhase.cancelled => SendTrack.cancelled,
    TxPhase.completed => SendTrack.completed,
    TxPhase.waitingRecipient ||
    TxPhase.waitingPayer => SendTrack.waitingRecipient,
    TxPhase.confirming ||
    TxPhase.waitingSender ||
    TxPhase.fromBackup => SendTrack.confirming,
  };
}

/// The index of the current step for [track] on the four steps, or 4 when all are done.
int sendTrackerStep(SendTrack track) => switch (track) {
  SendTrack.waitingRecipient => 1,
  SendTrack.confirming => 3,
  SendTrack.completed || SendTrack.notPosted || SendTrack.cancelled => 4,
};

/// Whether the current marker's ring pulses. Widget tests turn it off in
/// `test/flutter_test_config.dart`, since a loop never lets `pumpAndSettle` settle; reduced
/// motion stops it too.
@visibleForTesting
bool sendPulseMoves = true;

/// Steps with round markers joined by a rail: done filled, current a ring with a slow pulse
/// (still under reduced motion), later hollow. The current step's label is a live region.
class RoundSteps extends StatelessWidget {
  const RoundSteps({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, step) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      _RoundMark(state: step.state),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: step.state == TimelineState.done
                                ? doneMarkColor(t)
                                : t.line,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 18),
                    child: Semantics(
                      // One node per step, read on its own.
                      container: true,
                      liveRegion: step.state == TimelineState.current,
                      // The marker's state in words: done, now, or later.
                      label: [
                        switch (step.state) {
                          TimelineState.done => l.trackStepDone(step.label),
                          TimelineState.current => l.trackStepNow(step.label),
                          TimelineState.todo => l.trackStepLater(step.label),
                        },
                        ?step.detail,
                      ].join('. '),
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: step.state == TimelineState.todo
                                  ? t.dim
                                  : t.text,
                              fontWeight: step.state == TimelineState.todo
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                          ),
                          if (step.detail case final detail?)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                detail,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: t.dim,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A done marker's fill.
Color doneMarkColor(WalletTokens t) => t.ok;

class _RoundMark extends StatefulWidget {
  const _RoundMark({required this.state});

  final TimelineState state;

  @override
  State<_RoundMark> createState() => _RoundMarkState();
}

class _RoundMarkState extends State<_RoundMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_RoundMark old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final moves =
        widget.state == TimelineState.current &&
        sendPulseMoves &&
        !MediaQuery.disableAnimationsOf(context);
    if (moves && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!moves && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox.square(
      dimension: 28,
      child: Center(
        child: switch (widget.state) {
          TimelineState.done => Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: doneMarkColor(t),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 16, color: t.bg),
          ),
          TimelineState.current => AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: t.bg,
                shape: BoxShape.circle,
                border: Border.all(color: currentMarkEdge(t), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: currentMarkHalo(t),
                    spreadRadius:
                        2 + 3 * Curves.easeInOut.transform(_pulse.value),
                  ),
                ],
              ),
            ),
          ),
          TimelineState.todo => Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: t.bg,
              shape: BoxShape.circle,
              border: Border.all(color: t.lineStrong, width: 2),
            ),
          ),
        },
      ),
    );
  }
}
