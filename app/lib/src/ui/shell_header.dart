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

/// The key of the shell's balance header, for tests.
const Key shellHeaderKey = ValueKey('shell-header');

/// The key of the balance figure, for tests.
const Key balanceFigureKey = ValueKey('balance-figure');

/// The key of the fiat value under the figure, for tests.
const Key fiatValueKey = ValueKey('balance-fiat');

/// The key of the "not spendable yet" line, for tests.
const Key notSpendableKey = ValueKey('balance-not-spendable');

/// The key of the sync line at the header's foot, for tests.
const Key headerSyncLineKey = ValueKey('header-sync-line');

/// How far the header is open, from the shell's page position: 1 on Wallet, 0 on Send and
/// Receive, in between while a swipe or a tap moves the page.
double headerOpenness(double page) =>
    (1 - (page - ShellTab.wallet.index).abs()).clamp(0.0, 1.0);

/// The balance header above the three tabs.
///
/// On Wallet ([openness] 1) it is a panel of four or five lines: the spendable figure, large,
/// with the balance help, and the node and epicbox status rows on the right beside it; the
/// fiat value with the hide toggle; "X EPIC not spendable yet" when anything is not spendable,
/// which opens the balance help; and while syncing a thin progress line at the panel's foot.
///
/// On Send and Receive ([openness] 0) it is two lines: a smaller figure with the single worse
/// status's icon at the row's end, and the fiat value under it. In between it scrubs from one
/// to the other.
class ShellHeader extends ConsumerWidget {
  const ShellHeader({super.key, required this.openness});

