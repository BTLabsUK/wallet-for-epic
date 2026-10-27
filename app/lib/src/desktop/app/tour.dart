/// The first-unlock tour: one page per step. Each step opens a real page, lights the area that
/// matters on it and the page's sidebar entry, and says in a line or two what is there. Skip
/// (Esc) on every step, Back and Next (Enter, the arrow keys), a step counter; the card keeps
/// one place at the bottom of the content area so nothing jumps. It ends on Help.
///
/// Screens mark what a step lights with [TourTarget]; [startDeskTour] opens it (Help › Show the
/// tour again), and [DeskShell] opens it once by itself the first time Overview shows after an
/// unlock ([DeskTourController] keeps the seen flag).
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../data/desk_store.dart';
import '../desk_l10n.dart';
import '../widgets/kit.dart';
import '../data/pairing_state.dart' show deskInvoicesShownProvider;

/// One step: the page it opens, the [TourTarget] ids it lights (their union when several are on
/// screen; the card sits in the middle when none is), the sidebar entry and, on a Settings page,
/// the entry in the Settings list.
class TourStep {
  const TourStep({required this.route, required this.targets, required this.titleOf, required this.textOf, this.section, this.sub});

  final DeskRoute route;
  final List<String> targets;

  /// The card's title and text in the reader's language.
  final String Function(AppLocalizations l) titleOf;
  final String Function(AppLocalizations l) textOf;

  /// The English title and text (tests, logs).
  String get title => titleOf(englishStrings);
  String get text => textOf(englishStrings);

  /// The sidebar entry lit with the page; the route's section when null.
  final DeskSection? section;

  /// The Settings list entry lit with the page.
  final DeskRoute? sub;

  String get navId => 'nav-${section?.name ?? route.section?.name ?? route.name}';
  String? get subId => sub == null ? null : 'subnav-${sub!.name}';
}

/// The Invoices page's route once it is in the app (`DeskRoute.invoices`), else null. The tour
/// finds it by name, so the Invoices step switches on with the page and needs no other change.
final DeskRoute? deskInvoicesRoute = DeskRoute.values.where((r) => r.name == 'invoices').firstOrNull;

/// The steps, in order; the Invoices step after Receive when [invoices] (the page exists).
List<TourStep> tourStepsFor({required bool invoices}) => [
  TourStep(
    route: DeskRoute.overview,
    targets: ['balance'],
    titleOf: (l) => l.deskTourOverviewTitle,
    textOf: (l) => l.deskTourOverviewText,
  ),
  TourStep(
    route: DeskRoute.send,
    targets: ['send-methods'],
    titleOf: (l) => l.deskTourSendTitle,
    textOf: (l) => l.deskTourSendText,
  ),
  TourStep(
    route: DeskRoute.receive,
    targets: ['receive-epicbox', 'receive-files'],
    titleOf: (l) => l.deskTourReceiveTitle,
    textOf: (l) => l.deskTourReceiveText,
  ),
  if (invoices)
    TourStep(
      route: deskInvoicesRoute ?? DeskRoute.overview,
      targets: const ['invoices-tabs'],
      titleOf: (l) => l.deskTourInvoicesTitle,
      textOf: (l) => l.deskTourInvoicesText,
    ),
  TourStep(
    route: DeskRoute.activity,
    targets: ['activity-list'],
    titleOf: (l) => l.deskTourActivityTitle,
    textOf: (l) => l.deskTourActivityText,
  ),
  TourStep(
    route: DeskRoute.contacts,
    targets: ['contacts-list'],
    titleOf: (l) => l.deskTourContactsTitle,
    textOf: (l) => l.deskTourContactsText,
  ),
  TourStep(
    route: DeskRoute.settingsNode,
    targets: ['node-server'],
    sub: DeskRoute.settingsNode,
    titleOf: (l) => l.deskTourNodeTitle,
    textOf: (l) => l.deskTourNodeText,
  ),
  // Advanced: where the hidden parts are switched on. The step only shows the page.
  TourStep(
    route: DeskRoute.settingsAdvanced,
    targets: ['advanced-top'],
    sub: DeskRoute.settingsAdvanced,
    titleOf: (l) => l.deskTourAdvancedTitle,
    textOf: (l) => DeskFeatures.tor ? l.deskTourAdvancedText : l.deskNoTorTourAdvancedText,
  ),
  TourStep(
    route: DeskRoute.settingsHelp,
    targets: ['help-top'],
    sub: DeskRoute.settingsHelp,
    titleOf: (l) => l.deskTourHelpTitle,
    textOf: (l) => l.deskTourHelpText,
  ),
];

