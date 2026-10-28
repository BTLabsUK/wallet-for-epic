// SPDX-License-Identifier: Apache-2.0
/// How paying by file works, told as a short looping animation in a bottom sheet: two people,
/// "You" and "Friend", and a payment file that travels between them in four steps.
///
/// Send and Receive open it from a ? next to their file controls, with the story told from
/// their side ([FileExchangeRole]). A tap on the animation pauses it; with reduced motion the
/// sheet shows the four steps as a still list.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';

/// Whose side of a file payment the help tells.
enum FileExchangeRole {
  /// The user pays: they make the file and finish with the reply.
  sender,

  /// The user gets paid: the friend makes the file and the user signs the reply.
  receiver,
}

/// Opens the payment file explainer for [role].
Future<void> showFileExchangeHelp(
  BuildContext context, {
  required FileExchangeRole role,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => FileExchangeHelp(role: role),
);

/// How long each of the four steps stays on screen.
const Duration fileHelpStepDuration = Duration(milliseconds: 2500);

const int _steps = 4;

/// The visible caption, so tests can read it among the hidden ones that hold the height.
const Key fileHelpCaptionKey = ValueKey('fileHelpCaption');

/// The tappable animation area.
const Key fileHelpAnimationKey = ValueKey('fileHelpAnimation');

/// The sheet's content. Public for the screenshot tour and tests; open it with
/// [showFileExchangeHelp].
class FileExchangeHelp extends StatefulWidget {
  const FileExchangeHelp({super.key, required this.role});

  final FileExchangeRole role;

  @override
  State<FileExchangeHelp> createState() => _FileExchangeHelpState();
}

class _FileExchangeHelpState extends State<FileExchangeHelp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: fileHelpStepDuration * _steps,
  );
  bool _paused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  /// Runs the loop unless the user paused it or the system asks for reduced motion.
  void _sync() {
    final run = !_paused && !MediaQuery.disableAnimationsOf(context);
    if (run && !_loop.isAnimating) {
      // Continues from where it stopped.
      _loop.repeat();
    } else if (!run && _loop.isAnimating) {
      _loop.stop();
    }
  }

  void _toggle() {
    setState(() => _paused = !_paused);
    _sync();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  List<String> _captions(AppLocalizations l) => switch (widget.role) {
    FileExchangeRole.sender => [
      l.fileHelpSendStep1,
      l.fileHelpSendStep2,
      l.fileHelpSendStep3,
      l.fileHelpSendStep4,
    ],
    FileExchangeRole.receiver => [
      l.fileHelpReceiveStep1,
      l.fileHelpReceiveStep2,
      l.fileHelpReceiveStep3,
      l.fileHelpReceiveStep4,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final captions = _captions(l);
    final still = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(l.fileHelpTitle, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 16),
            if (still)
              _StillSteps(captions: captions)
            else
              AnimatedBuilder(
                animation: _loop,
                builder: (context, _) => _Animated(
                  value: _loop.value,
                  payerIsYou: widget.role == FileExchangeRole.sender,
                  captions: captions,
                  paused: _paused,
                  onTap: _toggle,
                ),
              ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.commonClose),
            ),
          ],
        ),
      ),
    );
  }
}

/// One frame of the story at loop position [value] (0 to 1).
class _Animated extends StatelessWidget {
  const _Animated({
    required this.value,
    required this.payerIsYou,
    required this.captions,
    required this.paused,
    required this.onTap,
  });

