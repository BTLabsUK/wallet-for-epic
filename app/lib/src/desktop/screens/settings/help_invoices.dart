import 'package:flutter/material.dart';

import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'help_topics.dart';

/// Help › Invoices: shown when the wallet supports invoices, before "When something goes wrong".
const invoiceHelpSection = 'invoices';

/// Opens Help at a section: scrolls to it and opens its first topic.
class HelpAt {
  const HelpAt(this.section, {this.topic = 0});

  final String section;

  /// Which topic of the section opens.
  final int topic;

  @override
  bool operator ==(Object other) => other is HelpAt && other.section == section && other.topic == topic;

  @override
  int get hashCode => Object.hash(section, topic);
}

String invoiceHelpTitle(AppLocalizations l) => l.deskInvHelpTitle;
String invoiceHelpLede(AppLocalizations l) => l.deskInvHelpLede;

/// The three invoice topics, with [confirmations] as the open wallet counts them.
List<HelpTopic> invoiceHelpTopics(AppLocalizations l, int confirmations) => [
  HelpTopic(
    invoiceHelpSection,
    l.deskInvHelpFlowTitle,
    l.deskInvHelpFlowShort,
    [
      HelpBlock.p(l.deskInvHelpFlowIntro),
      HelpBlock.ol([l.deskInvHelpFlowStep1, l.deskInvHelpFlowStep2, l.deskInvHelpFlowStep3, l.deskInvHelpFlowStep4(confirmations)]),
      HelpBlock.p(l.deskInvHelpFlowNever),
      HelpBlock.p(l.deskInvHelpFlowIssued),
    ],
    invoiceFlow: true,
  ),
  HelpTopic(invoiceHelpSection, l.deskInvHelpTrustTitle, l.deskInvHelpTrustShort, [
    HelpBlock.p(l.deskInvHelpTrustP1),
    HelpBlock.p(l.deskInvHelpTrustP2),
    HelpBlock.p(l.deskInvHelpTrustP3),
    HelpBlock.ul([l.deskInvHelpTrustWhere1, l.deskInvHelpTrustWhere2, l.deskInvHelpTrustWhere3]),
  ]),
  HelpTopic(invoiceHelpSection, l.deskInvHelpAddrTitle, l.deskInvHelpAddrShort, [
    HelpBlock.p(l.deskInvHelpAddrP1),
    HelpBlock.p(l.deskInvHelpAddrP2),
    HelpBlock.p(l.deskInvHelpAddrP3),
    HelpBlock.ul([l.deskInvHelpAddrWhere1, l.deskInvHelpAddrWhere2]),
  ]),
];

/// The invoice flow: issuer and payer, the invoice through the trusted-only invoice address, the
/// payment back to the payments address, the issuer finalizing. Side by side when there is room,
/// one column under 560 px.
class InvoiceFlowDiagram extends StatelessWidget {
  const InvoiceFlowDiagram({super.key, required this.confirmations});

