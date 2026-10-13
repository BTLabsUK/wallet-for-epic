import 'dart:math' as math;

import 'package:flutter/material.dart';
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

/// The key of the figure in the app bar's title on Send and Receive, for tests.
const Key titleFigureKey = ValueKey('title-figure');

/// The key of the line under that figure with what is on hold and coming in, for tests.
const Key titlePendingKey = ValueKey('title-pending');

/// The key of the statuses in Wallet's fiat row, the only place they show.
const Key walletStatusesKey = ValueKey('statuses-wallet');

/// The key of the sync line along the app bar's foot, for tests.
const Key headerSyncLineKey = ValueKey('header-sync-line');

/// The key of the sweep along the app bar's foot when a payment lands, for tests.
const Key landingSweepKey = ValueKey('landing-sweep');

/// The width of the app bar's leading slot, the mark. The title, and so the figure on Send
/// and Receive, starts here.
const double shellLeadingWidth = 48;

/// How long the sweep takes when a payment lands.
const Duration landingSweepDuration = Duration(milliseconds: 1200);

/// The size Wallet's figure starts at, and the least it shrinks to.
const double figureSize = 60, figureMinSize = 34;

/// How far the header is open, from the shell's page position: 1 on Wallet, 0 on Send and
/// Receive, in between while a swipe or a tap moves the page.
double headerOpenness(double page) =>
    (1 - (page - ShellTab.wallet.index).abs()).clamp(0.0, 1.0);

/// A layer's opacity at [share] of the way to it: out of sight until 0.4, full from 0.6, so
/// the two layers of a cross-fade barely show at once.
double shellFade(double share) => ((share - 0.4) / 0.2).clamp(0.0, 1.0);

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

/// The two kinds of balance the pending line names: coins a send holds until it completes,
/// and coins on their way in (confirming, waiting for the sender, mining rewards maturing).
enum PendingKind { onHold, comingIn }

/// One item of the pending line: what it is, its glyph and its words. [kind] is null for the
/// calm line ("All confirmed", "Nothing here yet").
typedef PendingItem = ({PendingKind? kind, IconData icon, String text});

/// The money on its way in: confirming, waiting for the sender to finish, and mining rewards.
BigInt comingIn(WalletSummary summary) =>
    summary.awaitingConfirmation +
    summary.awaitingFinalization +
    summary.immature;