/// The steps of this build: with Invoices when its page is in the app.
final List<TourStep> deskTourSteps = tourStepsFor(invoices: deskInvoicesRoute != null);

/// The steps for the open wallet: with Invoices only when the page is in the app and the
/// wallet takes invoices (the sidebar hides the page otherwise).
List<TourStep> deskTourStepsFor({required bool supportsInvoices}) =>
    supportsInvoices ? deskTourSteps : tourStepsFor(invoices: false);

/// Tests: the steps the shell's overlay shows instead of [deskTourSteps].
@visibleForTesting
List<TourStep>? debugTourSteps;

// ---- targets -------------------------------------------------------------------------------

final Map<String, GlobalKey> _keys = {};

/// The key of a tour target; the same object for the same id.
GlobalKey tourKey(String id) => _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'tour:$id'));

/// Marks [child] as what a tour step lights. Use each id once on screen.
class TourTarget extends StatelessWidget {
  const TourTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: tourKey(id), child: child);
}

// ---- state ---------------------------------------------------------------------------------

@immutable
class DeskTourState {
  const DeskTourState({this.open = false, this.seen = false, this.start = 0});

  final bool open;

  /// The step it opens on (the screenshot tour shows later steps).
  final int start;

  /// Shown once already (or skipped): it does not open by itself again.
  final bool seen;
}

/// Whether the tour was seen, saved with the app's settings ([DeskSettings.tourSeen]), so it
/// opens by itself once, not on every start.
///
/// - [seen]: shown (or skipped) before, in this run or a saved one;
/// - [openIfUnseen]: the automatic first open; never when the saved flag says seen;
/// - [open]: opens it now (Show the tour, the screenshots), seen from then on;
/// - [markSeen]: saves the flag; [open] and closing an open tour call it;
/// - [close]: closes it (Done, Skip, Esc, lock);
/// - [reset]: this run forgets it was seen; the saved flag stays.
class DeskTourController extends Notifier<DeskTourState> {
  @override
  DeskTourState build() {
    final seen = ref.read(deskBootProvider).settings.tourSeen || ref.read(deskProvider).settings.tourSeen;
    logDebug('tour', 'seen=$seen at start');
    return DeskTourState(seen: seen);
  }

  bool get seen => state.seen;

  /// Opens it unless it was seen: in this run, or by the flag saved now (read again, as what
  /// the app holds in memory may be older). True when it opened.
  Future<bool> openIfUnseen() async {
    if (state.seen) return false;
    final store = ref.read(deskStoreProvider);
    try {
      if (store != null && (await store.settings()).tourSeen) {
        logDebug('tour', 'saved as seen; not opened');
        state = DeskTourState(seen: true, open: state.open, start: state.start);
        return false;
      }
    } on Object catch (e) {
      // An unreadable store: the boot value decides.
      logWarn('tour', 'seen flag not read: ${e.runtimeType}');
    }
    if (state.seen || state.open) return false;
    open();
    return true;
  }

  void open({int at = 0}) {
    logDebug('tour', 'open at step $at');
    state = DeskTourState(open: true, seen: true, start: at);
    unawaited(markSeen());
  }

  /// Closes it; closing an open tour (Done, Skip, Esc) saves it as seen. A tour that never
  /// opened (locked before it showed) still counts as unseen.
  void close() {
    final wasOpen = state.open;
    state = DeskTourState(seen: state.seen);
    if (wasOpen) unawaited(markSeen());
  }

