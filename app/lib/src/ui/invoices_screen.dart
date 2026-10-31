// SPDX-License-Identifier: Apache-2.0
/// Invoices from paired contacts the user allows (I-03, RFC 0002 11): home's entry with its badge, the list, and the
/// notices for what the drains find. Paying is the review screen's, behind the PIN gate;
/// nothing here pays. The list also holds the requests this wallet sent (I-06), and home's
/// entry turns their events into notices.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import '../help/help_content.dart' show HelpAnchor;
import 'cancel_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../levels/level_features.dart' show InvoicePresence;
import '../levels/level_providers.dart' show levelFeaturesProvider;
import '../contacts.dart';
import '../cancel_final.dart';
import '../errors.dart';
import '../pairing_providers.dart';
import '../l10n.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'help_screen.dart' show HelpButton, HelpId;
import 'invoice_request_screen.dart';
import 'invoice_review_screen.dart';
import 'invoice_rows.dart';
import 'settings_invoices.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';
import 'tour/tour_target.dart';
import 'tx_details_screen.dart';

/// The most of a service's message the app shows. LEPIC caps it too; this keeps one line.
const int invoiceMessageMaxLength = 120;

/// Control, format and bidi characters: a hostile message could reorder or hide text with
/// them. LEPIC strips them before Dart sees the message; this is the second fence.
final RegExp _unsafeChars = RegExp(
  '[\u0000-\u001F\u007F-\u009F\u00AD\u061C\u180E\u200B-\u200F\u2028-\u202E'
  '\u2060-\u2069\uFEFF]',
);

