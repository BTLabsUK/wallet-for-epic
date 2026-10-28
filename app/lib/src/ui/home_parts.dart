/// Home's parts taken from the desktop Overview: the balance tiles with icons, one per balance
/// that is not spendable, and the row of destinations that stands in for the sidebar.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../l10n.dart';
import '../pairing_providers.dart' show invoicesShownProvider;
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'theme/advanced.dart';
import 'theme/tokens.dart';

/// Whether the phone shows Outputs: Advanced › Outputs, or a split or consolidation the node
/// did not take yet (never hide what is in use). Home's destination, the Settings › Wallet row
/// and the balance tiles' tap read the same rule.
bool outputsShown(BuildContext context, WidgetRef ref) =>
    AdvancedOptions.has(context, AdvancedFeature.outputs) ||
    (ref.watch(sessionProvider) != null &&
        (ref.watch(homeProvider).value?.transactions.any((t) => t.repostable) ?? false));

/// What of [WalletSummary.awaitingFinalization] is the wallet's own: the change of a send,
/// and the receiving side of a split or consolidation, while not in a block. LEPIC counts the
/// change there and the coins it comes from in [WalletSummary.locked], and leaves it out of
/// Total until the block: it is not money waiting for a sender.
BigInt ownChangeOffChain(Iterable<TxEntry> txs) => txs
    .where(
      (t) =>
          t.blockHeight == null &&
          !t.confirmed &&
          (t.kind == TxKind.sent ||
              (t.kind == TxKind.received && t.transport == 'self')),
    )
    .fold(BigInt.zero, (sum, t) => sum + t.amountCredited);

/// What a balance tile shows.
enum BalanceKind {
  /// In a block, confirming.
  confirming,

  /// Offered to this wallet, not in a block yet (awaiting finalization).
  waitingSender,

  /// Of that, what its sender reports posted (the rows' word): still not in a block, so
  /// never spendable and not in Total until the chain has it (LNX-13).
  senderPosted,

  /// Held by a send in progress.
  locked,

  /// Every balance together.
  total,

  /// Nothing pending: "All confirmed" or "Nothing here yet".
  calm,
}

/// One tile: its kind, glyph, label and value (null for the calm tile).
typedef BalanceTileData = ({
  BalanceKind kind,
  IconData icon,
  String label,
  BigInt? value,
});

/// The tiles for [summary], in a fixed order: every pending balance that is not zero
/// (confirming, waiting for sender, locked in sends), then Total. Maturing mining rewards get
/// no tile on a phone (nobody mines to one); they are in Total and in Outputs. With nothing
/// pending, Total and a calm tile ("All confirmed", or "Nothing here yet" while the wallet
/// has had no payments, [empty]).
List<BalanceTileData> balanceTiles(
  AppLocalizations l,
  WalletSummary summary, {
  required bool empty,
  BigInt? senderPosted,
  BigInt? ownChange,
}) {
  BigInt upTo(BigInt? v, BigInt most) =>
      v == null || v <= BigInt.zero ? BigInt.zero : (v > most ? most : v);
  // The change of the wallet's own sends is in Locked in sends already ([ownChangeOffChain]):
  // never Waiting for sender.
  final own = upTo(ownChange, summary.awaitingFinalization);
  // What senders report posted moves out of Waiting for sender into its own tile, named as
  // its rows are: the tile and the row say the same.
  final posted = upTo(senderPosted, summary.awaitingFinalization - own);
  final waiting = summary.awaitingFinalization - own - posted;
  final pending = <BalanceTileData>[
    if (summary.awaitingConfirmation > BigInt.zero)
      (
        kind: BalanceKind.confirming,
        icon: Icons.timelapse,
        label: l.homeBalanceConfirming,
        value: summary.awaitingConfirmation,
      ),
    if (waiting > BigInt.zero)
      (
        kind: BalanceKind.waitingSender,
        icon: Icons.hourglass_empty,
        label: l.homeTileWaitingSender,
        value: waiting,
      ),
    if (posted > BigInt.zero)
      (
        kind: BalanceKind.senderPosted,
        icon: Icons.hourglass_bottom,
        label: l.txStatusSenderPosted,
        value: posted,
      ),
    if (summary.locked > BigInt.zero)
      (
        kind: BalanceKind.locked,
        icon: Icons.lock_outline,
        label: l.homeTileLocked,
        value: summary.locked,
      ),
  ];
  final total = (
    kind: BalanceKind.total,
    icon: Icons.account_balance_wallet_outlined,
    label: l.homeTileTotal,
    value: summary.total,
  );
  if (pending.isNotEmpty) return [...pending, total];
  // A new wallet shows Total alone (GP-009); a settled one says so beside it.
  if (empty) return [total];
  return [
    total,
    (
      kind: BalanceKind.calm,
      icon: Icons.check,
      label: l.balanceLineAllConfirmed,
      value: null,
    ),
  ];
}

