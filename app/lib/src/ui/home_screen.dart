import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart' show contactNameFor, contactsProvider;
import '../errors.dart';
import '../network.dart';
import '../providers.dart';
import '../push.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../updater.dart';
import '../wallet_service.dart';
import 'backup_screen.dart';
import 'common.dart';
import 'help_screen.dart';
import 'history_screen.dart';
import 'receive_screen.dart';
import 'restore_screen.dart' show ScanProgressView;
import 'scan_screen.dart' show qrScannerProvider;
import 'send_screen.dart';
import 'settings_screen.dart';
import 'slate_file_screen.dart';
import 'tx_details_screen.dart';

/// How often home refreshes against the node while it is on screen and the app is in front.
const Duration autoRefreshInterval = Duration(seconds: 60);

/// Transactions shown under "Recent activity".
const int recentActivityCount = 5;

/// The notice for a push that arrives while the app is open but not connected to the mailbox.
const String pushNotice =
    'A payment is waiting in your mailbox. It arrives once the app is connected.';

/// The notice for a listener event: what happened to which payment, never the raw message.
/// [tx] is the transaction with the event's slate id, when the list has it.
String paymentNotice(
  ListenerEvent event,
  TxEntry? tx, {
  String? contactName,
  bool hidden = false,
}) {
  final counterparty = tx?.counterparty;
  final who =
      contactName ?? (counterparty == null ? null : shortAddress(counterparty));
  switch (event.kind) {
    case ListenerEventKind.received:
      // The listener only accepted it; the sender still has to finish it.
      final amount = event.amount ?? (tx == null ? null : txAmount(tx).amount);
      final from = contactName == null ? '' : ' from $contactName';
      const rest = 'It completes when the sender finishes.';
      return amount == null || hidden
          ? 'A payment$from is on the way. $rest'
          : '${epicText(amount)}$from on the way. $rest';
    case ListenerEventKind.finalized:
      return who == null ? 'Payment completed' : 'Payment to $who completed';
    case ListenerEventKind.error:
      return event.slateId == null
          ? 'The mailbox server reported a problem. Retrying.'
          : 'A payment could not be completed.';
    case ListenerEventKind.connected ||
        ListenerEventKind.disconnected ||
        ListenerEventKind.stopped:
      return event.message;
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: _autoRefresh,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _timer = Timer.periodic(autoRefreshInterval, (_) => _autoRefresh());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateProvider.notifier).checkOnStart();
      ref.read(pushProvider.notifier).start();
      _openIncoming();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refresh() async {
    ref.invalidate(nodeTipProvider);
    try {
      await ref.read(homeProvider.notifier).reload();
    } catch (_) {
      // The error line shows it.
    }
  }

  /// Refreshes unless another screen covers home, the app is in the background, or a refresh
  /// or scan is already running.
  void _autoRefresh() {
    if (!mounted) return;
    final life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    if (ref.read(homeProvider).isLoading || ref.read(scanProvider).running) {
      return;
    }
    _refresh();
  }

  /// Opens a transaction file another app handed over, once a wallet is open to handle it.
  void _openIncoming() {
    final file = ref.read(incomingSlateProvider.notifier).take();
    if (file == null || !mounted) return;
    _open(SlateFileScreen(file: file));
  }

  Future<void> _backup() async {
    final done = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const BackupScreen()));
    if (done == true && mounted) _showMessage('Recovery phrase confirmed');
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _refresh();
  }

  /// Scans a QR code and opens Send with it as the recipient.
  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scan(context);
    if (text == null || !mounted) return;
    await _open(SendScreen(recipient: text));
  }

  /// Tells the user what the listener just did, in words, with a way to the transaction.
  Future<void> _notify(ListenerEvent event) async {
    TxEntry? tx;
    final slateId = event.slateId;
    if (slateId != null) {
      // The listener refreshes home right after this event; wait for that list.
      await Future<void>.delayed(Duration.zero);
      try {
        final data = await ref.read(homeProvider.future);
        tx = data.transactions.where((t) => t.slateId == slateId).firstOrNull;
      } catch (_) {
        // Word it without the transaction.
      }
    }
    if (!mounted) return;
    final contacts = ref.read(contactsProvider).value ?? const <Contact>[];
    final text = paymentNotice(
      event,
      tx,
      contactName: contactNameFor(contacts, tx?.counterparty),
      hidden: ref.read(appSettingsProvider).value?.hideBalances ?? false,
    );
    final key = tx?.key;
    _showNotice(text, txKey: key);
  }

  /// A payment notice: a few seconds long, with a way to the payment when it is known.
  void _showNotice(String text, {String? txKey}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 6),
        action: txKey == null
            ? null
            : SnackBarAction(
                label: 'View',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TxDetailsScreen(txKey: txKey),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A push only says a payment is waiting in the mailbox. While connected, the listener
    // collects it and gives the notice, so one payment gets one notice.
    ref.listen(pushProvider.select((s) => s.last), (_, message) {
      if (message == null || ref.read(listenerProvider).connected) return;
      _showNotice(pushNotice);
    });
    ref.listen(incomingSlateProvider, (_, file) {
      if (file != null) _openIncoming();
    });
    ref.listen(listenerProvider.select((s) => s.last), (_, event) {
      if (event != null) _notify(event);
    });
    final config = ref.watch(walletConfigProvider);
    final home = ref.watch(homeProvider);
    final scan = ref.watch(scanProvider);
    final data = home.value;
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    final title = config == null ? 'Wallet' : chainLabel(config.chain);
    final transactions = data?.transactions ?? const <TxEntry>[];
    final scanner = ref.watch(qrScannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Epic Cash · $title'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: home.isLoading || scan.running ? null : _refresh,
          ),
          IconButton(
            tooltip: 'Lock wallet',
            icon: const Icon(Icons.lock_outline),
            onPressed: () => lockWallet(context, ref),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _open(const SettingsScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // A fixed slot, so the minute refresh does not shift the list.
                  SizedBox(
                    height: 4,
                    child: home.isLoading
                        ? const LinearProgressIndicator(
                            semanticsLabel: 'Refreshing',
                          )
                        : null,
                  ),
                  if (scan.running || scan.error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ScanProgressView(scan: scan),
                      ),
                    ),
                  const _UpdateCard(),
                  if (!backedUp) _BackupCard(onBackup: _backup),
                  if (home.hasError && !home.isLoading)
                    ErrorText(describeError(home.error!)),
                  if (data != null) BalanceHeader(summary: data.summary),
                  _SyncLine(summary: data?.summary),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.north_east),
                          label: const Text('Send'),
                          onPressed: () => _open(const SendScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.south_west),
                          label: const Text('Receive'),
                          onPressed: () => _open(const ReceiveScreen()),
                        ),
                      ),
                      if (scanner.supported) ...[
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          tooltip: 'Scan a QR code to send',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: _scan,
                        ),
                      ],
                    ],
                  ),
                  _PendingSendsCard(transactions: transactions, open: _open),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Recent activity',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      if (transactions.isNotEmpty)
                        TextButton(
                          onPressed: () => _open(const HistoryScreen()),
                          child: const Text('See all'),
                        ),
                    ],
                  ),
                  if (data != null && transactions.isEmpty)
                    _EmptyActivity(
                      onReceive: () => _open(const ReceiveScreen()),
                    ),
                  for (final tx in pendingFirst(
                    transactions,
                  ).take(recentActivityCount))
                    TxTile(tx: tx),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Update availability, download progress and install errors. Hidden when there is nothing
