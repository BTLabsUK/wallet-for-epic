import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../providers.dart';
import '../vault.dart';
import 'common.dart';
import 'first_run_screen.dart';
import 'pin_unlock_screen.dart';
import 'unlock_screen.dart';

/// Decides where the app starts: PIN unlock, first run, or password unlock for a wallet made
/// before PINs existed.
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
    setState(() => _error = null);
    try {
      final next = await _destination();
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    }
  }

  Future<Widget> _destination() async {
    // A wallet left open would pin its chain for the one about to open.
    ref.read(sessionProvider.notifier).lock();
    final choice = await ref.read(networkChoiceProvider.future);
    final chain = choice.preset.chain;
    final dataDir = await ref.read(walletDirProvider)(chain);
    final config = choice.preset.config(
      dataDir: dataDir,
      nodeUrl: choice.nodeUrl,
    );
    ref.read(walletConfigProvider.notifier).select(config);

    final vault = ref.read(vaultProvider);
    final exists = await ref
        .read(walletServiceProvider)
        .walletExists(config: config);
    final stage = await vault.stage(chain);
    if (exists) {
      return switch (stage) {
        VaultStage.sealed => const PinUnlockScreen(),
        VaultStage.pending => const FirstRunScreen(),
        VaultStage.empty => const UnlockScreen(),
      };
    }
    // A PIN without a wallet means the files were removed; that key opens nothing now.
    if (stage == VaultStage.sealed) await vault.forget(chain);
    return const FirstRunScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBody(
        children: [
          if (_error == null)
            const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            ErrorText(_error!),
            BusyButton(label: 'Try again', onPressed: _route),
          ],
        ],
      ),
    );
  }
}