/// How many decimals every balance tile shows: the same for all, five when any
/// amount needs five or more (the rest is cut, never rounded), else four; so the figures
/// line up and compare, on the phone as on the desktop.
int tileDecimals(Iterable<BigInt> values) {
  var most = 0;
  for (final v in values) {
    final text = displayEpic(v);
    final dot = text.indexOf('.');
    final n = dot < 0 ? 0 : text.length - dot - 1;
    if (n > most) most = n;
  }
  return most >= 5 ? 5 : 4;
}

/// [atomic] cut to [decimals] decimals and shown with exactly that many, grouped.
String tileAmount(BigInt atomic, int decimals) {
  final cut = BigInt.from(10).pow(epicDecimals - decimals);
  return formatEpic(atomic - atomic.remainder(cut), minDecimals: decimals, grouped: true);
}

/// The key of the balance tiles row, for tests.
const Key balanceTilesKey = ValueKey('balance-tiles');

/// A tile's key, for tests.
Key balanceTileKey(BalanceKind kind) => ValueKey('balance-tile-${kind.name}');

/// The tiles of the open wallet's balance in a grid that fits the width: as many columns as
/// [width]-wide tiles fit (two on a phone), equal widths, and the last tile alone on its row
/// takes the whole row, as the desktop Overview's breakdown does. Nothing scrolls sideways and
/// no tile is ever cut. A tap on a tile with a value calls [onTap] with its kind (Home opens
/// Outputs with the matching filter); while Advanced hides Outputs the tiles are plain
/// readouts, every one of them (a balance is everyday reading, the page behind it is not).
class BalanceTiles extends ConsumerWidget {
  const BalanceTiles({super.key, required this.onTap});

  final void Function(BalanceKind kind) onTap;

  /// A tile's least width, a row's least height and the gap between tiles.
  static const double width = 150, height = 68, gap = 10;

  /// How many columns [tiles] tiles take at [maxWidth]: as many [width]-wide tiles as fit,
  /// at least one, never more than there are tiles.
  static int columns(double maxWidth, int tiles) =>
      ((maxWidth + gap) / (width + gap)).floor().clamp(1, math.max(1, tiles));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final data = ref.watch(homeProvider).value;
    final summary = data?.summary;
    if (summary == null) return const SizedBox(height: height);
    final hidden = amountDisplay(ref).hidden;
    final outputs = outputsShown(context, ref);
    final now = DateTime.now();
    final tiles = balanceTiles(
      l,
      summary,
      empty: data?.transactions.isEmpty ?? false,
      senderPosted: (data?.transactions ?? const <TxEntry>[])
          .where((t) => senderReportsPosted(t, now: now))
          .fold<BigInt>(BigInt.zero, (sum, t) => sum + t.amountCredited),
      ownChange: ownChangeOffChain(data?.transactions ?? const <TxEntry>[]),
    );
    // The row grows with the text scale: label line, value line and the paddings.
    final scaler = MediaQuery.textScalerOf(context);
    final rowHeight = math.max(
      height,
      24 + scaler.scale(12) * 1.4 + 4 + scaler.scale(15) * 1.2,
    );
    final decimals = tileDecimals([for (final x in tiles) ?x.value]);
    Widget tile(BalanceTileData tile) {
      final value = tile.value;
      final text = value == null
          ? null
          : hidden
          ? hiddenAmount
          : localDigits(l, tileAmount(value, decimals));
      return _BalanceTile(
        key: balanceTileKey(tile.kind),
        icon: tile.icon,
        label: tile.label,
        value: text,
        accent: tile.kind == BalanceKind.confirming,
        onTap: value == null || !outputs ? null : () => onTap(tile.kind),
        semanticsLabel: text == null
            ? tile.label
            : l.balanceHelpRow(tile.label, text),
      );
    }

