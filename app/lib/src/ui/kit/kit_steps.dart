// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../motion_switches.dart' show paymentNetworkMoves;
import '../theme/tokens.dart';
import 'kit_icons.dart';
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

/// A payment's three steps (HANDOFF 7.9): done is a filled ok dot, now is a ringed info dot
/// with a one-line reason, later is an empty dot. A hair line joins the dots. Drawn in a group
/// panel unless [card] is false. A screen reader hears each step with its state.
class KitSteps extends StatelessWidget {
  const KitSteps({super.key, required this.steps, this.card = true, this.semanticsId});

  final List<KitStep> steps;
  final bool card;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final rows = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      final last = i == steps.length - 1;
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
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 18,
                  child: Column(
                    children: [
                      const SizedBox(height: 5),
                      s.network && s.state == KitStepState.now ? const _NetworkDot() : _Dot(s.state),
                      Expanded(
                        child: last
                            ? const SizedBox.shrink()
                            : Container(width: 1.5, margin: const EdgeInsets.symmetric(vertical: 4), color: t.hair2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: last ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style: KitType.rowTitle.copyWith(color: s.state == KitStepState.later ? t.faint : t.text),
                        ),
                        if (s.detail != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(s.detail!, style: KitType.rowSub.copyWith(color: s.state == KitStepState.now ? t.info : t.dim)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final column = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    final body = card
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.group,
                borderRadius: BorderRadius.circular(Kit.rGroup),
                border: Border.all(color: t.hair),
              ),
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), child: column),
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

/// The dot of the step in progress on the network: a network icon in a ring, with a second ring
/// that spreads out and fades, over and over. Sits in the same 18 px column as the other dots.
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
        width: 18,
        height: Kit.stepDot,
        child: OverflowBox(
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
                        width: 18 * (0.7 + 0.3 * v),
                        height: 18 * (0.7 + 0.3 * v),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.info, width: 1.5)),
                      ),
                    ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: t.infoSoft, border: Border.all(color: t.info, width: 1.5)),
                    child: Icon(KitIcons.network, size: 9, color: t.info),
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
