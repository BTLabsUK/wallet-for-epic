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
import 'invoices_screen.dart' show InvoicesEntry;
import 'receive_screen.dart' show ReceiveView;
import 'restore_screen.dart' show ScanProgressView;
import 'scan_screen.dart' show qrScannerProvider;
import 'send_screen.dart' show SendView;
import 'shell_header.dart';
import 'settings_history.dart' show exportHistoryBackup;
import 'settings_screen.dart';
import 'slate_file_screen.dart';
import 'theme/brand.dart';
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
/// [tx] is the transaction with the event's slate id, else its tx id, when the list has it.
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
    case ListenerEventKind.repeated:
      // The sender asked again and got the first answer; no second payment is on the way.
      return contactName == null
          ? l.homeNoticeRepeated
          : l.homeNoticeRepeatedFrom(contactName);
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

/// The level of a listener event's notice: a payment that arrived or finished is a success, a
/// repeated slate only informs, a payment that expired or waits on the node is a warning, and a
/// relay or payment failure is an error.
NoticeLevel paymentNoticeLevel(ListenerEventKind kind) => switch (kind) {
  ListenerEventKind.received ||
  ListenerEventKind.finalized => NoticeLevel.success,
  ListenerEventKind.repeated => NoticeLevel.info,
  ListenerEventKind.expired || ListenerEventKind.delayed => NoticeLevel.warning,
  ListenerEventKind.error => NoticeLevel.error,
  // Never a notice; see [paymentNotice].
  ListenerEventKind.connected ||
  ListenerEventKind.disconnected ||
  ListenerEventKind.stopped => NoticeLevel.info,
};

/// Whether home's figures are on screen while a refresh against the node runs: the background
/// refresh after a local first load, or a reload in place.
bool _syncing(AsyncValue<HomeData> home) {
  final data = home.value;
  return data != null && (home.isLoading || data.syncing);
}

