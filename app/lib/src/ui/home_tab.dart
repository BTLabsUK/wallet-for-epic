// SPDX-License-Identifier: Apache-2.0
/// The Home tab of the phone shell (HANDOFF 9, "Home header and status", "Home lists", "Home
/// slot"): the logo and the connection pill, the balance with its fiat value and the eye, two
/// chips for money on its way, Send and Receive, the slot card, and the five latest payments.
///
/// Home shows things by state: it reads no level. Where a switch is meant (what the Advanced
/// setting shows) it reads [effectiveAdvancedProvider]. The shell ([HomeScreen]) owns the timers
/// and notices; this widget only draws.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../errors.dart';
import '../l10n.dart';
import '../models.dart';
import '../providers.dart';
import '../recent_activity.dart';
import '../restore_scan.dart';
import '../settings.dart';
import '../trust_ids.dart';
import '../devices/phone_devices.dart' show watchHistory;
import 'common.dart';
import 'home_screen.dart' show homeCardGap;
import 'home_parts.dart' show ownChangeOffChain;
import 'home_slot.dart';
import 'home_status.dart' show showConnectionsSheet;
import 'kit/kit_button.dart';
import 'kit/kit_chip.dart';
import 'kit/kit_empty_state.dart';
import 'kit/kit_group.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_row.dart';
import 'kit/kit_sheet.dart';
import 'kit/kit_status_pill.dart';
import 'kit/kit_support.dart';
import 'kit/kit_tokens.dart';
import 'phone_tx_row.dart';
import 'restore_card.dart';
import 'restore_screen.dart' show ScanProgressView;
import 'shell_header.dart' show BalanceHelp, balanceSheetKey, comingIn, fiatValueKey, walletFigure;
import 'status.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';
import 'tip.dart';
import 'tour/phone_tour.dart';

/// Where Home's connection pill stands, from the node and Epicbox statuses.
enum HomeConnection { ready, syncing, reconnecting, offline }

/// The pill's state for [status]. Epicbox stopped (null) does not count against the wallet.
HomeConnection homeConnection(WalletStatus status) {
  final node = status.node.state;
  final box = status.epicbox;
  final boxDown = box == EpicboxState.offline || box == EpicboxState.blocked;
  if (node == NodeState.offline && boxDown) return HomeConnection.offline;
  if (node == NodeState.offline || node == NodeState.connecting || box == EpicboxState.connecting || boxDown) {
    return HomeConnection.reconnecting;
  }
  if (node == NodeState.syncing) return HomeConnection.syncing;
  return HomeConnection.ready;
}

/// The key of Home's balance figure, for tests.
const Key homeFigureKey = ValueKey('home-figure');

/// The key of Home's pill, for tests.
const Key homePillKey = ValueKey('home-pill');

