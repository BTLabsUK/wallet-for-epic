// SPDX-License-Identifier: Apache-2.0
/// Help › How linked devices work: the picture of one sync as a short looping animation (this
/// device starts a payment, an encrypted notice goes over the server or servers, the other
/// device holds those coins, the blockchain confirms) and the live status panel under the
/// topic (this device, the linked devices with their last notice, the servers and whether they
/// answer). Shared by the phone and the desktop: [SyncHelpStyle.of] reads whichever token set
/// the theme carries, and each app passes what it knows ([SyncStatusPanel.view], the servers'
/// health, its own Link a device button). With reduced motion the picture stands still with its
/// four steps numbered, and the steps read as a list.
library;

import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../devices/device_model.dart';
import '../../devices/device_providers.dart';
import '../../desktop/theme/tokens.dart' show DeskColors, DeskText, DeskUnits, Fs;
import '../../l10n.dart';
import '../../network.dart' show EpicboxRelay;
import '../status_icons.dart';
import '../theme/tokens.dart';

/// How long each of the four steps stays on screen.
const Duration syncHelpStepDuration = Duration(milliseconds: 2400);

const int _steps = 4;

/// The visible caption, so tests can read it among the hidden ones that hold the height.
const Key syncHelpCaptionKey = ValueKey('syncHelpCaption');

/// The tappable animation area.
const Key syncHelpAnimationKey = ValueKey('syncHelpAnimation');

/// The still picture (reduced motion).
const Key syncHelpStillKey = ValueKey('syncHelpStill');

/// The status panel's Link a device slot.
const Key syncHelpLinkKey = ValueKey('syncHelpLink');

/// The drawing itself (its painter), moving or still.
const Key syncHelpPictureKey = ValueKey('syncHelpPicture');

/// The strings: the tree's, else English, as the desktop reads them (its windows carry no
/// Localizations widget in some tests and dialogs).
AppLocalizations _strings(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations) ?? englishStrings;

/// The colours and text styles the picture and the panel draw with, from the phone's
/// [WalletTokens] or the desktop's [DeskColors], whichever the theme carries. Sizes in dp on the
/// phone and in desktop units ([DeskUnits]) on the desktop, through [u].
class SyncHelpStyle {
  const SyncHelpStyle({
    required this.text,
    required this.dim,
    required this.faint,
    required this.accent,
    required this.accentSoft,
    required this.ok,
    required this.info,
    required this.warn,
    required this.risk,
    required this.line,
    required this.lineStrong,
    required this.surface,
    required this.surfaceHi,
    required this.radius,
    required this.label,
    required this.body,
    required this.small,
    required this.mono,
    required this.desk,
  });

