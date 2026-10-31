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
import 'common.dart';
import 'launch_screen.dart';
import 'levels/level_picker.dart';
import 'levels/level_sheets.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';

/// The words of a level, shared by the first-start step, Change level and the Advanced row.
String levelTitle(AppLocalizations l, WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => l.levelOneTitle,
  WalletLevel.casual => l.levelTwoTitle,
  WalletLevel.everything => l.levelThreeTitle,
};

/// The picker's "Create a new wallet" and "Restore from phrase" buttons, for tests.
const Key levelCreateKey = ValueKey('level-create');
const Key levelRestoreKey = ValueKey('level-restore');

/// The picker's last answer in this run, so Back from the PIN step or the restore phrase
/// returns to the picker with it, not to the old Welcome choice.
final levelStepAnswerProvider = NotifierProvider<LevelStepAnswer, ({WalletLevel level, bool undercover})?>(
  LevelStepAnswer.new,
);

class LevelStepAnswer extends Notifier<({WalletLevel level, bool undercover})?> {
  @override
  ({WalletLevel level, bool undercover})? build() => null;

  void set(({WalletLevel level, bool undercover}) answer) => state = answer;
}

/// First start of a fresh install, in place of Welcome: "Pick your depth" (the level, on the
/// depth dial, with a home preview that follows it), then Create or Restore, and under them,
/// quiet, Undercover from the start in Tor builds. Nothing connects until Create or Restore.
/// It fits a 320 x 568 phone without scrolling (the lead and the footer move into the ⓘ
/// sheet there); it scrolls only when large text needs it.
class LevelStepScreen extends ConsumerStatefulWidget {
  const LevelStepScreen({super.key});

  @override
  ConsumerState<LevelStepScreen> createState() => _LevelStepScreenState();
}

class _LevelStepScreenState extends ConsumerState<LevelStepScreen> {
  WalletLevel? _level;
  bool _undercover = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final answer = ref.read(levelStepAnswerProvider);
    if (answer != null) {
      _level = answer.level;
      _undercover = answer.undercover;
    }
  }

  Future<void> _go({required bool restore}) async {
    final level = _level;
    if (level == null || _busy) return;
    setState(() => _busy = true);
    try {
      // A second pass (Back from the PIN) with Undercover now off takes back the Tor only the
      // first one stored; complete() only ever turns it on.
      if (!_undercover && torBuilt && (ref.read(levelStepAnswerProvider)?.undercover ?? false)) {
        final settings = await ref.read(appSettingsProvider.future);
        await ref.read(appSettingsProvider.notifier).setAdvanced(settings.advanced.withMode(NetworkMode.standard));
      }
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
    final t = context.tokens;
    final theme = Theme.of(context);
    final offered = ref.watch(levelFeaturesProvider.select((f) => f.undercoverOffered));
    final ready = _level != null && !_busy;
    return SlotScaffold(
      glow: heroGlow,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: LayoutBuilder(
              builder: (context, box) {
                final compact = box.maxHeight < 640;
                return CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The lockup is the logo: it keeps its size at any text scale. The
                          // ⓘ sits where an app bar's actions do: its 48 dp box at the
                          // screen's edge, so the row runs past the content's side gutter.
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: MediaQuery.withNoTextScaling(
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: AlignmentDirectional.centerStart,
                                      child: BrandLockup(variant: BrandVariant.mobile, size: 22),
                                    ),
                                  ),
                                ),
                                const LevelHelpHint(),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        SizedBox(height: compact ? 0 : 8),
                                        Semantics(
                                          header: true,
                                          child: Text(
                                            l.lvPickTitle,
                                            textAlign: TextAlign.center,
                                            style:
                                                (compact ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)
                                                    ?.copyWith(color: t.text),
                                          ),
                                        ),
                                        if (!compact) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            l.lvPickLead,
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
                                          ),
                                        ],
                                        SizedBox(height: compact ? 6 : 12),
                                        Semantics(
                                          label: l.lvPickPreview,
                                          child: ExcludeSemantics(
                                            child: LevelPreview(
                                              level: _level,
                                              height: levelPreviewHeight(box.maxHeight),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: compact ? 6 : 12),
                                        LevelDial(
                                          level: _level,
                                          compact: compact,
                                          onLevel: (v) => setState(() => _level = v),
                                        ),
                                        SizedBox(height: compact ? 6 : 10),
                                        LevelCaption(level: _level, compact: compact),
                                        SizedBox(height: compact ? 6 : 12),
                                      ],
                                    ),
                                  ),
                                  FilledButton.icon(
                                    key: levelCreateKey,
                                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                    icon: const Icon(Icons.add),
                                    label: Text(l.firstRunCreate),
                                    onPressed: ready ? () => _go(restore: false) : null,
                                  ),
                                  SizedBox(height: compact ? 8 : 12),
                                  OutlinedButton.icon(
                                    key: levelRestoreKey,
                                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                    icon: const Icon(Icons.restore),
                                    label: Text(l.firstRunRestore),
                                    onPressed: ready ? () => _go(restore: true) : null,
                                  ),
                                  // Niche, so under the two ways in and quiet (the owner).
                                  if (offered) ...[
                                    SizedBox(height: compact ? 6 : 12),
                                    UndercoverRow(
                                      value: _undercover,
                                      onChanged: _busy ? null : (v) => setState(() => _undercover = v),
                                    ),
                                  ],
                                  if (!compact) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      l.levelFooter,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
