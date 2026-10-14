/// "How it works": an Epic payment as the handshake it is, in a bottom sheet. Three nodes,
/// You, Them and the Network, with one arrow lit at a time and a token moving along it.
///
/// The order is Mimblewimble's ([handshakeSteps]): the wallet that starts a payment or a
/// request also finishes it and hands it to the network; the other wallet adds its part and
/// signs in between. Play and Pause, and steps by hand (WCAG 2.2.2). With reduced motion
/// nothing moves and the step buttons remain.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n.dart';
import 'theme/tokens.dart';

/// Which handshake the sheet shows.
enum HandshakeFlow {
  /// You pay them.
  payment,

  /// You ask them for coins (an invoice); they pay.
  request,
}

/// A node of the diagram.
enum HandshakeParty { you, them, network }

/// One step of a handshake: [actor] does it, and the message goes [from] one node [to]
/// another. [to] is null for the network's confirmation, which goes nowhere.
class HandshakeStep {
  const HandshakeStep({
    required this.actor,
    required this.from,
    this.to,
    required this.caption,
  });

  final HandshakeParty actor;
  final HandshakeParty from;
  final HandshakeParty? to;
  final String Function(AppLocalizations l) caption;
}

/// The steps of [flow], in the order they happen.
List<HandshakeStep> handshakeSteps(HandshakeFlow flow) => switch (flow) {
  HandshakeFlow.payment => [
    HandshakeStep(
      actor: HandshakeParty.you,
      from: HandshakeParty.you,
      to: HandshakeParty.them,
      caption: (l) => l.handshakePay1,
    ),
    HandshakeStep(
      actor: HandshakeParty.them,
      from: HandshakeParty.them,
      to: HandshakeParty.you,
      caption: (l) => l.handshakePay2,
    ),
    HandshakeStep(
      actor: HandshakeParty.you,
      from: HandshakeParty.you,
      to: HandshakeParty.network,
      caption: (l) => l.handshakeFinish,
    ),
    HandshakeStep(
      actor: HandshakeParty.network,
      from: HandshakeParty.network,
      caption: (l) => l.handshakeConfirm,
    ),
  ],
  HandshakeFlow.request => [
    HandshakeStep(
      actor: HandshakeParty.you,
      from: HandshakeParty.you,
      to: HandshakeParty.them,
      caption: (l) => l.handshakeReq1,
    ),
    HandshakeStep(
      actor: HandshakeParty.them,
      from: HandshakeParty.them,
      to: HandshakeParty.you,
      caption: (l) => l.handshakeReq2,
    ),
    HandshakeStep(
      actor: HandshakeParty.you,
      from: HandshakeParty.you,
      to: HandshakeParty.network,
      caption: (l) => l.handshakeFinish,
    ),
    HandshakeStep(
      actor: HandshakeParty.network,
      from: HandshakeParty.network,
      caption: (l) => l.handshakeConfirm,
    ),
  ],
};

/// How long each step plays.
const Duration handshakeStepDuration = Duration(milliseconds: 2800);

/// The caption of the step shown, for tests.
const Key handshakeCaptionKey = ValueKey('handshake-caption');

/// Opens the sheet.
Future<void> showHandshakeSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const HandshakeSheet(),
    );

/// The sheet's content. Public for the screenshot tour and tests; open it with
/// [showHandshakeSheet].
class HandshakeSheet extends StatefulWidget {
  const HandshakeSheet({super.key, this.flow = HandshakeFlow.payment});

  /// The flow it opens on.
  final HandshakeFlow flow;

  @override
  State<HandshakeSheet> createState() => _HandshakeSheetState();
}

