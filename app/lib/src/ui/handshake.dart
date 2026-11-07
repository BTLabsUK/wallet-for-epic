// SPDX-License-Identifier: Apache-2.0
/// "How it works": an Epic payment as the handshake it is, in a bottom sheet. Four nodes,
/// You, the Relay (epicbox, or the file passed by hand), Them and the Network, with one
/// arrow lit at a time and a token moving along it.
///
/// The order is Mimblewimble's ([handshakeSteps]): the wallet that starts a payment or a
/// request also finishes it and hands it to the network; the other wallet adds its part and
/// signs in between. Play and Pause, and steps by hand (WCAG 2.2.2). With reduced motion
/// nothing moves and the step buttons remain.
library;

import 'phone_sheet.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../tor_build.dart';
import 'history_screen.dart' show FadingRow;
import 'method_icons.dart';
import 'theme/tokens.dart';

/// Which handshake the sheet shows.
enum HandshakeFlow {
  /// You pay them over epicbox.
  payment,

  /// You ask them for coins (an invoice) over epicbox; they pay.
  request,

  /// You pay them with a payment file, passed by hand both ways.
  file,

  /// You pay their wallet directly (a Link address: HTTP or Tor), no relay.
  direct,

  /// You pay the phone next to this one: codes shown and scanned both ways, no relay.
  qr,

  /// The same, told from the receiver's side: they show the code, you scan it.
  qrReceive,
}

/// Whether the flow goes through a middle node: the relay, or the file passed by hand.
bool handshakeHasMiddle(HandshakeFlow flow) => switch (flow) {
  HandshakeFlow.payment || HandshakeFlow.request || HandshakeFlow.file => true,
  HandshakeFlow.direct || HandshakeFlow.qr || HandshakeFlow.qrReceive => false,
};

/// The arrows of [flow], each as (from, to), in the order of the steps that use them.
List<(HandshakeParty, HandshakeParty)> handshakeLanes(HandshakeFlow flow) =>
    switch (flow) {
      HandshakeFlow.direct || HandshakeFlow.qr => const [
        (_you, _them),
        (_them, _you),
        (_you, _network),
      ],
      HandshakeFlow.qrReceive => const [
        (_them, _you),
        (_you, _them),
        (_them, _network),
      ],
      _ => const [
        (_you, _relay),
        (_relay, _them),
        (_them, _relay),
        (_relay, _you),
        (_you, _network),
      ],
    };

/// A node of the diagram. [relay] is the epicbox relay, or the file passed by hand in
/// [HandshakeFlow.file].
enum HandshakeParty { you, relay, them, network }

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

const _you = HandshakeParty.you;
const _relay = HandshakeParty.relay;
const _them = HandshakeParty.them;
const _network = HandshakeParty.network;