/// A service's [message] as the app shows it: one line of plain text, unsafe characters
/// removed, runs of space folded, at most [invoiceMessageMaxLength] characters. Null when
/// nothing is left.
String? invoiceMessageLine(String? message) {
  if (message == null) return null;
  final line = message
      .replaceAll(_unsafeChars, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (line.isEmpty) return null;
  final chars = line.runes.toList();
  if (chars.length <= invoiceMessageMaxLength) return line;
  return '${String.fromCharCodes(chars.take(invoiceMessageMaxLength - 1))}…';
}

/// The name of the contact whose pairing sent an invoice: the address-book name, else the
/// name the contact chose. Never anything the invoice says about itself.
String invoiceSenderName(
  AppLocalizations l,
  Iterable<PairingRecord> pairings,
  Iterable<Contact> contacts,
  String? pairingId,
) {
  final r = pairings.where((p) => p.id == pairingId).firstOrNull;
  final name = r == null ? '' : pairingName(r, contacts).trim();
  return name.isEmpty ? l.invoicesUnnamedService : name;
}

/// `5 h 12 min left`, `12 min left`, or under a minute.
String invoiceTimeLeft(AppLocalizations l, Duration left) {
  if (left < const Duration(minutes: 1)) return l.invoiceTimeLeftUnderMinute;
  // Rounded up, so the last minute reads "1 min left" until it is under a minute.
  final minutes = (left.inSeconds / 60).ceil();
  if (minutes < 60) return l.invoiceTimeLeftMinutes(minutes);
  return l.invoiceTimeLeftHours(minutes ~/ 60, minutes % 60);
}

/// The key of home's Invoices button, for tests.
const Key invoicesEntryKey = ValueKey('invoices-entry');

/// Home's app bar button to the invoices, with a badge of the pending ones, when the wallet
/// handles invoices. Being on home drains the invoice address once at start
/// ([pendingInvoicesProvider]) and again when the app comes back to the front. It also turns
/// invoice events into notices; none of them pays or cancels anything. With [visible] false
/// it draws nothing and keeps all of that, so home can show the way to the invoices elsewhere.
class InvoicesEntry extends ConsumerStatefulWidget {
  const InvoicesEntry({super.key, this.visible = true});

  final bool visible;

  @override
  ConsumerState<InvoicesEntry> createState() => _InvoicesEntryState();
}

class _InvoicesEntryState extends ConsumerState<InvoicesEntry> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: _drain,
  );
  StreamSubscription<InvoiceEvent>? _events;

  @override
  void initState() {
    super.initState();
    _lifecycle;
    ref.listenManual<WalletSession?>(
      invoiceSessionProvider,
      (_, session) => _subscribe(session),
      fireImmediately: true,
    );
    ref.listenManual<IssuerNotice?>(issuerNoticeProvider, (_, notice) {
      if (notice != null) _notifyIssuer(notice.event);
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _subscribe(WalletSession? session) {
    _events?.cancel();
    _events = null;
    if (session == null || !session.supportsInvoices) return;
    _events = session.invoiceEvents().listen(_notify);
  }

  Future<void> _drain() async {
    final session = ref.read(invoiceSessionProvider);
    if (!mounted || session == null) return;
    try {
      await ref.read(pendingInvoicesProvider.notifier).refresh();
    } catch (_) {
      // The Invoices screen shows it when the user goes there.
    }
  }

  Future<void> _notify(InvoiceEvent event) async {
    final notices = ref.read(noticeProvider.notifier);
    final l = context.l10n;
    void view(String text, NoticeLevel level, VoidCallback? open) =>
        notices.show(
          text,
          level: level,
          action: open == null ? null : NoticeAction(l.homeNoticeView, open),
        );
    // Who sent it, read before the list drops it.
    final invoice = ref.read(pendingInvoicesProvider).value?.where((i) => i.slateId == event.slateId).firstOrNull;
    switch (event.kind) {
      // An open Invoices or Review screen shows it at once, not on its next visit: a new one
      // listed, an ended one gone and its Approve off.
      case InvoiceEventKind.received || InvoiceEventKind.withdrawn || InvoiceEventKind.expired || InvoiceEventKind.declined:
        ref.read(pendingInvoicesProvider.notifier).reload().ignore();
      default:
        break;
    }
    switch (event.kind) {
      case InvoiceEventKind.received:
        // Level 1 keeps invoices quiet: no notice; the invoice is a row under Recent activity.
        if (ref.read(levelFeaturesProvider).invoices == InvoicePresence.quiet) break;
        view(l.invoiceNoticeReceived, NoticeLevel.info, () => _openInvoice(event.slateId));
      case InvoiceEventKind.posted:
        view(
          l.invoiceNoticePosted,
          NoticeLevel.success,
          await _openPayment(event.slateId),
        );
      case InvoiceEventKind.withdrawn:
        final session = ref.read(sessionProvider);
        final paid = session == null
            ? null
            : await session.paidInvoice(slateId: event.slateId);
        if (!mounted) return;
        if (paid == null) {
          // The sender by name, a person as much as a service.
          view(
            invoice == null
                ? l.invoiceNoticeWithdrawn
                : l.deskInvNoticeWithdrawn(
                    invoiceSenderName(l, ref.read(pairingsProvider).value ?? const [], ref.read(contactsProvider).value ?? const [], invoice.pairingId),
                  ),
            NoticeLevel.info,
            null,
          );
        } else {
          // Cancel, which asks first, while the payment can still be cancelled; else the way
          // to its details.
          final tx = await _findPayment(event.slateId);
          if (!mounted) return;
          notices.show(
            l.invoiceNoticeWithdrawnPaid,
            level: NoticeLevel.warning,
            action: tx == null
                ? null
                : tx.cancellable && tx.id != null
                ? NoticeAction(
                    l.txDetailsCancelPayment,
                    () => _cancelPayment(tx),
                  )
                : NoticeAction(l.homeNoticeView, _detailsOf(tx.key)),
          );
        }
      case InvoiceEventKind.expired:
        view(l.invoiceNoticeExpired, NoticeLevel.info, null);
      case InvoiceEventKind.declined:
        // The review screen says so itself.
        break;
      // Unverified (anyone can raise it): a notice only, naming no one.
      case InvoiceEventKind.unknownInvoicePayment:
        view(l.deskInvNoticeUnknownPayment, NoticeLevel.warning, null);
      case InvoiceEventKind.unknownSendAnswer:
        view(l.deskInvNoticeUnknownAnswer, NoticeLevel.warning, null);
      case InvoiceEventKind.receiveSuperseded:
        view(l.deskInvNoticeReceiveSuperseded, NoticeLevel.info, null);
      // Not an invoice: home words it (paymentPostedProvider, paymentCancelledProvider).
      case InvoiceEventKind.paymentPosted || InvoiceEventKind.paymentCancelled:
        break;
    }
  }

  /// What happened to a request this wallet sent, as a notice. None of them pays anything.
  void _notifyIssuer(IssuerEvent event) {
    if (!mounted) return;
    final l = context.l10n;
    final notices = ref.read(noticeProvider.notifier);
    final view = NoticeAction(
      l.homeNoticeView,
      _detailsOf('s:${event.slateId}'),
    );
    switch (event.kind) {
      case IssuerEventKind.paid:
        notices.show(
          l.issuerNoticePaid,
          level: NoticeLevel.success,
          action: view,
        );
      case IssuerEventKind.declined:
        notices.show(
          l.issuerNoticeDeclined,
          level: NoticeLevel.warning,
          action: view,
        );
      case IssuerEventKind.withdrawn:
        // The user withdrew it a moment ago; nothing to open.
        notices.show(l.issuerNoticeWithdrawn, level: NoticeLevel.warning);
      case IssuerEventKind.expired:
        notices.show(
          l.issuerNoticeExpired,
          level: NoticeLevel.info,
          action: view,
        );
      case IssuerEventKind.bounced:
        // Named, so the user knows whom to ask for a payment file.
        final payer = payerName(
          ref.read(contactsProvider).value ?? const <Contact>[],
          event.payerAddress ?? '',
          paired: event.pairingId == null ? null : ref.read(pairingNameProvider(event.pairingId!)),
        );
        notices.show(
          l.issuerNoticeBouncedFrom(payer),
          level: NoticeLevel.warning,
          action: view,
        );
    }
  }

  void _openInvoices() {
    // The notice outlives home: a lock replaces it with the unlock screen.
    if (!mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const InvoicesScreen()));
  }

  /// The invoice [slateId] to review, from the fresh list; the list when it is not in it.
  Future<void> _openInvoice(String slateId) async {
    // The notice outlives home: a lock replaces it with the unlock screen.
    if (!mounted) return;
    List<PendingInvoice> list = const [];
    try {
      list = await ref.read(pendingInvoicesProvider.future);
    } catch (_) {
      // The list says why.
    }
    if (!mounted) return;
    final invoice = list.where((i) => i.slateId == slateId).firstOrNull;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => invoice == null ? const InvoicesScreen() : InvoiceReviewScreen(invoice: invoice)),
    );
  }

  /// The payment of [slateId] in home's list, reloaded once when the list lacks it.
  Future<TxEntry?> _findPayment(String slateId) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (attempt > 0) ref.invalidate(homeProvider);
        final data = await ref.read(homeProvider.future);
        final tx = data.transactions
            .where((t) => t.slateId == slateId)
            .firstOrNull;
        if (tx != null) return tx;
      } catch (_) {
        // Worded without the payment.
      }
      if (!mounted) return null;
    }
    return null;
  }

  VoidCallback _detailsOf(String key) => () {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: key)),
    );
  };

  /// A way to the payment of [slateId] once home's list has it, else null.
  Future<VoidCallback?> _openPayment(String slateId) async {
    final tx = await _findPayment(slateId);
    return tx == null ? null : _detailsOf(tx.key);
  }

  /// Cancels [tx] after the same confirm the details screen asks, never without it.
  Future<void> _cancelPayment(TxEntry tx) async {
    final id = tx.id;
    if (!mounted || id == null) return;
    // The payment of an invoice: its issuer holds a copy it can finish, so the user picks
    // Cancel for sure (the coins spent back, for a fee) or the free Stop waiting (cancel_dialog.dart).
    final choice = await showCancelChoices(
      context,
      title: context.l10n.txDetailsCancelTitle,
      body: context.l10n.txDetailsCancelRequestBody,
      anchor: HelpAnchor.requests,
      keepLabel: context.l10n.txDetailsCancelKeep,
    );
    if (!choice.cancels || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final l = context.l10n;
    final notices = ref.read(noticeProvider.notifier);
    try {
      final result = await ref.read(cancelFinalProvider).cancel(session, tx, spendBack: choice.spendBack);
      logInfo('invoices', 'payment of a withdrawn invoice cancelled: ${result.name}');
      notices.show(
        switch (result) {
          CancelResult.cancelled => l.txDetailsPaymentCancelled,
          CancelResult.spentBack || CancelResult.spendBackPending => l.txDetailsPaymentCancelled,
          CancelResult.stoppedWaiting => l.txDetailsStoppedWaiting,
          CancelResult.alreadyPaid => l.errorPaymentAlreadyWentThrough,
        },
        level: switch (result) {
          CancelResult.spendBackPending || CancelResult.stoppedWaiting || CancelResult.alreadyPaid => NoticeLevel.info,
          _ => NoticeLevel.success,
        },
      );
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
    }
    ref.invalidate(homeProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Invoices off (Settings › Advanced) or none on this core: no entry, nothing drained.
    final session = ref.watch(invoiceSessionProvider);
    if (session == null) {
      return const SizedBox.shrink();
    }
    // Watched even when hidden: it is what drains the invoice address at start.
    final count = ref.watch(pendingInvoiceCountProvider);
    if (!widget.visible) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      key: invoicesEntryKey,
      tooltip: context.l10n.invoicesEntryTooltip(count),
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        backgroundColor: scheme.primary,
        textColor: scheme.onPrimary,
        child: const Icon(Icons.receipt_long_outlined),
      ),
      onPressed: _openInvoices,
    );
  }
}

