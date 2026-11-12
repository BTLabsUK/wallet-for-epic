// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart' show contactNameFor, contactsProvider;
import '../epic1.dart' show PaymentMode;
import '../l10n.dart';
import '../btlabs_onions.dart';
import '../net/tor_net.dart';
import '../phone_tor.dart';
import '../tor_phone.dart';
import '../providers.dart';
import '../scan/incoming_link.dart';
import '../scan/scan_checks.dart' show CodeOrigin;
import '../settings.dart';
import '../slate_files.dart';
import '../trust_ids.dart';
import '../updater.dart';
import '../wallet_service.dart';
import '../watch_mode.dart';
import 'backup_screen.dart';
import 'common.dart';
import 'last_session_offer.dart';
import 'contacts_screen.dart';
import 'home_tab.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_tab_bar.dart';
import 'invoices_screen.dart' show InvoicesEntry;
import 'tx_details_screen.dart';
import 'history_screen.dart';
import 'pairing/pairing_notices.dart';
import 'receive_screen.dart' show ReceiveView;
import 'scan_route.dart';
import '../devices/phone_devices.dart' show DeviceLifecycle;
import 'scan_screen.dart' show ScanCode, qrScannerProvider;
import 'send_screen.dart' show SendBack, SendView, trackedSendProvider;
import 'shell_header.dart';
import 'settings_screen.dart';
import 'slate_file_screen.dart';
import 'status.dart';
import 'theme/brand.dart' show ProtocolBackdrop, topGlow;
import 'tour/phone_tour.dart';
import 'levels/relay_down.dart' show RelayDownNotices;
import '../settings_file/host_settings.dart' show appConfig;
import '../log.dart' show logWarn;
import '../onion_notice.dart' show markOnionNoticeSeen, onionNoticeDue;
import '../pairing_providers.dart' show pairingCall;
import '../stale_open.dart';
import 'invite_link_gate.dart';

/// How often home refreshes against the node while it is on screen and the app is in front.
Duration get autoRefreshInterval => appConfig.nodeRefresh;

/// How often home asks the node for its tip between refreshes; a new block refreshes at once,
/// as the desktop does. Epic's blocks come in bursts (three in a minute is common), so a
/// refresh each minute alone could go from Confirming 0/3 to completed with nothing between.
/// While a payment can move with the next block it asks more often (watch mode,
/// watch_mode.dart).
Duration get tipCheckInterval => appConfig.nodeTipCheck;

/// The space between the cards of the Wallet tab (tiles, status, destinations, reminders).
const double homeCardGap = 12;

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
        ListenerEventKind.repeated ||
        ListenerEventKind.stopped:
      // Never a notice: the first three change the listener's state, not `ListenerState.last`;
      // a repeat is only logged (providers.dart).
      return event.message;
  }
}

/// The notice for a sender's report that it posted the incoming payment [tx] (null when the
/// list does not have it): the sender's word, with the amount unless balances are [hidden].
/// Never "received": the payment counts once the chain confirms it.
String senderPostedNotice(AppLocalizations l, TxEntry? tx, {bool hidden = false}) {
  final amount = hidden || tx == null ? null : epicText(l, txAmount(tx).amount);
  return amount == null
      ? l.homeNoticeSenderPosted
      : l.homeNoticeSenderPostedAmount(amount);
}

/// The level of a listener event's notice: a payment that arrived or finished is a success, a
/// payment that expired or waits on the node is a warning, and a
/// relay or payment failure is an error.
NoticeLevel paymentNoticeLevel(ListenerEventKind kind) => switch (kind) {
  ListenerEventKind.received ||
  ListenerEventKind.finalized => NoticeLevel.success,
  ListenerEventKind.expired || ListenerEventKind.delayed => NoticeLevel.warning,
  ListenerEventKind.error => NoticeLevel.error,
  // Never a notice; see [paymentNotice].
  ListenerEventKind.connected ||
  ListenerEventKind.disconnected ||
  ListenerEventKind.repeated ||
  ListenerEventKind.stopped => NoticeLevel.info,
};

