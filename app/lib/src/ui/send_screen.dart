import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../errors.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';

/// Manual slate send: create a slate, hand it over, then finalize the recipient's response.
class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final _amount = TextEditingController();
  final _response = TextEditingController();
  Timer? _debounce;
  BigInt? _parsedAmount;
  String? _amountError;
  FeeEstimate? _estimate;
  String? _estimateError;
  Slate? _slate;
  TxEntry? _posted;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _amount.dispose();
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

  Future<void> _createSlate() async {
    final amount = _parsedAmount;
    if (amount == null) return;
    await _run((session) async {
      final slate = await session.createSendSlate(
        amount: amount,
        minimumConfirmations: minimumConfirmations,
      );
      if (mounted) setState(() => _slate = slate);
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
      if (mounted) setState(() => _posted = tx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children;
    if (_posted != null) {
      children = _doneStep(context);
    } else if (_slate != null) {
      children = _responseStep(context, _slate!);
    } else {
      children = _amountStep(context);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Send')),
      body: ScreenBody(
        children: [
          const Text(
            'Sending takes two steps: create a slate and give it to the '
            'recipient, then paste the response they return to finalize and '
            'post the transaction.',
          ),
          const SizedBox(height: 16),
          ...children,
          if (_error != null) ErrorText(_error!),
        ],
      ),
    );
  }

  List<Widget> _amountStep(BuildContext context) {
    final spendable = ref.watch(homeProvider).value?.summary.spendable;
    final estimate = _estimate;
    return [
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
        label: 'Create slate',
        busy: _busy,
        onPressed: _parsedAmount == null || _estimateError != null
            ? null
            : _createSlate,
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
    return [
      Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                amount == null
                    ? 'Transaction posted.'
                    : 'Transaction of ${epicText(amount)} posted.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      const Text('It shows as confirmed once it is mined.'),
      const SizedBox(height: 24),
      BusyButton(label: 'Done', onPressed: () => Navigator.pop(context)),
    ];
  }
}