  final int confirmations;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final issues = _Node(icon: EIcons.invoice, title: l.deskInvHelpDiagramIssues);
    final gate = _Node(icon: EIcons.invoiceAddress, title: l.deskInvHelpDiagramGate, sub: l.deskInvHelpDiagramGateSub, gate: true);
    final dropped = _Node(icon: EIcons.closeCircle, title: l.deskInvHelpDiagramDropped, sub: l.deskInvHelpDiagramDroppedSub, dropped: true);
    final review = _Node(icon: EIcons.check, title: l.deskInvHelpDiagramReview, sub: l.deskInvHelpDiagramReviewSub, step: 2);
    final payAddr = _Node(icon: EIcons.receive, title: l.deskInvHelpDiagramPayAddr, sub: l.deskInvHelpDiagramPayAddrSub);
    final finalize = _Node(icon: EIcons.node, title: l.deskInvHelpDiagramFinal, sub: l.deskInvHelpDiagramFinalSub(confirmations), step: 4);
    return Semantics(
      container: true,
      label: l.deskInvHelpDiagramSemantics,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.all(Sp.x4),
          decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 560.u;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.deskInvHelpDiagramTitle, style: ts.label),
                  SizedBox(height: Sp.x4),
                  if (wide) ...[
                    _row(_Lane(EIcons.user, l.deskInvHelpDiagramIssuer), const SizedBox(), _Lane(EIcons.wallet, l.deskInvHelpDiagramPayer)),
                    SizedBox(height: Sp.x2),
                    _row(issues, _Arrow(label: l.deskInvHelpDiagramInvoice, step: 1), gate),
                    SizedBox(height: Sp.x2),
                    _row(const SizedBox(), Padding(padding: EdgeInsets.symmetric(horizontal: Sp.x2), child: dropped), _Down(height: 28.u)),
                    SizedBox(height: Sp.x2),
                    _row(payAddr, _Arrow(label: l.deskInvHelpDiagramPayment, step: 3, back: true), review),
                    _row(_Down(height: 22.u), const SizedBox(), const SizedBox()),
                    _row(finalize, const SizedBox(), const SizedBox()),
                  ] else ...[
                    _Lane(EIcons.user, l.deskInvHelpDiagramIssuer),
                    SizedBox(height: Sp.x2),
                    issues,
                    _Down(label: l.deskInvHelpDiagramInvoice, step: 1),
                    _Lane(EIcons.wallet, l.deskInvHelpDiagramPayer),
                    SizedBox(height: Sp.x2),
                    gate,
                    SizedBox(height: Sp.x2),
                    dropped,
                    _Down(height: 22.u),
                    review,
                    _Down(label: l.deskInvHelpDiagramPayment, step: 3),
                    _Lane(EIcons.user, l.deskInvHelpDiagramIssuer),
                    SizedBox(height: Sp.x2),
                    payAddr,
                    _Down(height: 22.u),
                    finalize,
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Issuer lane, the arrows between, payer lane.
  Widget _row(Widget issuer, Widget middle, Widget payer, {CrossAxisAlignment align = CrossAxisAlignment.center}) => Row(
    crossAxisAlignment: align,
    children: [
      Expanded(flex: 5, child: issuer),
      Expanded(flex: 4, child: middle),
      Expanded(flex: 5, child: payer),
    ],
  );
}

/// A lane's head: Issuer or Payer.
class _Lane extends StatelessWidget {
  const _Lane(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Row(
      children: [
        Icon(icon, size: 14.u, color: c.dim),
        SizedBox(width: Sp.x1),
        Flexible(child: Text(label.toUpperCase(), style: context.ts.mono(size: Fs.xs, color: c.dim))),
      ],
    );
  }
}

/// A box of the flow. [gate]: the invoice address, outlined in the accent. [dropped]: a sender
/// the gate turns away, dashed and faint.
class _Node extends StatelessWidget {
  const _Node({required this.icon, required this.title, this.sub, this.step, this.gate = false, this.dropped = false});

  final IconData icon;
  final String title;
  final String? sub;
  final int? step;
  final bool gate, dropped;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: 10.u),
      child: Row(
        children: [
          Icon(icon, size: 18.u, color: gate ? c.accent : (dropped ? c.faint : c.dim)),
          SizedBox(width: Sp.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ts.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: dropped ? c.dim : c.text,
                    decoration: dropped ? TextDecoration.lineThrough : null,
                    decorationColor: c.dim,
                  ),
                ),
                if (sub != null) Text(sub!, style: ts.small.copyWith(color: gate ? c.accentText : c.dim)),
              ],
            ),
          ),
          if (step != null) ...[SizedBox(width: Sp.x2), _Step(step!)],
        ],
      ),
    );
    final radius = BorderRadius.circular(Rad.sm);
    if (dropped) {
      return CustomPaint(
        painter: _Dashed(color: c.lineStrong, radius: Rad.sm),
        child: content,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: c.s1,
        border: Border.all(color: gate ? c.accent : c.lineStrong, width: gate ? 1.5 : 1),
        borderRadius: radius,
      ),
      child: content,
    );
  }
}

/// A step's number in a ring.
class _Step extends StatelessWidget {
  const _Step(this.n);

  final int n;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      width: 20.u,
      height: 20.u,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.accent)),
      child: Text('$n', style: TextStyle(fontSize: 11.u, fontWeight: FontWeight.w700, color: c.accentText, height: 1)),
    );
  }
}

/// A sideways arrow between the lanes, with its step and label above it.
class _Arrow extends StatelessWidget {
  const _Arrow({required this.label, required this.step, this.back = false});

  final String label;
  final int step;

  /// Points from the payer back to the issuer.
  final bool back;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Step(step),
              SizedBox(width: Sp.x1),
              Flexible(child: Text(label, style: context.ts.mono(size: Fs.xs, color: c.text), overflow: TextOverflow.ellipsis)),
            ],
          ),
          SizedBox(height: Sp.x1),
          SizedBox(height: 10.u, width: double.infinity, child: CustomPaint(painter: _ArrowLine(color: c.accent, back: back))),
        ],
      ),
    );
  }
}

