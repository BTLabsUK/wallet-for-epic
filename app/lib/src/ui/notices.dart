// SPDX-License-Identifier: Apache-2.0
/// The app's one way to tell the user something happened: a toast floating at the top of the
/// screen ([NoticeDock], in every `SlotScaffold`), over the content and clear of the bottom.
/// `app/README.md` "Notifications" has the standard.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../desktop/theme/tokens.dart' show Motion;
import '../desktop/widgets/motion.dart' show ExpandFade;
import 'notice_layout.dart';
import 'settings_rows.dart' show NavChevron;
import 'kit/kit_icons.dart';
import 'kit/kit_tokens.dart';
import 'theme/tokens.dart';

export 'notice_layout.dart' show NoticeLayout, RenderNoticeLayout;

/// How much a notice matters. Each has its own icon and token colour.
enum NoticeLevel {
  info,
  success,
  warning,
  error;

  /// Which notice gives way: a new one queues behind a visible one of a higher rank. Info and
  /// success both only confirm, so they share the lowest.
  int get rank => switch (this) {
    info || success => 0,
    warning => 1,
    error => 2,
  };
}

/// How long a notice of [level] stays unless it is persistent: success 3 s, info 4 s, warning
/// 6 s, error 8 s; 4 s more with an action; twice as long for a screen reader or switch access
/// ([accessible], `MediaQuery.accessibleNavigation`).
Duration noticeDuration(
  NoticeLevel level, {
  bool action = false,
  bool accessible = false,
}) {
  var seconds = switch (level) {
    NoticeLevel.success => 3,
    NoticeLevel.info => 4,
    NoticeLevel.warning => 6,
    NoticeLevel.error => 8,
  };
  if (action) seconds += 4;
  if (accessible) seconds *= 2;
  return Duration(seconds: seconds);
}

/// Notices waiting behind a visible one of a higher level; the oldest goes first.
const int maxQueuedNotices = 3;

/// The key of the visible notice card, for tests.
const Key noticeKey = ValueKey('notice');

/// A button on a notice. Pressing it also closes the notice.
class NoticeAction {
  const NoticeAction(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}

/// A short message: three lines on screen at most, the whole text for a screen reader.
class Notice {
  const Notice(
    this.id,
    this.text, {
    required this.level,
    this.title,
    this.action,
    this.secondary,
    this.persistent = false,
    this.progress,
    this.progressLabel,
    this.tag,
    this.onClose,
    this.items = const [],
    this.icon,
  });

  /// Distinct per notice, so the card animates when another one takes its place.
  final int id;
  final String text;
  final NoticeLevel level;

  /// A few bold words above [text], which then reads as the quieter detail.
  final String? title;
  final NoticeAction? action;

  /// A second, quieter button before [action] ("Not now"); with it both sit under the text.
  final NoticeAction? secondary;

  /// Stays until closed or replaced, instead of leaving after [noticeDuration].
  final bool persistent;

  /// Work in progress inside the card, from 0 to 1, with its screen-reader label.
  final double? progress;
  final String? progressLabel;

  /// Notices with the same tag are one subject (the update), so a newer one updates it in
  /// place, wherever it is, instead of stacking.
  final String? tag;

  /// Runs when the user closes the notice (its close button or a swipe), not when it times
  /// out, is replaced or its action is pressed.
  final VoidCallback? onClose;

  /// What [text] counts, one line each ("2 invoices", "1 withdrawal"): folded under the text,
  /// a tap on the card or its chevron unfolds them, each a way to its own place. A digest.
  final List<NoticeAction> items;

  /// A drawn mark of the notice's own (an arrival's arrow) in place of its level's.
  final IconData? icon;

  /// Has a close button: the ones that stay until closed (the frame draws the × there only);
  /// the others leave on their own, by a swipe, or by their action.
  bool get closable => persistent || items.isNotEmpty;
}

/// The visible notice; every [NoticeDock] shows it.
final noticeProvider = NotifierProvider<NoticeNotifier, Notice?>(
  NoticeNotifier.new,
);

class NoticeNotifier extends Notifier<Notice?> {
  static const Duration _tick = Duration(milliseconds: 100);

