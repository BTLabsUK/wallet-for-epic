/// The phone's first-unlock tour: coach marks over the real screens, one step per screen. Each
/// step opens its screen (a Home tab, or a screen pushed over Home), lights what matters on it
/// and says in a line or two what is there; Skip, Back and Next, a step counter, Done on the
/// last. The card sits at the bottom, or at the top when the lit area is low, and never covers
/// what it lights.
///
/// Screens mark what a step lights with [PhoneTourTarget] (`tour_target.dart`); the steps are
/// in `tour_steps.dart`. [PhoneTourAnchor] wraps Home: it opens the tour once, after the first
/// unlock when Home is idle ([PhoneTourController.openIfUnseen]), and shows the overlay over
/// every screen the tour opens. Help › Show the tour again calls [startPhoneTour]. A step
/// never switches a setting on.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../demo.dart';
import '../../l10n.dart';
import '../../providers.dart';
import '../../settings.dart';
import '../contacts_screen.dart';
import '../help_screen.dart';
import '../history_screen.dart';
import '../invoices_screen.dart';
import '../receive_screen.dart' show ReceiveTab, receiveTabProvider;
import '../settings_sections.dart';
import '../theme/tokens.dart';
import 'tour_steps.dart';
import 'tour_target.dart';

export 'tour_steps.dart';
export 'tour_target.dart';

/// The visible card, for tests.
const Key phoneTourCardKey = ValueKey('phone-tour-card');

/// Tests: the steps the overlay shows instead of [phoneTourSteps].
@visibleForTesting
List<PhoneTourStep>? debugPhoneTourSteps;

/// How long Home must have been up, idle, before the tour opens by itself.
const Duration phoneTourStartDelay = Duration(milliseconds: 1200);

/// The fade of the scrim and the rings, in and out alike.
const Duration _fadeTime = Duration(milliseconds: 220);

@immutable
class PhoneTourState {
  const PhoneTourState({this.open = false, this.start = 0});

  final bool open;

  /// The step it opens on (the screenshot tour shows later steps).
  final int start;
}

/// Whether the tour is open, and the seen flag ([AppSettings.phoneTourSeen]) it saves when it
/// opens: it opens by itself once, never again after it was shown or skipped.
class PhoneTourController extends Notifier<PhoneTourState> {
  /// Set by the open overlay: one step back, or the end on the first step. System Back asks it.
  VoidCallback? back;

  @override
  PhoneTourState build() => const PhoneTourState();

  /// False once the container is gone (a test ends, the app exits).
  bool get mounted => ref.mounted;

  /// Opens it now (Help › Show the tour again, the screenshots); saved as seen.
  void open({int at = 0}) {
    state = PhoneTourState(open: true, start: at);
    unawaited(ref.read(appSettingsProvider.notifier).markPhoneTourSeen());
  }

  /// Opens it unless it was seen, by the flag the settings hold now. True when it opened.
  Future<bool> openIfUnseen() async {
    if (state.open) return false;
    final settings = await ref.read(appSettingsProvider.future);
    if (settings.phoneTourSeen || state.open) return false;
    open();
    return true;
  }

  void close() {
    if (state.open) state = const PhoneTourState();
  }
}

final phoneTourProvider =
    NotifierProvider<PhoneTourController, PhoneTourState>(PhoneTourController.new);

/// Opens the tour from its first step, also when it was seen before.
void startPhoneTour(WidgetRef ref) =>
    ref.read(phoneTourProvider.notifier).open();

/// Whether Home opens the tour by itself. Not under `flutter test` (the suites pump Home after
/// an unlock); the tour's own tests turn it on.
final phoneTourAutoProvider = Provider<bool>(
  (ref) => kIsWeb || !WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding'),
);

// ---- anchor --------------------------------------------------------------------------------

