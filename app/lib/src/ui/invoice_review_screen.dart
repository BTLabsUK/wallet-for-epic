/// One invoice, approved or declined (I-03), and the invoice part of a paid payment's details.
/// The one caller of `payInvoice` in the app: Approve asks for the PIN (or its biometric
/// copy) first, every time.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../l10n.dart';
import '../amount.dart';
import '../providers.dart';
import '../send_preflight.dart';
import '../settings.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'invoice_rows.dart';
import 'invoices_screen.dart';
import 'pin.dart';
import 'theme/brand.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';

/// Asks for the PIN of the open wallet (or its biometric copy) before an invoice is paid.
/// True once it checked out; false when the user cancelled.
Future<bool> _invoiceGate(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  final config = ref.read(walletConfigProvider);
  if (session == null || config == null) return false;
  final vault = ref.read(vaultProvider);
  final approved = await askPin(
    context,
    reason: context.l10n.invoicePinReason,
    action: (pin) async {
      await vault.checkPin(session, config, pin);
      return true;
    },
  );
  return approved == true;
}

/// The amount large, the service by the user's own label, the time left counting down, and
/// the service's message as one plain line. Approve and Decline at the foot.
class InvoiceReviewScreen extends ConsumerStatefulWidget {
  const InvoiceReviewScreen({super.key, required this.invoice});

  final PendingInvoice invoice;

  @override
  ConsumerState<InvoiceReviewScreen> createState() =>
      _InvoiceReviewScreenState();
}

class _InvoiceReviewScreenState extends ConsumerState<InvoiceReviewScreen> {
  late final Timer _tick = Timer.periodic(
    const Duration(seconds: 1),
    (_) => setState(() {}),
  );
  bool _busy = false;

  /// Set once the user approved and the payment is signed but its reply did not get through.
  PaidInvoice? _unsent;

  PendingInvoice get _invoice => widget.invoice;

