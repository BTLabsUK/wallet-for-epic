// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../motion_switches.dart' show paymentNetworkMoves;
import '../theme/tokens.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

enum KitStepState { done, now, later }

/// One step of a [KitSteps]: a [title], a state, and one dim [detail] line (a time on a done
/// step, the reason on the step in progress).
class KitStep {
  const KitStep({required this.title, required this.state, this.detail, this.network = false});

  final String title;
  final KitStepState state;
  final String? detail;

  /// The step is the one on the network (posted, waiting for a block): while it is the step in
  /// progress its dot is a small network icon with a ring that spreads and fades, still under
  /// the platform's reduced motion and in tests (`paymentNetworkMoves`).
  final bool network;
}

/// A payment's steps (`.step`): done is a filled ok dot, now is a ringed info dot with a dim
/// reason under the title, later is an empty dot; a short hair line joins one dot to the next.
/// Each step is 12 above and below and 14 in, the title 15 (dim until it is done or current),
/// the detail 13. Drawn in a group panel with 4 above and below unless [card] is false; a
/// [footer] (one more row of the panel, as the "What if it never finishes?" line) goes after the
/// last step. A screen reader hears each step with its state.
class KitSteps extends StatelessWidget {
  const KitSteps({super.key, required this.steps, this.card = true, this.semanticsId, this.footer, this.margin = const EdgeInsets.symmetric(horizontal: Kit.gutter)});

  final List<KitStep> steps;
  final bool card;
  final String? semanticsId;
  final Widget? footer;

  /// The card's side margins: the gutter, or none where the page already has its own.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final rows = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      final state = switch (s.state) {
        KitStepState.done => l.phoneKitStepDone,
        KitStepState.now => l.phoneKitStepNow,
        KitStepState.later => l.phoneKitStepLater,
      };
      rows.add(
        Semantics(
          container: true,
          label: '${s.title}, $state${s.detail == null ? '' : ', ${s.detail}'}',
          excludeSemantics: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: s.network && s.state == KitStepState.now ? const _NetworkDot() : _Dot(s.state),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: KitType.body.copyWith(color: s.state == KitStepState.later ? t.dim : t.text, height: 1.3),
                          ),
                          if (s.detail != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(s.detail!, style: KitType.rowSub.copyWith(color: t.dim, height: 1.45)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // `.step + .step::before`: 1.5 wide, 24 tall, from 14 above the step.
              if (i > 0) Positioned(left: 18.5, top: -14, child: Container(width: 1.5, height: 24, color: t.hair2)),
            ],
          ),
        ),
      );
    }
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [...rows, ?footer],
    );
    final body = card
        ? Padding(
            padding: margin,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.group,
                borderRadius: BorderRadius.circular(Kit.rGroup),
                border: Border.all(color: t.hair),
              ),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: column),
            ),
          )
        : column;
    return kitId(semanticsId, body);
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.state);

  final KitStepState state;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return switch (state) {
      KitStepState.done => Container(width: Kit.stepDot, height: Kit.stepDot, decoration: BoxDecoration(color: t.ok, shape: BoxShape.circle)),
      KitStepState.now => Container(
        width: Kit.stepDot,
        height: Kit.stepDot,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: t.info, width: 1.5),
          boxShadow: [BoxShadow(color: t.info.withValues(alpha: 0.2), spreadRadius: 4)],
        ),
      ),
      KitStepState.later => Container(
        width: Kit.stepDot,
        height: Kit.stepDot,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.faint, width: 1.5)),
      ),
    };
  }
}

/// The dot of the step in progress on the network: a ringed dot of the same 10 px as the others, with a second ring
/// that spreads out and fades, over and over. Takes the same 10 px as the other dots; its ring overflows it.
class _NetworkDot extends StatefulWidget {
  const _NetworkDot();

  @override
  State<_NetworkDot> createState() => _NetworkDotState();
}

class _NetworkDotState extends State<_NetworkDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final move = paymentNetworkMoves && !MediaQuery.disableAnimationsOf(context);
    if (move && !_running) {
      _running = true;
      _controller.repeat();
    } else if (!move && _running) {
      _running = false;
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // The layout is as tall as the other dots; the icon's ring overflows it evenly.
    return ExcludeSemantics(
      child: SizedBox(
        width: Kit.stepDot,
        height: Kit.stepDot,
        child: OverflowBox(
          minWidth: 18,
          maxWidth: 18,
          minHeight: 18,
          maxHeight: 18,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final v = _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (_running)
                    Opacity(
                      opacity: (1 - v) * 0.5,
                      child: Container(
                        width: Kit.stepDot * 1.8 * (0.7 + 0.3 * v),
                        height: Kit.stepDot * 1.8 * (0.7 + 0.3 * v),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.info, width: 1.5)),
                      ),
                    ),
                  Container(
                    width: Kit.stepDot,
                    height: Kit.stepDot,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: t.infoSoft, border: Border.all(color: t.info, width: 1.5)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