/// The wallet shell: Send, Wallet and Receive as three tabs under one app bar and balance
/// header, with a tab bar below. Swiping or tapping changes only the page between them.
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

  late final PageController _pages = PageController(
    initialPage: ref.read(shellTabProvider).index,
  );

  /// Bumped when a payment is done, so the Send tab starts a fresh form.
  int _sendForm = 0;

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
    _pages.dispose();
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
    if (done == true && mounted) {
      _showNotice(context.l10n.homeBackedUpNotice, level: NoticeLevel.success);
    }
  }

  /// Opens [screen] over home. Coming back does not refresh: screens that change the wallet
  /// reload home themselves, and the timer keeps it current.
  Future<void> _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  /// Scans a QR code and shows the Send tab with it as the recipient.
  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scan(context);
    if (text == null || !mounted) return;
    ref.read(sendRecipientProvider.notifier).hand(text);
    _goTab(ShellTab.send);
  }

  void _goTab(ShellTab tab) => ref.read(shellTabProvider.notifier).go(tab);

  /// Moves the pages to [tab], unless a swipe already brought them there.
  void _showTab(ShellTab tab) {
    if (!_pages.hasClients || _pages.page?.round() == tab.index) return;
    if (MediaQuery.of(context).disableAnimations) {
      _pages.jumpToPage(tab.index);
      return;
    }
    // Send to Receive passes Wallet; the tab bar keeps marking the tab that was tapped.
    _tapMove++;
    final move = _tapMove;
    _pages
        .animateToPage(
          tab.index,
          duration: shellTabDuration,
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (move == _tapMove) _tapMove = 0;
        });
  }

  /// Nonzero while a tap moves the pages, so the pages passed on the way change no tab.
  int _tapMove = 0;

  void _pageChanged(int index) {
    if (_tapMove == 0) _goTab(ShellTab.values[index]);
  }

  /// A payment is done: back to Wallet, with a fresh Send form for next time.
  void _sendDone() {
    ref.read(sendRecipientProvider.notifier).clear();
    setState(() => _sendForm++);
    _goTab(ShellTab.wallet);
  }

  /// Tells the user what the listener just did, in words, with a way to the transaction.
  Future<void> _notify(ListenerEvent event) async {
    TxEntry? tx;
    final slateId = event.slateId;
    if (event.kind == ListenerEventKind.delayed) {
      // Once per payment for as long as home is open, however often the answer is retried.
      if (slateId != null && !_delayedShown.add(slateId)) return;
    }
    final txId = event.txId;
    if (slateId != null || txId != null) {
      // The listener refreshes home right after this event, except for a repeat; wait for
      // that list.
      await Future<void>.delayed(Duration.zero);
      try {
        final data = await ref.read(homeProvider.future);
        tx = data.transactions
            .where((t) => slateId != null ? t.slateId == slateId : t.id == txId)
            .firstOrNull;
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
    _showNotice(text, level: paymentNoticeLevel(event.kind), txKey: key);
  }

  /// A notice with a way to the payment when it is known. It leaves on its own; the payment is
  /// always one tap away in the list too.
  void _showNotice(String text, {required NoticeLevel level, String? txKey}) {
    ref
        .read(noticeProvider.notifier)
        .show(
          text,
          level: level,
          action: txKey == null
              ? null
              : NoticeAction(context.l10n.homeNoticeView, () {
                  // The notice outlives home: a lock replaces it with the unlock screen.
                  if (!mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TxDetailsScreen(txKey: txKey),
                    ),
                  );
                }),
        );
  }

  @override
  Widget build(BuildContext context) {
    // A push only says a payment is waiting in epicbox. While connected, the listener
    // collects it and gives the notice, so one payment gets one notice.
    ref.listen(pushProvider.select((s) => s.last), (_, message) {
      if (message == null || ref.read(listenerProvider).connected) return;
      _showNotice(context.l10n.homePushNotice, level: NoticeLevel.info);
    });
    ref.listen(incomingSlateProvider, (_, file) {
      if (file != null) _openIncoming();
    });
    ref.listen(listenerProvider.select((s) => s.last), (_, event) {
      if (event != null) _notify(event);
    });
    ref.listen(shellTabProvider, (_, tab) => _showTab(tab));
    // Once per phase, and per whole percent while downloading.
    ref.listen(
      updateProvider.select(
        (s) => (s.phase, ((s.progress ?? 0) * 100).floor(), s.text),
      ),
      (_, _) => showUpdateNotice(
        context.l10n,
        ref.read(updateProvider),
        ref.read(noticeProvider.notifier),
        ref.read(updateProvider.notifier),
      ),
    );
    final config = ref.watch(walletConfigProvider);
    final tab = ref.watch(shellTabProvider);
    final l = context.l10n;
    final scanner = ref.watch(qrScannerProvider);

    return SlotScaffold(
      idle: const _HomeStatus(),
      glow: topGlow,
      appBar: AppBar(
        leading: const Center(child: EpicMark(size: 26)),
        titleSpacing: 0,
        title: ShellTitle(chain: config?.chain),
        actions: [
          const InvoicesEntry(),
          if (scanner.supported)
            IconButton(
              tooltip: l.homeScanTooltip,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scan,
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) => _goTab(ShellTab.values[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.north_east),
            label: l.homeSendButton,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l.shellWalletTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.south_west),
            label: l.homeReceiveButton,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: AnimatedBuilder(
                    animation: _pages,
                    builder: (context, _) => ShellHeader(
                      openness: headerOpenness(
                        _pages.hasClients && _pages.position.haveDimensions
                            ? _pages.page ?? tab.index.toDouble()
                            : tab.index.toDouble(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: _pageChanged,
              children: [
                _KeepAlive(
                  child: SendView(
                    key: ValueKey('send-$_sendForm'),
                    onDone: _sendDone,
                  ),
                ),
                _KeepAlive(child: _walletTab(context)),
                const _KeepAlive(child: ReceiveView()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The middle tab: reminders, pending sends and recent activity, with pull to refresh.
  Widget _walletTab(BuildContext context) {
    final config = ref.watch(walletConfigProvider);
    final home = ref.watch(homeProvider);
    final scan = ref.watch(scanProvider);
    final l = context.l10n;
    final data = home.value;
    final backedUp = ref.watch(backedUpProvider).value ?? true;
    final backupDismissed =
        ref.watch(backupCardDismissedProvider).value ?? false;
    final transactions = data?.transactions ?? const <TxEntry>[];
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              // Pull to refresh works on a short list too.
              physics: const AlwaysScrollableScrollPhysics(),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _BackupCard(
                      onBackup: _backup,
                      onDismiss: () => dismissBackupCard(ref, config.chain),
                    ),
                  ),
                if (home.hasError && !home.isLoading)
                  ErrorText(describeError(l, home.error!)),
                _PendingSendsCard(transactions: transactions, open: _open),
                // It waits until the phrase card is gone, so the two backup cards never stack.
                if ((backedUp || backupDismissed) && config != null)
                  _HistoryBackupCard(
                    chain: config.chain,
                    transactions: transactions,
                  ),
                const SizedBox(height: 16),
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
                  EmptyState(
                    icon: const Icon(Icons.south_west),
                    message: l.homeNoPayments,
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
    );
  }
}

/// How long a tap on the tab bar takes to move the pages.
const Duration shellTabDuration = Duration(milliseconds: 250);

/// Keeps a tab's state (a half-filled form, a scroll position) while another tab is shown.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// The line under home's app bar: the sync bar while home syncs, else nothing.
class _HomeStatus extends ConsumerWidget {
  const _HomeStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_syncing(ref.watch(homeProvider))) return const SizedBox.shrink();
    final percent = ref.watch(syncProgressProvider);
    return SlotProgress(
      value: percent == null ? null : percent / 100,
      label: context.l10n.homeSyncingLabel,
    );
  }
}

/// The notice tag of the update phases, so each phase replaces the one before.
const String updateNoticeTag = 'update';

/// Shows the notice for [state]: available (persistent, Install), downloading (persistent, with
/// its progress), installing (persistent), failed (error, Try again), up to date after a check
/// from Settings (success). Idle closes it; checking says nothing here, since a check on start
/// is quiet and Settings announces its own.
void showUpdateNotice(
  AppLocalizations l,
  UpdateState state,
  NoticeNotifier notices,
  UpdateNotifier updater,
) {
  final update = state.update;
  // The available, downloading and installing phases always carry the update.
  final version = update?.versionName ?? '';
  void show(
    String text,
    NoticeLevel level, {
    NoticeAction? action,
    bool persistent = false,
    double? progress,
  }) => notices.show(
    text,
    level: level,
    action: action,
    persistent: persistent,
    progress: progress,
    progressLabel: progress == null ? null : l.updateDownloadProgressLabel,
    tag: updateNoticeTag,
  );
  switch (state.phase) {
    case UpdatePhase.idle:
      notices.dismissTag(updateNoticeTag);
    case UpdatePhase.checking:
      break;
    case UpdatePhase.upToDate:
      show(l.updateUpToDate, NoticeLevel.success);
    case UpdatePhase.available:
      show(
        state.text?.call(l) ?? l.updateAvailable(version),
        NoticeLevel.info,
        persistent: true,
        action: NoticeAction(l.updateInstallButton, updater.install),
      );
    case UpdatePhase.downloading:
      final progress = state.progress ?? 0;
      show(
        l.updateDownloading(version, (progress * 100).floor()),
        NoticeLevel.info,
        persistent: true,
        progress: progress,
      );
    case UpdatePhase.installing:
      show(l.updateInstalling(version), NoticeLevel.info, persistent: true);
    case UpdatePhase.failed:
      show(
        state.text?.call(l) ?? l.updateFailed,
        NoticeLevel.error,
        action: NoticeAction(
          l.updateTryAgain,
          update == null ? updater.check : updater.install,
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
