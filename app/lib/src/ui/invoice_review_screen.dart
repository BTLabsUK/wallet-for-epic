// SPDX-License-Identifier: Apache-2.0
/// One invoice, approved or declined (I-03), and the invoice part of a paid payment's details.
/// The one caller of `payInvoice` in the app: Approve asks for the PIN (or its biometric
/// copy) first, every time.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../contacts.dart' show contactsProvider;
import '../errors.dart';
import '../l10n.dart';
import '../network_gate.dart';
import '../pairing_providers.dart';
import '../amount.dart';
import '../providers.dart';
import '../send_preflight.dart';
import '../settings.dart';
import '../slate_files.dart' show responseFileName, sealedFileName;
import '../stall_retry.dart' show invoicePaymentStalled;
import '../wallet_service.dart';
import 'common.dart';
import 'invoice_rows.dart';
import 'invoices_screen.dart';
import 'net_block.dart';
import 'pairing/pairing_parts.dart';
import 'pin.dart';
import 'qr_show_screen.dart' show QrShowDone, showPaidReplyQr;
import 'slate_file_screen.dart' show SlateFileResult;
import 'theme/brand.dart' show GlyphTile;
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
    reason: usesPassphrase(ref) ? context.l10n.invoicePassphraseReason : context.l10n.invoicePinReason,
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

  String _service() => invoiceSenderName(
    context.l10n,
    ref.read(pairingsProvider).value ?? const [],
    ref.read(contactsProvider).value ?? const [],
    _invoice.pairingId,
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
    final pairing = _invoice.pairingId == null ? null : ref.watch(pairingByIdProvider(_invoice.pairingId!));
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final service = invoiceSenderName(l, ref.watch(pairingsProvider).value ?? const [], contacts, _invoice.pairingId);
    // A name the contact chose, not the user's own, is marked as its claim.
    final claimed = pairing != null && !contacts.any((c) => c.id == pairing.contactId);
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
    // Approving, declining and sending again all answer over the network.
    final block = watchNetBlock(context, ref);
    final canAnswer =
        unsent == null && !expired && !gone && !_busy && block == NetBlock.none;
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
        ? BusyButton(
            label: l.invoiceRetry,
            busy: _busy,
            onPressed: block == NetBlock.none ? _retry : null,
          )
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
      appBar: AppBar(title: Text(l.reqTitle)),
      idle: _busy ? SlotProgress(label: l.reqTitle) : null,
      body: ScreenBody(
        bottom: block == NetBlock.none
            ? bottom
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [NetBlockNote(block), bottom],
              ),
        children: [
          // The contact, by the user's own name for it; its key shortened, never the relay's
          // name. Sealed: it came through the contact's mailbox, sealed and signed.
          Row(
            children: [
              PairAvatar(name: service, kind: pairing?.kind ?? PairingParty.person, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l.reqRequests(service),
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (pairing != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 2),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [const SealedBadge(), TrustBadge(pairing), if (claimed) const ClaimedNameBadge()],
                        ),
                      ),
                    // A contact's request names the contact; its mailbox is never shown as an
                    // address (RFC C-21).
                    if (pairing == null)
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
          ReviewAmount(amount: _invoice.amount),
          if (fiat != null)
            Text(
              fiat,
              style: theme.textTheme.titleMedium?.copyWith(color: t.dim),
            ),
          const SizedBox(height: 20),
          _Fact(label: l.invoicesExpires, child: expiry),
          if (invoiceMessageLine(_invoice.reference) case final reference?)
            // The contact's own words for it, as untrusted as the message.
            _Fact(label: l.reqReference, child: Text(reference, maxLines: 2)),
          if (message != null)
            // Hostile text: plain, its controls and line breaks gone, never a link.
            _Fact(
              label: l.invoicesMessage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    l.deskInvPayerMessageCaption(service),
                    style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                  ),
                ],
              ),
            ),
          if (pairing == null)
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