  final double value;
  final bool payerIsYou;
  final List<String> captions;
  final bool paused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final step = math.min((value * _steps).floor(), _steps - 1);
    final label = theme.textTheme.labelLarge?.copyWith(color: t.dim);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          key: fileHelpAnimationKey,
          button: true,
          label: paused ? l.fileHelpPlay : l.fileHelpPause,
          onTap: onTap,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                border: Border.all(color: t.line),
                borderRadius: BorderRadius.circular(t.radiusSmall),
              ),
              child: CustomPaint(
                painter: GridFieldPainter(
                  t.text.withValues(alpha: dark ? 0.035 : 0.05),
                ),
                foregroundPainter: CornerTicksPainter(t.tick),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          paused ? Icons.play_arrow : Icons.pause,
                          size: 18,
                          color: t.dim,
                        ),
                      ),
                      CustomPaint(
                        size: const Size.fromHeight(130),
                        painter: FileExchangePainter(
                          value: value,
                          payerIsYou: payerIsYou,
                          you: t.accent,
                          friend: t.dim,
                          halo: t.accentSoft,
                          card: t.surfaceHi,
                          cardEdge: t.lineStrong,
                          ink: t.dim,
                          path: t.lineStrong,
                          signed: t.ok,
                          signedInk: t.bg,
                          coin: t.accent,
                          coinInk: t.accentInk,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Under each figure: the painter puts them at 18% and 82% of the width.
                      Row(
                        children: [
                          Expanded(
                            flex: 36,
                            child: Text(
                              l.fileHelpYou,
                              textAlign: TextAlign.center,
                              style: label,
                            ),
                          ),
                          const Spacer(flex: 28),
                          Expanded(
                            flex: 36,
                            child: Text(
                              l.fileHelpFriend,
                              textAlign: TextAlign.center,
                              style: label,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Every caption is laid out, so the sheet keeps the height of the longest one.
        Stack(
          children: [
            for (var i = 0; i < captions.length; i++)
              Visibility(
                visible: i == step,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Text(
                  captions[i],
                  key: i == step ? fileHelpCaptionKey : null,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _Dots(step: step),
      ],
    );
  }
}

/// Which of the four steps is showing, as dots with the current one drawn long.
class _Dots extends StatelessWidget {
  const _Dots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: context.l10n.fileHelpStepOf(step + 1, _steps),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _steps; i++)
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
      ),
    );
  }
}

/// Reduced motion: the four steps, numbered, one under the other.
class _StillSteps extends StatelessWidget {
  const _StillSteps({required this.captions});

  final List<String> captions;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < captions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: context.l10n.fileHelpStepOf(i + 1, captions.length),
                    excludeSemantics: true,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.accentSoft,
                        border: Border.all(color: t.accent),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: t.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        captions[i],
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The scene at loop position [value]: You on the left, Friend on the right, and the file.
///
/// Per step, with the payer P and the payee Q: (1) the file appears at P; (2) it travels to Q;
/// (3) Q signs it (a tick) and it travels back; (4) the file goes and a coin travels from P to
/// Q. The person acting in the step stands in a soft halo.
class FileExchangePainter extends CustomPainter {
  const FileExchangePainter({
    required this.value,
    required this.payerIsYou,
    required this.you,
    required this.friend,
    required this.halo,
    required this.card,
    required this.cardEdge,
    required this.ink,
    required this.path,
    required this.signed,
    required this.signedInk,
    required this.coin,
    required this.coinInk,
  });

  final double value;
  final bool payerIsYou;
  final Color you, friend, halo, card, cardEdge, ink, path;
  final Color signed, signedInk, coin, coinInk;

  /// Figure centres as a share of the width; the labels under the canvas match them.
  static const double leftX = 0.18, rightX = 0.82;

  static double _phase(double t, double from, double to) =>
      Curves.easeInOutCubic.transform(((t - from) / (to - from)).clamp(0, 1));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final step = math.min((value * _steps).floor(), _steps - 1);
    final t = value * _steps - step;

    final left = Offset(w * leftX, h), right = Offset(w * rightX, h);
    final payer = payerIsYou ? left : right;
    final payee = payerIsYou ? right : left;
    final actor = step == 2 ? payee : payer;

    // Where a file rests: above the person's shoulder, on the side facing the other one.
    final lane = h * 0.32;
    Offset rest(Offset person) =>
        Offset(person.dx + (person == left ? 1 : -1) * w * 0.15, lane);
    Offset arc(Offset a, Offset b, double p) =>
        Offset.lerp(a, b, p)! - Offset(0, h * 0.16 * math.sin(math.pi * p));

    _path(canvas, rest(left), rest(right));
    _person(canvas, left, h, you, lit: actor == left);
    _person(canvas, right, h, friend, lit: actor == right);

    switch (step) {
      case 0:
        final p = _phase(t, 0, 0.45);
        _file(
          canvas,
          rest(payer),
          h,
          scale: 0.6 + 0.4 * p,
          opacity: p,
          lines: _phase(t, 0.3, 0.8),
        );
      case 1:
        _file(canvas, arc(rest(payer), rest(payee), _phase(t, 0.15, 0.85)), h);
      case 2:
        final back = _phase(t, 0.45, 0.9);
        _file(
          canvas,
          arc(rest(payee), rest(payer), back),
          h,
          tick: _phase(t, 0.05, 0.35),
        );
      default:
        final fade = 1 - _phase(t, 0, 0.3);
        if (fade > 0) {
          _file(canvas, rest(payer), h, tick: 1, opacity: fade, scale: fade);
        }
        final travel = _phase(t, 0.2, 0.8);
        final show = _phase(t, 0.15, 0.3) * (1 - _phase(t, 0.88, 1));
        _coin(canvas, arc(rest(payer), rest(payee), travel), h, show);
    }
  }

  /// A dotted line between the two resting places: the way the file goes.
  void _path(Canvas canvas, Offset a, Offset b) {
    final dot = Paint()..color = path;
    const gap = 9.0;
    final n = ((b.dx - a.dx).abs() / gap).floor();
    // Too narrow for one gap: i / n would be NaN.
    if (n == 0) return;
    for (var i = 0; i <= n; i++) {
      canvas.drawCircle(Offset.lerp(a, b, i / n)!, 1.2, dot);
    }
  }

  /// A rounded figure standing on [foot]: a head and the shoulders.
  void _person(
    Canvas canvas,
    Offset foot,
    double h,
    Color color, {
    required bool lit,
  }) {
    final r = h * 0.14;
    final head = Offset(foot.dx, foot.dy - h * 0.62);
    if (lit) {
      canvas.drawCircle(
        Offset(foot.dx, foot.dy - h * 0.42),
        h * 0.42,
        Paint()..color = halo,
      );
    }
    final fill = Paint()..color = color;
    canvas.drawCircle(head, r, fill);
    final body = RRect.fromRectAndCorners(
      Rect.fromLTRB(
        foot.dx - r * 1.6,
        head.dy + r * 1.35,
        foot.dx + r * 1.6,
        foot.dy,
      ),
      topLeft: Radius.circular(r * 1.5),
      topRight: Radius.circular(r * 1.5),
      bottomLeft: Radius.circular(r * 0.3),
      bottomRight: Radius.circular(r * 0.3),
    );
    canvas.drawRRect(body, fill);
  }

  /// The payment file: a card with a folded corner and text lines; [tick] (0 to 1) grows the
  /// signed mark on it, [lines] (0 to 1) writes the lines.
  void _file(
    Canvas canvas,
    Offset centre,
    double h, {
    double scale = 1,
    double opacity = 1,
    double tick = 0,
    double lines = 1,
  }) {
    if (opacity <= 0 || scale <= 0) return;
    final cw = h * 0.24 * scale, ch = h * 0.3 * scale;
    final rect = Rect.fromCenter(center: centre, width: cw, height: ch);
    final fold = cw * 0.3;
    final shape = Path()
      ..moveTo(rect.left, rect.top + 3)
      ..quadraticBezierTo(rect.left, rect.top, rect.left + 3, rect.top)
      ..lineTo(rect.right - fold, rect.top)
      ..lineTo(rect.right, rect.top + fold)
      ..lineTo(rect.right, rect.bottom - 3)
      ..quadraticBezierTo(rect.right, rect.bottom, rect.right - 3, rect.bottom)
      ..lineTo(rect.left + 3, rect.bottom)
      ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - 3)
      ..close();
    Color a(Color c) => c.withValues(alpha: c.a * opacity);
    canvas.drawPath(shape, Paint()..color = a(card));
    final edge = Paint()
      ..color = a(cardEdge)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(shape, edge);
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - fold, rect.top)
        ..lineTo(rect.right - fold, rect.top + fold)
        ..lineTo(rect.right, rect.top + fold),
      edge,
    );
    final line = Paint()
      ..color = a(ink)
      ..strokeWidth = math.max(1.5, ch * 0.06)
      ..strokeCap = StrokeCap.round;
    final x0 = rect.left + cw * 0.2;
    for (final (i, length) in [0.45, 0.6, 0.4].indexed) {
      final drawn = ((lines * 3) - i).clamp(0.0, 1.0);
      if (drawn == 0) continue;
      final y = rect.top + ch * (0.42 + i * 0.18);
      canvas.drawLine(Offset(x0, y), Offset(x0 + cw * length * drawn, y), line);
    }
    if (tick > 0) {
      final r = cw * 0.24 * Curves.easeOutBack.transform(tick);
      final c = Offset(rect.right - cw * 0.05, rect.bottom - ch * 0.05);
      canvas.drawCircle(c, r, Paint()..color = a(signed));
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - r * 0.45, c.dy)
          ..lineTo(c.dx - r * 0.1, c.dy + r * 0.38)
          ..lineTo(c.dx + r * 0.48, c.dy - r * 0.35),
        Paint()
          ..color = a(signedInk)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, r * 0.28)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  /// The payment itself, once the reply is opened: a coin with an inner ring.
  void _coin(Canvas canvas, Offset centre, double h, double opacity) {
    if (opacity <= 0) return;
    final r = h * 0.1;
    canvas.drawCircle(
      centre,
      r,
      Paint()..color = coin.withValues(alpha: coin.a * opacity),
    );
    canvas.drawCircle(
      centre,
      r * 0.62,
      Paint()
        ..color = coinInk.withValues(alpha: 0.45 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(FileExchangePainter old) =>
      old.value != value ||
      old.payerIsYou != payerIsYou ||
      old.you != you ||
      old.friend != friend ||
      old.halo != halo ||
      old.card != card ||
      old.cardEdge != cardEdge ||
      old.ink != ink ||
      old.path != path ||
      old.signed != signed ||
      old.signedInk != signedInk ||
      old.coin != coin ||
      old.coinInk != coinInk;
}