/// The two halves of the Invoices screen.
enum InvoicesSegment { toPay, sent }

/// Keys of the Invoices screen, for tests.
const Key invoicesSegmentsKey = ValueKey('invoices-segments');
const Key invoicesNewRequestKey = ValueKey('invoices-new-request');

/// Invoices to pay, oldest first, and the requests this wallet sent, under two segments with
/// live counts. Opening it and pulling down drain the invoice and payments addresses; the
/// progress line shows for the first load only. With [segment], it opens on that half;
/// otherwise on To pay, or on Sent while there is nothing to pay and something sent.
class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key, this.segment});

  final InvoicesSegment? segment;

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  /// Keeps the time left current; the list changes it by the minute.
  late final Timer _tick = Timer.periodic(
    const Duration(seconds: 30),
    (_) => setState(() {}),
  );

  /// The user's choice, once they made one.
  late InvoicesSegment? _segment = widget.segment;

  @override
  void initState() {
    super.initState();
    _tick;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    // Payments for requests this wallet sent come to the payments address.
    unawaited(ref.read(paymentsDrainProvider.notifier).drain());
    try {
      await ref.read(pendingInvoicesProvider.notifier).refresh();
    } catch (_) {
      // The error line shows it.
    }
  }

  void _newRequest() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const InvoiceRequestScreen()));

  void _pairedContacts() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const InvoiceSettingsScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final invoices = ref.watch(pendingInvoicesProvider);
    final pairings = ref.watch(pairingsProvider).value ?? const <PairingRecord>[];
    final now = ref.watch(invoiceClockProvider)();
    final hidden = amountDisplay(ref).hidden;
    final toPay = [
      for (final i in invoices.value ?? const <PendingInvoice>[])
        if (!i.isExpiredAt(now)) i,
    ];
    final requests =
        ref.watch(issuedInvoicesProvider).value ?? const <IssuedInvoice>[];
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final segment =
        _segment ??
        (toPay.isEmpty && requests.isNotEmpty
            ? InvoicesSegment.sent
            : InvoicesSegment.toPay);
    // The label beside the icon where it fits at this text size, else the icon alone.
    final roomy = MediaQuery.textScalerOf(context).scale(14) <= 18;

    Widget emptyState({
      required IconData icon,
      required String title,
      required String? caption,
      required String action,
      required VoidCallback onAction,
    }) => EmptyState(
      icon: Icon(icon),
      message: title,
      action: Column(
        children: [
          if (caption != null) ...[
            Text(
              caption,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: t.dim),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: onAction,
            child: Text(action),
          ),
        ],
      ),
    );

    final List<Widget> rows = switch (segment) {
      InvoicesSegment.toPay when invoices.hasValue && toPay.isEmpty => [
        emptyState(
          icon: Icons.receipt_long_outlined,
          title: l.invoicesEmpty,
          caption: null,
          action: l.invoicesEmptyAction,
          onAction: _pairedContacts,
        ),
      ],
      InvoicesSegment.toPay => [
        for (final invoice in toPay)
          InvoiceRow(
            invoice: invoice,
            service: invoiceSenderName(l, pairings, contacts, invoice.pairingId),
            left: invoice.timeLeftAt(now),
            amount: shownEpic(l, invoice.amount, hidden: hidden),
          ),
      ],
      InvoicesSegment.sent when requests.isEmpty => [
        emptyState(
          icon: Icons.call_received,
          title: l.invoicesSentEmpty,
          caption: l.invoicesSentEmptyCaption,
          action: l.invoicesNewRequest,
          onAction: _newRequest,
        ),
      ],
      InvoicesSegment.sent => [
        for (final request in requests)
          RequestRow(
            request: request,
            payer: request.byFile
                ? l.reqByFile
                : payerName(
                    contacts,
                    request.payerAddress,
                    paired: request.pairingId == null ? null : ref.watch(pairingNameProvider(request.pairingId!)),
                  ),
            left: request.timeLeftAt(now),
            amount: shownEpic(l, request.amount, hidden: hidden),
          ),
      ],
    };

    ButtonSegment<InvoicesSegment> segmentOf(
      InvoicesSegment value,
      String label,
      int count,
    ) => ButtonSegment(
      value: value,
      label: Semantics(
        label: l.invoicesSegmentCount(label, count),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 6),
            Text(
              localInt(l, count),
              style: TextStyle(fontFamily: t.monoFamily, fontSize: 13),
            ),
          ],
        ),
      ),
    );

    return SlotScaffold(
      appBar: AppBar(
        title: Text(l.invoicesTitle),
        actions: [
          if (roomy)
            TextButton.icon(
              key: invoicesNewRequestKey,
              style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
              icon: const Icon(Icons.add),
              label: Text(l.invoicesNewRequest),
              onPressed: _newRequest,
            )
          else
            IconButton(
              key: invoicesNewRequestKey,
              tooltip: l.invoicesNewRequest,
              icon: const Icon(Icons.add),
              onPressed: _newRequest,
            ),
          const HelpButton(HelpId.invoices),
          const SizedBox(width: 8),
        ],
      ),
      // The first load only; a refresh after it keeps the list as it is.
      idle: invoices.isLoading && !invoices.hasValue
          ? SlotProgress(label: l.invoicesChecking)
          : null,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: PhoneTourTarget(
                    id: 'tour-invoices-tabs',
                    child: SegmentedButton<InvoicesSegment>(
                    key: invoicesSegmentsKey,
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    segments: [
                      segmentOf(
                        InvoicesSegment.toPay,
                        l.invoicesToPaySection,
                        toPay.length,
                      ),
                      segmentOf(
                        InvoicesSegment.sent,
                        l.invoicesSegmentSent,
                        requests.length,
                      ),
                    ],
                    selected: {segment},
                    onSelectionChanged: (s) =>
                        setState(() => _segment = s.first),
                  ),
                  ),
                ),
                if (invoices.hasError && !invoices.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ErrorText(describeError(l, invoices.error!)),
                        ),
                        TextButton(
                          onPressed: _refresh,
                          child: Text(l.commonRetry),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      // Pull to refresh works on an empty list too.
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 16),
                      children: rows,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
