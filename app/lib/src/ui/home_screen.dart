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
import 'settings_history.dart' show exportHistoryBackup;
import 'settings_screen.dart';
import 'slate_file_screen.dart';
import 'tx_details_screen.dart';

/// How often home refreshes against the node while it is on screen and the app is in front.
const Duration autoRefreshInterval = Duration(seconds: 60);

/// Transactions shown under "Recent activity".
const int recentActivityCount = 5;

/// How long a dismissed history backup reminder stays away.
const Duration historyReminderPause = Duration(days: 7);

/// How many payments a history backup would keep that the last export does not have, or null
/// when the reminder should stay hidden: nothing to keep, or it was dismissed less than
/// [historyReminderPause] ago.
///
/// A payment counts once, when it is newer than the export ([exportedAt], Unix seconds), was
/// pending in the export and has settled since, or has a different note than in the export
/// ([snapshot]). Restored and imported rows are left out: a restore or an import brings them
/// back anyway.
int? paymentsNotInBackup(
  Iterable<TxEntry> txs, {
  required DateTime now,
  int? exportedAt,
  int? dismissedAt,
  HistoryExportSnapshot? snapshot,
}) {
  if (dismissedAt != null &&
      now.difference(localTime(dismissedAt)) < historyReminderPause) {
    return null;
  }
  bool changed(TxEntry t) {
    if (exportedAt == null || t.timeUnix > exportedAt) return true;
    if (snapshot == null) return false;
    final settled =
        snapshot.pendingKeys.contains(t.key) &&
        (t.status == TxStatus.confirmed || t.status == TxStatus.cancelled);
    return settled ||
        snapshot.noteHashes[t.key] != HistoryExportSnapshot.noteHash(t.note);
  }

  final n = txs.where((t) => t.source == TxSource.wallet && changed(t)).length;
  return n == 0 ? null : n;
}

/// The notice for a push that arrives while the app is open but not connected to epicbox.
const String pushNotice =
    'A payment is waiting in your epicbox. It arrives once the app is connected.';

/// The notice for a listener event: what happened to which payment, never the raw message.
/// [tx] is the transaction with the event's slate id, when the list has it.
String paymentNotice(
  ListenerEvent event,
  TxEntry? tx, {
  String? contactName,
  bool hidden = false,
  String? ownServer,
}) {
  final counterparty = tx?.counterparty;
  final who =
      contactName ??
      (counterparty == null
          ? null
          : shortAddress(counterparty, ownServer: ownServer));
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
      // Finished and posted, not yet confirmed: "Completed" is kept for 10 confirmations.
      const wait = 'Waiting for confirmations.';
      return who == null
          ? 'Payment finished. $wait'
          : 'Payment to $who finished. $wait';
    case ListenerEventKind.expired:
      // The core says whether the funds are unlocked yet or unlock at the next refresh.
      return event.message;
    case ListenerEventKind.delayed:
      // Shown once per payment by home; the core retries and the payment is unchanged.
      return 'Could not reach the node. The payment will finish once it can.';
    case ListenerEventKind.error:
      return event.slateId == null
          ? 'The epicbox server reported a problem. Retrying.'
          : 'A payment could not be completed.';
    case ListenerEventKind.connected ||
        ListenerEventKind.disconnected ||
        ListenerEventKind.stopped:
      return event.message;
  }
}

/// Whether home's figures are on screen while a refresh against the node runs: the background
/// refresh after a local first load, or a reload in place.
bool _syncing(AsyncValue<HomeData> home) {
  final data = home.value;
  return data != null && (home.isLoading || data.syncing);
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

  /// Payments whose "could not reach the node" notice was already shown.
  final Set<String> _delayedShown = {};

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _timer = Timer.periodic(autoRefreshInterval, (_) => _autoRefresh());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateProvider.notifier).checkOnStart();
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
    if (_syncing(ref.read(homeProvider)) || ref.read(scanProvider).running) {
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
    if (done == true && mounted) _showMessage('Recovery phrase backed up');
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
    if (event.kind == ListenerEventKind.delayed) {
      // Once per payment for as long as home is open, however often the answer is retried.
      if (slateId != null && !_delayedShown.add(slateId)) return;
    }
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
      ownServer: ref.read(walletConfigProvider)?.epicboxDomain,
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
        // A notice with "View" would otherwise stay until tapped and hold back the next one;
        // the payment is always one tap away in the list.
        persist: false,
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
    // A push only says a payment is waiting in epicbox. While connected, the listener
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
    final syncing = _syncing(home);
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    final backupDismissed =
        ref.watch(backupCardDismissedProvider).value ?? false;
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
            onPressed: syncing || scan.running ? null : _refresh,
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
                  if (scan.running || scan.error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ScanProgressView(scan: scan),
                      ),
                    ),
                  const _UpdateCard(),
                  // The recovery phrase guards the funds, so its card stays on top.
                  if (!backedUp && !backupDismissed && config != null)
                    _BackupCard(
                      onBackup: _backup,
                      onDismiss: () => dismissBackupCard(ref, config.chain),
                    ),
                  if (home.hasError && !home.isLoading)
                    ErrorText(describeError(home.error!)),
                  if (data != null) BalanceHeader(summary: data.summary),
                  _SyncLine(summary: data?.summary, syncing: syncing),
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
                  // Below the actions, so the balance stays at the top. It waits until the
                  // phrase card is gone, so the two backup cards never stack.
                  if ((backedUp || backupDismissed) && config != null)
                    _HistoryBackupCard(
                      chain: config.chain,
                      transactions: transactions,
                    ),
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

