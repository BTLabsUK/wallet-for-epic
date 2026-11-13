// SPDX-License-Identifier: Apache-2.0
/// Requesting a payment: the issuer's side of invoices. The form that asks a
/// paired contact to pay (through its mailbox) or saves the request as a file for anyone, the
/// request's part of a transaction's details, and the withdraw confirm both share. Nothing
/// here spends: the payment comes back to this wallet, where the listener or a drain
/// finishes it.
library;

import 'app_dialog.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../help/help_content.dart' show HelpAnchor;
import 'cancel_note.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../initials.dart' show nameInitials;
import '../slate_files.dart';
import '../trust_ids.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'invoices_screen.dart';
import 'net_block.dart';
import 'kit/kit_amount.dart';
import 'kit/kit_avatar.dart';
import 'kit/kit_button.dart';
import 'kit/kit_chip.dart';
import 'kit/kit_fiat_swap.dart';
import 'kit/kit_row.dart' show KitIconWell;
import 'kit/kit_headers.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_keypad.dart';
import 'kit/kit_sheet.dart';
import 'kit/kit_tokens.dart';
import 'receive_code.dart';
import 'request_qr_screen.dart' show RequestQrScreen;
import 'scan_screen.dart' show offersQrPayment;
import 'send_screen.dart' show Utf8LengthLimiter, utf8Length;
import 'theme/protocol.dart';
import 'theme/tokens.dart';

/// Keys of the request form, for tests.
const Key requestPayerKey = ValueKey('request-payer');
const Key requestSaveFileKey = ValueKey('request-save-file');
const Key requestAmountKey = ValueKey('request-amount');
const Key requestMessageKey = ValueKey('request-message');
const Key requestShowQrKey = ValueKey('request-show-qr');
const Key requestFileWaitingKey = ValueKey('request-file-waiting');

/// Payment requests work as files, both ways: Invoices is on and the core handles them
/// (DESIGN §3). Off, "Save as a file for anyone" is absent.
bool requestFilesOn(WidgetRef ref, {bool listen = true}) =>
    (listen ? ref.watch(invoiceSessionProvider) : ref.read(invoiceSessionProvider))?.supportsRequestFiles ?? false;

/// The picker's value for "Save as a file for anyone".
const String _fileRow = '\u0000file';

/// The picker's value for "Show as QR".
const String _qrRow = '\u0000qr';

/// The payer as the user knows them: the contact's name, else the start of the address.
///
/// [paired] is the name of the paired contact asked, which comes first: a request to a
/// pairing has no address to show (RFC C-21).
String payerName(Iterable<Contact> contacts, String address, {String? paired}) =>
    paired != null && paired.isNotEmpty ? paired : contactNameFor(contacts, address) ?? shortAddress(address);

