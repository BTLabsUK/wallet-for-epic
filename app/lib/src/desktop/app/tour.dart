/// The first-unlock tour: one coachmark at a time next to the element it explains. Skip on
/// every step, Esc and a click outside end it; focus stays in the card while it runs.
///
/// Screens mark what a step points at with [TourTarget]; [startDeskTour] opens it on Overview,
/// and [DeskShell] opens it once by itself the first time Overview shows after an unlock.
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../widgets/kit.dart';

/// One step: [target] is a [TourTarget] id; a step whose target is not on screen shows its
/// card in the middle of the window.
class TourStep {
  const TourStep(this.target, this.title, this.text);

  final String target;
  final String title;
  final String text;
}

final List<TourStep> deskTourSteps = [
  TourStep(
    'balance',
    'Balance',
    'What can be spent now. Confirming, locked and awaiting amounts are listed under it; while the wallet checks the node they are dimmed and marked Updating.',
  ),
  TourStep(
    'send',
    'Send EPIC',
    'To an Epic address or a contact. A review shows everything before anything leaves the wallet.',
  ),
  TourStep(
    'receive',
    'Receive',
    'The Epic address and its QR code, the listener, and transaction files to sign or finalize.',
  ),
  TourStep(
    'receive',
    'Epicbox',
    'Starts with the wallet. The usual way: payments to the Epic address wait while the wallet is offline.',
  ),
  if (DeskFeatures.httpDirect)
    const TourStep(
      'receive',
      'HTTP(S)',
      'Straight from wallet to wallet. Turn the HTTP listener on only when a payment is expected.',
    ),
  TourStep(
    'receive',
    'Transaction files',
    'The most private way: both sides swap files directly, with no server in between.',
  ),
  TourStep(
    'activity',
    'Activity',
    'Every transaction, with its progress. A number here means something waits for an action.',
  ),
  TourStep(
    'settings',
    'Settings',
    'Node, receiving, recovery phrase and rescan; theme and interface scale under Appearance.',
  ),
];

// ---- targets -------------------------------------------------------------------------------

final Map<String, GlobalKey> _keys = {};

/// The key of a tour target; the same object for the same id.
GlobalKey tourKey(String id) =>
    _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'tour:$id'));

/// Marks [child] as what the tour step [id] points at. Use each id once on screen.
class TourTarget extends StatelessWidget {
  const TourTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: tourKey(id), child: child);
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

/// [DeskTourState.seen] is saved with the app's settings ([DeskSettings.tourSeen]), so the tour
/// opens by itself once, not on every start.
class DeskTourController extends Notifier<DeskTourState> {
  @override
  DeskTourState build() => DeskTourState(seen: ref.read(deskProvider).settings.tourSeen);

  void open({int at = 0}) {
    state = DeskTourState(open: true, seen: true, start: at);
    final settings = ref.read(deskProvider).settings;
    if (settings.tourSeen) return;
    unawaited(
      ref.read(deskProvider.notifier).saveSettings(settings.copyWith(tourSeen: true)).catchError((Object e) {
        logWarn('desk', 'tour seen not saved: $e');
      }),
    );
  }

  /// Closes it; a tour that never opened (locked before it showed) still counts as unseen.
  void close() => state = DeskTourState(seen: state.seen);

  /// Forget that it was seen (Settings › Appearance › Show the tour, which opens it again).
  void reset() => state = const DeskTourState();
}

final deskTourProvider = NotifierProvider<DeskTourController, DeskTourState>(
  DeskTourController.new,
);

/// Opens the tour on Overview, also when it was seen before.
void startDeskTour(WidgetRef ref) {
  ref.read(deskTourProvider.notifier).reset();
  ref.read(deskNavProvider.notifier).go(DeskRoute.overview);
  ref.read(deskTourProvider.notifier).open();
}

/// Not by itself under `flutter test` (the smoke tests and the screenshot tour pump Overview).
final bool deskTourAuto = !Platform.environment.containsKey('FLUTTER_TEST');

// ---- overlay -------------------------------------------------------------------------------

/// The tour over the shell: a scrim with a ring around the target, and the card.
class DeskTourOverlay extends ConsumerStatefulWidget {
  const DeskTourOverlay({
    super.key,
    this.stepList,
    this.startAt = 0,
  });

  final List<TourStep>? stepList;

  List<TourStep> get steps => stepList ?? deskTourSteps;
  final int startAt;

  @override
  ConsumerState<DeskTourOverlay> createState() => _DeskTourOverlayState();
}

