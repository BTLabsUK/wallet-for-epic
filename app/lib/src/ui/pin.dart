import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../vault.dart';
import 'common.dart';
import 'demo_pin.dart';

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
  bool _mismatch = false;
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
      _mismatch = false;
      _step = _PinStep.confirm;
    });
  }

  Future<void> _confirmed(String pin) async {
    if (pin != _chosen) {
      _confirm.clear();
      _pin.clear();
      setState(() {
        _chosen = '';
        _mismatch = true;
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
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (_step) {
        _PinStep.choose => [
          ?widget.intro,
          Text(
            widget.chooseTitle ?? l.pinChooseTitle(pinLength),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PinField(
            key: const ValueKey('pin-choose'),
            controller: _pin,
            label: l.pinLabel,
            errorText: _mismatch ? l.pinMismatch : null,
            onCompleted: _chosenPin,
          ),
        ],
        _PinStep.confirm => [
          Text(
            l.pinConfirmTitle,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PinField(
            key: const ValueKey('pin-confirm'),
            controller: _confirm,
            label: l.pinRepeatLabel,
            onCompleted: _confirmed,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _pin.clear();
              _confirm.clear();
              setState(() => _step = _PinStep.choose);
            },
            child: Text(l.pinChooseDifferent),
          ),
        ],
        _PinStep.biometrics => [
          Icon(
            Icons.fingerprint,
            size: 64,
            color: theme.colorScheme.primary,
            semanticLabel: l.pinBiometricsIconLabel,
          ),
          const SizedBox(height: 16),
          Text(
            l.pinBiometricsQuestion,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(l.pinBiometricsPinStillWorks, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          BusyButton(
            label: l.pinBiometricsEnable,
            onPressed: () => widget.onDone(_chosen, true),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => widget.onDone(_chosen, false),
            child: Text(l.pinBiometricsNotNow),
          ),
        ],
      },
    );
  }
}

/// A sentence for a wait before LEPIC checks a PIN: seconds up to two minutes, then minutes.
String _describeWait(
  Duration wait,
  String Function(int) seconds,
  String Function(int) minutes,
) {
  final s = wait.inSeconds < 1 ? 1 : wait.inSeconds;
  return s < 120 ? seconds(s) : minutes((s / 60).ceil());
}

/// A sentence for a rejected PIN: the tries left, or how long the next one waits.
String describePinRejection(AppLocalizations l, PinRejected rejection) {
  final wait = rejection.nextWait;
  if (wait == Duration.zero) return l.pinWrong(rejection.attemptsLeft);
  return _describeWait(wait, l.pinWrongWaitSeconds, l.pinWrongWaitMinutes);
}

/// Counts down to [until], while LEPIC waits before it checks a PIN after repeated failures.
class PinWaitNote extends StatefulWidget {
  const PinWaitNote({super.key, required this.until});

  final DateTime until;

  @override
  State<PinWaitNote> createState() => _PinWaitNoteState();
}

class _PinWaitNoteState extends State<PinWaitNote> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final left = widget.until.difference(DateTime.now());
    return Text(
      left <= Duration.zero
          ? l.pinChecking
          : _describeWait(left, l.pinCheckingSeconds, l.pinCheckingMinutes),
      textAlign: TextAlign.center,
    );
  }
}

/// When a PIN typed now will be checked, or null if at once.
Future<DateTime?> pinCheckTime(WidgetRef ref) async {
  final config = ref.read(walletConfigProvider);
  if (config == null) return null;
  final wait = await ref.read(vaultProvider).nextPinWait(config);
  return wait == Duration.zero ? null : DateTime.now().add(wait);
}

/// Asks for the PIN of the open wallet (or, with [allowBiometrics], its biometric copy) and
/// runs [action] with it. Returns what [action] returned, or null if the user cancelled. A
/// wrong PIN ([PinRejected] from [action]) is shown in the dialog and asked again.
Future<T?> askPin<T extends Object>(
  BuildContext context, {
  String? reason,
  bool allowBiometrics = true,
  required Future<T> Function(String pin) action,
}) {
  return showDialog<T>(
    context: context,
    builder: (_) => _PinPromptDialog<T>(
      reason: reason,
      allowBiometrics: allowBiometrics,
      action: action,
    ),
  );
}

class _PinPromptDialog<T extends Object> extends ConsumerStatefulWidget {
  const _PinPromptDialog({
    this.reason,
    required this.allowBiometrics,
    required this.action,
  });

  final String? reason;
  final bool allowBiometrics;
  final Future<T> Function(String pin) action;

  @override
  ConsumerState<_PinPromptDialog<T>> createState() =>
      _PinPromptDialogState<T>();
}

class _PinPromptDialogState<T extends Object>
    extends ConsumerState<_PinPromptDialog<T>> {
  final _pin = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _biometrics = false;
  DateTime? _checkAt;

  /// Web demo only: true while the demo PIN is filled in, false for the PIN field, null until
  /// [_checkDemoPin] has looked. Outside the demo always false.
  bool? _autoPin;

  @override
  void initState() {
    super.initState();
    if (ref.read(demoModeProvider)) {
      unawaited(_checkDemoPin());
    } else {
      _autoPin = false;
    }
    unawaited(_checkBiometrics());
  }

  Future<void> _checkDemoPin() async {
    final config = ref.read(walletConfigProvider);
    var auto = false;
    try {
      auto =
          config != null &&
          await ref.read(vaultProvider).usesDemoPin(config.chain);
    } catch (_) {
      // Unreadable: the PIN field shows.
    }
    if (mounted) setState(() => _autoPin = auto);
  }

  /// Runs the action with [demoPin]; if it fails, the field shows with the error.
  Future<void> _runDemoPin() async {
    await _run(demoPin);
    if (mounted && _error != null) setState(() => _autoPin = false);
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
    if (!mounted) return;
    setState(() => _biometrics = enabled);
    // Biometrics go first, as on the unlock screen; the PIN stays for a dismissed prompt.
    if (enabled) await _useBiometrics();
  }

  Future<void> _useBiometrics() async {
    final config = ref.read(walletConfigProvider);
    if (config == null || _busy) return;
    final vault = ref.read(vaultProvider);
    final pin = await vault.readBiometricPin(config.chain);
    if (pin == null) {
      final still = await vault.biometricsEnabled(config.chain);
      if (mounted) setState(() => _biometrics = still);
      return;
    }
    await _run(pin, biometric: true);
  }

  Future<void> _run(String pin, {bool biometric = false}) async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    final checkAt = await pinCheckTime(ref);
    if (mounted) setState(() => _checkAt = checkAt);
    try {
      final result = await widget.action(pin);
      if (mounted) Navigator.pop(context, result);
    } on PinRejected catch (rejection) {
      _pin.clear();
      final config = ref.read(walletConfigProvider);
      // A biometric copy that no longer opens is of no use.
      if (biometric && config != null) {
        await ref.read(vaultProvider).disableBiometrics(config.chain);
      }
      if (mounted) {
        setState(() {
          if (biometric) _biometrics = false;
          _error = describePinRejection(l, rejection);
        });
      }
    } catch (error) {
      _pin.clear();
      if (mounted) setState(() => _error = describeError(l, error));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _checkAt = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final checkAt = _checkAt;
    // Closing the dialog would not stop a running action (LEPIC may wait up to an hour before
    // it checks the PIN), so it stays open until the action ends.
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(l.pinPromptTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.reason != null) ...[
              Text(widget.reason!),
              const SizedBox(height: 16),
            ],
            switch (_autoPin) {
              null => const SizedBox(height: 56),
              true => DemoPinFill(compact: true, onDone: _runDemoPin),
              false => PinField(
                controller: _pin,
                label: l.pinLabel,
                enabled: !_busy,
                errorText: _error,
                onCompleted: _run,
              ),
            },
            if (_busy) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              if (checkAt != null) ...[
                const SizedBox(height: 8),
                PinWaitNote(until: checkAt),
              ],
            ],
            if (_biometrics)
              TextButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: Text(l.pinUseBiometrics),
                onPressed: _busy ? null : _useBiometrics,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l.commonCancel),
          ),
        ],
      ),
    );
  }
}
