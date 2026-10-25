/// Requesting a payment (I-06, SPEC 2.8): the issuer's side of invoices. The form that asks a
/// paired contact to pay (through its mailbox) or saves the request as a file for anyone, the
/// request's part of a transaction's details, and the withdraw confirm both share. Nothing
/// here spends: the payment comes back to this wallet, where the listener or a drain
/// finishes it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../amount.dart';
import '../app_log.dart';
import '../contacts.dart';
import '../errors.dart';
import '../l10n.dart';
import '../network_gate.dart';
import '../pairing_providers.dart';
import '../price.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'invoices_screen.dart';
import 'net_block.dart';
import 'pairing/pairing_parts.dart';
import 'send_screen.dart'
    show Utf8LengthLimiter, maxSendAtomic, normalizeAmountText, utf8Length;
import 'theme/protocol.dart';
import 'theme/tokens.dart';

/// Keys of the request form, for tests.
const Key requestPayerKey = ValueKey('request-payer');
const Key requestSaveFileKey = ValueKey('request-save-file');
const Key requestAmountKey = ValueKey('request-amount');
const Key requestMessageKey = ValueKey('request-message');
const Key requestSummaryKey = ValueKey('request-summary');

/// The payer as the user knows them: the contact's name, else the start of the address.
///
/// [paired] is the name of the paired contact asked, which comes first: a request to a
/// pairing has no address to show (RFC C-21).
String payerName(Iterable<Contact> contacts, String address, {String? paired}) =>
    paired != null && paired.isNotEmpty ? paired : contactNameFor(contacts, address) ?? shortAddress(address);

/// The one-word state of a request that is no longer waiting; null while it waits, where
/// the time left is shown instead.
String? issuedStateWord(AppLocalizations l, IssuedInvoiceState state) =>
    switch (state) {
      IssuedInvoiceState.waiting => null,
      IssuedInvoiceState.paid => l.issuedPaid,
      IssuedInvoiceState.declined => l.issuedDeclined,
      IssuedInvoiceState.withdrawn => l.issuedWithdrawn,
      IssuedInvoiceState.expired => l.issuedExpired,
      IssuedInvoiceState.bounced => l.issuedBounced,
    };