  final List<Notice> _queue = [];
  Timer? _timer;
  Duration _left = Duration.zero;
  bool _held = false;
  int _next = 0;

  /// Whether a screen reader or switch access is on; [NoticeDock] keeps it current.
  bool accessibleNavigation = false;

  @override
  Notice? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  /// The notices waiting, next first.
  List<Notice> get queued => List.unmodifiable(_queue);

  /// Shows [text] at [level]. It replaces the visible notice, unless that one has a higher
  /// level: then it waits (at most [maxQueuedNotices], the oldest dropped). The same text
  /// again restarts the visible notice's timer instead of stacking. A persistent notice that
  /// gets replaced waits to come back.
  void show(
    String text, {
    required NoticeLevel level,
    String? title,
    NoticeAction? action,
    NoticeAction? secondary,
    bool persistent = false,
    double? progress,
    String? progressLabel,
    String? tag,
    VoidCallback? onClose,
    List<NoticeAction> items = const [],
    IconData? icon,
  }) {
    Notice make(int id) => Notice(
      id,
      text,
      level: level,
      title: title,
      action: action,
      secondary: secondary,
      persistent: persistent,
      progress: progress,
      progressLabel: progressLabel,
      tag: tag,
      onClose: onClose,
      items: items,
      icon: icon,
    );
    final visible = state;
    if (visible != null &&
        ((tag != null && visible.tag == tag) ||
            (visible.text == text && visible.level == level))) {
      _display(make(visible.id));
      return;
    }
    final i = _queue.indexWhere(
      (n) =>
          (tag != null && n.tag == tag) || (n.text == text && n.level == level),
    );
    if (i >= 0) {
      _queue[i] = make(_queue[i].id);
      return;
    }
    final notice = make(_next++);
    if (visible != null && visible.level.rank > level.rank) {
      _queue.add(notice);
      if (_queue.length > maxQueuedNotices) _queue.removeAt(0);
      return;
    }
    if (visible != null && visible.persistent) {
      // It goes first and stays; over the cap, the newest waiting one gives way to it.
      _queue.insert(0, visible);
      if (_queue.length > maxQueuedNotices) _queue.removeLast();
    }
    _display(notice);
  }

  /// Closes the visible notice, or the one with [id] wherever it is; the next one shows.
  void dismiss([int? id]) {
    if (id != null && state?.id != id) {
      _queue.removeWhere((n) => n.id == id);
      return;
    }
    _timer?.cancel();
    state = null;
    if (_queue.isNotEmpty) _display(_queue.removeAt(0));
  }

  /// Closes every notice with [tag], visible or waiting.
  void dismissTag(String tag) {
    _queue.removeWhere((n) => n.tag == tag);
    if (state?.tag == tag) dismiss();
  }

  /// Closes everything, for tests that need a clear screen.
  void clear() {
    _queue.clear();
    _timer?.cancel();
    state = null;
  }

  /// Stops the clock while the pointer is on the card (hover or press).
  void hold() => _held = true;

  void release() => _held = false;

  void _display(Notice notice) {
    _timer?.cancel();
    // A notice updated in place (the same text, or its tag) keeps a hold from the pointer.
    if (state?.id != notice.id) _held = false;
    state = notice;
    if (notice.persistent) return;
    _left = noticeDuration(
      notice.level,
      action: notice.action != null || notice.items.isNotEmpty,
      accessible: accessibleNavigation,
    );
    _timer = Timer.periodic(_tick, (_) {
      if (_held) return;
      _left -= _tick;
      if (_left <= Duration.zero) dismiss(notice.id);
    });
  }
}

/// How long the toast takes to drop in, and to leave (HANDOFF 5.6: 220 ms in, 160 ms out).
const Duration noticeDockDuration = Duration(milliseconds: 220);
const Duration noticeDockLeave = Duration(milliseconds: 160);

/// Where the visible notice shows: a floating toast at the top of the screen, 50 dp from its top
/// edge and 12 dp from the sides, over the content, so it never covers the gold button or the
/// keypad at the bottom. `SlotScaffold` puts one on every screen; it takes no room in the
/// layout, and the toast is drawn in the [Overlay] above the screen. Every dock shows the same
/// notice, so one survives a pop.
class NoticeDock extends ConsumerStatefulWidget {
  const NoticeDock({super.key});

