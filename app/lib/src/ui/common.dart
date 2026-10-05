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
import 'notices.dart';
import 'theme/brand.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';
import 'tx_details_screen.dart';

export 'notices.dart';

/// Replaces the whole navigation stack with the shell of the open wallet, on its Wallet tab.
void goHome(BuildContext context) {
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(shellTabProvider.notifier).go(ShellTab.wallet);
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    (_) => false,
  );
}

/// Shows [tab] of the wallet shell and closes every screen over it. With [recipient] (a
/// scanned code, Send again), the Send form takes it as the recipient.
void showShellTab(BuildContext context, ShellTab tab, {String? recipient}) {
  final container = ProviderScope.containerOf(context, listen: false);
  if (recipient != null) {
    container.read(sendRecipientProvider.notifier).hand(recipient);
  }
  container.read(shellTabProvider.notifier).go(tab);
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// Closes the wallet and returns to the unlock screen.
void lockWallet(BuildContext context, WidgetRef ref) {
  ref.read(sessionProvider.notifier).lock();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
    (_) => false,
  );
}

/// Copies [text] and confirms with a success notice [notice], a whole sentence such as
/// `l.addressCopied` (never a noun with "copied" glued on: other languages inflect it).
/// Never use this for the recovery phrase.
Future<void> copyText(BuildContext context, String text, String notice) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(noticeProvider.notifier).show(notice, level: NoticeLevel.success);
}

/// The height of the line under the app bar that [SlotScaffold.idle] draws in.
const double progressSlotHeight = 2;

/// A 2 dp line under the app bar for a screen's own status, such as [SlotProgress]. It
/// reserves no more, so nothing moves when work starts or ends. Notices dock under it
/// ([NoticeDock]).
class ProgressSlot extends StatelessWidget {
  const ProgressSlot({super.key, this.idle});

  final Widget? idle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: progressSlotHeight,
      child: ClipRect(child: idle ?? const SizedBox.shrink()),
    );
  }
}

/// A thin progress bar under the app bar, for [SlotScaffold.idle]: work that runs while the
/// screen stays usable. Indeterminate when [value] is null.
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

/// A [Scaffold] with a [ProgressSlot] under the app bar and the [NoticeDock] under that. With
/// [centered], [body] sits in the middle of the space left (and scrolls when it does not fit);
/// otherwise it starts right below the dock, which moves it down while a notice shows. [idle]
/// is what the slot shows, such as a [SlotProgress]. With [glow], the screen gets the lit
/// Protocol backdrop, its light at that point.
class SlotScaffold extends StatelessWidget {
  const SlotScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.centered = false,
    this.idle,
    this.glow,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool centered;
  final Widget? idle;
  final Alignment? glow;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProgressSlot(idle: idle),
          const NoticeDock(),
          Expanded(child: centered ? CenteredScroll(child: body) : body),
        ],
      ),
    );
    final glow = this.glow;
    return glow == null
        ? scaffold
        : ProtocolBackdrop(focus: glow, child: scaffold);
  }
}

