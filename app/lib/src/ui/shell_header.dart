// SPDX-License-Identifier: Apache-2.0
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'home_status.dart' show StatusIcons, statusEntries;
import 'status.dart';
import 'theme/protocol.dart';
import 'theme/brand.dart' show BrandVariant, BrandWordmark;
import 'theme/tokens.dart';

/// The key of Wallet's balance area: the figure, the fiat row and the pending line, for tests.
const Key walletBalanceKey = ValueKey('wallet-balance');

/// The key of Wallet's figure, for tests.
const Key balanceFigureKey = ValueKey('balance-figure');

/// The key of the gold EPIC at the figure's top right, for tests.
const Key balanceUnitKey = ValueKey('balance-unit');

/// The key of the fiat value under the figure, for tests.
const Key fiatValueKey = ValueKey('balance-fiat');

/// The key of the "Available to spend" caption above the figure, for tests.
const Key balanceCaptionKey = ValueKey('balance-caption');

/// The key of the balance header under Send's and Receive's app bar, for tests.
const Key balanceHeaderKey = ValueKey('balance-header');

/// The key of the figure in that header, for tests.
const Key titleFigureKey = ValueKey('title-figure');

/// The key of the line under that figure with what is on hold, coming in or not on chain,
/// for tests: the tokens, or the count they collapse to.
const Key titlePendingKey = ValueKey('title-pending');

/// The key of the balance sheet a tap on a figure opens, for tests.
const Key balanceSheetKey = ValueKey('balance-sheet');

/// The size of the figure in the balance header: fixed, whatever is under it.
const double titleFigureSize = 17;

/// The size of the detail line under it: fixed too; the line collapses before it shrinks.
const double titleDetailSize = 12;

/// The key of the statuses in Wallet's fiat row.
const Key walletStatusesKey = ValueKey('statuses-wallet');

/// The key of the compact statuses in Send's and Receive's app bar.
const Key barStatusesKey = ValueKey('statuses-bar');

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

/// The size the figure never scales under: its unit goes first.
const double figureFloorSize = 14;

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

/// The money on its way in: in a block and confirming, and mining rewards. Outputs not on
/// chain yet ([WalletSummary.awaitingFinalization]) are left out: anyone can offer a payment
/// and never finish it, so it is not money until it is in a block. The ? lists them apart.
BigInt comingIn(WalletSummary summary) =>
    summary.awaitingConfirmation + summary.immature;

/// One token of the balance header's detail line: a small glyph and an amount, and what a
/// screen reader says for it.
typedef PendingToken = ({IconData icon, String amount, String label});

/// The detail line's tokens for [summary], at most three, in the order the money settles:
/// what a send holds (locked), what is on its way in (confirming, mining rewards), and what
/// is not on chain yet (payments offered or sent that no block holds, own change). Each is a
/// glyph with the amount by the display rule; the words are for screen readers.
List<PendingToken> pendingTokens(
  AppLocalizations l,
  WalletSummary summary, {
  required bool hidden,
}) {
  String amount(BigInt v) =>
      hidden ? hiddenAmount : localDigits(l, displayEpic(v));
  final incoming = comingIn(summary);
  return [
    if (summary.locked > BigInt.zero)
      (
        icon: Icons.lock_outline,
        amount: amount(summary.locked),
        label: l.balanceLineOnHold(amount(summary.locked)),
      ),
    if (incoming > BigInt.zero)
      (
        icon: Icons.south_west,
        amount: '+${amount(incoming)}',
        label: l.balanceLineComingIn(amount(incoming)),
      ),
    if (summary.awaitingFinalization > BigInt.zero)
      (
        icon: Icons.schedule,
        amount: amount(summary.awaitingFinalization),
        label: l.balanceHelpRow(
          l.homeBalanceNotOnChain,
          amount(summary.awaitingFinalization),
        ),
      ),
  ];
}

