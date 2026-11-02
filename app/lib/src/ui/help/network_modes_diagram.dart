// SPDX-License-Identifier: Apache-2.0
/// The network-modes picture: what each connection mode lets out of the device, as a small
/// animated topology (the owner's landing mockup B, "Choose what leaves", rebuilt in Flutter). A
/// row of mode buttons, an instrument panel with this device, Tor, Epicbox, the node and the
/// network, packets running both ways on every link the mode keeps up, and a readout of the
/// mode in words. Shared by the phone and the desktop: Help › Network modes shows it under the
/// topic's answer, and the ⓘ of Settings › Network & privacy › Connection mode opens it in a
/// sheet (phone) or a dialog (desktop), at the mode of the row.
///
/// It explains only: the buttons pick the mode the picture shows, never the wallet's mode.
/// What each mode really does is `network_gate.dart`; the words follow `network_mode_text.dart`
/// and the Help topic.
///
/// Dark as specified (the mockup's tokens); light from the shared palette both apps' light
/// tokens are made of. Geist Mono for the labels and Geist for the description, bundled
/// (assets/fonts, OFL); Thai and Chinese fall back to the bundled Noto fonts.
library;

import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../advanced.dart';
import '../../desktop/theme/tokens.dart' show DeskColors, DeskUnits;
import '../../l10n.dart';
import '../../tor_build.dart';
import '../network_mode_text.dart';
import '../theme/fonts.dart' show bundledFallback;
import '../theme/palette.dart';

/// The picture's root, for tests and the screenshot tour.
const Key networkModesDiagramKey = ValueKey('net-modes-diagram');

/// A mode's button above the picture: `net-modes-seg-<name>`.
Key networkModesSegmentKey(NetworkMode m) => ValueKey('net-modes-seg-${m.name}');

/// Packets run at this many viewBox units a second.
const double _packetSpeed = 85;

/// Mode changes cross-fade links, nodes and the badge over this.
const Duration _fade = Duration(milliseconds: 300);

/// The mode buttons' colour and fill change.
const Duration _segFade = Duration(milliseconds: 150);

/// At or under this viewport width the picture stands tall (the mockup's 640 px breakpoint).
const double _tallBreak = 640;

/// From this panel width the readout stands beside the picture (8 : 4), under it below.
const double _besideFrom = 880;

// ---------------------------------------------------------------------------------------------
// Colours

/// The picture's colours. [dark] is the mockup's own; [light] maps each role to the shared
/// light palette (`ui/theme/palette.dart`), which the phone's and the desktop's light tokens
/// are both made of.
class _Pal {
  const _Pal({
    required this.bg2,
    required this.panel2,
    required this.nodeFill,
    required this.line,
    required this.line2,
    required this.line3,
    required this.grid,
    required this.text,
    required this.dim,
    required this.faint,
    required this.cool,
    required this.gold,
    required this.offText,
  });

  final Color bg2, panel2, nodeFill, line, line2, line3, grid, text, dim, faint, cool, gold;

  /// The opacity of an off node's words: 45 % as specified on dark, a little more on light,
  /// where dark text fades into the white faster.
  final double offText;

  /// The on-node stroke: [cool] at 65 %.
  Color get coolStroke => cool.withValues(alpha: 0.65);

  static const dark = _Pal(
    bg2: Color(0xFF0D0F12),
    panel2: Color(0xFF15181E),
    nodeFill: Color(0xFF0F1115),
    line: Color(0x13FFFFFF),
    line2: Color(0x24FFFFFF),
    line3: Color(0x3DFFFFFF),
    grid: Color(0x0EFFFFFF),
    text: Color(0xFFECEEF2),
    dim: Color(0xFF959AA5),
    faint: Color(0xFF727885),
    cool: Color(0xFF8FB8FF),
    gold: Color(0xFFF6D471),
    offText: 0.45,
  );

  /// Light: the panel a step below the page's cards with white nodes on it, the info blue for
  /// what is live, the AA brown that stands for gold in the light theme.
  static const light = _Pal(
    bg2: PaletteLight.bg,
    panel2: PaletteLight.s1,
    nodeFill: PaletteLight.s1,
    line: PaletteLight.line,
    line2: PaletteLight.lineStrong,
    line3: PaletteLight.lineField,
    grid: PaletteLight.grid,
    text: PaletteLight.text,
    dim: PaletteLight.dim,
    faint: PaletteLight.faint,
    cool: PaletteLight.info,
    gold: PaletteLight.accent,
    offText: 0.6,
  );

  static _Pal of(BuildContext context) => Theme.of(context).brightness == Brightness.light ? light : dark;
}

// ---------------------------------------------------------------------------------------------
// Geometry and the modes

enum _N { dev, tor, box, node, net }

/// One layout of the picture in viewBox units: its size, the node boxes and the badge.
class _Layout {
  const _Layout({
    required this.vb,
    required this.w,
    required this.h,
    required this.nodes,
    required this.badge,
    required this.badgeMax,
    required this.tall,
  });