/// Reminds the user to export a history backup, which a restore from the phrase cannot replace.
class _HistoryBackupCard extends ConsumerWidget {
  const _HistoryBackupCard({required this.chain, required this.transactions});

  final Chain chain;
  final List<TxEntry> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();
    final exportedAt = settings.historyExportedAt[chain.name];
    final count = paymentsNotInBackup(
      transactions,
      now: now,
      exportedAt: exportedAt,
      dismissedAt: settings.historyReminderDismissedAt[chain.name],
      snapshot: settings.historyExportSnapshots[chain.name],
    );
    if (count == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    // Before any export nothing is in a backup; after one, some payments may only have changed.
    final text = exportedAt == null
        ? (count == 1
              ? '1 payment is not in a history backup.'
              : '$count payments are not in a history backup.')
        : (count == 1
              ? '1 payment is new or changed since your last history backup.'
              : '$count payments are new or changed since your last history '
                    'backup.');
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: colors.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$text A restore from your recovery phrase brings back only your '
                'balance.',
                style: TextStyle(color: colors.onSecondaryContainer),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ref
                        .read(appSettingsProvider.notifier)
                        .dismissHistoryReminder(chain, now),
                    child: const Text('Not now'),
                  ),
                  TextButton(
                    onPressed: () => exportHistoryBackup(context, ref),
                    child: const Text('Export history backup'),
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

/// Whether the recovery phrase card was closed on the open wallet. Stored beside the vault's
/// entries for the chain (`wallet.<chain>.*`), so deleting the wallet forgets it too.
final backupCardDismissedProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final config = ref.watch(walletConfigProvider);
  if (config == null) return false;
  return await ref
          .watch(secretStoreProvider)
          .read(_backupCardKey(config.chain)) ==
      '1';
});

String _backupCardKey(Chain chain) =>
    'wallet.${chain.name}.backupCardDismissed';

/// Hides the recovery phrase card on [chain]'s wallet for good.
Future<void> dismissBackupCard(WidgetRef ref, Chain chain) async {
  await ref.read(secretStoreProvider).write(_backupCardKey(chain), '1');
  ref.invalidate(backupCardDismissedProvider);
}

/// Asks the user to write the recovery phrase down, until they have or close it.
class _BackupCard extends StatelessWidget {
  const _BackupCard({required this.onBackup, required this.onDismiss});

  final VoidCallback onBackup;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            Icon(Icons.key_outlined, color: colors.primary),
            const SizedBox(width: 12),
            const Expanded(child: Text('Back up your recovery phrase.')),
            TextButton(onPressed: onBackup, child: const Text('Back up')),
            IconButton(
              tooltip: 'Dismiss',
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
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
                  container: true,
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
            Semantics(
              button: true,
              expanded: _expanded,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _expanded = !_expanded),
                child: ConstrainedBox(
                  // A full-size tap target, however short the text.
                  constraints: const BoxConstraints(minHeight: 48),
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

/// Whether the balance is current: syncing, up to date, not validated, or node unreachable, and
/// whether epicbox is connected. A thin bar under it moves while the wallet syncs.
class _SyncLine extends ConsumerWidget {
  const _SyncLine({required this.summary, required this.syncing});

  final WalletSummary? summary;
  final bool syncing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tip = ref.watch(nodeTipProvider);
    final listening = ref.watch(listenerProvider.select((s) => s.connected));
    final lost = ref.watch(listenerProvider.select((s) => s.lost));
    final percent = syncing ? ref.watch(syncProgressProvider) : null;
    final summary = this.summary;
    String? height;
    final (IconData icon, String text, bool problem) = switch (tip) {
      _ when syncing => (
        Icons.sync,
        percent == null ? 'Syncing…' : 'Syncing… $percent%',
        false,
      ),
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
      AsyncData() => (Icons.check_circle_outline, 'Up to date.', false),
      _ => (Icons.sync, 'Contacting node…', false),
    };
    if (tip case AsyncData(:final value)) {
      final synced =
          summary != null && summary.lastConfirmedHeight > BigInt.zero
          ? summary.lastConfirmedHeight
          : value.height;
      height = 'Synced at block ${groupDigits(synced)}';
    }
    final color = problem
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    final relay = listening
        ? null
        : lost
        ? 'Epicbox offline, reconnecting.'
        : 'Connecting to epicbox…';
    final line = Semantics(
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
                relay == null ? text : '$text $relay',
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The block height means little to most people; it stays one long-press away.
        if (height == null || syncing)
          line
        else
          Tooltip(message: height, child: line),
        // A fixed slot, so the bar coming and going does not shift the list.
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: SizedBox(
            height: 2,
            child: syncing
                ? LinearProgressIndicator(
                    value: percent == null ? null : percent / 100,
                    semanticsLabel: 'Syncing',
                  )
                : null,
          ),
        ),
      ],
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
                one
                    ? '${shownEpic(total, hidden: hidden)} is waiting for the '
                          'recipient\'s wallet to answer. Until then the funds '
                          'stay locked. If it never answers, open the payment and '
                          'tap Cancel payment.'
                    : '${shownEpic(total, hidden: hidden)} is waiting for the '
                          'recipients\' wallets to answer. Until then the funds '
                          'stay locked. If one never answers, open the payment '
                          'and tap Cancel payment.',
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
              'No payments yet.',
              style: theme.textTheme.titleMedium,
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