  @override
  ConsumerState<NoticeDock> createState() => _NoticeDockState();
}

class _NoticeDockState extends ConsumerState<NoticeDock> with SingleTickerProviderStateMixin {
  /// The docks alive now, oldest first. Only the newest draws the toast: a flow pushed over a
  /// screen has its own dock, and the screen under it is still built.
  static final List<_NoticeDockState> _live = [];
  static final ValueNotifier<int> _liveChanged = ValueNotifier(0);

  bool get _top => _live.isNotEmpty && identical(_live.last, this);

  final OverlayPortalController _portal = OverlayPortalController();
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: noticeDockDuration,
    reverseDuration: noticeDockLeave,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _open,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  /// The notice on show; it stays while the toast leaves.
  Notice? _shown;

  @override
  void initState() {
    super.initState();
    _live.add(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _liveChanged.value++);
    // A screen opened while a notice shows starts with the toast in place.
    _shown = ref.read(noticeProvider);
    if (_shown != null) {
      _open.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shown != null) _portal.show();
      });
    }
  }

  @override
  void dispose() {
    _live.remove(this);
    // Not during this frame's build: the docks that listen rebuild after it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _liveChanged.value++);
    _open.dispose();
    super.dispose();
  }

  void _onNotice(Notice? _, Notice? notice) {
    // Reduced motion, or a screen under another one (its tickers stopped), moves at once.
    final cut = MediaQuery.disableAnimationsOf(context) || !TickerMode.valuesOf(context).enabled;
    if (notice != null) {
      setState(() => _shown = notice);
      _portal.show();
      if (cut) {
        _open.value = 1;
      } else {
        _open.forward();
      }
      return;
    }
    if (cut) {
      _open.value = 0;
      _portal.hide();
      setState(() => _shown = null);
      return;
    }
    _open.reverse().whenCompleteOrCancel(() {
      if (mounted && ref.read(noticeProvider) == null) {
        _portal.hide();
        setState(() => _shown = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Notice?>(noticeProvider, _onNotice);
    ref.read(noticeProvider.notifier).accessibleNavigation = MediaQuery.accessibleNavigationOf(context);
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => ListenableBuilder(
        listenable: _liveChanged,
        builder: (context, _) => _top ? _toast(context) : const SizedBox.shrink(),
      ),
      child: const SizedBox.shrink(),
    );
  }

  Widget _toast(BuildContext context) {
    final shown = _shown;
    if (shown == null) return const SizedBox.shrink();
    final still = MediaQuery.disableAnimationsOf(context);
    // The status bar, or 50 dp, whichever is lower on the screen.
    final inset = MediaQueryData.fromView(View.of(context)).padding.top;
    final top = inset > Kit.toastTop ? inset : Kit.toastTop;
    final card = AnimatedSwitcher(
      duration: still ? Duration.zero : const Duration(milliseconds: 150),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: NoticeCard(key: ValueKey(shown.id), notice: shown),
    );
    return Positioned(
      top: top,
      left: Kit.toastSide,
      right: Kit.toastSide,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) => Opacity(
          opacity: _curve.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, -(1 - _curve.value) * 28), child: child),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            // The overlay has no Material above it: the buttons and ink in the toast need one.
            child: Material(type: MaterialType.transparency, child: card),
          ),
        ),
      ),
    );
  }
}

/// The icon and token colour of [level].
(IconData, Color) noticeLook(WalletTokens t, NoticeLevel level) =>
    switch (level) {
      NoticeLevel.info => (Icons.info_outline, t.info),
      NoticeLevel.success => (Icons.check_circle_outline, t.ok),
      NoticeLevel.warning => (Icons.warning_amber_rounded, t.warn),
      NoticeLevel.error => (Icons.error_outline, t.risk),
    };

/// What a screen reader says before the text.
String noticeLevelLabel(AppLocalizations l, NoticeLevel level) =>
    switch (level) {
      NoticeLevel.info => l.noticeLevelInfo,
      NoticeLevel.success => l.noticeLevelSuccess,
      NoticeLevel.warning => l.noticeLevelWarning,
      NoticeLevel.error => l.noticeLevelError,
    };