  final Size vb;

  /// The widest the badge grows for a long translation, centred where [badge] is: under the
  /// device (wide), or in the room right of it (tall).
  final double badgeMax;

  /// The node box (Tor's own width in [nodes] where it differs).
  final double w, h;
  final Map<_N, (Offset, double?)> nodes;
  final Rect badge;
  final bool tall;

  Offset c(_N n) => nodes[n]!.$1;
  double width(_N n) => nodes[n]!.$2 ?? w;
}

const _wide = _Layout(
  vb: Size(800, 330),
  w: 124,
  h: 48,
  nodes: {
    _N.dev: (Offset(84, 165), null),
    _N.tor: (Offset(300, 165), null),
    _N.box: (Offset(520, 62), null),
    _N.node: (Offset(520, 268), null),
    _N.net: (Offset(716, 268), null),
  },
  badge: Rect.fromLTWH(36, 204, 96, 24),
  badgeMax: 160,
  tall: false,
);

const _tall = _Layout(
  vb: Size(360, 560),
  w: 100,
  h: 46,
  nodes: {
    _N.dev: (Offset(180, 62), null),
    _N.tor: (Offset(180, 222), 90),
    _N.box: (Offset(55, 380), null),
    _N.node: (Offset(305, 380), null),
    _N.net: (Offset(305, 505), null),
  },
  badge: Rect.fromLTWH(248, 50, 96, 24),
  badgeMax: 116,
  tall: true,
);

/// The six links, always in this order (and painted in it).
const List<(_N, _N)> _links = [
  (_N.dev, _N.box),
  (_N.dev, _N.node),
  (_N.dev, _N.tor),
  (_N.tor, _N.box),
  (_N.tor, _N.node),
  (_N.node, _N.net),
];

/// What a mode keeps up: the live links (indices into [_links]), the nodes it reaches, and
/// whether the device holds its payments (Kill switch).
typedef _Shape = ({Set<int> live, Set<_N> on, bool held});

_Shape _shapeOf(NetworkMode m) => switch (m) {
  NetworkMode.standard => (live: {0, 1, 5}, on: {_N.box, _N.node, _N.net}, held: false),
  NetworkMode.torOnly => (live: {2, 3, 4, 5}, on: {_N.tor, _N.box, _N.node, _N.net}, held: false),
  NetworkMode.nodeOnly => (live: {1, 5}, on: {_N.node, _N.net}, held: false),
  NetworkMode.killSwitch => (live: <int>{}, on: <_N>{}, held: true),
};

enum _Tone { on, plain, off, warn }

/// The readout of [m]: its rows (name, value, tone). [tor] false (the build without Tor): no
/// Tor row.
List<(String, String, _Tone)> _readout(AppLocalizations l, NetworkMode m, {required bool tor}) {
  const epicbox = 'Epicbox';
  const torName = 'Tor';
  final rows = switch (m) {
    NetworkMode.standard => [
      (epicbox, l.netModesDirect, _Tone.on),
      (l.netModesNode, l.netModesDirect, _Tone.on),
      (torName, l.netModesOptional, _Tone.plain),
      (l.netModesLeaves, l.netModesYes, _Tone.plain),
    ],
    NetworkMode.torOnly => [
      (epicbox, l.netModesViaTor, _Tone.on),
      (l.netModesNode, l.netModesViaTor, _Tone.on),
      (torName, l.netModesAllTraffic, _Tone.on),
      (l.netModesLeaves, l.netModesViaTor, _Tone.plain),
    ],
    // The Tor switch stays the user's in Node only, and carries the node while it is on.
    NetworkMode.nodeOnly => [
      (epicbox, l.netModesOff, _Tone.off),
      (l.netModesNode, l.netModesDirect, _Tone.on),
      (torName, l.netModesOptional, _Tone.plain),
      (l.netModesLeaves, l.advModeNodeOnly, _Tone.plain),
    ],
    NetworkMode.killSwitch => [
      (epicbox, l.netModesOff, _Tone.off),
      (l.netModesNode, l.netModesOff, _Tone.off),
      (torName, l.netModesOff, _Tone.off),
      (l.netModesLeaves, l.netModesNo, _Tone.warn),
    ],
  };
  return [for (final r in rows) if (tor || r.$1 != torName) r];
}

/// The mode's sentence: the app's own words where it has them (Tor only, Normal without Tor).
String networkModesDescription(AppLocalizations l, NetworkMode m, {bool? tor}) => switch (m) {
  NetworkMode.standard => (tor ?? torBuilt) ? l.netModesDescStandard : l.advModeStandardHintNoTor,
  NetworkMode.torOnly => l.advModeTorOnlyHint,
  NetworkMode.nodeOnly => l.netModesDescNodeOnly,
  NetworkMode.killSwitch => l.netModesDescKillSwitch,
};

