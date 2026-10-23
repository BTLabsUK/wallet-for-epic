import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../demo.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../vault.dart';
import '../wallet_service.dart';
import 'centered_body.dart';
import 'common.dart';
import 'demo_pin.dart';
import 'demo_screens.dart' show endDemo;
import 'first_run_screen.dart' show NetworkSettingsButton;
import 'launch_screen.dart';
import 'pin.dart';
import 'setup_screen.dart';
import 'theme/brand.dart';

/// Opens the wallet with the PIN or biometrics.
class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key, this.stranded = false});

  /// The wallet or its sealed text is missing ([VaultStage.stranded]): a notice says that
  /// nothing was deleted, and Forgot PIN stays the way to remove it.
  final bool stranded;

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  final _pin = TextEditingController();
  String? _pinError;
  String? _error;
  bool _busy = false;
  bool _biometrics = false;

  /// When LEPIC checks the PIN being tried, while it waits after repeated failures.
  DateTime? _checkAt;

  /// Web demo only: true while the demo PIN is filled in for the visitor, false for the PIN
  /// field, null until [_prepare] has looked. Outside the demo always false.
  bool? _autoPin;

  @override
  void initState() {
    super.initState();
    _autoPin = ref.read(demoModeProvider) ? null : false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  @override
  void dispose() {
    _pin.clear();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    if (!ref.read(demoModeProvider)) return _prepareUnlock();
    // In the demo the lookup goes to the server; a failure says so and offers Try again.
    try {
      await _prepareUnlock();
    } catch (error) {
      logWarn('unlock', 'demo lookup failed: ${describeError(englishStrings, error)}');
      if (mounted) setState(() => _error = describeError(context.l10n, error));
      return;
    }
    // Without a wallet config nothing was looked up; the PIN field shows.
    if (mounted && _autoPin == null) setState(() => _autoPin = false);
  }

  Future<void> _retryPrepare() async {
    setState(() => _error = null);
    await _prepare();
  }

  Future<void> _prepareUnlock() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    // Only a cold start or the auto-lock starts biometrics; after Lock wallet the user taps.
    final autoPrompt = ref.read(lockReasonProvider.notifier).takeAutoPrompt();
    final vault = ref.read(vaultProvider);
    // The count survives a restart; say what the next try costs before it is made.
    final failures = await ref
        .read(walletServiceProvider)
        .pinFailures(config: config);
    final biometrics = await vault.biometricsEnabled(config.chain);
    // A demo wallet made with the demo PIN gets it filled in, unless a try already failed.
    final autoPin =
        ref.read(demoModeProvider) &&
        failures == 0 &&
        await vault.usesDemoPin(config.chain);
    if (!mounted) return;
    setState(() {
      _biometrics = biometrics;
      _autoPin = autoPin;
      if (failures > 0) {
        _pinError = describePinRejection(context.l10n, PinRejected(failures));
      }
    });
    if (biometrics && !autoPin && autoPrompt) await _unlockWithBiometrics();
  }

  /// Opens the demo wallet with [demoPin] once the dots are filled. A rejected PIN leaves the
  /// field; any other error stays here with Try again.
  Future<void> _unlockWithDemoPin() async {
    await _unlockWithPin(demoPin);
    if (mounted && _pinError != null) setState(() => _autoPin = false);
  }

  Future<void> _unlockWithBiometrics() async {
    await _attempt((vault, config) => vault.unlockWithBiometrics(config));
  }

  Future<void> _unlockWithPin(String pin) async {
    await _attempt((vault, config) => vault.unlock(config, pin));
  }

  /// Runs one unlock; [open] answers null when the biometric prompt was dismissed.
  Future<void> _attempt(
    Future<WalletSession?> Function(WalletVault vault, WalletConfig config)
    open,
  ) async {
    final config = ref.read(walletConfigProvider);
    if (config == null || _busy) return;
    final l = context.l10n;
    final vault = ref.read(vaultProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    final checkAt = await pinCheckTime(ref);
    if (mounted) setState(() => _checkAt = checkAt);
    try {
      final session = await open(vault, config);
      if (session == null) {
        // Dismissed, or the copy is gone after a new enrollment.
        final still = await vault.biometricsEnabled(config.chain);
        if (mounted) setState(() => _biometrics = still);
        return;
      }
      await ref.read(sessionProvider.notifier).open(session);
      if (mounted) goHome(context);
    } on PinRejected catch (rejection) {
      _pin.clear();
      final still = await vault.biometricsEnabled(config.chain);
      if (!mounted) return;
      setState(() {
        _biometrics = still;
        _pinError = describePinRejection(l, rejection);
      });
    } catch (error) {
      logWarn('unlock', 'unlock failed: ${describeError(englishStrings, error)}');
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

  Future<void> _forgotPin() async {
    // A demo wallet has no phrase to restore from: forgetting its PIN ends the demo.
    if (ref.read(demoModeProvider)) return endDemo(context, ref);
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
    final checkAt = _checkAt;
    return SlotScaffold(
      centered: true,
      glow: heroGlow,
      // The title is the hero's heading; the bar only holds the network action.
      appBar: AppBar(
        actions: [
          // The web demo is on floonet for good.
          if (!ref.watch(demoModeProvider))
            NetworkSettingsButton(
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
          BrandHero(
            // The demo PIN needs no network jargon: the visitor only watches it open.
            title: _autoPin != false
                ? l.demoPinUnlockTitle
                // The header's Test coins pill names the network in the demo.
                : config == null || ref.watch(demoModeProvider)
                ? l.unlockTitle
                : '${l.unlockTitle}${networkSuffix(l, config.chain)}',
          ),
          const SizedBox(height: 28),
          if (widget.stranded) ...[
            ErrorText(l.unlockStranded),
            const SizedBox(height: 16),
          ],
          switch (_autoPin) {
            // A frame or two while the demo looks up how its wallet opens.
            null => const SizedBox(height: 56),
            true => DemoPinFill(onDone: _unlockWithDemoPin),
            false => PinField(
              controller: _pin,
              label: l.pinLabel,
              enabled: !_busy,
              errorText: _pinError,
              onCompleted: _unlockWithPin,
            ),
          },
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          if (_busy && checkAt != null) ...[
            const SizedBox(height: 8),
            PinWaitNote(until: checkAt),
          ],
          if (_error != null) ErrorText(_error!),
          if (_autoPin != false && _error != null)
            BusyButton(
              label: l.launchTryAgain,
              busy: _busy,
              onPressed: _autoPin == null ? _retryPrepare : _unlockWithDemoPin,
            ),
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
          // Forgot PIN ends a demo; it stays away while the demo PIN fills in, and comes back
          // with an error or the PIN field.
          if (_autoPin == false || _error != null) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: _busy ? null : _forgotPin,
              child: Text(l.pinForgot),
            ),
          ],
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
