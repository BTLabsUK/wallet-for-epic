// SPDX-License-Identifier: Apache-2.0
/// The local node's fit check: two questions (how long the wallet is open, whether the
/// connection is metered) and the disk space, then a verdict. Shown when the local node is
/// picked in Settings › Node, and from Help. The node runs only while the app is open; nothing
/// here may say otherwise.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/desk_node.dart';
import '../../data/node_fit_facts.dart';
import '../../data/node_view.dart' show bytesText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// How long the wallet is usually open: the first question.
enum FitOpen { day, hours, minutes }

/// The answer [hoursPerDay] suggests; an hour or two when it is not known.
FitOpen fitOpenOf(double? hoursPerDay) => switch (hoursPerDay) {
  null => FitOpen.hours,
  < 1 / 3 => FitOpen.minutes,
  < 3 => FitOpen.hours,
  _ => FitOpen.day,
};

enum FitVerdict { good, wait, public, metered, noSpace }

/// The verdict for the answers: too little space first, then short visits, then a metered
/// connection, then how long the wallet is open.
FitVerdict fitVerdict({required FitOpen open, required bool metered, bool? enoughSpace}) {
  if (enoughSpace == false) return FitVerdict.noSpace;
  if (open == FitOpen.minutes) return FitVerdict.public;
  if (metered) return FitVerdict.metered;
  return open == FitOpen.day ? FitVerdict.good : FitVerdict.wait;
}

/// Whether [v] advises the local node: its main button starts it. Otherwise the main
/// button keeps the current node and starting it is the second choice.
bool fitStarts(FitVerdict v) => v != FitVerdict.public && v != FitVerdict.noSpace;

/// Settings › Node's argument from Help's fit check: start the local node, the check done.
class NodeFitStart {
  const NodeFitStart();
}

/// Opens the fit check. True: start the local node; false or null: keep the current node.
/// [inUse]: the local node already runs (from Help), so the check only informs.
Future<bool?> showNodeFitCheck(BuildContext context, {bool inUse = false}) =>
    showEDialog<bool>(context, builder: (_) => NodeFitDialog(inUse: inUse));

class NodeFitDialog extends ConsumerStatefulWidget {
  const NodeFitDialog({super.key, this.inUse = false});

  final bool inUse;

  @override
  ConsumerState<NodeFitDialog> createState() => _NodeFitDialogState();
}

class _NodeFitDialogState extends ConsumerState<NodeFitDialog> {
  FitOpen _open = FitOpen.hours;
  bool _metered = false;
  bool _openTouched = false;
  bool _netTouched = false;
  double? _hours;
  bool? _windowsMetered;
  LocalNodeFacts? _facts;
  bool _skip = false;

  @override
  void initState() {
    super.initState();
    final fit = ref.read(nodeFitFactsProvider);
    fit.hoursPerDay().then((h) {
      if (!mounted) return;
      setState(() {
        _hours = h;
        if (!_openTouched) _open = fitOpenOf(h);
      });
    }, onError: (_) {});
    fit.metered().then((m) {
      if (!mounted) return;
      setState(() {
        _windowsMetered = m;
        if (!_netTouched && m != null) _metered = m;
      });
    }, onError: (_) {});
    ref.read(deskNodeProvider).facts().then((f) {
      if (mounted) setState(() => _facts = f);
    }, onError: (_) {});
  }

  int get _chain => _facts?.chainBytes ?? mainnetChainBytesEstimate;

