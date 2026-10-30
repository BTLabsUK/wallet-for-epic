// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../password_estimate.dart';
import '../password_lists.dart';
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
    final usesPassphrase = ref.watch(usesPassphraseProvider).value ?? false;
    return SlotScaffold(
      centered: true,
      glow: heroGlow,
      appBar: AppBar(
        title: Text(
          !widget.passphrase
              ? l.settingsPinTitle
              : usesPassphrase
              ? l.settingsChangePassphrase
              : l.passphraseSetTitle,
        ),
      ),
      body: CenteredBody(
        children: [
          const Center(
            child: GlyphTile(size: 80, child: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 24),
          if (_currentPin == null) ...[
            Text(
              usesPassphrase ? l.passphraseEnterCurrent : l.settingsPinEnterCurrent,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PinField(
              controller: _current,
              label: usesPassphrase ? l.passphraseCurrentLabel : l.settingsPinCurrentLabel,
              enabled: !_busy,
              errorText: _pinError,
              onCompleted: _checkCurrent,
              passphrase: usesPassphrase,
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

/// A new passphrase, typed twice: the heading, the rules, the two fields with their eyes, the
/// strength hint under the first ([_PassphraseHint]), and Save. The rules are checked on Save:
/// too short or only digits under the first field, a mismatch under the second.
class _PassphraseSetup extends StatefulWidget {
  const _PassphraseSetup({required this.onDone});

  final ValueChanged<String> onDone;

  @override
  State<_PassphraseSetup> createState() => _PassphraseSetupState();
}

class _PassphraseSetupState extends State<_PassphraseSetup> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  String? _firstError;
  String? _secondError;

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
      _firstError = isValidPassphrase(first) ? null : l.passphraseChoose(minPassphraseLength);
      _secondError = _firstError == null && first != _second.text ? l.passphraseMismatch : null;
    });
    if (_firstError == null && _secondError == null) widget.onDone(first);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.passphraseChooseTitle,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l.passphraseRules(minPassphraseLength),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        PasswordField(
          key: const ValueKey('passphrase-new'),
          controller: _first,
          label: l.passphraseLabel,
          errorText: _firstError,
          textInputAction: TextInputAction.next,
        ),
        _PassphraseHint(controller: _first),
        const SizedBox(height: 8),
        PasswordField(
          key: const ValueKey('passphrase-repeat'),
          controller: _second,
          label: l.passphraseRepeat,
          errorText: _secondError,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 20),
        BusyButton(label: l.commonSave, onPressed: _save),
      ],
    );
  }
}

/// The estimator while the passphrase screen is open ([loadPasswordEstimator], the desktop's
/// word lists); released after it closes.
final _estimatorProvider = FutureProvider.autoDispose<PasswordEstimator>((ref) => loadPasswordEstimator());

/// The small print under a new passphrase: "14 characters · Strong". The count follows each
/// keystroke; the strength, from zxcvbn's guesses against [attackerGuessesPerSecond], comes a
/// moment after typing stops. It only informs; the rules alone decide what Save accepts. The
/// passphrase never leaves this widget.
class _PassphraseHint extends ConsumerStatefulWidget {
  const _PassphraseHint({required this.controller});

  final TextEditingController controller;

  static const delay = Duration(milliseconds: 150);

  @override
  ConsumerState<_PassphraseHint> createState() => _PassphraseHintState();
}

enum _Strength { weak, fair, strong }

class _PassphraseHintState extends ConsumerState<_PassphraseHint> {
  Timer? _timer;
  int _count = 0;
  _Strength? _strength;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _timer?.cancel();
    super.dispose();
  }

  void _changed() {
    final count = widget.controller.text.characters.length;
    _timer?.cancel();
    if (count != _count) setState(() => _count = count);
    if (count == 0) {
      setState(() => _strength = null);
      return;
    }
    _timer = Timer(_PassphraseHint.delay, _estimate);
  }

  void _estimate() {
    final estimator = ref.read(_estimatorProvider).value;
    final text = widget.controller.text;
    if (!mounted || estimator == null || text.isEmpty) return;
    final seconds = estimator.guesses(text) / attackerGuessesPerSecond;
    const day = 86400.0, year = 365.25 * day;
    setState(
      () => _strength = seconds < 30 * day
          ? _Strength.weak
          : seconds < 100 * year
          ? _Strength.fair
          : _Strength.strong,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Estimate as soon as the lists are ready, if typing came first.
    ref.listen(_estimatorProvider, (_, next) {
      if (next.hasValue && _count > 0 && _timer?.isActive != true) _estimate();
    });
    final l = context.l10n;
    final theme = Theme.of(context);
    final strength = switch (_strength) {
      null => null,
      _Strength.weak => (l.passphraseStrengthWeak, theme.colorScheme.error),
      _Strength.fair => (l.passphraseStrengthFair, theme.colorScheme.onSurfaceVariant),
      _Strength.strong => (l.passphraseStrengthStrong, theme.colorScheme.primary),
    };
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Semantics(
      label: l.passphraseStrengthLabel,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: SizedBox(
          height: 20,
          child: _count == 0
              ? null
              : Text.rich(
                  TextSpan(
                    text: l.passphraseCharacters(_count),
                    children: [
                      if (strength != null) ...[
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: strength.$1,
                          style: TextStyle(color: strength.$2, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                  style: small,
                  key: const ValueKey('passphrase-hint'),
                ),
        ),
      ),
    );
  }
}
