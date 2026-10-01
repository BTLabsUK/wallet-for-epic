import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../contacts.dart' show contactNameFor, contactsProvider;
import '../l10n.dart';
import '../price.dart';
import '../providers.dart';
import '../settings.dart';
import '../wallet_service.dart';
import 'home_screen.dart';
import 'launch_screen.dart';
import 'tx_details_screen.dart';

/// Replaces the whole navigation stack with the home screen of the open wallet.
void goHome(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    (_) => false,
  );
}

/// Closes the wallet and returns to the unlock screen.
void lockWallet(BuildContext context, WidgetRef ref) {
  ref.read(sessionProvider.notifier).lock();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
    (_) => false,
  );
}

/// Copies [text] and confirms in the notice slot with [notice], a whole sentence such as
/// `l.addressCopied` (never a noun with "copied" glued on: other languages inflect it).
/// Never use this for the recovery phrase.
Future<void> copyText(BuildContext context, String text, String notice) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(noticeProvider.notifier).show(notice);
}

/// How long a notice stays in the slot unless it is persistent.
const Duration noticeDuration = Duration(seconds: 4);

/// The height of the notice slot at text scale 1: one line of text beside a 48 dp button,
/// with 4 dp above and below. It grows with larger text only.
const double noticeSlotHeight = 56;

/// The key of the notice shown in a slot, for tests.
const Key noticeKey = ValueKey('notice');

/// A button on a notice, where a snack bar had an action.
class NoticeAction {
  const NoticeAction(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}

/// A short message for the notice slot.
class Notice {
  const Notice(this.id, this.text, {this.action, this.persistent = false});

  /// Distinct per [NoticeNotifier.show] call, so the same text shown twice counts twice.
  final int id;
  final String text;
  final NoticeAction? action;

  /// Stays until replaced or closed, instead of leaving after [noticeDuration].
  final bool persistent;
}

/// The notice every [NoticeSlot] shows: one at a time, the newest wins.
final noticeProvider = NotifierProvider<NoticeNotifier, Notice?>(
  NoticeNotifier.new,
);

class NoticeNotifier extends Notifier<Notice?> {
  Timer? _timer;
  int _next = 0;

  @override
  Notice? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  /// Shows [text], replacing any notice. It leaves after [noticeDuration] unless [persistent].
  void show(String text, {NoticeAction? action, bool persistent = false}) {
    _timer?.cancel();
    final notice = Notice(
      _next++,
      text,
      action: action,
      persistent: persistent,
    );
    state = notice;
    if (!persistent) {
      _timer = Timer(noticeDuration, () => dismiss(notice.id));
    }
  }

  /// Removes the notice, or only the one with [id] when given.
  void dismiss([int? id]) {
    if (id != null && state?.id != id) return;
    _timer?.cancel();
    state = null;
  }
}

/// A fixed-height strip under the app bar for the current notice, so the content below never
/// moves. With no notice it shows [idle] (a screen's own status, such as a progress bar), or
/// empty space.
class NoticeSlot extends ConsumerWidget {
  const NoticeSlot({super.key, this.idle});

  final Widget? idle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(noticeProvider);
    final height = max(
      noticeSlotHeight,
      MediaQuery.textScalerOf(context).scale(noticeSlotHeight),
    );
    return SizedBox(
      height: height,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: notice == null
            ? (idle ?? const SizedBox.shrink())
            : _NoticeView(key: ValueKey(notice.id), notice: notice),
      ),
    );
  }
}

class _NoticeView extends ConsumerWidget {
  const _NoticeView({super.key, required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final action = notice.action;
    final notifier = ref.read(noticeProvider.notifier);
    return Padding(
      key: noticeKey,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: action == null && !notice.persistent ? 16 : 4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    notice.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onSecondaryContainer),
                  ),
                ),
              ),
              if (action != null)
                TextButton(
                  onPressed: () {
                    notifier.dismiss(notice.id);
                    action.onPressed();
                  },
                  child: Text(action.label),
                ),
              if (notice.persistent)
                IconButton(
                  tooltip: context.l10n.commonClose,
                  icon: const Icon(Icons.close),
                  onPressed: () => notifier.dismiss(notice.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin progress bar along the top of a [NoticeSlot], for [SlotScaffold.idle]: work that runs
/// while the screen stays usable. Indeterminate when [value] is null.
class SlotProgress extends StatelessWidget {
  const SlotProgress({super.key, this.value, required this.label});

  final double? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: LinearProgressIndicator(
        minHeight: 2,
        value: value,
        semanticsLabel: label,
      ),
    );
  }
}

