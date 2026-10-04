import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../app_log.dart';
import '../amount.dart';
import '../contacts.dart';
import '../errors.dart';
import '../l10n.dart';
import '../price.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'centered_body.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'help_screen.dart';
import 'scan_screen.dart';
import 'slate_file_screen.dart';
import 'theme/advanced.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';

/// Sending: pick a recipient (their epicbox address), an amount, review, send. A
/// transaction file is offered under "Other ways to send".
/// The most EPIC that will ever exist, 21 million. Anything above is a typo.
final BigInt maxSendAtomic = BigInt.from(21000000) * atomicPerEpic;

/// Cleans a typed or pasted amount for parsing: removes spaces (also no-break and thin ones)
/// and apostrophes, a trailing unit such as "EPIC" or "USD", and thousands separators, and turns
/// a decimal comma into a dot.
///
/// Separators: when both `.` and `,` occur, the last one is the decimal separator
/// ("1,234.56", "1.234,56"). When only one kind occurs, more than one of it means thousands
/// ("1,234,567"). Thousands separators must group by exactly three after the first group, or
/// the amount is refused with a question ("1,234,5", "12,34.5"). A single one is the decimal
/// separator ("1,5", "0.25"). A single [groupSeparator], the one the app shows amounts with in
/// the reader's language (`,` in English, `.` in German), followed by exactly three digits
/// ("1,234") could be either, so it is refused with a question.
///
/// Throws a [LocalizedFormatException] for a negative or ambiguous amount.
String normalizeAmountText(
  String text, {
  required String unit,
  String groupSeparator = ',',
}) {
  var clean = text.replaceAll(RegExp(r"[\s\u00A0\u2009\u202F']"), '');
  final lower = clean.toLowerCase();
  if (lower.endsWith(unit.toLowerCase())) {
    clean = clean.substring(0, clean.length - unit.length);
  }
  if (clean.startsWith('-') || clean.startsWith('\u2212')) {
    throw LocalizedFormatException((l) => l.sendAmountNegative, text);
  }
  final dot = clean.lastIndexOf('.');
  final comma = clean.lastIndexOf(',');
  if (dot >= 0 && comma >= 0) {
    final decimal = dot > comma ? '.' : ',';
    final thousands = decimal == '.' ? ',' : '.';
    final at = clean.lastIndexOf(decimal);
    final whole = clean.substring(0, at);
    // One decimal separator, and the whole part grouped properly: "1,234.5", not "12,34.5"
    // or "1.2.3,4".
    if (whole.contains(decimal) || !_isGrouped(whole, thousands)) {
      throw _unclearAmount(text);
    }
    clean = '${whole.replaceAll(thousands, '')}.${clean.substring(at + 1)}';
  } else if (comma >= 0 || dot >= 0) {
    final sep = comma >= 0 ? ',' : '.';
    if (sep.allMatches(clean).length > 1) {
      // Several of one kind can only be thousands separators, so they must group by three:
      // "1,234,567", not "1,234,5".
      if (!_isGrouped(clean, sep)) throw _unclearAmount(text);
      clean = clean.replaceAll(sep, '');
    } else {
      final whole = clean.substring(0, clean.indexOf(sep));
      final fraction = clean.substring(clean.indexOf(sep) + 1);
      // "1,234" is 1.234 with a decimal comma but 1234 with a thousands comma, as the app
      // shows amounts in English ("1.234" in German). Guessing wrong sends 1000 times too much
      // or too little, so ask.
      if (sep == groupSeparator &&
          fraction.length == 3 &&
          RegExp(r'^[1-9]\d{0,2}$').hasMatch(whole)) {
        throw LocalizedFormatException(
          (l) => l.sendAmountAmbiguous(
            '$whole$fraction',
            localDecimal(l, '$whole.$fraction'),
          ),
          text,
        );
      }
      clean = clean.replaceAll(sep, '.');
    }
  }
  return clean;
}

