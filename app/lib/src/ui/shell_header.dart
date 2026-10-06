import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// The key of the shell's balance header, for tests.
const Key shellHeaderKey = ValueKey('shell-header');

/// The key of the balance figure, for tests.
const Key balanceFigureKey = ValueKey('balance-figure');

/// The key of the fiat value under the figure, for tests.
const Key fiatValueKey = ValueKey('balance-fiat');

/// The key of Wallet's "not spendable yet" line, for tests.
const Key notSpendableKey = ValueKey('balance-not-spendable');

/// The key of the "Spendable" caption above Wallet's figure, for tests.
const Key spendableCaptionKey = ValueKey('balance-caption');

/// The key of the dots beside Wallet's caption that say a tap shows another balance, for
/// tests.
const Key balanceDotsKey = ValueKey('balance-dots');

/// The key of the list of not-spendable balances that Wallet's line opens, for tests.
const Key breakdownKey = ValueKey('balance-breakdown');

/// The key of Wallet's life line, for tests.
const Key lifeLineKey = ValueKey('balance-life-line');

/// The key of the sync line at the foot of the Send and Receive header, for tests.
const Key headerSyncLineKey = ValueKey('header-sync-line');

/// How far the header is open, from the shell's page position: 1 on Wallet, 0 on Send and
/// Receive, in between while a swipe or a tap moves the page.
double headerOpenness(double page) =>
    (1 - (page - ShellTab.wallet.index).abs()).clamp(0.0, 1.0);

/// The balance header above the three tabs.
///
/// On Wallet ([openness] 1) it is the 1.3.1 balance panel: the "Spendable" caption; the
/// figure, large, with the hide toggle and the balance help; the fiat value and "X EPIC not
/// spendable yet", which opens the not-spendable balances, with the node and epicbox status
/// rows on their right; and the life line, drawn as far as the sync has come.
///
/// On Send and Receive ([openness] 0) it is shorter: the figure with its unit small, the
/// status rows beside it; the fiat value with the hide toggle and the help, which lists the
/// balances not spendable yet; and while syncing a thin progress line at the panel's foot. Its
/// height does not depend on what is pending.
///
/// In between, the two cross-fade and the height follows the page, so a swipe scrubs from one
/// to the other.
class ShellHeader extends ConsumerStatefulWidget {
  const ShellHeader({super.key, required this.openness});

  final double openness;

  @override
  ConsumerState<ShellHeader> createState() => _ShellHeaderState();
}

class _ShellHeaderState extends ConsumerState<ShellHeader> {
  /// Whether Wallet lists the not-spendable balances. Kept here, so it survives a tab change.
  bool _breakdown = false;

  /// The balance Wallet's figure shows, by kind, so it survives a tab change and a refresh
  /// that reorders nothing.
  _Kind _shown = _Kind.spendable;