  static SyncHelpStyle of(BuildContext context) {
    final desk = Theme.of(context).extension<DeskColors>();
    if (desk != null) {
      final ts = DeskText(desk);
      return SyncHelpStyle(
        text: desk.text,
        dim: desk.dim,
        faint: desk.faint,
        accent: desk.accent,
        accentSoft: desk.accentSoft,
        ok: desk.ok,
        info: desk.info,
        warn: desk.warn,
        risk: desk.risk,
        line: desk.line,
        lineStrong: desk.lineStrong,
        surface: desk.s1,
        surfaceHi: desk.s2,
        radius: 8.u,
        label: TextStyle(fontSize: Fs.xs.u, fontWeight: FontWeight.w500, color: desk.dim, height: 1.3),
        body: ts.body.copyWith(fontSize: 13.5.u),
        small: ts.small,
        mono: ts.mono(size: Fs.xs.u, color: desk.dim),
        desk: true,
      );
    }
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return SyncHelpStyle(
      text: t.text,
      dim: t.dim,
      faint: t.faint,
      accent: t.accent,
      accentSoft: t.accentSoft,
      ok: t.ok,
      info: t.info,
      warn: t.warn,
      risk: t.risk,
      line: t.line,
      lineStrong: t.lineStrong,
      surface: t.surface,
      surfaceHi: t.surfaceHi,
      radius: t.radius,
      label: (text.labelMedium ?? const TextStyle(fontSize: 12)).copyWith(color: t.dim),
      body: (text.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(color: t.text, height: 1.4),
      small: (text.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(color: t.dim),
      mono: TextStyle(fontFamily: t.monoFamily, fontSize: 12, color: t.dim, fontFeatures: const [FontFeature.tabularFigures()]),
      desk: false,
    );
  }

  final Color text, dim, faint, accent, accentSoft, ok, info, warn, risk, line, lineStrong, surface, surfaceHi;
  final double radius;
  final TextStyle label, body, small, mono;

  /// The desktop's tokens are in use.
  final bool desk;

  /// [dp] scaled as the platform scales its sizes.
  double u(double dp) => desk ? dp.u : dp;
}

/// The picture of a sync: this device, the server or servers, the other device, the
/// blockchain under them, and the notice on its way. [servers] (1 or 2) draws the servers the
/// link uses; [thisIsPhone] gives this device the phone's shape and the other the computer's.
/// It loops; a tap pauses it; with reduced motion it stands still.
class SyncDiagram extends StatefulWidget {
  const SyncDiagram({super.key, this.servers = 2, required this.thisIsPhone, this.maxWidth = 520});

  final int servers;
  final bool thisIsPhone;

  /// The picture never grows past this; it sits at the start of the line.
  final double maxWidth;

  @override
  State<SyncDiagram> createState() => _SyncDiagramState();
}

class _SyncDiagramState extends State<SyncDiagram> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: syncHelpStepDuration * _steps);
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

  @override
  Widget build(BuildContext context) {
    final l = _strings(context);
    final s = SyncHelpStyle.of(context);
    final servers = widget.servers.clamp(1, 2);
    final captions = [l.syncHelpStep1, l.syncHelpStep2(servers), l.syncHelpStep3, l.syncHelpStep4];
    final still = MediaQuery.disableAnimationsOf(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: s.u(widget.maxWidth)),
        child: still
            ? _Still(key: syncHelpStillKey, servers: servers, thisIsPhone: widget.thisIsPhone, captions: captions, style: s)
            : AnimatedBuilder(
                animation: _loop,
                builder: (context, _) => _Animated(
                  value: _loop.value,
                  servers: servers,
                  thisIsPhone: widget.thisIsPhone,
                  captions: captions,
                  paused: _paused,
                  onTap: _toggle,
                  style: s,
                ),
              ),
      ),
    );
  }
}

/// The frame around the picture: the surface, a hairline, and the node labels over the
/// drawing, the chain's under it. [picture] is the painter at [value] (or the still one).
class _Frame extends StatelessWidget {
  const _Frame({required this.style, required this.servers, required this.picture, this.corner});

  final SyncHelpStyle style;
  final int servers;
  final Widget picture;

  /// The pause or play mark at the top right.
  final Widget? corner;

