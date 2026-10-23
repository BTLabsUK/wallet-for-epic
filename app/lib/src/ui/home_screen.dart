import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart' show contactNameFor, contactsProvider;
import '../demo.dart';
import '../errors.dart';
import '../l10n.dart';
import '../btlabs_onions.dart';
import '../net/tor_net.dart';
import '../phone_tor.dart';
import '../tor_phone.dart';
import '../providers.dart';
import '../push.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../updater.dart';
import '../wallet_service.dart';
import 'backup_screen.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'demo_guide.dart';
import 'demo_screens.dart' show DemoCountdown, TestCoinsButton;
import 'help_screen.dart';
import 'history_screen.dart';
import 'home_parts.dart';
import 'invoices_screen.dart' show InvoicesEntry, InvoicesScreen;
import 'network_status.dart';
import 'outputs_screen.dart';
import 'receive_screen.dart' show ReceiveView;
import 'restore_screen.dart' show ScanProgressView;
import 'scan_screen.dart' show offersQrScan, qrScannerProvider;
import 'send_screen.dart' show SendView, trackedSendProvider;
import 'shell_header.dart';
import 'settings_history.dart' show exportHistoryBackup;
import 'settings_screen.dart';
import 'slate_file_screen.dart';
import 'status.dart';
import 'theme/brand.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';
import 'tx_details_screen.dart';

/// How often home refreshes against the node while it is on screen and the app is in front.
const Duration autoRefreshInterval = Duration(seconds: 60);

/// Transactions shown under "Recent activity".
const int recentActivityCount = 5;

/// The history backup reminder shows only with at least this many payments not in a backup.
const int historyReminderMinPayments = 10;

/// How long the history backup reminder stays away after the last export, the last "Not now",
/// or (for a wallet never exported nor dismissed) the first time it had something to remind of.
const Duration historyReminderPause = Duration(days: 30);

/// The reminder never shows while a payment this recent is in the list, so it does not pop up
/// right after a send or a receive.
const Duration historyReminderQuiet = Duration(minutes: 10);

/// How many payments a history backup would keep that the last export does not have, ignoring
/// when to remind. A payment counts once, when it is newer than the export ([exportedAt], Unix
/// seconds), was pending in the export and has settled since, or has a different note than in
/// the export ([snapshot]). Restored and imported rows are left out: a restore or an import
/// brings them back anyway.
int unbackedPayments(
  Iterable<TxEntry> txs, {
  int? exportedAt,
  HistoryExportSnapshot? snapshot,
}) {
  bool changed(TxEntry t) {
    if (exportedAt == null || t.timeUnix > exportedAt) return true;
    if (snapshot == null) return false;
    final settled =
        snapshot.pendingKeys.contains(t.key) &&
        (t.status == TxStatus.confirmed || t.status == TxStatus.cancelled);
    return settled ||
        snapshot.noteHashes[t.key] != HistoryExportSnapshot.noteHash(t.note);
  }

  return txs.where((t) => t.source == TxSource.wallet && changed(t)).length;
}