  Future<void> _close(bool start) async {
    if (_skip) await ref.read(nodeFitFactsProvider).setSkip(true);
    if (mounted) Navigator.of(context).pop(start);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final verdict = fitVerdict(open: _open, metered: _metered, enoughSpace: _facts?.enoughSpace);
    final starts = fitStarts(verdict);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return EDialog(
      size: DialogWidth.wide,
      icon: EIcons.node,
      title: l.deskNodeFitTitle,
      description: l.deskNodeFitDescription,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FitStage(open: _open, metered: _metered, download: bytesText(_chain, l)),
          SizedBox(height: Sp.x3),
          ExpandFade(
            open: _facts != null,
            child: Padding(padding: EdgeInsets.only(bottom: Sp.x3), child: _facts == null ? const SizedBox.shrink() : _DiskLine(facts: _facts!)),
          ),
          // The verdict under the picture and the disk, in view while the answers below change it.
          Semantics(
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: reduce ? Duration.zero : Motion.cross,
              child: KeyedSubtree(key: ValueKey(verdict), child: _verdictNotice(l, verdict)),
            ),
          ),
          SizedBox(height: Sp.x4),
          _Question(
            label: l.deskNodeFitOpenQ,
            hint: switch (_hours) {
              null => null,
              < 1 => l.deskNodeFitOpenHintUnder,
              final h => l.deskNodeFitOpenHint(h.round()),
            },
            hintIcon: EIcons.clock,
            child: ESegmented<FitOpen>(
              size: EBtnSize.sm,
              stretch: true,
              shrink: true,
              value: _open,
              segments: [
                ESegment(FitOpen.day, l.deskNodeFitOpenDay),
                ESegment(FitOpen.hours, l.deskNodeFitOpenHours),
                ESegment(FitOpen.minutes, l.deskNodeFitOpenMinutes),
              ],
              onChanged: (v) => setState(() {
                _open = v;
                _openTouched = true;
              }),
            ),
          ),
          SizedBox(height: Sp.x3),
          _Question(
            label: l.deskNodeFitNetQ,
            hint: switch (_windowsMetered) {
              null => null,
              true => l.deskNodeFitNetHintMetered,
              false => l.deskNodeFitNetHintFree,
            },
            hintIcon: EIcons.web,
            child: ESegmented<bool>(
              size: EBtnSize.sm,
              stretch: true,
              shrink: true,
              value: _metered,
              segments: [ESegment(false, l.deskNodeFitNetFree), ESegment(true, l.deskNodeFitNetMetered)],
              onChanged: (v) => setState(() {
                _metered = v;
                _netTouched = true;
              }),
            ),
          ),
        ],
      ),
      foot: widget.inUse
          ? Text(l.deskNodeFitInUse, style: context.ts.small)
          : ECheckbox(value: _skip, label: l.deskNodeFitDontShow, onChanged: (v) => setState(() => _skip = v)),
      actions: widget.inUse
          ? [EButton.primary(label: l.commonClose, autofocus: true, onPressed: () => Navigator.of(context).pop(false))]
          : starts
          ? [EButton(label: l.deskNodeFitNotNow, onPressed: () => _close(false)), EButton.primary(label: l.deskNodeFitStart, onPressed: () => _close(true))]
          : [EButton(label: l.deskNodeFitStartAnyway, onPressed: () => _close(true)), EButton.primary(label: l.deskNodeFitKeepPublic, onPressed: () => _close(false))],
    );
  }

  Widget _verdictNotice(AppLocalizations l, FitVerdict v) {
    final floor = _facts?.minFreeBytes ?? 0;
    return switch (v) {
      FitVerdict.good => ENotice(tone: ETone.ok, icon: EIcons.okCircle, title: l.deskNodeFitGood, text: l.deskNodeFitGoodText),
      FitVerdict.wait => ENotice(tone: ETone.ok, icon: EIcons.okCircle, title: l.deskNodeFitWait, text: l.deskNodeFitWaitText),
      FitVerdict.public => ENotice(icon: EIcons.server, title: l.deskNodeFitPublic, text: l.deskNodeFitPublicText),
      FitVerdict.metered => ENotice(tone: ETone.warn, icon: EIcons.download, title: l.deskNodeFitMetered, text: l.deskNodeFitMeteredText(bytesText(_chain, l))),
      FitVerdict.noSpace => ENotice(tone: ETone.warn, title: l.deskNodeFitNoSpace, text: l.deskNodeFitNoSpaceText(bytesText(_chain, l), bytesText(floor, l))),
    };
  }
}

/// A question's label with its hint (what this computer suggests), over its control.
class _Question extends StatelessWidget {
  const _Question({required this.label, required this.hint, required this.hintIcon, required this.child});

  final String label;
  final String? hint;
  final IconData hintIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Sp.x3,
            runSpacing: Sp.x1,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              ExcludeSemantics(child: Text(label, style: ts.strong)),
              if (hint != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(hintIcon, size: 14.u, color: c.faint),
                    SizedBox(width: Sp.x1),
                    Text(hint!, style: ts.small),
                  ],
                ),
            ],
          ),
          SizedBox(height: Sp.x2),
          child,
        ],
      ),
    );
  }
}

/// Free space and the chain's size, and chain data found on this computer.
class _DiskLine extends StatelessWidget {
  const _DiskLine({required this.facts});

