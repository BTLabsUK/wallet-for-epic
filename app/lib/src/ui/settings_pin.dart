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

/// Asks for the current PIN, then a new one twice. Pops true when the PIN changed.
class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

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
    _current.dispose();
    super.dispose();
  }

  Future<void> _checkCurrent(String pin) async {
    final config = ref.read(walletConfigProvider);
    if (config == null || _busy) return;
    setState(() {
      _busy = true;
      _pinError = null;
      _error = null;
    });
    try {
      // Checked first so a wrong PIN is caught before choosing a new one; it counts towards
      // the lockout like any other wrong PIN.
      await ref.read(vaultProvider).unlockWithPin(config.chain, pin);
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
    final currentPin = _currentPin;
    if (config == null || currentPin == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(vaultProvider)
          .changePin(config.chain, currentPin: currentPin, newPin: newPin);
      if (!mounted) return;
      ref.read(noticeProvider.notifier).show(context.l10n.settingsPinChanged);
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
      appBar: AppBar(title: Text(l.settingsPinTitle)),
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
            ),
          ] else if (_busy)
            const LinearProgressIndicator()
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
