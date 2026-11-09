// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../contact_store.dart' show ContactStore;
import '../dev_networks.dart';
import '../errors.dart';
import '../l10n.dart';
import '../pin_wrap.dart' show KeyWrapUnavailable, PinKeyLost;
import '../providers.dart';
import '../restore_scan.dart' show historyImportOfferProvider;
import '../trust_ids.dart';
import '../vault.dart';
import '../wallet_service.dart';
import 'app_dialog.dart';
import 'centered_body.dart';
import 'common.dart';
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

  /// The step of a Forgot PIN delete under way, for the line under the bar.
  DeleteStep? _deleting;
  bool _biometrics = false;

  /// The phone's Keystore did not release the PIN key: the wallet is intact, so Try again
  /// stands where Forgot PIN was.
  bool _keyRefused = false;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareUnlock());
  }

  @override
  void dispose() {
    _pin.clear();
    _pin.dispose();
    // An unlock left without opening a wallet: the address book key a wallet switch kept goes
    // (after an unlock the next wallet took it over, and nothing is kept).
    unawaited(ContactStore.dropHeldKeys());
    super.dispose();
  }

  Future<void> _prepareUnlock() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    // Only a cold start or the auto-lock starts biometrics; after Lock wallet the user taps.
    final autoPrompt = ref.read(lockReasonProvider.notifier).takeAutoPrompt();
    final vault = ref.read(vaultProvider);
    // The count survives a restart; say what the next try costs before it is made.
    var failures = 0;
    try {
      failures = await ref.read(walletServiceProvider).pinFailures(config: config);
    } on PinKeyLost catch (error) {
      // The PIN cannot open this wallet any more: said before a PIN is typed, with Forgot PIN.
      if (mounted) setState(() => _error = describeError(context.l10n, error));
      return;
    } catch (error) {
      // A Keystore that cannot answer now: the attempt reads the count again, and biometrics
      // are offered as ever.
      logWarn('unlock', 'PIN count not read: ${describeError(englishStrings, error)}');
    }
    final biometrics = await vault.biometricsEnabled(config.chain);
    if (!mounted) return;
    setState(() {
      _biometrics = biometrics;
      if (failures > 0) {
        _pinError = describePinRejection(context.l10n, PinRejected(failures));
      }
    });
    if (biometrics && autoPrompt) await _unlockWithBiometrics();
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
      _keyRefused = false;
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
      // A failed unlock wipes the address book key a wallet switch kept.
      unawaited(ContactStore.dropHeldKeys());
      final still = await vault.biometricsEnabled(config.chain);
      if (!mounted) return;
      setState(() {
        _biometrics = still;
        _pinError = describePinRejection(l, rejection);
      });
    } on KeyWrapUnavailable catch (error) {
      // The PIN typed stays, for Try again.
      unawaited(ContactStore.dropHeldKeys());
      logWarn('unlock', 'unlock failed: ${describeError(englishStrings, error)}');
      if (mounted) {
        setState(() {
          _error = describeError(l, error);
          _keyRefused = true;
        });
      }
    } catch (error) {
      logWarn('unlock', 'unlock failed: ${describeError(englishStrings, error)}');
      unawaited(ContactStore.dropHeldKeys());
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

  /// After a Keystore refusal: the PIN still in the field, else biometrics.
  Future<void> _tryAgain() async {
    setState(() {
      _keyRefused = false;
      _error = null;
    });
    if (_pin.text.isNotEmpty) {
      await _unlockWithPin(_pin.text);
    } else if (_biometrics) {
      await _unlockWithBiometrics();
    }
  }

  Future<void> _forgotPin() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final l = context.l10n;
    final confirmed = await showAppDialog<bool>(context, builder: (_) => const _ResetDialog());
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _deleting = DeleteStep.files;
    });
    try {
      // The same clean-up as Settings › Delete: backup note, shared files.
      await deleteWalletEverywhere(
        ref,
        config,
        onStep: (step) {
          if (mounted) setState(() => _deleting = step);
        },
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _deleting = null;
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
          NetworkSettingsButton(enabled: !_busy),
        ],
      ),
      body: CenteredBody(
        children: [
          BrandHero(
            title: config == null
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
          PinField(
            // The field changes with the mode, so its state (the eye, focus) starts over.
            key: ValueKey(passphrase ? 'unlock-passphrase' : 'unlock-pin'),
            controller: _pin,
            label: passphrase ? l.passphraseLabel : l.pinLabel,
            enabled: !_busy,
            errorText: _pinError,
            onCompleted: _unlockWithPin,
            passphrase: passphrase,
            // The error line's room is kept, so a wrong PIN moves nothing below.
            reserveError: true,
          ),
          const SizedBox(height: 8),
          // One slot for the check's bar or the error: Forgot PIN stays where it is whether a
          // check runs, failed or has not started.
          if (_busy && _copy != null)
            StoreCopyLine(progress: _copy!)
          else
            PinStepFoot(
              child: _busy
                  ? PinCheckBar(
                      status: _deleting == null ? null : deleteStepText(l, _deleting!),
                      lines: _deleting == null ? [l.workChecking, l.workOpening] : const [],
                    )
                  : (_error == null ? null : ErrorText(_error!)),
            ),
          if (_busy && checkAt != null) ...[
            const SizedBox(height: 8),
            PinWaitNote(until: checkAt),
          ],
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
          const SizedBox(height: 24),
          // A healthy wallet the Keystore holds back is not one to delete.
          if (_keyRefused)
            FilledButton(
              onPressed: _busy || _reading ? null : _tryAgain,
              child: TrustId(TrustIds.unlockRetry, child: Text(l.unlockTryAgain)),
            )
          else
            TextButton(
              onPressed: _busy ? null : _forgotPin,
              child: Text(passphrase ? l.passphraseForgot : l.pinForgot),
            ),
          // Quiet, under Forgot: the way out when the stored mode and the secret disagree.
          if (canSwitch)
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