  final double openness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final t = openness;
    final summary = ref.watch(homeProvider).value?.summary;
    final node = watchWalletStatus(ref).node;
    final display = amountDisplay(ref);
    final hidden = display.hidden;
    final fiat = summary == null
        ? null
        : approxFiat(l, summary.spendable, display);
    final notSpendable = summary == null
        ? BigInt.zero
        : summary.total - summary.spendable;
    // The theme's balance face (Montserrat, tabular) at displayMedium's size on Wallet.
    final figureStyle = TextStyle.lerp(
      theme.textTheme.headlineSmall,
      theme.textTheme.displaySmall?.copyWith(
        fontSize: theme.textTheme.displayMedium?.fontSize,
      ),
      t,
    );
    // On Wallet the unit is about 60 % of the number's size, so the number gets the width.
    final unitStyle = figureStyle?.copyWith(
      fontSize: (figureStyle.fontSize ?? 24) * (1 - 0.4 * t),
    );
    final fiatStyle = TextStyle.lerp(
      theme.textTheme.bodyMedium,
      theme.textTheme.titleMedium,
      t,
    )?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final Widget figure = summary == null
        ? const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Semantics(
            container: true,
            label: hidden ? l.homeBalanceHiddenLabel : null,
            excludeSemantics: hidden,
            // One line however long the balance: it shrinks rather than wraps.
            child: FittedBox(
              key: balanceFigureKey,
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text.rich(
                hidden
                    ? const TextSpan(text: hiddenAmount)
                    : TextSpan(
                        children: [
                          TextSpan(
                            text: localDigits(
                              l,
                              formatEpic(summary.spendable, grouped: true),
                            ),
                          ),
                          // The same words as [epicText], so it reads as one amount.
                          TextSpan(text: ' EPIC', style: unitStyle),
                        ],
                      ),
                maxLines: 1,
                style: figureStyle,
              ),
            ),
          );
    final eye = IconButton(
      tooltip: hidden ? l.homeShowBalances : l.homeHideBalances,
      icon: Icon(
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: () =>
          ref.read(appSettingsProvider.notifier).setHideBalances(!hidden),
    );
    final left = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: figure),
            if (summary != null && t > 0)
              _Collapse(
                openness: t,
                child: BalanceHelp(summary: summary, hidden: hidden),
              ),
          ],
        ),
        // The fiat value on every tab; the hide toggle at its end on Wallet only, so the
        // figure keeps the width.
        if (summary != null && (fiat != null || t > 0))
          Row(
            children: [
              if (fiat != null)
                Flexible(
                  child: Text(fiat, key: fiatValueKey, style: fiatStyle),
                ),
              if (t > 0) _Collapse(openness: t, child: eye),
            ],
          ),
      ],
    );
    final status = Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        if (t > 0)
          _Collapse(
            openness: t,
            axis: Axis.vertical,
            alignment: AlignmentDirectional.centerEnd,
            child: const StatusRows(),
          ),
        if (t < 1)
          IgnorePointer(
            ignoring: t >= 0.5,
            child: Opacity(opacity: 1 - t, child: const CompactStatus()),
          ),
      ],
    );
    final syncing = node.state == NodeState.syncing;
    return Semantics(
      container: true,
      child: ProtocolBalancePanel(
        key: shellHeaderKey,
        // The header pads its own content, so the sync line can run along the panel's foot.
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.lerp(
                // The same end inset open and shrunk, so the status stays at one edge.
                const EdgeInsetsDirectional.fromSTEB(
                  14,
                  6,
                  10,
                  6,
                ).resolve(Directionality.of(context)),
                // The 1.3.1 panel's padding.
                const EdgeInsetsDirectional.fromSTEB(
                  18,
                  18,
                  10,
                  16,
                ).resolve(Directionality.of(context)),
                t,
              )!,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) => Row(
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 8),
                        // At most 40 % of the row: large text shortens the status words
                        // before it squeezes the figure.
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.4,
                          ),
                          child: status,
                        ),
                      ],
                    ),
                  ),
                  if (summary != null && notSpendable > BigInt.zero && t > 0)
                    _Collapse(
                      openness: t,
                      axis: Axis.vertical,
                      child: _NotSpendableLine(
                        summary: summary,
                        amount: notSpendable,
                        hidden: hidden,
                      ),
                    ),
                ],
              ),
            ),
            if (syncing && t > 0)
              _Collapse(
                openness: t,
                axis: Axis.vertical,
                child: ExcludeSemantics(
                  // Determinate, so it never animates by itself; the node row says the
                  // percent to screen readers.
                  child: LinearProgressIndicator(
                    key: headerSyncLineKey,
                    value: (node.percent ?? 0) / 100,
                    minHeight: 2,
                    color: context.tokens.accent,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "X EPIC not spendable yet", under the fiat value on Wallet. A tap opens the balance help.
class _NotSpendableLine extends StatefulWidget {
  const _NotSpendableLine({
    required this.summary,
    required this.amount,
    required this.hidden,
  });

  final WalletSummary summary;
  final BigInt amount;
  final bool hidden;

  @override
  State<_NotSpendableLine> createState() => _NotSpendableLineState();
}

class _NotSpendableLineState extends State<_NotSpendableLine> {
  final _tooltip = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Tooltip(
      key: _tooltip,
      richMessage: BalanceHelp.message(l, widget.summary, widget.hidden),
      triggerMode: TooltipTriggerMode.manual,
      showDuration: const Duration(seconds: 10),
      child: Semantics(
        button: true,
        child: InkWell(
          key: notSpendableKey,
          borderRadius: BorderRadius.circular(8),
          onTap: () => _tooltip.currentState?.ensureTooltipVisible(),
          child: ConstrainedBox(
            // A full-size tap target, however short the text.
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    l.homeBalanceNotSpendable(
                      shownEpic(l, widget.amount, hidden: widget.hidden),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: context.tokens.dim),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.help_outline, size: 16, color: context.tokens.dim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [child] faded and folded along [axis] by [openness], or along both when [axis] is null, so
/// the header's size follows the page.
class _Collapse extends StatelessWidget {
  const _Collapse({
    required this.openness,
    this.axis,
    required this.child,
    this.alignment = AlignmentDirectional.centerStart,
  });

  final double openness;
  final Axis? axis;
  final AlignmentGeometry alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: alignment,
        widthFactor: axis != Axis.vertical ? openness : null,
        heightFactor: axis != Axis.horizontal ? openness : null,
        child: Opacity(opacity: openness, child: child),
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
          text: l.balanceHelpRow(label, shownEpic(l, amount, hidden: hidden)),
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
  const ShellTitle({super.key, required this.chain});

  /// Null before the network is known.
  final Chain? chain;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final chain = this.chain;
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(l.shellTitle, maxLines: 1, overflow: TextOverflow.fade),
        ),
        if (chain != null && chain != Chain.mainnet) ...[
          const SizedBox(width: 8),
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
      ],
    );
  }
}