/// The strings: the tree's, else English (some desktop dialogs and tests carry no
/// Localizations widget).
AppLocalizations _strings(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations) ?? englishStrings;

/// The picture's look, by mode, as numbers a cross-fade can blend: per link how live it is
/// (0 idle, 1 live), per node how reached (0 off, 1 on), how held the device is, how shown the
/// badge.
class _Look {
  _Look(this.links, this.nodes, this.held, this.badge);

  factory _Look.of(_Shape s) => _Look(
    [for (var i = 0; i < _links.length; i++) s.live.contains(i) ? 1.0 : 0.0],
    {for (final n in _N.values) n: s.on.contains(n) ? 1.0 : 0.0},
    s.held ? 1 : 0,
    s.held ? 1 : 0,
  );

  final List<double> links;
  final Map<_N, double> nodes;
  final double held, badge;

  static double _l(double a, double b, double t) => a + (b - a) * t;

  static _Look lerp(_Look a, _Look b, double t) => _Look(
    [for (var i = 0; i < a.links.length; i++) _l(a.links[i], b.links[i], t)],
    {for (final n in _N.values) n: _l(a.nodes[n]!, b.nodes[n]!, t)},
    _l(a.held, b.held, t),
    _l(a.badge, b.badge, t),
  );
}

// ---------------------------------------------------------------------------------------------
// The widget

/// The network-modes picture, at [initial] (the wallet's mode, or the row whose ⓘ opened it).
/// [tor]: the build has Tor (defaults to [torBuilt]); without it there is no Tor only, no Tor
/// node and no Tor row.
class NetworkModesDiagram extends StatefulWidget {
  const NetworkModesDiagram({super.key = networkModesDiagramKey, this.initial = NetworkMode.standard, this.tor});

  final NetworkMode initial;
  final bool? tor;

  @override
  State<NetworkModesDiagram> createState() => _NetworkModesDiagramState();
}

class _NetworkModesDiagramState extends State<NetworkModesDiagram> with TickerProviderStateMixin, WidgetsBindingObserver {
  late NetworkMode _mode;
  late final AnimationController _fadeCtl = AnimationController(vsync: this, duration: _fade, value: 1);
  late final Animation<double> _fadeT = CurvedAnimation(parent: _fadeCtl, curve: Curves.ease);
  late _Look _from;
  late _Look _to;

  /// The packets' clock: seconds the picture has run, paused off screen and in the background.
  final ValueNotifier<double> _clock = ValueNotifier(0);
  double _clockBase = 0;
  late final Ticker _ticker = createTicker(_tick);

  /// When each live link went live, on [_clock]; its packets start there at p = 0.
  final Map<int, double> _liveSince = {};

  bool _visible = true;

  /// The reader paused the packets (the button in the caption): motion that runs on beside
  /// text needs a way to stop it.
  bool _paused = false;
  bool _foreground = true;
  double _lastVisibilityCheck = 0;
  final List<ScrollPosition> _scrolls = [];

  bool get _tor => widget.tor ?? torBuilt;

  List<NetworkMode> get _modes => offeredNetworkModes(tor: _tor);