  /// Saves the seen flag: in the store directly, and in the app's settings so a later save of
  /// any setting carries it.
  Future<void> markSeen() async {
    state = DeskTourState(open: state.open, seen: true, start: state.start);
    final desk = ref.read(deskProvider.notifier);
    if (!ref.read(deskProvider).settings.tourSeen) desk.holdTourSeen();
    try {
      await ref.read(deskStoreProvider)?.saveTourSeen();
      logDebug('tour', 'seen saved');
    } on Object catch (e) {
      logWarn('desk', 'tour seen not saved: ${e.runtimeType}');
    }
  }

  /// Forget that it was seen in this run (Help › Show the tour again, which opens it
  /// again). The saved flag stays: the tour still does not open by itself at the next start.
  void reset() => state = const DeskTourState();
}

final deskTourProvider = NotifierProvider<DeskTourController, DeskTourState>(DeskTourController.new);

/// Opens the tour from its first step (Help › Show the tour again), also when it was seen
/// before. The overlay opens each step's page itself.
void startDeskTour(WidgetRef ref) {
  ref.read(deskTourProvider.notifier).reset();
  ref.read(deskTourProvider.notifier).open();
}

/// Not by itself under `flutter test` (the smoke tests and the screenshot tour pump Overview).
final bool deskTourAuto = kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

// ---- overlay -------------------------------------------------------------------------------

/// The tour over the shell: a scrim with holes over the lit areas, hairline rings around them,
/// and the card at the bottom of the content area.
class DeskTourOverlay extends ConsumerStatefulWidget {
  const DeskTourOverlay({super.key, this.stepList, this.startAt = 0});

  final List<TourStep>? stepList;
  final int startAt;

  @override
  ConsumerState<DeskTourOverlay> createState() => _DeskTourOverlayState();
}