/// Wraps Home: starts the tour when it is due and shows its overlay on the root overlay, above
/// every screen the tour opens. System Back moves the tour one step back (it ends on the first).
class PhoneTourAnchor extends ConsumerStatefulWidget {
  const PhoneTourAnchor({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PhoneTourAnchor> createState() => _PhoneTourAnchorState();
}

class _PhoneTourAnchorState extends ConsumerState<PhoneTourAnchor> {
  OverlayEntry? _entry;
  Timer? _timer;
  int _waits = 0;
  late final PhoneTourController _tour = ref.read(phoneTourProvider.notifier);

  @override
  void initState() {
    super.initState();
    _tour;
    if (ref.read(phoneTourAutoProvider) && !ref.read(demoModeProvider)) {
      _timer = Timer(phoneTourStartDelay, _tryStart);
    }
  }

  /// Home idle: its route is the current one (no PIN screen, dialog or sheet over it) on the
  /// Wallet tab. A payment link opened at unlock moved to Send: the link wins, and the tour
  /// waits until Wallet shows again (AND-1).
  void _tryStart() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent || ref.read(shellTabProvider) != ShellTab.wallet) {
      if (++_waits < 30) _timer = Timer(const Duration(seconds: 1), _tryStart);
      return;
    }
    unawaited(_tour.openIfUnseen());
  }

  void _show(int start) {
    if (_entry != null) return;
    final home = ModalRoute.of(context);
    if (home == null) return;
    final navigator = Navigator.of(context);
    final entry = OverlayEntry(
      builder: (_) =>
          PhoneTourOverlay(navigator: navigator, home: home, start: start),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _hide() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry
      ..remove()
      ..dispose();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_entry != null) {
      _hide();
      // Home went away (locked, replaced): the tour is over with it.
      Future.microtask(() {
        if (_tour.mounted) _tour.close();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(phoneTourProvider, (was, now) {
      if (now.open) {
        _show(now.start);
      } else {
        _hide();
      }
    });
    final open = ref.watch(phoneTourProvider.select((s) => s.open));
    return PopScope(
      canPop: !open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) (_tour.back ?? _tour.close)();
      },
      child: widget.child,
    );
  }
}

// ---- overlay -------------------------------------------------------------------------------

/// The tour over the app: a scrim with a hole over the lit area, a ring around it, and the card.
/// It opens each step's screen itself and puts the card where it covers nothing lit.
class PhoneTourOverlay extends ConsumerStatefulWidget {
  const PhoneTourOverlay({
    super.key,
    required this.navigator,
    required this.home,
    this.start = 0,
    this.stepList,
  });

  final NavigatorState navigator;

  /// Home's route: the tour closes every screen it opened by popping back to it.
  final Route<dynamic> home;
  final int start;

  /// Tests: the steps to show instead of [phoneTourSteps].
  final List<PhoneTourStep>? stepList;

  @override
  ConsumerState<PhoneTourOverlay> createState() => _PhoneTourOverlayState();
}

class _PhoneTourOverlayState extends ConsumerState<PhoneTourOverlay>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final List<PhoneTourStep> _steps =
      widget.stepList ??
      debugPhoneTourSteps ??
      phoneTourSteps(
        invoices: ref.read(sessionProvider)?.supportsInvoices ?? false,
      );

  /// The step being opened, and the one the card shows: they differ while the next screen
  /// comes up, so the card and the ring change together, once the page has settled.
  late int _target = widget.start.clamp(0, _steps.length - 1);
  int? _shown;

  /// The ring around the lit area, in this overlay's coordinates; null with nothing lit.
  Rect? _lit;
  bool _atTop = false;
  bool _closing = false;
  int _gen = 0;
  Route<void>? _screen;