  @override
  void initState() {
    super.initState();
    _mode = _modes.contains(widget.initial) ? widget.initial : NetworkMode.standard;
    _from = _to = _Look.of(_shapeOf(_mode));
    for (final i in _shapeOf(_mode).live) {
      _liveSince[i] = 0;
    }
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisible());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _watchScrolls();
    _syncTicker();
  }

  @override
  void didUpdateWidget(NetworkModesDiagram old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial && _modes.contains(widget.initial)) _apply(widget.initial);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _scrolls) {
      s.removeListener(_checkVisible);
    }
    _ticker.dispose();
    _fadeCtl.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Inactive is a desktop window without the focus, still on screen: it keeps running.
    _foreground = state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
    _syncTicker();
  }

  /// Every scroll view around the picture: a scroll re-checks whether it is on screen.
  void _watchScrolls() {
    for (final s in _scrolls) {
      s.removeListener(_checkVisible);
    }
    _scrolls.clear();
    var ctx = context;
    for (var depth = 0; depth < 6; depth++) {
      final scrollable = Scrollable.maybeOf(ctx);
      if (scrollable == null) break;
      _scrolls.add(scrollable.position..addListener(_checkVisible));
      ctx = scrollable.context;
    }
  }

  /// Whether any of the picture is inside every scroll view around it and the window.
  void _checkVisible() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    var shown = rect.overlaps(screen);
    for (final s in _scrolls) {
      final vp = s.context.notificationContext?.findRenderObject();
      if (vp is RenderBox && vp.hasSize && vp.attached) {
        final r = vp.localToGlobal(Offset.zero) & vp.size;
        shown = shown && rect.overlaps(r);
      }
    }
    if (shown != _visible) {
      _visible = shown;
      _syncTicker();
    }
  }

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Runs the packets while any link is live, the picture is on screen, the app in front and
  /// motion allowed.
  void _syncTicker() {
    if (!mounted) return;
    final run = !_still && !_paused && _visible && _foreground && _shapeOf(_mode).live.isNotEmpty;
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
      _clockBase = _clock.value;
    }
  }

  void _tick(Duration elapsed) {
    _clock.value = _clockBase + elapsed.inMicroseconds / 1e6;
    // A layout change can move the picture without a scroll: a check twice a second.
    if (_clock.value - _lastVisibilityCheck > 0.5) {
      _lastVisibilityCheck = _clock.value;
      _checkVisible();
    }
  }

  /// Shows [m]: the caption, the readout and the badge at once, links and nodes cross-fading
  /// from where they are; links that turn live start their packets at p = 0.
  void _apply(NetworkMode m) {
    if (m == _mode) return;
    final now = _Look.lerp(_from, _to, _fadeT.value);
    final shape = _shapeOf(m);
    _liveSince.removeWhere((i, _) => !shape.live.contains(i));
    for (final i in shape.live) {
      _liveSince.putIfAbsent(i, () => _clock.value);
    }
    setState(() {
      _mode = m;
      _from = now;
      _to = _Look.of(shape);
    });
    if (_still) {
      _fadeCtl.value = 1;
    } else {
      _fadeCtl.forward(from: 0);
    }
    _syncTicker();
  }

  @override
  Widget build(BuildContext context) {
    final l = _strings(context);
    final pal = _Pal.of(context);
    final desk = Theme.of(context).extension<DeskColors>() != null;
    double u(double v) => desk ? v.u : v;
    final tall = MediaQuery.sizeOf(context).width <= _tallBreak;
    final layout = tall ? _tall : _wide;
    final shape = _shapeOf(_mode);
    final desc = networkModesDescription(l, _mode, tor: _tor);
    final name = networkModeName(l, _mode);

    final segments = _Segments(
      modes: _modes,
      selected: _mode,
      tall: tall,
      pal: pal,
      u: u,
      label: l.netModesGroup,
      name: (m) => networkModeName(l, m),
      onSelect: _apply,
    );
    final panel = _Instrument(
      layout: layout,
      pal: pal,
      u: u,
      tall: tall,
      liveCount: shape.live.length,
      // Only while packets run or are held: no motion, no button.
      paused: !_still && shape.live.isNotEmpty ? _paused : null,
      onPause: () {
        setState(() => _paused = !_paused);
        _syncTicker();
      },
      semantics: l.netModesDiagramLabel(name, desc),
      painterBelow: _LinksPainter(
        layout: layout,
        pal: pal,
        look: () => _Look.lerp(_from, _to, _fadeT.value),
        live: shape.live,
        liveSince: _liveSince,
        clock: _clock,
        packets: !_still,
        tor: _tor,
        repaint: Listenable.merge([_clock, _fadeCtl]),
      ),
      painterAbove: _NodesPainter(
        layout: layout,
        pal: pal,
        look: () => _Look.lerp(_from, _to, _fadeT.value),
        labels: _labels(l),
        badge: l.netModesPostElsewhere.toUpperCase(),
        tor: _tor,
        textDirection: Directionality.of(context),
        repaint: _fadeCtl,
      ),
    );
    Widget readout({bool beside = false}) => _Readout(
      beside: beside,
      pal: pal,
      u: u,
      tall: tall,
      tag: l.netModesModeTag,
      name: name,
      description: desc,
      rows: _readout(l, _mode, tor: _tor),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: segments),
        SizedBox(height: u(tall ? 18 : 24)),
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth < u(_besideFrom)) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [panel, SizedBox(height: u(tall ? 14 : 20)), readout()],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 8, child: Align(alignment: Alignment.topCenter, child: panel)),
                  SizedBox(width: u(32)),
                  Expanded(flex: 4, child: Padding(padding: EdgeInsets.symmetric(vertical: _Instrument.tickOut(tall)), child: readout(beside: true))),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Map<_N, (String, String)> _labels(AppLocalizations l) => {
    _N.dev: (l.netModesDevice, l.netModesDeviceSub),
    _N.tor: ('Tor', l.netModesTorSub),
    _N.box: ('Epicbox', l.netModesEpicboxSub),
    _N.node: (l.netModesNode, l.netModesNodeSub),
    _N.net: (l.netModesNetwork, l.netModesNetworkSub),
  };
}

// ---------------------------------------------------------------------------------------------
// Type

TextStyle _mono(double size, Color color, {double em = 0, FontWeight weight = FontWeight.w400}) => TextStyle(
  fontFamily: 'GeistMono',
  fontFamilyFallback: bundledFallback,
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: em * size,
  height: 1.2,
  fontFeatures: const [FontFeature.tabularFigures(), FontFeature('zero')],
);

