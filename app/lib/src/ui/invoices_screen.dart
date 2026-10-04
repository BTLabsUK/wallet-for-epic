/// Invoices from trusted services (I-03): home's entry with its badge, the list, and the
/// notices for what the drains find. Paying is the review screen's, behind the PIN gate;
/// nothing here pays.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'invoice_review_screen.dart';
import 'theme/brand.dart';
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

/// The service's name as the user gave it, matched on the sender's key. Never anything the
/// invoice says about itself, and never the relay part of the address.
String invoiceServiceName(
  AppLocalizations l,
  List<TrustedService> services,
  String senderAddress,
) {
  final label = serviceLabel(services, senderAddress)?.trim();
  return label == null || label.isEmpty ? l.invoicesUnnamedService : label;
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
/// invoice events into notices; none of them pays or cancels anything.
class InvoicesEntry extends ConsumerStatefulWidget {
  const InvoicesEntry({super.key});

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
      sessionProvider,
      (_, session) => _subscribe(session),
      fireImmediately: true,
    );
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
    final session = ref.read(sessionProvider);
    if (!mounted || session == null || !session.supportsInvoices) return;
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
    switch (event.kind) {
      case InvoiceEventKind.received:
        view(l.invoiceNoticeReceived, NoticeLevel.info, _openInvoices);
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
          view(l.invoiceNoticeWithdrawn, NoticeLevel.info, null);
        } else {
          // The payment's details carry the Cancel the user may confirm.
          view(
            l.invoiceNoticeWithdrawnPaid,
            NoticeLevel.warning,
            await _openPayment(event.slateId),
          );
        }
      case InvoiceEventKind.expired:
        view(l.invoiceNoticeExpired, NoticeLevel.info, null);
      case InvoiceEventKind.declined:
        // The review screen says so itself.
        break;
    }
  }

  void _openInvoices() {
    // The notice outlives home: a lock replaces it with the unlock screen.
    if (!mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const InvoicesScreen()));
  }

  /// A way to the payment of [slateId] once home's list has it, else null.
  Future<VoidCallback?> _openPayment(String slateId) async {
    TxEntry? tx;
    try {
      final data = await ref.read(homeProvider.future);
      tx = data.transactions.where((t) => t.slateId == slateId).firstOrNull;
    } catch (_) {
      // Worded without the payment.
    }
    final key = tx?.key;
    if (key == null) return null;
    return () {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: key)),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null || !session.supportsInvoices) {
      return const SizedBox.shrink();
    }
    final count = ref.watch(pendingInvoiceCountProvider);
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

/// Pending invoices, oldest first, each with its service, amount and time left. Opening it
/// and pulling down drain the invoice address.
class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  /// Keeps the time left current; the list changes it by the minute.
  late final Timer _tick = Timer.periodic(
    const Duration(seconds: 30),
    (_) => setState(() {}),
  );

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
    try {
      await ref.read(pendingInvoicesProvider.notifier).refresh();
    } catch (_) {
      // The error line shows it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final invoices = ref.watch(pendingInvoicesProvider);
    final services =
        ref.watch(trustedServicesProvider).value ?? const <TrustedService>[];
    final now = ref.watch(invoiceClockProvider)();
    final hidden = amountDisplay(ref).hidden;
    final list = invoices.value;
    return SlotScaffold(
      appBar: AppBar(title: Text(l.invoicesTitle)),
      idle: invoices.isLoading ? SlotProgress(label: l.invoicesChecking) : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                // Pull to refresh works on an empty list too.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (invoices.hasError && !invoices.isLoading)
                    ErrorText(describeError(l, invoices.error!)),
                  if (list != null && list.isEmpty)
                    EmptyState(
                      icon: const Icon(Icons.receipt_long_outlined),
                      message: l.invoicesEmpty,
                    ),
                  for (final invoice in list ?? const <PendingInvoice>[])
                    _InvoiceTile(
                      invoice: invoice,
                      service: invoiceServiceName(
                        l,
                        services,
                        invoice.senderAddress,
                      ),
                      timeLeft: invoiceTimeLeft(l, invoice.timeLeftAt(now)),
                      amount: shownEpic(l, invoice.amount, hidden: hidden),
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

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({
    required this.invoice,
    required this.service,
    required this.timeLeft,
    required this.amount,
  });

  final PendingInvoice invoice;
  final String service;
  final String timeLeft;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(service, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(timeLeft),
        trailing: Text(amount, style: theme.textTheme.titleMedium),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => InvoiceReviewScreen(invoice: invoice),
          ),
        ),
      ),
    );
  }
}
