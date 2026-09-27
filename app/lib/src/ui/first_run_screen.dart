import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../network.dart';
import '../providers.dart';
import 'common.dart';
import 'pin.dart';
import 'restore_screen.dart';
import 'setup_screen.dart';

/// First start: the wallet is created in the background while the user picks a PIN.
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  ({String pin, bool biometrics})? _answer;
  String? _error;

  @override
  void initState() {
    super.initState();
    final config = ref.read(walletConfigProvider);
    if (config != null) {
      // Riverpod forbids provider writes during build; initState of a pushed route is fine,
      // but a post-frame start keeps that true for any caller.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(walletSetupProvider.notifier).start(config),
      );
    }
  }

  Future<void> _finish(String pin, bool useBiometrics) async {
    setState(() {
      _answer = (pin: pin, biometrics: useBiometrics);
      _error = null;
    });
    try {
      final result = await ref
          .read(walletSetupProvider.notifier)
          .finish(pin: pin, useBiometrics: useBiometrics);
      ref.read(sessionProvider.notifier).unlocked(result.session);
      if (!mounted) return;
      if (useBiometrics && !result.biometrics) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometric unlock was not set up. You can turn it on from the '
              'wallet menu.',
            ),
          ),
        );
      }
      goHome(context);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    }
  }

  void _retry() {
    // finish() starts the creation again when it had failed.
    final answer = _answer;
    if (answer != null) _finish(answer.pin, answer.biometrics);
  }

  Future<void> _leave(Widget screen) async {
    await ref.read(walletSetupProvider.notifier).abandon();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(walletSetupProvider);
    final config = ref.watch(walletConfigProvider);
    final theme = Theme.of(context);
    final network = config == null ? '' : ' (${chainLabel(config.chain)})';
    final waiting = _answer != null && _error == null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome$network'),
        actions: [
          IconButton(
            tooltip: 'Network settings',
            icon: const Icon(Icons.settings_ethernet),
            onPressed: waiting ? null : () => _leave(const SetupScreen()),
          ),
        ],
      ),
      body: ScreenBody(
        children: [
          if (_answer == null) ...[
            PinSetupView(
              onDone: _finish,
              intro: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Your new Epic Cash wallet is being created on this device. '
                  'Meanwhile, protect it with a PIN.',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _CreationStatus(setup: setup),
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('I already have a wallet: restore it'),
              onPressed: () => _leave(const RestoreScreen()),
            ),
          ] else if (waiting) ...[
            const SizedBox(height: 48),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(
              setup.running
                  ? 'Finishing your wallet…'
                  : 'Securing your wallet…',
              textAlign: TextAlign.center,
            ),
          ] else ...[
            ErrorText(_error!),
            BusyButton(label: 'Try again', onPressed: _retry),
          ],
        ],
      ),
    );
  }
}

class _CreationStatus extends StatelessWidget {
  const _CreationStatus({required this.setup});

  final WalletSetup setup;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    if (setup.error != null) {
      return ErrorText(
        'Creating the wallet failed: ${describeError(setup.error!)} '
        'It is tried again when you finish the PIN.',
      );
    }
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          if (setup.session == null)
            const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.check_circle, size: 16),
          const SizedBox(width: 8),
          Text(
            setup.session == null ? 'Creating wallet…' : 'Wallet created',
            style: style,
          ),
        ],
      ),
    );
  }
}