/// A [Scaffold] with a [NoticeSlot] under the app bar. With [centered], [body] sits in the
/// middle of the space left (and scrolls when it does not fit); otherwise it starts right
/// below the slot. [idle] is what the slot shows when there is no notice.
class SlotScaffold extends StatelessWidget {
  const SlotScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.centered = false,
    this.idle,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool centered;
  final Widget? idle;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoticeSlot(idle: idle),
          Expanded(
            child: centered
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(child: body),
                      ),
                    ),
                  )
                : body,
          ),
        ],
      ),
    );
  }
}

/// `1,234.5 EPIC`, with [l]'s separators (`1.234,5 EPIC` in German). Display only; see
/// [formatEpic] and [localDigits].
String epicText(AppLocalizations l, BigInt atomic) =>
    '${localDigits(l, formatEpic(atomic, grouped: true))} EPIC';

/// What an amount shows while balances are hidden.
const String hiddenAmount = '•••••';

/// [epicText], or [hiddenAmount] when [hidden].
String shownEpic(AppLocalizations l, BigInt atomic, {required bool hidden}) =>
    hidden ? hiddenAmount : epicText(l, atomic);

/// An epicbox address short enough for a list or a title: the first and last 6 characters of
/// the key around an ellipsis, then `@relay`. With [ownServer] (the host of the wallet's own
/// epicbox server), `@relay` is dropped when it is that server, since it tells the user nothing.
/// URLs, and keys already short, come back as they are. Show the full address wherever the user
/// may need to check or copy it.
String shortAddress(String address, {String? ownServer}) {
  final text = address.trim();
  final lower = text.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return text;
  final at = text.indexOf('@');
  final key = at < 0 ? text : text.substring(0, at);
  var relay = at < 0 ? '' : text.substring(at);
  if (ownServer != null && relay.isNotEmpty) {
    final host = relay.substring(1).split(':').first.toLowerCase();
    if (host == ownServer.trim().toLowerCase()) relay = '';
  }
  final shortKey = key.length <= 14
      ? key
      : '${key.substring(0, 6)}…${key.substring(key.length - 6)}';
  return '$shortKey$relay';
}

/// `2,500,000`, with [l]'s thousands separator.
String groupDigits(AppLocalizations l, Object number) => localInt(l, number);

/// The display settings every amount depends on: hidden or not, and the fiat price.
({bool hidden, double? price, String currency}) amountDisplay(WidgetRef ref) {
  final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
  return (
    hidden: settings.hideBalances,
    price: settings.showFiat ? ref.watch(priceProvider).value : null,
    currency: settings.fiatCurrency,
  );
}

/// `≈ 1.23 USD` for [atomic], or null when there is no price or amounts are hidden.
String? approxFiat(
  AppLocalizations l,
  BigInt atomic,
  ({bool hidden, double? price, String currency}) display,
) {
  final price = display.price;
  if (price == null || display.hidden) return null;
  return '≈ ${localDigits(l, fiatText(atomic, price, display.currency))}';
}

// Dates.

String _two(int v) => v.toString().padLeft(2, '0');

DateTime localTime(int unixSeconds) =>
    DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);

/// Local `yyyy-MM-dd HH:mm`, the same in every language.
String formatTimestamp(int unixSeconds) {
  final t = localTime(unixSeconds);
  return '${t.year}-${_two(t.month)}-${_two(t.day)} ${_two(t.hour)}:${_two(t.minute)}';
}

/// `21 Sep 2026, 14:05`.
String formatDateTime(AppLocalizations l, DateTime t) =>
    l.dateWithTime(localDay(l, t), localClock(l, t));

/// Whole days from [t]'s local date to [now]'s: 0 for today, 1 for yesterday.
int daysAgo(DateTime t, DateTime now) => DateTime(
  now.year,
  now.month,
  now.day,
).difference(DateTime(t.year, t.month, t.day)).inDays;

/// A day heading: `Today`, `Yesterday`, else `21 Sep 2026`.
String dayLabel(AppLocalizations l, DateTime t, DateTime now) =>
    switch (daysAgo(t, now)) {
      0 => l.dateToday,
      1 => l.dateYesterday,
      _ => localDay(l, t),
    };

