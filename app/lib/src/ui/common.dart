import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../contacts.dart' show contactNameFor, contactsProvider;
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

/// Copies [text] and confirms with a snack bar. Never use this for the recovery phrase.
Future<void> copyText(BuildContext context, String text, String what) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$what copied')));
}

/// `1.5 EPIC`.
String epicText(BigInt atomic) => '${formatEpic(atomic)} EPIC';

/// What an amount shows while balances are hidden.
const String hiddenAmount = '•••••';

/// [epicText], or [hiddenAmount] when [hidden].
String shownEpic(BigInt atomic, {required bool hidden}) =>
    hidden ? hiddenAmount : epicText(atomic);

/// `2,500,000`.
String groupDigits(Object number) {
  final text = number.toString();
  final negative = text.startsWith('-');
  final digits = negative ? text.substring(1) : text;
  final out = StringBuffer(negative ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

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
  BigInt atomic,
  ({bool hidden, double? price, String currency}) display,
) {
  final price = display.price;
  if (price == null || display.hidden) return null;
  return '≈ ${fiatText(atomic, price, display.currency)}';
}

// Dates.

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _two(int v) => v.toString().padLeft(2, '0');

DateTime localTime(int unixSeconds) =>
    DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);

/// Local `yyyy-MM-dd HH:mm`.
String formatTimestamp(int unixSeconds) {
  final t = localTime(unixSeconds);
  return '${t.year}-${_two(t.month)}-${_two(t.day)} ${_two(t.hour)}:${_two(t.minute)}';
}

/// `21 Sep 2026, 14:05`.
String formatDateTime(DateTime t) =>
    '${t.day} ${_months[t.month - 1]} ${t.year}, ${_two(t.hour)}:${_two(t.minute)}';

/// Whole days from [t]'s local date to [now]'s: 0 for today, 1 for yesterday.
int daysAgo(DateTime t, DateTime now) => DateTime(
  now.year,
  now.month,
  now.day,
).difference(DateTime(t.year, t.month, t.day)).inDays;

/// A day heading: `Today`, `Yesterday`, else `21 Sep 2026`.
String dayLabel(DateTime t, DateTime now) => switch (daysAgo(t, now)) {
  0 => 'Today',
  1 => 'Yesterday',
  _ => '${t.day} ${_months[t.month - 1]} ${t.year}',
};

/// A short time for a list row: `Today, 14:05`, `Yesterday, 14:05`, `21 Sep, 14:05`, and the
/// year added for other years.
String shortDate(DateTime t, DateTime now) {
  final time = '${_two(t.hour)}:${_two(t.minute)}';
  return switch (daysAgo(t, now)) {
    0 => 'Today, $time',
    1 => 'Yesterday, $time',
    _ when t.year == now.year => '${t.day} ${_months[t.month - 1]}, $time',
    _ => '${t.day} ${_months[t.month - 1]} ${t.year}',
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
String signedEpic(TxEntry tx, {required bool hidden}) {
  if (hidden) return hiddenAmount;
  final (:amount, :outgoing) = txAmount(tx);
  return '${outgoing ? '-' : '+'}${epicText(amount)}';
}

String txKindLabel(TxKind kind) => switch (kind) {
  TxKind.coinbase => 'Mining reward',
  TxKind.received || TxKind.receivedCancelled => 'Received',
  TxKind.sent || TxKind.sentCancelled => 'Sent',
};

/// The row title: a mining reward, restored funds, the contact's name, else the direction.
String txTitle(TxEntry tx, {String? contactName}) {
  if (tx.kind == TxKind.coinbase) return 'Mining reward';
  if (tx.source == TxSource.restored) return 'Restored funds';
  return contactName ?? txKindLabel(tx.kind);
}

/// Not final yet: waiting for the other side or for the chain.
bool isPending(TxEntry tx) =>
    tx.status == TxStatus.awaitingRecipient ||
    tx.status == TxStatus.awaitingConfirmation;

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
}

TxPhase txPhase(TxEntry tx, BigInt? tip) {
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
String txStatusLabel(TxEntry tx, BigInt? tip) => switch (txPhase(tx, tip)) {
  TxPhase.waitingRecipient => 'Waiting for recipient',
  TxPhase.waitingSender => 'Waiting for sender',
  TxPhase.confirming =>
    'Confirming ${txConfirmations(tx, tip) ?? 0}/$confirmationsTarget',
  TxPhase.completed => 'Completed',
  TxPhase.cancelled => 'Cancelled',
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
      TxPhase.completed => (
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
          txStatusLabel(tx, tip),
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
    final (IconData icon, Color bg, Color fg) = switch (tx.kind) {
      _ when tx.status == TxStatus.cancelled => (
        Icons.block,
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
      TxKind.coinbase => (
        Icons.bolt,
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      TxKind.received || TxKind.receivedCancelled => (
        Icons.south_west,
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      TxKind.sent || TxKind.sentCancelled => (
        Icons.north_east,
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
    };
    return CircleAvatar(
      backgroundColor: bg,
      foregroundColor: fg,
      child: Icon(icon),
    );
  }
}

/// One transaction in a list. Tapping it opens its details, where cancel lives.
class TxTile extends ConsumerWidget {
  const TxTile({super.key, required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = amountDisplay(ref);
    final tip = tipHeight(ref);
    final now = ref.watch(clockProvider)();
    final (:amount, outgoing: _) = txAmount(tx);
    final fiat = approxFiat(amount, display);
    final theme = Theme.of(context);
    final title = txTitle(tx, contactName: contactName(ref, tx.counterparty));
    final date = shortDate(localTime(tx.timeUnix), now);
    final signed = signedEpic(tx, hidden: display.hidden);
    return ListTile(
      key: ValueKey('tx-${tx.key}'),
      contentPadding: EdgeInsets.zero,
      leading: TxIcon(tx: tx),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(date),
          TxStatusChip(tx: tx, tip: tip),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Semantics(
            label: display.hidden ? 'Amount hidden' : null,
            excludeSemantics: display.hidden,
            child: Text(
              signed,
              style: theme.textTheme.bodyLarge?.copyWith(
                decoration: tx.status == TxStatus.cancelled
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          if (fiat != null) Text(fiat, style: theme.textTheme.bodySmall),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: tx.key)),
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
            Icon(Icons.error_outline, color: color, semanticLabel: 'Error'),
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
          tooltip: _obscure ? 'Show password' : 'Hide password',
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
                  tooltip: 'Copy slate',
                  icon: const Icon(Icons.copy),
                  onPressed: () => copyText(context, json, 'Slate'),
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
          tooltip: 'Paste',
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
