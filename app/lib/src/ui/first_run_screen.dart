import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import 'centered_body.dart';
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
    final l = context.l10n;
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
        ref.read(noticeProvider.notifier).show(l.firstRunBiometricsNotSetUp);
      }
      goHome(context);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(l, error));
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
    final l = context.l10n;
    final setup = ref.watch(walletSetupProvider);
    final config = ref.watch(walletConfigProvider);
    final network = config == null ? '' : networkSuffix(l, config.chain);
    final waiting = _answer != null && _error == null;

    return SlotScaffold(
      centered: true,
      appBar: AppBar(
        title: Text('${l.firstRunTitle}$network'),
        actions: [
          IconButton(
            tooltip: l.setupNetworkSettingsTooltip,
            icon: const Icon(Icons.settings_ethernet),
            onPressed: waiting ? null : () => _leave(const SetupScreen()),
          ),
        ],
      ),
      body: CenteredBody(
        children: [
          if (_answer == null) ...[
            PinSetupView(onDone: _finish),
            const SizedBox(height: 16),
            _CreationStatus(setup: setup),
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.restore),
              label: Text(l.firstRunRestore),
              onPressed: () => _leave(const RestoreScreen()),
            ),
          ] else if (waiting) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(
              setup.running ? l.firstRunFinishing : l.firstRunSecuring,
              textAlign: TextAlign.center,
            ),
          ] else ...[
            ErrorText(_error!),
            BusyButton(label: l.firstRunTryAgain, onPressed: _retry),
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
    final l = context.l10n;
    final style = Theme.of(context).textTheme.bodySmall;
    if (setup.error != null) {
      return ErrorText(l.firstRunCreateFailed(describeError(l, setup.error!)));
    }
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
            setup.session == null ? l.firstRunCreating : l.firstRunCreated,
            style: style,
          ),
        ],
      ),
    );
  }
}
