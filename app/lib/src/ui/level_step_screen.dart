// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../advanced.dart';
import '../l10n.dart';
import '../levels/first_start.dart';
import '../levels/level_providers.dart';
import '../levels/wallet_level.dart';
import '../settings.dart';
import '../tor_build.dart';
import '../trust_ids.dart';
import 'common.dart';
import 'launch_screen.dart';
import 'levels/level_picker.dart';
import 'theme/brand.dart';

/// The words of a level, shared by Change level and the Advanced row.
String levelTitle(AppLocalizations l, WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => l.levelOneTitle,
  WalletLevel.casual => l.levelTwoTitle,
  WalletLevel.everything => l.levelThreeTitle,
};

/// The first step's "Create a new wallet" and "Restore from phrase" buttons, for tests.
const Key levelCreateKey = ValueKey('level-create');
const Key levelRestoreKey = ValueKey('level-restore');

/// The first step's last answer in this run, so Back from the PIN step or the restore phrase
/// returns to the first step with it, not to the old Welcome choice.
final levelStepAnswerProvider = NotifierProvider<LevelStepAnswer, ({WalletLevel level, bool undercover})?>(
  LevelStepAnswer.new,
);

class LevelStepAnswer extends Notifier<({WalletLevel level, bool undercover})?> {
  @override
  ({WalletLevel level, bool undercover})? build() => null;

  void set(({WalletLevel level, bool undercover}) answer) => state = answer;
}

/// First start of a fresh install, in place of Welcome: Create or Restore and, under them,
/// quiet, Tor only from the first connection in Tor builds. The wallet starts in
/// [firstStartLevel]. Nothing connects until Create or Restore.
class LevelStepScreen extends ConsumerStatefulWidget {
  const LevelStepScreen({super.key});

  @override
  ConsumerState<LevelStepScreen> createState() => _LevelStepScreenState();
}

class _LevelStepScreenState extends ConsumerState<LevelStepScreen> {
  bool _undercover = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _undercover = ref.read(levelStepAnswerProvider)?.undercover ?? false;
  }

  Future<void> _go({required bool restore}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final previous = ref.read(levelStepAnswerProvider);
      // A second pass (Back from the PIN) with Tor only now off takes back the Tor only the
      // first one stored; complete() only ever turns it on.
      if (!_undercover && torBuilt && (previous?.undercover ?? false)) {
        final settings = await ref.read(appSettingsProvider.future);
        await ref.read(appSettingsProvider.notifier).setAdvanced(settings.advanced.withMode(NetworkMode.standard));
      }
      final level = previous?.level ?? firstStartLevel;
      await ref.read(firstStartProvider.notifier).complete(level: level, undercover: _undercover);
      ref.read(levelStepAnswerProvider.notifier).set((level: level, undercover: _undercover));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LaunchScreen(start: restore ? FirstRunStart.restore : FirstRunStart.create),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Tor only is a promise about the first connection: on a second pass (Back from the PIN)
    // whose first pass left it off, connections were made already, so the row stays away
    // (as on the desktop). With it on, it stays, to turn it off again.
    final offered =
        ref.watch(levelFeaturesProvider.select((f) => f.undercoverOffered)) &&
        (ref.watch(firstStartProvider) || (ref.read(levelStepAnswerProvider)?.undercover ?? false));
    // Welcome's layout: the hero centred in the room above the two ways in, which sit at the
    // foot of the screen, with Tor only quiet under them. It scrolls only when large text
    // needs it.
    return SlotScaffold(
      glow: heroGlow,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: Center(child: BrandHero(title: l.firstRunTitle))),
                        const SizedBox(height: 16),
                        trustId(
                          TrustIds.welcomeCreate,
                          FilledButton.icon(
                            key: levelCreateKey,
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            icon: const Icon(Icons.add),
                            label: Text(l.firstRunCreate),
                            onPressed: _busy ? null : () => _go(restore: false),
                          ),
                        ),
                        const SizedBox(height: 16),
                        trustId(
                          TrustIds.welcomeRestore,
                          OutlinedButton.icon(
                            key: levelRestoreKey,
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            icon: const Icon(Icons.restore),
                            label: Text(l.firstRunRestore),
                            onPressed: _busy ? null : () => _go(restore: true),
                          ),
                        ),
                        // Niche, so under the two ways in and quiet (the owner).
                        if (offered) ...[
                          const SizedBox(height: 16),
                          UndercoverRow(
                            value: _undercover,
                            onChanged: _busy ? null : (v) => setState(() => _undercover = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