class _HandshakeSheetState extends State<HandshakeSheet>
    with SingleTickerProviderStateMixin {
  late HandshakeFlow _flow = widget.flow;
  int _step = 0;
  bool _paused = false;

  /// Progress through the current step, 0 to 1. At the end the next step starts.
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: handshakeStepDuration,
  )..addStatusListener(_stepEnded);

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  /// Plays unless paused or under reduced motion, where the token rests mid-arrow.
  void _sync() {
    if (_still) {
      _progress.stop();
      _progress.value = 0.5;
    } else if (_paused) {
      _progress.stop();
    } else if (!_progress.isAnimating) {
      _progress.forward();
    }
  }

  void _stepEnded(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _step = (_step + 1) % handshakeSteps(_flow).length);
    _progress.forward(from: 0);
  }

  /// Shows [step] and pauses there: the reader chose it, so it must not move on unannounced.
  void _go(int step) {
    final count = handshakeSteps(_flow).length;
    setState(() {
      _step = (step + count) % count;
      _paused = true;
    });
    if (_still) return;
    _progress.value = 0.5;
    _sync();
  }

  void _toggle() {
    setState(() => _paused = !_paused);
    _sync();
  }

  void _switch(HandshakeFlow flow) {
    setState(() {
      _flow = flow;
      _step = 0;
    });
    if (_still) return;
    _progress.value = _paused ? 0.5 : 0;
    _sync();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final steps = handshakeSteps(_flow);
    final step = steps[_step];
    final still = _still;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(l.sendHowItWorks, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 16),
            SegmentedButton<HandshakeFlow>(
              segments: [
                ButtonSegment(
                  value: HandshakeFlow.payment,
                  label: Text(l.handshakePayment),
                ),
                ButtonSegment(
                  value: HandshakeFlow.request,
                  label: Text(l.handshakeRequest),
                ),
              ],
              selected: {_flow},
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              onSelectionChanged: (selected) => _switch(selected.first),
            ),
            const SizedBox(height: 16),
            // The picture says what the caption says; screen readers get the caption.
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.surface,
                  border: Border.all(color: t.line),
                  borderRadius: BorderRadius.circular(t.radiusSmall),
                ),
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) =>
                      _Diagram(step: step, progress: _progress.value),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Every caption is laid out, so the sheet keeps the height of the longest one.
            Semantics(
              // Announced when the user moves it, not every few seconds while it plays.
              liveRegion: _paused || still,
              child: Stack(
                children: [
                  for (final (i, s) in steps.indexed)
                    Visibility(
                      visible: i == _step,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Text(
                        '${i + 1}. ${s.caption(l)}',
                        key: i == _step ? handshakeCaptionKey : null,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l.handshakePrevious,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _go(_step - 1),
                ),
                Semantics(
                  label: l.fileHelpStepOf(_step + 1, steps.length),
                  excludeSemantics: true,
                  child: _Dots(step: _step, count: steps.length),
                ),
                if (!still)
                  IconButton(
                    tooltip: _paused ? l.fileHelpPlay : l.fileHelpPause,
                    icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                    onPressed: _toggle,
                  ),
                IconButton(
                  tooltip: l.handshakeNext,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _go(_step + 1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.commonClose),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.step, required this.count});

  final int step;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: i == step ? 18 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == step ? t.accent : t.lineStrong,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// Where each node sits, as a share of the diagram's width and height.
const Map<HandshakeParty, Alignment> _place = {
  HandshakeParty.you: Alignment(-0.85, -0.5),
  HandshakeParty.them: Alignment(0.85, -0.5),
  HandshakeParty.network: Alignment(0, 0.62),
};

/// The three nodes as labelled boxes over the painted arrows and token.
class _Diagram extends StatelessWidget {
  const _Diagram({required this.step, required this.progress});

  final HandshakeStep step;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    String label(HandshakeParty p) => switch (p) {
      HandshakeParty.you => l.handshakeYou,
      HandshakeParty.them => l.handshakeThem,
      HandshakeParty.network => l.handshakeNetwork,
    };
    return SizedBox(
      height: 168,
      child: LayoutBuilder(
        builder: (context, box) {
          final nodeWidth = math.min(104.0, box.maxWidth * 0.26);
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: HandshakePainter(
                    step: step,
                    progress: progress,
                    line: t.lineStrong,
                    lit: t.accent,
                    halo: t.accentSoft,
                    token: t.accent,
                    done: t.ok,
                    nodeWidth: nodeWidth,
                  ),
                ),
              ),
              for (final party in HandshakeParty.values)
                Align(
                  alignment: _place[party]!,
                  child: _Node(
                    width: nodeWidth,
                    label: label(party),
                    lit: step.actor == party,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.width, required this.label, required this.lit});

  final double width;
  final String label;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: t.surfaceHi,
        borderRadius: BorderRadius.circular(t.radiusSmall),
        border: Border.all(
          color: lit ? t.accent : t.lineStrong,
          width: lit ? 2 : 1,
        ),
        boxShadow: lit
            ? [BoxShadow(color: t.accentSoft, spreadRadius: 4)]
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: theme.textTheme.labelLarge?.copyWith(color: t.text),
        ),
      ),
    );
  }
}

