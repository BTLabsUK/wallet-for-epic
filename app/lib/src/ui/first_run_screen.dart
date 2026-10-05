import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import 'centered_body.dart';
import 'common.dart';
import 'pin.dart';
import 'restore_screen.dart';
import 'setup_screen.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';

/// First start: the user picks a PIN, then LEPIC creates the wallet sealed under it.
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  ({String pin, bool biometrics})? _answer;
  String? _error;

  Future<void> _finish(String pin, bool useBiometrics) async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final l = context.l10n;
    setState(() {
      _answer = (pin: pin, biometrics: useBiometrics);
      _error = null;
    });
    try {
      final result = await ref
          .read(vaultProvider)
          .create(config, pin: pin, useBiometrics: useBiometrics);
      ref.read(sessionProvider.notifier).unlocked(result.session);
      _answer = null;
      if (!mounted) return;
      if (useBiometrics && !result.biometrics) {
        ref
            .read(noticeProvider.notifier)
            .show(l.firstRunBiometricsNotSetUp, level: NoticeLevel.warning);
      }
      goHome(context);
    } catch (error) {
      logWarn(
        'setup',
        'creating the wallet failed: ${describeError(englishStrings, error)}',
      );
      if (mounted) setState(() => _error = describeError(l, error));
    }
  }

  void _retry() {
    final answer = _answer;
    if (answer != null) _finish(answer.pin, answer.biometrics);
  }

  void _leave(Widget screen) => Navigator.of(context)
      .pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(walletConfigProvider);
    final network = config == null ? '' : networkSuffix(l, config.chain);
    final waiting = _answer != null && _error == null;

    return SlotScaffold(
      centered: true,
      glow: heroGlow,
      // The title is the hero's heading; the bar only holds the network action.
      appBar: AppBar(
        // Mainnet on node.btlabs.uk works without a choice, but a new install must be able
        // to reach floonet or another node before it has a wallet, so this is not Advanced.
        actions: [
          NetworkSettingsButton(
            onPressed: waiting ? null : () => _leave(const SetupScreen()),
          ),
        ],
      ),
      body: CenteredBody(
        children: [
          BrandHero(title: '${l.firstRunTitle}$network'),
          const SizedBox(height: 28),
          if (_answer == null) ...[
            PinSetupView(onDone: _finish),
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.restore),
              label: Text(l.firstRunRestore),
              onPressed: () => _leave(const RestoreScreen()),
            ),
          ] else if (waiting) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(l.firstRunSecuring, textAlign: TextAlign.center),
          ] else ...[
            ErrorText(_error!),
            BusyButton(label: l.firstRunTryAgain, onPressed: _retry),
          ],
        ],
      ),
    );
  }
}

/// The app bar's way to network settings before a wallet is open, on first run and unlock:
/// the icon and its label in the accent colour, so it reads as a button rather than a
/// decoration. When the labelled button would take more than half the screen's width, at the
/// current text scale and in the current language, it gives way to the icon and its tooltip,
/// so a long label never overflows the bar.
class NetworkSettingsButton extends StatelessWidget {
  const NetworkSettingsButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  /// Everything beside the label: the button's start padding (12), the icon (18), the gap
  /// (8), its end padding (16) and the margin after it (8).
  static const double _chrome = 62;

  /// The labelled button keeps to this share of the width; the rest is left for the bar's
  /// back arrow and some air.
  static const double _maxShare = 0.5;

  bool _labelFits(BuildContext context, String label) {
    final theme = Theme.of(context);
    final style =
        theme.textButtonTheme.style?.textStyle?.resolve(const {}) ??
        theme.textTheme.labelLarge;
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width + _chrome;
    painter.dispose();
    return width <= MediaQuery.sizeOf(context).width * _maxShare;
  }

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.setupNetworkSettingsTooltip;
    final colour = context.tokens.accentText;
    const icon = Icon(Icons.settings_ethernet);
    if (!_labelFits(context, label)) {
      return IconButton(
        tooltip: label,
        color: colour,
        icon: icon,
        onPressed: onPressed,
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: colour,
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        icon: icon,
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}
