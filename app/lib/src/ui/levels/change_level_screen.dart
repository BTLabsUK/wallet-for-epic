// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart';
import '../../l10n.dart';
import '../../levels/level_providers.dart';
import '../../levels/wallet_level.dart';
import '../../settings.dart';
import '../common.dart';
import '../theme/tokens.dart';
import 'level_picker.dart';
import 'level_sheets.dart';

/// Change level's Save button, for tests.
const Key levelSaveKey = ValueKey('level-save');

/// Settings › Advanced › Wallet level: the picker's dial and preview with the level in force
/// picked, and Undercover (Network mode › Tor only) in Tor builds. Save applies both.
class ChangeLevelScreen extends ConsumerStatefulWidget {
  const ChangeLevelScreen({super.key});

  @override
  ConsumerState<ChangeLevelScreen> createState() => _ChangeLevelScreenState();
}

class _ChangeLevelScreenState extends ConsumerState<ChangeLevelScreen> {
  late WalletLevel _level;
  late final bool _wasUndercover;
  late bool _undercover;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _level = ref.read(currentLevelProvider);
    _wasUndercover = ref.read(appSettingsProvider).value?.advanced.networkMode == NetworkMode.torOnly;
    _undercover = _wasUndercover;
  }

  Future<void> _save() async {
    if (_busy) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      if (_level != ref.read(currentLevelProvider)) {
        await ref.read(walletLevelProvider.notifier).setLevel(_level);
      }
      if (_undercover != _wasUndercover) {
        // After the level: its preset may have changed the prefs.
        final settings = await ref.read(appSettingsProvider.future);
        await ref
            .read(appSettingsProvider.notifier)
            .setAdvanced(settings.advanced.withMode(_undercover ? NetworkMode.torOnly : NetworkMode.standard));
      }
      ref.read(noticeProvider.notifier).show(l.lvPickSaved, level: NoticeLevel.success);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final offered = ref.watch(levelFeaturesProvider.select((f) => f.undercoverOffered));
    return SlotScaffold(
      appBar: AppBar(title: Text(l.levelRowTitle), actions: const [LevelHelpHint(), SizedBox(width: 4)]),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: LayoutBuilder(
              builder: (context, box) {
                final compact = box.maxHeight < 560;
                return CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Semantics(
                                    label: l.lvPickPreview,
                                    child: ExcludeSemantics(
                                      child: LevelPreview(
                                        level: _level,
                                        height: levelPreviewHeight(box.maxHeight + 100),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  LevelDial(
                                    level: _level,
                                    compact: compact,
                                    onLevel: (v) => setState(() => _level = v),
                                  ),
                                  const SizedBox(height: 10),
                                  LevelCaption(level: _level, compact: compact),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                            if (offered) ...[
                              UndercoverRow(
                                later: true,
                                value: _undercover,
                                onChanged: _busy ? null : (v) => setState(() => _undercover = v),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.lvPickTakesEffect,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim),
                              ),
                              const SizedBox(height: 12),
                            ],
                            BusyButton(key: levelSaveKey, label: l.commonSave, busy: _busy, onPressed: _save),
                          ],
                        ),
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
