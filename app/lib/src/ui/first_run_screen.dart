// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advanced.dart';
import '../app_log.dart';
import '../errors.dart';
import '../help/help_content.dart' show HelpId;
import '../levels/first_run_servers_phone.dart';
import '../levels/first_start.dart';
import '../levels/wallet_level.dart' show firstStartLevel;
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart';
import '../tor_build.dart';
import '../trust_ids.dart';
import 'common.dart';
import 'help_screen.dart' show openHelp;
import 'kit/kit_brand_tile.dart';
import 'kit/kit_button.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_help_sheet.dart';
import 'kit/kit_row.dart';
import 'kit/kit_support.dart' show kitId;
import 'kit/kit_tokens.dart';
import 'launch_screen.dart';
import 'levels/tor_wait_screen.dart';
import 'pin.dart';
import 'restore_screen.dart';
import 'theme/brand.dart' show BrandVariant, BrandWordmark, heroGlow;
import 'theme/tokens.dart';
import 'work_status.dart';

/// The first-run screen's "Create a new wallet" button, for tests and the tour.
const Key firstRunCreateKey = ValueKey('first-run-create');

/// The first-run screen's "Restore from a phrase" button, for tests and the tour.
const Key firstRunRestoreKey = ValueKey('first-run-restore');

/// The first-run screen's "Tor only" row, for tests and the tour.
const Key firstRunTorOnlyKey = ValueKey('first-run-tor-only');

/// First start, and the start after the last wallet was deleted (HANDOFF 7.7, Start-1): the
/// brand tile, Create, Restore and, in Tor builds, the Tor only switch. The choice is a step of
/// its own, before any PIN: a tester whose keyboard covered the restore link under the PIN
/// field created a wallet they did not want (26.10.16). Create leads to the PIN on the keypad,
/// then the repeat, then the biometrics offer; the wallet is made sealed under it.
///
/// On a fresh install nothing connects until Create or Restore ([firstStartProvider]): the
/// screen answers that first step, with the Tor only switch, as the level step did before.
/// The first step's top gap: the tile sits 188 below the top of the frame.
const double _welcomeTop = 124;

/// The "Tor only" row under the two buttons: the title, its line, and the switch (`.row`, 12 above,
/// 4 in, 52 high).
class _TorOnlyRow extends StatelessWidget {
  const _TorOnlyRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return Semantics(
      container: true,
      toggled: value,
      label: l.levelUndercoverTitle,
      hint: l.phoneWelcomeTorLine,
      excludeSemantics: true,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: kitId(
        TrustIds.welcomeToronly,
        InkWell(
          key: firstRunTorOnlyKey,
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.levelUndercoverTitle, style: KitType.rowTitle.copyWith(color: t.text)),
                        const SizedBox(height: 3),
                        Text(l.phoneWelcomeTorLine, style: KitType.rowSub.copyWith(color: t.dim)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IgnorePointer(child: ExcludeSemantics(child: KitSwitch(value: value, onChanged: onChanged))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key, this.startCreating = false});

  /// From a screen that stands in for the choice: the PIN step at once, and its Back returns
  /// there.
  final bool startCreating;

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  ({String pin, bool biometrics})? _answer;
  String? _error;

  /// "Create a new wallet" was chosen: the PIN step shows.
  bool _creating = false;

  /// Tor only from the first connection.
  late bool _tor = torBuilt && ref.read(networkModeProvider) == NetworkMode.torOnly;

  /// Create or Restore is saving the first step.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _creating = widget.startCreating;
  }

  @override
  void dispose() {
    _answer = null;
    super.dispose();
  }

  /// The first step answered, before the PIN or the phrase: Tor only stored (or taken back
  /// after a Back from a later step) and, on a fresh install, the hold on connections ends.
  Future<void> _answerFirstStep() async {
    if (torBuilt && !_tor && ref.read(networkModeProvider) == NetworkMode.torOnly) {
      final settings = await ref.read(appSettingsProvider.future);
      await ref.read(appSettingsProvider.notifier).setAdvanced(settings.advanced.withMode(NetworkMode.standard));
    }
    if (ref.read(firstStartProvider)) {
      await ref.read(firstStartProvider.notifier).complete(level: firstStartLevel, undercover: _tor);
    }
  }

  Future<void> _go({required bool restore}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _answerFirstStep();
      if (!mounted) return;
      if (restore) {
        _leave(const RestoreScreen());
      } else {
        setState(() => _creating = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish(String pin, bool useBiometrics) async {
    if (ref.read(walletConfigProvider) == null) return;
    final l = context.l10n;
    setState(() {
      _answer = (pin: pin, biometrics: useBiometrics);
      _error = null;
    });
    try {
      // On the servers first run picked: the new wallet's address names a relay that answers.
      final config = await configAfterFirstRunServers(ref);
      if (config == null || !mounted) return;
      final vault = ref.read(vaultProvider);
      final result = await vault.create(
        config,
        pin: pin,
        useBiometrics: useBiometrics,
      );
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
      }
      // Undercover from the start: Home once Tor carries the wallet's requests.
      if (shouldWaitForTor(ref)) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const TorWaitScreen()),
          (_) => false,
        );
      } else {
        goHome(context);
      }
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

  /// Back on the PIN step: to the choice, or to the screen that stood in for it.
  void _backFromPin() {
    if (widget.startCreating) {
      _leave(const LaunchScreen());
    } else {
      setState(() => _creating = false);
    }
  }

  void _leave(Widget screen) =>
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));