TextStyle _sans(double size, Color color) => TextStyle(
  fontFamily: 'Geist',
  fontFamilyFallback: bundledFallback,
  fontSize: size,
  color: color,
  height: 1.4,
  letterSpacing: -0.01 * size,
);

// ---------------------------------------------------------------------------------------------
// The mode buttons

class _Segments extends StatefulWidget {
  const _Segments({
    required this.modes,
    required this.selected,
    required this.tall,
    required this.pal,
    required this.u,
    required this.label,
    required this.name,
    required this.onSelect,
  });

  final List<NetworkMode> modes;
  final NetworkMode selected;
  final bool tall;
  final _Pal pal;
  final double Function(double) u;
  final String label;
  final String Function(NetworkMode) name;
  final ValueChanged<NetworkMode> onSelect;

  @override
  State<_Segments> createState() => _SegmentsState();
}

class _SegmentsState extends State<_Segments> {
  final Map<NetworkMode, FocusNode> _nodes = {};

  FocusNode _node(NetworkMode m) => _nodes.putIfAbsent(m, () => FocusNode(debugLabel: 'net-modes ${m.name}'));

  @override
  void dispose() {
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  /// Moves to the [i]th mode (wrapping), focuses it and shows it.
  void _go(int i) {
    final modes = widget.modes;
    final m = modes[(i % modes.length + modes.length) % modes.length];
    _node(m).requestFocus();
    widget.onSelect(m);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final u = w.u;
    final pal = w.pal;
    final fontSize = w.tall ? 11.0 : 12.0;
    final hPad = u(w.tall ? 6 : 14);
    final index = w.modes.indexOf(w.selected);
    Widget seg(NetworkMode m, int i) => _Segment(
      key: networkModesSegmentKey(m),
      focusNode: _node(m)..skipTraversal = m != w.selected,
      text: w.name(m).toUpperCase(),
      semanticsLabel: w.name(m),
      selected: m == w.selected,
      gold: m == NetworkMode.killSwitch,
      pal: pal,
      height: u(34),
      hPad: hPad,
      radius: u(5),
      style: _mono(fontSize, pal.dim, em: 0.06),
      // A tap focuses the button too, so the arrow keys go on from there.
      onTap: () {
        _node(m).requestFocus();
        w.onSelect(m);
      },
      onMove: (d) => _go(index + d),
      onFirst: () => _go(0),
      onLast: () => _go(w.modes.length - 1),
    );
    final gap = u(3);
    final box = BoxDecoration(color: pal.bg2, border: Border.all(color: pal.line2), borderRadius: BorderRadius.circular(u(8)));
    Widget grid(int cols) {
      final rows = <Widget>[];
      for (var r = 0; r * cols < w.modes.length; r++) {
        if (r > 0) rows.add(SizedBox(height: gap));
        rows.add(
          Row(
            children: [
              for (var c = 0; c < cols; c++) ...[
                if (c > 0) SizedBox(width: gap),
                Expanded(child: r * cols + c < w.modes.length ? seg(w.modes[r * cols + c], r * cols + c) : const SizedBox.shrink()),
              ],
            ],
          ),
        );
      }
      return Container(
        decoration: box,
        padding: EdgeInsets.all(gap),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
      );
    }

    final group = LayoutBuilder(
      builder: (context, c) {
        // Four modes on a phone: two by two; three (no Tor in the build): one row.
        final cols = w.modes.length == 4 ? 2 : 3;
        if (w.tall) return grid(cols);
        // Wide: sized to its labels, unless they do not fit the line (a long translation).
        final scaler = MediaQuery.textScalerOf(context);
        var need = gap * (w.modes.length + 1) + 2;
        for (final m in w.modes) {
          final tp = TextPainter(
            text: TextSpan(text: w.name(m).toUpperCase(), style: _mono(fontSize, pal.dim, em: 0.06)),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          need += tp.width + hPad * 2;
          tp.dispose();
        }
        if (need > c.maxWidth) return grid(cols);
        return Container(
          decoration: box,
          padding: EdgeInsets.all(gap),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < w.modes.length; i++) ...[if (i > 0) SizedBox(width: gap), seg(w.modes[i], i)],
            ],
          ),
        );
      },
    );
    return Semantics(
      role: SemanticsRole.radioGroup,
      label: w.label,
      container: true,
      explicitChildNodes: true,
      // Full width on a phone, sized to its labels otherwise.
      child: w.tall ? SizedBox(width: double.infinity, child: group) : group,
    );
  }
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.by);
  final int by;
}

class _EdgeIntent extends Intent {
  const _EdgeIntent(this.last);
  final bool last;
}

class _Segment extends StatefulWidget {
  const _Segment({
    super.key,
    required this.focusNode,
    required this.text,
    required this.semanticsLabel,
    required this.selected,
    required this.gold,
    required this.pal,
    required this.height,
    required this.hPad,
    required this.radius,
    required this.style,
    required this.onTap,
    required this.onMove,
    required this.onFirst,
    required this.onLast,
  });