/// A short time for a list row: `Today, 14:05`, `Yesterday, 14:05`, `21 Sep, 14:05`, and the
/// year added for other years.
String shortDate(AppLocalizations l, DateTime t, DateTime now) {
  final time = localClock(l, t);
  return switch (daysAgo(t, now)) {
    0 => l.dateWithTime(l.dateToday, time),
    1 => l.dateWithTime(l.dateYesterday, time),
    _ when t.year == now.year => l.dateWithTime(localDayMonth(l, t), time),
    _ => localDay(l, t),
  };
}

// Transactions.

/// The amount a transaction moved, excluding the fee, and whether it left the wallet.
({BigInt amount, bool outgoing}) txAmount(TxEntry tx) {
  final net = tx.amountCredited - tx.amountDebited;
  if (!net.isNegative) return (amount: net, outgoing: false);
  final sent = -net - (tx.fee ?? BigInt.zero);
  return (amount: sent.isNegative ? BigInt.zero : sent, outgoing: true);
}

/// `+5 EPIC`, `-1 EPIC`, or [hiddenAmount].
String signedEpic(AppLocalizations l, TxEntry tx, {required bool hidden}) {
  if (hidden) return hiddenAmount;
  final (:amount, :outgoing) = txAmount(tx);
  return '${outgoing ? '-' : '+'}${epicText(l, amount)}';
}

bool _outgoingKind(TxEntry tx) =>
    tx.kind == TxKind.sent || tx.kind == TxKind.sentCancelled;

/// The row title, the same style for every row: the contact's name, else the other side's
/// short address, else what kind of payment it is. The status is never in the title, only in
/// the chip.
String txTitle(
  AppLocalizations l,
  TxEntry tx, {
  String? contactName,
  String? ownServer,
}) {
  final special = _specialTitle(l, tx);
  if (special != null) return special;
  final counterparty = tx.counterparty;
  return contactName ??
      (counterparty == null
          ? _directionNoun(l, tx)
          : shortAddress(counterparty, ownServer: ownServer));
}

/// The details title: the contact's name, else what kind of payment it is. The address is in
/// the "Sent to" / "Received from" row just below, in full.
String txHeading(AppLocalizations l, TxEntry tx, {String? contactName}) =>
    _specialTitle(l, tx) ?? contactName ?? _directionNoun(l, tx);

/// Titles that describe where a payment came from rather than who: mining and a chain scan.
String? _specialTitle(AppLocalizations l, TxEntry tx) {
  if (tx.kind == TxKind.coinbase) return l.txMiningReward;
  if (tx.source == TxSource.restored) return l.txRestoredFunds;
  return null;
}

String _directionNoun(AppLocalizations l, TxEntry tx) =>
    _outgoingKind(tx) ? l.txOutgoingPayment : l.txIncomingPayment;

/// A pending record that came only from a history backup: this wallet has nothing of its own
/// to say how it ended, so it is neither pending nor done.
bool isFromBackupUnknown(TxEntry tx) =>
    tx.source == TxSource.imported &&
    (tx.status == TxStatus.awaitingRecipient ||
        tx.status == TxStatus.awaitingConfirmation);

/// Not final yet: waiting for the other side or for the chain.
bool isPending(TxEntry tx) =>
    !isFromBackupUnknown(tx) &&
    (tx.status == TxStatus.awaitingRecipient ||
        tx.status == TxStatus.awaitingConfirmation);

/// Blocks on top of the one holding [tx], counting that block, or null when either height is
/// unknown.
int? txConfirmations(TxEntry tx, BigInt? tip) {
  final height = tx.blockHeight;
  if (height == null || tip == null) return null;
  final n = tip - height + BigInt.one;
  return n.isNegative ? 0 : n.toInt();
}

/// Confirmations after which the list calls a transaction completed.
final int confirmationsTarget = minimumConfirmations.toInt();

/// Where a transaction stands, in the words its status chip uses.
enum TxPhase {
  waitingRecipient,
  waitingSender,
  confirming,
  completed,
  cancelled,

  /// A pending record from a history backup that this wallet cannot follow up.
  fromBackup,
}

