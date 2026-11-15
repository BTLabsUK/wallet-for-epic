// SPDX-License-Identifier: Apache-2.0
/// The Home tab of the phone shell (HANDOFF 9, "Home header and status", "Home lists", "Home
/// slot"): the logo and the connection pill, the balance with its fiat value and the eye, two
/// chips for money on its way, Send and Receive, the slot card, and the five latest payments.
///
/// Home shows things by state: it reads no level. Where a switch is meant (what the Advanced
/// setting shows) it reads [advancedPrefsProvider]. The shell ([HomeScreen]) owns the timers
/// and notices; this widget only draws.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advanced.dart' show NetworkMode;
import '../announcements/announcement_card.dart' show AnnouncementToast, firstLiveAnnouncementProvider;
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
import 'home_change.dart';
import 'home_slot.dart';
import 'home_status.dart' show showConnectionsSheet;
import 'net_view.dart';
import 'network_mode_text.dart' show networkModeName;
import 'kit/kit_button.dart';
import 'kit/kit_chip.dart';
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
import 'shell_header.dart' show balanceSheetKey, comingIn, fiatValueKey;
import 'status.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';
import 'tip.dart';
import 'tour/phone_tour.dart';

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
    final announcement = ref.watch(firstLiveAnnouncementProvider);
    final data = home.value;
    final transactions = watchHistory(ref, data?.transactions ?? const <TxEntry>[]);
    final recent = pendingFirst(transactions).take(recentActivityCount).toList();
    // A wallet before its first payment, at rest: nothing found yet and no search under way.
    final fresh =
        data != null &&
        transactions.isEmpty &&
        !restoreUnfinished &&
        !importOffer &&
        !scan.running &&
        scan.error == null &&
        !home.hasError;
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
                      SliverToBoxAdapter(child: _Balance(summary: data?.summary, transactions: transactions, fresh: fresh)),
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 16),
                        sliver: SliverList.list(
                          children: [
                            // A message from BT Labs: above the cards, until dismissed. No
                            // space is kept when nothing is live.
                            if (announcement != null) ...[
                              KitGroup(
                                key: const ValueKey('home-announcement'),
                                children: [AnnouncementToast(announcement, swipeToDismiss: true)],
                              ),
                              const SizedBox(height: homeCardGap),
                            ],
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
                            _Recent(loaded: data != null, recent: recent, fresh: fresh),
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
    final mode = ref.watch(networkModeProvider);
    final state = netHealth(mode, status);
    final label = switch (state) {
      HomeConnection.ready => l.phoneKitReady,
      HomeConnection.syncing => l.phoneHomeSyncing('${(status.node.percent ?? 0).round()}'),
      HomeConnection.reconnecting => l.phoneKitReconnecting,
      HomeConnection.offline => l.phoneHomeOffline,
      HomeConnection.paused => '',
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
                    ready: state == HomeConnection.ready || state == HomeConnection.paused,
                    label: label,
                    modeMark: netModeMark(mode),
                    modeName: mode == NetworkMode.standard ? null : networkModeName(l, mode),
                    showState: state != HomeConnection.paused,
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

/// The balance block: the caption with the eye, the figure (what can be spent now) with its
/// unit, the fiat line, the chips for money on its way (the change of open sends in one
/// confirming chip, [openChange]), and Send and Receive. A tap on the figure opens the balance
/// sheet. With no balance yet a placeholder holds the figure's place; with no connection the
/// last known figure shows and the caption says so. A [fresh] wallet with nothing in it has
/// nothing to send: Receive is the gold button there, and Send takes it back with the first
/// payment.
class _Balance extends ConsumerWidget {
  const _Balance({required this.summary, required this.transactions, required this.fresh});

  final WalletSummary? summary;
  final List<TxEntry> transactions;

  /// No payment yet and nothing being searched for (see [HomeTab]).
  final bool fresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final display = amountDisplay(ref);
    final hidden = display.hidden;
    final lastKnown = ref.watch(balanceLastKnownProvider);
    final summary = this.summary;
    final target = confirmationsTargetOf(ref);
    final sends = openChange(transactions, tipHeight(ref), target: target, nameOf: (tx) => txPartyName(ref, tx));
    final change = changeSum(sends);
    // Home shows what can be spent now; the change of open sends is in the confirming chip.
    final figure = summary?.spendable;
    final fiat = figure == null ? null : phoneFiat(l, figure, display, approx: true);
    final arriving = summary == null ? BigInt.zero : _clampZero(comingIn(summary) - changeInBlock(sends));
    final inSends = change > BigInt.zero ? BigInt.zero : summary?.locked ?? BigInt.zero;
    final receiveFirst = fresh && figure == BigInt.zero && change == BigInt.zero;
    void openSheet() {
      final s = summary;
      if (s == null) return;
      showKitSheet<void>(
        context: context,
        builder: (_) => BalanceSheet(summary: s, hidden: hidden, sends: sends, target: target),
      );
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
      if (!hidden && change > BigInt.zero)
        kitId(
          TrustIds.homeChange,
          KitChip(
            changeChipText(l, sends, epicFor(l, change, unit: false)),
            leading: PhoneProgressMark(fraction: changeFraction(sends, target), size: 13),
            info: true,
            onTap: openSheet,
            semanticsLabel: changeChipText(l, sends, epicText(l, change)),
          ),
        ),
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
                          kind: receiveFirst ? KitButtonKind.quiet : KitButtonKind.gold,
                          onPressed: () => showShellFlow(context, ShellFlow.send),
                          semanticsId: TrustIds.tabSend,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: KitButton(
                          label: l.homeReceiveButton,
                          icon: KitIcons.receive,
                          kind: receiveFirst ? KitButtonKind.gold : KitButtonKind.quiet,
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

/// The balance sheet: what can be spent now; the change of open sends, confirming, with a row
/// for each send and what it waits for; the other balances that are not zero (payments
/// arriving, offered, mining rewards, coins a send holds when it has no change); and the total
/// of the rows, payments only offered left out. While change is confirming, a note says why.
class BalanceSheet extends StatelessWidget {
  const BalanceSheet({
    super.key,
    required this.summary,
    required this.hidden,
    this.sends = const [],
    this.target = 6,
  });

  final WalletSummary summary;
  final bool hidden;

  /// The open sends with change ([openChange]).
  final List<OpenChange> sends;

  /// The confirmations the balance counts with.
  final int target;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final change = changeSum(sends);
    final inBlock = changeInBlock(sends);
    final arriving = _clampZero(summary.awaitingConfirmation - inBlock);
    final offered = _clampZero(summary.awaitingFinalization - (change - inBlock));
    // While change confirms, the coins its sends hold are spent: only what is held for a
    // linked device stays in.
    final held = change > BigInt.zero ? summary.held ?? BigInt.zero : summary.locked;
    final total = summary.spendable + change + arriving + held + summary.immature;
    String shown(BigInt v) => shownEpic(l, v, hidden: hidden, exact: true);
    KitRow row(String title, BigInt amount, {String? help}) =>
        KitRow(title: title, subtitle: help, subtitleLines: 3, value: shown(amount), size: KitRowSize.list);
    return KitSheet(
      key: balanceSheetKey,
      title: l.balanceSheetTitle,
      primaryLabel: l.commonDone,
      onPrimary: () => Navigator.of(context).maybePop(),
      primaryKind: KitButtonKind.quiet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitGroup(
            onSheet: true,
            children: [
              row(l.phoneBalanceAvailableNow, summary.spendable),
              if (change > BigInt.zero) ...[
                KitRow(
                  title: l.homeBalanceConfirming,
                  titleColor: t.info,
                  leading: PhoneProgressMark(fraction: changeFraction(sends, target), size: 14),
                  value: shown(change),
                  size: KitRowSize.list,
                ),
                for (final c in sends)
                  KitRow(
                    leading: const SizedBox(width: 14),
                    title: txTitle(l, c.tx, contactName: c.who),
                    subtitleWidget: Text(
                      changeRowHint(l, c, target),
                      style: KitType.rowSub.copyWith(color: t.info),
                    ),
                    value: shown(c.change),
                    size: KitRowSize.list,
                  ),
              ],
              if (arriving > BigInt.zero) row(l.phoneBalanceArriving, arriving, help: l.balanceConfirmingHelp),
              if (offered > BigInt.zero) row(l.homeBalanceNotOnChain, offered, help: l.balanceNotOnChainHelp),
              if (held > BigInt.zero) row(l.homeBalanceLocked, held, help: l.balanceLockedHelp),
              if (summary.immature > BigInt.zero) row(l.homeBalanceImmature, summary.immature, help: l.balanceImmatureHelp),
              // With nothing else in, Available now is the total: one row says it.
              if (total != summary.spendable) row(l.balanceTotal, total),
            ],
          ),
          if (change > BigInt.zero)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Text(l.phoneBalanceChangeNote(target), style: KitType.rowSub.copyWith(color: t.dim)),
            ),
        ],
      ),
    );
  }
}

BigInt _clampZero(BigInt v) => v < BigInt.zero ? BigInt.zero : v;

/// The "Recent" heading and its rows. Before the first payment a [fresh] wallet shows the list
/// as empty slots ([_RecentSlots]); a wallet that is being restored or searched shows nothing.
/// [loaded] is false until the first read.
class _Recent extends ConsumerWidget {
  const _Recent({required this.loaded, required this.recent, required this.fresh});

  final bool loaded;
  final List<TxEntry> recent;
  final bool fresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    if (!loaded) return const SizedBox.shrink();
    if (recent.isEmpty) return fresh ? const _RecentSlots() : const SizedBox.shrink();
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

/// Recent before the first payment: the heading, and the list drawn as empty slots that fade
/// out downwards. The first slot says what lands in it. Nothing here takes a tap, and the first
/// payment's row takes the first slot's place without moving the list.
class _RecentSlots extends ConsumerWidget {
  const _RecentSlots();

  /// The lines that stand in for a name, a date and an amount, one set per empty slot.
  static const List<(double, double, double)> _lines = [(132, 84, 52), (108, 96, 44), (120, 72, 48)];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSectionHead(
          l.phoneHomeRecent,
          top: ref.watch(homeSlotVisibleProvider).isEmpty ? 18 : 13,
          // No "See all" yet. Its height stays, so the heading and the list sit where they
          // will when the first payment lands.
          trailing: const SizedBox(height: Kit.touchMin),
        ),
        ShaderMask(
          blendMode: BlendMode.dstIn,
          // Only the alpha counts: whole at the top, gone at the bottom.
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.bg, t.bg.withValues(alpha: 0)],
            stops: const [0.36, 1],
          ).createShader(rect),
          child: KitGroup(
            children: [
              KitRow(
                leading: const _Slot(icon: KitIcons.receive),
                title: l.phoneHomeFirstPayment,
                subtitle: l.phoneHomeFirstPaymentHint,
                subtitleLines: 2,
              ),
              for (final (name, date, amount) in _lines)
                ExcludeSemantics(child: _SlotRow(name: name, date: date, amount: amount)),
            ],
          ),
        ),
      ],
    );
  }
}