/// How many payments the history backup reminder should name, or null when it stays hidden:
/// fewer than [historyReminderMinPayments] not in a backup; a wallet payment from the last
/// [historyReminderQuiet]; or less than [historyReminderPause] since the latest of the last
/// export ([exportedAt]), the last dismissal ([dismissedAt]) and, as a start for a wallet with
/// neither, [firstSeenAt] (when the reminder first had something to remind of). All Unix
/// seconds. With none of the three known the reminder waits for [firstSeenAt] to be stored.
int? paymentsNotInBackup(
  Iterable<TxEntry> txs, {
  required DateTime now,
  int? exportedAt,
  int? dismissedAt,
  int? firstSeenAt,
  HistoryExportSnapshot? snapshot,
}) {
  final n = unbackedPayments(txs, exportedAt: exportedAt, snapshot: snapshot);
  if (n < historyReminderMinPayments) return null;
  final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;
  final quietFrom = nowSeconds - historyReminderQuiet.inSeconds;
  if (txs.any((t) => t.source == TxSource.wallet && t.timeUnix > quietFrom)) {
    return null;
  }
  final marks = [exportedAt, dismissedAt, firstSeenAt].nonNulls;
  if (marks.isEmpty) return null;
  final since = marks.reduce((a, b) => a > b ? a : b);
  if (now.difference(localTime(since)) < historyReminderPause) return null;
  return n;
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
      // Finished and posted, not yet confirmed: "Completed" is kept for the balance's confirmations.
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

  /// The page position as [headerOpenness] reads it: 1 on Wallet, 0 on Send and Receive. A tap
  /// from Send to Receive stays at 0, rather than opening and closing on the way.
  double _openness() {
    final tab = ref.read(shellTabProvider);
    if (_tapPassesWallet) return 0;
    return headerOpenness(
      _pages.hasClients && _pages.position.haveDimensions
          ? _pages.page ?? tab.index.toDouble()
          : tab.index.toDouble(),
    );
  }

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _timer = Timer.periodic(autoRefreshInterval, (_) => _autoRefresh());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Home opens at start and on every unlock: each is an opening. A resume that needs no
      // unlock checks from `WalletApp`.
      // The web demo has no in-app updates.
      if (!ref.read(demoModeProvider)) {
        ref.read(updateProvider.notifier).checkOnOpening();
      }
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
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

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
    final from = ShellTab.values[(_pages.page ?? tab.index.toDouble()).round()];
    _tapPassesWallet = from != ShellTab.wallet && tab != ShellTab.wallet;
    _pages
        .animateToPage(
          tab.index,
          duration: shellTabDuration,
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (move == _tapMove) {
            _tapMove = 0;
            _tapPassesWallet = false;
          }
        });
  }

  /// Nonzero while a tap moves the pages, so the pages passed on the way change no tab.
  int _tapMove = 0;

  /// Whether the running tap moves between Send and Receive, past Wallet. The header then
  /// stays closed instead of opening and closing again on the way, which flickered.
  bool _tapPassesWallet = false;

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
    // Send's tracker is showing this payment finish; a notice would say it twice.
    if (event.kind == ListenerEventKind.finalized &&
        tx != null &&
        tx.key == ref.read(trackedSendProvider) &&
        ref.read(shellTabProvider) == ShellTab.send) {
      return;
    }
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
    // The phone's Tor controller lives as long as the shell: it starts tor on unlock when Tor
    // receiving is on, and keeps it for a send. A listen, not a watch: progress ticks must
    // not rebuild the shell. The app's own requests (status, price, updates, support) follow
    // the switch's state through phoneTorFollow, with BT Labs' onions from the signed list.
    void follow(PhoneTorState s) {
      TorNet.onions = onionLookupOf(ref.read(onionDirectoryProvider));
      phoneTorFollow(s);
    }

    ref.listen(phoneTorProvider, (_, s) => follow(s));
    follow(ref.read(phoneTorProvider));
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
    final tab = ref.watch(shellTabProvider);
    final l = context.l10n;
    final demo = ref.watch(demoModeProvider);
    final scan = offersQrScan(ref);

    return _Backdrop(
      child: SlotScaffold(
        idle: const ShellEdge(),
        appBar: AppBar(
          leadingWidth: shellLeadingWidth,
          leading: const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: 10),
              child: EpicMark(size: 26),
            ),
          ),
          titleSpacing: 0,
          title: AnimatedBuilder(
            animation: _pages,
            builder: (context, _) => ShellBarTitle(
              openness: _openness(),
              trailing: demo ? const DemoCountdown() : null,
            ),
          ),
          actions: [
            // Invoices moved to the destinations row; the entry keeps its event wiring.
            const InvoicesEntry(visible: false),
            if (scan)
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
            _SettingsButton(onPressed: () => _open(const SettingsScreen())),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab.index,
          onDestinationSelected: (i) => _goTab(ShellTab.values[i]),
          // Each tab shows its label, so none has a tooltip, which stayed over the main
          // button after a click.
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.north_east),
              label: l.homeSendButton,
              tooltip: '',
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet),
              label: l.shellWalletTab,
              tooltip: '',
            ),
            NavigationDestination(
              icon: const Icon(Icons.south_west),
              label: l.homeReceiveButton,
              tooltip: '',
            ),
          ],
        ),
        body: PageView(
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
    );
  }

  /// A balance tile opens Outputs, filtered to that balance (Total: every output).
  void _openOutputs(BalanceKind kind) => _open(
    OutputsScreen(
      filter: switch (kind) {
        BalanceKind.confirming => OutputsFilter.confirming,
        BalanceKind.waitingSender => OutputsFilter.confirming,
        BalanceKind.locked => OutputsFilter.locked,
        BalanceKind.immature => OutputsFilter.immature,
        BalanceKind.total || BalanceKind.calm => null,
      },
    ),
  );

  /// A destination tile opens its screen.
  void _openDestination(HomeDestination destination) => _open(switch (destination) {
    HomeDestination.activity => const HistoryScreen(),
    HomeDestination.outputs => const OutputsScreen(),
    HomeDestination.contacts => const ContactsScreen(),
    HomeDestination.invoices => const InvoicesScreen(),
  });

  /// The middle tab: the balance tiles, the status card, the destinations, reminders,
  /// pending sends and recent activity, with pull to refresh.
  Widget _walletTab(BuildContext context) {
    final config = ref.watch(walletConfigProvider);
    final home = ref.watch(homeProvider);
    final scan = ref.watch(scanProvider);
    final l = context.l10n;
    final data = home.value;
    final demo = ref.watch(demoModeProvider);
    final guide = demoGuideShown(ref);
    // The web demo shows no phrase and keeps no history files, so it has no backup cards.
    final backedUp = demo || (ref.watch(backedUpProvider).value ?? true);
    final backupDismissed =
        ref.watch(backupCardDismissedProvider).value ?? false;
    final transactions = data?.transactions ?? const <TxEntry>[];
    Widget column(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: child,
      ),
    );
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The balance stays put above the list; a swipe fades it with the page position,
          // and off Wallet its line stops scrolling.
          AnimatedBuilder(
            animation: _pages,
            builder: (context, child) {
              final t = _openness();
              return TickerMode(
                enabled: t > 0,
                child: Opacity(opacity: shellFade(t), child: child),
              );
            },
            child: column(const WalletBalance()),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: column(
                ListView(
                  // Pull to refresh works on a short list too.
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    // The desktop Overview's tiles, status rows and sidebar, in that order.
                    // The tiles row runs edge to edge; the list's gutter is taken back.
                    BalanceTiles(onTap: _openOutputs),
                    const SizedBox(height: 12),
                    const NetworkStatusCard(),
                    const SizedBox(height: 12),
                    HomeDestinations(onOpen: _openDestination),
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
                    if (guide)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: DemoGuide(),
                      ),
                    // It waits until the phrase card is gone, so the two backup cards never stack.
                    if ((backedUp || backupDismissed) &&
                        config != null &&
                        !demo)
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
                              child: Text(l.homeViewAll(transactions.length)),
                            ),
                    ),
                    if (data != null && transactions.isEmpty)
                      EmptyState(
                        icon: const Icon(Icons.south_west),
                        message: l.homeNoPayments,
                        // The checklist carries Get test coins while it shows; otherwise
                        // the next step is the Receive tab.
                        action: demo && !guide
                            ? const TestCoinsButton()
                            : demo
                            ? null
                            : TextButton(
                                onPressed: () => _goTab(ShellTab.receive),
                                child: Text(l.homeReceiveButton),
                              ),
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
        ],
      ),
    );
  }
}