/// Asks before [invoice] is withdrawn, then withdraws it. The `withdrawn` event brings the
/// notice; a failure shows as an error notice. True once it was withdrawn.
Future<bool> confirmWithdraw(
  BuildContext context,
  WidgetRef ref,
  IssuedInvoice invoice,
) async {
  final payer = invoice.byFile
      ? context.l10n.reqToAnyone
      : payerName(
          ref.read(contactsProvider).value ?? const <Contact>[],
          invoice.payerAddress,
          paired: invoice.pairingId == null ? null : ref.read(pairingNameProvider(invoice.pairingId!)),
        );
  final confirmed = await showAppDialog<bool>(
    context,
    builder: (context) {
      final l = context.l10n;
      final theme = Theme.of(context);
      // Withdrawing cancels the request: the outlined risk style; Keep is the secondary.
      return AppDialog(
        title: l.issuedWithdrawTitle,
        icon: Icons.request_quote_outlined,
        body: CancelNote(
          text: l.issuedWithdrawBody(payer),
          anchor: HelpAnchor.requests,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        actions: [
          DialogButton.secondary(label: l.issuedWithdrawKeep, onPressed: () => Navigator.pop(context, false)),
          DialogButton.risk(label: l.issuedWithdraw, onPressed: () => Navigator.pop(context, true)),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return false;
  final l = context.l10n;
  // Everything the end needs is taken before the await: withdrawing reloads the list, which
  // can remove the row (and `ref`) that asked. Using `ref` after that threw, and the error
  // notice came although the withdraw had worked.
  final notices = ref.read(noticeProvider.notifier);
  final withdrawals = ref.read(issuedInvoicesProvider.notifier);
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await withdrawals.withdraw(invoice.slateId);
    container.invalidate(homeProvider);
    return true;
  } catch (error) {
    notices.show(describeError(l, error), level: NoticeLevel.error);
    return false;
  }
}

/// The paired contacts a request can go to: verified, and their card says their wallet pays
/// requests (caps bit 1). Anyone else gets the request as a file.
/// One per contact: the pairing it pays through (contactPairingOf), never its older ones twice.
List<PairingRecord> requestPayers(Iterable<PairingRecord> pairings) {
  final all = pairings.toList();
  return [
    for (final r in all)
      if (r.state == PairingState.verified &&
          r.caps.paysInvoices &&
          (r.contactId == null || contactPairingOf(all, r.contactId!)?.id == r.id))
        r,
  ];
}

/// The Ask-for-an-amount page (Receive-2): the amount on a keypad, who pays and a note, then
/// "Ask for {amount}". Who pays is a paired contact (the request goes to their mailbox), anyone
/// with a code (a QR shown to a phone nearby) or anyone with a file. No PIN: nothing leaves the
/// wallet. A contact's request opens the Invoices screen's sent requests.
class InvoiceRequestScreen extends ConsumerStatefulWidget {
  const InvoiceRequestScreen({super.key, this.pairingId, this.asQr = false, this.message});

  /// The paired contact to ask, when the page opens from it.
  final String? pairingId;

  /// The page opens on "Anyone, with a code" (Receive › In person).
  final bool asQr;

  /// The note the page opens with: the last request's, for the next payer at a till.
  final String? message;

  @override
  ConsumerState<InvoiceRequestScreen> createState() => _InvoiceRequestScreenState();
}

class _InvoiceRequestScreenState extends ConsumerState<InvoiceRequestScreen> {
  late String? _to = widget.pairingId;

  /// "Anyone, with a file" was chosen (true) or another payer was (false); null until the user
  /// picks.
  bool? _toFile;

  /// "Anyone, with a code" was chosen: the request goes to a phone next to this one.
  late bool _toQr = widget.asQr;

  /// The amount as typed on the keypad, with a "." for the decimal point.
  String _digits = '';
  late String _note = widget.message ?? '';

  /// The keypad types fiat instead of EPIC.
  bool _fiatEntry = false;
  String? _payerError;
  bool _busy = false;

  double? get _price => ref.read(priceProvider).value;

  String get _currency => ref.read(appSettingsProvider).value?.fiatCurrency ?? 'usd';

  /// The typed amount in atomic EPIC, or null while it is empty, zero or cannot be priced.
  BigInt? get _amount {
    final text = _digits.endsWith('.') ? _digits.substring(0, _digits.length - 1) : _digits;
    if (text.isEmpty) return null;
    try {
      final BigInt amount;
      if (_fiatEntry) {
        final price = _price;
        if (price == null || price <= 0) return null;
        amount = fiatToAtomic(text, price, text);
      } else {
        amount = parseEpic(text);
      }
      return amount == BigInt.zero ? null : amount;
    } on FormatException {
      return null;
    }
  }

  void _digit(String d) {
    final decimals = _fiatEntry ? (_currency.toLowerCase() == 'btc' ? 8 : 2) : 8;
    final dot = _digits.indexOf('.');
    if (dot >= 0 ? _digits.length - dot - 1 >= decimals : _digits.length >= 9) return;
    setState(() => _digits = _digits == '0' ? d : _digits + d);
  }

  void _point() {
    if (_digits.contains('.')) return;
    setState(() => _digits = _digits.isEmpty ? '0.' : '$_digits.');
  }

  void _delete() {
    if (_digits.isNotEmpty) setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  /// Switches the keypad between EPIC and fiat, keeping the amount.
  void _swap() {
    final price = _price;
    if (price == null) return;
    final amount = _amount;
    setState(() {
      _fiatEntry = !_fiatEntry;
      _digits = amount == null ? '' : (_fiatEntry ? (amount / atomicPerEpic * price).toStringAsFixed(2) : formatEpic(amount));
    });
  }

  Future<void> _editNote() async {
    final note = await showKitSheet<String>(context: context, builder: (_) => _NoteSheet(note: _note));
    if (note != null && mounted) setState(() => _note = note.trim());
  }

  Future<void> _pickPayer(List<PairingRecord> payers, List<Contact> contacts, {required String? selected}) async {
    final l = context.l10n;
    final byFile = requestFilesOn(ref, listen: false);
    final byQr = byFile && offersQrPayment(ref);
    final picked = await KitPickerSheet.show<String>(
      context: context,
      title: l.phoneRecvWho,
      selected: selected,
      note: payers.isEmpty && !byFile ? l.reqNoPayersContacts : null,
      choices: [
        for (final r in payers)
          KitChoice(
            value: r.id,
            title: pairingName(r, contacts),
            leading: KitAvatar(initials: nameInitials(pairingName(r, contacts), count: 2, phone: true)),
          ),
        if (byQr)
          KitChoice(
            value: _qrRow,
            title: l.phoneRecvAnyoneCode,
            subtitle: l.phoneRecvAnyoneCodeLine,
            leading: KitIconWell(KitIcons.qr),
            semanticsId: TrustIds.receiveAskAnyoneCode,
          ),
        if (byFile)
          KitChoice(
            value: _fileRow,
            title: l.phoneRecvAnyoneFile,
            subtitle: l.phoneRecvAnyoneFileLine,
            leading: KitIconWell(KitIcons.invoice),
            semanticsId: TrustIds.receiveAskAnyoneFile,
          ),
      ],
    );
    if (picked != null && mounted) {
      setState(() {
        _toQr = picked == _qrRow;
        _toFile = picked == _fileRow;
        if (picked != _fileRow && picked != _qrRow) _to = picked;
        _payerError = null;
      });
    }
  }

  Future<void> _request(List<PairingRecord> payers, List<Contact> contacts) async {
    if (_busy) return;
    final l = context.l10n;
    final to = _to;
    final amount = _amount;
    if (to == null) {
      setState(() => _payerError = l.reqPickContactOrMethod);
      unawaited(_pickPayer(payers, contacts, selected: null));
      return;
    }
    if (amount == null) return;
    final message = _note.trim();
    final payer = ref.read(pairingNameProvider(to));
    final notices = ref.read(noticeProvider.notifier);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(autoLockHoldProvider.notifier)
          .during(
            () => pairingCall(ref, (api) => api.requestPayment(id: to, amount: amount, message: message.isEmpty ? null : message)),
          );
      ref.invalidate(issuedInvoicesProvider);
      logInfo('invoices', 'payment request sent');
      ref.invalidate(homeProvider);
      notices.show(l.reqSent(payer), level: NoticeLevel.success);
      // The request in the list, where its state follows.
      unawaited(navigator.pushReplacement(MaterialPageRoute<void>(builder: (_) => const InvoicesScreen(segment: InvoicesSegment.sent))));
    } catch (error) {
      logWarn('invoices', 'payment request failed: ${describeError(englishStrings, error)}');
      notices.show(describeError(l, error), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Makes the request file, then shows it to save or share (DESIGN §3.2). Nothing is spent,
  /// so no PIN; the request waits in Requests sent.
  Future<void> _saveFile() async {
    if (_busy) return;
    final l = context.l10n;
    final amount = _amount;
    if (amount == null) return;
    final message = _note.trim();
    final notices = ref.read(noticeProvider.notifier);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final slate = await ref
          .read(autoLockHoldProvider.notifier)
          .during(() => pairingCall(ref, (api) => api.requestFile(amount: amount, message: message.isEmpty ? null : message)));
      ref
        ..invalidate(issuedInvoicesProvider)
        ..invalidate(homeProvider);
      logInfo('invoices', 'payment request saved as a file');
      unawaited(
        navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RequestFileSavedScreen(slate: slate, amount: amount, message: message.isEmpty ? null : message),
          ),
        ),
      );
    } catch (error) {
      logWarn('invoices', 'request file failed: ${describeError(englishStrings, error)}');
      notices.show(describeError(l, error), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Makes the request and shows it as a code (Direct · QR Payment). Nothing is spent, so no
  /// PIN; the request waits in Requests sent until the payer's answer is scanned.
  Future<void> _showQr() async {
    if (_busy) return;
    final l = context.l10n;
    final amount = _amount;
    if (amount == null) return;
    final message = _note.trim();
    final notices = ref.read(noticeProvider.notifier);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final slate = await ref
          .read(autoLockHoldProvider.notifier)
          .during(() => pairingCall(ref, (api) => api.requestFile(amount: amount, message: message.isEmpty ? null : message)));
      ref
        ..invalidate(issuedInvoicesProvider)
        ..invalidate(homeProvider);
      logInfo('invoices', 'payment request shown as a QR');
      unawaited(
        navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RequestQrScreen(slate: slate, amount: amount, message: message.isEmpty ? null : message),
          ),
        ),
      );
    } catch (error) {
      logWarn('invoices', 'QR request failed: ${describeError(englishStrings, error)}');
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
    // Kept alive while the page is open: the list follows what is sent.
    ref.watch(issuedInvoicesProvider);
    final price = ref.watch(priceProvider).value;
    final currency = ref.watch(appSettingsProvider).value?.fiatCurrency ?? 'usd';
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final payers = requestPayers(ref.watch(pairingsProvider).value ?? const <PairingRecord>[]);
    final to = payers.where((r) => r.id == _to).firstOrNull;
    // Request files off (the core or the Invoices switch): contacts only.
    final byFile = requestFilesOn(ref);
    // Nobody chosen yet means anyone: with a code where the phone offers it, else a file.
    final toQr = byFile && offersQrPayment(ref) && (_toQr || (_toFile == null && _to == null));
    final toFile = byFile && !toQr && (_toFile ?? _to == null);
    final amount = _amount;
    final unit = _fiatEntry ? currency.toUpperCase() : epicUnit;
    final String? fiat;
    if (price == null) {
      fiat = null;
    } else if (_fiatEntry) {
      fiat = approxText(epicExact(l, amount ?? BigInt.zero));
    } else {
      fiat = phoneFiat(l, amount ?? BigInt.zero, (hidden: false, price: price, currency: currency), approx: true);
    }
    final anyone = toQr || toFile;
    final chip = anyone ? l.phoneRecvFromAnyone : (to == null ? l.phoneRecvWho : l.phoneRecvFromName(pairingName(to, contacts)));
    final selected = toQr ? _qrRow : (toFile ? _fileRow : to?.id);
    final contactRoute = !anyone;
    final canSubmit = amount != null && !_busy && (!contactRoute || block == NetBlock.none);
    return SlotScaffold(
      idle: _busy ? SlotProgress(label: l.phoneRecvAsk) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                SizedBox(
                  height: Kit.flowHeader,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: KitIconButton(
                            icon: KitIcons.back,
                            label: l.phoneKitBack,
                            semanticsId: TrustIds.receiveAskBack,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 52),
                          child: TrustId(
                            TrustIds.receiveAskPayer,
                            child: Semantics(
                              button: true,
                              label: chip,
                              excludeSemantics: true,
                              onTap: () => _pickPayer(payers, contacts, selected: selected),
                              child: InkWell(
                                key: requestPayerKey,
                                borderRadius: BorderRadius.circular(Kit.rButtonSmall),
                                onTap: () => _pickPayer(payers, contacts, selected: selected),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minHeight: Kit.hitMin),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(child: Text(chip, style: KitType.flowTitle.copyWith(color: t.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      Padding(padding: const EdgeInsets.only(left: 8), child: Icon(KitIcons.chevronDown, size: 16, color: t.dim)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: KitIconButton(icon: KitIcons.help, label: l.sendHelp, color: t.dim, onPressed: () => showAskHelp(context)),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 58),
                        KeyedSubtree(
                          key: requestAmountKey,
                          child: KitAmountDisplay(
                            amount: localDecimal(l, _digits),
                            unit: unit,
                          ),
                        ),
                        // Frame: the line 14 under the figure, 22 high, in a 44 tap target.
                        if (fiat != null) ...[
                          const SizedBox(height: 3),
                          KitFiatSwap(text: fiat, onSwap: price == null ? null : _swap),
                        ],
                        // The chip sits in a 48 tap target: 13 to the frame's chip top, less the 7 it adds.
                        SizedBox(height: _note.isEmpty ? 3 : 6),
                        TrustId(
                          TrustIds.receiveAskNote,
                          child: KitChip(
                            _note.isEmpty ? l.phonePayAddNote : _note,
                            icon: _note.isEmpty ? KitIcons.add : KitIcons.message,
                            large: _note.isNotEmpty,
                            onTap: _editNote,
                          ),
                        ),
                        if (_payerError != null) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
                            child: LiveFieldError(_payerError!),
                          ),
                        ],
                        if (contactRoute && block != NetBlock.none)
                          Padding(padding: const EdgeInsets.fromLTRB(Kit.gutter, 12, Kit.gutter, 0), child: NetBlockNote(block)),
                      ],
                    ),
                  ),
                ),
                KitKeypad(onDigit: _digit, onDelete: _delete, onPoint: _point, idFor: (k) => 'request-key-$k'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Kit.gutter, 17, Kit.gutter, 0),
                  child: KitButton(
                    key: toQr ? requestShowQrKey : (toFile ? requestSaveFileKey : null),
                    label: amount == null ? l.phoneRecvAsk : l.phoneRecvAskFor(epicExact(l, amount)),
                    kind: canSubmit ? KitButtonKind.gold : KitButtonKind.off,
                    semanticsId: TrustIds.receiveAskSubmit,
                    onPressed: canSubmit ? (toQr ? _showQr : (toFile ? _saveFile : () => _request(payers, contacts))) : null,
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

/// The note sheet: a field limited to what LEPIC signs, and Done.
class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.note});

  final String note;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _controller = TextEditingController(text: widget.note);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return KitSheet(
      title: l.phonePayNote,
      primary: KitButton(label: l.commonDone, onPressed: () => Navigator.of(context).pop(_controller.text)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
        child: TextField(
          key: requestMessageKey,
          controller: _controller,
          autofocus: true,
          // LEPIC signs at most this many bytes; the field stops there instead of cutting.
          inputFormatters: const [Utf8LengthLimiter(slateMessageMaxBytes)],
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
              Text(l.sendMessageCounter(utf8Length(_controller.text), slateMessageMaxBytes), style: KitType.rowSub.copyWith(color: t.dim)),
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) => Navigator.of(context).pop(v),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: l.requestMessageLabel, helperText: l.requestMessageHelper, helperMaxLines: 3),
        ),
      ),
    );
  }
}

/// The payment request, made (Gap-1): its code (the animated I1 payment QR), Copy and Share
/// hand the request over as a file. Done goes to Requests sent, where it waits.
class RequestFileSavedScreen extends StatelessWidget {
  const RequestFileSavedScreen({super.key, required this.slate, required this.amount, this.message});

  final Slate slate;
  final BigInt amount;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return RequestCodePage(
      amount: amount,
      message: message,
      json: slate.json,
      fileName: sendFileName(slate.slateId),
      status: const RequestStatusLine(),
      onDone: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const InvoicesScreen(segment: InvoicesSegment.sent)),
      ),
      card: RequestQrCard(json: slate.json, label: l.deskKitQrOf(l.qrShowTitleRequest)),
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
    // A paid request is told by the payment's own steps (Requested, Paid, Confirmed): no block.
    if (invoice == null || invoice.state == IssuedInvoiceState.paid) return const SizedBox.shrink();
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
        '${l.issuedDetailsWaiting} · '
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
      padding: const EdgeInsets.fromLTRB(Kit.gutter, 16, Kit.gutter, 0),
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
                invoice.byFile
                    ? l.reqToAnyone
                    : payerName(
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
              subtitle: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(text)),
            ],
          ),
          if (invoice.byFile && invoice.withdrawable) ...[
            const SizedBox(height: 12),
            InlineNotice(key: requestFileWaitingKey, level: NoticeLevel.info, text: l.reqFileWaitingCard),
          ],
          if (invoice.withdrawable) ...[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.undo),
                label: Text(l.issuedWithdraw),
                onPressed: _busy ? null : () => _withdraw(invoice),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
