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
import 'scan_screen.dart';
import 'slate_file_screen.dart';

/// Sending: pick a recipient (epicbox address or wallet URL), an amount, review, send. A
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
    this.noteSaved = true,
  });

  final TxEntry tx;
  final BigInt amount;

  /// Epicbox address or URL; null for a file send.
  final Recipient? to;
  final bool noteSaved;
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
    if (value == null || value < 0 || price == null || price <= 0) {
      throw const FormatException('Enter an amount such as 10.50');
    }
    return BigInt.from((value / price * 100000000).round());
  }

  void _onAmountChanged(String text) {
    _debounce?.cancel();
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
    _amount.text = _fiatEntry
        ? (amount / atomicPerEpic * price).toStringAsFixed(2)
        : formatEpic(amount);
    // Keep the exact amount when going back to EPIC; fiat rounding would change it.
    if (_fiatEntry) {
      _onAmountChanged(_amount.text);
    }
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

  Future<void> _run(Future<void> Function(WalletSession session) action) async {
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

  /// Checks the form, then shows the review sheet and sends when the user confirms.
  Future<void> _review() async {
    final amount = _parsedAmount;
    if (amount == null) return;
    final problem = checkRecipient(
      ref.read(walletServiceProvider),
      _recipient.text,
    );
    setState(() => _recipientError = problem);
    if (problem != null) return;
    final estimate = _estimate ?? await _estimateFee(amount);
    if (estimate == null || !mounted) return;
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
    if (confirmed == true && mounted) await _send(to, amount);
  }

  Future<void> _send(Recipient to, BigInt amount) => _run((session) async {
    final tx = switch (to.kind) {
      RecipientKind.epicbox => await session.sendEpicbox(
        amount: amount,
        minimumConfirmations: minimumConfirmations,
        address: to.address,
      ),
      RecipientKind.http => await session.sendHttp(
        amount: amount,
        minimumConfirmations: minimumConfirmations,
        url: to.address,
      ),
    };
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
    ref.invalidate(homeProvider);
    if (mounted) {
      setState(
        () =>
            _sent = _Sent(tx: tx, amount: amount, to: to, noteSaved: noteSaved),
      );
    }
  });

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
    await _run((session) async {
      final slate = await session.createSendSlate(
        amount: amount,
        minimumConfirmations: minimumConfirmations,
      );
      ref.invalidate(homeProvider);
      if (!mounted) return;
      setState(() => _slate = slate);
      await _shareSlate();
    });
  }

  Future<void> _shareSlate() async {
    final slate = _slate;
    if (slate == null) return;
    await ref
        .read(slateFilesProvider)
        .export(name: sendFileName(slate.slateId), json: slate.json);
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
      setState(() => _error = 'Paste the response slate from the recipient.');
      return;
    }
    await _run((session) async {
      final tx = await session.finalizeAndPost(slateJson: json);
      ref.invalidate(homeProvider);
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
          minLines: 1,
          maxLines: 3,
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {
            _recipientError = null;
            _error = null;
          }),
          decoration: InputDecoration(
            labelText: 'To',
            hintText: 'Epicbox address or wallet URL',
            errorText: _recipientError,
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Paste',
                  icon: const Icon(Icons.content_paste),
                  onPressed: _paste,
                ),
                if (scanner.supported)
                  IconButton(
                    tooltip: 'Scan QR code',
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scan,
                  ),
                IconButton(
                  tooltip: 'Choose a contact',
                  icon: const Icon(Icons.contacts),
                  onPressed: _pickContact,
                ),
              ],
            ),
          ),
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
        if (to.kind == RecipientKind.epicbox && !listening) ...[
          const SizedBox(height: 8),
          const ErrorText(
            'Not connected to the relay yet. The send is delivered, but it '
            'finishes only once the listener is connected.',
          ),
        ],
        const SizedBox(height: 16),
      ] else ...[
        const Text(
          'Sending takes two steps: share the transaction file with the '
          'recipient, then open the .response file they send back to '
          'finalize and post the transaction.',
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
        busy: _busy,
        onPressed: amount == null || _estimateError != null
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
              'Send with a transaction file when the recipient has no '
              'epicbox address: you share a file, they return a response file.',
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
      BusyButton(label: 'Share $name', onPressed: _shareSlate),
      const SizedBox(height: 8),
      const Text(
        'The funds stay locked until you finalize. If the recipient never '
        'responds, cancel the pending transaction from the home screen.',
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
          SlateBox(title: 'Transaction slate', json: slate.json),
          const SizedBox(height: 16),
          SlateInput(
            controller: _response,
            label: 'Paste the recipient\'s response',
          ),
          const SizedBox(height: 16),
          BusyButton(
            label: 'Finalize and post',
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
                waiting
                    ? 'Sent.'
                    : 'Sent ${epicText(sent.amount)}. The payment is complete.',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(
        waiting
            ? 'The payment completes when the recipient\'s wallet is online; '
                  'keep this app open or reopen it later to finish.'
            : 'It shows as confirmed once it is mined.',
        style: theme.textTheme.bodyLarge,
      ),
      if (waiting) ...[
        const SizedBox(height: 8),
        const Text(
          'If the recipient never answers, cancel the payment from the '
          'transaction list to unlock the funds.',
        ),
      ],
      if (!sent.noteSaved) ...[
        const SizedBox(height: 8),
        const Text(
          'The note could not be saved. You can add it from the '
          'transaction\'s details.',
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
    ];
  }
}

/// Everything about the send on one sheet, with the button that sends it.
class _ReviewSheet extends StatelessWidget {
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

  String _money(BigInt amount) {
    final p = price;
    return p == null
        ? epicText(amount)
        : '${epicText(amount)} (≈ ${fiatText(amount, p, currency)})';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = estimate.amount + estimate.fee;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Review your payment', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _Row(label: 'To', value: contactName ?? to.address),
            if (contactName != null) _Row(label: '', value: to.address),
            _Row(label: 'Amount', value: _money(estimate.amount)),
            _Row(label: 'Fee', value: epicText(estimate.fee)),
            _Row(label: 'Total', value: _money(total), strong: true),
            if (note.isNotEmpty) _Row(label: 'Note', value: note),
            const SizedBox(height: 8),
            Text(
              to.kind == RecipientKind.epicbox
                  ? 'Delivered through the epicbox relay. It completes when '
                        'the recipient\'s wallet is online.'
                  : 'Sent straight to the recipient\'s wallet.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Send ${epicText(estimate.amount)}'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = strong
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(child: SelectableText(value, style: style)),
        ],
      ),
    );
  }
}