  final FocusNode focusNode;
  final String text;
  final String semanticsLabel;
  final bool selected;

  /// Kill switch: its label is gold while selected.
  final bool gold;
  final _Pal pal;
  final double height, hPad, radius;
  final TextStyle style;
  final VoidCallback onTap;
  final ValueChanged<int> onMove;
  final VoidCallback onFirst, onLast;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final pal = w.pal;
    final color = w.selected ? (w.gold ? pal.gold : pal.text) : (_hover ? pal.text : pal.dim);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: w.selected,
      label: w.semanticsLabel,
      excludeSemantics: true,
      onTap: w.onTap,
      child: FocusableActionDetector(
        focusNode: w.focusNode,
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowDown): _MoveIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowUp): _MoveIntent(-1),
          SingleActivator(LogicalKeyboardKey.home): _EdgeIntent(false),
          SingleActivator(LogicalKeyboardKey.end): _EdgeIntent(true),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => w.onTap()),
          _MoveIntent: CallbackAction<_MoveIntent>(onInvoke: (i) => w.onMove(i.by)),
          _EdgeIntent: CallbackAction<_EdgeIntent>(onInvoke: (i) => i.last ? w.onLast() : w.onFirst()),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: w.onTap,
          child: AnimatedContainer(
            duration: _segFade,
            constraints: BoxConstraints(minHeight: w.height),
            padding: EdgeInsets.symmetric(horizontal: w.hPad),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: w.selected ? pal.panel2 : pal.panel2.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(w.radius),
              // The inset outline of the selected button; the keyboard's focus ring in blue.
              border: Border.all(
                color: _focus ? pal.cool : (w.selected ? pal.line3 : pal.line3.withValues(alpha: 0)),
                width: _focus ? 1.5 : 1,
              ),
            ),
            child: AnimatedDefaultTextStyle(
              duration: _segFade,
              style: w.style.copyWith(color: color),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(w.text, maxLines: 1, softWrap: false)),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// The instrument panel

class _Instrument extends StatelessWidget {
  const _Instrument({
    required this.layout,
    required this.pal,
    required this.u,
    required this.tall,
    required this.liveCount,
    required this.paused,
    required this.onPause,
    required this.semantics,
    required this.painterBelow,
    required this.painterAbove,
  });

  final _Layout layout;
  final _Pal pal;
  final double Function(double) u;
  final bool tall;
  final int liveCount;

  /// Whether the packets are paused; null: no packets, no pause button.
  final bool? paused;
  final VoidCallback onPause;
  final String semantics;
  final CustomPainter painterBelow, painterAbove;

  /// How far the corner ticks stand outside the panel.
  static double tickOut(bool tall) => tall ? 5 : 6;

