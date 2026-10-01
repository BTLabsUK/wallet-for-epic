import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart' show contactNameFor, contactsProvider;
import '../errors.dart';
import '../l10n.dart';
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
import 'theme/advanced.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';
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

/// The notice for a listener event: what happened to which payment, never the raw message.
/// [tx] is the transaction with the event's slate id, when the list has it.
String paymentNotice(
  AppLocalizations l,
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
      final shown = hidden || amount == null ? null : epicText(l, amount);
      return switch ((shown, contactName)) {
        (null, null) => l.homeNoticeReceived,
        (null, final from?) => l.homeNoticeReceivedFrom(from),
        (final a?, null) => l.homeNoticeReceivedAmount(a),
        (final a?, final from?) => l.homeNoticeReceivedAmountFrom(a, from),
      };
    case ListenerEventKind.finalized:
      // Finished and posted, not yet confirmed: "Completed" is kept for 10 confirmations.
      return who == null ? l.homeNoticeFinished : l.homeNoticeFinishedTo(who);
    case ListenerEventKind.expired:
      // The core says whether the funds are unlocked yet or unlock at the next refresh, in
      // English; other languages get the sentence that claims neither.
      return l.localeName == 'en' ? event.message : l.errorPaymentExpired;
    case ListenerEventKind.delayed:
      // Shown once per payment by home; the core retries and the payment is unchanged.
      return l.homeNoticeDelayed;
    case ListenerEventKind.error:
      return event.slateId == null
          ? l.homeNoticeRelayProblem
          : l.homeNoticePaymentFailed;
    case ListenerEventKind.connected ||
        ListenerEventKind.disconnected ||
        ListenerEventKind.stopped:
      // Never a notice: these change the listener's state, not `ListenerState.last`.
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
    if (done == true && mounted) _showNotice(context.l10n.homeBackedUpNotice);
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
      context.l10n,
      event,
      tx,
      contactName: contactNameFor(contacts, tx?.counterparty),
      hidden: ref.read(appSettingsProvider).value?.hideBalances ?? false,
      ownServer: ref.read(walletConfigProvider)?.epicboxDomain,
    );
    final key = tx?.key;
    _showNotice(text, txKey: key);
  }

  /// A notice in the slot, with a way to the payment when it is known. It leaves on its own;
  /// the payment is always one tap away in the list too.
  void _showNotice(String text, {String? txKey}) {
    ref
        .read(noticeProvider.notifier)
        .show(
          text,
          action: txKey == null
              ? null
              : NoticeAction(
                  context.l10n.homeNoticeView,
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TxDetailsScreen(txKey: txKey),
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
      _showNotice(context.l10n.homePushNotice);
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
    final l = context.l10n;
    final data = home.value;
    final syncing = _syncing(home);
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    final backupDismissed =
        ref.watch(backupCardDismissedProvider).value ?? false;
    final title = config == null
        ? l.homeTitleNoNetwork
        : l.homeTitle(chainName(l, config.chain));
    final transactions = data?.transactions ?? const <TxEntry>[];
    final scanner = ref.watch(qrScannerProvider);

    return SlotScaffold(
      idle: const _HomeStatus(),
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: l.homeRefreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: syncing || scan.running ? null : _refresh,
          ),
          IconButton(
            tooltip: l.homeLockTooltip,
            icon: const Icon(Icons.lock_outline),
            onPressed: () => lockWallet(context, ref),
          ),
          IconButton(
            tooltip: l.homeSettingsTooltip,
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
                  // The recovery phrase guards the funds, so its card stays on top.
                  if (!backedUp && !backupDismissed && config != null)
                    _BackupCard(
                      onBackup: _backup,
                      onDismiss: () => dismissBackupCard(ref, config.chain),
                    ),
                  if (home.hasError && !home.isLoading)
                    ErrorText(describeError(l, home.error!)),
                  if (data != null)
                    ProtocolBalancePanel(
                      syncProgress: syncing
                          ? (ref.watch(syncProgressProvider) ?? 0) / 100
                          : 1,
                      footer: _SyncLine(
                        summary: data.summary,
                        syncing: syncing,
                      ),
                      child: BalanceHeader(summary: data.summary),
                    )
                  else
                    _SyncLine(summary: null, syncing: syncing),
                  const SizedBox(height: 16),
                  _Actions(
                    onSend: () => _open(const SendScreen()),
                    onReceive: () => _open(const ReceiveScreen()),
                    onScan: scanner.supported ? _scan : null,
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
                  ProtocolSectionHead(
                    l.homeRecentActivity,
                    trailing: transactions.isEmpty
                        ? null
                        : TextButton(
                            onPressed: () => _open(const HistoryScreen()),
                            child: Text(l.homeSeeAll),
                          ),
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

/// What home's notice slot shows when there is no notice: the update line while there is
/// something to say about an update, else the sync bar while home syncs, else nothing.
class _HomeStatus extends ConsumerWidget {
  const _HomeStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updating = ref.watch(
      updateProvider.select((s) => s.phase != UpdatePhase.idle),
    );
    if (updating) return const _UpdateLine();
    if (!_syncing(ref.watch(homeProvider))) return const SizedBox.shrink();
    final percent = ref.watch(syncProgressProvider);
    return SlotProgress(
      value: percent == null ? null : percent / 100,
      label: context.l10n.homeSyncingLabel,
    );
  }
}

/// Update availability, download progress and install errors, in one line that fits the slot.
class _UpdateLine extends ConsumerWidget {
  const _UpdateLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(updateProvider);
    final notifier = ref.read(updateProvider.notifier);
    final update = state.update;
    // The available, downloading and installing phases always carry the update.
    final version = update?.versionName ?? '';
    final (String text, Widget? action) = switch (state.phase) {
      UpdatePhase.idle => ('', null),
      UpdatePhase.checking => (l.updateChecking, null),
      UpdatePhase.upToDate => (l.updateUpToDate, null),
      UpdatePhase.available => (
        state.text?.call(l) ?? l.updateAvailable(version),
        TextButton(
          onPressed: notifier.install,
          child: Text(l.updateInstallButton),
        ),
      ),
      UpdatePhase.downloading => (
        l.updateDownloading(version, ((state.progress ?? 0) * 100).floor()),
        null,
      ),
      UpdatePhase.installing => (l.updateInstalling(version), null),
      UpdatePhase.failed => (
        state.text?.call(l) ?? l.updateFailed,
        TextButton(
          onPressed: update == null ? notifier.check : notifier.install,
          child: Text(l.updateTryAgain),
        ),
      ),
    };
    if (text.isEmpty) return const SizedBox.shrink();
    final notes = update?.notes ?? '';
    final line = Row(
      children: [
        Icon(Icons.system_update, semanticLabel: l.updateIconLabel),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),
        ?action,
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Stack(
        children: [
          Positioned.fill(
            child: notes.isNotEmpty && state.phase == UpdatePhase.available
                // The release notes stay one long-press away.
                ? Tooltip(message: notes, child: line)
                : line,
          ),
          if (state.phase == UpdatePhase.downloading)
            Positioned(
              left: 36,
              right: 8,
              bottom: 4,
              child: LinearProgressIndicator(
                value: state.progress,
                semanticsLabel: l.updateDownloadProgressLabel,
              ),
            ),
        ],
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
    final l = context.l10n;
    // Before any export nothing is in a backup; after one, some payments may only have changed.
    final text = exportedAt == null
        ? l.homeHistoryNotBackedUp(count)
        : l.homeHistoryChangedSinceBackup(count);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: EdgeCard(
        edge: context.tokens.warn,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(text),
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ref
                        .read(appSettingsProvider.notifier)
                        .dismissHistoryReminder(chain, now),
                    child: Text(l.homeHistoryReminderNotNow),
                  ),
                  TextButton(
                    onPressed: () => exportHistoryBackup(context, ref),
                    child: Text(l.homeHistoryExportButton),
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
    final t = context.tokens;
    final l = context.l10n;
    return EdgeCard(
      edge: t.warn,
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Row(
          children: [
            Icon(Icons.key_outlined, color: t.accentText),
            const SizedBox(width: 12),
            Expanded(child: Text(l.homeBackupCardText)),
            TextButton(
              onPressed: onBackup,
              child: Text(l.homeBackupCardButton),
            ),
            IconButton(
              tooltip: l.homeBackupCardDismiss,
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
    final l = context.l10n;
    final summary = widget.summary;
    final display = amountDisplay(ref);
    final hidden = display.hidden;
    final fiat = approxFiat(l, summary.spendable, display);
    final buckets = [
      (l.homeBalanceConfirming, summary.awaitingConfirmation),
      (l.homeBalanceWaitingToFinish, summary.awaitingFinalization),
      (l.homeBalanceLocked, summary.locked),
      (l.homeBalanceImmature, summary.immature),
    ].where((b) => b.$2 > BigInt.zero).toList();
    final notSpendable = summary.total - summary.spendable;
    final summaryLine = notSpendable > BigInt.zero
        ? l.homeBalanceNotSpendable(shownEpic(l, notSpendable, hidden: hidden))
        : l.homeBalanceAmountWaitingToFinish(
            shownEpic(l, summary.awaitingFinalization, hidden: hidden),
          );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.homeBalanceSpendable, style: theme.textTheme.labelLarge),
          Row(
            children: [
              Flexible(
                child: Semantics(
                  container: true,
                  label: hidden ? l.homeBalanceHiddenLabel : null,
                  excludeSemantics: hidden,
                  // One line however long the balance: it shrinks rather than wraps.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      shownEpic(l, summary.spendable, hidden: hidden),
                      maxLines: 1,
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: hidden ? l.homeShowBalances : l.homeHideBalances,
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
                            ? l.homeHideBreakdown
                            : l.homeShowBreakdown,
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
                    Text(shownEpic(l, value, hidden: hidden)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Whether the balance is current: syncing, up to date, not validated, or node unreachable, and
/// whether epicbox is connected. The sync bar is in the notice slot ([_HomeStatus]).
class _SyncLine extends ConsumerWidget {
  const _SyncLine({required this.summary, required this.syncing});

  final WalletSummary? summary;
  final bool syncing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final tip = ref.watch(nodeTipProvider);
    final listening = ref.watch(listenerProvider.select((s) => s.connected));
    final lost = ref.watch(listenerProvider.select((s) => s.lost));
    final percent = syncing ? ref.watch(syncProgressProvider) : null;
    final summary = this.summary;
    String? height;
    final (IconData icon, String text, bool problem) = switch (tip) {
      _ when syncing => (
        Icons.sync,
        percent == null ? l.homeSyncSyncing : l.homeSyncSyncingPercent(percent),
        false,
      ),
      AsyncError() => (Icons.cloud_off, l.homeSyncNodeUnreachable, true),
      _ when summary != null && !summary.validatedWithNode => (
        Icons.sync_problem,
        l.homeSyncNotValidated,
        true,
      ),
      AsyncData() => (Icons.check_circle_outline, l.homeSyncUpToDate, false),
      _ => (Icons.sync, l.homeSyncContactingNode, false),
    };
    if (tip case AsyncData(:final value)) {
      final synced =
          summary != null && summary.lastConfirmedHeight > BigInt.zero
          ? summary.lastConfirmedHeight
          : value.height;
      height = l.homeSyncedAtBlock(groupDigits(l, synced));
    }
    final color = problem
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    final relay = listening
        ? null
        : lost
        ? l.homeEpicboxOffline
        : l.homeEpicboxConnecting;
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
                relay == null ? text : l.homeSyncLineWithRelay(text, relay),
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
    // The block height means little to most people; it stays one long-press away, or in the
    // readout with Advanced options on.
    final status = height == null || syncing
        ? line
        : Tooltip(message: height, child: line);
    final config = ref.watch(walletConfigProvider);
    if (config == null) return status;
    final node = Uri.tryParse(config.nodeUrl)?.host ?? config.nodeUrl;
    final listener = listening
        ? l.receiveEpicboxConnected
        : lost
        ? l.receiveEpicboxOffline
        : l.receiveEpicboxConnecting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        status,
        Advanced(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, left: 26),
            child: Readout(
              [
                if (height != null) '$height · $node' else node,
                '${config.epicboxDomain}:${config.epicboxPort} · $listener',
              ].join('\n'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Send, Receive and Scan as one hairline-divided strip, icons in the accent colour.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.onSend,
    required this.onReceive,
    required this.onScan,
  });

  final VoidCallback onSend;
  final VoidCallback onReceive;

  /// Null where the device has no camera scanner.
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final radius = BorderRadius.circular(t.radiusSmall);
    final cells = <(IconData, String, String?, VoidCallback)>[
      (Icons.north_east, l.homeSendButton, null, onSend),
      (Icons.south_west, l.homeReceiveButton, null, onReceive),
      if (onScan case final scan?)
        (Icons.qr_code_scanner, l.sendScanButton, l.homeScanTooltip, scan),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: t.line),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (icon, label, tooltip, onTap))
                  in cells.indexed) ...[
                if (i > 0)
                  VerticalDivider(width: 1, thickness: 1, color: t.line),
                Expanded(
                  child: _ActionCell(
                    icon: icon,
                    label: label,
                    tooltip: tooltip,
                    onTap: onTap,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cell = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: t.accentText),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      child: tooltip == null ? cell : Tooltip(message: tooltip, child: cell),
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
    final l = context.l10n;
    final count = waiting.length;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: EdgeCard(
        edge: context.tokens.accent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.homePendingTitle(count),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l.homePendingBody(count, shownEpic(l, total, hidden: hidden)),
              ),
              // One row on a phone; wraps only at large text.
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    style: _compact,
                    onPressed: () =>
                        openHelp(context, HelpTopic.waitingForRecipient),
                    child: Text(l.homePendingWhy),
                  ),
                  TextButton(
                    style: _compact,
                    onPressed: () => open(
                      count == 1
                          ? TxDetailsScreen(txKey: waiting.single.key)
                          : const HistoryScreen(filter: HistoryFilter.pending),
                    ),
                    child: Text(l.homePendingView(count)),
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
              context.l10n.homeNoPayments,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.qr_code),
              label: Text(context.l10n.homeShowMyAddress),
              onPressed: onReceive,
            ),
          ],
        ),
      ),
    );
  }
}