/// A refusal of a payment request file or its answer, worded for the screens (DESIGN §3.3,
/// §3.4); null for any other failure. LEPIC ends an unpaid file request after its expiry.
///
/// A request [scanned] from a QR says more: it expired, or its time limit does not fit this
/// network (a code made on another network, or a clock far off).
String Function(AppLocalizations l)? requestFileRefusal(Object error, {bool scanned = false}) => switch (error) {
  WalletError(kind: WalletErrorKind.invoiceAlreadyPaid) => (l) => l.reqFileAlreadyPaid,
  WalletError(kind: WalletErrorKind.invoiceNotForThisChain) => (l) => l.reqOtherChain,
  WalletError(kind: WalletErrorKind.paymentExpired) when scanned => (l) => l.reqExpired,
  WalletError(kind: WalletErrorKind.paymentExpired || WalletErrorKind.invoiceNotFound) => (l) => l.reqFileEnded,
  _ => null,
};

/// The keys of the request file review, for tests.
const Key requestFileWarnKey = ValueKey('request-file-warn');
const Key requestFileApproveKey = ValueKey('request-file-approve');
const Key requestFileNotNowKey = ValueKey('request-file-not-now');
const Key requestFileMessageKey = ValueKey('request-file-message');
const Key requestQrShowAnswerKey = ValueKey('request-qr-show-answer');

/// A payment request opened from a file (DESIGN §3.3). The file is untrusted: nothing says
/// who made it, so a warn card says so, unless a paired contact sealed it ([pairingId]); its
/// message is cleaned plain text. Approve asks for the PIN, pays exactly the amount shown
/// ([WalletSession.payRequestFile], which LEPIC checks against the signed one) and shows the
/// answer file. Not now closes; nothing is paid, stored or sent.
class RequestFileReviewScreen extends ConsumerStatefulWidget {
  const RequestFileReviewScreen({
    super.key,
    required this.json,
    required this.info,
    this.sealedText,
    this.pairingId,
    this.pasted = false,
    this.scanned = false,
  });

  /// The request (I1) as plain slate JSON, or the sealed text when the engine keeps the slate
  /// inside ([sealedText]).
  final String json;
  final SlateInfo info;

  /// The request as it came sealed from a paired contact: paid sealed
  /// ([PairingApi.paySealedRequest]), its answer sealed back when it can be.
  final String? sealedText;

  /// The paired contact that sealed the file, or null when nothing names its maker.
  final String? pairingId;

  /// The text was pasted: the answer can be copied too.
  final bool pasted;

  /// The request was scanned from a QR code (Direct · QR Payment): the answer goes back as a QR,
  /// shown as soon as it is signed, and no switch is asked for.
  final bool scanned;

  @override
  ConsumerState<RequestFileReviewScreen> createState() => _RequestFileReviewScreenState();
}

class _RequestFileReviewScreenState extends ConsumerState<RequestFileReviewScreen> {
  bool _busy = false;
  PaidRequestFile? _paid;

  /// The answer sealed for the paired contact that sent the request, when it seals.
  String? _sealedAnswer;

  /// Why it cannot be paid: already paid here, or ended. The screen is read-only then.
  String Function(AppLocalizations l)? _refused;

  SlateInfo get _info => widget.info;

  @override
  void initState() {
    super.initState();
    _checkPaid();
  }