LocalizedFormatException _unclearAmount(String text) =>
    LocalizedFormatException((l) => l.sendAmountUnclear, text);

/// Whether [digits] is 1 to 3 digits, then groups of exactly three after each [sep].
bool _isGrouped(String digits, String sep) =>
    RegExp('^\\d{1,3}(${RegExp.escape(sep)}\\d{3})*\$').hasMatch(digits);

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key, this.recipient});

  /// Prefills the recipient, for example from a QR code scanned on the home screen.
  final String? recipient;

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

/// What the result step reports.
class _Sent {
  const _Sent({
    required this.tx,
    required this.amount,
    this.to,
    this.reviewedFee,
    this.noteSaved = true,
  });

  final TxEntry tx;
  final BigInt amount;

  /// Their address or URL; null for a file send.
  final Recipient? to;

  /// The fee the review sheet showed, to compare with the one charged.
  final BigInt? reviewedFee;
  final bool noteSaved;

  /// The fee charged, when it differs from the one reviewed.
  BigInt? get changedFee {
    final charged = tx.fee;
    final reviewed = reviewedFee;
    if (charged == null || reviewed == null || charged == reviewed) return null;
    return charged;
  }
}

class _SendScreenState extends ConsumerState<SendScreen> {
  late final _recipient = TextEditingController(
    text: widget.recipient == null
        ? null
        : parseRecipient(widget.recipient!).address,
  );
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _response = TextEditingController();
  final _amountFocus = FocusNode();
  final _noteFocus = FocusNode();

  /// Transaction file instead of epicbox or HTTP.
  bool _fileMode = false;

  /// The amount field holds fiat instead of EPIC.
  bool _fiatEntry = false;
  Timer? _debounce;
  BigInt? _parsedAmount;
  String? _amountError;
  String? _recipientError;
  FeeEstimate? _estimate;
  String? _estimateError;
  Slate? _slate;
  _Sent? _sent;
  String? _error;
  bool _busy = false;

  /// Between a tap on Review and the sheet closing. A second tap must not open a second sheet.
  bool _reviewing = false;

  /// Review is asking the wallet for the fee; the button shows a spinner meanwhile.
  bool _estimating = false;

  /// The amount came from Max, so Review asks for the maximum again rather than a fee.
  bool _maxUsed = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _recipient.dispose();
    _amount.dispose();
    _note.dispose();
    _response.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  double? get _price => ref.read(priceProvider).value;

  String get _currency =>
      ref.read(appSettingsProvider).value?.fiatCurrency ?? 'usd';

