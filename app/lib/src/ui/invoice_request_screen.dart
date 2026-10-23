/// Requesting a payment (I-06): the issuer's side of invoices. The form that sends a request
/// to the payer's invoice address, the request's part of a transaction's details, and the
/// withdraw confirm both share. Nothing here spends: the payment comes back to this wallet's
/// payments address, where the listener or a drain finishes it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../amount.dart';
import '../app_log.dart';
import '../contacts.dart';
import '../errors.dart';
import '../l10n.dart';
import '../price.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'file_exchange_help.dart';
import 'invoices_screen.dart';
import 'receive_screen.dart' show shareAddress;
import 'scan_screen.dart';
import 'send_screen.dart'
    show Utf8LengthLimiter, maxSendAtomic, normalizeAmountText, utf8Length;
import 'theme/protocol.dart';
import 'theme/tokens.dart';

/// Keys of the request form, for tests.
const Key requestPayerKey = ValueKey('request-payer');
const Key requestNoInvoicesKey = ValueKey('request-no-invoices');
const Key requestAmountKey = ValueKey('request-amount');
const Key requestMessageKey = ValueKey('request-message');
const Key requestSummaryKey = ValueKey('request-summary');

/// The payer as the user knows them: the contact's name, else the start of the address.
String payerName(Iterable<Contact> contacts, String address) =>
    contactNameFor(contacts, address) ?? shortAddress(address);

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

/// The request form. It first says what the payer must do (trust this wallet's address,
/// shown in full with copy and share, and give their invoice address), then takes the
/// payer's invoice address, the amount in EPIC or fiat, and an optional message. Request
/// sends it; no PIN, since nothing leaves the wallet. Success opens the Invoices screen.
class InvoiceRequestScreen extends ConsumerStatefulWidget {
  const InvoiceRequestScreen({super.key});

  @override
  ConsumerState<InvoiceRequestScreen> createState() =>
      _InvoiceRequestScreenState();
}

class _InvoiceRequestScreenState extends ConsumerState<InvoiceRequestScreen> {
  final _payer = TextEditingController();
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
  bool _sharing = false;

  @override
  void dispose() {
    _payer.dispose();
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

  void _setPayer(String text) {
    _payer.text = parseRecipient(text).address;
    setState(() => _payerError = null);
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _setPayer(text);
  }

  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scan(context);
    if (text != null && mounted) _setPayer(text);
  }

  Future<void> _pickContact() async {
    final contact = await Navigator.of(context).push<Contact>(
      MaterialPageRoute<Contact>(
        builder: (_) => const ContactsScreen(pick: true),
      ),
    );
    if (contact != null && mounted) _setPayer(contact.address);
  }