  @override
  Widget build(BuildContext context) {
    final l = _strings(context);
    final s = style;
    final label = s.label;
    return DecoratedBox(
      decoration: BoxDecoration(color: s.surface, border: Border.all(color: s.line), borderRadius: BorderRadius.circular(s.radius)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(s.u(10), s.u(8), s.u(10), s.u(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Over each column of the drawing: the painter puts the nodes at 1/6, 1/2 and 5/6.
            Row(
              children: [
                Expanded(child: Text(l.devicesThisDevice, textAlign: TextAlign.center, style: label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(child: Text(servers == 1 ? l.syncHelpServer : l.devicesServers, textAlign: TextAlign.center, style: label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(child: Text(l.syncHelpOtherDevice, textAlign: TextAlign.center, style: label, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            SizedBox(height: s.u(4)),
            Stack(
              children: [
                AspectRatio(aspectRatio: _SyncPainter.w / _SyncPainter.h, child: picture),
                if (corner != null) Positioned(top: 0, right: 0, child: corner!),
              ],
            ),
            SizedBox(height: s.u(4)),
            Row(
              children: [
                Icon(Icons.view_week_outlined, size: s.u(14), color: s.dim),
                SizedBox(width: s.u(6)),
                Expanded(child: Text(l.syncHelpChain, style: label, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One frame of the story at loop position [value] (0 to 1), the caption of its step under
/// it and the step dots.
class _Animated extends StatelessWidget {
  const _Animated({
    required this.value,
    required this.servers,
    required this.thisIsPhone,
    required this.captions,
    required this.paused,
    required this.onTap,
    required this.style,
  });

  final double value;
  final int servers;
  final bool thisIsPhone;
  final List<String> captions;
  final bool paused;
  final VoidCallback onTap;
  final SyncHelpStyle style;

  @override
  Widget build(BuildContext context) {
    final l = _strings(context);
    final s = style;
    final step = math.min((value * _steps).floor(), _steps - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          key: syncHelpAnimationKey,
          button: true,
          image: true,
          label: '${l.syncHelpDiagram} ${paused ? l.fileHelpPlay : l.fileHelpPause}',
          onTap: onTap,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: _Frame(
              style: s,
              servers: servers,
              corner: Icon(paused ? Icons.play_arrow : Icons.pause, size: s.u(16), color: s.dim),
              picture: CustomPaint(key: syncHelpPictureKey, painter: _SyncPainter(value: value, servers: servers, thisIsPhone: thisIsPhone, style: s)),
            ),
          ),
        ),
        SizedBox(height: s.u(10)),
        // Every caption is laid out, so the block keeps the height of the longest one.
        Stack(
          children: [
            for (var i = 0; i < captions.length; i++)
              Visibility(
                visible: i == step,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Semantics(
                  liveRegion: i == step,
                  child: Text(captions[i], key: i == step ? syncHelpCaptionKey : null, style: s.body),
                ),
              ),
          ],
        ),
        SizedBox(height: s.u(8)),
        Semantics(
          label: l.fileHelpStepOf(step + 1, _steps),
          excludeSemantics: true,
          child: Row(
            children: [
              for (var i = 0; i < _steps; i++)
                Container(
                  width: i == step ? s.u(18) : s.u(6),
                  height: s.u(6),
                  margin: EdgeInsets.only(right: s.u(6)),
                  decoration: BoxDecoration(color: i == step ? s.accent : s.lineStrong, borderRadius: BorderRadius.circular(s.u(3))),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Reduced motion: the whole story in one picture, its four steps numbered where they happen,
/// and the steps as a numbered list under it.
class _Still extends StatelessWidget {
  const _Still({super.key, required this.servers, required this.thisIsPhone, required this.captions, required this.style});

  final int servers;
  final bool thisIsPhone;
  final List<String> captions;
  final SyncHelpStyle style;

  @override
  Widget build(BuildContext context) {
    final l = _strings(context);
    final s = style;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          image: true,
          label: l.syncHelpDiagram,
          excludeSemantics: true,
          child: _Frame(
            style: s,
            servers: servers,
            picture: CustomPaint(key: syncHelpPictureKey, painter: _SyncPainter(value: null, servers: servers, thisIsPhone: thisIsPhone, style: s)),
          ),
        ),
        SizedBox(height: s.u(10)),
        for (var i = 0; i < captions.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: s.u(6)),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: l.fileHelpStepOf(i + 1, captions.length),
                    excludeSemantics: true,
                    child: Container(
                      width: s.u(22),
                      height: s.u(22),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: s.accentSoft, border: Border.all(color: s.accent), shape: BoxShape.circle),
                      child: Text('${i + 1}', style: s.label.copyWith(color: s.text)),
                    ),
                  ),
                  SizedBox(width: s.u(10)),
                  Expanded(child: Padding(padding: EdgeInsets.only(top: s.u(2)), child: Text(captions[i], style: s.body))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The drawing, in a 320 × 124 box scaled to the width. Dim strokes for what is always there
/// (the devices, the servers, the paths, the chain); the accent for the one thing happening
/// (the notice with its lock, the lit device); the info colour for coins held; ok for the
/// chain's confirmation. [value] null draws the still picture with the step numbers.
class _SyncPainter extends CustomPainter {
  const _SyncPainter({required this.value, required this.servers, required this.thisIsPhone, required this.style});

  final double? value;
  final int servers;
  final bool thisIsPhone;
  final SyncHelpStyle style;

  static const double w = 320, h = 124;

  // The columns the labels over the drawing line up with.
  static const double xThis = w / 6, xServer = w / 2, xOther = w * 5 / 6;
  static const double yNodes = 46, yChain = 106;

  Paint _stroke(Color c, [double width = 1.6]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = c;

  Paint _fill(Color c) => Paint()..color = c;

  static double _ease(double t) => Curves.easeInOutCubic.transform(t.clamp(0, 1));
  static double _appear(double t) => Curves.easeOutCubic.transform(t.clamp(0, 1));

  /// [path] cut into dashes of [on], gaps of [off].
  static Path _dashed(Path path, double on, double off) {
    final out = Path();
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        out.addPath(m.extractPath(d, (d + on).clamp(0, m.length)), Offset.zero);
        d += on + off;
      }
    }
    return out;
  }

  static Path _line(Offset a, Offset b) => Path()
    ..moveTo(a.dx, a.dy)
    ..lineTo(b.dx, b.dy);

  /// A point at [t] (0 to 1) along [path].
  static Offset _along(Path path, double t) {
    final m = path.computeMetrics().first;
    return m.getTangentForOffset(m.length * t.clamp(0, 1))!.position;
  }

  double get _serverY1 => servers == 1 ? yNodes : yNodes - 18;
  double get _serverY2 => yNodes + 18;

  /// A device: a phone (tall) or a computer (wide with a stand), its screen in the surface.
  void _device(Canvas canvas, Offset c, bool phone, Paint p, Color screen) {
    if (phone) {
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 24, height: 42), const Radius.circular(4));
      canvas.drawRRect(r, _fill(screen));
      canvas.drawRRect(r, p);
      canvas.drawLine(Offset(c.dx - 4, c.dy + 15), Offset(c.dx + 4, c.dy + 15), p);
    } else {
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, c.dy - 4), width: 44, height: 30), const Radius.circular(3));
      canvas.drawRRect(r, _fill(screen));
      canvas.drawRRect(r, p);
      canvas.drawLine(Offset(c.dx, c.dy + 11), Offset(c.dx, c.dy + 17), p);
      canvas.drawLine(Offset(c.dx - 9, c.dy + 17), Offset(c.dx + 9, c.dy + 17), p);
    }
  }

  /// A server: a box with its two drive lines and a light.
  void _server(Canvas canvas, Offset c, Paint p, Color screen) {
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 36, height: 24), const Radius.circular(4));
    canvas.drawRRect(r, _fill(screen));
    canvas.drawRRect(r, p);
    canvas.drawLine(Offset(c.dx - 12, c.dy - 3), Offset(c.dx + 4, c.dy - 3), p);
    canvas.drawLine(Offset(c.dx - 12, c.dy + 4), Offset(c.dx + 4, c.dy + 4), p);
    canvas.drawCircle(Offset(c.dx + 11, c.dy + 0.5), 1.6, _fill(p.color));
  }

  /// The notice: an envelope, with a lock on it once it is sealed ([lock] 0 to 1 grows it).
  void _envelope(Canvas canvas, Offset c, double lock, Paint p, Color paper, {double scale = 1}) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    const rect = Rect.fromLTWH(-11, -7, 22, 14);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), _fill(paper));
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), p);
    canvas.drawPath(
      Path()
        ..moveTo(-11, -7)
        ..lineTo(0, 1)
        ..lineTo(11, -7),
      p,
    );
    if (lock > 0) {
      final a = _appear(lock);
      canvas.save();
      canvas.translate(9, -8);
      canvas.scale(a);
      canvas.drawCircle(Offset.zero, 6.5, _fill(paper));
      canvas.drawCircle(Offset.zero, 6.5, _stroke(p.color, 1.4));
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -0.5, 6, 4.5), const Radius.circular(1)), _fill(p.color));
      canvas.drawPath(
        Path()
          ..moveTo(-2, -0.5)
          ..lineTo(-2, -2)
          ..arcToPoint(const Offset(2, -2), radius: const Radius.circular(2))
          ..lineTo(2, -0.5),
        _stroke(p.color, 1.3),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  /// Coins on a device's screen: two stacked, with a dashed ring while held, a tick once the
  /// chain confirmed them.
  void _coins(Canvas canvas, Offset c, {required double held, required double confirmed}) {
    if (held <= 0 && confirmed <= 0) return;
    final a = _appear(math.max(held, confirmed));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(a);
    final coin = _stroke(confirmed > 0 ? style.ok : style.info, 1.4);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 2), width: 12, height: 5), coin);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -2), width: 12, height: 5), coin);
    if (confirmed > 0) {
      _tick(canvas, const Offset(8, -6), _appear(confirmed), style.ok, style.surface);
    } else {
      canvas.drawPath(_dashed(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 11)), 3, 3), _stroke(style.info, 1.2));
    }
    canvas.restore();
  }

  /// A check mark in a disc.
  void _tick(Canvas canvas, Offset c, double a, Color color, Color paper) {
    if (a <= 0) return;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(a);
    canvas.drawCircle(Offset.zero, 6, _fill(paper));
    canvas.drawCircle(Offset.zero, 6, _fill(color));
    canvas.drawPath(
      Path()
        ..moveTo(-3, 0)
        ..lineTo(-0.8, 2.3)
        ..lineTo(3.2, -2.3),
      _stroke(paper, 1.5),
    );
    canvas.restore();
  }

  /// A step number in a disc, for the still picture.
  void _number(Canvas canvas, Offset c, int n) {
    canvas.drawCircle(c, 7.5, _fill(style.accentSoft));
    canvas.drawCircle(c, 7.5, _stroke(style.accent, 1.2));
    final tp = TextPainter(
      text: TextSpan(text: '$n', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: style.text, fontFamily: style.label.fontFamily)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  /// The blockchain: linked blocks across the bottom; the newest at the right gets the
  /// confirmation ([confirmed] 0 to 1 lights it, with the tick).
  void _chain(Canvas canvas, double confirmed) {
    final dim = _stroke(style.dim, 1.4);
    const n = 7, bw = 16.0, bh = 11.0, gap = 12.0;
    const span = n * bw + (n - 1) * gap;
    const x0 = (w - span) / 2;
    for (var i = 0; i < n; i++) {
      final x = x0 + i * (bw + gap);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, yChain - bh / 2, bw, bh), const Radius.circular(2));
      final last = i == n - 1;
      if (last) {
        final a = _appear(confirmed);
        if (a <= 0) {
          canvas.drawRRect(r, _stroke(style.lineStrong, 1.2));
        } else {
          canvas.drawRRect(r, _fill(Color.lerp(style.surface, style.ok, 0.25 * a)!));
          canvas.drawRRect(r, _stroke(Color.lerp(style.lineStrong, style.ok, a)!, 1.4));
          _tick(canvas, Offset(x + bw / 2, yChain - bh / 2 - 2), a, style.ok, style.surface);
        }
      } else {
        canvas.drawRRect(r, _fill(style.surfaceHi));
        canvas.drawRRect(r, dim);
      }
      if (i < n - 1) {
        final p = last ? dim : (i == n - 2 ? _stroke(confirmed > 0 ? style.ok : style.lineStrong, 1.4) : dim);
        canvas.drawLine(Offset(x + bw, yChain), Offset(x + bw + gap, yChain), p);
      }
    }
  }

  /// A soft disc behind the device acting now.
  void _halo(Canvas canvas, Offset c, double a) {
    if (a <= 0) return;
    canvas.drawCircle(c, 34 * _appear(a), _fill(style.accentSoft.withValues(alpha: style.accentSoft.a * a)));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / w, size.height / h);
    final still = value == null;
    final step = still ? 0 : math.min((value! * _steps).floor(), _steps - 1);
    final t = still ? 0.0 : value! * _steps - step;

    final thisC = Offset(xThis, yNodes);
    final otherC = Offset(xOther, yNodes);
    final serverCs = [Offset(xServer, _serverY1), if (servers == 2) Offset(xServer, _serverY2)];
    final dim = _stroke(style.dim);

    // The paths the notice takes, from the edge of this device to the edge of the other.
    final from = Offset(thisC.dx + (thisIsPhone ? 16 : 26), yNodes);
    final to = Offset(otherC.dx - (thisIsPhone ? 26 : 16), yNodes);
    final legs1 = [for (final sc in serverCs) _line(from, Offset(sc.dx - 22, sc.dy))];
    final legs2 = [for (final sc in serverCs) _line(Offset(sc.dx + 22, sc.dy), to)];
    for (final p in [...legs1, ...legs2]) {
      canvas.drawPath(_dashed(p, 3, 4), _stroke(style.lineStrong, 1.4));
    }
    // Arrowheads into the other device.
    canvas.drawPath(
      Path()
        ..moveTo(to.dx - 4, to.dy - 4)
        ..lineTo(to.dx, to.dy)
        ..lineTo(to.dx - 4, to.dy + 4),
      _stroke(style.lineStrong, 1.4),
    );

    // The devices and the chain, with what each step leaves behind.
    final acting = still ? 0.0 : (step == 0 ? _appear(t * 4) : step == 1 ? 1 - _appear(t * 4) : 0.0);
    final receiving = still ? 0.0 : (step == 2 ? _appear(t * 4) : step == 3 ? 1 - _appear(t * 4) : 0.0);
    _halo(canvas, thisC, acting);
    _halo(canvas, otherC, receiving);
    final confirmed = still ? 1.0 : (step == 3 ? _appear(t * 3) : 0.0);
    final held = still ? 1.0 : (step == 2 ? _appear((t - 0.15) * 3) : step == 3 ? 1.0 : 0.0);
    _chain(canvas, confirmed);
    final thisLit = !still && (step == 0 || (step == 1 && t < 0.15));
    _device(canvas, thisC, thisIsPhone, _stroke(thisLit ? style.accent : style.dim), style.surfaceHi);
    _device(canvas, otherC, !thisIsPhone, _stroke(!still && step == 2 ? style.accent : style.dim), style.surfaceHi);
    for (final sc in serverCs) {
      _server(canvas, sc, dim, style.surfaceHi);
    }
    // The payment this device started: an envelope being written on its screen (step 1),
    // sealed with the lock as it leaves (step 2).
    final paper = style.surface;
    final accent = _stroke(style.accent, 1.5);
    if (still) {
      // Everything at once: the sealed notice on the first leg, the coins held, the chain's
      // tick, and the numbers 1 to 4 where each step happens.
      _envelope(canvas, _along(legs1.first, 0.5), 1, accent, paper);
      _coins(canvas, Offset(otherC.dx, otherC.dy - 4), held: 0, confirmed: 1);
      _tick(canvas, Offset(thisC.dx + (thisIsPhone ? 10 : 20), thisC.dy - (thisIsPhone ? 19 : 17)), 1, style.ok, style.surface);
      _number(canvas, Offset(thisC.dx - (thisIsPhone ? 20 : 30), thisC.dy - 16), 1);
      _number(canvas, Offset(xServer, servers == 2 ? yNodes : yNodes - 24), 2);
      _number(canvas, Offset(otherC.dx + (thisIsPhone ? 30 : 20), otherC.dy - 16), 3);
      _number(canvas, Offset(w / 2 + 68, yChain - 1), 4);
    } else {
      switch (step) {
        case 0:
          // The envelope grows on this device's screen.
          _envelope(canvas, Offset(thisC.dx, thisC.dy - 4), 0, accent, paper, scale: 0.75 * _appear(t * 3));
        case 1:
          // Leaves with its lock, to every server at once, then on to the other device. The
          // second copy arrives a little later and fades: the same notice, read once.
          final lock = _appear(t * 5);
          if (t < 0.5) {
            final k = _ease(t * 2);
            for (final leg in legs1) {
              _envelope(canvas, Offset.lerp(Offset(thisC.dx, thisC.dy - 4), _along(leg, k), k)!, lock, accent, paper, scale: 0.75 + 0.25 * k);
            }
          } else {
            final k = _ease((t - 0.5) * 2);
            for (final (i, leg) in legs2.indexed) {
              final late = i == 0 ? 0.0 : 0.12;
              final kk = _ease(((t - 0.5) * 2 - late) / (1 - late));
              final fade = i == 0 ? 1.0 : 1 - _appear((kk - 0.85) / 0.15);
              if (fade <= 0) continue;
              final p = _stroke(style.accent.withValues(alpha: fade), 1.5);
              _envelope(canvas, _along(leg, kk), lock, p, paper.withValues(alpha: fade), scale: 1 - 0.1 * k);
            }
          }
        case 2:
          // Read on the other device: the coins it names are held, and the payment is listed.
          final open = 1 - _appear(t * 3);
          if (open > 0) {
            _envelope(canvas, Offset(otherC.dx, otherC.dy - 4), 1, _stroke(style.accent.withValues(alpha: open), 1.5), paper.withValues(alpha: open), scale: 0.9);
          }
          _coins(canvas, Offset(otherC.dx, otherC.dy - 4), held: held, confirmed: 0);
          final row = _appear((t - 0.4) * 3);
          if (row > 0) {
            final p = _stroke(style.dim.withValues(alpha: row), 1.4);
            final y = otherC.dy + (thisIsPhone ? 8 : 4);
            canvas.drawLine(Offset(otherC.dx - 9, y), Offset(otherC.dx + 9, y), p);
            canvas.drawLine(Offset(otherC.dx - 9, y + 4), Offset(otherC.dx + 3, y + 4), p);
          }
        case 3:
          // The chain confirms: the held coins turn confirmed, both devices get the tick.
          _coins(canvas, Offset(otherC.dx, otherC.dy - 4), held: 1, confirmed: _appear((t - 0.25) * 3));
          _tick(canvas, Offset(thisC.dx + (thisIsPhone ? 10 : 20), thisC.dy - (thisIsPhone ? 19 : 17)), _appear((t - 0.3) * 3), style.ok, style.surface);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SyncPainter old) => old.value != value || old.servers != servers || old.thisIsPhone != thisIsPhone || old.style != style;
}

/// What a server is doing now, as the panel words it.
enum SyncServerState { answering, notAnswering, unknown }

/// The live status under the topic: this device, each linked device with when its last notice
/// came, the servers in use with whether they answer. [view] null or without devices shows
/// the empty state with [linkAction] (the app's own Link a device button). [serverState] is
/// what the app knows of a server (its monitor, its list); [now] the clock the times are read
/// against.
class SyncStatusPanel extends StatelessWidget {
  const SyncStatusPanel({
    super.key,
    required this.view,
    required this.now,
    required this.serverState,
    required this.thisIsPhone,
    this.linkAction,
  });

  final DeviceView? view;
  final DateTime now;
  final SyncServerState Function(String server) serverState;
  final bool thisIsPhone;
  final Widget? linkAction;

  @override
  Widget build(BuildContext context) {
    final l = _strings(context);
    final s = SyncHelpStyle.of(context);
    final book = view?.book;
    final devices = view?.devices ?? const <LinkedDevice>[];
    final servers = book?.servers ?? const <String>[];
    final states = {for (final v in servers) v: serverState(v)};
    final allDown = states.isNotEmpty && states.values.every((st) => st == SyncServerState.notAnswering);
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: s.surface, border: Border.all(color: s.line), borderRadius: BorderRadius.circular(s.radius)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(s.u(14), s.u(12), s.u(14), s.u(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Semantics(header: true, child: Text(l.syncHelpStatus, style: s.label.copyWith(color: s.text, fontWeight: FontWeight.w600)))),
                  if (book != null && book.paused) ...[
                    Icon(Icons.pause_circle_outline, size: s.u(14), color: s.warn),
                    SizedBox(width: s.u(4)),
                    Text(l.syncHelpPaused, style: s.small.copyWith(color: s.warn)),
                  ],
                ],
              ),
              SizedBox(height: s.u(8)),
              if (devices.isEmpty)
                _Empty(style: s, linkAction: linkAction)
              else ...[
                _Row(
                  style: s,
                  icon: thisIsPhone ? Icons.smartphone : Icons.computer_outlined,
                  title: book?.deviceName ?? '',
                  trailing: l.devicesThisDevice,
                ),
                for (final d in devices)
                  _Row(style: s, icon: Icons.devices_outlined, title: d.name, trailing: _seen(l, d.lastSeen), trailingColor: d.lastSeen == null ? s.faint : null),
                if (servers.isNotEmpty) ...[
                  Padding(padding: EdgeInsets.symmetric(vertical: s.u(8)), child: Divider(height: 1, thickness: 1, color: s.line)),
                  for (final v in servers)
                    _Row(
                      style: s,
                      icon: EpicGlyphs.epicbox,
                      title: EpicboxRelay.parse(v)?.label ?? v,
                      titleStyle: s.mono.copyWith(color: s.text),
                      dot: _dot(s, states[v]!, allDown),
                      trailing: switch (states[v]!) {
                        SyncServerState.answering => l.syncHelpAnswering,
                        SyncServerState.notAnswering => l.syncHelpNotAnswering,
                        SyncServerState.unknown => l.syncHelpNotChecked,
                      },
                      trailingColor: switch (states[v]!) {
                        SyncServerState.answering => s.ok,
                        SyncServerState.notAnswering => allDown ? s.risk : s.warn,
                        SyncServerState.unknown => s.faint,
                      },
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// When a linked device was last heard from, as the devices page words it.
  String _seen(AppLocalizations l, DateTime? at) {
    if (at == null) return l.devicesNotSeen;
    final d = now.difference(at);
    if (d.inMinutes < 1) return l.devicesSeenNow;
    if (d.inHours < 1) return l.devicesSeenMinutes(d.inMinutes);
    if (d.inDays < 1) return l.devicesSeenHours(d.inHours);
    return l.devicesSeenDays(d.inDays);
  }

  /// A server's state as a shape and a colour, never colour alone: filled answering, a ring
  /// not answering (risk when no server answers), a faint ring not checked.
  Widget _dot(SyncHelpStyle s, SyncServerState st, bool allDown) {
    final color = switch (st) {
      SyncServerState.answering => s.ok,
      SyncServerState.notAnswering => allDown ? s.risk : s.warn,
      SyncServerState.unknown => s.faint,
    };
    return Container(
      width: s.u(8),
      height: s.u(8),
      decoration: BoxDecoration(shape: BoxShape.circle, color: st == SyncServerState.answering ? color : Colors.transparent, border: Border.all(color: color, width: 1.5)),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.style, required this.icon, required this.title, this.titleStyle, required this.trailing, this.trailingColor, this.dot});

  final SyncHelpStyle style;
  final IconData icon;
  final String title;
  final TextStyle? titleStyle;
  final String trailing;
  final Color? trailingColor;
  final Widget? dot;

  @override
  Widget build(BuildContext context) {
    final s = style;
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: s.u(5)),
        child: Row(
          children: [
            Icon(icon, size: s.u(18), color: s.dim),
            SizedBox(width: s.u(10)),
            Expanded(child: Text(title, style: titleStyle ?? s.body, maxLines: 1, overflow: TextOverflow.ellipsis)),
            SizedBox(width: s.u(8)),
            if (dot != null) ...[dot!, SizedBox(width: s.u(6))],
            Text(trailing, style: s.small.copyWith(color: trailingColor ?? s.dim)),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.style, required this.linkAction});

  final SyncHelpStyle style;
  final Widget? linkAction;

  @override
  Widget build(BuildContext context) {
    final l = _strings(context);
    final s = style;
    return Row(
      children: [
        Icon(EpicGlyphs.link, size: s.u(18), color: s.dim),
        SizedBox(width: s.u(10)),
        Expanded(child: Text(l.devicesEmpty, style: s.body.copyWith(color: s.dim))),
        if (linkAction != null) ...[SizedBox(width: s.u(8)), KeyedSubtree(key: syncHelpLinkKey, child: linkAction!)],
      ],
    );
  }
}