/// The toast [NoticeDock] shows (HANDOFF 7.6): a blurred floating card, radius 20, with the
/// level's icon in a 34 dp circle, one or two lines of words (a bold title over a dim detail), a
/// gold text button, a close ×, and a 3 dp progress line when work is running. A swipe up (or
/// sideways) sends it away. A digest unfolds its items under the words.
class NoticeCard extends ConsumerStatefulWidget {
  const NoticeCard({super.key, required this.notice});

  final Notice notice;

  @override
  ConsumerState<NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends ConsumerState<NoticeCard> {
  /// How far a swipe has moved the card: sideways either way, or up.
  Offset _drag = Offset.zero;

  /// Whether a mouse is over the card: then lifting a click does not restart the clock.
  bool _hovering = false;

  /// Whether the notice's [Notice.items] are unfolded; the clock stops while they are.
  bool _open = false;

  NoticeNotifier get _notices => ref.read(noticeProvider.notifier);

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _notices.hold();
    } else {
      _releaseUnlessHovered();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final v = details.velocity.pixelsPerSecond;
    final width = context.size?.width ?? 300;
    final away = _drag.dx.abs() > width / 3 || _drag.dy < -32 || v.dx.abs() > 700 || v.dy < -500;
    if (away) {
      _notices.dismiss(widget.notice.id);
      widget.notice.onClose?.call();
    } else {
      setState(() => _drag = Offset.zero);
    }
    _releaseUnlessHovered();
  }

  void _releaseUnlessHovered() {
    if (!_hovering && !_open) _notices.release();
  }