  /// A request this wallet paid before opens read-only, as a second Review of a paid
  /// invoice does; LEPIC refuses a second payment either way.
  Future<void> _checkPaid() async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    try {
      final txs = await session.transactions(refresh: false);
      final paid = txs.any((t) => t.slateId == _info.slateId && t.kind == TxKind.sent);
      if (paid && mounted) setState(() => _refused = (l) => l.reqFileAlreadyPaid);
    } on WalletError catch (_) {
      // Approve finds out instead.
    }
  }

  Future<void> _approve() async {
    final l = context.l10n;
    final container = ProviderScope.containerOf(context, listen: false);
    final notices = ref.read(noticeProvider.notifier);
    // The gate first, every time: nothing below runs without it.
    if (!await _invoiceGate(context, ref) || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _busy = true);
    try {
      final sealedText = widget.sealedText;
      final PaidRequestFile paid;
      String? sealed;
      if (sealedText != null) {
        final r = await ref
            .read(autoLockHoldProvider.notifier)
            .during(() => session.pairing.paySealedRequest(sealedText, amount: _info.amount));
        paid = r.paid;
        if (r.sealed) sealed = r.paid.json;
      } else {
        paid = await ref
            .read(autoLockHoldProvider.notifier)
            .during(() => session.payRequestFile(slateJson: widget.json, amount: _info.amount));
      }
      container.invalidate(homeProvider);
      logInfo('invoices', 'request file paid');
      final id = widget.pairingId;
      if (id != null && sealedText == null) {
        try {
          final r = await session.pairing.pairing(id);
          if (r != null && r.seals) sealed = await session.pairing.sealSlate(id: id, slateJson: paid.json);
        } on WalletError catch (error) {
          // The plain answer works as well; only the seal is lost.
          logWarn('invoices', 'request answer not sealed: ${error.kind.name}');
        }
      }
      if (mounted) {
        setState(() {
          _paid = paid;
          _sealedAnswer = sealed;
        });
        // In person the other phone waits for the answer: it shows at once.
        if (widget.scanned) unawaited(_showReply(paid));
      }
    } catch (error) {
      final refused = requestFileRefusal(error, scanned: widget.scanned);
      if (refused != null) {
        if (mounted) setState(() => _refused = refused);
      } else {
        notices.show(describeError(l, error), level: NoticeLevel.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The answer as a QR for whoever asked; Done there closes this screen too.
  Future<void> _showReply(PaidRequestFile paid) async {
    final result = await showPaidReplyQr(context, json: paid.json, amount: paid.amount, slateId: paid.slateId);
    if (result is QrShowDone && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final pairing = widget.pairingId == null ? null : ref.watch(pairingByIdProvider(widget.pairingId!));
    final paid = _paid;
    if (paid != null && widget.scanned) {
      // Back from the reply QR without Done: the answer can be shown again.
      return SlotScaffold(
        appBar: AppBar(title: Text(l.reqTitle)),
        body: ScreenBody(
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                key: requestQrShowAnswerKey,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.qr_code_2),
                label: Text(l.qrShowReplyAsQr),
                onPressed: () => _showReply(paid),
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.commonDone),
              ),
            ],
          ),
          children: [
            Row(
              children: [
                GlyphTile(size: 48, child: Icon(Icons.check_circle_outline, color: t.ok)),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(l.reqQrAnswerTitle, style: theme.textTheme.titleMedium),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ReviewAmount(amount: paid.amount),
            const SizedBox(height: 12),
            Text(l.reqQrAnswerLead),
          ],
        ),
      );
    }
    if (paid != null) {
      final sealed = _sealedAnswer;
      final name = sealed != null ? sealedFileName(paid.slateId) : responseFileName(paid.slateId);
      return SlotScaffold(
        appBar: AppBar(title: Text(l.reqTitle)),
        body: ScreenBody(
          children: [
            SlateFileResult(
              title: l.reqAnswerTitle,
              lead: l.reqAnswerLead,
              fileName: name,
              amount: paid.amount,
              json: sealed ?? paid.json,
              copyable: widget.pasted,
              badge: sealed != null && pairing != null ? SealedBadge(name: pairingName(pairing, contacts)) : null,
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.commonDone),
            ),
          ],
        ),
      );
    }
    final service = invoiceSenderName(l, ref.watch(pairingsProvider).value ?? const [], contacts, widget.pairingId);
    final claimed = pairing != null && !contacts.any((c) => c.id == pairing.contactId);
    final display = amountDisplay(ref);
    final spendable = ref.watch(homeProvider).value?.summary.spendable;
    final refused = _refused;
    final short = refused == null && spendable != null && _info.amount > spendable ? _info.amount - spendable : null;
    final fiat = approxFiat(l, _info.amount, (hidden: false, price: display.price, currency: display.currency));
    // The issuer's words, unchecked: the first message an I1 carries is the issuer's.
    final message = invoiceMessageLine(
      messageBy(_info.messages, SlateRole.receiver) ?? _info.messages.firstOrNull?.text,
    );

    return SlotScaffold(
      appBar: AppBar(title: Text(l.reqTitle)),
      idle: _busy ? SlotProgress(label: l.reqTitle) : null,
      body: ScreenBody(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (refused == null)
              BusyButton(
                key: requestFileApproveKey,
                label: widget.scanned ? l.reqApproveShowAnswer : l.reqApproveSaveAnswer,
                busy: _busy,
                onPressed: !_busy && short == null ? _approve : null,
              ),
            TextButton(
              key: requestFileNotNowKey,
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: Text(refused == null ? l.reqNotNow : l.pairClosed),
            ),
          ],
        ),
        children: [
          if (pairing != null)
            // Sealed by a paired contact: the sender is known, as on a contact's request.
            Row(
              children: [
                PairAvatar(name: service, kind: pairing.kind, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l.reqRequests(service),
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 2),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [const SealedBadge(), TrustBadge(pairing), if (claimed) const ClaimedNameBadge()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                GlyphTile(
                  size: 48,
                  child: Icon(widget.scanned ? Icons.qr_code_2 : Icons.description_outlined, color: t.accentText),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.scanned ? l.reqFromQrTitle : l.reqFromFileTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            EdgeCard(
              key: requestFileWarnKey,
              edge: t.warn,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.scanned ? l.reqFromQrWarn : l.reqFromFileWarn),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ReviewAmount(amount: _info.amount),
          if (fiat != null) Text(fiat, style: theme.textTheme.titleMedium?.copyWith(color: t.dim)),
          const SizedBox(height: 20),
          if (message != null)
            // Hostile text: plain, its controls and line breaks gone, never a link.
            _Fact(
              label: widget.scanned ? l.reqQrMessageLabel : l.reqFileMessageLabel,
              child: Text(message, key: requestFileMessageKey, maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          if (refused == null)
            _Fact(
              label: l.invoicesPaysFrom,
              child: Text(
                l.invoicesAvailable(spendable == null ? '…' : shownEpic(l, spendable, hidden: display.hidden)),
              ),
            ),
          if (refused == null) ...[
            const SizedBox(height: 8),
            // Nothing goes over the relay: the answer is a file.
            const _Checks(epicbox: false),
          ],
          if (short != null) ...[
            const SizedBox(height: 16),
            EdgeCard(
              edge: t.risk,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(liveRegion: true, child: Text(l.invoicesShort(epicExact(l, short)))),
              ),
            ),
          ],
          if (refused != null) ...[
            const SizedBox(height: 16),
            EdgeCard(
              edge: t.dim,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(liveRegion: true, child: Text(refused(l))),
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
class ReviewAmount extends StatelessWidget {
  const ReviewAmount({super.key, required this.amount});

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
  const _Checks({this.epicbox = true});

  /// Whether the Epicbox line shows: not for a request file, whose answer is a file.
  final bool epicbox;

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
        if (!epicbox)
          const SizedBox.shrink()
        else if (listener.connected)
          check(l.invoicesCheckEpicbox, ok, l.invoicesEpicboxOk)
        else
          check(
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
    final service = invoiceSenderName(
      l,
      ref.watch(pairingsProvider).value ?? const [],
      ref.watch(contactsProvider).value ?? const [],
      paid.pairingId,
    );
    final message = invoiceMessageLine(paid.message);
    final tip = ref.watch(homeProvider).value?.summary.lastConfirmedHeight;

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

    final now = ref.watch(clockProvider)();
    // A paired contact's request: the states in the contact's own words.
    final paired = paid.pairingId != null;
    final age = now.difference(DateTime.fromMillisecondsSinceEpoch(widget.tx.createdAtUnix * 1000));
    final Widget? pairedState = !paired
        ? null
        : switch (paid.status) {
            InvoiceStatus.replied when invoicePaymentStalled(widget.tx, now) || age > const Duration(hours: 2) && txConfirmations(widget.tx, tip) == null =>
              PairEdgeNotice(
                tone: BadgeTone.warn,
                title: l.reqNotPostedTitle(service),
                body: l.reqNotPostedBody,
                actions: [FilledButton(onPressed: _busy ? null : () => _retry(paid, service), child: Text(l.reqSendAgain))],
              ),
            InvoiceStatus.replyFailed when age > const Duration(hours: 24) =>
              PairEdgeNotice(tone: BadgeTone.warn, title: l.reqUnreachableTitle(service), body: l.reqUnreachableBody),
            InvoiceStatus.withdrawn when widget.tx.status == TxStatus.cancelled =>
              PairEdgeNotice(tone: BadgeTone.info, title: l.reqWithdrewTitle(service), body: l.reqWithdrewBody),
            _ => null,
          };
    // Confirmed on the network: done, whatever the contact last reported.
    final status = widget.tx.status == TxStatus.confirmed
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, color: t.ok, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(l.invoiceDetailsConfirmed(service))),
            ],
          )
        : pairedState ?? switch (paid.status) {
      // Still not on the network a while after paying, though the wallet sent the reply again
      // by itself (windows-05, stall_retry.dart): Stalled, with Send again.
      InvoiceStatus.replied when invoicePaymentStalled(widget.tx, now) => warning(
        l.invoiceDetailsStalled(service),
        TextButton.icon(
          icon: const Icon(Icons.send_outlined),
          label: Text(l.txDetailsSendAgain),
          onPressed: _busy ? null : () => _retry(paid, service),
        ),
      ),
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
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(l.txDetailsCancelPayment),
                    onPressed: widget.onCancel,
                  ),
                ],
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
                l.invoiceReviewMessageLabel(service),
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
          // A paired contact's request: where the payment is on its way.
          if (paid.pairingId != null) ...[
            const SizedBox(height: 12),
            if (paid.status == InvoiceStatus.replied && txConfirmations(widget.tx, tip) == null) ...[
              PairEdgeNotice(
                tone: BadgeTone.info,
                title: l.reqPaidWaiting(service),
                // A person's wallet posts it, not "the exchange".
                body: (ref.watch(pairingByIdProvider(paid.pairingId!))?.kind ?? PairingParty.exchange) == PairingParty.person
                    ? l.reqPaidWaitingBodyPerson
                    : l.reqPaidWaitingBody,
              ),
              const SizedBox(height: 12),
            ],
            RequestTimeline(paid: paid, tx: widget.tx, name: service, tip: tip, target: confirmationsTargetOf(ref)),
          ],
        ],
      ),
    );
  }
}

/// A paid request's way: Paid, delivered to the contact's relay, posted by the
/// contact, then the confirmations. The current step says what the wallet waits for.
class RequestTimeline extends StatelessWidget {
  const RequestTimeline({super.key, required this.paid, required this.tx, required this.name, required this.tip, required this.target});

  final PaidInvoice paid;
  final TxEntry tx;
  final String name;
  final BigInt? tip;
  final int target;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final delivered = paid.status != InvoiceStatus.replyFailed;
    final confirmations = txConfirmations(tx, tip);
    final posted = paid.status == InvoiceStatus.posted || confirmations != null;
    final confirmed = confirmations != null && confirmations >= target;
    return StatusTimeline(
      steps: [
        TimelineStep(l.reqTlPaid, TimelineState.done),
        TimelineStep(
          l.reqTlDelivered(name),
          delivered ? TimelineState.done : TimelineState.current,
          detail: delivered ? null : l.reqRelayRetrying,
        ),
        TimelineStep(
          l.reqTlPosted(name),
          posted ? TimelineState.done : (delivered ? TimelineState.current : TimelineState.todo),
          detail: !posted && delivered ? l.reqTlPostedHint : null,
        ),
        if (confirmed)
          TimelineStep(l.reqTlConfirmed, TimelineState.done)
        else if (confirmations != null)
          TimelineStep(l.reqTlConfirming, TimelineState.current, detail: l.reqTlConfirmingHint(confirmations, target))
        else
          TimelineStep(l.reqTlConfirmed, TimelineState.todo),
      ],
    );
  }
}