/// An avatar's place with nothing in it yet: 40, radius 13, a dashed outline, and the [icon] of
/// what will fill it on the first one.
class _Slot extends StatelessWidget {
  const _Slot({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return CustomPaint(
      painter: _DashedOutline(t.faint.withValues(alpha: 0.5)),
      child: SizedBox.square(
        dimension: Kit.avatar,
        child: icon == null ? null : Center(child: ExcludeSemantics(child: Icon(icon, size: 18, color: t.dim))),
      ),
    );
  }
}

/// One empty slot of the list: the avatar's outline and three quiet lines where a payment's
/// name, date and amount go. The height and the padding are a list row's.
class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.name, required this.date, required this.amount});

  final double name;
  final double date;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget line(double width) => Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(4)),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Kit.rowList),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const _Slot(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [line(name), const SizedBox(height: 9), line(date)],
              ),
            ),
            line(amount),
          ],
        ),
      ),
    );
  }
}

/// A dashed rounded square, the outline of an avatar that is not there yet.
class _DashedOutline extends CustomPainter {
  const _DashedOutline(this.color);

  final Color color;

  static const double _stroke = 1.5;
  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(_stroke / 2), const Radius.circular(Kit.rAvatar)));
    for (final metric in outline.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += _dash + _gap) {
        final end = at + _dash;
        canvas.drawPath(metric.extractPath(at, end > metric.length ? metric.length : end), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline old) => old.color != color;
}
