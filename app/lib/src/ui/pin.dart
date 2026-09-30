import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../providers.dart';
import '../vault.dart';
import 'common.dart';

/// A masked [pinLength]-digit field that calls [onCompleted] once all digits are in.
class PinField extends StatelessWidget {
  const PinField({
    super.key,
    required this.controller,
    required this.label,
    required this.onCompleted,
    this.errorText,
    this.enabled = true,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onCompleted;
  final String? errorText;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: pinLength,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(context).textTheme.headlineSmall
          ?.copyWith(letterSpacing: 12),
      onChanged: (value) {
        if (value.length == pinLength) onCompleted(value);
      },
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// Picks a PIN, confirms it, then asks about biometric unlock where the device has it.
/// Calls [onDone] once, with the PIN and the biometric answer.
class PinSetupView extends ConsumerStatefulWidget {
  const PinSetupView({
    super.key,
    required this.onDone,
    this.intro,
    this.askBiometrics = true,
    this.chooseTitle,
  });

  final void Function(String pin, bool useBiometrics) onDone;

  /// Whether to offer biometric unlock after the PIN. Off when changing an existing PIN.
  final bool askBiometrics;

  /// Replaces "Choose a 6-digit PIN".
  final String? chooseTitle;

  /// Shown above the first PIN field.
  final Widget? intro;

  @override
  ConsumerState<PinSetupView> createState() => _PinSetupViewState();
}

enum _PinStep { choose, confirm, biometrics }

class _PinSetupViewState extends ConsumerState<PinSetupView> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  late final Future<bool> _biometricsAvailable = ref
      .read(biometricStoreProvider)
      .isAvailable();
  _PinStep _step = _PinStep.choose;
  String? _error;
  String _chosen = '';

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _chosenPin(String pin) {
    setState(() {
      _chosen = pin;
      _error = null;
      _step = _PinStep.confirm;
    });
  }

  Future<void> _confirmed(String pin) async {
    if (pin != _chosen) {
      _confirm.clear();
      _pin.clear();
      setState(() {
        _chosen = '';
        _error = 'The PINs do not match. Choose a PIN again.';
        _step = _PinStep.choose;
      });
      return;
    }
    if (widget.askBiometrics && await _biometricsAvailable) {
      if (mounted) setState(() => _step = _PinStep.biometrics);
    } else {
      widget.onDone(pin, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (_step) {
        _PinStep.choose => [
          ?widget.intro,
          Text(
            widget.chooseTitle ?? 'Choose a $pinLength-digit PIN',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'You enter it to open the wallet and to confirm important actions.',
          ),
          const SizedBox(height: 16),
          PinField(
            key: const ValueKey('pin-choose'),
            controller: _pin,
            label: 'PIN',
            errorText: _error,
            onCompleted: _chosenPin,
          ),
        ],
        _PinStep.confirm => [
          Text('Enter the PIN again', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          PinField(
            key: const ValueKey('pin-confirm'),
            controller: _confirm,
            label: 'Repeat PIN',
            onCompleted: _confirmed,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _pin.clear();
              _confirm.clear();
              setState(() => _step = _PinStep.choose);
            },
            child: const Text('Choose a different PIN'),
          ),
        ],
        _PinStep.biometrics => [
          Icon(
            Icons.fingerprint,
            size: 64,
            color: theme.colorScheme.primary,
            semanticLabel: 'Biometrics',
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock with fingerprint or face?',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'You can still use your PIN at any time.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          BusyButton(
            label: 'Use biometrics',
            onPressed: () => widget.onDone(_chosen, true),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => widget.onDone(_chosen, false),
            child: const Text('Not now'),
          ),
        ],
      },
    );
  }
}

/// A sentence for a rejected PIN.
String describePinRejection(PinRejected rejection) {
  final until = rejection.lockedUntil;
  if (until != null) {
    final wait = until.difference(DateTime.now());
    final seconds = wait.inSeconds < 1 ? 1 : wait.inSeconds;
    final text = seconds < 120
        ? '$seconds seconds'
        : '${(seconds / 60).ceil()} minutes';
    return 'Too many wrong PINs. Try again in $text.';
  }
  final left = rejection.attemptsLeft ?? 0;
  return 'Wrong PIN. $left ${left == 1 ? 'try' : 'tries'} left before a pause.';
}

/// Asks for the PIN (or, with [allowBiometrics], biometrics) of the current wallet and returns
/// its password, or null if the user cancelled.
Future<String?> askWalletPassword(
  BuildContext context, {
  String? reason,
  bool allowBiometrics = true,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _PinPromptDialog(reason: reason, allowBiometrics: allowBiometrics),
  );
}

class _PinPromptDialog extends ConsumerStatefulWidget {
  const _PinPromptDialog({this.reason, required this.allowBiometrics});

  final String? reason;
  final bool allowBiometrics;

  @override
  ConsumerState<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends ConsumerState<_PinPromptDialog> {
  final _pin = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _biometrics = false;

  @override
  void initState() {
    super.initState();
    unawaited(_checkBiometrics());
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final config = ref.read(walletConfigProvider);
    if (config == null || !widget.allowBiometrics) return;
    final enabled = await ref
        .read(vaultProvider)
        .biometricsEnabled(config.chain);
    if (mounted) setState(() => _biometrics = enabled);
  }

  Future<void> _useBiometrics() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final password = await ref
        .read(vaultProvider)
        .unlockWithBiometrics(config.chain);
    if (password != null && mounted) Navigator.pop(context, password);
  }

  Future<void> _submit(String pin) async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final password = await ref
          .read(vaultProvider)
          .unlockWithPin(config.chain, pin);
      if (mounted) Navigator.pop(context, password);
    } on PinRejected catch (rejection) {
      _pin.clear();
      if (mounted) setState(() => _error = describePinRejection(rejection));
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter your PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.reason != null) ...[
            Text(widget.reason!),
            const SizedBox(height: 16),
          ],
          PinField(
            controller: _pin,
            label: 'PIN',
            enabled: !_busy,
            errorText: _error,
            onCompleted: _submit,
          ),
          if (_biometrics)
            TextButton.icon(
              icon: const Icon(Icons.fingerprint),
              label: const Text('Use biometrics'),
              onPressed: _busy ? null : _useBiometrics,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
