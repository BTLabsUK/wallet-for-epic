// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../levels/first_start.dart';
import '../providers.dart';
import '../vault.dart';
import 'centered_body.dart';
import 'common.dart';
import 'first_run_screen.dart';
import 'level_step_screen.dart';
import 'pin_unlock_screen.dart';
import 'theme/brand.dart';

/// Decides where the app starts: PIN unlock, or first run when no wallet opens with a PIN
/// (also over an install of 1.2.x or older, which stays in place, [WalletVault.prepare]).
class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key});

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
    // A fresh install answers the level step before anything else.
    if (ref.read(firstStartProvider)) return const LevelStepScreen();
    // A wallet left open would pin its chain for the one about to open.
    ref.read(sessionProvider.notifier).lock();
    final choice = await ref.read(networkChoiceProvider.future);
    final chain = choice.preset.chain;
    final dataDir = await ref.read(walletDirProvider)(chain);
    final config = choice.config(dataDir);
    ref.read(walletConfigProvider.notifier).select(config);

    return switch (await ref.read(vaultProvider).prepare(config)) {
      VaultStage.ready => const PinUnlockScreen(),
      VaultStage.empty => const FirstRunScreen(),
      VaultStage.stranded => const PinUnlockScreen(stranded: true),
    };
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
          if (_error == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            ErrorText(_error!),
            BusyButton(label: context.l10n.launchTryAgain, onPressed: _route),
          ],
        ],
      ),
    );
  }
}