  @override
  Widget build(BuildContext context) {
    final l = _strings(context);
    final cap = _mono(11.5, pal.faint, em: 0.07);
    final out = tickOut(tall);
    return CustomPaint(
      foregroundPainter: _TicksPainter(color: pal.text.withValues(alpha: 0.7), arm: tall ? 9 : 11),
      child: Padding(
        padding: EdgeInsets.all(out),
        child: DecoratedBox(
          decoration: BoxDecoration(color: pal.bg2, border: Border.all(color: pal.line2)),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(minHeight: u(34)),
                  padding: EdgeInsets.symmetric(horizontal: u(12), vertical: u(4)),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: pal.line2))),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${l.netModesTag} '),
                              TextSpan(text: l.netModesTopology.toUpperCase(), style: TextStyle(color: pal.dim)),
                            ],
                          ),
                          style: cap,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: u(12)),
                      Text(l.netModesLiveLinks(liveCount).toUpperCase(), style: cap, maxLines: 1),
                      if (paused case final p?) ...[
                        SizedBox(width: u(6)),
                        SizedBox.square(
                          dimension: u(26),
                          child: IconButton(
                            key: const ValueKey('net-modes-pause'),
                            onPressed: onPause,
                            tooltip: p ? l.fileHelpPlay : l.fileHelpPause,
                            padding: EdgeInsets.zero,
                            iconSize: u(16),
                            color: pal.dim,
                            hoverColor: pal.line2,
                            focusColor: pal.line3,
                            style: IconButton.styleFrom(minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: const RoundedRectangleBorder()),
                            icon: Icon(p ? Icons.play_arrow : Icons.pause),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Semantics(
                  image: true,
                  label: semantics,
                  excludeSemantics: true,
                  child: ClipRect(
                    child: CustomPaint(
                      painter: _GridPainter(pal.grid),
                      child: AspectRatio(
                        aspectRatio: layout.vb.width / layout.vb.height,
                        child: RepaintBoundary(
                          child: CustomPaint(painter: painterBelow, foregroundPainter: painterAbove),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 40 px grid under the picture, in screen pixels from the body's top left.
class _GridPainter extends CustomPainter {
  const _GridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var x = 40.0; x < size.width; x += 40) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
    }
    for (var y = 40.0; y < size.height; y += 40) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

/// The four corner ticks: L-shapes at the corners of the box they paint over (the panel's
/// corners less their offset), arms along the edges.
class _TicksPainter extends CustomPainter {
  const _TicksPainter({required this.color, required this.arm});

  final Color color;
  final double arm;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final w = size.width, h = size.height;
    for (final (x, y, dx, dy) in [(0.0, 0.0, 1, 1), (w, 0.0, -1, 1), (0.0, h, 1, -1), (w, h, -1, -1)]) {
      canvas.drawRect(Rect.fromLTWH(dx > 0 ? x : x - arm, dy > 0 ? y : y - 1, arm, 1), p);
      canvas.drawRect(Rect.fromLTWH(dx > 0 ? x : x - 1, dy > 0 ? y : y - arm, 1, arm), p);
    }
  }

  @override
  bool shouldRepaint(_TicksPainter old) => old.color != color || old.arm != arm;
}

/// The links and their packets, under the nodes: they repaint every frame while packets run.
class _LinksPainter extends CustomPainter {
  _LinksPainter({
    required this.layout,
    required this.pal,
    required this.look,
    required this.live,
    required this.liveSince,
    required this.clock,
    required this.packets,
    required this.tor,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _Layout layout;
  final _Pal pal;
  final _Look Function() look;

  /// The links live in the mode shown: solid, with packets (the dash switches at once).
  final Set<int> live;
  final Map<int, double> liveSince;
  final ValueNotifier<double> clock;
  final bool packets;
  final bool tor;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / layout.vb.width;
    canvas.save();
    canvas.scale(k);
    final now = look();
    final line = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final packet = Paint()..color = pal.cool;
    for (var i = 0; i < _links.length; i++) {
      final (a, b) = _links[i];
      if (!tor && (a == _N.tor || b == _N.tor)) continue;
      final pa = layout.c(a), pb = layout.c(b);
      final d = pb - pa;
      final len = d.distance;
      final t = now.links[i];
      final color = Color.lerp(pal.line3, pal.cool, t)!;
      final opacity = 0.55 + (0.85 - 0.55) * t;
      line.color = color.withValues(alpha: color.a * opacity);
      canvas.save();
      canvas.translate(pa.dx, pa.dy);
      canvas.rotate(math.atan2(d.dy, d.dx));
      final isLive = live.contains(i);
      if (isLive) {
        canvas.drawLine(Offset.zero, Offset(len, 0), line);
      } else {
        for (var s = 0.0; s < len; s += 8) {
          canvas.drawLine(Offset(s, 0), Offset(math.min(s + 3, len), 0), line);
        }
      }
      if (isLive && packets) {
        final dur = len / _packetSpeed;
        final since = liveSince[i] ?? 0;
        final p = (((clock.value - since) / dur) % 1 + 1) % 1;
        final fwd = len * p;
        final rev = len * (1 - ((p + 0.5) % 1));
        canvas.drawRect(Rect.fromCenter(center: Offset(fwd, 0), width: 8, height: 2), packet);
        canvas.drawRect(Rect.fromCenter(center: Offset(rev, 0), width: 8, height: 2), packet);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LinksPainter old) =>
      old.layout != layout || old.pal != pal || old.live != live || old.packets != packets || old.tor != tor;
}

/// The nodes and the badge, over the links (packets pass under the nodes). They repaint only
/// while a mode change fades.
class _NodesPainter extends CustomPainter {
  _NodesPainter({
    required this.layout,
    required this.pal,
    required this.look,
    required this.labels,
    required this.badge,
    required this.tor,
    required this.textDirection,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _Layout layout;
  final _Pal pal;
  final _Look Function() look;
  final Map<_N, (String, String)> labels;
  final String badge;
  final bool tor;
  final TextDirection textDirection;

  /// The least size on screen of the labels: under it the text keeps this size (and fits its
  /// box) while the picture shrinks further, so a narrow dialog stays readable.
  static const double _minTitle = 10.5, _minSub = 9, _minBadge = 9;

  /// A label in [style] at its spec [size] in viewBox units, at least [minPx] on screen at
  /// scale [k], shrunk to [maxWidth] when a translation is longer.
  TextPainter _text(String text, double size, double minPx, double k, double maxWidth, TextStyle Function(double) style) {
    var fs = math.max(size, minPx / k);
    TextPainter make(double f) => TextPainter(text: TextSpan(text: text, style: style(f)), textDirection: textDirection, maxLines: 1)..layout();
    var tp = make(fs);
    if (tp.width > maxWidth) {
      fs = fs * maxWidth / tp.width;
      tp.dispose();
      tp = make(fs);
    }
    return tp;
  }

  /// Paints [tp] centred on [cx] with its baseline at [baseline].
  void _at(Canvas canvas, TextPainter tp, double cx, double baseline) {
    final asc = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(canvas, Offset(cx - tp.width / 2, baseline - asc));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / layout.vb.width;
    canvas.save();
    canvas.scale(k);
    final now = look();
    final fill = Paint()..color = pal.nodeFill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final n in _N.values) {
      if (!tor && n == _N.tor) continue;
      final c = layout.c(n);
      final w = layout.width(n), h = layout.h;
      final rect = Rect.fromCenter(center: c, width: w, height: h);
      double textOpacity;
      if (n == _N.dev) {
        stroke.color = Color.lerp(pal.text, pal.gold, now.held)!;
        textOpacity = 1;
      } else {
        final on = now.nodes[n]!;
        stroke.color = Color.lerp(pal.line2, pal.coolStroke, on)!;
        textOpacity = pal.offText + (1 - pal.offText) * on;
      }
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);
      final (title, sub) = labels[n]!;
      final t = _text(title.toUpperCase(), 13, _minTitle, k, w - 10, (f) => _mono(f, pal.text.withValues(alpha: textOpacity), em: 0.06));
      final s = _text(sub, 11, _minSub, k, w - 10, (f) => _mono(f, pal.faint.withValues(alpha: pal.faint.a * textOpacity), em: 0.03));
      _at(canvas, t, c.dx, c.dy - 3);
      _at(canvas, s, c.dx, c.dy + 13);
      t.dispose();
      s.dispose();
    }
    if (now.badge > 0.001) {
      final b = layout.badge;
      final tp = _text(badge, 11, _minBadge, k, layout.badgeMax - 16, (f) => _mono(f, pal.gold.withValues(alpha: now.badge), em: 0.06));
      // As wide as its words need, centred where the mockup puts it, inside the picture.
      final bw = math.max(b.width, tp.width + 16);
      final left = (b.center.dx - bw / 2).clamp(4.0, layout.vb.width - 4 - bw);
      final rect = Rect.fromLTWH(left, b.top, bw, b.height);
      final dash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = pal.gold.withValues(alpha: 0.7 * now.badge);
      _dashedRect(canvas, rect, dash);
      _at(canvas, tp, rect.center.dx, b.top + b.height / 2 + 4);
      tp.dispose();
    }
    canvas.restore();
  }

  /// [r]'s outline dashed 2 on, 3 off, as the mockup's `stroke-dasharray: 2 3` runs around it.
  void _dashedRect(Canvas canvas, Rect r, Paint p) {
    final path = Path()..addRect(r);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 5) {
        canvas.drawPath(m.extractPath(d, math.min(d + 2, m.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(_NodesPainter old) =>
      old.layout != layout || old.pal != pal || old.badge != badge || old.tor != tor || old.labels.toString() != labels.toString();
}

// ---------------------------------------------------------------------------------------------
// The readout

class _Readout extends StatelessWidget {
  const _Readout({
    required this.beside,
    required this.pal,
    required this.u,
    required this.tall,
    required this.tag,
    required this.name,
    required this.description,
    required this.rows,
  });

  /// Beside the picture, as tall as it: the rows go to the bottom.
  final bool beside;
  final _Pal pal;
  final double Function(double) u;
  final bool tall;
  final String tag, name, description;
  final List<(String, String, _Tone)> rows;

  @override
  Widget build(BuildContext context) {
    final descSize = tall ? 16.0 : 17.0;
    final rowStyle = _mono(12, pal.faint, em: 0.06);
    Color tone(_Tone t) => switch (t) {
      _Tone.on => pal.cool,
      _Tone.plain => pal.text,
      _Tone.off => pal.faint,
      _Tone.warn => pal.gold,
    };
    final scaler = MediaQuery.textScalerOf(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: EdgeInsets.all(u(tall ? 16 : 20)),
        decoration: BoxDecoration(color: pal.bg2, border: Border.all(color: pal.line2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${tag.toUpperCase()} '),
                  TextSpan(text: name.toUpperCase(), style: TextStyle(color: pal.text, fontWeight: FontWeight.w500)),
                ],
              ),
              style: _mono(12, pal.faint, em: 0.08),
            ),
            SizedBox(height: u(14)),
            ConstrainedBox(
              // Three lines held on wide screens, so the rows do not jump between modes.
              constraints: BoxConstraints(minHeight: tall ? 0 : scaler.scale(descSize) * 1.4 * 3),
              child: Text(description, style: _sans(descSize, pal.text)),
            ),
            SizedBox(height: u(14)),
            if (beside) const Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: pal.line2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (k, v, t) in rows)
                    Container(
                      padding: EdgeInsets.symmetric(vertical: u(9)),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: pal.line))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(child: Text(k.toUpperCase(), style: rowStyle)),
                          SizedBox(width: u(12)),
                          Flexible(
                            child: Text(v.toUpperCase(), textAlign: TextAlign.end, style: rowStyle.copyWith(color: tone(t))),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