  /// Parses the amount field in the current unit into atomic EPIC.
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
      // `normalizeAmountText` leaves only digits and one dot, so no NaN, Infinity or 1e400.
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
    _debounce?.cancel();
    _maxUsed = false;
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
      _estimate = null;
      _estimateError = null;
      _error = null;
    });
    final valid = _parsedAmount;
    if (valid != null) {
      _debounce = Timer(
        const Duration(milliseconds: 400),
        () => _estimateFee(valid),
      );
    }
  }

  Future<FeeEstimate?> _estimateFee(BigInt amount) async {
    final session = ref.read(sessionProvider);
    if (session == null) return null;
    try {
      final estimate = await session.estimateFee(
        amount: amount,
        minimumConfirmations: minimumConfirmations,
      );
      if (mounted && _parsedAmount == amount) {
        setState(() => _estimate = estimate);
      }
      return estimate;
    } catch (error) {
      if (mounted && _parsedAmount == amount) {
        setState(() => _estimateError = describeError(context.l10n, error));
      }
      return null;
    }
  }

  /// Switches the amount field between EPIC and fiat, keeping the amount.
  void _toggleUnit() {
    final price = _price;
    final amount = _parsedAmount;
    if (price == null) {
      // The price went away while entering fiat: start over in EPIC.
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
    // Only the text changes. The exact amount (from Max, say) stays until the user edits the
    // field; re-reading the rounded fiat text would change it.
    _amount.text = localDecimal(
      context.l10n,
      _fiatEntry
          ? (amount / atomicPerEpic * price).toStringAsFixed(2)
          : formatEpic(amount),
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _setRecipient(text);
  }

  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scan(context);
    if (text != null && mounted) _setRecipient(text);
  }

  Future<void> _pickContact() async {
    final contact = await Navigator.of(context).push<Contact>(
      MaterialPageRoute<Contact>(
        builder: (_) => const ContactsScreen(pick: true),
      ),
    );
    if (contact != null && mounted) _setRecipient(contact.address);
  }

  void _setRecipient(String text) {
    _recipient.text = parseRecipient(text).address;
    setState(() {
      _recipientError = null;
      _error = null;
    });
  }

  /// Runs one wallet action at a time; a second tap while one runs does nothing.
  Future<void> _run(Future<void> Function(WalletSession session) action) async {
    if (_busy) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(session);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Checks the form, asks the wallet for the fee again (outputs may have changed since the
  /// last estimate), then shows the review sheet and sends when the user confirms.
  Future<void> _review() async {
    if (_reviewing || _busy) return;
    final session = ref.read(sessionProvider);
    final amount = _parsedAmount;
    if (session == null || amount == null) return;
    // The check still takes a wallet URL; this wallet no longer sends to one (OD-2).
    final problem =
        checkRecipient(
          context.l10n,
          ref.read(walletServiceProvider),
          _recipient.text,
        ) ??
        (parseRecipient(_recipient.text).kind == RecipientKind.http
            ? context.l10n.sendUrlUnsupported
            : null);
    setState(() => _recipientError = problem);
    if (problem != null) return;
    setState(() {
      _reviewing = true;
      _estimating = true;
      _error = null;
    });
    try {
      final FeeEstimate estimate;
      try {
        estimate = _maxUsed
            ? await session.estimateMax(
                minimumConfirmations: minimumConfirmations,
              )
            : await session.estimateFee(
                amount: amount,
                minimumConfirmations: minimumConfirmations,
              );
      } catch (error) {
        if (mounted) {
          setState(() => _estimateError = describeError(context.l10n, error));
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _estimating = false;
        _estimate = estimate;
        _estimateError = null;
        if (_maxUsed && estimate.amount != amount) {
          _parsedAmount = estimate.amount;
          if (!_fiatEntry) {
            _amount.text = localDecimal(
              context.l10n,
              formatEpic(estimate.amount),
            );
          }
        }
      });
      final to = parseRecipient(_recipient.text);
      final contacts = ref.read(contactsProvider).value ?? const <Contact>[];
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _ReviewSheet(
          to: to,
          contactName: contactNameFor(contacts, to.address),
          estimate: estimate,
          note: _note.text.trim(),
          price: _price,
          currency: _currency,
        ),
      );
      if (confirmed == true && mounted) await _send(to, estimate);
    } finally {
      if (mounted) {
        setState(() {
          _reviewing = false;
          _estimating = false;
        });
      }
    }
  }

  Future<void> _send(Recipient to, FeeEstimate reviewed) {
    // Captured now: after the await the screen may be gone, and home must still refresh.
    final container = ProviderScope.containerOf(context, listen: false);
    // A slow send must not lock the wallet under the user and lose the result step.
    final hold = ref.read(autoLockHoldProvider.notifier);
    final amount = reviewed.amount;
    return _run((session) async {
      // [_review] lets only an epicbox address through.
      final tx = await hold.during(
        () => session.sendEpicbox(
          amount: amount,
          minimumConfirmations: minimumConfirmations,
          address: to.address,
        ),
      );
      // The payment is out; a note that fails to save must not look like a failed send.
      var noteSaved = true;
      final note = _note.text.trim();
      if (note.isNotEmpty) {
        try {
          await session.setTxNote(key: tx.key, note: note);
        } catch (error) {
          logWarn(
            'send',
            'saving the note failed: ${describeError(englishStrings, error)}',
          );
          noteSaved = false;
        }
      }
      container.invalidate(homeProvider);
      if (mounted) {
        setState(
          () => _sent = _Sent(
            tx: tx,
            amount: amount,
            to: to,
            reviewedFee: reviewed.fee,
            noteSaved: noteSaved,
          ),
        );
      }
    });
  }

  /// Fills in the largest amount that can be sent now, with its fee.
  Future<void> _max() async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    _debounce?.cancel();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final estimate = await session.estimateMax(
        minimumConfirmations: minimumConfirmations,
      );
      if (!mounted) return;
      _amount.text = localDecimal(context.l10n, formatEpic(estimate.amount));
      setState(() {
        _fiatEntry = false;
        _maxUsed = true;
        _parsedAmount = estimate.amount;
        _amountError = null;
        _estimate = estimate;
        _estimateError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _estimateError = describeError(context.l10n, error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createFile() async {
    final amount = _parsedAmount;
    if (amount == null) return;
    final container = ProviderScope.containerOf(context, listen: false);
    await _run((session) async {
      final slate = await session.createSendSlate(
        amount: amount,
        minimumConfirmations: minimumConfirmations,
      );
      container.invalidate(homeProvider);
      if (mounted) setState(() => _slate = slate);
    });
  }

  Future<void> _openResponse() async {
    final slate = _slate;
    if (slate == null) return;
    final posted = await openSlateFile(
      context,
      ref,
      expectedSlateId: slate.slateId,
    );
    if (posted && mounted) Navigator.pop(context);
  }

  Future<void> _finalize() async {
    final json = _response.text.trim();
    if (json.isEmpty) {
      setState(() => _error = context.l10n.sendPasteResponseMissing);
      return;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    final hold = ref.read(autoLockHoldProvider.notifier);
    await _run((session) async {
      final tx = await hold.during(
        () => session.finalizeAndPost(slateJson: json),
      );
      container.invalidate(homeProvider);
      if (mounted) {
        setState(
          () => _sent = _Sent(tx: tx, amount: _parsedAmount ?? BigInt.zero),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children;
    final sent = _sent;
    if (sent != null) {
      children = _resultStep(context, sent);
    } else if (_slate != null) {
      children = _responseStep(context, _slate!);
    } else {
      children = _formStep(context);
    }
    final all = [...children, if (_error != null) ErrorText(_error!)];
    // The result is short, so it sits in the middle; the form and file steps scroll, and the
    // form keeps its button at the foot of the screen.
    final form = sent == null && _slate == null;
    return SlotScaffold(
      centered: sent != null,
      glow: sent != null && !sent.tx.repostable ? heroGlow : null,
      appBar: AppBar(
        title: Text(
          _fileMode && sent == null
              ? context.l10n.sendByFileTitle
              : context.l10n.sendTitle,
        ),
      ),
      body: sent != null
          ? CenteredBody(children: all)
          : ScreenBody(
              bottom: form ? _formAction(context) : null,
              children: all,
            ),
    );
  }

  /// Review, or Create file in file mode.
  Widget _formAction(BuildContext context) {
    final l = context.l10n;
    return BusyButton(
      label: _fileMode ? l.sendCreateFile : l.sendReview,
      busy: _busy || _estimating,
      onPressed: _parsedAmount == null || _estimateError != null || _reviewing
          ? null
          : _fileMode
          ? _createFile
          : _review,
    );
  }

  List<Widget> _formStep(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final spendable = ref.watch(homeProvider).value?.summary.spendable;
    final listening = ref.watch(listenerProvider).connected;
    final price = ref.watch(priceProvider).value;
    final currency =
        ref.watch(appSettingsProvider).value?.fiatCurrency ?? 'usd';
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final scanner = ref.watch(qrScannerProvider);
    final recent = recentRecipients(
      ref.watch(homeProvider).value?.transactions ?? const <TxEntry>[],
    );
    final to = parseRecipient(_recipient.text);
    final contact = _recipient.text.trim().isEmpty
        ? null
        : contactFor(contacts, to.address);
    final amount = _parsedAmount;
    final estimate = _estimate;
    // The file route is technical.
    final advanced = AdvancedOptions.of(context);

    String? amountHelper;
    if (amount != null && price != null) {
      amountHelper = _fiatEntry
          ? '≈ ${epicText(l, amount)}'
          : '≈ ${localDigits(l, fiatText(amount, price, currency))}';
    }

    return [
      if (!_fileMode) ...[
        TextField(
          controller: _recipient,
          autocorrect: false,
          enableSuggestions: false,
          // Grows to show the whole address, so its start can be checked. The full width and
          // a smaller size fit a 52-character key on one line and its @server on the next,
          // instead of breaking inside the server name.
          minLines: 1,
          maxLines: null,
          keyboardType: TextInputType.url,
          // Next goes to the amount, not to the Paste button below the field.
          textInputAction: TextInputAction.next,
          onEditingComplete: _amountFocus.requestFocus,
          style: theme.textTheme.bodyMedium,
          onChanged: (_) => setState(() {
            _recipientError = null;
            _error = null;
          }),
          decoration: InputDecoration(
            labelText: l.sendRecipientLabel,
            hintText: l.sendRecipientHintSimple,
            error: _recipientError == null
                ? null
                : LiveFieldError(_recipientError!),
            border: const OutlineInputBorder(),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            Tooltip(
              message: l.commonPaste,
              child: TextButton.icon(
                icon: const Icon(Icons.content_paste),
                label: Text(l.commonPaste),
                onPressed: _paste,
              ),
            ),
            if (scanner.supported)
              Tooltip(
                message: l.scanQrTooltip,
                child: TextButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l.sendScanButton),
                  onPressed: _scan,
                ),
              ),
            Tooltip(
              message: l.sendChooseContactTooltip,
              child: TextButton.icon(
                icon: const Icon(Icons.contacts),
                label: Text(l.sendContactsButton),
                onPressed: _pickContact,
              ),
            ),
          ],
        ),
        if (_recipient.text.trim().isEmpty && recent.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // On its own line, so wrapped chips line up under each other.
                Text(l.sendRecentLabel, style: theme.textTheme.bodyMedium),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final address in recent)
                      ActionChip(
                        avatar: const Icon(Icons.history, size: 18),
                        label: Text(
                          contactNameFor(contacts, address) ??
                              shortAddress(address),
                        ),
                        tooltip: l.sendRecentTooltip(address),
                        onPressed: () => _setRecipient(address),
                      ),
                  ],
                ),
              ],
            ),
          ),
        if (contact != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(l.sendSendingToContact(contact.name))),
              ],
            ),
          ),
        if (_recipient.text.trim().isNotEmpty &&
            to.kind == RecipientKind.epicbox &&
            !listening)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  const Icon(Icons.sync, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.sendStillConnecting,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ] else ...[
        Text(l.sendFileIntro),
        const SizedBox(height: 16),
      ],
      TextField(
        controller: _amount,
        focusNode: _amountFocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: _fileMode
            ? TextInputAction.done
            : TextInputAction.next,
        onEditingComplete: _fileMode
            ? () => FocusScope.of(context).unfocus()
            : _noteFocus.requestFocus,
        onChanged: _onAmountChanged,
        decoration: InputDecoration(
          labelText: l.sendAmountLabel(
            _fiatEntry ? currency.toUpperCase() : 'EPIC',
          ),
          helperText: amountHelper,
          error: _amountError == null ? null : LiveFieldError(_amountError!),
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Plain text buttons: their text is their label. A Tooltip here, inside the
              // field's suffix, broke the semantics tree after a route pop.
              if (price != null || _fiatEntry)
                TextButton(
                  onPressed: _toggleUnit,
                  child: Text(
                    l.sendUseUnit(_fiatEntry ? 'EPIC' : currency.toUpperCase()),
                  ),
                ),
              TextButton(
                onPressed: _busy ? null : _max,
                child: Text(l.sendMax),
              ),
            ],
          ),
        ),
      ),
      if (spendable != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            price == null
                ? l.sendSpendable(epicText(l, spendable))
                : l.sendSpendableWithFiat(
                    epicText(l, spendable),
                    localDigits(l, fiatText(spendable, price, currency)),
                  ),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      const SizedBox(height: 8),
      if (estimate != null)
        Semantics(
          liveRegion: true,
          child: Text(
            l.sendFeeAndTotal(
              epicText(l, estimate.fee),
              epicText(l, estimate.amount + estimate.fee),
            ),
          ),
        ),
      if (_estimateError != null) ErrorText(_estimateError!),
      if (!_fileMode) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          focusNode: _noteFocus,
          maxLength: 200,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (_parsedAmount != null &&
                _estimateError == null &&
                !_reviewing &&
                !_busy) {
              _review();
            }
          },
          decoration: InputDecoration(
            labelText: l.sendNoteLabel,
            helperText: l.sendNoteHelper,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
      const SizedBox(height: 16),
      if (_fileMode)
        TextButton(
          onPressed: () => setState(() {
            _fileMode = false;
            _error = null;
          }),
          child: Text(l.sendToAddressInstead),
        )
      else if (advanced)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(l.sendOtherWays),
          children: [
            Text(l.sendOtherWaysExplanation),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => setState(() {
                _fileMode = true;
                _recipientError = null;
                _error = null;
              }),
              child: Text(l.sendByFileButton),
            ),
            const SizedBox(height: 8),
          ],
        ),
    ];
  }

  List<Widget> _responseStep(BuildContext context, Slate slate) {
    final l = context.l10n;
    final name = sendFileName(slate.slateId);
    final theme = Theme.of(context);
    return [
      Text(l.sendFileStep1(name), style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      SlateFileButtons(name: name, json: slate.json),
      const SizedBox(height: 8),
      Text(l.sendFileLockedNote),
      const SizedBox(height: 24),
      Text(
        l.sendFileStep2(responseFileName(name)),
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      BusyButton(label: l.sendOpenResponseFile, onPressed: _openResponse),
      const SizedBox(height: 24),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(l.sendCopyPasteInstead),
        children: [
          SlateBox(title: l.sendSlateBoxTitle, json: slate.json),
          const SizedBox(height: 16),
          SlateInput(controller: _response, label: l.sendPasteResponseLabel),
          const SizedBox(height: 16),
          BusyButton(
            label: l.slateFinishPayment,
            busy: _busy,
            onPressed: _finalize,
          ),
        ],
      ),
    ];
  }

  List<Widget> _resultStep(BuildContext context, _Sent sent) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final to = sent.to;
    // Finished but not taken by the network: the form stays closed, so it cannot be sent twice.
    if (sent.tx.repostable) {
      return [
        NotPostedNotice(tx: sent.tx),
        const SizedBox(height: 8),
        BusyButton(
          label: l.commonDone,
          onPressed: () => Navigator.pop(context),
        ),
      ];
    }
    final waiting = to?.kind == RecipientKind.epicbox;
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final known = to == null || contactFor(contacts, to.address) != null;
    return [
      Center(
        child: GlyphTile(
          size: 88,
          child: Icon(
            waiting ? Icons.schedule_send : Icons.check,
            color: waiting ? null : context.tokens.ok,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Semantics(
        liveRegion: true,
        child: Text(
          // An epicbox payment has not gone anywhere yet; "Sent" would let the
          // user close the app, which stops it from finishing.
          waiting
              ? l.sendResultStarted(epicText(l, sent.amount))
              : l.sendResultSent(epicText(l, sent.amount)),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        waiting
            ? l.sendResultWaitingBody
            : l.sendResultOnItsWay(confirmationsTarget),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge,
      ),
      if (waiting) ...[
        const SizedBox(height: 8),
        Text(
          l.sendResultAutoCancel(sendTtlDays),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      if (sent.changedFee case final fee?) ...[
        const SizedBox(height: 8),
        Text(
          l.sendResultFeeChanged(
            epicText(l, fee),
            epicText(l, sent.reviewedFee!),
          ),
        ),
      ],
      if (!sent.noteSaved) ...[
        const SizedBox(height: 8),
        Text(l.sendResultNoteNotSaved),
      ],
      const SizedBox(height: 24),
      if (!known) ...[
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.person_add),
          label: Text(l.sendSaveToContacts),
          onPressed: () => Navigator.of(context).push<Contact>(
            MaterialPageRoute<Contact>(
              builder: (_) => ContactEditScreen(address: to.address),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      BusyButton(label: l.commonDone, onPressed: () => Navigator.pop(context)),
      const SizedBox(height: 8),
      TextButton.icon(
        icon: const Icon(Icons.help_outline),
        label: Text(l.sendHelp),
        onPressed: () => openHelp(
          context,
          waiting ? HelpTopic.waitingForRecipient : HelpTopic.confirmations,
        ),
      ),
    ];
  }
}

/// Everything about the send on one sheet, with the button that sends it.
class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({
    required this.to,
    required this.contactName,
    required this.estimate,
    required this.note,
    required this.price,
    required this.currency,
  });

  final Recipient to;
  final String? contactName;
  final FeeEstimate estimate;
  final String note;
  final double? price;
  final String currency;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  /// Set by the first tap on Send. A second tap would pop the Send screen as well.
  bool _closing = false;

  void _close(bool send) {
    if (_closing) return;
    setState(() => _closing = true);
    Navigator.pop(context, send);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final estimate = widget.estimate;
    final total = estimate.amount + estimate.fee;
    final price = widget.price;
    final name = widget.contactName;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.sendReviewTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            if (name != null) _Row(label: l.sendReviewTo, value: name),
            _Row(
              label: name == null ? l.sendReviewTo : '',
              value: _breakableAddress(widget.to.address),
              style: theme.textTheme.bodyMedium,
            ),
            _Row(
              label: l.sendReviewAmount,
              value: epicText(l, estimate.amount),
            ),
            _Row(label: l.sendReviewFee, value: epicText(l, estimate.fee)),
            _Row(
              label: l.sendReviewTotal,
              value: price == null
                  ? epicText(l, total)
                  : l.sendReviewTotalWithFiat(
                      epicText(l, total),
                      localDigits(l, fiatText(total, price, widget.currency)),
                    ),
              style: theme.textTheme.titleMedium,
            ),
            if (widget.note.isNotEmpty)
              _Row(label: l.sendReviewNote, value: widget.note),
            const SizedBox(height: 8),
            Text(l.sendReviewViaEpicbox, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _closing ? null : () => _close(true),
              child: Text(l.sendReviewSendButton(epicText(l, estimate.amount))),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _closing ? null : () => _close(false),
              child: Text(l.sendReviewEdit),
            ),
          ],
        ),
      ),
    );
  }
}

/// [address] with a zero-width break before `@`, so a line break keeps the epicbox server
/// whole instead of splitting it. For display only: the break character must never be copied.
String _breakableAddress(String address) =>
    address.replaceFirst('@', '\u200B@');

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.style});

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          // Plain text: the address carries a display-only break character.
          Expanded(
            child: Text(value, style: style ?? theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
