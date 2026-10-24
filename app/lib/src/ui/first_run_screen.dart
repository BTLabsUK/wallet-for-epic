import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../demo.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../wallet_service.dart' show Chain;
import 'centered_body.dart';
import 'common.dart';
import 'demo_pin.dart';
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

  @override
  void initState() {
    super.initState();
    // The web demo and preview ask for no PIN: the wallet is set up with the demo PIN at once.
    if (ref.read(pinlessProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finish(demoPin, false);
      });
    }
  }

  @override
  void dispose() {
    _answer = null;
    super.dispose();
  }

  Future<void> _finish(String pin, bool useBiometrics) async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final l = context.l10n;
    setState(() {
      _answer = (pin: pin, biometrics: useBiometrics);
      _error = null;
    });
    try {
      final vault = ref.read(vaultProvider);
      final result = await vault.create(
        config,
        pin: pin,
        useBiometrics: useBiometrics,
      );
      if (ref.read(demoModeProvider) || ref.read(pinlessProvider)) {
        await _markDemoPin(config.chain);
      }
      await ref.read(sessionProvider.notifier).open(result.session);
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

  /// Notes that the demo wallet opens with [demoPin], so unlock fills it in again. The wallet
  /// exists already; without the note unlock asks for the PIN, and Forgot PIN ends the demo.
  Future<void> _markDemoPin(Chain chain) async {
    try {
      await ref.read(vaultProvider).markDemoPin(chain);
    } catch (error) {
      logWarn('setup', 'storing the demo PIN note failed: $error');
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
    // The web demo is on floonet for good, and never takes a phrase or biometrics.
    final demo = ref.watch(demoModeProvider);
    final pinless = ref.watch(pinlessProvider);

    return SlotScaffold(
      centered: true,
      glow: heroGlow,
      // The title is the hero's heading; the bar only holds the network action.
      appBar: AppBar(
        // Mainnet on node.btlabs.uk works without a choice, but a new install must be able
        // to reach floonet or another node before it has a wallet, so this is not Advanced.
        actions: [
          if (!demo && !pinless)
            NetworkSettingsButton(
              onPressed: waiting ? null : () => _leave(const SetupScreen()),
            ),
        ],
      ),
      body: CenteredBody(
        children: [
          // The demo has no PIN to choose and no network to name: it only sets itself up.
          BrandHero(
            title: demo || pinless ? l.demoPinSetUpTitle : '${l.firstRunTitle}$network',
          ),
          const SizedBox(height: 28),
          if (_answer == null && pinless)
            const Center(child: CircularProgressIndicator())
          else if (_answer == null) ...[
            if (demo)
              DemoPinFill(onDone: () => _finish(demoPin, false))
            else
              PinSetupView(onDone: _finish),
            if (!demo) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                icon: const Icon(Icons.restore),
                label: Text(l.firstRunRestore),
                onPressed: () => _leave(const RestoreScreen()),
              ),
            ],
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
/// decoration. When the labelled button, measured at the current text scale and in the
/// current language, would not fit beside a back arrow, it gives way to the icon and its
/// tooltip, so a long label never overflows the bar.
class NetworkSettingsButton extends StatelessWidget {
  const NetworkSettingsButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  /// The icon in a [TextButton.icon]; it does not grow with the text.
  static const double _iconSize = 18;

  /// The button's start padding, icon gap and end padding: Material 3 shrinks them from
  /// 12 + 8 + 16 at text scale 1 to 4 + 4 + 4 at scale 2 and above.
  static const double _paddingAtOne = 36;
  static const double _paddingAtTwo = 12;

  /// The margin after the button, at the bar's end.
  static const double _margin = 8;

  /// What the bar keeps for everything else: a 56 dp back arrow when the screen is pushed,
  /// and 16 of inset.
  static const double _reserved = 72;

  bool _labelFits(BuildContext context, String label) {
    final theme = Theme.of(context);
    final style =
        theme.textButtonTheme.style?.textStyle?.resolve(const {}) ??
        theme.textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final padding = lerpDouble(
      _paddingAtOne,
      _paddingAtTwo,
      (scaler.scale(1) - 1).clamp(0.0, 1.0),
    )!;
    final width = painter.width + _iconSize + padding + _margin;
    painter.dispose();
    return width <= MediaQuery.sizeOf(context).width - _reserved;
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