/// [child] in the middle of the space it gets, scrolling when it does not fit. For a short
/// body such as [CenteredBody], in a scaffold or a tab.
class CenteredScroll extends StatelessWidget {
  const CenteredScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// `1,234.5 EPIC`, with [l]'s separators (`1.234,5 EPIC` in German), by the app's display
/// rule ([displayEpic]): large amounts lose decimals, cut off, never rounded up. For balances,
/// lists and notices. Display only; see [localDigits].
String epicText(AppLocalizations l, BigInt atomic) =>
    '${localDigits(l, displayEpic(atomic))} EPIC';

/// [epicText] with every decimal there is: `1,234,567.12345678 EPIC`. For the places that hold
/// the full value one tap from a balance or a row: the balance help, transaction details, the
/// Send form's fee and total, the review and its result, payment files and invoice reviews.
String epicExact(AppLocalizations l, BigInt atomic) =>
    '${localDigits(l, formatEpic(atomic, grouped: true))} EPIC';

/// What an amount shows while balances are hidden.
const String hiddenAmount = '•••••';

/// [epicText], or [epicExact] with [exact], or [hiddenAmount] when [hidden].
String shownEpic(
  AppLocalizations l,
  BigInt atomic, {
  required bool hidden,
  bool exact = false,
}) => hidden
    ? hiddenAmount
    : exact
    ? epicExact(l, atomic)
    : epicText(l, atomic);

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

/// `+5 EPIC`, `-1 EPIC`, or [hiddenAmount]; by the display rule, or with every decimal when
/// [exact].
String signedEpic(
  AppLocalizations l,
  TxEntry tx, {
  required bool hidden,
  bool exact = false,
}) {
  if (hidden) return hiddenAmount;
  final (:amount, :outgoing) = txAmount(tx);
  final text = shownEpic(l, amount, hidden: false, exact: exact);
  return '${outgoing ? '-' : '+'}$text';
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

String _directionNoun(AppLocalizations l, TxEntry tx) => _outgoingKind(tx)
    ? l.txOutgoingPayment
    : tx.isRequest
    ? l.txPaymentRequest
    : l.txIncomingPayment;

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

  /// A request this wallet sent that the payer has not paid ([TxEntry.awaitingPayer]).
  waitingPayer,
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
    TxStatus.awaitingConfirmation when tx.awaitingPayer => TxPhase.waitingPayer,
    // A paid request has arrived: it waits only for the chain.
    TxStatus.awaitingConfirmation when tx.isRequest => TxPhase.confirming,
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
      TxPhase.waitingPayer => l.txStatusWaitingPayer,
      TxPhase.confirming => l.txStatusConfirming(
        txConfirmations(tx, tip) ?? 0,
        confirmationsTarget,
      ),
      TxPhase.completed => l.txStatusCompleted,
      TxPhase.cancelled => l.txStatusCancelled,
      TxPhase.fromBackup => l.txStatusFromBackup,
    };

/// A payment's progress for [StatusTimeline], or null where a timeline would add nothing to
/// the status text: cancelled payments, backup records, mining rewards, restored or imported
/// rows. The current step names what the wallet waits for ("Waiting for recipient").
List<TimelineStep>? txTimeline(AppLocalizations l, TxEntry tx, BigInt? tip) {
  if (tx.source != TxSource.wallet || tx.kind == TxKind.coinbase) return null;
  final phase = txPhase(tx, tip);
  final confirming = l.txStatusConfirming(
    txConfirmations(tx, tip) ?? 0,
    confirmationsTarget,
  );
  // Each step: label once done, label while current, label before it is reached.
  final List<(String, String, String)> steps;
  final int? at;
  if (_outgoingKind(tx)) {
    steps = [
      (l.txStepStarted, l.txStepStarted, l.txStepStarted),
      (l.txStepAccepted, l.txStatusWaitingRecipient, l.txStepAccepted),
      (l.txStepPosted, l.txStepPosted, l.txStepPosted),
      (l.txStepConfirmed, confirming, l.txStepConfirming),
      (l.txStatusCompleted, l.txStatusCompleted, l.txStatusCompleted),
    ];
    at = switch (phase) {
      TxPhase.waitingRecipient => 1,
      TxPhase.confirming => 3,
      TxPhase.completed => steps.length,
      _ => null,
    };
  } else if (tx.isRequest) {
    // Nothing arrives before the payer pays.
    steps = [
      (l.txStepRequested, l.txStepRequested, l.txStepRequested),
      (l.txStepPaid, l.txStatusWaitingPayer, l.txStepPaid),
      (l.txStepConfirmed, confirming, l.txStepConfirming),
      (l.txStatusCompleted, l.txStatusCompleted, l.txStatusCompleted),
    ];
    at = switch (phase) {
      TxPhase.waitingPayer => 1,
      TxPhase.confirming => 2,
      TxPhase.completed => steps.length,
      _ => null,
    };
  } else {
    steps = [
      (l.txStepArrived, l.txStepArrived, l.txStepArrived),
      (l.txStepSenderFinished, l.txStatusWaitingSender, l.txStepSenderFinished),
      (l.txStepConfirmed, confirming, l.txStepConfirming),
      (l.txStatusCompleted, l.txStatusCompleted, l.txStatusCompleted),
    ];
    at = switch (phase) {
      TxPhase.waitingSender => 1,
      TxPhase.confirming => 2,
      TxPhase.completed => steps.length,
      _ => null,
    };
  }
  if (at == null) return null;
  return [
    for (final (i, (done, now, todo)) in steps.indexed)
      i < at
          ? TimelineStep(done, TimelineState.done)
          : i == at
          ? TimelineStep(now, TimelineState.current)
          : TimelineStep(todo, TimelineState.todo),
  ];
}

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
      TxPhase.waitingRecipient ||
      TxPhase.waitingSender ||
      TxPhase.waitingPayer => (
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

/// The direction of [tx] in a hairline square: green in, plain out, gold for a reward.
class TxIcon extends StatelessWidget {
  const TxIcon({super.key, required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final (IconData icon, Color fg, String label) = switch (tx.kind) {
      _ when tx.status == TxStatus.cancelled => (
        Icons.block,
        t.dim,
        l.txIconCancelled,
      ),
      TxKind.coinbase => (Icons.bolt, t.accentText, l.txMiningReward),
      TxKind.received ||
      TxKind.receivedCancelled => (Icons.south_west, t.ok, l.txIconIncoming),
      TxKind.sent ||
      TxKind.sentCancelled => (Icons.north_east, t.text, l.txIconOutgoing),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.radiusSmall),
        border: Border.all(color: t.lineStrong),
      ),
      child: Icon(icon, size: 20, color: fg, semanticLabel: label),
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
  final amount = hidden
      ? l.txSpokenHiddenAmount
      : epicText(l, txAmount(tx).amount);
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
      (false, final w?) when cancelled => l.txSpokenCancelledReceiveFrom(
        amount,
        w,
      ),
      (false, null) when tx.awaitingPayer => l.txSpokenRequesting(amount),
      (false, final w?) when tx.awaitingPayer => l.txSpokenRequestingFrom(
        amount,
        w,
      ),
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
                    // Amounts are data, so the mono face.
                    Text(
                      signed,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: context.tokens.monoFamily,
                        fontSize: 14.5,
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

/// Body padding and a width cap, so screens stay readable on tablets and desktop. [bottom] is
/// the screen's main action, held at the foot of the screen (above the keyboard when it is
/// open) instead of wherever the form happens to end.
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children, this.bottom});

  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final bottom = this.bottom;
    final list = ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: bottom == null
              ? list
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: list),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: context.tokens.line),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: bottom,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
