// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart';
import '../../l10n.dart';
import '../../phone_tor.dart';
import '../../settings.dart';
import '../../tor_build.dart';
import '../common.dart';
import '../theme/brand.dart';
import '../theme/tokens.dart';
import 'level_art.dart';

/// The wait screen's "Turn Undercover off" button, for tests.
const Key torWaitOffKey = ValueKey('tor-wait-off');

/// Whether a wallet just set up should wait for Tor before Home: Undercover (Tor only) is on
/// and Tor cannot carry a request yet.
bool shouldWaitForTor(WidgetRef ref) =>
    torBuilt &&
    ref.read(networkModeProvider) == NetworkMode.torOnly &&
    !ref.read(phoneTorProvider).canSend &&
    ref.read(phoneTorProvider).phase != PhoneTorPhase.unavailable;

/// After the PIN of a new wallet with Undercover on: "Connecting through Tor" until Tor can
/// carry the wallet's requests, then Home. Nothing goes around Tor, so where Tor is blocked
/// the way on is to turn Undercover off (Network mode › Standard).
class TorWaitScreen extends ConsumerStatefulWidget {
  const TorWaitScreen({super.key});

  @override
  ConsumerState<TorWaitScreen> createState() => _TorWaitScreenState();
}

class _TorWaitScreenState extends ConsumerState<TorWaitScreen> {
  bool _left = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !shouldWaitForTor(ref)) _home();
    });
  }

  void _home() {
    if (_left || !mounted) return;
    _left = true;
    goHome(context);
  }

  Future<void> _turnOff() async {
    if (_busy) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final settings = await ref.read(appSettingsProvider.future);
      await ref.read(appSettingsProvider.notifier).setAdvanced(settings.advanced.withMode(NetworkMode.standard));
      ref.read(noticeProvider.notifier).show(l.lvPickTorOffDone, level: NoticeLevel.info);
      _home();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    ref.listen(phoneTorProvider, (_, s) {
      if (s.canSend || s.phase == PhoneTorPhase.unavailable) _home();
    });
    ref.listen(networkModeProvider, (_, mode) {
      if (mode != NetworkMode.torOnly) _home();
    });
    final tor = ref.watch(phoneTorProvider);
    final progress = tor.phase == PhoneTorPhase.starting ? tor.progress : null;
    return PopScope(
      canPop: false,
      child: SlotScaffold(
        glow: heroGlow,
        body: ScreenBody(
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.lvPickTorBlocked,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: t.dim, height: 1.45),
              ),
              const SizedBox(height: 4),
              TextButton(
                key: torWaitOffKey,
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: _busy ? null : _turnOff,
                child: Text(l.lvPickTorOff),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 48),
            const Center(child: GlyphTile(child: LevelArt(LevelArtKind.agent, size: 40))),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(l.lvPickTorTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: 8),
            Text(
              l.lvPickTorLead,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: t.dim, height: 1.45),
            ),
            const SizedBox(height: 20),
            Semantics(
              liveRegion: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      progress == null ? l.lvPickTorBusy : '${l.lvPickTorBusy} ${percentText(l, progress)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