class _DeskTourOverlayState extends ConsumerState<DeskTourOverlay> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Fixed for this run of the tour: the wallet does not change while it is open.
  late final List<TourStep> _steps =
      widget.stepList ?? debugTourSteps ?? deskTourStepsFor(supportsInvoices: ref.read(deskInvoicesShownProvider));
  late int _i = widget.startAt.clamp(0, _steps.length - 1);
  final _next = FocusNode(debugLabel: 'tour next');
  final _self = GlobalKey();
  final _card = GlobalKey();

  /// The lit areas, in the overlay's coordinates: the page area, the sidebar entry, the
  /// Settings list entry. Null when not on screen.
  Rect? _rect, _nav, _sub;

  /// Frames still to try placing on: a page builds its targets over a frame or two.
  int _tries = 0;

  /// 0 → 1: the rings' fade-in (200 ms ease-out from 102 %); instant with reduced motion.
  late final _in = AnimationController(vsync: this, duration: Dur.base);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open(_i, first: true);
  }

  /// A window resize moves the targets: the rings are placed again once the page has laid out.
  @override
  void didChangeMetrics() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _place(resized: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _in.dispose();
    _next.dispose();
    super.dispose();
  }

  /// Shows step [i]: opens its page and places the rings when the page is up. The first step's
  /// page opens after the frame that builds the overlay (no provider change while building).
  void _open(int i, {bool first = false}) {
    if (!first) setState(() => _i = i);
    _rect = _nav = _sub = null;
    _tries = 12;
    _in.value = 0;
    void go() {
      if (!mounted) return;
      final step = _steps[i];
      if (ref.read(deskNavProvider).route != step.route) ref.read(deskNavProvider.notifier).go(step.route);
      WidgetsBinding.instance.addPostFrameCallback((_) => _place());
    }

    if (first) {
      WidgetsBinding.instance.addPostFrameCallback((_) => go());
    } else {
      go();
    }
  }

  /// The target's area in the overlay, scrolled into view first: a page area up to the top of its
  /// scroll view, a navigation entry just far enough to show (the sidebar scrolls in low windows).
  Rect? _find(String id, RenderBox me, {ScrollPositionAlignmentPolicy? scroll}) {
    final ctx = tourKey(id).currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    if (scroll != null) Scrollable.maybeOf(ctx!)?.position.ensureVisible(box, alignmentPolicy: scroll);
    return MatrixUtils.transformRect(box.getTransformTo(me), Offset.zero & box.size);
  }

  void _place({bool resized = false}) {
    if (!mounted) return;
    final me = _self.currentContext?.findRenderObject() as RenderBox?;
    final step = _steps[_i];
    Rect? r, nav, sub;
    if (me != null) {
      for (final id in step.targets) {
        final found = _find(id, me, scroll: ScrollPositionAlignmentPolicy.keepVisibleAtStart);
        if (found != null) r = r == null ? found : r.expandToInclude(found);
      }
      nav = _find(step.navId, me, scroll: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      if (step.subId != null) sub = _find(step.subId!, me, scroll: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      // A long page area (a list) stops inside the window and above the card.
      if (r != null) {
        final edge = 8.u;
        final cardTop = (_card.currentContext?.findRenderObject() as RenderBox?)?.localToGlobal(Offset.zero, ancestor: me).dy;
        var bottom = math.min(r.bottom, me.size.height - edge);
        if (cardTop != null && bottom > cardTop - Sp.x3 && cardTop - Sp.x3 - r.top > 80.u) bottom = cardTop - Sp.x3;
        r = Rect.fromLTRB(math.max(r.left, edge), math.max(r.top, edge), math.min(r.right, me.size.width - edge), bottom);
      }
    }
    final ready = r != null || _tries <= 0;
    if (!ready && !resized) {
      _tries--;
      WidgetsBinding.instance.addPostFrameCallback((_) => _place());
      return;
    }
    setState(() {
      _rect = r;
      _nav = nav;
      _sub = sub;
    });
    if (resized) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _in.value = 1;
    } else {
      _in.forward(from: 0);
    }
    _next.requestFocus();
  }

  /// Done, Skip or Esc: the tour closes on Overview, wherever its step was (its last page is
  /// Help), so a wallet just restored or imported shows its scan at once (#76).
  void _end() {
    ref.read(deskTourProvider.notifier).close();
    if (ref.read(deskNavProvider).route != DeskRoute.overview) ref.read(deskNavProvider.notifier).go(DeskRoute.overview);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final steps = _steps;
    final step = steps[_i];
    final last = _i == steps.length - 1;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final forward = last ? _end : () => _open(_i + 1);
    final back = _i > 0 ? () => _open(_i - 1) : null;
    return LayoutBuilder(
      key: _self,
      builder: (context, box) {
        final size = box.biggest;
        final gap = Sp.x3;
        final cardW = math.min(440.u, size.width - 2 * gap);
        // The content area: right of the sidebar (the rail under 1000 px, nothing under 600).
        final left = size.width >= Bp.desktop ? Ctl.sidebar : (size.width >= Bp.phone ? Ctl.rail : 0.0);
        final cardX = (left + (size.width - left - cardW) / 2).clamp(gap, math.max(gap, size.width - cardW - gap)).roundToDouble();
        final edge = 28.u;
        // Enter is Next (Done on the last step) unless a focused button takes it.
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _end,
            const SingleActivator(LogicalKeyboardKey.enter): forward,
            const SingleActivator(LogicalKeyboardKey.numpadEnter): forward,
            const SingleActivator(LogicalKeyboardKey.arrowRight): forward,
            const SingleActivator(LogicalKeyboardKey.arrowLeft): ?back,
          },
          child: FocusScope(
            autofocus: true,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _end,
                    child: AnimatedBuilder(
                      animation: _in,
                      builder: (_, _) => CustomPaint(
                        painter: _ScrimPainter(
                          holes: [
                            if (_rect != null) (_rect!.inflate(6.u), 10.u),
                            if (_nav != null) (_nav!.inflate(3.u), Rad.sm),
                            if (_sub != null) (_sub!.inflate(3.u), Rad.sm),
                          ],
                          scrim: c.scrim,
                          ring: c.accent,
                          glow: c.glow,
                          t: Curves.easeOutCubic.transform(_in.value),
                          scale: reduce,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  key: _card,
                  left: cardX,
                  bottom: edge,
                  width: cardW,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Semantics(
                      scopesRoute: true,
                      namesRoute: true,
                      explicitChildNodes: true,
                      label: l.deskTourSemantics,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x3),
                        decoration: BoxDecoration(
                          color: c.s4,
                          border: Border.all(color: c.lineStrong),
                          borderRadius: BorderRadius.circular(Rad.lg),
                          boxShadow: [BoxShadow(color: c.scrim, blurRadius: 24.u, offset: Offset(0, 8.u))],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: reduce ? Duration.zero : Dur.fast,
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
                              child: Column(
                                key: ValueKey(_i),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        l.deskTourCounter(_i + 1, steps.length),
                                        style: ts.mono(size: Fs.xs, color: c.accentText),
                                      ),
                                      const Spacer(),
                                      ExcludeSemantics(
                                        child: _Dots(count: steps.length, at: _i, on: c.accent, off: c.lineField),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: Sp.x1),
                                  Semantics(header: true, child: Text(step.titleOf(l), style: ts.h3)),
                                  SizedBox(height: 6.u),
                                  Semantics(liveRegion: true, child: Text(step.textOf(l), style: ts.bodyDim)),
                                ],
                              ),
                            ),
                            SizedBox(height: Sp.x4),
                            Row(
                              children: [
                                EButton(label: l.deskTourSkip, size: EBtnSize.sm, kind: EBtnKind.ghost, hit44: true, onPressed: _end),
                                SizedBox(width: Sp.x2),
                                Text(
                                  'Esc', // l10n-ok: key name
                                  style: ts.mono(size: Fs.xs, color: c.faint),
                                ),
                                const Spacer(),
                                if (back != null) ...[EButton(label: l.deskTourBack, size: EBtnSize.sm, hit44: true, onPressed: back), SizedBox(width: Sp.x2)],
                                Focus(
                                  focusNode: _next,
                                  skipTraversal: true,
                                  child: EButton.primary(label: last ? l.commonDone : l.deskTourNext, size: EBtnSize.sm, hit44: true, onPressed: forward),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Seven dots, the steps up to the current one lit.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.at, required this.on, required this.off});

  final int count, at;
  final Color on, off;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < count; i++)
        Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 5.u),
          child: Container(
            width: 6.u,
            height: 6.u,
            decoration: BoxDecoration(shape: BoxShape.circle, color: i <= at ? on : off),
          ),
        ),
    ],
  );
}

