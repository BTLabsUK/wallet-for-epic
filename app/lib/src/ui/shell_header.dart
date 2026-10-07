import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'status.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';

/// The key of Wallet's balance area: the figure, the fiat row and the pending line, for tests.
const Key walletBalanceKey = ValueKey('wallet-balance');

/// The key of Wallet's figure, for tests.
const Key balanceFigureKey = ValueKey('balance-figure');

/// The key of the gold EPIC at the figure's top right, for tests.
const Key balanceUnitKey = ValueKey('balance-unit');

/// The key of the fiat value under the figure, for tests.
const Key fiatValueKey = ValueKey('balance-fiat');

/// The key of the pending line under the fiat row, for tests.
const Key pendingLineKey = ValueKey('pending-line');

/// The key of the pending line's moving part, a [Transform], for tests.
const Key pendingReelKey = ValueKey('pending-reel');

/// The key of the figure in the app bar's title on Send and Receive, for tests.
const Key titleFigureKey = ValueKey('title-figure');

/// The key of the pulsing dot after that figure while anything is pending, for tests.
const Key pendingDotKey = ValueKey('pending-dot');

/// The key of the statuses in the app bar, for tests.
const Key barStatusesKey = ValueKey('statuses-bar');

/// The key of the statuses in Wallet's fiat row, when the app bar has no room for them.
const Key walletStatusesKey = ValueKey('statuses-wallet');

/// The key of the statuses under the app bar on Send and Receive, when the bar has no room.
const Key tabStatusesKey = ValueKey('statuses-tab');

/// The key of the sync line along the app bar's foot, for tests.
const Key headerSyncLineKey = ValueKey('header-sync-line');

/// The key of the sweep along the app bar's foot when a payment lands, for tests.
const Key landingSweepKey = ValueKey('landing-sweep');

/// The width of the app bar's leading slot, the mark. The title, and so the figure on Send
/// and Receive, starts here.
const double shellLeadingWidth = 48;

/// The height of the row under the app bar that holds the statuses on Send and Receive when
/// the bar has no room for them.
const double tabStatusRowHeight = 30;

/// How much narrower than the room the titles must be before the statuses move back into
/// the app bar, so they do not flap at the boundary.
const double statusHysteresis = 8;

/// How long the sweep takes when a payment lands.
const Duration landingSweepDuration = Duration(milliseconds: 1200);

/// How fast the pending line scrolls when it does not fit, in dp per second.
const double pendingLineSpeed = 24;

/// How long each item of the pending line shows with reduced motion, when it does not fit.
const Duration pendingLineStep = Duration(seconds: 4);

/// The size Wallet's figure starts at, and the least it shrinks to.
const double figureSize = 60, figureMinSize = 34;

/// How far the header is open, from the shell's page position: 1 on Wallet, 0 on Send and
/// Receive, in between while a swipe or a tap moves the page.
double headerOpenness(double page) =>
    (1 - (page - ShellTab.wallet.index).abs()).clamp(0.0, 1.0);

/// A layer's opacity at [share] of the way to it: out of sight until 0.4, full from 0.6, so
/// the two layers of a cross-fade barely show at once.
double shellFade(double share) => ((share - 0.4) / 0.2).clamp(0.0, 1.0);

/// Whether the statuses belong in the app bar, given where they are now ([inBar]): the widest
/// title on any tab needs [need], the bar gives the title [room], and the statuses take
/// [statuses] of it while in the bar. They leave once a title does not fit beside them, and
/// come back only when every title fits with [statusHysteresis] to spare.
bool statusesInBar({
  required bool inBar,
  required double need,
  required double room,
  required double statuses,
}) {
  if (inBar) return need <= room;
  return need <= room - statuses - statusHysteresis;
}

/// Whether [after] is [before] with a pending payment landed: spendable rose while the money
/// on its way in (confirming, waiting to finish, mining rewards) fell. A cancelled send, a
/// new payment on its way, or the first balance of a wallet is not one.
bool paymentLanded(WalletSummary? before, WalletSummary? after) {
  if (before == null || after == null) return false;
  BigInt incoming(WalletSummary s) =>
      s.awaitingConfirmation + s.awaitingFinalization + s.immature;
  return after.spendable > before.spendable &&
      incoming(after) < incoming(before);
}