  final LocalNodeFacts facts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final chain = bytesText(facts.chainBytes, l);
    final free = facts.freeBytes;
    final enough = facts.enoughSpace;
    final found = facts.reusable.isEmpty ? null : facts.reusable.map((r) => r.bytes).reduce(math.max);
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(EIcons.folder, size: Ctl.icon, color: c.dim),
          SizedBox(width: Sp.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: l.deskNodeFitDisk, style: ts.strong),
                      const TextSpan(text: '  ·  '),
                      TextSpan(text: free == null ? l.deskNodeFitDiskUnknown(chain) : l.deskNodeFitDiskFree(bytesText(free, l), chain)),
                    ],
                  ),
                  style: ts.bodyDim,
                ),
                if (found != null && found > 0) ...[SizedBox(height: Sp.x1), Text(l.deskNodeFitFound(bytesText(found, l)), style: ts.small)],
              ],
            ),
          ),
          if (enough != null) ...[
            SizedBox(width: Sp.x3),
            Icon(enough ? EIcons.okCircle : EIcons.alert, size: Ctl.icon, color: enough ? c.ok : c.warn),
          ],
        ],
    );
  }
}

/// The picture: this computer's node in a ring of peers. The ring shows how much of the open
/// time the node is in sync (green) and catching up (striped amber); a few blocks travel out to
/// the peers once when the answer changes. [metered] shows the first download's size.
class FitStage extends StatefulWidget {
  const FitStage({super.key, required this.open, required this.metered, required this.download});

  final FitOpen open;
  final bool metered;
  final String download;

  /// The ring's in-sync share for [open].
  static double ringOf(FitOpen open) => switch (open) {
    FitOpen.day => 0.95,
    FitOpen.hours => 0.58,
    FitOpen.minutes => 0.08,
  };

  @override
  State<FitStage> createState() => _FitStageState();
}