/// Asks before [invoice] is withdrawn, then withdraws it. The `withdrawn` event brings the
/// notice; a failure shows as an error notice. True once it was withdrawn.
Future<bool> confirmWithdraw(
  BuildContext context,
  WidgetRef ref,
  IssuedInvoice invoice,
) async {
  final payer = payerName(
    ref.read(contactsProvider).value ?? const <Contact>[],
    invoice.payerAddress,
    paired: invoice.pairingId == null ? null : ref.read(pairingNameProvider(invoice.pairingId!)),
  );
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l = context.l10n;
      return AlertDialog(
        title: Text(l.issuedWithdrawTitle),
        content: Text(l.issuedWithdrawBody(payer)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.issuedWithdrawKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.issuedWithdraw),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return false;
  final l = context.l10n;
  final notices = ref.read(noticeProvider.notifier);
  try {
    await ref.read(issuedInvoicesProvider.notifier).withdraw(invoice.slateId);
    ref.invalidate(homeProvider);
    return true;
  } catch (error) {
    notices.show(describeError(l, error), level: NoticeLevel.error);
    return false;
  }
}

/// The paired contacts a request can go to: verified, and their card says their wallet pays
/// requests (caps bit 1). Anyone else gets the request as a file.
List<PairingRecord> requestPayers(Iterable<PairingRecord> pairings) => [
  for (final r in pairings)
    if (r.state == PairingState.verified && r.caps.paysInvoices) r,
];

/// The request form: To (a paired contact whose wallet pays requests), the amount in EPIC or
/// fiat, an optional message and the time to pay. Send request sends it to the contact's
/// mailbox; Save as file makes a payment file for anyone. No PIN: nothing leaves the wallet.
/// Success opens the Invoices screen's sent requests.
class InvoiceRequestScreen extends ConsumerStatefulWidget {
  const InvoiceRequestScreen({super.key, this.pairingId});

  /// The paired contact to ask, when the form opens from it.
  final String? pairingId;

  @override
  ConsumerState<InvoiceRequestScreen> createState() =>
      _InvoiceRequestScreenState();
}

class _InvoiceRequestScreenState extends ConsumerState<InvoiceRequestScreen> {
  late String? _to = widget.pairingId;
  final _amount = TextEditingController();
  final _message = TextEditingController();
  final _amountFocus = FocusNode();
  final _messageFocus = FocusNode();

  /// The amount field holds fiat instead of EPIC.
  bool _fiatEntry = false;
  BigInt? _parsedAmount;
  String? _payerError;
  String? _amountError;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _message.dispose();
    _amountFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  double? get _price => ref.read(priceProvider).value;

  String get _currency =>
      ref.read(appSettingsProvider).value?.fiatCurrency ?? 'usd';

  /// The amount field in its unit, in atomic EPIC. Throws a [FormatException] saying why not.
  BigInt _parseAmount(String text) {
    final clean = normalizeAmountText(
      text,
      unit: _fiatEntry ? _currency : 'epic',
      groupSeparator: NumberFormat.decimalPattern(context.l10n.localeName)
          .symbols
          .GROUP_SEP,
    );
    final BigInt amount;
    if (_fiatEntry) {
      final price = _price;
      if (price == null || price <= 0) {
        throw LocalizedFormatException((l) => l.sendAmountNoPrice, text);
      }
      if (!RegExp(r'^\d*\.?\d*$').hasMatch(clean) || clean == '.') {
        throw LocalizedFormatException(
          (l) => l.sendAmountEnterFiatExample,
          text,
        );
      }
      amount = BigInt.from((double.parse(clean) / price * 100000000).round());
    } else {
      amount = parseEpic(clean);
    }
    if (amount > maxSendAtomic) {
      throw LocalizedFormatException((l) => l.sendAmountTooLarge, text);
    }
    return amount;
  }

  void _onAmountChanged(String text) {
    final l = context.l10n;
    BigInt? amount;
    String? problem;
    if (text.trim().isNotEmpty) {
      try {
        amount = _parseAmount(text);
        if (amount == BigInt.zero) problem = l.sendAmountZero;
      } on FormatException catch (e) {
        problem = describeError(l, e);
      }
    }
    setState(() {
      _parsedAmount = problem == null ? amount : null;
      _amountError = problem;
    });
  }

  /// Switches the amount field between EPIC and fiat, keeping the amount.
  void _toggleUnit() {
    final price = _price;
    final amount = _parsedAmount;
    if (price == null) {
      _amount.clear();
      setState(() => _fiatEntry = false);
      _onAmountChanged('');
      return;
    }
    setState(() => _fiatEntry = !_fiatEntry);
    if (amount == null) {
      _onAmountChanged(_amount.text);
      return;
    }
    _amount.text = localDecimal(
      context.l10n,
      _fiatEntry
          ? (amount / atomicPerEpic * price).toStringAsFixed(2)
          : formatEpic(amount),
    );
  }

  Future<void> _pickPayer(List<PairingRecord> payers, List<Contact> contacts) async {
    final l = context.l10n;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final r in payers)
            ListTile(
              minTileHeight: 64,
              leading: PairAvatar(name: pairingName(r, contacts), kind: r.kind, size: 40),
              title: Text(pairingName(r, contacts)),
              trailing: TrustBadge(r, short: true),
              selected: r.id == _to,
              onTap: () => Navigator.pop(context, r.id),
            ),
          if (payers.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text(l.reqNoPayers)),
        ],
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _to = picked;
        _payerError = null;
      });
    }
  }

  /// The amount, or null after saying why not.
  BigInt? _amountOrSay() {
    final l = context.l10n;
    setState(() {
      if (_parsedAmount == null && _amountError == null) _amountError = l.sendAmountZero;
    });
    return _parsedAmount;
  }

  Future<void> _request() async {
    if (_busy) return;
    final l = context.l10n;
    final to = _to;
    if (to == null) {
      setState(() => _payerError = l.reqPickContact);
      _amountOrSay();
      return;
    }
    final amount = _amountOrSay();
    if (amount == null) return;
    final message = _message.text.trim();
    final payer = ref.read(pairingNameProvider(to));
    final notices = ref.read(noticeProvider.notifier);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(autoLockHoldProvider.notifier)
          .during(
            () => pairingCall(
              ref,
              (api) => api.requestPayment(id: to, amount: amount, message: message.isEmpty ? null : message),
            ),
          );
      ref.invalidate(issuedInvoicesProvider);
      logInfo('invoices', 'payment request sent');
      ref.invalidate(homeProvider);
      notices.show(l.reqSent(payer), level: NoticeLevel.success);
      // The request in the list, where its state follows.
      unawaited(
        navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const InvoicesScreen(segment: InvoicesSegment.sent),
          ),
        ),
      );
    } catch (error) {
      logWarn(
        'invoices',
        'payment request failed: ${describeError(englishStrings, error)}',
      );
      notices.show(describeError(l, error), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveFile() async {
    if (_busy) return;
    final l = context.l10n;
    final amount = _amountOrSay();
    if (amount == null) return;
    final message = _message.text.trim();
    final notices = ref.read(noticeProvider.notifier);
    final files = ref.read(slateFilesProvider);
    setState(() => _busy = true);
    try {
      final slate = await pairingCall(
        ref,
        (api) => api.requestFile(amount: amount, message: message.isEmpty ? null : message),
      );
      ref.invalidate(issuedInvoicesProvider);
      final saved = await files.save(name: sendFileName(slate.slateId), json: slate.json, dialogTitle: l.reqFileTitle);
      if (saved) notices.show(l.reqFileSaved, level: NoticeLevel.success);
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final block = watchNetBlock(context, ref);
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    // Kept alive while the form is open: the list follows what is sent.
    ref.watch(issuedInvoicesProvider);
    final price = ref.watch(priceProvider).value;
    final currency =
        ref.watch(appSettingsProvider).value?.fiatCurrency ?? 'usd';
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final payers = requestPayers(ref.watch(pairingsProvider).value ?? const <PairingRecord>[]);
    final to = payers.where((r) => r.id == _to).firstOrNull;
    // LEPIC requests from paired contacts only: no file to save.
    final byFile = ref.watch(sessionProvider)?.supportsRequestFiles ?? false;
    final amount = _parsedAmount;
    // What Send request does, once the payer and the amount are good.
    final summary = amount == null || to == null
        ? null
        : l.invoicesRequestSummary(pairingName(to, contacts), epicExact(l, amount));
    String? amountHelper;
    if (amount != null && price != null) {
      amountHelper = _fiatEntry
          ? '≈ ${epicExact(l, amount)}'
          : '≈ ${localDigits(l, fiatText(amount, price, currency))}';
    }

    return SlotScaffold(
      appBar: AppBar(title: Text(l.reqNewTitle)),
      idle: _busy ? SlotProgress(label: l.reqNewTitle) : null,
      body: ScreenBody(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (summary != null) ...[
              EdgeCard(
                edge: t.accent,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(summary, key: requestSummaryKey),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Sending the request is a network action; the file is not.
            NetBlockNote(block),
            Row(
              children: [
                if (byFile) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      key: requestSaveFileKey,
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: Text(l.reqNewSaveFile),
                      onPressed: _busy ? null : _saveFile,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: BusyButton(
                    label: l.reqNewSend,
                    busy: _busy,
                    onPressed: block == NetBlock.none && payers.isNotEmpty ? _request : null,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          PairLead(byFile ? l.reqNewLead : l.reqNewLeadContacts),
          const SizedBox(height: 16),
          InkWell(
            key: requestPayerKey,
            borderRadius: BorderRadius.circular(t.radiusSmall),
            onTap: () => _pickPayer(payers, contacts),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l.reqNewTo,
                border: const OutlineInputBorder(),
                error: _payerError == null ? null : LiveFieldError(_payerError!),
                suffixIcon: const Icon(Icons.expand_more),
              ),
              child: to == null
                  ? Text(payers.isEmpty ? l.reqNoPayers : l.reqPickContact, style: TextStyle(color: t.dim))
                  : Row(
                      children: [
                        PairAvatar(name: pairingName(to, contacts), kind: to.kind, size: 28),
                        const SizedBox(width: 8),
                        Flexible(child: Text(pairingName(to, contacts), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        TrustBadge(to, short: true),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          PairSmallPrint(l.reqNewToHint),
          const SizedBox(height: 16),
          TextField(
            key: requestAmountKey,
            controller: _amount,
            focusNode: _amountFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onEditingComplete: _messageFocus.requestFocus,
            onChanged: _onAmountChanged,
            decoration: InputDecoration(
              labelText: l.sendAmountLabel(
                _fiatEntry ? currency.toUpperCase() : 'EPIC',
              ),
              helperText: amountHelper,
              error: _amountError == null
                  ? null
                  : LiveFieldError(_amountError!),
              border: const OutlineInputBorder(),
              suffixIcon: price != null || _fiatEntry
                  ? TextButton(
                      onPressed: _toggleUnit,
                      child: Text(
                        l.sendUseUnit(
                          _fiatEntry ? 'EPIC' : currency.toUpperCase(),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: requestMessageKey,
            controller: _message,
            focusNode: _messageFocus,
            // LEPIC signs at most this many bytes; the field stops there instead of cutting.
            inputFormatters: const [Utf8LengthLimiter(slateMessageMaxBytes)],
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => Text(
                  l.sendMessageCounter(
                    utf8Length(_message.text),
                    slateMessageMaxBytes,
                  ),
                  style: theme.textTheme.bodySmall,
                ),
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l.requestMessageLabel,
              helperText: l.requestMessageHelper,
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: t.info),
              const SizedBox(width: 8),
              Expanded(child: Text(l.invSetTimeToPay)),
              Text(l.pairDurHours(invoiceExpiry.inHours, 0), style: TextStyle(fontFamily: t.monoFamily, fontSize: 13, color: t.dim)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The request's part of a transaction's details, when [tx] is a request this wallet sent:
/// the payer, the message, the state and, while it waits, Withdraw with a confirm. Nothing
/// when it is not one, or the wallet has no invoices.
class IssuedInvoiceBlock extends ConsumerStatefulWidget {
  const IssuedInvoiceBlock({super.key, required this.tx});

  final TxEntry tx;

  @override
  ConsumerState<IssuedInvoiceBlock> createState() => _IssuedInvoiceBlockState();
}

class _IssuedInvoiceBlockState extends ConsumerState<IssuedInvoiceBlock> {
  /// Keeps a waiting request's time left current; nothing else on the block changes by itself.
  late final Timer _tick;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      final slateId = widget.tx.slateId;
      if (slateId == null) return;
      final invoice = ref.read(issuedInvoiceProvider(slateId)).value;
      if (invoice?.state == IssuedInvoiceState.waiting) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _withdraw(IssuedInvoice invoice) async {
    setState(() => _busy = true);
    try {
      await confirmWithdraw(context, ref, invoice);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slateId = widget.tx.slateId;
    if (slateId == null) return const SizedBox.shrink();
    final invoice = ref.watch(issuedInvoiceProvider(slateId)).value;
    if (invoice == null) return const SizedBox.shrink();
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final now = ref.watch(invoiceClockProvider)();
    final message = invoice.message;
    // The details list the slate's messages already; show it here only when they lack it.
    final shownElsewhere = widget.tx.messages.any((m) => m.text == message);

    final (IconData icon, Color color, String text) = switch (invoice.state) {
      IssuedInvoiceState.waiting => (
        Icons.timer,
        t.dim,
        '${l.issuedDetailsWaiting} '
            '${invoiceTimeLeft(l, invoice.timeLeftAt(now))}',
      ),
      IssuedInvoiceState.paid => (
        Icons.check_circle_outline,
        t.ok,
        l.issuedDetailsPaid,
      ),
      IssuedInvoiceState.declined => (
        Icons.block,
        t.warn,
        l.issuedDetailsDeclined,
      ),
      IssuedInvoiceState.withdrawn => (
        Icons.undo,
        t.dim,
        l.issuedDetailsWithdrawn,
      ),
      IssuedInvoiceState.expired => (
        Icons.timer_off_outlined,
        t.dim,
        l.issuedDetailsExpired,
      ),
      IssuedInvoiceState.bounced => (
        Icons.reply,
        t.warn,
        l.issuedDetailsBounced,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProtocolSectionHead(l.issuedDetailsSection),
          // The details' "Requested from" row names the payer already, with the address.
          if (widget.tx.counterparty == null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l.issuedDetailsPayer,
                style: theme.textTheme.labelLarge,
              ),
              subtitle: Text(
                payerName(
                  contacts,
                  invoice.payerAddress,
                  paired: invoice.pairingId == null ? null : ref.watch(pairingNameProvider(invoice.pairingId!)),
                ),
              ),
            ),
          if (message != null && !shownElsewhere)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l.txDetailsYourMessage,
                style: theme.textTheme.labelLarge,
              ),
              subtitle: Text(message),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(text)),
            ],
          ),
          if (invoice.withdrawable)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.undo),
                label: Text(l.issuedWithdraw),
                onPressed: _busy ? null : () => _withdraw(invoice),
              ),
            ),
        ],
      ),
    );
  }
}
