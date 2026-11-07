// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../levels/first_start.dart';
import '../providers.dart';
import '../vault.dart';
import '../wallet_service.dart' show WalletConfig;
import 'home_screen.dart';
import 'centered_body.dart';
import 'common.dart';
import 'first_run_screen.dart';
import 'level_step_screen.dart';
import 'pin_unlock_screen.dart';
import 'restore_screen.dart';
import 'theme/brand.dart';
import 'work_status.dart';

const String _previewPin = '000000';

/// Where the first-start picker sends a fresh install: the PIN of a new wallet, or the phrase.
enum FirstRunStart { create, restore }

/// Decides where the app starts: PIN unlock, or first run when no wallet opens with a PIN
/// (also over an install of 1.2.x or older, which stays in place, [WalletVault.prepare]).
class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key, this.start});

  /// The picker's Create or Restore: with no wallet yet, straight to that step.
  final FirstRunStart? start;

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    final l = context.l10n;
    setState(() => _error = null);
    try {
      final next = await _destination();
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
    } catch (error) {
      if (mounted) setState(() => _error = describeError(l, error));
    }
  }

  Future<Widget> _destination() async {
    // A fresh install answers the first step (Create, Restore, Tor only) before anything else.
    if (ref.read(firstStartProvider)) return const LevelStepScreen();
    // A wallet left open would pin its chain for the one about to open.
    ref.read(sessionProvider.notifier).lock();
    final choice = await ref.read(networkChoiceProvider.future);
    final chain = choice.preset.chain;
    final dataDir = await ref.read(walletDirProvider)(chain);
    final config = choice.config(dataDir);
    ref.read(walletConfigProvider.notifier).select(config);

    // The web preview has no lock: it makes its fake wallet and opens it (web/preview.dart).
    if (previewNoLock) return _previewHome(config);

    return switch (await ref.read(vaultProvider).prepare(config)) {
      VaultStage.ready => const PinUnlockScreen(),
      VaultStage.empty => switch (widget.start) {
        FirstRunStart.create => const FirstRunScreen(startCreating: true),
        FirstRunStart.restore => const RestoreScreen(),
        // Back from those steps in the run that answered the first step: the first step again.
        null when ref.read(levelStepAnswerProvider) != null => const LevelStepScreen(),
        null => const FirstRunScreen(),
      },
      VaultStage.stranded => const PinUnlockScreen(stranded: true),
    };
  }

  /// The preview's wallet, made on the first visit and opened again after any lock, with no PIN
  /// asked. Only the preview build (`WFE_WEB_FAKE`) gets here; the fake wallet takes any PIN.
  Future<Widget> _previewHome(WalletConfig config) async {
    final vault = ref.read(vaultProvider);
    final session = await vault.prepare(config) == VaultStage.ready
        ? await vault.unlock(config, _previewPin)
        : (await vault.create(config, pin: _previewPin)).session;
    await ref.read(sessionProvider.notifier).open(session);
    ref.read(shellTabProvider.notifier).go(ShellTab.wallet);
    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return SlotScaffold(
      centered: true,
      glow: heroGlow,
      body: CenteredBody(
        children: [
          const BrandHero(),
          const SizedBox(height: 32),
          if (_error == null) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            // Also keeps the screen drawing while it routes ([FrameKeeper]).
            WorkStatus(
              lines: [context.l10n.workStarting],
              showAfter: const Duration(milliseconds: 400),
            ),
          ] else ...[
            ErrorText(_error!),
            BusyButton(label: context.l10n.launchTryAgain, onPressed: _route),
          ],
        ],
      ),
    );
  }
}