class _DeskTourOverlayState extends ConsumerState<DeskTourOverlay> {
  late int _i = widget.startAt;
  final _next = FocusNode(debugLabel: 'tour next');
  final _self = GlobalKey();
  Rect? _rect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _place());
  }

  @override
  void dispose() {
    _next.dispose();
    super.dispose();
  }

  void _place() {
    if (!mounted) return;
    final me = _self.currentContext?.findRenderObject() as RenderBox?;
    final ctx = tourKey(widget.steps[_i].target).currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    Rect? r;
    if (me != null && box != null && box.attached && box.hasSize) {
      Scrollable.maybeOf(ctx!)?.position.ensureVisible(
        box,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      r = MatrixUtils.transformRect(
        box.getTransformTo(me),
        Offset.zero & box.size,
      );
    }
    setState(() => _rect = r);
    _next.requestFocus();
  }

  void _go(int i) {
    setState(() => _i = i);
    WidgetsBinding.instance.addPostFrameCallback((_) => _place());
  }

  void _end() => ref.read(deskTourProvider.notifier).close();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final step = widget.steps[_i];
    final last = _i == widget.steps.length - 1;
    final cardW = 320.u;
    return LayoutBuilder(
      key: _self,
      builder: (context, box) {
        final size = box.biggest;
        final gap = Sp.x3;
        final w = math.min(cardW, size.width - 2 * gap);
        final r = _rect;
        final forward = last ? _end : () => _go(_i + 1);
        // Enter is Next (Done on the last step) unless a focused button takes it.
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _end,
            const SingleActivator(LogicalKeyboardKey.enter): forward,
            const SingleActivator(LogicalKeyboardKey.numpadEnter): forward,
          },
          child: FocusScope(
            autofocus: true,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _end,
                    child: CustomPaint(
                      painter: _ScrimPainter(
                        rect: r?.inflate(6.u),
                        scrim: c.scrim,
                        ring: c.accent,
                        radius: Rad.sm,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomSingleChildLayout(
                    delegate: _CardPlace(rect: r, width: w, gap: gap + 6.u),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Semantics(
                        scopesRoute: true,
                        namesRoute: true,
                        explicitChildNodes: true,
                        label: 'Tour of the wallet',
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                            Sp.x5,
                            Sp.x4,
                            Sp.x5,
                            Sp.x3,
                          ),
                          decoration: BoxDecoration(
                            color: c.s4,
                            border: Border.all(color: c.lineStrong),
                            borderRadius: BorderRadius.circular(Rad.lg),
                            boxShadow: [
                              BoxShadow(
                                color: c.scrim,
                                blurRadius: 24.u,
                                offset: Offset(0, 8.u),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_i + 1} of ${widget.steps.length}',
                                style: ts.mono(
                                  size: Fs.xs,
                                  color: c.accentText,
                                ),
                              ),
                              SizedBox(height: Sp.x1),
                              Semantics(
                                header: true,
                                child: Text(step.title, style: ts.h3),
                              ),
                              SizedBox(height: 6.u),
                              Text(step.text, style: ts.bodyDim),
                              SizedBox(height: Sp.x4),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: Sp.x2,
                                runSpacing: Sp.x2,
                                children: [
                                  EButton(
                                    label: 'Skip tour',
                                    size: EBtnSize.sm,
                                    kind: EBtnKind.ghost,
                                    onPressed: _end,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_i > 0) ...[
                                        EButton(
                                          label: 'Back',
                                          size: EBtnSize.sm,
                                          onPressed: () => _go(_i - 1),
                                        ),
                                        SizedBox(width: Sp.x2),
                                      ],
                                      Focus(
                                        focusNode: _next,
                                        skipTraversal: true,
                                        child: EButton.primary(
                                          label: last ? 'Done' : 'Next',
                                          size: EBtnSize.sm,
                                          onPressed: forward,
                                        ),
                                      ),
                                    ],
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
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Places the card next to the ring: right of a narrow target (the sidebar), else below it
/// when it fits, else above; in the middle when there is no target. Always inside the window.
class _CardPlace extends SingleChildLayoutDelegate {
  _CardPlace({required this.rect, required this.width, required this.gap});

  final Rect? rect;
  final double width;
  final double gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) =>
      BoxConstraints(maxWidth: width, minWidth: width, maxHeight: c.maxHeight);

  @override
  Offset getPositionForChild(Size size, Size card) {
    final r = rect;
    final edge = Sp.x3;
    double left, top;
    if (r == null) {
      left = (size.width - card.width) / 2;
      top = (size.height - card.height) / 2;
    } else if (r.right + gap + card.width + edge < size.width &&
        r.width < size.width * 0.3) {
      left = r.right + gap;
      top = r.center.dy - card.height / 2;
    } else if (r.bottom + gap + card.height + edge < size.height) {
      left = r.center.dx - card.width / 2;
      top = r.bottom + gap;
    } else if (r.top - gap - card.height > edge) {
      left = r.center.dx - card.width / 2;
      top = r.top - gap - card.height;
    } else {
      // A target taller than the window allows: over its lower part.
      left = r.center.dx - card.width / 2;
      top = size.height - card.height - edge;
    }
    left = left.clamp(edge, math.max(edge, size.width - card.width - edge));
    top = top.clamp(edge, math.max(edge, size.height - card.height - edge));
    // Whole pixels: a card at .5 px draws its text blurred on Windows.
    return Offset(left.roundToDouble(), top.roundToDouble());
  }

  @override
  bool shouldRelayout(_CardPlace old) =>
      old.rect != rect || old.width != width || old.gap != gap;
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({
    required this.rect,
    required this.scrim,
    required this.ring,
    required this.radius,
  });

  final Rect? rect;
  final Color scrim;
  final Color ring;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Path()..addRect(Offset.zero & size);
    final r = rect;
    if (r == null) {
      canvas.drawPath(all, Paint()..color = scrim);
      return;
    }
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, all, hole),
      Paint()..color = scrim,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.rect != rect || old.scrim != scrim || old.ring != ring;
}
