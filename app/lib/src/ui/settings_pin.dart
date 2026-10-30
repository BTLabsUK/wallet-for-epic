// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../vault.dart';
import 'centered_body.dart';
import 'common.dart';
import 'pin.dart';
import 'theme/brand.dart';

/// Asks for the current PIN, then a new one twice. Pops true when the PIN changed. With
/// [passphrase], the new one is a passphrase ([isValidPassphrase]) that replaces the PIN.
class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key, this.passphrase = false});

  final bool passphrase;

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  final _current = TextEditingController();
  String? _currentPin;
  String? _pinError;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _current.clear();
    _currentPin = null;
    _current.dispose();
    super.dispose();
  }

  Future<void> _checkCurrent(String pin) async {
    final config = ref.read(walletConfigProvider);
    final session = ref.read(sessionProvider);
    if (config == null || session == null || _busy) return;
    setState(() {
      _busy = true;
      _pinError = null;
      _error = null;
    });
    try {
      // Checked first so a wrong PIN is caught before choosing a new one; LEPIC counts it like
      // any other wrong PIN.
      await ref.read(vaultProvider).checkPin(session, config, pin);
      if (mounted) setState(() => _currentPin = pin);
    } on PinRejected catch (rejection) {
      if (mounted) {
        setState(
          () => _pinError = describePinRejection(context.l10n, rejection),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context.l10n, error));
    } finally {
      _current.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _change(String newPin, bool _) async {
    final config = ref.read(walletConfigProvider);
    final session = ref.read(sessionProvider);
    final currentPin = _currentPin;
    if (config == null || session == null || currentPin == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final biometricsKept = await ref
          .read(vaultProvider)
          .changePin(
            session,
            config,
            currentPin: currentPin,
            newPin: newPin,
          );
      ref.invalidate(usesPassphraseProvider);
      if (!mounted) return;
      final l = context.l10n;
      ref
          .read(noticeProvider.notifier)
          .show(
            widget.passphrase
                ? (biometricsKept ? l.passphraseSet : l.passphraseSetBiometricsOff)
                : biometricsKept
                ? l.settingsPinChanged
                : l.settingsPinChangedBiometricsOff,
            level: biometricsKept ? NoticeLevel.success : NoticeLevel.warning,
          );
      Navigator.pop(context, true);
    } on PinRejected catch (rejection) {
      if (mounted) {
        setState(() {
          _currentPin = null;
          _pinError = describePinRejection(context.l10n, rejection);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _currentPin = null;
          _error = describeError(context.l10n, error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SlotScaffold(
      centered: true,
      glow: heroGlow,
      appBar: AppBar(
        title: Text(widget.passphrase ? l.settingsUsePassphrase : l.settingsPinTitle),
      ),
      body: CenteredBody(
        children: [
          const Center(
            child: GlyphTile(size: 80, child: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 24),
          if (_currentPin == null) ...[
            Text(
              l.settingsPinEnterCurrent,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PinField(
              controller: _current,
              label: l.settingsPinCurrentLabel,
              enabled: !_busy,
              errorText: _pinError,
              onCompleted: _checkCurrent,
              passphrase: ref.watch(usesPassphraseProvider).value ?? false,
            ),
          ] else if (_busy)
            const LinearProgressIndicator()
          else if (widget.passphrase)
            _PassphraseSetup(onDone: (passphrase) => _change(passphrase, false))
          else
            PinSetupView(
              askBiometrics: false,
              chooseTitle: l.settingsPinChooseNew(pinLength),
              onDone: _change,
            ),
          if (_busy && _currentPin == null) const LinearProgressIndicator(),
          if (_error != null) ErrorText(_error!),
        ],
      ),
    );
  }
}

/// A new passphrase, typed twice. Minimal on purpose: the final design comes later.
class _PassphraseSetup extends StatefulWidget {
  const _PassphraseSetup({required this.onDone});

  final ValueChanged<String> onDone;

  @override
  State<_PassphraseSetup> createState() => _PassphraseSetupState();
}

class _PassphraseSetupState extends State<_PassphraseSetup> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _first.clear();
    _second.clear();
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _save() {
    final l = context.l10n;
    final first = _first.text;
    setState(() {
      _error = !isValidPassphrase(first)
          ? l.passphraseChoose(minPassphraseLength)
          : first != _second.text
          ? l.passphraseMismatch
          : null;
    });
    if (_error == null) widget.onDone(first);
  }

  InputDecoration _field(String label, {String? error}) => InputDecoration(
    labelText: label,
    errorText: error,
    errorMaxLines: 3,
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.passphraseChoose(minPassphraseLength),
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _first,
          autofocus: true,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          keyboardType: TextInputType.visiblePassword,
          decoration: _field(l.passphraseLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _second,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          keyboardType: TextInputType.visiblePassword,
          onSubmitted: (_) => _save(),
          decoration: _field(l.passphraseRepeat, error: _error),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}
