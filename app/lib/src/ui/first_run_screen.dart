// SPDX-License-Identifier: Apache-2.0
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
import 'network_menu.dart';
import 'pin.dart';
import 'restore_screen.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';

/// The first-run screen's "Create a new wallet" button, for tests and the tour.
const Key firstRunCreateKey = ValueKey('first-run-create');

/// The first-run screen's "Restore from a phrase" button, for tests and the tour.
const Key firstRunRestoreKey = ValueKey('first-run-restore');

/// First start, and the start after the last wallet was deleted: the user chooses between a
/// new wallet and a restore, then picks a PIN, and LEPIC creates the wallet sealed under it.
/// The choice is a step of its own, before any text field: a tester whose keyboard covered
/// the restore link under the PIN field created a wallet they did not want (26.10.16).
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  ({String pin, bool biometrics})? _answer;
  String? _error;

  /// "Create a new wallet" was chosen: the PIN step shows. The demo and the preview skip the
  /// choice, as they have no phrase to restore.
  bool _creating = false;

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
            .show(
              l.firstRunBiometricsNotSetUp,
              level: NoticeLevel.warning,
              // Stays until closed: the first-run tour opens over Home and a timed notice
              // ran out under it unseen.
              persistent: true,
            );
      } else if (useBiometrics) {
        // Their copy cannot be read back in the process that wrote it (WAL-11).
        ref
            .read(noticeProvider.notifier)
            .show(l.biometricsFromNextStart, level: NoticeLevel.info, persistent: true);
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

  void _leave(Widget screen) =>
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(walletConfigProvider);
    final network = config == null || !ref.watch(devNetworksProvider)
        ? ''
        : networkSuffix(l, config.chain);
    final waiting = _answer != null && _error == null;
    // The web demo is on floonet for good, and never takes a phrase or biometrics.
    final demo = ref.watch(demoModeProvider);
    final pinless = ref.watch(pinlessProvider);
    final choosing = !demo && !pinless && !_creating;

    final onPinStep = _creating && _answer == null;
    // The system's Back on the PIN step returns to the choice, as the bar's arrow does.
    return PopScope(
      canPop: !onPinStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _creating = false);
      },
      child: SlotScaffold(
        centered: !(_answer == null && choosing) && !onPinStep,
        glow: heroGlow,
        // The title is the hero's heading; the bar only holds the network action, and on the
        // PIN step the way back to the choice.
        appBar: AppBar(
          leading: onPinStep
              ? BackButton(onPressed: () => setState(() => _creating = false))
              : null,
          automaticallyImplyLeading: false,
          // Mainnet on the built-in node works without a choice, but a new install must be able
          // to reach floonet or another node before it has a wallet, so this is not Advanced.
          actions: [
            if (!demo && !pinless) NetworkSettingsButton(enabled: !waiting),
          ],
        ),
        body: onPinStep && !demo
            ? SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PinSetupView(onDone: _finish, actionsAtFoot: true),
                    ),
                  ),
                ),
              )
            : _answer == null && choosing
            // The hero centred in the room above the two choices, which sit at the foot of
            // the screen, above a keyboard.
            ? SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: BrandHero(
                                  title: '${l.firstRunTitle}$network',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.icon(
                                key: firstRunCreateKey,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: const Icon(Icons.add),
                                label: Text(l.firstRunCreate),
                                onPressed: () =>
                                    setState(() => _creating = true),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                key: firstRunRestoreKey,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: const Icon(Icons.restore),
                                label: Text(l.firstRunRestore),
                                onPressed: () => _leave(const RestoreScreen()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : CenteredBody(
                children: [
                  // The demo has no PIN to choose and no network to name: it only sets itself up.
                  BrandHero(
                    title: demo || pinless
                        ? l.demoPinSetUpTitle
                        : '${l.firstRunTitle}$network',
                  ),
                  const SizedBox(height: 28),
                  if (_answer == null && pinless)
                    const Center(child: CircularProgressIndicator())
                  else if (_answer == null && choosing)
                    // Two plain choices and no text field, so no keyboard can cover either. A new
                    // wallet is the primary one; Restore stands beside it at the same size. They
                    // sit at the foot of the screen, as every primary action.
                    const SizedBox.shrink()
                  else if (_answer == null) ...[
                    if (demo)
                      DemoPinFill(onDone: () => _finish(demoPin, false))
                    else
                      PinSetupView(onDone: _finish),
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
      ),
    );
  }
}

/// The app bar's way to the servers before a wallet is open, on first run and unlock: it opens
/// the small menu ([showNetworkMenu]) with Node and Epicbox. The icon and its label in the
/// accent colour, so it reads as a button rather than a decoration. When the labelled button,
/// measured at the current text scale and in the current language, would not fit beside a
/// back arrow, it gives way to the icon and its tooltip, so a long label never overflows the
/// bar.
class NetworkSettingsButton extends StatelessWidget {
  const NetworkSettingsButton({super.key, this.enabled = true});

  /// False while the screen is busy (the button is disabled).
  final bool enabled;

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
    final onPressed = enabled ? () => showNetworkMenu(context) : null;
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