  void _pinHelp() {
    final l = context.l10n;
    showKitHelp(
      context,
      title: l.phoneStartPinHelpTitle,
      lines: [l.phoneStartPinHelpUnlock, l.phoneStartPinHelpLost],
      onMore: () => openHelp(context, HelpId.phrase),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final waiting = _answer != null && _error == null;
    final choosing = !_creating;
    final onPinStep = _creating && _answer == null;
    // Tor only is a promise about the first connection: once connections were made (a Back
    // from a later step with it off) the row stays away, and with it on it stays, to turn it
    // off again.
    final torOffered = torBuilt && (ref.watch(firstStartProvider) || _tor);

    final Widget body;
    if (onPinStep) {
      // The system's Back and the header's arrow return to the choice.
      body = Column(
        children: [
          KitFlowHeader(title: '', back: true, onLeading: _backFromPin, onHelp: _pinHelp),
          Expanded(
            child: Padding(
              padding: EdgeInsets.zero,
              child: PinSetupView(onDone: _finish, actionsAtFoot: true),
            ),
          ),
        ],
      );
    } else if (_answer == null && choosing) {
      // The frame: the tile 188 from the top, the wordmark 40 high 34 below it, the title 34
      // below that, the buttons and the Tor row at the foot (34 above the edge).
      final compact = MediaQuery.viewInsetsOf(context).bottom > 0;
      body = CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A keyboard-sized inset (a small window) gives the top room back.
                  SizedBox(height: compact ? 0 : _welcomeTop),
                  if (!compact) ...[
                    const ExcludeSemantics(child: Center(child: KitBrandTile())),
                    const SizedBox(height: 22),
                  ],
                  const Center(
                    child: ExcludeSemantics(
                      child: SizedBox(height: 40, child: FittedBox(child: BrandWordmark(variant: BrandVariant.mobile, size: 26))),
                    ),
                  ),
                  SizedBox(height: compact ? 20 : 34),
                  Semantics(
                    header: true,
                    child: Text(l.firstRunTitle, style: KitType.pageTitle.copyWith(color: t.text), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(l.phoneWelcomeBody, style: KitType.body.copyWith(color: t.dim, height: 1.45), textAlign: TextAlign.center),
                  ),
                  const Spacer(),
                  const SizedBox(height: Kit.gutter),
                  KitButton(
                    key: firstRunCreateKey,
                    label: l.firstRunCreate,
                    onPressed: _busy ? null : () => _go(restore: false),
                    semanticsId: TrustIds.welcomeCreate,
                  ),
                  const SizedBox(height: 10),
                  KitButton(
                    key: firstRunRestoreKey,
                    label: l.firstRunRestore,
                    kind: KitButtonKind.quiet,
                    onPressed: _busy ? null : () => _go(restore: true),
                    semanticsId: TrustIds.welcomeRestore,
                  ),
                  if (torOffered) _TorOnlyRow(value: _tor, onChanged: _busy ? null : (v) => setState(() => _tor = v)),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      body = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Kit.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: ExcludeSemantics(child: KitBrandTile())),
              const SizedBox(height: 28),
              if (waiting) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                WorkStatus(
                  lines: [l.workCreating, l.firstRunSecuring, l.workOpening],
                  // The body text the plain line had. Not DefaultTextStyle.of(context): this
                  // context is above the Scaffold, so it gave the no-Material fallback (red,
                  // yellow underline).
                  style: KitType.body.copyWith(color: t.dim),
                ),
              ] else ...[
                ErrorText(_error!),
                const SizedBox(height: 12),
                KitButton(label: l.firstRunTryAgain, onPressed: _retry),
              ],
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: !onPinStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backFromPin();
      },
      child: SlotScaffold(
        glow: heroGlow,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: body),
          ),
        ),
      ),
    );
  }
}