  Future<void> _share(String address) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await shareAddress(
        context,
        ref,
        address: address,
        chain: ref.read(walletConfigProvider)?.chain,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// Null when [text] is an epicbox address this wallet can ask, else why not. The wallet
  /// checks again; this only words the common mistakes.
  String? _checkPayer(AppLocalizations l, String text) {
    if (text.trim().isEmpty) return l.requestPayerMissing;
    final recipient = parseRecipient(text);
    final key = epicboxKey(recipient.address);
    final own = [
      ref.read(addressProvider).value,
      ref.read(invoiceAddressProvider).value,
    ];
    if (own.any((o) => o != null && epicboxKey(o) == key)) {
      return l.requestPayerOwn;
    }
    if (recipient.kind != RecipientKind.epicbox ||
        !ref
            .read(walletServiceProvider)
            .validateEpicboxAddress(address: recipient.address)) {
      return l.contactsAddressInvalid('es5x…@epicbox.epiccash.com');
    }
    return null;
  }

  bool _payerOk(AppLocalizations l) {
    final text = _payer.text.trim();
    return text.isNotEmpty && _checkPayer(l, text) == null;
  }

  Future<void> _request() async {
    if (_busy) return;
    final l = context.l10n;
    final problem = _checkPayer(l, _payer.text);
    setState(() {
      _payerError = problem;
      if (_parsedAmount == null && _amountError == null) {
        _amountError = l.sendAmountZero;
      }
    });
    final amount = _parsedAmount;
    if (problem != null || amount == null) return;
    final address = parseRecipient(_payer.text).address;
    final message = _message.text.trim();
    final payer = payerName(
      ref.read(contactsProvider).value ?? const <Contact>[],
      address,
    );
    final notices = ref.read(noticeProvider.notifier);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(autoLockHoldProvider.notifier)
          .during(
            () => ref
                .read(issuedInvoicesProvider.notifier)
                .issue(
                  amount: amount,
                  address: address,
                  message: message.isEmpty ? null : message,
                ),
          );
      logInfo('invoices', 'payment request sent');
      ref.invalidate(homeProvider);
      notices.show(l.requestSentNotice(payer), level: NoticeLevel.success);
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final address = ref.watch(addressProvider);
    // Read now, so the own-address check has it by the time Request is tapped.
    ref.watch(invoiceAddressProvider);
    // Kept alive while the form is open: Request goes through its notifier.
    ref.watch(issuedInvoicesProvider);
    final scanner = ref.watch(qrScannerProvider);
    final files = ref.watch(slateFilesProvider);
    final price = ref.watch(priceProvider).value;
    final currency =
        ref.watch(appSettingsProvider).value?.fiatCurrency ?? 'usd';
    // Said before Request: a payer whose wallet sent a request back cannot pay this one.
    final payerText = _payer.text.trim();
    final capability = payerText.isEmpty || _checkPayer(l, payerText) != null
        ? null
        : ref
              .watch(peerCapabilityProvider(parseRecipient(payerText).address))
              .value;
    final amount = _parsedAmount;
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    // What Send request does, once the payer and the amount are good.
    final summary = amount == null || !_payerOk(l)
        ? null
        : l.invoicesRequestSummary(
            payerName(contacts, parseRecipient(payerText).address),
            epicExact(l, amount),
          );
    String? amountHelper;
    if (amount != null && price != null) {
      amountHelper = _fiatEntry
          ? '≈ ${epicExact(l, amount)}'
          : '≈ ${localDigits(l, fiatText(amount, price, currency))}';
    }

    return SlotScaffold(
      appBar: AppBar(title: Text(l.requestTitle)),
      idle: _busy ? SlotProgress(label: l.requestTitle) : null,
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
            BusyButton(
              label: l.invoicesSendRequest,
              busy: _busy,
              onPressed: _request,
            ),
          ],
        ),
        children: [
          ProtocolSectionHead(l.invoicesRequestHowTitle),
          const SizedBox(height: 8),
          Text(l.requestStepsIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(l.requestStepTrust),
          const SizedBox(height: 8),
          switch (address) {
            AsyncData(:final value) => Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.requestYourAddress,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: t.dim,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: t.monoFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l.commonCopy,
                          color: t.accentText,
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () =>
                              copyText(context, value, l.receiveAddressCopied),
                        ),
                        if (files.canShare || files.canShareText)
                          IconButton(
                            tooltip: l.commonShare,
                            color: t.accentText,
                            icon: const Icon(Icons.share, size: 20),
                            onPressed: _sharing ? null : () => _share(value),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AsyncError(:final error) => ErrorText(describeError(l, error)),
            _ => const LinearProgressIndicator(),
          },
          const SizedBox(height: 12),
          Text(l.requestStepAddress),
          const SizedBox(height: 16),
          TextField(
            key: requestPayerKey,
            controller: _payer,
            autocorrect: false,
            enableSuggestions: false,
            minLines: 1,
            maxLines: null,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            onEditingComplete: _amountFocus.requestFocus,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: t.monoFamily,
            ),
            onChanged: (_) => setState(() => _payerError = null),
            decoration: InputDecoration(
              labelText: l.requestPayerLabel,
              error: _payerError == null ? null : LiveFieldError(_payerError!),
              border: const OutlineInputBorder(),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.content_paste),
                label: Text(l.commonPaste),
                onPressed: _paste,
              ),
              if (scanner.supported)
                TextButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l.sendScanButton),
                  onPressed: _scan,
                ),
              TextButton.icon(
                icon: const Icon(Icons.contacts),
                label: Text(l.sendContactsButton),
                onPressed: _pickContact,
              ),
            ],
          ),
          if (capability == PeerCapability.noInvoices)
            Card(
              key: requestNoInvoicesKey,
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber, color: t.warn, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Semantics(
                            liveRegion: true,
                            child: Text(l.requestPayerNoInvoices),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        icon: const Icon(Icons.description_outlined),
                        label: Text(l.fileHelpTitle),
                        onPressed: () => showFileExchangeHelp(
                          context,
                          role: FileExchangeRole.receiver,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            onSubmitted: (_) => _request(),
            decoration: InputDecoration(
              labelText: l.requestMessageLabel,
              helperText: l.requestMessageHelper,
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
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
              subtitle: Text(payerName(contacts, invoice.payerAddress)),
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