  TextButton _textButton(NoticeAction a, {required bool primary}) {
    final t = context.tokens;
    return TextButton(
      onPressed: () {
        _notices.dismiss(widget.notice.id);
        a.onPressed();
      },
      style: TextButton.styleFrom(
        foregroundColor: primary ? t.accentText : t.dim,
        // From the theme's label style, so the fallback fonts (Thai, Chinese) stay.
        textStyle: Theme.of(context).textTheme.labelLarge?.merge(KitType.toastAction),
        minimumSize: const Size(0, 40), // `.ta` min-height
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(a.label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notice = widget.notice;
    final t = context.tokens;
    final l = context.l10n;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (_, color) = noticeLook(t, notice.level);
    final icon = notice.icon ?? switch (notice.level) {
      NoticeLevel.info => KitIcons.info,
      NoticeLevel.success => KitIcons.check,
      NoticeLevel.warning => KitIcons.warning,
      NoticeLevel.error => KitIcons.error,
    };
    final action = notice.action;
    final secondary = notice.secondary;
    final items = notice.items;
    final progress = notice.progress;
    final still = MediaQuery.disableAnimationsOf(context);
    final title = notice.title, text = notice.text;
    final lines = notice.persistent ? null : noticeMaxLines;
    final cut = lines == null ? null : TextOverflow.ellipsis;

    final words = Semantics(
      container: true,
      liveRegion: true,
      label: '${noticeLevelLabel(l, notice.level)}: ${[?title, text].join('. ')}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // `.tt` is weight 500; its `small` is 12.5 regular, dim, 2 below.
            if (title != null) Text(title, maxLines: lines, overflow: cut, style: KitType.toast.copyWith(color: t.text, fontWeight: FontWeight.w500)),
            if (title != null) const SizedBox(height: 2),
            Text(
              text,
              maxLines: lines,
              overflow: cut,
              style: title == null
                  ? KitType.toast.copyWith(color: t.text, fontWeight: FontWeight.w500)
                  : KitType.toast.copyWith(color: t.dim, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
    final wordsTap = items.isEmpty ? words : GestureDetector(behavior: HitTestBehavior.opaque, onTap: _toggle, child: words);

    final chevron = items.isEmpty
        ? null
        : IconButton(
            key: noticeUnfoldKey,
            tooltip: _open ? l.msgCheckHideDetails : l.msgCheckShowDetails,
            onPressed: _toggle,
            icon: AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: still ? Duration.zero : noticeUnfoldDuration,
              curve: Curves.easeOutCubic,
              child: Icon(Icons.expand_more, color: t.dim),
            ),
          );
    final close = notice.closable
        ? IconButton(
            tooltip: l.commonClose,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: Icon(KitIcons.close, size: 16, color: t.faint),
            onPressed: () {
              _notices.dismiss(notice.id);
              notice.onClose?.call();
            },
          )
        : null;

    // The items unfold under the whole card, the words' left edge as their own.
    final unfold = items.isEmpty
        ? null
        : ExpandFade(
            open: _open,
            child: Padding(
              key: noticeItemsKey,
              padding: const EdgeInsetsDirectional.only(start: _wordsStart - 8, end: 4, bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items)
                    InkWell(
                      onTap: () {
                        _notices.dismiss(notice.id);
                        item.onPressed();
                      },
                      borderRadius: BorderRadius.circular(t.radiusSmall),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: Kit.hitMin),
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.label, style: KitType.toast.copyWith(color: t.text))),
                            const NavChevron(size: 20),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );

    final trailing = [?chevron, ?close];
    final body = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(11, 0, 10, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoticeLayout(
            icon: ExcludeSemantics(
              child: Container(
                width: Kit.toastIcon,
                height: Kit.toastIcon,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: dark ? 0.16 : 0.14)),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: color),
              ),
            ),
            words: Padding(
              padding: const EdgeInsets.symmetric(vertical: _wordsPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  wordsTap,
                  if (progress != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          color: t.accentText,
                          backgroundColor: t.fill,
                          semanticsLabel: notice.progressLabel,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: action == null
                ? null
                : Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 4,
                    children: [if (secondary != null) _textButton(secondary, primary: false), _textButton(action, primary: true)],
                  ),
            close: trailing.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsetsDirectional.only(start: 11),
                    child: Row(mainAxisSize: MainAxisSize.min, children: trailing),
                  ),
            iconGap: 11,
            actionGap: 11,
            firstLine: 14.5 * 1.3 + 2 * _wordsPad,
            textEnd: 0,
            minHeight: Kit.toastMin,
            centered: true,
          ),
          ?unfold,
        ],
      ),
    );

    final radius = BorderRadius.circular(Kit.rGroup);
    return Listener(
      onPointerDown: (_) => _notices.hold(),
      onPointerUp: (_) => _releaseUnlessHovered(),
      onPointerCancel: (_) => _releaseUnlessHovered(),
      child: MouseRegion(
        onEnter: (_) {
          _hovering = true;
          _notices.hold();
        },
        onExit: (_) {
          _hovering = false;
          _notices.release();
        },
        child: GestureDetector(
          onPanUpdate: (d) => setState(() => _drag += d.delta),
          onPanEnd: _onDragEnd,
          onPanCancel: () => setState(() => _drag = Offset.zero),
          child: Transform.translate(
            offset: Offset(_drag.dx, _drag.dy < 0 ? _drag.dy : 0),
            child: Opacity(
              opacity: (1 - _drag.distance / 300).clamp(0.2, 1),
              child: DecoratedBox(
                key: noticeKey,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.6 : 0.16), offset: const Offset(0, 14), blurRadius: 34)],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: Kit.blur, sigmaY: Kit.blur),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.group,
                        borderRadius: radius,
                        border: Border.all(color: t.hair2),
                      ),
                      child: body,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The space above and below the words inside the card.
const double _wordsPad = 10;

/// Where the words start inside the card's body: the level's icon and the gap after it.
const double _wordsStart = 11 + Kit.toastIcon + 11;

/// How long a digest takes to unfold its items, and to fold them.
const Duration noticeUnfoldDuration = Motion.expand;

/// The chevron that unfolds a digest, and its items once unfolded: for tests.
const Key noticeUnfoldKey = ValueKey('notice-unfold');
const Key noticeItemsKey = ValueKey('notice-items');

/// The most lines a passing toast shows; a persistent one shows its whole text. The screen
/// reader always hears all of it.
const int noticeMaxLines = 2;

/// The surface of every phone notice, docked or in the flow: the panel's surface and hairline,
/// with [color] (the level's) as a 3 dp leading edge. No corner brackets: those are brand art.
class NoticeSurface extends StatelessWidget {
  const NoticeSurface({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusSmall),
        side: BorderSide(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(start: BorderSide(color: color, width: 3)),
        ),
        child: child,
      ),
    );
  }
}

/// A phone notice's parts in [NoticeLayout]: the level's icon, a bold [title] and/or a regular
/// [text] (dim under a title), [below] (a progress bar), the [actions] beside the words while
/// they fit on one line and on their own row under them otherwise, and [close] at the end. A
/// screen reader hears the level and the words as one.
class NoticeParts extends StatelessWidget {
  const NoticeParts({
    super.key,
    required this.level,
    this.title,
    this.text,
    this.maxLines,
    required this.icon,
    required this.color,
    this.below,
    this.onWords,
    this.actions = const [],
    this.actionsBelow = false,
    this.close,
    this.liveRegion = false,
  }) : assert(title != null || text != null);

