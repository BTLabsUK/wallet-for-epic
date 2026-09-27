import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../errors.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';

/// How a send reaches the recipient.
enum SendMethod {
  /// Through an epicbox relay. The listener completes it when the recipient answers.
  epicbox,

  /// To a wallet listening on HTTP. Completes in one request.
  http,

  /// By hand: copy a slate out, paste the response back.
  slate,
}

/// Validates an HTTP recipient: scheme and host.
String? checkHttpRecipient(String text) {
  final uri = Uri.tryParse(text.trim());
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty) {
    return 'Enter the full address, such as http://203.0.113.5:3415';
  }
  return null;
}

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final _amount = TextEditingController();
  final _recipient = TextEditingController();
  final _response = TextEditingController();
  SendMethod _method = SendMethod.epicbox;
  Timer? _debounce;
  BigInt? _parsedAmount;
  String? _amountError;
  String? _recipientError;
  FeeEstimate? _estimate;
  String? _estimateError;
  Slate? _slate;
  TxEntry? _done;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _amount.dispose();
    _recipient.dispose();
    _response.dispose();
    super.dispose();
  }

  void _onAmountChanged(String text) {
    _debounce?.cancel();
    BigInt? amount;
    String? problem;
    if (text.trim().isNotEmpty) {
      try {
        amount = parseEpic(text);
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

  Future<void> _estimateFee(BigInt amount) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    try {
      final estimate = await session.estimateFee(
        amount: amount,
        minimumConfirmations: minimumConfirmations,
      );
      if (mounted && _parsedAmount == amount) {
        setState(() => _estimate = estimate);
      }
    } catch (error) {
      if (mounted && _parsedAmount == amount) {
        setState(() => _estimateError = describeError(error));
      }
    }
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

  String? _checkRecipient() {
    final text = _recipient.text.trim();
    return switch (_method) {
      SendMethod.epicbox =>
        ref.read(walletServiceProvider).validateEpicboxAddress(address: text)
            ? null
            : 'Enter a full epicbox address: <address>@<relay>',
      SendMethod.http => checkHttpRecipient(text),
      SendMethod.slate => null,
    };
  }

  Future<void> _send() async {
    final amount = _parsedAmount;
    if (amount == null) return;
    final problem = _checkRecipient();
    setState(() => _recipientError = problem);
    if (problem != null) return;
    final to = _recipient.text.trim();
    await _run((session) async {
      switch (_method) {
        case SendMethod.epicbox:
          final tx = await session.sendEpicbox(
            amount: amount,
            minimumConfirmations: minimumConfirmations,
            address: to,
          );
          if (mounted) setState(() => _done = tx);
        case SendMethod.http:
          final tx = await session.sendHttp(
            amount: amount,
            minimumConfirmations: minimumConfirmations,
            url: to,
          );
          if (mounted) setState(() => _done = tx);
        case SendMethod.slate:
          final slate = await session.createSendSlate(
            amount: amount,
            minimumConfirmations: minimumConfirmations,
          );
          if (mounted) setState(() => _slate = slate);
      }
    });
  }

  Future<void> _finalize() async {
    final json = _response.text.trim();
    if (json.isEmpty) {
      setState(() => _error = 'Paste the response slate from the recipient.');
      return;
    }
    await _run((session) async {
      final tx = await session.finalizeAndPost(slateJson: json);
      if (mounted) setState(() => _done = tx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children;
    if (_done != null) {
      children = _doneStep(context);
    } else if (_slate != null) {
      children = _responseStep(context, _slate!);
    } else {
      children = _formStep(context);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Send')),
      body: ScreenBody(
        children: [...children, if (_error != null) ErrorText(_error!)],
      ),
    );
  }

  List<Widget> _formStep(BuildContext context) {
    final spendable = ref.watch(homeProvider).value?.summary.spendable;
    final listening = ref.watch(listenerProvider).connected;
    final estimate = _estimate;
    final recipientLabel = switch (_method) {
      SendMethod.epicbox => 'Recipient epicbox address',
      SendMethod.http => 'Recipient wallet URL',
      SendMethod.slate => '',
    };
    return [
      SegmentedButton<SendMethod>(
        segments: const [
          ButtonSegment(value: SendMethod.epicbox, label: Text('Epicbox')),
          ButtonSegment(value: SendMethod.http, label: Text('HTTP')),
          ButtonSegment(value: SendMethod.slate, label: Text('Slate')),
        ],
        selected: {_method},
        onSelectionChanged: (selection) => setState(() {
          _method = selection.first;
          _recipientError = null;
          _error = null;
        }),
      ),
      const SizedBox(height: 8),
      Text(switch (_method) {
        SendMethod.epicbox =>
          'Sent through the epicbox relay. It completes by itself once the '
              'recipient\'s wallet answers, while this wallet is open.',
        SendMethod.http =>
          'Sent straight to a wallet that listens on HTTP, such as '
              'epic-wallet listen. It completes at once.',
        SendMethod.slate =>
          'Sending takes two steps: create a slate and give it to the '
              'recipient, then paste the response they return to finalize and '
              'post the transaction.',
      }),
      if (_method == SendMethod.epicbox && !listening) ...[
        const SizedBox(height: 8),
        const ErrorText(
          'Not connected to the relay yet. The send is delivered, but it '
          'finishes only once the listener is connected.',
        ),
      ],
      const SizedBox(height: 16),
      if (_method != SendMethod.slate) ...[
        TextField(
          controller: _recipient,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: _method == SendMethod.http
              ? TextInputType.url
              : TextInputType.text,
          onChanged: (_) => setState(() => _recipientError = null),
          decoration: InputDecoration(
            labelText: recipientLabel,
            errorText: _recipientError,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: 'Paste',
              icon: const Icon(Icons.content_paste),
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final text = data?.text?.trim();
                if (text == null || text.isEmpty) return;
                _recipient.text = text;
                setState(() => _recipientError = null);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      TextField(
        controller: _amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: _onAmountChanged,
        decoration: InputDecoration(
          labelText: 'Amount (EPIC)',
          helperText: spendable == null
              ? null
              : 'Spendable: ${epicText(spendable)}',
          errorText: _amountError,
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      if (estimate != null)
        Semantics(
          liveRegion: true,
          child: Text(
            'Fee: ${epicText(estimate.fee)}. '
            'Total: ${epicText(estimate.amount + estimate.fee)}.',
          ),
        ),
      if (_estimateError != null) ErrorText(_estimateError!),
      const SizedBox(height: 16),
      BusyButton(
        label: _method == SendMethod.slate ? 'Create slate' : 'Send',
        busy: _busy,
        onPressed: _parsedAmount == null || _estimateError != null
            ? null
            : _send,
      ),
    ];
  }

  List<Widget> _responseStep(BuildContext context, Slate slate) {
    return [
      SlateBox(
        title: 'Step 1: give this slate to the recipient',
        json: slate.json,
      ),
      const SizedBox(height: 8),
      const Text(
        'The funds stay locked until you finalize. If the recipient never '
        'responds, cancel the pending transaction from the home screen.',
      ),
      const SizedBox(height: 16),
      SlateInput(
        controller: _response,
        label: 'Step 2: paste the recipient\'s response',
      ),
      const SizedBox(height: 16),
      BusyButton(label: 'Finalize and post', busy: _busy, onPressed: _finalize),
    ];
  }

  List<Widget> _doneStep(BuildContext context) {
    final amount = _parsedAmount;
    final waiting = _method == SendMethod.epicbox;
    final what = amount == null ? 'Transaction' : epicText(amount);
    return [
      Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(
              waiting ? Icons.schedule_send : Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                waiting
                    ? '$what sent to the relay.'
                    : amount == null
                    ? 'Transaction posted.'
                    : 'Transaction of $what posted.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        waiting
            ? 'It completes by itself when the recipient\'s wallet answers. '
                  'Keep this wallet open until then. If they never answer, '
                  'cancel it from the home screen to unlock the funds.'
            : 'It shows as confirmed once it is mined.',
      ),
      const SizedBox(height: 24),
      BusyButton(label: 'Done', onPressed: () => Navigator.pop(context)),
    ];
  }
}