/// The lit backdrop behind the shell. While the node syncs its light breathes slowly; with
/// reduced motion it does not.
class _Backdrop extends ConsumerWidget {
  const _Backdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ProtocolBackdrop(
    focus: topGlow,
    breathing: watchWalletStatus(ref).node.state == NodeState.syncing,
    child: child,
  );
}

/// The app bar's Settings button, with an accent dot while an update is on offer.
class _SettingsButton extends ConsumerWidget {
  const _SettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(updateProvider.select((s) => s.update != null));
    final l = context.l10n;
    return IconButton(
      key: settingsButtonKey,
      tooltip: update ? l.homeSettingsUpdateTooltip : l.homeSettingsTooltip,
      icon: Badge(
        key: update ? settingsUpdateDotKey : null,
        isLabelVisible: update,
        smallSize: 8,
        backgroundColor: context.tokens.accent,
        child: const Icon(Icons.settings_outlined),
      ),
      onPressed: onPressed,
    );
  }
}

/// The app bar's Settings button and its update dot, for tests.
const Key settingsButtonKey = ValueKey('settings-button');
const Key settingsUpdateDotKey = ValueKey('settings-update-dot');

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
      final text = state.text;
      text == null
          ? show(l.updateUpToDate, NoticeLevel.success)
          : show(text(l), NoticeLevel.info);
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
    final firstSeenAt = settings.historyReminderFirstSeenAt[chain.name];
    if (firstSeenAt == null &&
        unbackedPayments(
              transactions,
              exportedAt: exportedAt,
              snapshot: settings.historyExportSnapshots[chain.name],
            ) >
            0) {
      // The 30 days of a wallet with no export and no dismissal start here.
      final notifier = ref.read(appSettingsProvider.notifier);
      Future.microtask(() => notifier.markHistoryReminderSeen(chain, now));
    }
    final count = paymentsNotInBackup(
      transactions,
      now: now,
      exportedAt: exportedAt,
      dismissedAt: settings.historyReminderDismissedAt[chain.name],
      firstSeenAt: firstSeenAt,
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
              // One line; "Why is it waiting?" has the rest.
              Text(l.homePendingShort(shownEpic(l, total, hidden: hidden))),
              // One row on a phone; wraps only at large text.
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    style: _compact,
                    onPressed: () =>
                        openHelp(context, HelpId.send),
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
