// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../demo.dart';
import '../errors.dart';
import '../l10n.dart';
import '../pin_wrap.dart' show PinKeyLost;
import '../providers.dart';
import '../restore_scan.dart' show historyImportOfferProvider;
import '../vault.dart';
import '../wallet_service.dart';
import 'app_dialog.dart';
import 'centered_body.dart';
import 'common.dart';
import 'demo_pin.dart';
import 'demo_screens.dart' show endDemo;
import 'first_run_screen.dart' show NetworkSettingsButton;
import 'launch_screen.dart';
import 'pin.dart';
import 'theme/brand.dart';
import 'wallet_delete.dart';

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

  /// The biometric prompt is up. The PIN field stays usable meanwhile: a prompt the system
  /// never answers must not hold the screen.
  bool _reading = false;

  /// When LEPIC checks the PIN being tried, while it waits after repeated failures.
  DateTime? _checkAt;

  /// The copy step of a first unlock after the update, while it runs; null otherwise.
  StoreMigrationProgress? _copy;

  /// The user's choice between the PIN and the passphrase field, over the stored mode. Only a
  /// wallet that ever had a passphrase is offered it: if the app stopped between the new
  /// sealed text and the recorded mode, the field would otherwise not fit the secret.
  bool? _passphraseChosen;

  /// Web demo only: true while the demo PIN is filled in for the visitor, false for the PIN
  /// field, null until [_prepare] has looked. Outside the demo always false.
  bool? _autoPin;

  /// Web demo and preview ([pinlessProvider]): the wallet opens with one tap, no PIN. On a
  /// cold start it opens by itself.
  bool _noPin = false;

  @override
  void initState() {
    super.initState();
    _autoPin = ref.read(demoModeProvider) || ref.read(pinlessProvider) ? null : false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  @override
  void dispose() {
    _pin.clear();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    if (!ref.read(demoModeProvider) && !ref.read(pinlessProvider)) {
      return _prepareUnlock();
    }
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
    final coldStart = ref.read(lockReasonProvider) == LockReason.coldStart;
    // Only a cold start or the auto-lock starts biometrics; after Lock wallet the user taps.
    final autoPrompt = ref.read(lockReasonProvider.notifier).takeAutoPrompt();
    final vault = ref.read(vaultProvider);
    // The count survives a restart; say what the next try costs before it is made.
    final int failures;
    try {
      failures = await ref.read(walletServiceProvider).pinFailures(config: config);
    } on PinKeyLost catch (error) {
      // The PIN cannot open this wallet any more: said before a PIN is typed, with Forgot PIN.
      if (mounted) setState(() => _error = describeError(context.l10n, error));
      return;
    }
    final biometrics = await vault.biometricsEnabled(config.chain);
    // A demo wallet made with the demo PIN gets it filled in, unless a try already failed; in a
    // build without PINs it opens with a tap instead.
    final demoPinWallet = failures == 0 && await vault.usesDemoPin(config.chain);
    final noPin = ref.read(pinlessProvider) && demoPinWallet;
    final autoPin = !noPin && ref.read(demoModeProvider) && demoPinWallet;
    if (!mounted) return;
    setState(() {
      _biometrics = biometrics && !noPin;
      _autoPin = autoPin;
      _noPin = noPin;
      if (failures > 0) {
        _pinError = describePinRejection(context.l10n, PinRejected(failures));
      }
    });
    // Starting the app goes straight into the wallet; after a lock the Unlock button opens it.
    if (noPin && coldStart) return _unlockWithDemoPin();
    if (biometrics && !autoPin && autoPrompt) await _unlockWithBiometrics();
  }

  /// Opens the demo wallet with [demoPin] once the dots are filled. A rejected PIN leaves the
  /// field; any other error stays here with Try again.
  Future<void> _unlockWithDemoPin() async {
    await _unlockWithPin(demoPin);
    if (mounted && _pinError != null) {
      setState(() {
        _autoPin = false;
        _noPin = false;
      });
    }
  }

  Future<void> _unlockWithBiometrics() async {
    final config = ref.read(walletConfigProvider);
    if (config == null || _busy || _reading) return;
    final vault = ref.read(vaultProvider);
    setState(() => _reading = true);
    final String? pin;
    try {
      pin = await vault.readBiometricPin(config.chain);
    } on Object catch (error) {
      // As an unlock that failed: said under the field, the PIN still usable.
      logWarn('unlock', 'biometric read failed: ${describeError(englishStrings, error)}');
      if (mounted) setState(() => _error = describeError(context.l10n, error));
      return;
    } finally {
      if (mounted) setState(() => _reading = false);
    }
    // Unlocked with the PIN meanwhile, or gone.
    if (!mounted || _busy || ref.read(sessionProvider) != null) return;
    if (pin == null) {
      // Dismissed, or the copy is gone after a new enrollment.
      final still = await vault.biometricsEnabled(config.chain);
      if (mounted) setState(() => _biometrics = still);
      return;
    }
    final String found = pin;
    await _attempt((vault, config) => vault.unlockWithBiometricPin(config, found));
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
    // LEPIC's open copies the records into the encrypted store on the first unlock after the
    // update; the line shows while it does. It restarts cleanly, so nothing asks to wait.
    final copying = ref.read(walletServiceProvider).storeMigrationProgress.listen((p) {
      if (mounted) setState(() => _copy = p.finished ? null : p);
    });
    try {
      var rebuilt = false;
      WalletSession? session;
      try {
        session = await open(vault, config);
      } on WalletError catch (e) {
        if (e.kind != WalletErrorKind.damagedDatabase) rethrow;
        // The core set the damaged database aside; opening again rebuilds it from the phrase,
        // and the restore scan then brings the funds back (restore_scan.dart).
        logWarn('unlock', 'wallet database damaged: opening a rebuilt one');
        rebuilt = true;
        session = await open(vault, config);
      }
      if (session == null) {
        // Dismissed, or the copy is gone after a new enrollment.
        final still = await vault.biometricsEnabled(config.chain);
        if (mounted) setState(() => _biometrics = still);
        return;
      }
      await ref.read(sessionProvider.notifier).open(session);
      if (session.storeOpen == StoreOpenOutcome.plainFallback) {
        ref.read(noticeProvider.notifier).show(l.storeRecordsPlain, level: NoticeLevel.info, persistent: true);
      }
      if (rebuilt) {
        ref
            .read(noticeProvider.notifier)
            .show(l.unlockDatabaseRebuilt, level: NoticeLevel.warning, persistent: true);
        ref.read(historyImportOfferProvider.notifier).set(true);
      }
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
      unawaited(copying.cancel());
      if (mounted) {
        setState(() {
          _busy = false;
          _checkAt = null;
          _copy = null;
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
    final confirmed = await showAppDialog<bool>(context, builder: (_) => const _ResetDialog());
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      // The same clean-up as Settings › Delete: backup note, shared files.
      await deleteWalletEverywhere(ref, config);
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

  void _switchMode(bool passphrase) {
    _pin.clear();
    setState(() {
      _passphraseChosen = passphrase;
      _pinError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(walletConfigProvider);
    final checkAt = _checkAt;
    final passphrase = _passphraseChosen ?? (ref.watch(usesPassphraseProvider).value ?? false);
    final canSwitch = ref.watch(passphraseEverUsedProvider).value ?? false;
    return SlotScaffold(
      centered: true,
      glow: heroGlow,
      // The title is the hero's heading; the bar only holds the network action.
      appBar: AppBar(
        actions: [
          // The web demo is on floonet for good.
          if (!ref.watch(demoModeProvider))
            NetworkSettingsButton(enabled: !_busy),
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
                : ref.watch(devNetworksProvider)
                ? '${l.unlockTitle}${networkSuffix(l, config.chain)}'
                : l.unlockTitle,
          ),
          const SizedBox(height: 28),
          if (widget.stranded) ...[
            ErrorText(l.unlockStranded),
            const SizedBox(height: 16),
          ],
          if (_noPin)
            BusyButton(
              label: l.pinlessUnlock,
              busy: _busy,
              onPressed: _unlockWithDemoPin,
            )
          else
            switch (_autoPin) {
              // A frame or two while the demo looks up how its wallet opens.
              null => const SizedBox(height: 56),
              true => DemoPinFill(onDone: _unlockWithDemoPin),
              false => PinField(
                // The field changes with the mode, so its state (the eye, focus) starts over.
                key: ValueKey(passphrase ? 'unlock-passphrase' : 'unlock-pin'),
                controller: _pin,
                label: passphrase ? l.passphraseLabel : l.pinLabel,
                enabled: !_busy,
                errorText: _pinError,
                onCompleted: _unlockWithPin,
                passphrase: passphrase,
              ),
            },
          const SizedBox(height: 16),
          if (_busy && _copy != null)
            StoreCopyLine(progress: _copy!)
          else if (_busy)
            const PinCheckBar(),
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
              onPressed: _busy || _reading ? null : _unlockWithBiometrics,
            ),
          ],
          // Forgot PIN ends a demo; it stays away while the demo PIN fills in, and comes back
          // with an error or the PIN field.
          if (!_noPin && (_autoPin == false || _error != null)) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: _busy ? null : _forgotPin,
              child: Text(passphrase ? l.passphraseForgot : l.pinForgot),
            ),
            // Quiet, under Forgot: the way out when the stored mode and the secret disagree.
            if (canSwitch && _autoPin == false)
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: _busy ? null : () => _switchMode(!passphrase),
                child: Text(
                  passphrase ? l.passphraseUsePinInstead : l.passphraseUsePassphraseInstead,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
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
    return AppDialog(
      title: l.pinResetTitle,
      icon: Icons.delete_forever_outlined,
      tone: DialogTone.risk,
      description: l.pinResetBody,
      body: DialogCheckRow(
        value: _understood,
        onChanged: (value) => setState(() => _understood = value),
        label: l.pinResetConfirm,
      ),
      actions: [
        DialogButton.secondary(label: l.pinResetKeep, onPressed: () => Navigator.pop(context, false)),
        DialogButton.risk(label: l.pinResetDelete, onPressed: _understood ? () => Navigator.pop(context, true) : null),
      ],
    );
  }
}

/// The copy step of a first unlock after the update: "Encrypting wallet records…" and a bar.
class StoreCopyLine extends StatelessWidget {
  const StoreCopyLine({super.key, required this.progress});

  final StoreMigrationProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fraction = progress.fraction;
    return Semantics(
      liveRegion: true,
      child: Column(
        key: const ValueKey('store-copy'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              Flexible(child: Text(l.storeEncrypting, textAlign: TextAlign.center)),
            ],
          ),
          if (fraction != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: fraction),
          ],
        ],
      ),
    );
  }
}