/// to say.
class _UpdateCard extends ConsumerWidget {
  const _UpdateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    final notifier = ref.read(updateProvider.notifier);
    final update = state.update;
    final version = update == null ? '' : ' ${update.versionName}';
    final (String text, Widget? action) = switch (state.phase) {
      UpdatePhase.idle => ('', null),
      UpdatePhase.checking => ('Checking for updates…', null),
      UpdatePhase.upToDate => ('This is the latest version.', null),
      UpdatePhase.available => (
        state.message ?? 'Version$version is available.',
        FilledButton.tonal(
          onPressed: notifier.install,
          child: const Text('Update'),
        ),
      ),
      UpdatePhase.downloading => (
        'Downloading version$version… '
            '${((state.progress ?? 0) * 100).floor()}%',
        null,
      ),
      UpdatePhase.installing => ('Installing version$version…', null),
      UpdatePhase.failed => (
        state.message ?? 'The update failed.',
        TextButton(
          onPressed: update == null ? notifier.check : notifier.install,
          child: const Text('Try again'),
        ),
      ),
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update, semanticLabel: 'Update'),
                const SizedBox(width: 12),
                Expanded(child: Semantics(liveRegion: true, child: Text(text))),
                ?action,
              ],
            ),
            if (state.phase == UpdatePhase.downloading)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: LinearProgressIndicator(
                  value: state.progress,
                  semanticsLabel: 'Download progress',
                ),
              ),
            if (update != null &&
                update.notes.isNotEmpty &&
                state.phase == UpdatePhase.available)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Text(
                  update.notes,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Asks the user to write the recovery phrase down, until they have.
class _BackupCard extends StatelessWidget {
  const _BackupCard({required this.onBackup});

  final VoidCallback onBackup;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Back up your wallet',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: colors.onTertiaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              'Write down your recovery phrase. It is the only way to get your '
              'funds back if you lose this device or forget your PIN.',
              style: TextStyle(color: colors.onTertiaryContainer),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onBackup,
                child: const Text('Back up now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The spendable balance, large, with its fiat value, an eye toggle that hides amounts, and a
/// line for money that is not spendable yet which opens the breakdown.
class BalanceHeader extends ConsumerStatefulWidget {
  const BalanceHeader({super.key, required this.summary});

  final WalletSummary summary;

  @override
  ConsumerState<BalanceHeader> createState() => _BalanceHeaderState();
}

class _BalanceHeaderState extends ConsumerState<BalanceHeader> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.summary;
    final display = amountDisplay(ref);
    final hidden = display.hidden;
    final fiat = approxFiat(summary.spendable, display);
    final buckets = [
      ('Confirming', summary.awaitingConfirmation),
      ('Waiting to finish', summary.awaitingFinalization),
      ('Locked by a payment in progress', summary.locked),
      ('Mining rewards not spendable yet', summary.immature),
    ].where((b) => b.$2 > BigInt.zero).toList();
    final notSpendable = summary.total - summary.spendable;
    final summaryLine = notSpendable > BigInt.zero
        ? '${shownEpic(notSpendable, hidden: hidden)} not spendable yet'
        : '${shownEpic(summary.awaitingFinalization, hidden: hidden)} '
              'waiting to finish';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spendable', style: theme.textTheme.labelLarge),
          Row(
            children: [
              Flexible(
                child: Semantics(
                  label: hidden ? 'Balance hidden' : null,
                  excludeSemantics: hidden,
                  child: Text(
                    shownEpic(summary.spendable, hidden: hidden),
                    style: theme.textTheme.displaySmall,
                  ),
                ),
              ),
              IconButton(
                tooltip: hidden ? 'Show balances' : 'Hide balances',
                icon: Icon(
                  hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => ref
                    .read(appSettingsProvider.notifier)
                    .setHideBalances(!hidden),
              ),
            ],
          ),
          if (fiat != null)
            Text(
              fiat,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (buckets.isNotEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(summaryLine)),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      semanticLabel: _expanded
                          ? 'Hide breakdown'
                          : 'Show breakdown',
                    ),
                  ],
                ),
              ),
            ),
          if (_expanded)
            for (final (label, value) in buckets)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    Text(shownEpic(value, hidden: hidden)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Whether the balance is current: synced at a height, not validated, or node unreachable, and
/// whether payments can arrive.
class _SyncLine extends ConsumerWidget {
  const _SyncLine({required this.summary});

  final WalletSummary? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tip = ref.watch(nodeTipProvider);
    final listening = ref.watch(listenerProvider.select((s) => s.connected));
    final lost = ref.watch(listenerProvider.select((s) => s.lost));
    final summary = this.summary;
    final (IconData icon, String text, bool problem) = switch (tip) {
      AsyncError() => (
        Icons.cloud_off,
        'Node unreachable. Balances may be out of date.',
        true,
      ),
      _ when summary != null && !summary.validatedWithNode => (
        Icons.sync_problem,
        'Not validated with node. Balances may be out of date.',
        true,
      ),
      AsyncData(:final value) => (
        Icons.check_circle_outline,
        'Synced at height ${groupDigits(summary != null && summary.lastConfirmedHeight > BigInt.zero ? summary.lastConfirmedHeight : value.height)}.',
        false,
      ),
      _ => (Icons.sync, 'Contacting node…', false),
    };
    final color = problem
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    final relay = listening
        ? 'Connected. Ready to receive payments.'
        : lost
        ? 'Mailbox offline, reconnecting.'
        : 'Connecting to the mailbox to receive payments…';
    return Semantics(
      liveRegion: problem,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$text $relay',
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sends the recipient has not answered yet, with what that means.
class _PendingSendsCard extends ConsumerWidget {
  const _PendingSendsCard({required this.transactions, required this.open});

  static final ButtonStyle _compact = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 8),
  );

  final List<TxEntry> transactions;
  final Future<void> Function(Widget screen) open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = transactions
        .where(
          (t) =>
              t.status == TxStatus.awaitingRecipient && !isFromBackupUnknown(t),
        )
        .toList();
    if (waiting.isEmpty) return const SizedBox.shrink();
    final hidden = amountDisplay(ref).hidden;
    final total = waiting.fold(
      BigInt.zero,
      (sum, t) => sum + txAmount(t).amount,
    );
    final colors = Theme.of(context).colorScheme;
    final one = waiting.length == 1;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: colors.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                one
                    ? 'A payment is waiting for the recipient'
                    : '${waiting.length} payments are waiting for their recipients',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: colors.onSecondaryContainer),
              ),
              const SizedBox(height: 4),
              Text(
                '${shownEpic(total, hidden: hidden)} is on its way. A payment '
                'completes when the recipient\'s wallet answers; until then the '
                'funds stay locked. To cancel, open the payment and tap Cancel '
                'payment.',
                style: TextStyle(color: colors.onSecondaryContainer),
              ),
              // One row on a phone; wraps only at large text.
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    style: _compact,
                    onPressed: () =>
                        openHelp(context, HelpTopic.waitingForRecipient),
                    child: const Text('Why is it waiting?'),
                  ),
                  TextButton(
                    style: _compact,
                    onPressed: () => open(
                      one
                          ? TxDetailsScreen(txKey: waiting.single.key)
                          : const HistoryScreen(filter: HistoryFilter.pending),
                    ),
                    child: Text(one ? 'View payment' : 'View payments'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a brand-new wallet shows instead of an empty list: how money gets in.
class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.onReceive});

  final VoidCallback onReceive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Your wallet is ready',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'To get EPIC, show your address or QR code to the sender. '
              'Payments arrive while this app is open.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.qr_code),
              label: const Text('Show my address'),
              onPressed: onReceive,
            ),
          ],
        ),
      ),
    );
  }
}
