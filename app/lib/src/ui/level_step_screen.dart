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
import 'theme/tokens.dart';

/// The words of a level, shared by the first-start step, the Change level dialog and the
/// Advanced row.
String levelTitle(AppLocalizations l, WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => l.levelOneTitle,
  WalletLevel.casual => l.levelTwoTitle,
  WalletLevel.everything => l.levelThreeTitle,
};

String _levelLine(AppLocalizations l, WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => l.levelOneLine,
  WalletLevel.casual => l.levelTwoLine,
  WalletLevel.everything => l.levelThreeLine,
};

/// The key of a level's tile, for tests: `levelTileKey(WalletLevel.casual)`.
Key levelTileKey(WalletLevel level) => ValueKey('level-tile-${level.number}');

/// The "Undercover from the start" switch's key, for tests.
const Key levelUndercoverKey = ValueKey('level-undercover');

/// The Continue button's key, for tests.
const Key levelContinueKey = ValueKey('level-continue');

/// The three levels as radio tiles, with the Undercover switch in Tor builds. Placeholder
/// look until the level design lands.
class LevelChoices extends StatelessWidget {
  const LevelChoices({
    super.key,
    required this.level,
    required this.onLevel,
    required this.undercover,
    required this.onUndercover,
  });

  final WalletLevel? level;
  final ValueChanged<WalletLevel> onLevel;
  final bool undercover;
  final ValueChanged<bool> onUndercover;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RadioGroup<WalletLevel>(
          groupValue: level,
          onChanged: (v) {
            if (v != null) onLevel(v);
          },
          child: Column(
            children: [
              for (final lv in WalletLevel.values)
                RadioListTile<WalletLevel>(
                  key: levelTileKey(lv),
                  value: lv,
                  title: Text(levelTitle(l, lv)),
                  subtitle: Text(_levelLine(l, lv)),
                ),
            ],
          ),
        ),
        if (torBuilt)
          SwitchListTile(
            key: levelUndercoverKey,
            value: undercover,
            onChanged: onUndercover,
            title: Text(l.levelUndercoverTitle),
            subtitle: Text(l.levelUndercoverLine),
          ),
      ],
    );
  }
}

/// First start of a fresh install, before Welcome and the PIN: the level and, in Tor builds,
/// Undercover from the start. Nothing connects until Continue.
class LevelStepScreen extends ConsumerStatefulWidget {
  const LevelStepScreen({super.key});

  @override
  ConsumerState<LevelStepScreen> createState() => _LevelStepScreenState();
}

class _LevelStepScreenState extends ConsumerState<LevelStepScreen> {
  WalletLevel? _level;
  bool _undercover = false;
  bool _busy = false;

  Future<void> _continue() async {
    final level = _level;
    if (level == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(firstStartProvider.notifier).complete(level: level, undercover: _undercover);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const LaunchScreen()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return SlotScaffold(
      body: ScreenBody(
        bottom: BusyButton(
          key: levelContinueKey,
          label: l.commonContinue,
          busy: _busy,
          onPressed: _level == null ? null : _continue,
        ),
        children: [
          const SizedBox(height: 16),
          Text(l.levelStepTitle, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          LevelChoices(
            level: _level,
            onLevel: (v) => setState(() => _level = v),
            undercover: _undercover,
            onUndercover: (v) => setState(() => _undercover = v),
          ),
          const SizedBox(height: 16),
          Text(l.levelFooter, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.dim)),
        ],
      ),
    );
  }
}

/// Settings › Advanced › Wallet level: the same choices in a dialog. Picking a level stores it
/// at once; the Undercover switch (Tor builds) maps to the Tor only network mode.
Future<void> showChangeLevelDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final l = context.l10n;
        final level = ref.watch(currentLevelProvider);
        final mode = ref.watch(appSettingsProvider.select((s) => s.value?.advanced.networkMode)) ?? NetworkMode.standard;
        return AlertDialog(
          title: Text(l.levelChangeTitle),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SingleChildScrollView(
            child: LevelChoices(
              level: level,
              onLevel: (v) => ref.read(walletLevelProvider.notifier).setLevel(v),
              undercover: mode == NetworkMode.torOnly,
              onUndercover: (on) async {
                final settings = await ref.read(appSettingsProvider.future);
                await ref
                    .read(appSettingsProvider.notifier)
                    .setAdvanced(settings.advanced.withMode(on ? NetworkMode.torOnly : NetworkMode.standard));
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel))],
        );
      },
    ),
  );
}