/// Whether home's figures are on screen while a refresh against the node runs: the background
/// refresh after a local first load, or a reload in place.
bool _syncing(AsyncValue<HomeData> home) {
  final data = home.value;
  return data != null && (home.isLoading || data.syncing);
}


/// The wallet shell: the tab bar (Home, Activity, Scan, Contacts, Settings) under the current
/// tab. Scan opens the scanner as a flow; Send and Receive open as full-screen routes over the
/// tab bar, asked for through [shellFlowProvider]. The shell also owns the timers, the notices
/// and the hosts that listen for events (invoices, pairing, linked devices, relay).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: _resumed,
    onPause: _paused,
  );
  Timer? _timer;
  bool _tipBusy = false;

  /// In the background: the tip timer stays off until the app is back.
  bool _away = false;
  final TipPacer _tipPace = TipPacer(normal: tipCheckInterval);

  /// Payments whose "could not reach the node" notice was already shown.
  final Set<String> _delayedShown = {};

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _startRefreshTimer();
    _armTip();
    // Each list read can change the pace: a new payment, a step, a block.
    ref.listenManual(homeProvider, (_, next) {
      final data = next.value;
      if (data == null || !mounted) return;
      ref.read(blockWatchProvider).saw(data.transactions, data.summary.lastConfirmedHeight, now: ref.read(clockProvider)());
      _armTip();
    }, fireImmediately: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Home opens at start and on every unlock: each is an opening. A resume that needs no
      // unlock checks from `WalletApp`.
      ref.read(updateProvider.notifier).checkOnOpening();
      _openIncoming();
      _openLink();
      // After unlock, once: the last session froze or crashed, its log can be sent.
      unawaited(offerLastSessionReport(context, ref));
      // The one notice about the changed Tor address goes before the phrase reminder: the
      // reminder yields to a notice already up, and comes back on a later opening.
      unawaited(_offerOnionNotice().then((_) => _offerBackup()));
      _noteStaleOpen();
    });
    // epic1 mode has no Tor address payments: its notice goes with the switch.
    ref.listenManual<PaymentMode>(paymentModeProvider, (_, mode) {
      if (mode == PaymentMode.epic1) ref.read(noticeProvider.notifier).dismissTag(onionNoticeTag);
    });
    // The welcome tour goes first: the reminder waits until it closes.
    ref.listenManual<bool>(phoneTourProvider.select((s) => s.open), (was, open) {
      if (was == true && !open) unawaited(_offerBackup());
    });
  }

  /// A wallet not opened for a while says so, once per open (`stale_open.dart`).
  void _noteStaleOpen() {
    if (!mounted) return;
    final days = ref.read(staleOpenShownProvider.notifier).take(ref.read(clockProvider)());
    if (days == null) return;
    ref.read(noticeProvider.notifier).show(context.l10n.contactsStaleOpened(days), level: NoticeLevel.info);
    // The check runs in the background; a contact it gets no answer from shows "Not answering".
    unawaited(pairingCall(ref, (api) => api.checkContacts()).then<void>((_) {}, onError: (Object _) {}));
  }

  /// This opening's recovery phrase reminder was handled (shown, or not due).
  bool _backupAsked = false;

  /// The one notice a wallet from before the onion's own key sees (onion_notice.dart): once,
  /// also when closed without its link. The link is copied: the phone opens no browser itself.
  /// Not in epic1 mode: the wallet takes no Tor address payments there. The notice waits for
  /// the classic mode.
  Future<void> _offerOnionNotice() async {
    if (!mounted || ref.read(phoneTourProvider).open) return;
    if (ref.read(paymentModeProvider) == PaymentMode.epic1) return;
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final store = ref.read(secretStoreProvider);
    if (!await onionNoticeDue(store, chain: config.chain.name, walletId: config.walletId)) return;
    // Never over another notice (a payment, the records' copy): the next opening shows it.
    if (!mounted || ref.read(noticeProvider) != null) return;
    try {
      await markOnionNoticeSeen(store, chain: config.chain.name, walletId: config.walletId);
    } on Object catch (e) {
      logWarn('home', 'onion notice marker not saved: ${e.runtimeType}');
      return;
    }
    if (!mounted || ref.read(noticeProvider) != null) return;
    final l = context.l10n;
    ref.read(noticeProvider.notifier).show(l.torAddressChangedTitle, level: NoticeLevel.info, persistent: true, tag: onionNoticeTag);
  }

  /// Item 16: the recovery phrase reminder is a notice, not a card. It comes on an opening of
  /// home while the phrase is not written down, at most once per [backupNoticeEvery]; Settings ›
  /// Security keeps its warning mark meanwhile.
  Future<void> _offerBackup() async {
    if (_backupAsked || !mounted) return;
    if (ref.read(phoneTourProvider).open) return;
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    _backupAsked = true;
    final bool backedUp;
    try {
      backedUp = await ref.read(backedUpProvider.future);
    } on Object {
      return;
    }
    if (backedUp || !mounted) return;
    final store = ref.read(secretStoreProvider);
    final now = ref.read(clockProvider)();
    final last = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(await store.read(backupNoticeKey(config.chain)) ?? '') ?? 0,
    );
    if (!mounted || now.difference(last) < backupNoticeEvery) return;
    // Never over another notice (a payment, the records' copy): this opening goes without it.
    if (ref.read(noticeProvider) != null) return;
    await store.write(backupNoticeKey(config.chain), '${now.millisecondsSinceEpoch}');
    if (!mounted || ref.read(noticeProvider) != null) return;
    final l = context.l10n;
    ref
        .read(noticeProvider.notifier)
        .show(
          l.homeBackupCardText,
          // Info, so a payment's notice that comes next takes its place at once.
          level: NoticeLevel.info,
          tag: backupNoticeTag,
          action: NoticeAction(l.homeBackupCardButton, () {
            // The notice outlives home: a lock replaces it with the unlock screen.
            if (mounted) unawaited(_backup());
          }),
        );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tipPace.stop();
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

  /// Refreshes unless the app is in the background, or a refresh or scan is already running.
  /// Also under another screen: Outputs and the transaction details show the same figures, and
  /// they stood still while the header kept saying Synced (android-06).
  void _autoRefresh() {
    if (!mounted) return;
    final life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) return;
    if (_syncing(ref.read(homeProvider)) || ref.read(scanProvider).running) {
      return;
    }
    // The minute's timer counts from this refresh: after a block's refresh it only covers a
    // node that is stuck or does not answer.
    _startRefreshTimer();
    _refresh();
  }

  void _startRefreshTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(autoRefreshInterval, (_) => _autoRefresh());
  }

  void _resumed() {
    _away = false;
    _armTip();
    _autoRefresh();
  }

  void _paused() {
    _away = true;
    _tipPace.stop(now: ref.read(clockProvider)());
  }

  /// How closely the list is watched now (watch_mode.dart).
  WatchPace _pace() {
    final data = ref.read(homeProvider).value;
    if (data == null) return WatchPace.none;
    return listPace(
      data.transactions,
      now: ref.read(clockProvider)(),
      tip: data.summary.lastConfirmedHeight,
      minConfirmations: data.summary.minimumConfirmations.toInt(),
      steps: ref.read(blockWatchProvider),
    );
  }

  /// Sets the tip timer for the pace now: to the next ask, or to the moment the pace can change
  /// by time alone.
  void _armTip() {
    if (!mounted || _away) return;
    final data = ref.read(homeProvider).value;
    final now = ref.read(clockProvider)();
    final change = data == null ? null : nextWatchChange(data.transactions, now: now, steps: ref.read(blockWatchProvider));
    _tipPace.arm(_pace(), change: change, now: now, fire: _tipFired);
  }

  void _tipFired() {
    if (!mounted) return;
    if (_tipPace.due(_pace())) _checkTip();
    _armTip();
  }

  /// Asks the node for its tip and refreshes when it is past the height home counts
  /// confirmations at: each block moves a payment's Confirming n/3. Skipped when a refresh
  /// would be ([_autoRefresh]); a failed ask waits for the next one, later in watch mode.
  /// A node that answers again after failing has the payments it refused posted again at once.
  Future<void> _checkTip() async {
    if (!mounted || _tipBusy) return;
    final life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) return;
    final home = ref.read(homeProvider);
    final shown = home.value?.summary.lastConfirmedHeight;
    if (shown == null || shown == BigInt.zero || _syncing(home) || ref.read(scanProvider).running) {
      return;
    }
    _tipBusy = true;
    try {
      final tip = await ref.refresh(nodeTipProvider.future);
      if (!mounted) return;
      final back = _tipPace.answered();
      // A node back after failing is asked at the watch pace again, not the backed-off one.
      _armTip();
      if (back) ref.read(stallRetryProvider).nodeBack();
      if (tip.height > shown || back) {
        _autoRefresh();
      } else if (home.value?.transactions.any((t) => postingNow(t, ref.read(clockProvider)(), ref.read(blockWatchProvider))) ?? false) {
        // Being posted: read the list again, so "Not on the network" does not wait for a block.
        unawaited(ref.read(homeProvider.notifier).relist());
      }
    } catch (_) {
      // The status line shows a node that does not answer; the minute's refresh still runs.
      _tipPace.failed();
      _armTip();
    } finally {
      _tipBusy = false;
    }
  }

  /// Opens a transaction file another app handed over, once a wallet is open to handle it.
  void _openIncoming() {
    final file = ref.read(incomingSlateProvider.notifier).take();
    if (file == null || !mounted) return;
    _open(SlateFileScreen(file: file));
  }

  Future<void> _backup() async {
    ref.read(noticeProvider.notifier).dismissTag(backupNoticeTag);
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

  /// Scans a QR code and opens what it is: Send for a payment code or an address, the QR
  /// Payment reader for a QR Payment code, and a sheet for anything else.
  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scanCode(context);
    if (text == null || !mounted) return;
    await openScannedText(
      context,
      ref,
      text,
      origin: CodeOrigin.qr,
      scanAgain: _scan,
    );
  }

  /// Opens a payment link another app handed over, once the wallet is open. Over another
  /// screen it waits for the user's Open, so nothing in progress is closed.
  void _openLink() {
    final link = ref.read(incomingLinkProvider.notifier).take();
    if (link == null || !mounted) return;
    unawaited(_openLinkText(link.text));
  }

  Future<void> _openLinkText(String text) async {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent ?? true) {
      unawaited(openScannedText(context, ref, text, origin: CodeOrigin.link));
      return;
    }
    showLinkWaiting(ref, context.l10n, () {
      if (mounted) {
        unawaited(
          openScannedText(context, ref, text, origin: CodeOrigin.link),
        );
      }
    }, pairing: pairingLinkKind(text) != null);
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
      // The listener refreshes home right after this event; wait for that list.
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
        _sendOpen) {
      return;
    }
    // The scanned payment's own screen says it is accepted; the notice would cover that.
    if (event.kind == ListenerEventKind.received &&
        qrPaymentScreensOpen > 0) {
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
    _showNotice(
      text,
      level: paymentNoticeLevel(event.kind),
      txKey: key,
      // A failed payment the list does not name yet still has a way in: Activity (UP-030).
      activity: event.kind == ListenerEventKind.error && event.slateId != null && key == null,
    );
  }

  /// The sender of an incoming payment reports it posted; the row says so already
  /// ([paymentPostedProvider] read the list first).
  void _notifyPosted(InvoiceEvent event) {
    final tx = ref
        .read(homeProvider)
        .value
        ?.transactions
        .where((t) => t.slateId == event.slateId)
        .firstOrNull;
    _showNotice(
      senderPostedNotice(
        context.l10n,
        tx,
        hidden: ref.read(appSettingsProvider).value?.hideBalances ?? false,
      ),
      level: NoticeLevel.info,
      txKey: tx?.key,
    );
  }

  /// A notice with a way to the payment when it is known, or to Activity when [activity]. It
  /// leaves on its own; the payment is always one tap away in the list too.
  void _showNotice(
    String text, {
    required NoticeLevel level,
    String? txKey,
    bool activity = false,
  }) {
    final Widget? target = txKey != null
        ? TxDetailsScreen(txKey: txKey)
        : activity
        ? const HistoryScreen()
        : null;
    ref
        .read(noticeProvider.notifier)
        .show(
          text,
          level: level,
          action: target == null
              ? null
              : NoticeAction(context.l10n.homeNoticeView, () {
                  // The notice outlives home: a lock replaces it with the unlock screen.
                  if (!mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => target),
                  );
                }),
        );
  }


  /// Opens the Send or Receive route over the tab bar, after anything over the shell is closed.
  /// A second request replaces the first: Send's "Receive" button, a scanned code.
  void _openFlow(ShellFlow flow) {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (flow == ShellFlow.send) _sendRoutes++;
      navigator
          .push(MaterialPageRoute<void>(builder: (_) => ShellFlowRoute(flow: flow)))
          .whenComplete(() {
            if (flow == ShellFlow.send) _sendRoutes--;
          });
    });
  }

  int _sendRoutes = 0;

  bool get _sendOpen => _sendRoutes > 0;

  void _goTab(int index) => ref.read(shellTabProvider.notifier).go(ShellTab.values[index]);

  @override
  Widget build(BuildContext context) {
    ref.listen(incomingSlateProvider, (_, file) {
      if (file != null) _openIncoming();
    });
    ref.listen(incomingLinkProvider, (_, link) {
      if (link != null) _openLink();
    });
    ref.listen(
      linkDroppedBusyProvider,
      (_, _) => showLinkBusy(ref, context.l10n),
    );
    ref.listen(listenerProvider.select((s) => s.last), (_, event) {
      if (event != null) _notify(event);
    });
    ref.listen(paymentPostedProvider, (_, event) {
      if (event != null) _notifyPosted(event);
    });
    // Keeps the release of payments their senders cancelled listening while home shows; the
    // row words it.
    ref.listen(paymentCancelledProvider, (_, _) {});
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
    // A request for Send or Receive (a button, a scanned code, a notification): take it and
    // open the route.
    ref.listen(shellFlowProvider, (_, flow) {
      if (flow == null) return;
      ref.read(shellFlowProvider.notifier).taken();
      _openFlow(flow);
    });
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

    // The Android back: a tab other than Home goes to Home first; on Home the app leaves, as
    // the system does. Screens over the shell pop first. Invites the system opened (pairing,
    // device link) go to their feature's confirm sheet.
    return InviteLinkGate(
      onUnreadable: (context) => _showNotice(context.l10n.inviteLinkUnreadable, level: NoticeLevel.warning),
      onNoHandler: (context, kind) => _showNotice(inviteNoHandlerText(context.l10n, kind), level: NoticeLevel.info),
      child: PopScope(
        canPop: tab == ShellTab.home,
        onPopInvokedWithResult: (didPop, _) {
          // The tour takes back for its own steps.
          if (didPop || ref.read(phoneTourProvider).open) return;
          ref.read(shellTabProvider.notifier).go(ShellTab.home);
        },
        child: PhoneTourAnchor(
          child: _Backdrop(
            child: SlotScaffold(
              idle: const ShellEdge(),
              // Read below the body's hosts: their invoice events listen before the first
              // collect of the mailboxes starts.
              bottomNavigationBar: Consumer(
                builder: (context, ref, _) => KitTabBar(
                selected: tab.index,
                onSelect: _goTab,
                onScan: _scan,
                scanLabel: l.phoneTabScan,
                scanId: TrustIds.tabScan,
                items: [
                  KitTabItem(icon: KitIcons.home, iconOn: KitIcons.homeOn, label: l.phoneTabHome, semanticsId: TrustIds.tabHome),
                  KitTabItem(
                    icon: KitIcons.activity,
                    iconOn: KitIcons.activityOn,
                    label: l.historyTitle,
                    badge: ref.watch(pendingInvoiceCountProvider),
                    semanticsId: TrustIds.tabActivity,
                  ),
                  KitTabItem(icon: KitIcons.contacts, iconOn: KitIcons.contactsOn, label: l.contactsTitle, semanticsId: TrustIds.tabContacts),
                  KitTabItem(icon: KitIcons.settings, iconOn: KitIcons.settingsOn, label: l.settingsTitle, semanticsId: TrustIds.tabSettings),
                ],
              ),
              ),
              body: Stack(
                children: [
                  // Hosts that listen for events; they draw nothing.
                  // Invoices keep their event wiring (a new invoice is a notice).
                  const InvoicesEntry(visible: false),
                  // Pairing events as notices.
                  const PairingNotices(),
                  // Linked devices' runs (resume, the 5 s reads while on screen).
                  const DeviceLifecycle(child: SizedBox.shrink()),
                  // The Epicbox relay offer as a notice.
                  const RelayDownNotices(),
                  Positioned.fill(
                    child: switch (tab) {
                      ShellTab.home => HomeTab(onRefresh: _refresh),
                      ShellTab.activity => const HistoryScreen(),
                      ShellTab.contacts => const ContactsScreen(),
                      ShellTab.settings => const SettingsScreen(),
                    },
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

/// Send or Receive as a full-screen route over the tab bar: a close button, the balance header
/// and today's screen. A finished payment closes the route. The Android back takes Send's own
/// steps back first.
class ShellFlowRoute extends ConsumerStatefulWidget {
  const ShellFlowRoute({super.key, required this.flow});

  final ShellFlow flow;

  @override
  ConsumerState<ShellFlowRoute> createState() => _ShellFlowRouteState();
}

class _ShellFlowRouteState extends ConsumerState<ShellFlowRoute> {
  final _sendBack = SendBack();

  void _close() => Navigator.of(context).maybePop();

  /// A payment is done: the route closes, and the next Send starts with a fresh form.
  void _done() {
    ref.read(sendRecipientProvider.notifier).clear();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final send = widget.flow == ShellFlow.send;
    final touring = ref.watch(phoneTourProvider.select((s) => s.open));
    return PopScope(
      canPop: !send && !touring,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // The tour opened this route: Back is its step back, not the route's own.
        if (touring) {
          final tour = ref.read(phoneTourProvider.notifier);
          (tour.back ?? tour.close)();
          return;
        }
        if (_sendBack.stepBack()) return;
        Navigator.of(context).pop();
      },
      child: _Backdrop(
        child: SlotScaffold(
          body: SafeArea(
            // Send draws its own header per step (close on Who, back later), as the frames do,
            // and keeps its own insets: the review's sheet runs to the screen's edge.
            top: !send,
            bottom: !send,
            child: send
                ? SendView(onDone: _done, back: _sendBack)
                : Column(
                    children: [
                      KitFlowHeader(
                        title: l.homeReceiveButton,
                        onLeading: _close,
                        leadingId: TrustIds.flowClose,
                      ),
                      const BalanceHeader(),
                      const Expanded(child: ReceiveView()),
                    ],
                  ),
          ),
        ),
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
    VoidCallback? onClose,
  }) => notices.show(
    text,
    level: level,
    action: action,
    persistent: persistent,
    progress: progress,
    progressLabel: progress == null ? null : l.updateDownloadProgressLabel,
    tag: updateNoticeTag,
    onClose: onClose,
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
      // Offered once per version: closed, it stays closed until About's Check for updates.
      if (updater.noticeDismissed(version)) {
        notices.dismissTag(updateNoticeTag);
        return;
      }
      show(
        state.text?.call(l) ?? l.updateAvailable(version),
        NoticeLevel.info,
        persistent: true,
        action: NoticeAction(l.updateInstallButton, updater.install),
        onClose: () => updater.dismissNotice(version),
      );
    case UpdatePhase.needsPermission:
      // Allow, then return: the update carries on by itself; Update asks again.
      show(
        state.text?.call(l) ?? l.updateAllowInstalls,
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

/// The recovery phrase reminder comes back on a later opening of home, at most this often.
const Duration backupNoticeEvery = Duration(days: 1);

/// The tag of the recovery phrase reminder's notice.
const String backupNoticeTag = 'backup-phrase';

/// The one notice about the changed Tor address (onion_notice.dart).
const String onionNoticeTag = 'onion-notice';

/// When the recovery phrase reminder last showed on [chain]'s wallet (milliseconds since the
/// epoch). Stored beside the vault's entries for the chain (`wallet.<chain>.*`), so deleting the
/// wallet forgets it too.
String backupNoticeKey(Chain chain) => 'wallet.${chain.name}.backupNoticeAt';