/// The steps of [flow], in the order they happen. The slate goes out through the relay
/// (or the file), comes back the same way, and the wallet that started finishes it and
/// posts it: the payer for a payment, the issuer for a request (LEPIC finalizes an invoice
/// on the issuer's side once the payer's reply arrives).
List<HandshakeStep> handshakeSteps(HandshakeFlow flow) {
  switch (flow) {
    case HandshakeFlow.direct:
      // Their wallet answers on the connection the payment came on.
      return [
        HandshakeStep(
          actor: _you,
          from: _you,
          to: _them,
          caption: (l) => torBuilt ? l.handshakeLink1 : l.handshakeLink1NoTor,
        ),
        HandshakeStep(
          actor: _them,
          from: _them,
          to: _you,
          caption: (l) => l.handshakeLink2,
        ),
        HandshakeStep(
          actor: _you,
          from: _you,
          to: _network,
          caption: (l) => l.handshakeFinish,
        ),
        HandshakeStep(
          actor: _network,
          from: _network,
          caption: (l) => l.handshakeConfirm,
        ),
      ];
    case HandshakeFlow.qr:
      // Phone to phone: the codes are the messages, the camera the way in.
      return [
        HandshakeStep(
          actor: _you,
          from: _you,
          to: _them,
          caption: (l) => l.handshakeQr1,
        ),
        HandshakeStep(
          actor: _them,
          from: _you,
          to: _them,
          caption: (l) => l.handshakeQr2,
        ),
        HandshakeStep(
          actor: _them,
          from: _them,
          to: _you,
          caption: (l) => l.handshakeQr3,
        ),
        HandshakeStep(
          actor: _you,
          from: _them,
          to: _you,
          caption: (l) => l.handshakeQr4,
        ),
        HandshakeStep(
          actor: _you,
          from: _you,
          to: _network,
          caption: (l) => l.handshakeQr5,
        ),
      ];
    case HandshakeFlow.qrReceive:
      return [
        HandshakeStep(
          actor: _them,
          from: _them,
          to: _you,
          caption: (l) => l.handshakeQrR1,
        ),
        HandshakeStep(
          actor: _you,
          from: _them,
          to: _you,
          caption: (l) => l.handshakeQrR2,
        ),
        HandshakeStep(
          actor: _you,
          from: _you,
          to: _them,
          caption: (l) => l.handshakeQrR3,
        ),
        HandshakeStep(
          actor: _them,
          from: _you,
          to: _them,
          caption: (l) => l.handshakeQrR4,
        ),
        HandshakeStep(
          actor: _them,
          from: _them,
          to: _network,
          caption: (l) => l.handshakeQrR5,
        ),
      ];
    case HandshakeFlow.payment || HandshakeFlow.request || HandshakeFlow.file:
      break;
  }
  final (out, signs, back, returned) = switch (flow) {
    HandshakeFlow.payment => (
      (AppLocalizations l) => l.handshakePay1,
      (AppLocalizations l) => l.handshakePay2,
      (AppLocalizations l) => l.handshakeBack,
      (AppLocalizations l) => l.handshakeRelayBack,
    ),
    HandshakeFlow.request => (
      (AppLocalizations l) => l.handshakeReq1,
      (AppLocalizations l) => l.handshakeReq2,
      (AppLocalizations l) => l.handshakeBack,
      (AppLocalizations l) => l.handshakeRelayBack,
    ),
    HandshakeFlow.file => (
      (AppLocalizations l) => l.handshakeFile1,
      (AppLocalizations l) => l.handshakeFile2,
      (AppLocalizations l) => l.handshakeFile3,
      (AppLocalizations l) => l.handshakeFile4,
    ),
    _ => throw StateError('handled above'),
  };
  return [
    HandshakeStep(actor: _you, from: _you, to: _relay, caption: out),
    HandshakeStep(actor: _them, from: _relay, to: _them, caption: signs),
    HandshakeStep(actor: _them, from: _them, to: _relay, caption: back),
    HandshakeStep(
      // The relay delivers; a file is opened by you.
      actor: flow == HandshakeFlow.file ? _you : _relay,
      from: _relay,
      to: _you,
      caption: returned,
    ),
    HandshakeStep(
      actor: _you,
      from: _you,
      to: _network,
      caption: (l) => l.handshakeFinish,
    ),
    HandshakeStep(
      actor: _network,
      from: _network,
      caption: (l) => l.handshakeConfirm,
    ),
  ];
}

/// How long each step plays.
const Duration handshakeStepDuration = Duration(milliseconds: 2800);

/// The caption of the step shown, for tests.
const Key handshakeCaptionKey = ValueKey('handshake-caption');