/// The balances that are not spendable yet, in the pending line's order.
enum PendingKind { confirming, waiting, locked, mining }

/// One item of the pending line: what it is, its glyph and its words. [kind] is null for the
/// calm line ("All confirmed", "Nothing here yet").
typedef PendingItem = ({PendingKind? kind, IconData icon, String text});

/// The pending line's items for [summary]: each non-zero balance not spendable yet, in
/// [PendingKind] order; with none, "All confirmed", or "Nothing here yet" when the wallet has
/// had no payments ([empty]).
List<PendingItem> pendingItems(
  AppLocalizations l,
  WalletSummary summary, {
  required bool hidden,
  required bool empty,
}) {
  String amount(BigInt v) =>
      hidden ? hiddenAmount : localDigits(l, displayEpic(v));
  final items = <PendingItem>[
    if (summary.awaitingConfirmation > BigInt.zero)
      (
        kind: PendingKind.confirming,
        icon: Icons.south_west,
        text: l.balanceLineConfirming(amount(summary.awaitingConfirmation)),
      ),
    if (summary.awaitingFinalization > BigInt.zero)
      (
        kind: PendingKind.waiting,
        icon: Icons.schedule,
        text: l.balanceLineWaiting(amount(summary.awaitingFinalization)),
      ),
    if (summary.locked > BigInt.zero)
      (
        kind: PendingKind.locked,
        icon: Icons.lock_outline,
        text: l.balanceLineLocked(amount(summary.locked)),
      ),
    if (summary.immature > BigInt.zero)
      (
        kind: PendingKind.mining,
        icon: Icons.bolt,
        text: l.balanceLineMining(amount(summary.immature)),
      ),
  ];
  if (items.isNotEmpty) return items;
  return [
    (
      kind: null,
      icon: Icons.check,
      text: empty ? l.balanceLineNothingYet : l.balanceLineAllConfirmed,
    ),
  ];
}

/// Whether anything in [summary] is not spendable yet.
bool hasPending(WalletSummary summary) =>
    summary.awaitingConfirmation > BigInt.zero ||
    summary.awaitingFinalization > BigInt.zero ||
    summary.locked > BigInt.zero ||
    summary.immature > BigInt.zero;

/// What a screen reader says for the spendable balance.
String _spendableLabel(AppLocalizations l, BigInt spendable, bool hidden) =>
    l.balanceHelpRow(
      l.homeBalanceSpendable,
      hidden ? l.homeBalanceHiddenLabel : epicText(l, spendable),
    );

/// Wallet's balance area, with no panel around it: the spendable figure in Montserrat 60,
/// the gold EPIC at its top right; under it one row with the statuses when the app bar has no
/// room for them ([statuses]), the fiat value, the eye and the ?; under that the pending line.
///
/// Every part has a fixed height for the text scale, so nothing here moves when amounts
/// change, a payment lands, amounts are hidden or nothing is pending. A figure too wide shrinks
/// to fit, to [figureMinSize] at least, and never wraps.
class WalletBalance extends ConsumerWidget {
  const WalletBalance({super.key, required this.statuses});