/// What a screen reader says for the spendable balance: the exact amount.
String _spendableLabel(AppLocalizations l, BigInt spendable, bool hidden) =>
    l.balanceHelpRow(
      l.homeBalanceSpendable,
      hidden ? l.homeBalanceHiddenLabel : epicExact(l, spendable),
    );

/// Wallet's balance area, with no panel around it, centred as one column: the caption
/// "Available to spend", the spendable figure in Montserrat 60 with the gold EPIC at its top
/// right, the two centred as a unit; under it one row, [statusTarget] high: the status icons
/// ([StatusIcons]) at its start, the fiat value and the eye at its end. The pending balances
/// are in the tiles under it (`home_parts.dart`), in the list below.
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
    // Kill switch keeps the last known balance and marks it so on the caption.
    final lastKnown = ref.watch(balanceLastKnownProvider);
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
    final captionStyle = (Theme.of(context).textTheme.bodySmall ??
            const TextStyle(fontSize: 12))
        .copyWith(color: t.dim);
    final rowHeight = math.max(
      statusTarget,
      _lineHeight(fiatStyle, scaler, context),
    );
    // The tooltip opens above the eye, over the figure's own row, not over the tiles below.
    final eye = Tooltip(
      message: hidden ? l.homeShowBalances : l.homeHideBalances,
      preferBelow: false,
      child: IconButton(
        iconSize: statusGlyph,
        color: t.dim,
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          semanticLabel: hidden ? l.homeShowBalances : l.homeHideBalances,
        ),
        onPressed: () =>
            ref.read(appSettingsProvider.notifier).setHideBalances(!hidden),
      ),
    );
    // The icons' and the eye's 48 dp targets reach [statusInset] past their glyphs, so the
    // row's gutter is that much narrower: the first glyph and the eye line up with the text.
    const gutter = 18.0;
    return Semantics(
      container: true,
      child: Padding(
        key: walletBalanceKey,
        padding: const EdgeInsets.fromLTRB(
          gutter - statusInset,
          20,
          gutter - statusInset,
          4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The caption says what the figure is, as the desktop's Overview does.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: statusInset),
              child: SizedBox(
                height: _lineHeight(captionStyle, scaler, context),
                child: Text(
                  lastKnown
                      ? l.settingsStateJoin(
                          l.homeAvailableToSpend,
                          l.lastKnownCaption.toLowerCase(),
                        )
                      : l.homeAvailableToSpend,
                  key: balanceCaptionKey,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: captionStyle,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: statusInset),
              child: SizedBox(
                height: figureSize,
                child: summary == null
                    ? const Center(
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _Figure(summary: summary, hidden: hidden),
              ),
            ),
            const SizedBox(height: 2),
            // The statuses show before the first balance too: they say why it is not here.
            // The fiat value takes what the icons leave and shrinks rather than wraps, so an
            // icon coming or going (Tor on, the onion published) moves nothing else.
            SizedBox(
              height: rowHeight,
              child: LayoutBuilder(
                builder: (context, box) => Row(
                children: [
                  // The mode mark and four icons are 350 dp wide with a long mode name: on a
                  // 360 dp phone the strip shrinks a little rather than wrap or overflow. It
                  // keeps its natural width otherwise.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: math.max(0, box.maxWidth - (summary != null ? statusTarget : 0))),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: const StatusIcons(key: walletStatusesKey),
                    ),
                  ),
                  Expanded(
                    child: fiat == null
                        ? const SizedBox.shrink()
                        : Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 8,
                              ),
                              child: FittedBox(
                                key: fiatValueKey,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  fiat,
                                  maxLines: 1,
                                  style: fiatStyle,
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (summary != null) eye,
                ],
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

/// Wallet's figure (four decimals, [displayEpic]) and its gold EPIC, in a box [figureSize]
/// high. The figure takes the largest whole size from [figureSize] down to [figureMinSize] at
/// which it fits beside the unit. It does not follow the text scale, which would only shrink
/// it back; the unit does, up to 1.3x. A tap opens the balance sheet ([showBalanceSheet]).
class _Figure extends StatelessWidget {
  const _Figure({required this.summary, required this.hidden});

  final WalletSummary summary;
  final bool hidden;

  BigInt get spendable => summary.spendable;

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
          bool fits(double size, {bool unit = true}) =>
              _textWidth(text, figure(size), TextScaler.noScaling, direction) +
                  (unit ? unitWidth : 0) <=
              constraints.maxWidth;
          // The widths grow with the size, so a binary search over whole sizes finds it.
          double best({required bool unit}) {
            if (fits(figureSize, unit: unit)) return figureSize;
            var low = figureMinSize, high = figureSize;
            while (high - low > 1) {
              final mid = ((low + high) / 2).floorToDouble();
              if (fits(mid, unit: unit)) {
                low = mid;
              } else {
                high = mid;
              }
            }
            return low;
          }
          var size = best(unit: true);
          // Past the least size the figure scales down with its unit; before that scaling
          // would take it under a readable 14, the unit goes instead, and the
          // semantics still say EPIC.
          final atMin = _textWidth(text, figure(figureMinSize), TextScaler.noScaling, direction) + unitWidth;
          final showUnit = fits(figureMinSize) || figureMinSize * constraints.maxWidth / atMin >= figureFloorSize;
          if (!showUnit) size = best(unit: false);
          // The figure and its unit are centred as one; the figure's Flexible is loose, so
          // the row's free space falls on both sides.
          return BalanceTap(
            summary: summary,
            hidden: hidden,
            child: Row(
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
              if (showUnit)
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
            ),
          );
        },
      ),
    );
  }
}

/// The balance header at the top of Send and Receive, under the app bar, [statusTarget]
/// high: at its start the spendable figure at [titleFigureSize] with a small gold EPIC, and
/// under it the detail line (the [pendingTokens], or their count when they do not fit); at its
/// end the status icons ([StatusIcons]), the same row as under Wallet's figure. A balance is
/// never clipped (UP-002): on a narrow row the detail line goes under the icons first, then
/// the figure takes the whole width and the icons a second row, and only then the figure
/// shrinks, to [titleFigureFloor] at the least. A tap anywhere on the figure opens the
/// balance sheet with every amount in full.
class BalanceHeader extends ConsumerWidget {
  const BalanceHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final summary = ref.watch(homeProvider).value?.summary;
    final hidden = amountDisplay(ref).hidden;
    // The icons are [statusTarget] wide each: their row's width without laying it out.
    final iconsWidth = statusEntries(context, ref, bar: true).entries.length * statusTarget;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final icons = StatusIcons(key: barStatusesKey, bar: true);
    return Container(
      key: balanceHeaderKey,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: statusTarget),
        child: Padding(
          // The figure starts at the text gutter; the last icon's target reaches the edge.
          padding: const EdgeInsetsDirectional.only(start: 16),
          child: LayoutBuilder(
            builder: (context, box) {
              if (summary == null) {
                return Row(children: [const Spacer(), icons]);
              }
              final tokens = pendingTokens(l, summary, hidden: hidden);
              final text = hidden ? hiddenAmount : localDigits(l, displayEpic(summary.spendable));
              final full = box.maxWidth;
              final beside = full - 4 - iconsWidth;
              double figureWidth(double size) => _spanWidth(_figureSpan(text, t, size), scaler, direction);
              final detailWidth = _tokensWidth(context, tokens, scaler, direction);
              final figureBeside = figureWidth(titleFigureSize) <= beside;
              final detailBeside = tokens.isEmpty || detailWidth <= beside;
              final label = [
                _spendableLabel(l, summary.spendable, hidden),
                for (final item in tokens) item.label,
              ].join('\n');
              Widget figure(double size) => BalanceTap(
                summary: summary,
                hidden: hidden,
                label: label,
                child: _FigureText(text: text, size: size),
              );
              Widget detail() => ExcludeSemantics(
                child: BalanceTap(
                  summary: summary,
                  hidden: hidden,
                  child: _DetailLine(tokens: tokens),
                ),
              );
              if (figureBeside && detailBeside) {
                // The figure over its detail line, the icons beside them.
                return Row(
                  children: [
                    Expanded(
                      child: BalanceTap(
                        summary: summary,
                        hidden: hidden,
                        label: label,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FigureText(text: text, size: titleFigureSize),
                            if (tokens.isNotEmpty) _DetailLine(tokens: tokens),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    icons,
                  ],
                );
              }
              if (figureBeside) {
                // (1) The detail line on its own, under the icons.
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [Expanded(child: figure(titleFigureSize)), const SizedBox(width: 4), icons]),
                    detail(),
                  ],
                );
              }
              // (2) The figure takes the whole width, the icons a second row; (3) only then it
              // shrinks, never under the floor.
              var size = titleFigureSize;
              while (size > titleFigureFloor && figureWidth(size) > full) {
                size -= 1;
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  figure(size),
                  Row(
                    children: [
                      Expanded(child: tokens.isEmpty ? const SizedBox.shrink() : detail()),
                      const SizedBox(width: 4),
                      icons,
                    ],
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

/// The least size the header's figure shrinks to (UP-002).
const double titleFigureFloor = 14;

/// The header's figure as one span: the amount at [size] in the heading face with tabular
/// figures, then a small gold EPIC.
TextSpan _figureSpan(String text, WalletTokens t, double size) => TextSpan(
  style: TextStyle(
    fontFamily: t.headFamily,
    fontWeight: FontWeight.w600,
    fontSize: size,
    height: 1.2,
    color: t.text,
    letterSpacing: -0.01 * size,
    fontFeatures: const [FontFeature.tabularFigures()],
  ),
  children: [
    TextSpan(text: text),
    TextSpan(
      text: ' EPIC',
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 0.12 * 11,
        color: t.accentText,
      ),
    ),
  ],
);

/// The width of [span] at [scaler], on one line.
double _spanWidth(InlineSpan span, TextScaler scaler, TextDirection direction) {
  final painter = TextPainter(
    text: span,
    textDirection: direction,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// The detail line's style.
TextStyle _detailStyle(WalletTokens t) => TextStyle(
  fontSize: titleDetailSize,
  height: 1.2,
  color: t.dim,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// The glyph before each detail amount, the gap after it, and the dot between two tokens.
const double _detailGlyph = 12, _detailGap = 3;
const String _detailDot = ' · ';

/// The width of [tokens] laid out on one line, as [_DetailLine] draws them.
double _tokensWidth(BuildContext context, List<PendingToken> tokens, TextScaler scaler, TextDirection direction) {
  final style = _detailStyle(context.tokens);
  var width = 0.0;
  for (final (n, item) in tokens.indexed) {
    if (n > 0) width += _textWidth(_detailDot, style, scaler, direction);
    width += scaler.scale(_detailGlyph) + _detailGap + _textWidth(item.amount, style, scaler, direction);
  }
  return width;
}

/// The spendable figure ([displayEpic]) in the balance header at [size], never wrapped.
class _FigureText extends StatelessWidget {
  const _FigureText({required this.text, required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text.rich(
    _figureSpan(text, context.tokens, size),
    key: titleFigureKey,
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.clip,
  );
}

/// The header's detail line: the [tokens] as glyph and amount, or, when they would not fit
/// the width, the count of them ([AppLocalizations.pendingCount]) with a chevron.
class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.tokens});

  final List<PendingToken> tokens;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final detailStyle = _detailStyle(t);
    Widget token(PendingToken item) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: scaler.scale(_detailGlyph), color: t.dim),
        const SizedBox(width: _detailGap),
        Text(item.amount, maxLines: 1, softWrap: false, style: detailStyle),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits = _tokensWidth(context, tokens, scaler, direction) <= constraints.maxWidth;
        return Row(
          key: titlePendingKey,
          mainAxisSize: MainAxisSize.min,
          children: fits
              ? [
                  for (final (n, item) in tokens.indexed) ...[
                    if (n > 0) Text(_detailDot, style: detailStyle),
                    token(item),
                  ],
                ]
              : [
                  Flexible(
                    child: Text(
                      l.pendingCount(tokens.length),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: detailStyle,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: scaler.scale(14),
                    color: t.dim,
                  ),
                ],
        );
      },
    );
  }
}

/// A figure that opens the balance sheet on a tap: a button to a screen reader, [label] (the
/// exact amount and the details) its words when given, the sheet's purpose its hint.
class BalanceTap extends StatelessWidget {
  const BalanceTap({
    super.key,
    required this.summary,
    required this.hidden,
    required this.child,
    this.label,
  });

  final WalletSummary summary;
  final bool hidden;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void open() => showBalanceSheet(context, summary: summary, hidden: hidden);
    return Semantics(
      container: true,
      button: true,
      label: label,
      hint: l.balanceHelpLabel,
      excludeSemantics: label != null,
      onTap: open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        // A full-height target in the header; Wallet's figure is taller anyway.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: statusTarget),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Opens the balance sheet: every balance of [summary] that is not zero (the total always)
/// with its exact amount ([epicExact]) and a short explanation, from [BalanceHelp.rows].
/// With [hidden] the amounts are dots and the sheet says nothing more.
Future<void> showBalanceSheet(
  BuildContext context, {
  required WalletSummary summary,
  required bool hidden,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => BalanceSheet(summary: summary, hidden: hidden),
);

/// The balance sheet's body: a title and one row per balance, the label and its explanation
/// at the start, the exact amount in the mono face at the end, so every digit is readable.
class BalanceSheet extends StatelessWidget {
  const BalanceSheet({super.key, required this.summary, required this.hidden});

  final WalletSummary summary;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final amountStyle = TextStyle(
      fontFamily: t.monoFamily,
      fontSize: 15,
      color: t.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // A short screen scrolls the rows under the handle rather than clips them.
    return SingleChildScrollView(
      key: balanceSheetKey,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l.balanceSheetTitle, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          for (final (label, amount, help) in BalanceHelp.rows(l, summary))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: theme.textTheme.bodyLarge),
                        if (help != null)
                          Text(
                            help,
                            style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    shownEpic(l, amount, hidden: hidden, exact: true),
                    style: amountStyle,
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The app bar's foot on every tab, in the shell's progress slot: while the node syncs, its
/// progress as a determinate line in the in-progress blue; and when a payment lands
/// ([paymentLanded]) a 1 dp line in the same blue that sweeps out from the centre once, in
/// [landingSweepDuration]. Neither takes the gold: it is no state. The sweep runs
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
              color: t.info,
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
                  color: t.info,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The ? beside a balance: a tap opens the balance sheet ([showBalanceSheet]), every balance
/// that is not zero with a few words on what it is. Spendable needs none.
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
        l.homeBalanceNotOnChain,
        summary.awaitingFinalization,
        l.balanceNotOnChainHelp,
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
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return IconButton(
      icon: Icon(
        Icons.help_outline,
        size: 20,
        color: context.tokens.dim,
        semanticLabel: l.balanceHelpLabel,
      ),
      onPressed: () => showBalanceSheet(
        context,
        summary: widget.summary,
        hidden: widget.hidden,
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: BrandWordmark(
                  variant: BrandVariant.mobile,
                  size: 17,
                  label: context.l10n.shellTitle,
                ),
              ),
        ),
      ],
    );
  }
}
