import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// How far the header is open, from the shell's page position: 1 on Wallet, 0 on Send and
/// Receive, in between while a swipe or a tap moves the page.
double headerOpenness(double page) =>
    (1 - (page - ShellTab.wallet.index).abs()).clamp(0.0, 1.0);

/// The balance header above the three tabs. On Wallet ([openness] 1) it is one row: the
/// spendable figure with its fiat value, the balance help and the hide toggle on the left; the
/// node and epicbox statuses on the right. On Send and Receive ([openness] 0) it is one line: a
/// smaller figure and the single worse status. In between it scrubs from one to the other.
class ShellHeader extends ConsumerWidget {
  const ShellHeader({super.key, required this.openness});

  final double openness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final t = openness;
    final summary = ref.watch(homeProvider).value?.summary;
    final display = amountDisplay(ref);
    final hidden = display.hidden;
    final fiat = summary == null
        ? null
        : approxFiat(l, summary.spendable, display);
    final figureStyle = TextStyle.lerp(
      theme.textTheme.titleLarge,
      theme.textTheme.displaySmall,
      t,
    );
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
              child: Text(
                shownEpic(l, summary.spendable, hidden: hidden),
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
                axis: Axis.horizontal,
                child: BalanceHelp(summary: summary, hidden: hidden),
              ),
          ],
        ),
        // The fiat value, and the hide toggle at its end so the figure keeps the width.
        if (summary != null && t > 0)
          _Collapse(
            openness: t,
            axis: Axis.vertical,
            child: Row(
              children: [
                if (fiat != null)
                  Flexible(
                    child: Text(
                      fiat,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                eye,
              ],
            ),
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
    return Semantics(
      container: true,
      child: ProtocolBalancePanel(
        key: shellHeaderKey,
        padding: EdgeInsets.lerp(
          const EdgeInsetsDirectional.fromSTEB(
            14,
            2,
            4,
            2,
          ).resolve(Directionality.of(context)),
          const EdgeInsetsDirectional.fromSTEB(
            18,
            12,
            8,
            12,
          ).resolve(Directionality.of(context)),
          t,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 8),
              // At most 40 % of the row: large text shortens the status words before it
              // squeezes the figure.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.4,
                ),
                child: status,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [child] faded and folded along [axis] by [openness], so the header's size follows the page.
class _Collapse extends StatelessWidget {
  const _Collapse({
    required this.openness,
    required this.axis,
    required this.child,
    this.alignment = AlignmentDirectional.centerStart,
  });

  final double openness;
  final Axis axis;
  final AlignmentGeometry alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: alignment,
        widthFactor: axis == Axis.horizontal ? openness : null,
        heightFactor: axis == Axis.vertical ? openness : null,
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

  @override
  State<BalanceHelp> createState() => _BalanceHelpState();
}

class _BalanceHelpState extends State<BalanceHelp> {
  final _tooltip = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final spans = <InlineSpan>[];
    for (final (i, (label, amount, help)) in BalanceHelp.rows(
      l,
      widget.summary,
    ).indexed) {
      if (i > 0) spans.add(const TextSpan(text: '\n\n'));
      spans.add(
        TextSpan(
          text: l.balanceHelpRow(
            label,
            shownEpic(l, amount, hidden: widget.hidden),
          ),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
      if (help != null) spans.add(TextSpan(text: '\n$help'));
    }
    // A button, so screen readers can press it; the tooltip holds the answer.
    return Tooltip(
      key: _tooltip,
      richMessage: TextSpan(children: spans),
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