  @override
  Widget build(BuildContext context) {
    final t = widget.openness;
    final status = watchWalletStatus(ref);
    final b = _Balance(
      summary: ref.watch(homeProvider).value?.summary,
      node: status.node,
      epicbox: status.epicbox,
      display: amountDisplay(ref),
    );
    // Once nothing is pending the list is closed, so it does not open by itself next time.
    if (b.summary != null && b.notSpendable == BigInt.zero) _breakdown = false;
    // A balance that reached zero is not shown: back to Spendable in the same frame.
    if (b.summary != null && b.amountOf(_shown) == BigInt.zero) {
      _shown = _Kind.spendable;
    }
    // The panel that is more than half shown takes taps, keys and screen readers; Wallet's
    // from halfway.
    Widget layer(double opacity, bool active, Widget panel) => IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: Opacity(opacity: opacity, child: panel),
      ),
    );

    return Semantics(
      container: true,
      child: ProtocolBalancePanel(
        key: shellHeaderKey,
        // Each panel pads its own content, so the sync line can run along the panel's foot.
        padding: EdgeInsets.zero,
        child: _Blend(
          openness: t,
          children: [
            if (t < 1) layer(_fade(1 - t), t < 0.5, _tabPanel(b, t < 0.5)),
            if (t > 0) layer(_fade(t), t >= 0.5, _walletPanel(b, t >= 0.5)),
          ],
        ),
      ),
    );
  }

  /// A panel's opacity at [share] of the way to it: out of sight until 0.4, full from 0.6,
  /// so the two barely show at once.
  static double _fade(double share) => ((share - 0.4) / 0.2).clamp(0.0, 1.0);

  /// [amount] (Spendable unless given) as the figure, by the display rule ([displayEpic]), on
  /// one line however long it is: it shrinks rather than wraps, and the unit stays with it.
  Widget _figure(
    _Balance b, {
    required bool keyed,
    required TextStyle? style,
    required TextStyle? unit,
    BigInt? amount,
  }) {
    final l = context.l10n;
    final summary = b.summary;
    if (summary == null) {
      return const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Semantics(
      container: true,
      label: b.hidden ? l.homeBalanceHiddenLabel : null,
      excludeSemantics: b.hidden,
      child: _OneLine(
        fitKey: keyed ? balanceFigureKey : null,
        style: style,
        text: b.hidden
            ? const TextSpan(text: hiddenAmount)
            : TextSpan(
                children: [
                  TextSpan(
                    text: localDigits(
                      l,
                      displayEpic(amount ?? summary.spendable),
                    ),
                  ),
                  // The same words as [epicText], so it reads as one amount.
                  TextSpan(text: ' EPIC', style: unit),
                ],
              ),
      ),
    );
  }

  Widget _eye(_Balance b) {
    final l = context.l10n;
    return IconButton(
      tooltip: b.hidden ? l.homeShowBalances : l.homeHideBalances,
      icon: Icon(
        b.hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: () =>
          ref.read(appSettingsProvider.notifier).setHideBalances(!b.hidden),
    );
  }

  /// [left], and the status rows on the right, at most 30 % of the row: large text shortens
  /// the status words before it squeezes the balance.
  Widget _withStatus(Widget? left, {Widget status = const StatusRows()}) =>
      LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Expanded(child: left ?? const SizedBox.shrink()),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.3),
              child: status,
            ),
          ],
        ),
      );

  /// Send and Receive: the figure with the statuses beside it, the fiat value with the hide
  /// toggle and the help, and the sync line at the foot.
  Widget _tabPanel(_Balance b, bool keyed) {
    final theme = Theme.of(context);
    final summary = b.summary;
    final figureStyle = theme.textTheme.displaySmall?.copyWith(
      fontSize: theme.textTheme.displayMedium?.fontSize,
    );
    // The unit is 40 % of the number's size, so the number gets the width.
    final unitStyle = figureStyle?.copyWith(
      fontSize: (figureStyle.fontSize ?? 45) * 0.4,
    );
    final fiat = b.fiat(context);
    final left = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _figure(b, keyed: keyed, style: figureStyle, unit: unitStyle),
        if (summary != null)
          Row(
            children: [
              if (fiat != null)
                Flexible(
                  child: _OneLine(
                    fitKey: keyed ? fiatValueKey : null,
                    text: TextSpan(text: fiat),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              _eye(b),
              BalanceHelp(summary: summary, hidden: b.hidden),
            ],
          ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 10, 16),
          child: _withStatus(left),
        ),
        if (b.syncing)
          ExcludeSemantics(
            // Determinate, so it never animates by itself; the node row says the percent to
            // screen readers.
            child: LinearProgressIndicator(
              key: keyed ? headerSyncLineKey : null,
              value: b.syncProgress,
              minHeight: 2,
              color: context.tokens.accent,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }

  /// Wallet: the 1.3.1 panel, with the help beside the figure and the statuses beside the
  /// lines under it instead of the "Up to date" footer.
  ///
  /// A tap on the caption or the figure shows the next balance that is not zero ([_Kind]
  /// order, wrapping); dots beside the caption say there is one. While amounts are hidden it
  /// shows Spendable and a tap does nothing, so the caption gives nothing away.
  Widget _walletPanel(_Balance b, bool keyed) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final summary = b.summary;
    final shown = b.hidden ? _Kind.spendable : _shown;
    final amount = b.amountOf(shown);
    final fiat = b.fiat(context, amount);
    final figureStyle = theme.textTheme.displaySmall;
    final pending = summary != null && b.notSpendable > BigInt.zero;
    final open = _breakdown && pending && shown == _Kind.spendable;
    final next = b.next(shown);
    final cycles = summary != null && !b.hidden && next != shown;
    void cycle() => setState(() => _shown = next);
    final caption = b.caption(l, shown);
    return Padding(
      // The 1.3.1 panel's padding and its 8 dp above the caption; below the life line it
      // keeps part of the room its "Up to date" footer took, so the panel is 1.3.1's height.
      padding: const EdgeInsetsDirectional.fromSTEB(18, 26, 10, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Caption and figure take the tap together; the eye and the ? win their own.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The figure's own Semantics carries the action.
            excludeFromSemantics: true,
            onTap: cycles ? cycle : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The figure's label reads the caption, so screen readers hear it once.
                ExcludeSemantics(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          caption,
                          key: keyed ? spendableCaptionKey : null,
                          style: theme.textTheme.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (cycles) ...[
                        const SizedBox(width: 8),
                        _Dots(
                          key: keyed ? balanceDotsKey : null,
                          count: b.cycled.length,
                          index: b.cycled.indexOf(shown),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Semantics(
                        container: true,
                        button: cycles,
                        label: summary == null
                            ? null
                            : l.balanceHelpRow(
                                caption,
                                b.hidden
                                    ? l.homeBalanceHiddenLabel
                                    : epicText(l, amount),
                              ),
                        onTap: cycles ? cycle : null,
                        onTapHint: cycles ? l.homeBalanceNextHint : null,
                        excludeSemantics: true,
                        // 2 dp above and below the figure's 44 dp line make a 48 dp tap target,
                        // as tall as the eye beside it. A ConstrainedBox(minHeight: 48) here
                        // made Flutter 3.47.5's semantics flush throw (a null geometry) once a
                        // dialog opened over home.
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: _figure(
                            b,
                            keyed: keyed,
                            style: figureStyle,
                            unit: figureStyle,
                            amount: amount,
                          ),
                        ),
                      ),
                    ),
                    if (summary != null) ...[
                      _eye(b),
                      BalanceHelp(summary: summary, hidden: b.hidden),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Each status on a line of its own, centred on it: the node on the fiat line,
          // epicbox on the not-spendable line, or alone while nothing is pending.
          _withStatus(
            fiat == null
                ? null
                : _OneLine(
                    fitKey: keyed ? fiatValueKey : null,
                    text: TextSpan(text: fiat),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
            status: const NodeStatusRow(),
          ),
          if (pending || b.epicbox != null)
            _withStatus(
              !pending
                  ? null
                  : shown == _Kind.spendable
                  ? _BreakdownLine(
                      key: keyed ? notSpendableKey : null,
                      text: l.homeBalanceNotSpendable(
                        shownEpic(l, b.notSpendable, hidden: b.hidden),
                      ),
                      open: open,
                      onTap: () => setState(() => _breakdown = !_breakdown),
                    )
                  // The figure shows a balance not spendable yet, so the line says what
                  // is, and a tap goes back to it.
                  : _BreakdownLine(
                      key: keyed ? notSpendableKey : null,
                      text: l.homeBalanceSpendableLine(
                        epicText(l, b.amountOf(_Kind.spendable)),
                      ),
                      onTap: () => setState(() => _shown = _Kind.spendable),
                    ),
              status: const EpicboxStatusRow(),
            ),
          if (open)
            Padding(
              key: keyed ? breakdownKey : null,
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Column(
                children: [
                  for (final (label, value) in b.buckets(l))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(label)),
                          Text(shownEpic(l, value, hidden: b.hidden)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 16, end: 8),
            child: ProtocolLifeLine(
              key: keyed ? lifeLineKey : null,
              progress: b.syncing ? b.syncProgress : 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// The balances Wallet's figure can show, in the order a tap steps through them.
enum _Kind { spendable, confirming, waitingToFinish, locked, immature }

/// What both panels show, read once per build.
class _Balance {
  _Balance({
    required this.summary,
    required this.node,
    required this.epicbox,
    required this.display,
  });

  final WalletSummary? summary;
  final NodeStatus node;

  /// Null while the listener is stopped.
  final EpicboxState? epicbox;
  final ({bool hidden, double? price, String currency}) display;

  bool get hidden => display.hidden;

  bool get syncing => node.state == NodeState.syncing;

  double get syncProgress => (node.percent ?? 0) / 100;

  BigInt get notSpendable {
    final summary = this.summary;
    return summary == null ? BigInt.zero : summary.total - summary.spendable;
  }

  String? fiat(BuildContext context, [BigInt? amount]) {
    final summary = this.summary;
    return summary == null
        ? null
        : approxFiat(
            context.l10n,
            amount ?? summary.spendable,
            display,
            short: true,
          );
  }

  /// The balance of [kind]; zero before the summary is there.
  BigInt amountOf(_Kind kind) {
    final summary = this.summary;
    if (summary == null) return BigInt.zero;
    return switch (kind) {
      _Kind.spendable => summary.spendable,
      _Kind.confirming => summary.awaitingConfirmation,
      _Kind.waitingToFinish => summary.awaitingFinalization,
      _Kind.locked => summary.locked,
      _Kind.immature => summary.immature,
    };
  }

  /// The caption above Wallet's figure while it shows [kind]: the breakdown's words, shorter
  /// where those are long.
  String caption(AppLocalizations l, _Kind kind) => switch (kind) {
    _Kind.spendable => l.homeBalanceSpendable,
    _Kind.confirming => l.homeBalanceConfirming,
    _Kind.waitingToFinish => l.homeBalanceWaitingToFinish,
    _Kind.locked => l.homeCaptionLocked,
    _Kind.immature => l.homeCaptionMiningRewards,
  };

  /// The kinds a tap steps through: those that are not zero, in order. When Spendable is
  /// zero and only one other is not, Spendable stays one of them, so there are two.
  List<_Kind> get cycled {
    final kinds = [
      for (final k in _Kind.values)
        if (amountOf(k) > BigInt.zero) k,
    ];
    return kinds.length == 1 && kinds.single != _Kind.spendable
        ? [_Kind.spendable, ...kinds]
        : kinds;
  }

  /// The kind after [from] that is not zero, wrapping. With no other, a zero Spendable when
  /// [from] is not Spendable (the pair [cycled] keeps), else [from].
  _Kind next(_Kind from) {
    const kinds = _Kind.values;
    for (var i = 1; i <= kinds.length; i++) {
      final k = kinds[(from.index + i) % kinds.length];
      if (k == from) break;
      if (amountOf(k) > BigInt.zero) return k;
    }
    return from == _Kind.spendable ? from : _Kind.spendable;
  }

  /// The balances that are not spendable yet, zero ones left out.
  List<(String, BigInt)> buckets(AppLocalizations l) {
    final summary = this.summary;
    if (summary == null) return const [];
    return [
      (l.homeBalanceConfirming, summary.awaitingConfirmation),
      (l.homeBalanceWaitingToFinish, summary.awaitingFinalization),
      (l.homeBalanceLocked, summary.locked),
      (l.homeBalanceImmature, summary.immature),
    ].where((b) => b.$2 > BigInt.zero).toList();
  }
}

/// [text] on one line, shrunk rather than wrapped when it is too long, and always one line of
/// [style] high, so a long amount does not change the panel's height.
class _OneLine extends StatelessWidget {
  const _OneLine({required this.text, required this.style, this.fitKey});

  final InlineSpan text;
  final TextStyle? style;

  /// The key of the part that shrinks, so tests measure what is drawn.
  final Key? fitKey;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: AlignmentDirectional.centerStart,
    children: [
      // An unseen line holds the height.
      ExcludeSemantics(
        child: Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Text('0', maxLines: 1, style: style),
        ),
      ),
      FittedBox(
        key: fitKey,
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text.rich(text, maxLines: 1, style: style),
      ),
    ],
  );
}

/// Lays its one or two children over each other at the top, and takes the height of the one
/// that is there, or between the two by [openness] while both are: the first child's at 0,
/// the last's at 1. Clips what does not fit.
class _Blend extends MultiChildRenderObjectWidget {
  const _Blend({required this.openness, required super.children});

  final double openness;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBlend(openness);

  @override
  void updateRenderObject(BuildContext context, _RenderBlend renderObject) {
    renderObject.openness = openness;
  }
}

class _BlendParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderBlend extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BlendParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BlendParentData> {
  _RenderBlend(this._openness);

  double _openness;
  set openness(double value) {
    if (value == _openness) return;
    _openness = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BlendParentData) {
      child.parentData = _BlendParentData();
    }
  }

  double _height(List<double> heights) => heights.length == 1
      ? heights.single
      : heights.first + (heights.last - heights.first) * _openness;

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      BoxConstraints.tightFor(width: constraints.maxWidth);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final heights = [
      for (final child in getChildrenAsList())
        child.getDryLayout(_childConstraints(constraints)).height,
    ];
    if (heights.isEmpty) return constraints.smallest;
    return constraints.constrain(Size(constraints.maxWidth, _height(heights)));
  }

  @override
  void performLayout() {
    final heights = <double>[];
    for (final child in getChildrenAsList()) {
      child.layout(_childConstraints(constraints), parentUsesSize: true);
      heights.add(child.size.height);
    }
    size = heights.isEmpty
        ? constraints.smallest
        : constraints.constrain(Size(constraints.maxWidth, _height(heights)));
  }

  @override
  double computeMinIntrinsicHeight(double width) => _height([
    for (final child in getChildrenAsList()) child.getMinIntrinsicHeight(width),
  ]);

  @override
  double computeMaxIntrinsicHeight(double width) => _height([
    for (final child in getChildrenAsList()) child.getMaxIntrinsicHeight(width),
  ]);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  final _clip = LayerHandle<ClipRectLayer>();

  @override
  void paint(PaintingContext context, Offset offset) {
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
      oldLayer: _clip.layer,
    );
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}

/// "X EPIC not spendable yet" on Wallet, as in 1.3.1: a tap lists the balances behind it
/// ([open] says whether they show). Without [open], a plain line that acts on a tap.
class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({
    super.key,
    required this.text,
    this.open,
    required this.onTap,
  });

  final String text;
  final bool? open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final open = this.open;
    return Semantics(
      button: true,
      expanded: open,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: ConstrainedBox(
          // A full-size tap target, however short the text.
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(text)),
              if (open != null)
                Icon(
                  open ? Icons.expand_less : Icons.expand_more,
                  semanticLabel: open
                      ? l.homeHideBreakdown
                      : l.homeShowBreakdown,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which of the balances a tap on Wallet's figure steps through is shown, as dots: the
/// current one in the accent colour. Seen, not read; the figure's label says the rest.
class _Dots extends StatelessWidget {
  const _Dots({super.key, required this.count, required this.index});

  final int count;

  /// -1 while the figure shows a zero Spendable, which is not one of the steps.
  final int index;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == index ? tokens.accent : tokens.dim,
              ),
              child: const SizedBox.square(dimension: 6),
            ),
          ),
      ],
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

/// The app bar's title: the mark's name, and on a test network its name with a ? whose tooltip
/// says its coins have no value. Mainnet shows no network name.
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
          Tooltip(
            message: l.shellTestNetworkTooltip,
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chainName(l, chain),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: context.tokens.accentText,
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
        ],
        if (trailing case final trailing?) ...[
          const SizedBox(width: 8),
          Flexible(child: trailing),
        ],
      ],
    );
  }
}