  final bool statuses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final scaler = MediaQuery.textScalerOf(context);
    final data = ref.watch(homeProvider).value;
    final summary = data?.summary;
    final display = amountDisplay(ref);
    final hidden = display.hidden;
    final fiat = summary == null
        ? null
        : approxFiat(l, summary.spendable, display, short: true);
    final fiatStyle = TextStyle(
      fontFamily: t.monoFamily,
      fontSize: 13,
      color: t.dim,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final rowHeight = math.max(
      statusTarget,
      _lineHeight(fiatStyle, scaler, context),
    );
    final eye = IconButton(
      tooltip: hidden ? l.homeShowBalances : l.homeHideBalances,
      iconSize: statusGlyph,
      color: t.dim,
      icon: Icon(
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: () =>
          ref.read(appSettingsProvider.notifier).setHideBalances(!hidden),
    );
    // The area's own start is [statusInset] before the figure, so a status target or the eye
    // that leads its row puts its glyph under the figure's first digit.
    return Semantics(
      container: true,
      child: Padding(
        key: walletBalanceKey,
        padding: const EdgeInsetsDirectional.fromSTEB(
          18 - statusInset,
          20,
          18,
          4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: statusInset),
              child: SizedBox(
                height: figureSize,
                child: summary == null
                    ? const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _Figure(spendable: summary.spendable, hidden: hidden),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: rowHeight,
              child: summary == null
                  ? null
                  : Row(
                      children: [
                        if (statuses) const BarStatuses(key: walletStatusesKey),
                        if (fiat != null)
                          Flexible(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: statuses ? 0 : statusInset,
                              ),
                              child: FittedBox(
                                key: fiatValueKey,
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  fiat,
                                  maxLines: 1,
                                  style: fiatStyle,
                                ),
                              ),
                            ),
                          ),
                        eye,
                        BalanceHelp(summary: summary, hidden: hidden),
                      ],
                    ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: statusInset),
              child: PendingLine(
                items: summary == null
                    ? const []
                    : pendingItems(
                        l,
                        summary,
                        hidden: hidden,
                        empty: data?.transactions.isEmpty ?? false,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The height of one line of [style] at [scaler].
double _lineHeight(TextStyle style, TextScaler scaler, BuildContext context) {
  final painter = TextPainter(
    text: TextSpan(text: '0', style: style),
    textDirection: Directionality.of(context),
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final height = painter.height;
  painter.dispose();
  return height;
}

/// The width of [text] in [style] at [scaler], on one line.
double _textWidth(
  String text,
  TextStyle style,
  TextScaler scaler,
  TextDirection direction,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// Wallet's figure and its gold EPIC, in a box [figureSize] high. The figure takes the largest
/// whole size from [figureSize] down to [figureMinSize] at which it fits beside the unit. It
/// does not follow the text scale, which would only shrink it back; the unit does, up to 1.3x.
class _Figure extends StatelessWidget {
  const _Figure({required this.spendable, required this.hidden});

  final BigInt spendable;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final direction = Directionality.of(context);
    final text = hidden ? hiddenAmount : localDigits(l, displayEpic(spendable));
    TextStyle figure(double size) =>
        (theme.textTheme.displaySmall ?? const TextStyle()).copyWith(
          fontFamily: t.headFamily,
          fontWeight: FontWeight.w600,
          fontSize: size,
          height: 1,
          letterSpacing: -0.01 * size,
          color: t.text,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    final unitStyle = TextStyle(
      fontFamily: t.headFamily,
      fontWeight: FontWeight.w600,
      fontSize: 15,
      height: 1,
      letterSpacing: 0.14 * 15,
      color: t.accentText,
    );
    final unitScaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.3);
    return Semantics(
      container: true,
      label: _spendableLabel(l, spendable, hidden),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final unitWidth =
              8 + _textWidth('EPIC', unitStyle, unitScaler, direction);
          bool fits(double size) =>
              _textWidth(text, figure(size), TextScaler.noScaling, direction) +
                  unitWidth <=
              constraints.maxWidth;
          // The widths grow with the size, so a binary search over whole sizes finds it.
          var size = figureMinSize;
          if (fits(figureSize)) {
            size = figureSize;
          } else {
            var low = figureMinSize, high = figureSize;
            while (high - low > 1) {
              final mid = ((low + high) / 2).floorToDouble();
              if (fits(mid)) {
                low = mid;
              } else {
                high = mid;
              }
            }
            size = low;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Only an extreme width needs less than the least size: then it scales down
              // rather than wraps or clips.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    text,
                    key: balanceFigureKey,
                    maxLines: 1,
                    softWrap: false,
                    textScaler: TextScaler.noScaling,
                    style: figure(size),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8, top: 7),
                child: Text(
                  'EPIC',
                  key: balanceUnitKey,
                  maxLines: 1,
                  textScaler: unitScaler,
                  style: unitStyle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The pending line under Wallet's figure: [items] on one line of fixed height, each a small
/// glyph and its words, mono 12; the calm item ("All confirmed") fainter.
///
/// When they do not fit, they scroll left as one seamless loop at [pendingLineSpeed], the
/// right edge faded; a press, or hover with a mouse, pauses it. A changed amount changes the
/// words in place and the loop runs on; a changed set of kinds starts it again. With reduced
/// motion it never scrolls: it cuts to the next item every [pendingLineStep]. Screen readers
/// hear the whole list once.
class PendingLine extends StatefulWidget {
  const PendingLine({super.key, required this.items});

  final List<PendingItem> items;

  @override
  State<PendingLine> createState() => _PendingLineState();
}

class _PendingLineState extends State<PendingLine>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration? _last;
  Timer? _cutTimer;

  /// How far the loop has scrolled, within one copy of the items. A notifier, so a frame of
  /// the loop moves the reel without building the line again.
  final ValueNotifier<double> _offset = ValueNotifier(0);

  /// With reduced motion: the item the line starts at.
  int _cut = 0;

  bool _pressed = false;
  bool _hovered = false;

  /// What the last layout found: the width of one copy, each item's start, and whether the
  /// items overflow the line.
  double _cycle = 0;
  List<double> _starts = const [];
  bool _overflow = false;

  /// Glyph, the gap after it, and the space after each item.
  static const double _glyph = 12, _gap = 6, _after = 22;

  String get _kinds => widget.items.map((i) => i.kind?.name).join(',');

  @override
  void didUpdateWidget(PendingLine old) {
    super.didUpdateWidget(old);
    final before = old.items.map((i) => i.kind?.name).join(',');
    if (before != _kinds) {
      _offset.value = 0;
      _cut = 0;
      _last = null;
      _cutTimer?.cancel();
      _cutTimer = null;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _cutTimer?.cancel();
    _offset.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final last = _last;
    _last = elapsed;
    if (last == null || _pressed || _hovered || _cycle <= 0) return;
    final dt = (elapsed - last).inMicroseconds / Duration.microsecondsPerSecond;
    _offset.value = (_offset.value + pendingLineSpeed * dt) % _cycle;
  }

  /// Starts or stops the ticker and the reduced-motion timer for the last layout.
  void _sync(bool still) {
    if (!mounted) return;
    final scroll = _overflow && !still;
    if (scroll && !_ticker.isActive) {
      _last = null;
      _ticker.start();
    } else if (!scroll && _ticker.isActive) {
      _ticker.stop();
    }
    if (!_overflow) _offset.value = 0;
    final cut = _overflow && still;
    if (cut && _cutTimer == null) {
      _cutTimer = Timer.periodic(pendingLineStep, (_) {
        if (!mounted || _starts.isEmpty) return;
        setState(() => _cut = (_cut + 1) % _starts.length);
      });
    } else if (!cut && _cutTimer != null) {
      _cutTimer!.cancel();
      _cutTimer = null;
      _cut = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scaler = MediaQuery.textScalerOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final direction = Directionality.of(context);
    final style = TextStyle(
      fontFamily: t.monoFamily,
      fontSize: 12,
      color: t.dim,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final calm = style.copyWith(color: t.faint);
    final height = math.max(20.0, _lineHeight(style, scaler, context) + 4);
    final items = widget.items;
    return Semantics(
      container: true,
      label: items.map((i) => i.text).join('\n'),
      excludeSemantics: true,
      child: SizedBox(
        key: pendingLineKey,
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final widths = [
              for (final i in items)
                _glyph +
                    _gap +
                    _textWidth(
                      i.text,
                      i.kind == null ? calm : style,
                      scaler,
                      direction,
                    ) +
                    _after,
            ];
            final starts = <double>[];
            var x = 0.0;
            for (final w in widths) {
              starts.add(x);
              x += w;
            }
            _cycle = x;
            _starts = starts;
            // The space after the last item does not need to fit.
            _overflow = items.isNotEmpty && x - _after > constraints.maxWidth;
            WidgetsBinding.instance.addPostFrameCallback((_) => _sync(still));
            Widget copy() => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (n, i) in items.indexed)
                  SizedBox(
                    width: widths[n],
                    child: Row(
                      children: [
                        Icon(
                          i.icon,
                          size: _glyph,
                          color: i.kind == null ? t.faint : t.dim,
                        ),
                        const SizedBox(width: _gap),
                        Flexible(
                          child: Text(
                            i.text,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: i.kind == null ? calm : style,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
            Widget reel = ClipRect(
              child: OverflowBox(
                alignment: AlignmentDirectional.centerStart,
                minWidth: 0,
                maxWidth: double.infinity,
                child: ValueListenableBuilder<double>(
                  valueListenable: _offset,
                  builder: (context, offset, row) {
                    final shift = !_overflow
                        ? 0.0
                        : still
                        ? starts[_cut % starts.length]
                        : offset;
                    return Transform.translate(
                      key: pendingReelKey,
                      offset: Offset(
                        direction == TextDirection.ltr ? -shift : shift,
                        0,
                      ),
                      child: row,
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [copy(), if (_overflow) copy()],
                  ),
                ),
              ),
            );
            if (_overflow) {
              // The far edge fades out over 28 dp, so the cut-off word does not end hard.
              reel = ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => LinearGradient(
                  begin: AlignmentDirectional.centerStart.resolve(direction),
                  end: AlignmentDirectional.centerEnd.resolve(direction),
                  colors: const [
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0, 1 - 28 / math.max(rect.width, 28), 1],
                ).createShader(rect),
                child: reel,
              );
            }
            return MouseRegion(
              onEnter: (_) => _hovered = true,
              onExit: (_) => _hovered = false,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _pressed = true,
                onPointerUp: (_) => _pressed = false,
                onPointerCancel: (_) => _pressed = false,
                child: reel,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The app bar's title on every tab, cross-faded by the page position ([openness], 1 on
/// Wallet): Wallet's [ShellTitle] (the name, a test network's name, the demo's countdown in
/// [trailing]), and on Send and Receive the spendable figure with a small gold EPIC and a
/// pulsing dot while anything is pending.
///
/// Both are laid out on every frame, so [onMeasured] hears after each layout that changed them
/// how wide the wider one would be ([need]) and how wide the bar lets the title be ([room]);
/// the shell moves the statuses out of the bar from that ([statusesInBar]). Each shrinks
/// rather than overflows when the bar is narrower still.
class ShellBarTitle extends StatelessWidget {
  const ShellBarTitle({
    super.key,
    required this.openness,
    required this.chain,
    required this.onMeasured,
    this.trailing,
  });

  final double openness;
  final Chain? chain;
  final Widget? trailing;
  final void Function(double need, double room) onMeasured;

  @override
  Widget build(BuildContext context) {
    final t = openness;
    // The title that is more than half shown takes taps and screen readers.
    Widget layer(double opacity, bool active, Widget child) => IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: Opacity(opacity: opacity, child: child),
      ),
    );
    return _TitleSlots(
      onMeasured: onMeasured,
      children: [
        layer(
          shellFade(t),
          t >= 0.5,
          ShellTitle(chain: chain, trailing: trailing),
        ),
        layer(shellFade(1 - t), t < 0.5, _FigureTitle(shown: t < 1)),
      ],
    );
  }
}

/// The spendable figure as Send's and Receive's title: the app bar's title style with tabular
/// figures, a small gold EPIC after it, and while anything is pending an accent dot that pulses
/// while [shown]. The dot's room is kept when there is no dot, so a payment starting does not
/// change the title's width.
class _FigureTitle extends ConsumerWidget {
  const _FigureTitle({required this.shown});

  final bool shown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeProvider).value?.summary;
    if (summary == null) return const SizedBox.shrink();
    final l = context.l10n;
    final t = context.tokens;
    final hidden = amountDisplay(ref).hidden;
    final pending = hasPending(summary);
    final style = DefaultTextStyle.of(context).style
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    const dot = 6.0;
    return Semantics(
      container: true,
      label: [
        _spendableLabel(l, summary.spendable, hidden),
        if (pending) l.shellPendingLabel,
      ].join('\n'),
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text.rich(
          key: titleFigureKey,
          TextSpan(
            children: [
              TextSpan(
                text: hidden
                    ? hiddenAmount
                    : localDigits(l, displayEpic(summary.spendable)),
              ),
              const WidgetSpan(child: SizedBox(width: 6)),
              TextSpan(
                text: 'EPIC',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.12 * 11,
                  color: t.accentText,
                ),
              ),
              const WidgetSpan(child: SizedBox(width: 6)),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: pending
                    ? Pulse(
                        active: shown,
                        child: DecoratedBox(
                          key: pendingDotKey,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.accent,
                          ),
                          child: const SizedBox.square(dimension: dot),
                        ),
                      )
                    : const SizedBox.square(dimension: dot),
              ),
            ],
          ),
          maxLines: 1,
          softWrap: false,
          style: style,
        ),
      ),
    );
  }
}

/// Lays its children over each other at the start, vertically centred, each as wide as it is
/// up to the room given, and tells [onMeasured] how wide the widest would be unconstrained.
class _TitleSlots extends MultiChildRenderObjectWidget {
  const _TitleSlots({required this.onMeasured, required super.children});

  final void Function(double need, double room) onMeasured;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTitleSlots(onMeasured);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTitleSlots renderObject,
  ) {
    renderObject.onMeasured = onMeasured;
  }
}

class _TitleSlotsParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTitleSlots extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TitleSlotsParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TitleSlotsParentData> {
  _RenderTitleSlots(this.onMeasured);

  void Function(double need, double room) onMeasured;

  double? _need, _room;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TitleSlotsParentData) {
      child.parentData = _TitleSlotsParentData();
    }
  }

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth,
        maxHeight: constraints.maxHeight,
      );

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => getChildrenAsList().fold(
    0.0,
    (w, child) => math.max(w, child.getMaxIntrinsicWidth(height)),
  );

  @override
  double computeMinIntrinsicHeight(double width) => getChildrenAsList().fold(
    0.0,
    (h, child) => math.max(h, child.getMinIntrinsicHeight(width)),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => getChildrenAsList().fold(
    0.0,
    (h, child) => math.max(h, child.getMaxIntrinsicHeight(width)),
  );

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    var size = Size.zero;
    for (final child in getChildrenAsList()) {
      final s = child.getDryLayout(_childConstraints(constraints));
      size = Size(
        math.max(size.width, s.width),
        math.max(size.height, s.height),
      );
    }
    return constraints.constrain(size);
  }

  @override
  void performLayout() {
    final room = constraints.maxWidth;
    var need = 0.0, width = 0.0, height = 0.0;
    for (final child in getChildrenAsList()) {
      need = math.max(need, child.getMaxIntrinsicWidth(double.infinity));
      child.layout(_childConstraints(constraints), parentUsesSize: true);
      width = math.max(width, child.size.width);
      height = math.max(height, child.size.height);
    }
    size = constraints.constrain(Size(width, height));
    for (final child in getChildrenAsList()) {
      (child.parentData! as _TitleSlotsParentData).offset = Offset(
        0,
        (size.height - child.size.height) / 2,
      );
    }
    if (need != _need || room != _room) {
      _need = need;
      _room = room;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (attached) onMeasured(need, room);
      });
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// The app bar's foot on every tab, in the shell's progress slot: while the node syncs, its
/// progress as a determinate accent line; and when a payment lands ([paymentLanded]) a 1 dp
/// accent line that sweeps out from the centre once, in [landingSweepDuration]. The sweep runs
/// with reduced motion too, by the operator's choice; the sync line never moves by itself.
class ShellEdge extends ConsumerStatefulWidget {
  const ShellEdge({super.key});

  @override
  ConsumerState<ShellEdge> createState() => _ShellEdgeState();
}

class _ShellEdgeState extends ConsumerState<ShellEdge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: landingSweepDuration,
  );

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homeProvider.select((h) => h.value?.summary), (before, after) {
      if (paymentLanded(before, after)) _sweep.forward(from: 0);
    });
    final node = watchWalletStatus(ref).node;
    final t = context.tokens;
    return ExcludeSemantics(
      // The node status says the percent to screen readers.
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (node.state == NodeState.syncing)
            LinearProgressIndicator(
              key: headerSyncLineKey,
              value: (node.percent ?? 0) / 100,
              minHeight: progressSlotHeight,
              color: t.accent,
              backgroundColor: Colors.transparent,
            ),
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) => CustomPaint(
                key: landingSweepKey,
                size: const Size(double.infinity, SweepLinePainter.thickness),
                painter: SweepLinePainter(
                  progress: _sweep.value,
                  color: t.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The ? beside the balance: a tap shows every balance that is not zero, each with a few
/// words on what it is. Spendable needs none.
class BalanceHelp extends StatefulWidget {
  const BalanceHelp({super.key, required this.summary, required this.hidden});

  final WalletSummary summary;
  final bool hidden;

  /// Label, amount and explanation of each balance, zero ones left out except the total.
  static List<(String, BigInt, String?)> rows(
    AppLocalizations l,
    WalletSummary summary,
  ) => [
    (l.balanceTotal, summary.total, l.balanceTotalHelp),
    if (summary.spendable > BigInt.zero)
      (l.homeBalanceSpendable, summary.spendable, null),
    if (summary.awaitingConfirmation > BigInt.zero)
      (
        l.homeBalanceConfirming,
        summary.awaitingConfirmation,
        l.balanceConfirmingHelp,
      ),
    if (summary.awaitingFinalization > BigInt.zero)
      (
        l.homeBalanceWaitingToFinish,
        summary.awaitingFinalization,
        l.balanceWaitingHelp,
      ),
    if (summary.locked > BigInt.zero)
      (l.homeBalanceLocked, summary.locked, l.balanceLockedHelp),
    if (summary.immature > BigInt.zero)
      (l.homeBalanceImmature, summary.immature, l.balanceImmatureHelp),
  ];

  /// The help's text: each of [rows] in bold, with its explanation under it.
  static TextSpan message(
    AppLocalizations l,
    WalletSummary summary,
    bool hidden,
  ) {
    final spans = <InlineSpan>[];
    for (final (i, (label, amount, help)) in rows(l, summary).indexed) {
      if (i > 0) spans.add(const TextSpan(text: '\n\n'));
      spans.add(
        TextSpan(
          text: l.balanceHelpRow(
            label,
            shownEpic(l, amount, hidden: hidden, exact: true),
          ),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
      if (help != null) spans.add(TextSpan(text: '\n$help'));
    }
    return TextSpan(children: spans);
  }

  @override
  State<BalanceHelp> createState() => _BalanceHelpState();
}

class _BalanceHelpState extends State<BalanceHelp> {
  final _tooltip = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // A button, so screen readers can press it; the tooltip holds the answer.
    return Tooltip(
      key: _tooltip,
      richMessage: BalanceHelp.message(l, widget.summary, widget.hidden),
      triggerMode: TooltipTriggerMode.manual,
      showDuration: const Duration(seconds: 10),
      child: IconButton(
        icon: Icon(
          Icons.help_outline,
          size: 20,
          color: context.tokens.dim,
          semanticLabel: l.balanceHelpLabel,
        ),
        onPressed: () => _tooltip.currentState?.ensureTooltipVisible(),
      ),
    );
  }
}

/// Wallet's app bar title: the mark's name, and on a test network its name with a ? whose
/// tooltip says its coins have no value. Mainnet shows no network name.
class ShellTitle extends StatelessWidget {
  const ShellTitle({super.key, required this.chain, this.trailing});

  /// Null before the network is known.
  final Chain? chain;

  /// After the network name: the web demo's countdown. It takes the name's place, which the
  /// bar has no room for beside both; the mark before the title still names the app.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final chain = this.chain;
    final theme = Theme.of(context);
    final named = trailing == null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (named)
          Flexible(
            child: Text(l.shellTitle, maxLines: 1, overflow: TextOverflow.fade),
          ),
        if (chain != null && chain != Chain.mainnet) ...[
          if (named) const SizedBox(width: 8),
          // Flexible like the name, so a bar narrower than both fades them, never overflows.
          Flexible(
            child: Tooltip(
              message: l.shellTestNetworkTooltip,
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        chainName(l, chain),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: context.tokens.accentText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.help_outline,
                      size: 16,
                      color: context.tokens.accentText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (trailing case final trailing?) ...[
          const SizedBox(width: 8),
          Flexible(child: trailing),
        ],
      ],
    );
  }
}