  @override
  void initState() {
    super.initState();
    _tick;
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  void _say(String text, NoticeLevel level) => ref
      .read(noticeProvider.notifier)
      .show(text, level: level, tag: _invoiceTag(_invoice.slateId));

  String _service() => invoiceServiceName(
    context.l10n,
    ref.read(trustedServicesProvider).value ?? const [],
    _invoice.senderAddress,
  );

  Future<void> _approve() async {
    final l = context.l10n;
    final service = _service();
    final container = ProviderScope.containerOf(context, listen: false);
    // The gate first, every time: nothing below runs without it.
    if (!await _invoiceGate(context, ref) || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    // The time may have run out, or the service withdrawn it, while the PIN was asked.
    final pending = ref.read(pendingInvoicesProvider).value;
    if (_invoice.isExpiredAt(ref.read(invoiceClockProvider)()) ||
        (pending != null &&
            !pending.any((i) => i.slateId == _invoice.slateId))) {
      setState(() {});
      return;
    }
    setState(() => _busy = true);
    try {
      // A slow payment must not lock the wallet under the user and lose the Retry.
      final paid = await ref
          .read(autoLockHoldProvider.notifier)
          .during(
            () => session.payInvoice(
              slateId: _invoice.slateId,
              amount: _invoice.amount,
            ),
          );
      container.read(pendingInvoicesProvider.notifier).answered(paid.slateId);
      container
        ..invalidate(homeProvider)
        ..invalidate(paidInvoiceProvider(paid.slateId));
      if (paid.status == InvoiceStatus.replyFailed) {
        logWarn('invoices', 'an approved invoice reply was not delivered');
        if (mounted) setState(() => _unsent = paid);
        _say(l.invoiceReplyFailedNotice, NoticeLevel.error);
        return;
      }
      logInfo('invoices', 'invoice paid');
      _say(l.invoicePaidNotice(service), NoticeLevel.success);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      _say(describeError(l, error), NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retry() async {
    final l = context.l10n;
    final service = _service();
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy = true);
    try {
      final paid = await resendInvoiceReply(ref, _invoice.slateId);
      container.invalidate(paidInvoiceProvider(paid.slateId));
      if (paid.status == InvoiceStatus.replyFailed) {
        _say(l.invoiceReplyFailedNotice, NoticeLevel.error);
        return;
      }
      _say(l.invoicePaidNotice(service), NoticeLevel.success);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      _say(describeError(l, error), NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    final l = context.l10n;
    final service = _service();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.invoiceDeclineTitle),
        content: Text(l.invoiceDeclineBody(service)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.invoiceDeclineKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.invoiceDecline),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy = true);
    try {
      await session.declineInvoice(slateId: _invoice.slateId);
      logInfo('invoices', 'invoice declined');
      container
          .read(pendingInvoicesProvider.notifier)
          .answered(_invoice.slateId);
      _say(l.invoiceDeclinedNotice, NoticeLevel.success);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      _say(describeError(l, error), NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final services =
        ref.watch(trustedServicesProvider).value ?? const <TrustedService>[];
    final service = invoiceServiceName(l, services, _invoice.senderAddress);
    final pending = ref.watch(pendingInvoicesProvider).value;
    final now = ref.watch(invoiceClockProvider)();
    final unsent = _unsent;
    final expired = unsent == null && _invoice.isExpiredAt(now);
    // Withdrawn by the service, or answered elsewhere, while this screen was open.
    final gone =
        unsent == null &&
        !expired &&
        pending != null &&
        !pending.any((i) => i.slateId == _invoice.slateId);
    final display = amountDisplay(ref);
    final spendable = ref.watch(homeProvider).value?.summary.spendable;
    // The wallet adds the fee; this catches what cannot be paid at all.
    final short =
        unsent == null && spendable != null && _invoice.amount > spendable
        ? _invoice.amount - spendable
        : null;
    final canAnswer = unsent == null && !expired && !gone && !_busy;
    // The amount shows even with balances hidden: nobody approves what they cannot see.
    final fiat = approxFiat(l, _invoice.amount, (
      hidden: false,
      price: display.price,
      currency: display.currency,
    ));
    final message = invoiceMessageLine(_invoice.message);
    final mono = TextStyle(
      fontFamily: t.monoFamily,
      fontSize: 13,
      color: t.text,
    );

    final Widget bottom = unsent != null
        ? BusyButton(label: l.invoiceRetry, busy: _busy, onPressed: _retry)
        : Row(
            children: [
              Expanded(
                child: BusyButton(
                  label: l.invoiceApprove,
                  busy: _busy,
                  onPressed: canAnswer && short == null ? _approve : null,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: canAnswer ? _decline : null,
                child: Text(l.invoiceDecline),
              ),
            ],
          );

    final Widget expiry = expired || gone
        ? Row(
            children: [
              Icon(Icons.timer_off_outlined, size: 18, color: t.warn),
              const SizedBox(width: 6),
              Expanded(child: Text(expired ? l.invoiceExpired : l.invoiceGone)),
            ],
          )
        : Wrap(
            spacing: 6,
            children: [
              Text(
                invoiceTimeLeft(l, _invoice.timeLeftAt(now)),
                style: TextStyle(
                  color: _invoice.timeLeftAt(now) < invoiceWarnUnder
                      ? t.warn
                      : t.text,
                ),
              ),
              Text(
                l.invoicesUntil(localClock(l, _invoice.expiresAt)),
                style: TextStyle(color: t.dim),
              ),
            ],
          );

    return SlotScaffold(
      appBar: AppBar(title: Text(l.invoiceReviewTitle)),
      idle: _busy ? SlotProgress(label: l.invoiceReviewTitle) : null,
      body: ScreenBody(
        bottom: bottom,
        children: [
          // The service, by the user's own label; its key shortened, never the relay's name.
          Row(
            children: [
              const GlyphTile(
                size: 40,
                child: Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        service,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _shortKey(_invoice.senderAddress),
                      style: mono.copyWith(color: t.dim),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ReviewAmount(amount: _invoice.amount),
          if (fiat != null)
            Text(
              fiat,
              style: theme.textTheme.titleMedium?.copyWith(color: t.dim),
            ),
          const SizedBox(height: 20),
          _Fact(label: l.invoicesExpires, child: expiry),
          if (message != null)
            // Hostile text: plain, its controls and line breaks gone, never a link.
            _Fact(label: l.invoicesMessage, child: Text(message, maxLines: 3)),
          _Fact(
            label: l.invoicesFrom,
            child: _AddressText(_invoice.senderAddress, style: mono),
          ),
          if (unsent == null)
            _Fact(
              label: l.invoicesPaysFrom,
              child: Text(
                l.invoicesAvailable(
                  spendable == null
                      ? '…'
                      : shownEpic(l, spendable, hidden: display.hidden),
                ),
              ),
            ),
          if (unsent == null && !expired && !gone) ...[
            const SizedBox(height: 8),
            const _Checks(),
          ],
          if (short != null && canAnswer) ...[
            const SizedBox(height: 16),
            EdgeCard(
              edge: t.risk,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(l.invoicesShort(epicExact(l, short))),
                ),
              ),
            ),
          ],
          if (unsent != null) ...[
            const SizedBox(height: 16),
            EdgeCard(
              edge: t.warn,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.invoiceReplyFailedTitle(service),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(l.invoiceReplyFailedBody),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The key of [address], shortened, without its relay.
String _shortKey(String address) {
  final at = address.indexOf('@');
  return shortAddress(at < 0 ? address : address.substring(0, at));
}

/// The invoice's amount in the display face at 34, with every decimal, and a small gold
/// EPIC after it.
class _ReviewAmount extends StatelessWidget {
  const _ReviewAmount({required this.amount});

  final BigInt amount;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Semantics(
      label: epicExact(l, amount),
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              localDigits(l, formatEpic(amount, grouped: true)),
              key: invoiceReviewAmountKey,
              maxLines: 1,
              style: TextStyle(
                fontFamily: t.headFamily,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: t.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'EPIC',
              style: TextStyle(
                fontFamily: t.headFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.accentText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The key of the review's amount, for tests.
const Key invoiceReviewAmountKey = ValueKey('invoice-review-amount');

/// One fact of the review: the label in a narrow column, the value beside it.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: TextStyle(color: t.dim)),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// A whole address, wrapping, the relay part dim.
class _AddressText extends StatelessWidget {
  const _AddressText(this.address, {required this.style});

  final String address;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final at = address.indexOf('@');
    return SelectableText.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: at < 0 ? address : address.substring(0, at)),
          if (at >= 0)
            TextSpan(
              text: address.substring(at),
              style: TextStyle(color: context.tokens.dim),
            ),
        ],
      ),
    );
  }
}

/// What paying needs, checked as the review opens: the node answers, and the epicbox
/// listener is connected, as Send's review does. They inform; nothing here blocks Approve.
class _Checks extends ConsumerWidget {
  const _Checks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final node = ref.watch(sendNodeCheckProvider);
    final listener = ref.watch(listenerProvider);
    Widget check(
      String label,
      Widget mark,
      String word, {
      VoidCallback? retry,
    }) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32),
      child: Row(
        children: [
          SizedBox(width: 20, child: mark),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: t.dim)),
          const SizedBox(width: 8),
          Expanded(child: Text(word)),
          if (retry != null)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: retry,
              child: Text(l.commonRetry),
            ),
        ],
      ),
    );
    final ok = Icon(Icons.check, size: 18, color: t.ok);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (node) {
          AsyncValue(isLoading: true) => check(
            l.invoicesCheckNode,
            const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            l.sendChecking,
          ),
          AsyncValue(hasError: true) => check(
            l.invoicesCheckNode,
            Icon(Icons.error_outline, size: 18, color: t.risk),
            l.invoicesNodeDown,
            retry: () => ref.invalidate(sendNodeCheckProvider),
          ),
          _ => check(l.invoicesCheckNode, ok, l.invoicesNodeOk),
        },
        listener.connected
            ? check(l.invoicesCheckEpicbox, ok, l.invoicesEpicboxOk)
            : check(
                l.invoicesCheckEpicbox,
                Icon(Icons.sync_problem, size: 18, color: t.warn),
                l.invoicesEpicboxDown,
              ),
      ],
    );
  }
}

/// One notice per invoice: a Retry that works replaces the failure it fixes.
String _invoiceTag(String slateId) => 'invoice-$slateId';

/// Sends the stored reply of a paid invoice again. Signs nothing, so it asks for no PIN: the
/// user's approval stands.
Future<PaidInvoice> resendInvoiceReply(WidgetRef ref, String slateId) async {
  final session = ref.read(sessionProvider);
  if (session == null) throw StateError('Wallet is locked');
  final paid = await ref
      .read(autoLockHoldProvider.notifier)
      .during(() => session.resendInvoiceReply(slateId: slateId));
  logInfo('invoices', 'invoice reply sent again');
  return paid;
}

/// The invoice part of a payment's details, when the payment paid one: the service by its
/// label, its message, and what the service reports. A withdrawal after payment shows a
/// warning with [onCancel], which confirms before it cancels. Nothing when [tx] paid no
/// invoice or the wallet has no invoices.
class PaidInvoiceBlock extends ConsumerStatefulWidget {
  const PaidInvoiceBlock({super.key, required this.tx, this.onCancel});

  final TxEntry tx;

  /// The details screen's cancel, which asks the user first. Null while it is busy.
  final VoidCallback? onCancel;

  @override
  ConsumerState<PaidInvoiceBlock> createState() => _PaidInvoiceBlockState();
}

class _PaidInvoiceBlockState extends ConsumerState<PaidInvoiceBlock> {
  bool _busy = false;

  Future<void> _retry(PaidInvoice paid, String service) async {
    final l = context.l10n;
    final notices = ref.read(noticeProvider.notifier);
    setState(() => _busy = true);
    try {
      final resent = await resendInvoiceReply(ref, paid.slateId);
      ref.invalidate(paidInvoiceProvider(paid.slateId));
      if (resent.status == InvoiceStatus.replyFailed) {
        notices.show(
          l.invoiceReplyFailedNotice,
          level: NoticeLevel.error,
          tag: _invoiceTag(paid.slateId),
        );
      } else {
        notices.show(
          l.invoicePaidNotice(service),
          level: NoticeLevel.success,
          tag: _invoiceTag(paid.slateId),
        );
      }
    } catch (error) {
      notices.show(
        describeError(l, error),
        level: NoticeLevel.error,
        tag: _invoiceTag(paid.slateId),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slateId = widget.tx.slateId;
    if (slateId == null) return const SizedBox.shrink();
    final paid = ref.watch(paidInvoiceProvider(slateId)).value;
    if (paid == null) return const SizedBox.shrink();
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final services =
        ref.watch(trustedServicesProvider).value ?? const <TrustedService>[];
    final service = invoiceServiceName(l, services, paid.senderAddress);
    final message = invoiceMessageLine(paid.message);

    Widget warning(String text, Widget? action) => EdgeCard(
      edge: t.warn,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: t.warn),
                const SizedBox(width: 8),
                Expanded(child: Text(text)),
              ],
            ),
            if (action != null)
              Align(alignment: AlignmentDirectional.centerEnd, child: action)
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );

    final status = switch (paid.status) {
      // Still waiting: the service may never have got the reply (linux-12). Send again
      // delivers the stored one; Cancel comes once the payment's time runs out.
      InvoiceStatus.replied
          when widget.tx.status == TxStatus.awaitingRecipient =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.invoiceDetailsReplied(service)),
            const SizedBox(height: 8),
            Text(l.invoiceDetailsRepliedHelp(service), style: theme.textTheme.bodySmall),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                icon: const Icon(Icons.send_outlined),
                label: Text(l.txDetailsSendAgain),
                onPressed: _busy ? null : () => _retry(paid, service),
              ),
            ),
          ],
        ),
      InvoiceStatus.replied => Text(l.invoiceDetailsReplied(service)),
      InvoiceStatus.posted => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: t.ok, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(l.invoiceDetailsPosted(service))),
        ],
      ),
      InvoiceStatus.replyFailed => warning(
        l.invoiceDetailsReplyFailed(service),
        TextButton.icon(
          icon: const Icon(Icons.send_outlined),
          label: Text(l.invoiceRetry),
          onPressed: _busy ? null : () => _retry(paid, service),
        ),
      ),
      InvoiceStatus.withdrawn => warning(
        l.invoiceDetailsWithdrawn(service),
        widget.tx.cancellable && widget.onCancel != null
            ? OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: Text(l.txDetailsCancelPayment),
                onPressed: widget.onCancel,
              )
            : null,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProtocolSectionHead(l.invoiceDetailsSection),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l.invoiceDetailsService,
              style: theme.textTheme.labelLarge,
            ),
            subtitle: Text(service),
          ),
          if (message != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l.invoiceReviewMessageLabel,
                style: theme.textTheme.labelLarge,
              ),
              // Hostile text: one plain line, never a link.
              subtitle: Text(
                message,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          status,
        ],
      ),
    );
  }
}