  final NoticeLevel level;
  final String? title;
  final String? text;
  final int? maxLines;
  final IconData icon;
  final Color color;
  final Widget? below;

  /// A tap on the words (a digest unfolds); the chevron in [actions] says what it does.
  final VoidCallback? onWords;
  final List<Widget> actions;
  final bool actionsBelow;
  final Widget? close;
  final bool liveRegion;

  /// Space above and below the words, inside the card's 4 dp.
  static const double wordsPad = 8;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14, height: 1.43);
    final line = MediaQuery.textScalerOf(context).scale(base.fontSize ?? 14) * (base.height ?? 1.43);
    final title = this.title, text = this.text;
    final cut = maxLines == null ? null : TextOverflow.ellipsis;
    final words = Semantics(
      container: true,
      liveRegion: liveRegion,
      label: '${noticeLevelLabel(l, level)}: ${[?title, ?text].join('. ')}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(title, maxLines: maxLines, overflow: cut, style: base.copyWith(color: t.text, fontWeight: FontWeight.w600)),
            if (text != null)
              Text(text, maxLines: maxLines, overflow: cut, style: base.copyWith(color: title == null ? t.text : t.dim)),
          ],
        ),
      ),
    );
    final wordsRow = onWords == null
        ? words
        : GestureDetector(behavior: HitTestBehavior.opaque, onTap: onWords, child: words);
    return NoticeLayout(
      icon: ExcludeSemantics(child: Icon(icon, color: color)),
      words: Padding(
        padding: const EdgeInsets.symmetric(vertical: wordsPad),
        child: below == null
            ? wordsRow
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [wordsRow, below!],
              ),
      ),
      actions: actions.isEmpty
          ? null
          : Wrap(alignment: WrapAlignment.end, spacing: 4, children: actions),
      actionsBelow: actionsBelow,
      close: close,
      iconGap: 12,
      actionGap: 4,
      firstLine: line + 2 * wordsPad,
      textEnd: 12,
      minHeight: 48,
      centered: true,
    );
  }
}

/// A notice in the flow of a screen, where it stays while its reason does (a refused amount,
/// a warning before the recovery phrase): the docked card's look and anatomy ([NoticeSurface],
/// [NoticeParts]), never cut, with no timer. A screen's passing messages go through
/// [NoticeNotifier.show] instead. [icon] replaces the level's own; [onClose] adds a close
/// button named [closeLabel] (Close by default).
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.level,
    this.title,
    this.text,
    this.icon,
    this.actions = const [],
    this.actionsBelow = false,
    this.below,
    this.onClose,
    this.closeKey,
    this.closeLabel,
    this.liveRegion = false,
  }) : assert(title != null || text != null);

  final NoticeLevel level;
  final String? title;
  final String? text;
  final IconData? icon;
  final Key? closeKey;
  final List<Widget> actions;
  final bool actionsBelow;
  final Widget? below;
  final VoidCallback? onClose;
  final String? closeLabel;

  /// Announced when it appears or changes (an error after a tap).
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final (glyph, color) = noticeLook(context.tokens, level);
    final onClose = this.onClose;
    return NoticeSurface(
      color: color,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 4, 4),
        child: NoticeParts(
          level: level,
          title: title,
          text: text,
          icon: icon ?? glyph,
          color: color,
          below: below,
          actions: actions,
          actionsBelow: actionsBelow,
          liveRegion: liveRegion,
          close: onClose == null
              ? null
              : IconButton(
                  key: closeKey,
                  tooltip: closeLabel ?? context.l10n.commonClose,
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
        ),
      ),
    );
  }
}
