import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../contacts.dart';
import '../errors.dart';
import '../price.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'help_screen.dart';
import 'scan_screen.dart';
import 'slate_file_screen.dart';

/// Sending: pick a recipient (their address or a wallet URL), an amount, review, send. A
/// transaction file is offered under "Other ways to send".
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
    super.dispose();
  }

  double? get _price => ref.read(priceProvider).value;

  String get _currency =>
      ref.read(appSettingsProvider).value?.fiatCurrency ?? 'usd';

  /// Parses the amount field in the current unit into atomic EPIC.
  BigInt _parseAmount(String text) {
    if (!_fiatEntry) return parseEpic(text);
    final price = _price;
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    // `double.tryParse` also reads "NaN", "Infinity" and "1e400".
    if (value == null ||
        !value.isFinite ||
        value < 0 ||
        price == null ||
        price <= 0) {
      throw const FormatException('Enter an amount such as 10.50');
    }
    return BigInt.from((value / price * 100000000).round());
  }

  void _onAmountChanged(String text) {
    _debounce?.cancel();
    _maxUsed = false;
    BigInt? amount;
    String? problem;
    if (text.trim().isNotEmpty) {
      try {
        amount = _parseAmount(text);
        if (amount == BigInt.zero) problem = 'Enter an amount above zero.';
      } on FormatException catch (e) {
        problem = e.message;
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
        setState(() => _estimateError = describeError(error));
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
    _amount.text = _fiatEntry
        ? (amount / atomicPerEpic * price).toStringAsFixed(2)
        : formatEpic(amount);
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
      if (mounted) setState(() => _error = describeError(error));
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
    final problem = checkRecipient(
      ref.read(walletServiceProvider),
      _recipient.text,
    );
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
        if (mounted) setState(() => _estimateError = describeError(error));
        return;
      }
      if (!mounted) return;
      setState(() {
        _estimating = false;
        _estimate = estimate;
        _estimateError = null;
        if (_maxUsed && estimate.amount != amount) {
          _parsedAmount = estimate.amount;
          if (!_fiatEntry) _amount.text = formatEpic(estimate.amount);
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
      final tx = await hold.during(
        () => switch (to.kind) {
          RecipientKind.epicbox => session.sendEpicbox(
            amount: amount,
            minimumConfirmations: minimumConfirmations,
            address: to.address,
          ),
          RecipientKind.http => session.sendHttp(
            amount: amount,
            minimumConfirmations: minimumConfirmations,
            url: to.address,
          ),
        },
      );
      // The payment is out; a note that fails to save must not look like a failed send.
      var noteSaved = true;
      final note = _note.text.trim();
      if (note.isNotEmpty) {
        try {
          await session.setTxNote(key: tx.key, note: note);
        } catch (_) {
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
      _amount.text = formatEpic(estimate.amount);
      setState(() {
        _fiatEntry = false;
        _maxUsed = true;
        _parsedAmount = estimate.amount;
        _amountError = null;
        _estimate = estimate;
        _estimateError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _estimateError = describeError(error));
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
      setState(() => _error = 'Paste the response text from the recipient.');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileMode && sent == null ? 'Send by file' : 'Send'),
      ),
      body: ScreenBody(
        children: [...children, if (_error != null) ErrorText(_error!)],
      ),
    );
  }

  List<Widget> _formStep(BuildContext context) {
    final theme = Theme.of(context);
    final spendable = ref.watch(homeProvider).value?.summary.spendable;
    final listening = ref.watch(listenerProvider).connected;
    final price = ref.watch(priceProvider).value;
    final currency =
        ref.watch(appSettingsProvider).value?.fiatCurrency ?? 'usd';
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final scanner = ref.watch(qrScannerProvider);
    final to = parseRecipient(_recipient.text);
    final contact = _recipient.text.trim().isEmpty
        ? null
        : contactFor(contacts, to.address);
    final amount = _parsedAmount;
    final estimate = _estimate;

    String? amountHelper;
    if (amount != null && price != null) {
      amountHelper = _fiatEntry
          ? '≈ ${epicText(amount)}'
          : '≈ ${fiatText(amount, price, currency)}';
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
          style: theme.textTheme.bodyMedium,
          onChanged: (_) => setState(() {
            _recipientError = null;
            _error = null;
          }),
          decoration: InputDecoration(
            labelText: 'To',
            hintText: 'Their address or a wallet URL',
            errorText: _recipientError,
            border: const OutlineInputBorder(),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            Tooltip(
              message: 'Paste',
              child: TextButton.icon(
                icon: const Icon(Icons.content_paste),
                label: const Text('Paste'),
                onPressed: _paste,
              ),
            ),
            if (scanner.supported)
              Tooltip(
                message: 'Scan QR code',
                child: TextButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan'),
                  onPressed: _scan,
                ),
              ),
            Tooltip(
              message: 'Choose a contact',
              child: TextButton.icon(
                icon: const Icon(Icons.contacts),
                label: const Text('Contacts'),
                onPressed: _pickContact,
              ),
            ),
          ],
        ),
        if (contact != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Sending to ${contact.name}')),
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
                      'Still connecting. You can send now; it finishes once '
                      'the app is connected.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ] else ...[
        const Text(
          'Sending takes two steps: share the transaction file with the '
          'recipient, then open the .response file they send back to '
          'finish the payment.',
        ),
        const SizedBox(height: 16),
      ],
      TextField(
        controller: _amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: _onAmountChanged,
        decoration: InputDecoration(
          labelText: _fiatEntry
              ? 'Amount (${currency.toUpperCase()})'
              : 'Amount (EPIC)',
          helperText: amountHelper,
          errorText: _amountError,
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (price != null || _fiatEntry)
                TextButton(
                  onPressed: _toggleUnit,
                  child: Text(
                    _fiatEntry ? 'Use EPIC' : 'Use ${currency.toUpperCase()}',
                  ),
                ),
              TextButton(
                onPressed: _busy ? null : _max,
                child: const Text('Max'),
              ),
            ],
          ),
        ),
      ),
      if (spendable != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Spendable: ${epicText(spendable)}'
            '${price == null ? '' : ' (≈ ${fiatText(spendable, price, currency)})'}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      const SizedBox(height: 8),
      if (estimate != null)
        Semantics(
          liveRegion: true,
          child: Text(
            'Fee: ${epicText(estimate.fee)}. '
            'Total: ${epicText(estimate.amount + estimate.fee)}.',
          ),
        ),
      if (_estimateError != null) ErrorText(_estimateError!),
      if (!_fileMode) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            helperText: 'Only you see this note.',
            border: OutlineInputBorder(),
          ),
        ),
      ],
      const SizedBox(height: 16),
      BusyButton(
        label: _fileMode ? 'Create transaction file' : 'Review',
        busy: _busy || _estimating,
        onPressed: amount == null || _estimateError != null || _reviewing
            ? null
            : _fileMode
            ? _createFile
            : _review,
      ),
      const SizedBox(height: 24),
      if (_fileMode)
        TextButton(
          onPressed: () => setState(() {
            _fileMode = false;
            _error = null;
          }),
          child: const Text('Send to an address instead'),
        )
      else
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Other ways to send'),
          children: [
            const Text(
              'Send with a transaction file when the recipient does not use '
              'the mailbox: you share a file, they return a response file.',
            ),
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
              child: const Text('Send by transaction file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
    ];
  }

  List<Widget> _responseStep(BuildContext context, Slate slate) {
    final name = sendFileName(slate.slateId);
    final theme = Theme.of(context);
    return [
      Text(
        'Step 1: give $name to the recipient',
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      SlateFileButtons(name: name, json: slate.json),
      const SizedBox(height: 8),
      const Text(
        'The funds stay locked until you finish. If the recipient never '
        'responds, open the payment and tap Cancel payment.',
      ),
      const SizedBox(height: 24),
      Text(
        'Step 2: open the $name.response file they return',
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      BusyButton(label: 'Open response file', onPressed: _openResponse),
      const SizedBox(height: 24),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Copy and paste instead'),
        children: [
          SlateBox(title: 'Transaction text', json: slate.json),
          const SizedBox(height: 16),
          SlateInput(
            controller: _response,
            label: 'Paste the recipient\'s response',
          ),
          const SizedBox(height: 16),
          BusyButton(
            label: 'Finish payment',
            busy: _busy,
            onPressed: _finalize,
          ),
        ],
      ),
    ];
  }

  List<Widget> _resultStep(BuildContext context, _Sent sent) {
    final theme = Theme.of(context);
    final to = sent.to;
    // Finished but not taken by the network: the form stays closed, so it cannot be sent twice.
    if (sent.tx.repostable) {
      return [
        NotPostedNotice(tx: sent.tx),
        const SizedBox(height: 8),
        BusyButton(label: 'Done', onPressed: () => Navigator.pop(context)),
      ];
    }
    final waiting = to?.kind == RecipientKind.epicbox;
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final known = to == null || contactFor(contacts, to.address) != null;
    return [
      Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(
              waiting ? Icons.schedule_send : Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                // A mailbox payment has not gone anywhere yet; "Sent" would let the
                // user close the app, which stops it from finishing.
                waiting
                    ? 'Payment started: ${epicText(sent.amount)}'
                    : 'Sent ${epicText(sent.amount)}',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(
        waiting
            ? 'It finishes when the recipient\'s wallet answers, usually '
                  'within minutes if their app is open. Keep this app open, or '
                  'open it again within a week to finish. You can find it on '
                  'the home screen and in History.'
            : 'The payment is on its way to the network. It shows as '
                  'Completed after $minimumConfirmations confirmations.',
        style: theme.textTheme.bodyLarge,
      ),
      if (waiting) ...[
        const SizedBox(height: 8),
        const Text(
          'If it is not completed, it cancels by itself after $sendTtlDays '
          'days and the amount unlocks. To stop it sooner, open the payment and '
          'tap Cancel payment.',
        ),
      ],
      if (sent.changedFee case final fee?) ...[
        const SizedBox(height: 8),
        Text(
          'The fee charged was ${epicText(fee)}, not the '
          '${epicText(sent.reviewedFee!)} shown before, because the wallet '
          'picked its coins again when sending.',
        ),
      ],
      if (!sent.noteSaved) ...[
        const SizedBox(height: 8),
        const Text(
          'The note could not be saved. You can add it by opening the '
          'payment.',
        ),
      ],
      const SizedBox(height: 24),
      if (!known) ...[
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.person_add),
          label: const Text('Save to contacts'),
          onPressed: () => Navigator.of(context).push<Contact>(
            MaterialPageRoute<Contact>(
              builder: (_) => ContactEditScreen(address: to.address),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      BusyButton(label: 'Done', onPressed: () => Navigator.pop(context)),
      const SizedBox(height: 8),
      TextButton.icon(
        icon: const Icon(Icons.help_outline),
        label: const Text('Help'),
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
            Text('Review your payment', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            if (name != null) _Row(label: 'To', value: name),
            _Row(
              label: name == null ? 'To' : '',
              value: _breakableAddress(widget.to.address),
              style: theme.textTheme.bodyMedium,
            ),
            _Row(label: 'Amount', value: epicText(estimate.amount)),
            _Row(label: 'Fee', value: epicText(estimate.fee)),
            _Row(
              label: 'Total',
              value: price == null
                  ? epicText(total)
                  : '${epicText(total)} (≈ ${fiatText(total, price, widget.currency)})',
              style: theme.textTheme.titleMedium,
            ),
            if (widget.note.isNotEmpty) _Row(label: 'Note', value: widget.note),
            const SizedBox(height: 8),
            Text(
              widget.to.kind == RecipientKind.epicbox
                  ? 'Goes through Epic\'s mailbox service. It completes when '
                        'the recipient\'s wallet answers.'
                  : 'Goes straight to the recipient\'s wallet.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _closing ? null : () => _close(true),
              child: Text('Send ${epicText(estimate.amount)}'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _closing ? null : () => _close(false),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }
}

/// [address] with a zero-width break before `@`, so a line break keeps the mailbox server
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