/// The arrows between the nodes, the current one lit, and the token moving along it at
/// [progress]. The confirmation, which has no arrow, rings the network instead.
class HandshakePainter extends CustomPainter {
  const HandshakePainter({
    required this.step,
    required this.progress,
    required this.line,
    required this.lit,
    required this.halo,
    required this.token,
    required this.done,
    required this.nodeWidth,
  });

  final HandshakeStep step;
  final double progress;
  final Color line, lit, halo, token, done;
  final double nodeWidth;

  static const double _nodeHeight = 40;

  Offset _centre(HandshakeParty p, Size size) =>
      _place[p]!.alongSize(size) +
      // Align places the box, so its centre moves with the alignment.
      Offset(-_place[p]!.x * nodeWidth / 2, -_place[p]!.y * _nodeHeight / 2);

  /// The lane from [from] to [to]: the two wallets talk on two lanes, out above and back
  /// below, so the arrow back is not the same line.
  (Offset, Offset) _lane(HandshakeParty from, HandshakeParty to, Size size) {
    final a = _centre(from, size), b = _centre(to, size);
    if (to == HandshakeParty.network || from == HandshakeParty.network) {
      // From the wallet's lower edge to the network's top.
      final toNet = to == HandshakeParty.network;
      final wallet = toNet ? a : b, net = toNet ? b : a;
      final w = Offset(wallet.dx, wallet.dy + _nodeHeight / 2 + 4);
      final n = Offset(
        net.dx + (wallet.dx < net.dx ? -1 : 1) * nodeWidth * 0.2,
        net.dy - _nodeHeight / 2 - 4,
      );
      return toNet ? (w, n) : (n, w);
    }
    final left = a.dx < b.dx;
    final dy = from == HandshakeParty.you ? -8.0 : 8.0;
    final half = nodeWidth / 2 + 6;
    return (
      Offset(a.dx + (left ? half : -half), a.dy + dy),
      Offset(b.dx + (left ? -half : half), b.dy + dy),
    );
  }

  void _arrow(Canvas canvas, Offset a, Offset b, Paint paint) {
    canvas.drawLine(a, b, paint);
    final dir = (b - a) / (b - a).distance;
    final normal = Offset(-dir.dy, dir.dx);
    final head = Path()
      ..moveTo(b.dx, b.dy)
      ..lineTo(
        b.dx - dir.dx * 8 + normal.dx * 4.5,
        b.dy - dir.dy * 8 + normal.dy * 4.5,
      )
      ..lineTo(
        b.dx - dir.dx * 8 - normal.dx * 4.5,
        b.dy - dir.dy * 8 - normal.dy * 4.5,
      )
      ..close();
    canvas.drawPath(head, Paint()..color = paint.color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const lanes = [
      (HandshakeParty.you, HandshakeParty.them),
      (HandshakeParty.them, HandshakeParty.you),
      (HandshakeParty.you, HandshakeParty.network),
    ];
    final quiet = Paint()
      ..color = line
      ..strokeWidth = 1.2;
    final bright = Paint()
      ..color = lit
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final (from, to) in lanes) {
      final current = step.from == from && step.to == to;
      final (a, b) = _lane(from, to, size);
      _arrow(canvas, a, b, current ? bright : quiet);
      if (current) {
        final p = Curves.easeInOutCubic.transform(progress.clamp(0.0, 1.0));
        final at = Offset.lerp(a, b, p)!;
        canvas.drawCircle(at, 9, Paint()..color = halo);
        canvas.drawCircle(at, 5.5, Paint()..color = token);
      }
    }
    if (step.to == null) {
      // The network records it: a ring that closes round the node.
      final c = _centre(step.from, size);
      final rect = Rect.fromCenter(
        center: c,
        width: nodeWidth + 14,
        height: _nodeHeight + 14,
      );
      final ring = Paint()
        ..color = done
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final path = Path()
        ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)));
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0)),
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(HandshakePainter old) =>
      old.step != step ||
      old.progress != progress ||
      old.line != line ||
      old.lit != lit ||
      old.halo != halo ||
      old.token != token ||
      old.done != done ||
      old.nodeWidth != nodeWidth;
}