  final _self = GlobalKey();
  final _ghost = GlobalKey();
  final _next = FocusNode(debugLabel: 'phone tour next');
  late final _fade = AnimationController(vsync: this, duration: _fadeTime);
  late final _ring = AnimationController(vsync: this, duration: _fadeTime);
  late final PhoneTourController _tour = ref.read(phoneTourProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tour.back = _back;
    WidgetsBinding.instance.addPostFrameCallback((_) => _go(_target));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_tour.back == _back) _tour.back = null;
    _fade.dispose();
    _ring.dispose();
    _next.dispose();
    super.dispose();
  }

  /// A rotation or a window change moves the targets: the ring is placed again.
  @override
  void didChangeMetrics() {
    if (mounted && _shown != null && !_closing) _watch(++_gen);
  }

  bool get _reduce => MediaQuery.disableAnimationsOf(context);

  // ---- navigation

  void _go(int i) {
    if (!mounted || _closing) return;
    setState(() {
      _target = i;
      _lit = null;
    });
    _gen++;
    _navigate(_steps[i].place);
    _watch(_gen);
  }

  void _forward() {
    if (_closing || _shown == null) return;
    _target >= _steps.length - 1 ? unawaited(_end()) : _go(_target + 1);
  }

  void _back() {
    if (_closing) return;
    _target > 0 ? _go(_target - 1) : unawaited(_end());
  }

  /// Opens [place]: a Home tab (closing the screen the tour had open), or a screen pushed over
  /// Home, replacing the previous step's screen.
  void _navigate(TourPlace place) {
    final tab = switch (place) {
      TourPlace.wallet => ShellTab.wallet,
      TourPlace.send => ShellTab.send,
      TourPlace.receive => ShellTab.receive,
      _ => null,
    };
    if (tab != null) {
      _leaveScreens();
      if (place == TourPlace.receive) {
        ref.read(receiveTabProvider.notifier).choose(ReceiveTab.epicbox);
      }
      ref.read(shellTabProvider.notifier).go(tab);
      return;
    }
    final route = MaterialPageRoute<void>(
      builder: (_) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: _screenFor(place),
      ),
    );
    final navigator = widget.navigator;
    if (_screen?.isActive ?? false) {
      navigator.pushReplacement(route);
    } else {
      _leaveScreens();
      navigator.push(route);
    }
    _screen = route;
  }

  Widget _screenFor(TourPlace place) => switch (place) {
    TourPlace.activity => const HistoryScreen(),
    TourPlace.contacts => const ContactsScreen(),
    TourPlace.invoices => const InvoicesScreen(),
    TourPlace.privacy => const SettingsSectionScreen(
      section: SettingsSection.privacyNetwork,
    ),
    TourPlace.advanced => const SettingsSectionScreen(
      section: SettingsSection.advanced,
    ),
    TourPlace.help => const HelpScreen(),
    TourPlace.wallet || TourPlace.send || TourPlace.receive =>
      throw StateError('a tab is not a screen'),
  };

  void _leaveScreens() {
    _screen = null;
    if (!widget.home.isCurrent) {
      widget.navigator.popUntil((r) => r == widget.home);
    }
  }

  /// Done, Skip, system Back on the first step: back to Home's Wallet tab, then the card fades.
  Future<void> _end() async {
    if (_closing) return;
    _closing = true;
    _gen++;
    _leaveScreens();
    ref.read(shellTabProvider.notifier).go(ShellTab.wallet);
    if (!_reduce && _fade.value > 0) {
      await _fade.animateBack(0, curve: Curves.easeIn);
    }
    if (mounted) _tour.close();
  }

  // ---- placing

  /// Waits for the step's screen to come up and hold still, then shows the card and ring on it.
  /// A page builds its targets over a few frames and slides in over ~300 ms, so the targets'
  /// union is read each frame until it has not moved for two.
  void _watch(int gen) {
    var tries = 0;
    var same = 0;
    var scrolled = false;
    Rect? last;
    void tick(Duration _) {
      if (!mounted || gen != _gen || _closing) return;
      final me = _self.currentContext?.findRenderObject() as RenderBox?;
      Rect? union;
      if (me != null && me.hasSize) {
        for (final id in _steps[_target].targets) {
          final ctx = phoneTourContext(id);
          final box = ctx?.findRenderObject() as RenderBox?;
          if (ctx == null || box == null || !box.attached || !box.hasSize) {
            continue;
          }
          if (!scrolled) {
            Scrollable.ensureVisible(
              ctx,
              duration: Duration.zero,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
            );
          }
          final r = MatrixUtils.transformRect(
            box.getTransformTo(me),
            Offset.zero & box.size,
          );
          union = union == null ? r : union.expandToInclude(r);
        }
        scrolled = scrolled || union != null;
      }
      same = union != null && union == last ? same + 1 : 0;
      last = union;
      tries++;
      if ((union != null && same >= 2) || tries >= 90) {
        _apply(union);
      } else {
        WidgetsBinding.instance.addPostFrameCallback(tick);
        WidgetsBinding.instance.scheduleFrame();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(tick);
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Puts the card and the ring: the card at the bottom unless the lit area is low enough to
  /// reach it, then at the top; a lit area that reaches both is cut short above (or below) the
  /// card, on the side that keeps more of it.
  void _apply(Rect? area) {
    final me = _self.currentContext?.findRenderObject() as RenderBox?;
    if (me == null || !me.hasSize) return;
    final size = me.size;
    final pad = MediaQuery.paddingOf(context);
    final cardH =
        (_ghost.currentContext?.findRenderObject() as RenderBox?)?.size.height ??
        0;
    const gap = _cardGap;
    final topEdge = pad.top + gap + cardH + _ringGap;
    final bottomEdge = size.height - pad.bottom - gap - cardH - _ringGap;
    Rect? ring;
    var atTop = false;
    if (area != null) {
      final r = Rect.fromLTRB(
        math.max(area.left - _ringGap, 8),
        math.max(area.top - _ringGap, 8),
        math.min(area.right + _ringGap, size.width - 8),
        math.min(area.bottom + _ringGap, size.height - 8),
      );
      if (r.bottom <= bottomEdge) {
        ring = r;
      } else if (r.top >= topEdge) {
        ring = r;
        atTop = true;
      } else {
        final keepAbove = bottomEdge - r.top;
        final keepBelow = r.bottom - topEdge;
        if (keepAbove >= keepBelow) {
          ring = Rect.fromLTRB(r.left, r.top, r.right, math.max(r.top + 1, bottomEdge));
        } else {
          atTop = true;
          ring = Rect.fromLTRB(r.left, math.min(r.bottom - 1, topEdge), r.right, r.bottom);
        }
      }
    }
    setState(() {
      _shown = _target;
      _lit = ring;
      _atTop = atTop;
    });
    if (_reduce) {
      _fade.value = 1;
      _ring.value = 1;
    } else {
      if (_fade.value < 1) _fade.forward();
      _ring.forward(from: 0);
    }
    _next.requestFocus();
  }

  // ---- build

  static const double _cardGap = 16;
  static const double _ringGap = 6;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final index = _shown ?? _target;
    final placed = _shown != null;
    final scrim = Theme.of(context).colorScheme.scrim;
    return BlockSemantics(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () => unawaited(_end()),
          const SingleActivator(LogicalKeyboardKey.arrowRight): _forward,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _back,
        },
        child: FocusScope(
          autofocus: true,
          child: LayoutBuilder(
            key: _self,
            builder: (context, box) {
              final size = box.biggest;
              final pad = MediaQuery.paddingOf(context);
              final cardW = math.min(440.0, size.width - 2 * _cardGap);
              final cardX = (size.width - cardW) / 2;
              // The card scrolls inside itself past this, for long text or a large font.
              final maxH = math.max(160.0, size.height * 0.5);
              Widget card(int at, {required bool live}) => _TourCard(
                key: live ? phoneTourCardKey : null,
                counter: l.tourPhoneCounter(at + 1, _steps.length),
                title: _steps[at].titleOf(l),
                text: _steps[at].textOf(l),
                last: at == _steps.length - 1,
                first: at == 0,
                maxHeight: maxH,
                nextFocus: live ? _next : null,
                onSkip: () => unawaited(_end()),
                onBack: _back,
                onNext: _forward,
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_fade, _ring]),
                        builder: (_, _) => CustomPaint(
                          painter: _ScrimPainter(
                            hole: _lit,
                            radius: t.radius,
                            scrim: scrim.withValues(alpha: 0.72 * _fade.value),
                            ring: t.accent,
                            t: Curves.easeOut.transform(_ring.value),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The same card, laid out but not shown: its height says where the real one
                  // goes before the step changes.
                  Positioned(
                    left: cardX,
                    top: 0,
                    width: cardW,
                    child: Offstage(
                      child: ExcludeFocus(
                        child: ExcludeSemantics(
                          child: KeyedSubtree(
                            key: _ghost,
                            child: card(_target, live: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: cardX,
                    width: cardW,
                    top: _atTop ? pad.top + _cardGap : null,
                    bottom: _atTop ? null : pad.bottom + _cardGap,
                    child: IgnorePointer(
                      ignoring: !placed || _closing,
                      child: FadeTransition(
                        opacity: placed ? _fade : const AlwaysStoppedAnimation(0),
                        child: Semantics(
                          scopesRoute: true,
                          namesRoute: true,
                          explicitChildNodes: true,
                          label: l.tourPhoneSemantics,
                          child: card(index, live: true),
                        ),
                      ),
                    ),
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

/// The step's card: counter, title and text (scrolling inside when it is long), Skip, Back, Next.
class _TourCard extends StatelessWidget {
  const _TourCard({
    super.key,
    required this.counter,
    required this.title,
    required this.text,
    required this.last,
    required this.first,
    required this.maxHeight,
    required this.nextFocus,
    required this.onSkip,
    required this.onBack,
    required this.onNext,
  });

  final String counter, title, text;
  final bool last, first;
  final double maxHeight;
  final FocusNode? nextFocus;
  final VoidCallback onSkip, onBack, onNext;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final theme = Theme.of(context);
    const tap = Size(48, 48);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Material(
        color: t.surfaceHi,
        elevation: 8,
        shadowColor: theme.colorScheme.scrim,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: t.lineStrong),
          borderRadius: BorderRadius.circular(t.radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                counter,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: t.accentText,
                  fontFamily: t.monoFamily,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: theme.textTheme.titleLarge),
                      ),
                      const SizedBox(height: 6),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          text,
                          style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: tap,
                      foregroundColor: t.dim,
                    ),
                    onPressed: onSkip,
                    child: Text(l.tourPhoneSkip),
                  ),
                  const SizedBox(width: 8),
                  // Back and Next wrap under each other rather than overflow at a large font.
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (!first)
                          TextButton(
                            style: TextButton.styleFrom(minimumSize: tap),
                            onPressed: onBack,
                            child: Text(l.tourPhoneBack),
                          ),
                        FilledButton(
                          focusNode: nextFocus,
                          style: FilledButton.styleFrom(minimumSize: tap),
                          onPressed: onNext,
                          child: Text(last ? l.commonDone : l.tourPhoneNext),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The scrim with a rounded hole over the lit area and a ring around it, [t] its fade-in.
class _ScrimPainter extends CustomPainter {
  _ScrimPainter({
    required this.hole,
    required this.radius,
    required this.scrim,
    required this.ring,
    required this.t,
  });

  final Rect? hole;
  final double radius;
  final Color scrim;
  final Color ring;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Path()..addRect(Offset.zero & size);
    final hole = this.hole;
    if (hole == null) {
      canvas.drawPath(all, Paint()..color = scrim);
      return;
    }
    final rr = RRect.fromRectAndRadius(hole, Radius.circular(radius));
    final cut = Path.combine(
      PathOperation.difference,
      all,
      Path()..addRRect(rr),
    );
    canvas.drawPath(cut, Paint()..color = scrim);
    canvas.drawRRect(
      rr,
      Paint()
        ..color = ring.withValues(alpha: ring.a * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole ||
      old.t != t ||
      old.scrim != scrim ||
      old.ring != ring ||
      old.radius != radius;
}