class _FitStageState extends State<FitStage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(FitStage old) {
    super.didUpdateWidget(old);
    if (old.open != widget.open) _run();
  }

  /// One round of blocks going out, never a loop; none with reduced motion.
  void _run() {
    if (MediaQuery.disableAnimationsOf(context) || widget.open == FitOpen.minutes) {
      _pulse.value = 0;
      return;
    }
    _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final open = widget.open;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final (cap, sub) = switch (open) {
      FitOpen.day => (l.deskNodeFitCapDay, l.deskNodeFitCapDaySub),
      FitOpen.hours => (l.deskNodeFitCapHours, l.deskNodeFitCapHoursSub),
      FitOpen.minutes => (l.deskNodeFitCapMinutes, l.deskNodeFitCapMinutesSub),
    };
    final chips = switch (open) {
      FitOpen.day => (true, true, true),
      FitOpen.hours => (true, false, false),
      FitOpen.minutes => (false, false, false),
    };
    final side = 120.u;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
      decoration: BoxDecoration(color: c.s1, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.lineStrong)),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: side,
                  height: side,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: FitStage.ringOf(open)),
                    duration: reduce ? Duration.zero : Motion.expand,
                    curve: Motion.easeOut,
                    builder: (context, ring, _) => Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _StagePainter(
                              ring: ring,
                              pulse: _pulse,
                              blocks: switch (open) {
                                FitOpen.day => 6,
                                FitOpen.hours => 2,
                                FitOpen.minutes => 0,
                              },
                              dim: open == FitOpen.minutes,
                              colors: c,
                            ),
                          ),
                        ),
                        Icon(EIcons.monitor, size: Ctl.iconLg, color: c.text),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: side,
                  child: Text(l.deskNodeFitThisComputer, style: ts.caption, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          SizedBox(width: Sp.x5),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(liveRegion: true, child: Text(cap, style: ts.strong)),
                Text(sub, style: ts.small),
                SizedBox(height: Sp.x3),
                Wrap(
                  spacing: Sp.x2,
                  runSpacing: Sp.x2,
                  children: [
                    _Chip(icon: EIcons.lock, label: l.deskNodeFitChipPrivate, on: chips.$1),
                    _Chip(icon: EIcons.network, label: l.deskNodeFitChipNetwork, on: chips.$2),
                    _Chip(icon: EIcons.sync, label: l.deskNodeFitChipInSync, on: chips.$3),
                    if (widget.metered) _Chip(icon: EIcons.download, label: l.deskNodeFitDownload(widget.download), on: true, warn: true),
                  ],
                ),
                SizedBox(height: Sp.x3),
                ExcludeSemantics(
                  child: Wrap(
                    spacing: Sp.x4,
                    children: [
                      _Legend(color: c.ok, label: l.deskNodeFitInSync),
                      _Legend(color: c.warn, label: l.deskNodeFitCatchingUp, striped: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A tag in the picture: lit when it applies to the answer, faint when not.
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.on, this.warn = false});

  final IconData icon;
  final String label;
  final bool on;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final fg = warn ? c.warn : (on ? c.ok : c.faint);
    return Semantics(
      label: label,
      // Off: what the local node does not bring with this answer.
      enabled: on,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Dur.base,
        padding: EdgeInsets.symmetric(horizontal: Sp.x2, vertical: 3.u),
        decoration: BoxDecoration(
          color: on ? (warn ? c.warnSoft : c.okSoft) : Colors.transparent,
          borderRadius: BorderRadius.circular(Rad.xs),
          border: Border.all(color: on ? fg.withValues(alpha: 0.4) : c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.u, color: fg),
            SizedBox(width: Sp.x1),
            Flexible(child: Text(label, style: context.ts.caption.copyWith(color: on ? c.text : c.faint))),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.striped = false});

  final Color color;
  final String label;
  final bool striped;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10.u,
        height: 10.u,
        decoration: BoxDecoration(
          color: striped ? null : color,
          gradient: striped
              ? LinearGradient(
                  colors: [color, color, context.dc.warnSoft, context.dc.warnSoft],
                  stops: const [0, 0.5, 0.5, 1],
                  tileMode: TileMode.repeated,
                  begin: Alignment.topLeft,
                  end: const Alignment(-0.4, -0.4),
                )
              : null,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      SizedBox(width: Sp.x1),
      Text(label, style: context.ts.caption),
    ],
  );
}

class _StagePainter extends CustomPainter {
  _StagePainter({required this.ring, required this.pulse, required this.blocks, required this.dim, required this.colors}) : super(repaint: pulse);

  final double ring;
  final Animation<double> pulse;
  final int blocks;
  final bool dim;
  final DeskColors colors;

  static const _peers = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final c = colors;
    final o = size.center(Offset.zero);
    final s = size.shortestSide / 2;
    final peerR = s * 0.86;
    final ringR = s * 0.5;
    final stroke = s * 0.09;
    final dot = s * 0.065;
    final fade = dim ? 0.45 : 1.0;
    Offset at(double r, int i) {
      final a = -math.pi / 2 + i * 2 * math.pi / _peers;
      return o + Offset(math.cos(a), math.sin(a)) * r;
    }

    final line = Paint()
      ..color = c.lineStrong.withValues(alpha: c.lineStrong.a * fade)
      ..strokeWidth = 1;
    final peerFill = Paint()..color = c.s3.withValues(alpha: fade);
    final peerEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = c.dim.withValues(alpha: 0.6 * fade);
    for (var i = 0; i < _peers; i++) {
      canvas.drawLine(at(ringR + stroke, i), at(peerR - dot, i), line);
      canvas.drawCircle(at(peerR, i), dot, peerFill);
      canvas.drawCircle(at(peerR, i), dot, peerEdge);
    }

    // Catching up: amber stripes all round, under the in-sync share.
    final rect = Rect.fromCircle(center: o, radius: ringR);
    final band = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const stripes = 48;
    for (var i = 0; i < stripes; i++) {
      band.color = i.isEven ? c.warn : c.warnSoft;
      canvas.drawArc(rect, i * 2 * math.pi / stripes, 2 * math.pi / stripes, false, band);
    }
    if (ring > 0) {
      band.color = c.ok;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * ring.clamp(0.0, 1.0), false, band);
    }

    // Blocks going out to the peers, one after another, once.
    final t = pulse.value;
    if (blocks == 0 || t == 0 || t == 1) return;
    final block = Paint()..color = c.ok;
    for (var b = 0; b < blocks; b++) {
      final start = b * 0.5 / blocks;
      final p = ((t - start) / 0.5).clamp(0.0, 1.0);
      if (p == 0 || p == 1) continue;
      final i = (b * 3 + 1) % _peers;
      final pos = Offset.lerp(at(ringR + stroke, i), at(peerR - dot, i), Curves.easeOut.transform(p))!;
      block.color = c.ok.withValues(alpha: p < 0.15 ? p / 0.15 : 1 - (p - 0.15) / 0.85);
      canvas.drawCircle(pos, dot * 0.55, block);
    }
  }

  @override
  bool shouldRepaint(_StagePainter old) => old.ring != ring || old.blocks != blocks || old.dim != dim || old.colors != colors;
}