    return LayoutBuilder(
      key: balanceTilesKey,
      builder: (context, box) {
        final cols = columns(box.maxWidth, tiles.length);
        final rows = <List<BalanceTileData>>[
          for (var i = 0; i < tiles.length; i += cols)
            tiles.sublist(i, math.min(i + cols, tiles.length)),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (r, row) in rows.indexed) ...[
              if (r > 0) const SizedBox(height: gap),
              SizedBox(
                height: rowHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, t) in row.indexed) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Expanded(child: tile(t)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
    required this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool accent;
  final VoidCallback? onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final calm = value == null;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: calm ? t.faint : t.dim,
    );
    final valueStyle = TextStyle(
      fontFamily: t.monoFamily,
      fontSize: 15,
      height: 1.2,
      color: accent ? t.accentText : t.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticsLabel,
      // The action for screen readers too, since the tree below is excluded.
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: t.line),
          borderRadius: BorderRadius.circular(t.radiusSmall),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          // The grid gives every tile its column's width; the label fits it or shrinks a
          // little before it would be cut.
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 15,
                        color: calm
                            ? t.faint
                            : accent
                            ? t.accentText
                            : t.dim,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: labelStyle,
                          ),
                        ),
                      ),

                    ],
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A destination on Home's row: the sidebar's entries, adapted.
enum HomeDestination { activity, outputs, contacts, invoices }

/// A destination tile's key, for tests.
Key homeDestinationKey(HomeDestination d) => ValueKey('home-dest-${d.name}');

/// The row of destinations under the status card: Activity, Outputs (while Advanced shows it,
/// [outputsShown]), Contacts and, on a wallet with invoices, Invoices with the number of
/// invoices to pay as its badge. Each tile is one 64 dp target.
class HomeDestinations extends ConsumerWidget {
  const HomeDestinations({super.key, required this.onOpen});

  final void Function(HomeDestination destination) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final invoices = ref.watch(invoicesShownProvider);
    final toPay = invoices
        ? ref.watch(pendingInvoicesProvider).value?.length ?? 0
        : 0;
    final tiles = <Widget>[
      _DestinationTile(
        key: homeDestinationKey(HomeDestination.activity),
        icon: Icons.format_list_bulleted,
        label: l.homeDestActivity,
        onTap: () => onOpen(HomeDestination.activity),
      ),
      if (outputsShown(context, ref))
        _DestinationTile(
          key: homeDestinationKey(HomeDestination.outputs),
          icon: Icons.data_usage,
          label: l.homeDestOutputs,
          onTap: () => onOpen(HomeDestination.outputs),
        ),
      _DestinationTile(
        key: homeDestinationKey(HomeDestination.contacts),
        icon: Icons.people_outline,
        label: l.settingsContacts,
        onTap: () => onOpen(HomeDestination.contacts),
      ),
      if (invoices)
        _DestinationTile(
          key: homeDestinationKey(HomeDestination.invoices),
          icon: Icons.receipt_long_outlined,
          label: l.invoicesTitle,
          badge: toPay,
          onTap: () => onOpen(HomeDestination.invoices),
        ),
    ];
    return Row(
      children: [
        for (final (i, tile) in tiles.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: tile),
        ],
      ],
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      button: true,
      label: badge > 0 ? '$label, $badge' : label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: t.line),
          borderRadius: BorderRadius.circular(t.radiusSmall),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 20, color: t.accentText),
                    if (badge > 0)
                      PositionedDirectional(
                        top: -6,
                        end: -10,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: t.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$badge',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: t.accentInk,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: t.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