TxPhase txPhase(TxEntry tx, BigInt? tip) {
  if (isFromBackupUnknown(tx)) return TxPhase.fromBackup;
  final n = txConfirmations(tx, tip);
  return switch (tx.status) {
    TxStatus.cancelled => TxPhase.cancelled,
    TxStatus.awaitingRecipient => TxPhase.waitingRecipient,
    TxStatus.awaitingConfirmation
        when tx.blockHeight == null &&
            (tx.kind == TxKind.received ||
                tx.kind == TxKind.receivedCancelled) =>
      TxPhase.waitingSender,
    TxStatus.awaitingConfirmation => TxPhase.confirming,
    TxStatus.confirmed when n != null && n < confirmationsTarget =>
      TxPhase.confirming,
    TxStatus.confirmed => TxPhase.completed,
  };
}

/// `Waiting for recipient`, `Confirming 3/10`, `Completed`, …
String txStatusLabel(AppLocalizations l, TxEntry tx, BigInt? tip) =>
    switch (txPhase(tx, tip)) {
      TxPhase.waitingRecipient => l.txStatusWaitingRecipient,
      TxPhase.waitingSender => l.txStatusWaitingSender,
      TxPhase.confirming => l.txStatusConfirming(
        txConfirmations(tx, tip) ?? 0,
        confirmationsTarget,
      ),
      TxPhase.completed => l.txStatusCompleted,
      TxPhase.cancelled => l.txStatusCancelled,
      TxPhase.fromBackup => l.txStatusFromBackup,
    };

/// Pending transactions first, then the rest, each newest first.
List<TxEntry> pendingFirst(Iterable<TxEntry> txs) {
  int newest(TxEntry a, TxEntry b) => b.timeUnix.compareTo(a.timeUnix);
  return [
    ...txs.where(isPending).toList()..sort(newest),
    ...txs.where((t) => !isPending(t)).toList()..sort(newest),
  ];
}

/// The node's tip height, when known.
BigInt? tipHeight(WidgetRef ref) => ref.watch(nodeTipProvider).value?.height;

/// The host of the open wallet's epicbox server, for [shortAddress].
String? ownEpicboxServer(WidgetRef ref) =>
    ref.watch(walletConfigProvider.select((c) => c?.epicboxDomain));

/// The name saved for [address] in the address book, when there is one.
String? contactName(WidgetRef ref, String? address) {
  final contacts = ref.watch(contactsProvider).value;
  return contacts == null ? null : contactNameFor(contacts, address);
}

/// The small rounded label with a transaction's status.
class TxStatusChip extends StatelessWidget {
  const TxStatusChip({super.key, required this.tx, required this.tip});

  final TxEntry tx;
  final BigInt? tip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (txPhase(tx, tip)) {
      TxPhase.waitingRecipient || TxPhase.waitingSender => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      TxPhase.confirming => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      TxPhase.completed || TxPhase.fromBackup => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
      TxPhase.cancelled => (colors.errorContainer, colors.onErrorContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          txStatusLabel(context.l10n, tx, tip),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
        ),
      ),
    );
  }
}