/// The pending line's items for [summary], at most two: what a send holds ("10 on hold") and
/// what is on its way in ("+7.49 coming in"). With neither, "All confirmed", or "Nothing here
/// yet" when the wallet has had no payments ([empty]). The ? beside the balance still splits
/// each one up.
List<PendingItem> pendingItems(
  AppLocalizations l,
  WalletSummary summary, {
  required bool hidden,
  required bool empty,
}) {
  String amount(BigInt v) =>
      hidden ? hiddenAmount : localDigits(l, displayEpic(v));
  final incoming = comingIn(summary);
  final items = <PendingItem>[
    if (summary.locked > BigInt.zero)
      (
        kind: PendingKind.onHold,
        icon: Icons.lock_outline,
        text: l.balanceLineOnHold(amount(summary.locked)),
      ),
    if (incoming > BigInt.zero)
      (
        kind: PendingKind.comingIn,
        icon: Icons.south_west,
        text: l.balanceLineComingIn(amount(incoming)),
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
    summary.locked > BigInt.zero || comingIn(summary) > BigInt.zero;

/// What a screen reader says for the spendable balance.
String _spendableLabel(AppLocalizations l, BigInt spendable, bool hidden) =>
    l.balanceHelpRow(
      l.homeBalanceSpendable,
      hidden ? l.homeBalanceHiddenLabel : epicText(l, spendable),
    );

/// Wallet's balance area, with no panel around it, centred as one column: the spendable
/// figure in Montserrat 60 with the gold EPIC at its top right, the two centred as a unit;
/// under it one centred row with the node and epicbox statuses, the fiat value, the eye and
/// the ?; under that the pending line, centred while it fits.
///
/// Every part has a fixed height for the text scale, so nothing here moves when amounts
/// change, a payment lands, amounts are hidden or nothing is pending. A figure too wide shrinks
/// to fit, to [figureMinSize] at least, and never wraps.
class WalletBalance extends ConsumerWidget {
  const WalletBalance({super.key});

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
    return Semantics(
      container: true,
      child: Padding(
        key: walletBalanceKey,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: figureSize,
              child: summary == null
                  ? const Center(
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _Figure(spendable: summary.spendable, hidden: hidden),
            ),
            const SizedBox(height: 2),
            // The statuses show before the first balance too: they say why it is not here.
            SizedBox(
              height: rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const StatusIcons(key: walletStatusesKey),
                  if (fiat != null)
                    Flexible(
                      child: FittedBox(
                        key: fiatValueKey,
                        fit: BoxFit.scaleDown,
                        child: Text(fiat, maxLines: 1, style: fiatStyle),
                      ),
                    ),
                  if (summary != null) ...[
                    eye,
                    BalanceHelp(summary: summary, hidden: hidden),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 2),
            PendingLine(
              items: summary == null
                  ? const []
                  : pendingItems(
                      l,
                      summary,
                      hidden: hidden,
                      empty: data?.transactions.isEmpty ?? false,
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
          // The figure and its unit are centred as one; the figure's Flexible is loose, so
          // the row's free space falls on both sides.
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
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

/// The pending line under Wallet's figure: [items] (at most two) on one centred line of fixed
/// height, each a small glyph and its words in the body face at 13, dim; the calm item ("All
/// confirmed") fainter. It never scrolls: when the items are wider than the line, as at large
/// text on a small phone, they shrink to fit. Screen readers hear them once, in order.
class PendingLine extends StatelessWidget {
  const PendingLine({super.key, required this.items});

  final List<PendingItem> items;

  /// Glyph (at the text scale, like its words), the gap after it, and the space between two
  /// items.
  static const double _glyph = 13, _gap = 5, _between = 16;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scaler = MediaQuery.textScalerOf(context);
    final style = TextStyle(
      fontSize: 13,
      color: t.dim,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final calm = style.copyWith(color: t.faint);
    final height = math.max(20.0, _lineHeight(style, scaler, context) + 4);
    return Semantics(
      container: true,
      label: items.map((i) => i.text).join('\n'),
      excludeSemantics: true,
      child: SizedBox(
        key: pendingLineKey,
        height: height,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (n, i) in items.indexed) ...[
                  if (n > 0) const SizedBox(width: _between),
                  Icon(
                    i.icon,
                    size: scaler.scale(_glyph),
                    color: i.kind == null ? t.faint : t.dim,
                  ),
                  const SizedBox(width: _gap),
                  Text(
                    i.text,
                    maxLines: 1,
                    softWrap: false,
                    style: i.kind == null ? calm : style,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The app bar's title on every tab, cross-faded by the page position ([openness], 1 on
/// Wallet): Wallet's [ShellTitle] ("Epic Cash", or the demo's pill in [trailing]), and on
/// Send and Receive the spendable figure with a small gold EPIC, and under it what is on hold
/// or coming in. Each shrinks rather than overflows when the bar is narrow.
class ShellBarTitle extends StatelessWidget {
  const ShellBarTitle({super.key, required this.openness, this.trailing});

  final double openness;
  final Widget? trailing;

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
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        layer(shellFade(t), t >= 0.5, ShellTitle(trailing: trailing)),
        layer(shellFade(1 - t), t < 0.5, const _FigureTitle()),
      ],
    );
  }
}

/// The spendable figure as Send's and Receive's title: the app bar's title style with tabular
/// figures and a small gold EPIC after it; while anything is on hold or coming in, a quiet line
/// under it with the same words as Wallet's pending line, so the two never disagree.
class _FigureTitle extends ConsumerWidget {
  const _FigureTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(homeProvider).value;
    final summary = data?.summary;
    if (summary == null) return const SizedBox.shrink();
    final l = context.l10n;
    final t = context.tokens;
    final hidden = amountDisplay(ref).hidden;
    final pending = [
      for (final i in pendingItems(l, summary, hidden: hidden, empty: false))
        if (i.kind != null) i.text,
    ];
    final style = DefaultTextStyle.of(context).style
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final figure = Text.rich(
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
        ],
      ),
      maxLines: 1,
      softWrap: false,
      style: style,
    );
    return Semantics(
      container: true,
      label: [
        _spendableLabel(l, summary.spendable, hidden),
        ...pending,
      ].join('\n'),
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            figure,
            if (pending.isNotEmpty)
              Text(
                pending.join(' · '),
                key: titlePendingKey,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  color: t.dim,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
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

/// Wallet's app bar title: the mark's name, or in the web demo its Test coins pill ([trailing]),
/// which takes the name's place; the mark before the title still names the app. It names no
/// network: a test network says so in the node status's tooltip.
class ShellTitle extends StatelessWidget {
  const ShellTitle({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child:
              trailing ??
              Text(
                context.l10n.shellTitle,
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
        ),
      ],
    );
  }
}