/// Home: the first tab of the shell. [onRefresh] is the pull-to-refresh the shell runs.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final home = ref.watch(homeProvider);
    final scan = ref.watch(scanProvider);
    final restoreUnfinished = ref.watch(restoreScanProvider.select((r) => r.required));
    final importOffer = ref.watch(historyImportOfferProvider);
    final data = home.value;
    final transactions = watchHistory(ref, data?.transactions ?? const <TxEntry>[]);
    final recent = pendingFirst(transactions).take(recentActivityCount).toList();
    final t = context.tokens;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HomeHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: CustomScrollView(
                    // Pull to refresh works on a short list too.
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _Balance(summary: data?.summary, transactions: transactions)),
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 16),
                        sliver: SliverList.list(
                          children: [
                            // The cards carry the gutter themselves.
                            const HomeSlot(),
                            // An unfinished restore: its own card, with the scan in it.
                            if (restoreUnfinished || importOffer)
                              const Padding(padding: EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, homeCardGap), child: RestoreCard())
                            else if (scan.running || scan.error != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, homeCardGap),
                                child: Container(
                                  padding: const EdgeInsets.all(Kit.gutter),
                                  decoration: BoxDecoration(color: t.group, borderRadius: BorderRadius.circular(Kit.rGroup)),
                                  child: ScanProgressView(scan: scan),
                                ),
                              ),
                            // The recovery phrase reminder is a notice (the shell), not a card.
                            if (home.hasError && !home.isLoading)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, homeCardGap),
                                child: ErrorText(describeError(l, home.error!)),
                              ),
                            _Recent(loaded: data != null, recent: recent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The logo at the start and the connection pill at the end.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = watchWalletStatus(ref);
    final state = homeConnection(status);
    final label = switch (state) {
      HomeConnection.ready => l.phoneKitReady,
      HomeConnection.syncing => l.phoneHomeSyncing('${(status.node.percent ?? 0).round()}'),
      HomeConnection.reconnecting => l.phoneKitReconnecting,
      HomeConnection.offline => l.phoneHomeOffline,
    };
    // `.bar`: 44 tall at the safe area's top, 16 in; the logo, a spacer, the pill.
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
        child: Row(
          children: [
            // The logo is the mark alone: it names the app to a screen reader.
            Semantics(label: l.shellTitle, image: true, excludeSemantics: true, child: const EpicMark(size: 26)),
            const SizedBox(width: 10),
            // Flexible: at large text the word ellipsizes beside the logo instead of overflowing.
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                // The bar is 44 as drawn; the pill's 48 tall target reaches past it.
                child: OverflowBox(
                  maxHeight: 48,
                  alignment: AlignmentDirectional.centerEnd,
                  child: KitStatusPill(
                    key: homePillKey,
                    ready: state == HomeConnection.ready,
                    label: label,
                    onTap: () => showConnectionsSheet(context),
                    semanticsId: TrustIds.homeStatus,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The balance block: the caption with the eye, the figure with its unit, the fiat line, the
/// chips for money on its way, and Send and Receive. A tap on the figure opens the balance
/// sheet. With no balance yet a placeholder holds the figure's place; with no connection the
/// last known figure shows and the caption says so.
class _Balance extends ConsumerWidget {
  const _Balance({required this.summary, required this.transactions});

  final WalletSummary? summary;
  final List<TxEntry> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final display = amountDisplay(ref);
    final hidden = display.hidden;
    final lastKnown = ref.watch(balanceLastKnownProvider);
    final summary = this.summary;
    final own = ownChangeOffChain(transactions);
    final figure = summary == null ? null : walletFigure(summary, own);
    final fiat = figure == null ? null : phoneFiat(l, figure, display, approx: true);
    final arriving = summary == null ? BigInt.zero : comingIn(summary);
    final inSends = summary?.locked ?? BigInt.zero;
    void openSheet() {
      final s = summary;
      if (s == null) return;
      showKitSheet<void>(context: context, builder: (_) => BalanceSheet(summary: s, ownChange: own, hidden: hidden));
    }

    final eye = Tip(
      hidden ? l.homeShowBalances : l.homeHideBalances,
      above: true,
      child: kitId(
        TrustIds.homeEye,
        KitPress(
          onTap: () => ref.read(appSettingsProvider.notifier).setHideBalances(!hidden),
          radius: Kit.rPill,
          semanticsLabel: hidden ? l.homeShowBalances : l.homeHideBalances,
          child: SizedBox(
            width: Kit.touchMin,
            height: Kit.touchMin,
            child: Icon(hidden ? KitIcons.eyeOff : KitIcons.eye, size: 14, color: t.dim),
          ),
        ),
      ),
    );
    // `.lbl`: the word at 13 and the 14 eye 6 after it. The eye's target is 48 wide and tall,
    // so the eye is pulled 11 back and a 28 spacer at the start keeps the line centred.
    final caption = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (summary != null) const SizedBox(width: 28),
        Flexible(
          child: Text(
            lastKnown ? l.phoneHomeBalanceLastKnown : l.phoneKitAvailable,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KitType.rowSub.copyWith(color: t.dim),
          ),
        ),
        if (summary != null) Transform.translate(offset: const Offset(-11, 0), child: eye),
      ],
    );
    final Widget figureWidget = figure == null
        ? const _FigurePlaceholder()
        : _Figure(balance: figure, hidden: hidden, onTap: openSheet, label: l.phoneHomeBalanceSheetHint);
    final chips = <Widget>[
      if (!hidden && arriving > BigInt.zero)
        KitChip(
          l.phoneHomeArriving(epicFor(l, arriving, unit: false)),
          leading: const PhoneProgressMark(fraction: 2 / 3, size: 13),
          info: true,
          onTap: openSheet,
          semanticsLabel: l.phoneHomeArriving(epicText(l, arriving)),
        ),
      if (!hidden && inSends > BigInt.zero)
        KitChip(
          l.phoneHomeInSends(epicFor(l, inSends, unit: false)),
          icon: KitIcons.lock,
          iconSize: 12,
          onTap: openSheet,
          semanticsLabel: l.phoneHomeInSends(epicText(l, inSends)),
        ),
    ];
    return PhoneTourTarget(
      id: 'tour-balance',
      // `.bal` after a 26 gap under the bar: caption 16, amount +8, fiat +8, buttons +24, the
      // section 34 below. The caption's target is 48 tall, so everything under it is pulled up
      // by 16, the 13 above is what the 26 leaves under the 44 bar's 48 pill target (measured
      // against the frame), and the section head gives back the 16.
      child: Padding(
        // With chips the frame lifts the block by 10 (`margin-top: 16` instead of 26).
        padding: EdgeInsets.fromLTRB(Kit.gutter, chips.isEmpty ? 13 : 3, Kit.gutter, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: caption),
            Transform.translate(
              offset: const Offset(0, -16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 8), child: figureWidget),
                  if (fiat != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        fiat,
                        key: fiatValueKey,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KitType.body.copyWith(color: t.dim, height: 1.3),
                      ),
                    ),
                  // `.chips`: 12 below the fiat, 28 tall, 18 above the buttons. The chips' target is
                  // 48 tall, so 10 comes off each side and the spacing is what is left.
                  if (chips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(alignment: WrapAlignment.center, spacing: 8, children: chips),
                    ),
                  SizedBox(height: chips.isEmpty ? 24 : 8),
                  Row(
                    children: [
                      Expanded(
                        child: KitButton(
                          label: l.homeSendButton,
                          icon: KitIcons.send,
                          onPressed: () => showShellFlow(context, ShellFlow.send),
                          semanticsId: TrustIds.tabSend,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: KitButton(
                          label: l.homeReceiveButton,
                          icon: KitIcons.receive,
                          kind: KitButtonKind.quiet,
                          onPressed: () => showShellFlow(context, ShellFlow.receive),
                          semanticsId: TrustIds.tabReceive,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The balance's place while the first read is on its way.
class _FigurePlaceholder extends StatelessWidget {
  const _FigurePlaceholder();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: Center(
      child: SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: context.tokens.dim),
      ),
    ),
  );
}

/// The figure at 50 with its fraction dimmed and the gold EPIC at its top right. It keeps to
/// one line: a long figure shrinks.
class _Figure extends StatelessWidget {
  const _Figure({required this.balance, required this.hidden, required this.onTap, required this.label});

  final BigInt balance;
  final bool hidden;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = hidden ? hiddenAmount : localDigits(l, surfaceEpic(balance, AmountSurface.hero));
    // The fraction is the last run of digits after a separator; a hidden figure has none.
    final cut = hidden ? null : RegExp(r'[.,٫]\p{Nd}+$', unicode: true).firstMatch(text);
    final whole = cut == null ? text : text.substring(0, cut.start);
    final fraction = cut == null ? '' : text.substring(cut.start);
    final base = KitType.homeBalance.copyWith(color: t.text, fontFeatures: const [FontFeature.tabularFigures()]);
    final spoken = hidden ? l.homeBalanceHiddenLabel : epicExact(l, balance);
    return Semantics(
      button: true,
      label: '${l.homeWalletBalance}: $spoken',
      hint: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: kitId(
          TrustIds.homeBalance,
          Padding(
            padding: EdgeInsets.zero,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: whole),
                        if (fraction.isNotEmpty)
                          TextSpan(
                            text: fraction,
                            style: TextStyle(color: t.text.withValues(alpha: KitType.homeBalanceFraction)),
                          ),
                      ],
                    ),
                    key: homeFigureKey,
                    maxLines: 1,
                    softWrap: false,
                    textScaler: TextScaler.noScaling,
                    style: base,
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8, top: 6),
                    child: Text(epicUnit, textScaler: TextScaler.noScaling, style: KitType.unit.copyWith(color: t.accentText)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The balance sheet: the balance and each other balance that is not zero, from
/// [BalanceHelp.rows], the exact amount at the end of each row.
class BalanceSheet extends StatelessWidget {
  const BalanceSheet({super.key, required this.summary, required this.hidden, this.ownChange});

  final WalletSummary summary;
  final BigInt? ownChange;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rows = BalanceHelp.rows(l, summary, ownChange: ownChange);
    return KitSheet(
      key: balanceSheetKey,
      title: l.balanceSheetTitle,
      child: KitGroup(
        onSheet: true,
        children: [
          for (final (label, amount, help) in rows)
            KitRow(
              title: label,
              subtitle: help,
              value: shownEpic(l, amount, hidden: hidden, exact: true),
              size: KitRowSize.list,
            ),
        ],
      ),
    );
  }
}

/// The "Recent" heading and its rows, or the line that stands for them before the first
/// payment. [loaded] is false until the first read.
class _Recent extends ConsumerWidget {
  const _Recent({required this.loaded, required this.recent});

  final bool loaded;
  final List<TxEntry> recent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    if (!loaded) return const SizedBox.shrink();
    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            KitEmptyState(
              icon: KitIcons.receive,
              title: l.phoneHomeEmpty,
              actionLabel: l.homeReceiveEpicButton,
              onAction: () => showShellFlow(context, ShellFlow.receive),
              actionId: TrustIds.homeReceiveEmpty,
              actionKind: KitButtonKind.quiet,
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSectionHead(
          l.phoneHomeRecent,
          // `.sec` sits 34 under the buttons, 14 under the slot's page dots (Home-busy).
          top: ref.watch(homeSlotVisibleProvider).isEmpty ? 18 : 13,
          trailing: kitId(
            TrustIds.homeSeeall,
            KitPress(
              onTap: () => ref.read(shellTabProvider.notifier).go(ShellTab.activity),
              radius: Kit.rButton,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Kit.touchMin),
                child: Center(
                  widthFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(l.phoneHomeSeeAll, style: KitType.rowSub.copyWith(color: t.accentText, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ),
          ),
        ),
        KitGroup(children: [for (final tx in recent) PhoneTxRow(tx: tx, dated: true)]),
      ],
    );
  }
}