/// A downward link inside a lane; with [label], a numbered step of the one-column layout.
class _Down extends StatelessWidget {
  const _Down({this.label, this.step, this.height});

  final String? label;
  final int? step;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final line = SizedBox(width: 12.u, height: height ?? 40.u, child: CustomPaint(painter: _ArrowLine(color: label == null ? c.dim : c.accent, down: true)));
    if (label == null) return Padding(padding: EdgeInsets.only(left: 20.u), child: Align(alignment: Alignment.centerLeft, child: line));
    return Padding(
      padding: EdgeInsets.only(left: 20.u),
      child: Row(
        children: [
          line,
          SizedBox(width: Sp.x3),
          _Step(step!),
          SizedBox(width: Sp.x1),
          Flexible(child: Text(label!, style: context.ts.mono(size: Fs.xs, color: c.text))),
        ],
      ),
    );
  }
}

class _ArrowLine extends CustomPainter {
  const _ArrowLine({required this.color, this.back = false, this.down = false});

  final Color color;
  final bool back, down;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const head = 4.0;
    if (down) {
      final x = size.width / 2;
      canvas.drawLine(Offset(x, 2), Offset(x, size.height - 2), p);
      canvas.drawPath(Path()..moveTo(x - head, size.height - 2 - head)..lineTo(x, size.height - 2)..lineTo(x + head, size.height - 2 - head), p);
      return;
    }
    final y = size.height / 2;
    final a = back ? size.width - 2 : 2.0, b = back ? 2.0 : size.width - 2;
    final d = back ? head : -head;
    canvas.drawLine(Offset(a, y), Offset(b, y), p);
    canvas.drawPath(Path()..moveTo(b + d, y - head)..lineTo(b, y)..lineTo(b + d, y + head), p);
  }

  @override
  bool shouldRepaint(_ArrowLine old) => old.color != color || old.back != back || old.down != down;
}

/// A dashed rounded outline: the sender the gate drops.
class _Dashed extends CustomPainter {
  const _Dashed({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.5));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 4), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashed old) => old.color != color;
}

/// The invoices section's art, 160 × 96 scaled like HelpArt: a bill (dim) travels on the accent
/// path to an address box with a tick; a crossed sender stays outside.
class InvoiceHelpMark extends StatelessWidget {
  const InvoiceHelpMark({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: width * 96 / 160,
        child: CustomPaint(painter: _MarkPainter(dim: c.dim, accent: c.accent, fill: c.s1)),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.dim, required this.accent, required this.fill});

  final Color dim, accent, fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 160);
    Paint stroke(Color color) => Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final d = stroke(dim), a = stroke(accent);
    // The bill: a page with a folded corner and lines.
    final bill = Path()
      ..moveTo(18, 20)
      ..lineTo(42, 20)
      ..lineTo(50, 28)
      ..lineTo(50, 66)
      ..lineTo(18, 66)
      ..close();
    canvas.drawPath(bill, Paint()..color = fill);
    canvas.drawPath(bill, d);
    canvas.drawPath(Path()..moveTo(42, 20)..lineTo(42, 28)..lineTo(50, 28), d);
    for (final y in [36.0, 44.0, 52.0]) {
      canvas.drawLine(Offset(25, y), Offset(y == 52 ? 35 : 43, y), d);
    }
    // The accent path to the invoice address.
    for (var x = 58.0; x < 92; x += 7) {
      canvas.drawLine(Offset(x, 43), Offset(x + 3, 43), a);
    }
    canvas.drawPath(Path()..moveTo(91, 39)..lineTo(95, 43)..lineTo(91, 47), a);
    // The invoice address: a box with a tick.
    final box = RRect.fromLTRBR(102, 26, 142, 60, const Radius.circular(5));
    canvas.drawRRect(box, Paint()..color = fill);
    canvas.drawRRect(box, d);
    canvas.drawPath(Path()..moveTo(113, 43)..lineTo(119, 49)..lineTo(131, 37), a);
    // A sender outside, crossed out.
    canvas.drawCircle(const Offset(70, 64), 6, d);
    canvas.drawLine(const Offset(80, 60), const Offset(88, 68), d);
    canvas.drawLine(const Offset(88, 60), const Offset(80, 68), d);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.dim != dim || old.accent != accent || old.fill != fill;
}