/// A round icon with the direction of [tx].
class TxIcon extends StatelessWidget {
  const TxIcon({super.key, required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = context.l10n;
    final (IconData icon, Color bg, Color fg, String label) = switch (tx.kind) {
      _ when tx.status == TxStatus.cancelled => (
        Icons.block,
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
        l.txIconCancelled,
      ),
      TxKind.coinbase => (
        Icons.bolt,
        colors.primaryContainer,
        colors.onPrimaryContainer,
        l.txMiningReward,
      ),
      TxKind.received || TxKind.receivedCancelled => (
        Icons.south_west,
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        l.txIconIncoming,
      ),
      TxKind.sent || TxKind.sentCancelled => (
        Icons.north_east,
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        l.txIconOutgoing,
      ),
    };
    return CircleAvatar(
      backgroundColor: bg,
      foregroundColor: fg,
      child: Icon(icon, semanticLabel: label),
    );
  }
}

/// What a screen reader says for a payment row, as one sentence:
/// "Received 10 EPIC from Alice, completed, Today, 10:01".
/// [who] is the contact name or short address, [date] the row's date text.
String txSpokenLabel(
  AppLocalizations l,
  TxEntry tx, {
  required String? who,
  required String date,
  required String status,
  required bool hidden,
}) {
  final amount = hidden ? l.txSpokenHiddenAmount : epicText(l, txAmount(tx).amount);
  final out = _outgoingKind(tx);
  final String what;
  if (tx.kind == TxKind.coinbase) {
    what = l.txSpokenMiningReward(amount);
  } else if (tx.source == TxSource.restored) {
    what = l.txSpokenRestoredFunds(amount);
  } else {
    final cancelled = tx.status == TxStatus.cancelled;
    final pending = !cancelled && isPending(tx);
    what = switch ((out, who)) {
      (true, null) when cancelled => l.txSpokenCancelledSend(amount),
      (true, final w?) when cancelled => l.txSpokenCancelledSendTo(amount, w),
      (false, null) when cancelled => l.txSpokenCancelledReceive(amount),
      (false, final w?) when cancelled =>
        l.txSpokenCancelledReceiveFrom(amount, w),
      (true, null) when pending => l.txSpokenSending(amount),
      (true, final w?) when pending => l.txSpokenSendingTo(amount, w),
      (false, null) when pending => l.txSpokenReceiving(amount),
      (false, final w?) when pending => l.txSpokenReceivingFrom(amount, w),
      (true, null) => l.txSpokenSent(amount),
      (true, final w?) => l.txSpokenSentTo(amount, w),
      (false, null) => l.txSpokenReceived(amount),
      (false, final w?) => l.txSpokenReceivedFrom(amount, w),
    };
  }
  // English lower-cases the chip's word mid-sentence; other languages keep it, since German
  // nouns stay capitalised and Chinese has no case.
  final spokenStatus = l.localeName == 'en' ? status.toLowerCase() : status;
  return l.txSpokenRow(what, spokenStatus, date);
}

/// One transaction in a list. Tapping it opens its details, where cancel lives.
class TxTile extends ConsumerWidget {
  const TxTile({super.key, required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final display = amountDisplay(ref);
    final tip = tipHeight(ref);
    final now = ref.watch(clockProvider)();
    final (:amount, outgoing: _) = txAmount(tx);
    // A cancelled payment moved nothing, so it has no value to show.
    final fiat = tx.status == TxStatus.cancelled
        ? null
        : approxFiat(l, amount, display);
    final theme = Theme.of(context);
    final name = contactName(ref, tx.counterparty);
    final title = txTitle(
      l,
      tx,
      contactName: name,
      ownServer: ownEpicboxServer(ref),
    );
    final date = shortDate(l, localTime(tx.timeUnix), now);
    final signed = signedEpic(l, tx, hidden: display.hidden);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: tx.key)),
    );
    final counterparty = tx.counterparty;
    // One sentence for screen readers instead of the pieces (title, chip, date, amount, fiat),
    // so the status is said once and in order.
    return Semantics(
      key: ValueKey('tx-${tx.key}'),
      button: true,
      label: txSpokenLabel(
        l,
        tx,
        who:
            name ??
            (counterparty == null
                ? null
                : shortAddress(counterparty, ownServer: ownEpicboxServer(ref))),
        date: date,
        status: txStatusLabel(l, tx, tip),
        hidden: display.hidden,
      ),
      onTap: open,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TxIcon(tx: tx),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(date, style: muted),
                        TxStatusChip(tx: tx, tip: tip),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // At most 40 % of the row, so a long title keeps some room.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      signed,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: tx.status == TxStatus.cancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (fiat != null)
                      Text(
                        fiat,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An error sentence, announced to screen readers when it appears.
class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: color,
              semanticLabel: context.l10n.commonError,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: TextStyle(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A primary button that shows a spinner and ignores taps while [busy].
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

/// A password input with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _obscure
              ? context.l10n.passwordShow
              : context.l10n.passwordHide,
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// Slate JSON in a scrollable monospace box with a copy button.
class SlateBox extends StatelessWidget {
  const SlateBox({super.key, required this.title, required this.json});

  final String title;
  final String json;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                IconButton(
                  tooltip: context.l10n.slateCopyTooltip,
                  icon: const Icon(Icons.copy),
                  onPressed: () =>
                      copyText(context, json, context.l10n.slateCopied),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: SelectableText(
                  json,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
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

/// Multi-line field for pasting slate JSON.
class SlateInput extends StatelessWidget {
  const SlateInput({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 8,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.multiline,
      onChanged: onChanged,
      style: const TextStyle(fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: context.l10n.commonPaste,
          icon: const Icon(Icons.content_paste),
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            final text = data?.text;
            if (text == null) return;
            controller.text = text;
            onChanged?.call(text);
          },
        ),
      ),
    );
  }
}

/// Body padding and a width cap, so screens stay readable on tablets and desktop.
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: children,
          ),
        ),
      ),
    );
  }
}
