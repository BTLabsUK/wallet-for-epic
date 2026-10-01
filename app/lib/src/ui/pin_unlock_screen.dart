import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../vault.dart';
import 'centered_body.dart';
import 'common.dart';
import 'launch_screen.dart';
import 'pin.dart';
import 'setup_screen.dart';

/// Opens the wallet with the PIN or biometrics.
class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  final _pin = TextEditingController();
  String? _pinError;
  String? _error;
  bool _busy = false;
  bool _biometrics = false;
  DateTime? _lockedUntil;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final vault = ref.read(vaultProvider);
    final lockedUntil = await vault.lockedUntil(config.chain);
    if (lockedUntil != null) _lockOut(lockedUntil);
    final biometrics = await vault.biometricsEnabled(config.chain);
    if (!mounted) return;
    setState(() => _biometrics = biometrics);
    if (biometrics) await _unlockWithBiometrics();
  }

  void _lockOut(DateTime until) {
    _lockTimer?.cancel();
    setState(() => _lockedUntil = until);
    _lockTimer = Timer(until.difference(DateTime.now()), () {
      if (mounted) {
        setState(() {
          _lockedUntil = null;
          _pinError = null;
        });
      }
    });
  }

  Future<void> _unlockWithBiometrics() async {
    final config = ref.read(walletConfigProvider);
    if (config == null || _busy) return;
    final password = await ref
        .read(vaultProvider)
        .unlockWithBiometrics(config.chain);
    if (password == null) {
      // Dismissed, or the copy is gone after a new enrollment.
      final still = await ref
          .read(vaultProvider)
          .biometricsEnabled(config.chain);
      if (mounted) setState(() => _biometrics = still);
      return;
    }
    await _open(password);
  }

  Future<void> _unlockWithPin(String pin) async {
    final config = ref.read(walletConfigProvider);
    if (config == null || _busy) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _pinError = null;
      _error = null;
    });
    try {
      final password = await ref
          .read(vaultProvider)
          .unlockWithPin(config.chain, pin);
      await _open(password);
    } on PinRejected catch (rejection) {
      _pin.clear();
      if (!mounted) return;
      setState(() => _pinError = describePinRejection(l, rejection));
      final until = rejection.lockedUntil;
      if (until != null) _lockOut(until);
    } catch (error) {
      logWarn(
        'unlock',
        'PIN unlock failed: ${describeError(englishStrings, error)}',
      );
      _pin.clear();
      if (mounted) setState(() => _error = describeError(l, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String password) async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final session = await ref
          .read(walletServiceProvider)
          .open(config: config, password: password);
      ref.read(sessionProvider.notifier).unlocked(session);
      if (mounted) goHome(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(l, error);
        });
      }
    }
  }

  Future<void> _forgotPin() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ResetDialog(),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      ref.read(sessionProvider.notifier).lock();
      await ref.read(walletServiceProvider).deleteWallet(config: config);
      await ref.read(vaultProvider).forget(config.chain);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(l, error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(walletConfigProvider);
    final locked = _lockedUntil != null;
    return SlotScaffold(
      centered: true,
      appBar: AppBar(
        title: Text(
          config == null
              ? l.unlockTitle
              : '${l.unlockTitle}${networkSuffix(l, config.chain)}',
        ),
        actions: [
          IconButton(
            tooltip: l.setupNetworkSettingsTooltip,
            icon: const Icon(Icons.settings_ethernet),
            onPressed: _busy
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SetupScreen(),
                    ),
                  ),
          ),
        ],
      ),
      body: CenteredBody(
        children: [
          PinField(
            controller: _pin,
            label: l.pinLabel,
            enabled: !_busy && !locked,
            errorText: _pinError,
            onCompleted: _unlockWithPin,
          ),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) ErrorText(_error!),
          if (_biometrics) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.fingerprint),
              label: Text(l.pinUseBiometrics),
              onPressed: _busy ? null : _unlockWithBiometrics,
            ),
          ],
          const SizedBox(height: 24),
          TextButton(
            onPressed: _busy ? null : _forgotPin,
            child: Text(l.pinForgot),
          ),
        ],
      ),
    );
  }
}

class _ResetDialog extends StatefulWidget {
  const _ResetDialog();

  @override
  State<_ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<_ResetDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: Text(l.pinResetTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.pinResetBody),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _understood,
            onChanged: (value) => setState(() => _understood = value ?? false),
            title: Text(l.pinResetConfirm),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.pinResetKeep),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: error),
          onPressed: _understood ? () => Navigator.pop(context, true) : null,
          child: Text(l.pinResetDelete),
        ),
      ],
    );
  }
}