/// The scrim with a rounded hole per lit area, a 1.5 px ring and a soft glow around each.
/// [t] is the rings' fade-in (0 → 1); the first hole (the page area) is drawn 2 % larger at 0.
class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.holes, required this.scrim, required this.ring, required this.glow, required this.t, required this.scale});

  final List<(Rect, double)> holes;
  final Color scrim;
  final Color ring;
  final Color glow;
  final double t;

  /// Reduced motion: no size change while fading in.
  final bool scale;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Path()..addRect(Offset.zero & size);
    if (holes.isEmpty) {
      canvas.drawPath(all, Paint()..color = scrim);
      return;
    }
    var cut = all;
    for (final (r, rad) in holes) {
      final hole = Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(rad)));
      cut = Path.combine(PathOperation.difference, cut, hole);
    }
    canvas.drawPath(cut, Paint()..color = scrim);
    for (final (i, (r0, rad)) in holes.indexed) {
      final r = i == 0 && !scale ? r0.inflate(r0.shortestSide * 0.01 * (1 - t)) : r0;
      final rr = RRect.fromRectAndRadius(r, Radius.circular(rad));
      canvas.drawRRect(
        rr.inflate(2),
        Paint()
          ..color = glow.withValues(alpha: glow.a * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..color = ring.withValues(alpha: ring.a * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.holes.length != holes.length || old.t != t || old.scrim != scrim || old.ring != ring || !_sameHoles(old.holes);

  bool _sameHoles(List<(Rect, double)> o) {
    for (var i = 0; i < o.length; i++) {
      if (o[i].$1 != holes[i].$1 || o[i].$2 != holes[i].$2) return false;
    }
    return true;
  }
}