/// Opens the sheet.
Future<void> showHandshakeSheet(
  BuildContext context, {
  HandshakeFlow flow = HandshakeFlow.payment,
}) => showPhoneSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => HandshakeSheet(flow: flow),
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

  /// The QR tab's flow: the receiver's side when the sheet was opened from Receive.
  late final HandshakeFlow _qrFlow = widget.flow == HandshakeFlow.qrReceive
      ? HandshakeFlow.qrReceive
      : HandshakeFlow.qr;
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
            // One chip per way to pay, in a row that scrolls, every label the same size
            // (UP-009); the QR chip tells the side it was opened from. The chosen flow is a
            // neutral fill with the text colour: gold is the brand and the primary action,
            // never a selection.
            FadingRow(
              children: [
                for (final (i, (flow, label)) in [
                  (HandshakeFlow.payment, MethodIcons.shortName(l, MethodKind.epicbox)),
                  (HandshakeFlow.request, l.handshakeRequest),
                  (HandshakeFlow.direct, MethodIcons.familyName(l, MethodFamily.link)),
                  (_qrFlow, MethodIcons.shortName(l, MethodKind.directQr)),
                  (HandshakeFlow.file, MethodIcons.shortName(l, MethodKind.directFile)),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(label),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _flow == flow ? t.text : t.dim,
                    ),
                    selected: _flow == flow,
                    showCheckmark: false,
                    backgroundColor: t.surface,
                    selectedColor: t.selected,
                    side: BorderSide(color: _flow == flow ? t.lineStrong : t.line),
                    onSelected: (_) => _switch(flow),
                  ),
                ],
              ],
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
                  builder: (context, _) => _Diagram(
                    flow: _flow,
                    step: step,
                    progress: _progress.value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Every caption is laid out, so the sheet keeps the height of the longest one.
            Semantics(
              // Announced when the user moves it, not every few seconds while it plays.
              liveRegion: _paused || still,
              child: Stack(
                // A one-line caption is as wide as its text: keep it centred.
                alignment: Alignment.topCenter,
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

/// Where each node sits, as a share of the diagram's width and height: a diamond, the
/// relay above between the wallets and the network below.
const Map<HandshakeParty, Alignment> _place = {
  HandshakeParty.you: Alignment(-1, 0),
  HandshakeParty.relay: Alignment(0, -1),
  HandshakeParty.them: Alignment(1, 0),
  HandshakeParty.network: Alignment(0, 1),
};

/// The four nodes as labelled boxes over the painted arrows and token.
class _Diagram extends StatelessWidget {
  const _Diagram({
    required this.flow,
    required this.step,
    required this.progress,
  });

  final HandshakeFlow flow;
  final HandshakeStep step;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    String label(HandshakeParty p) => switch (p) {
      HandshakeParty.you => l.handshakeYou,
      HandshakeParty.relay =>
        flow == HandshakeFlow.file ? l.handshakeFile : l.handshakeRelay,
      HandshakeParty.them => l.handshakeThem,
      HandshakeParty.network => l.handshakeNetwork,
    };
    return SizedBox(
      height: 184,
      child: Padding(
        // Room for the lit node's halo and the network's ring.
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(
          builder: (context, box) {
            final nodeWidth = math.min(104.0, box.maxWidth * 0.24);
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
                      lanes: handshakeLanes(flow),
                    ),
                  ),
                ),
                for (final party in HandshakeParty.values)
                  if (party != HandshakeParty.relay || handshakeHasMiddle(flow))
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
    required this.lanes,
  });

  final HandshakeStep step;
  final double progress;
  final Color line, lit, halo, token, done;
  final double nodeWidth;
  final List<(HandshakeParty, HandshakeParty)> lanes;

  static const double _nodeHeight = 40;

  Offset _centre(HandshakeParty p, Size size) =>
      _place[p]!.alongSize(size) +
      // Align places the box, so its centre moves with the alignment.
      Offset(-_place[p]!.x * nodeWidth / 2, -_place[p]!.y * _nodeHeight / 2);

  /// The lane from [from] to [to], between the two boxes' edges. A pair that talks both
  /// ways gets two lanes side by side, so the arrow back is not the same line.
  (Offset, Offset) _lane(HandshakeParty from, HandshakeParty to, Size size) {
    final a = _centre(from, size), b = _centre(to, size);
    final dir = (b - a) / (b - a).distance;
    double exit(Offset d) => math.min(
      d.dx == 0 ? double.infinity : (nodeWidth / 2 + 5) / d.dx.abs(),
      d.dy == 0 ? double.infinity : (_nodeHeight / 2 + 5) / d.dy.abs(),
    );
    var start = a + dir * exit(dir), end = b - dir * exit(dir);
    if (to != HandshakeParty.network) {
      // The same side for a pair whichever way it goes: out on one lane, back on the other.
      final forward = from.index < to.index;
      final canon = forward ? dir : -dir;
      final normal = Offset(-canon.dy, canon.dx) * (forward ? 5.0 : -5.0);
      start += normal;
      end += normal;
    }
    return (start, end);
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
      old.nodeWidth != nodeWidth ||
      old.lanes != lanes;
}
