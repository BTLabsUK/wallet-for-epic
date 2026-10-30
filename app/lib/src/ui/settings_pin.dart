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
import 'info_hint.dart';
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

/// The small print under a new passphrase: "14 characters · about 300 years to crack", the
/// phone twin of the desktop's `PasswordHint` (same [characterCount] and
/// [PasswordEstimator.crackTime], so both read the same). The count follows every keystroke;
/// the time comes [estimateDelay] after typing stops. It only informs: nothing here blocks
/// Save, the rules alone decide what it accepts, and no colour judges the passphrase. Screen
/// readers hear the time in a live region, [announceDelay] after typing stops and only when
/// it changed. The info icon opens an [InfoSheet] with how the time is estimated. The
/// passphrase and the estimate never leave this widget.
class _PassphraseHint extends ConsumerStatefulWidget {
  const _PassphraseHint({required this.controller});

  final TextEditingController controller;

  static const estimateDelay = Duration(milliseconds: 150);
  static const announceDelay = Duration(seconds: 1);

  @override
  ConsumerState<_PassphraseHint> createState() => _PassphraseHintState();
}

class _PassphraseHintState extends ConsumerState<_PassphraseHint> {
  Timer? _estimateTimer;
  Timer? _announceTimer;
  int _count = 0;
  String? _time;
  String _announced = '';

  @override
  void initState() {
    super.initState();
    _count = widget.controller.text.characters.length;
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _estimateTimer?.cancel();
    _announceTimer?.cancel();
    super.dispose();
  }

  void _changed() {
    final count = widget.controller.text.characters.length;
    _estimateTimer?.cancel();
    _announceTimer?.cancel();
    if (count == 0) {
      setState(() {
        _count = 0;
        _time = null;
        _announced = '';
      });
      return;
    }
    if (count != _count) setState(() => _count = count);
    _estimateTimer = Timer(_PassphraseHint.estimateDelay, _estimate);
  }

  void _estimate() {
    final estimator = ref.read(_estimatorProvider).value;
    final text = widget.controller.text;
    if (!mounted || estimator == null || text.isEmpty) return;
    setState(() => _time = estimator.crackTime(text));
    _announceTimer = Timer(_PassphraseHint.announceDelay - _PassphraseHint.estimateDelay, () {
      if (mounted && _time != null && _time != _announced) setState(() => _announced = _time!);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Estimate as soon as the lists are ready, if typing came first.
    ref.listen(_estimatorProvider, (_, next) {
      if (next.hasValue && widget.controller.text.isNotEmpty && _estimateTimer?.isActive != true) _estimate();
    });
    final l = context.l10n;
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final line = _count == 0 ? '' : [characterCount(_count), ?_time].join(' · ');
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Flexible(
              child: Semantics(
                liveRegion: true,
                label: _announced,
                child: ExcludeSemantics(
                  child: Text(line, key: const ValueKey('passphrase-hint'), style: small),
                ),
              ),
            ),
            if (_count > 0) ...[
              const SizedBox(width: 4),
              InfoHint(
                l.deskKitPasswordNote,
                key: const ValueKey('passphrase-hint-info'),
                size: 48,
                title: l.deskKitPasswordNoteLabel,
                icon: Icons.info_outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
