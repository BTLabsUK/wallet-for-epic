/// Settings › Advanced › Confirmations: the open wallet's minimum confirmations as a stepper
/// (−, the count, +), 1–30. The default (6) carries a Default tag; any other count offers
/// Reset, and a count below the default a quiet line on what it trades. Each tap applies at
/// once; quick taps are stored as one ([MinimumConfirmationsSetting]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../min_confirmations.dart';
import '../models.dart'
    show defaultMinimumConfirmations, maxMinimumConfirmations, minMinimumConfirmations;
import 'badge.dart';
import 'info_hint.dart';
import 'notices.dart';
import 'theme/tokens.dart';

/// Keys of the row's parts, for tests and the tour.
const confirmationsRowKey = ValueKey('adv-confirmations');
const confirmationsMinusKey = ValueKey('adv-confirmations-minus');
const confirmationsPlusKey = ValueKey('adv-confirmations-plus');
const confirmationsValueKey = ValueKey('adv-confirmations-value');
const confirmationsResetKey = ValueKey('adv-confirmations-reset');
const confirmationsNoteKey = ValueKey('adv-confirmations-note');

class ConfirmationsRow extends ConsumerWidget {
  const ConfirmationsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final setting = ref.watch(minimumConfirmationsSettingProvider);
    final count = setting.value;
    final ready = count != null && !setting.hasError;
    final shown = count ?? defaultMinimumConfirmations;

    Future<void> set(int next) async {
      try {
        await ref.read(minimumConfirmationsSettingProvider.notifier).set(next);
      } catch (error) {
        if (!context.mounted) return;
        ref.read(noticeProvider.notifier).show(describeError(context.l10n, error), level: NoticeLevel.error);
      }
    }

    final atDefault = shown == defaultMinimumConfirmations;
    final valueText = Semantics(
      label: l.advConfirmations,
      value: l.advConfirmationsCount(shown),
      liveRegion: true,
      excludeSemantics: true,
      child: SizedBox(
        width: 32,
        child: Text(
          '$shown',
          key: confirmationsValueKey,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          key: confirmationsRowKey,
          leading: const Icon(Icons.verified_outlined),
          title: TitleWithHint(
            l.advConfirmations,
            hint: l.advConfirmationsHint(defaultMinimumConfirmations, minMinimumConfirmations, maxMinimumConfirmations),
            icon: Icons.verified_outlined,
          ),
          subtitle: !ready
              ? null
              : Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: atDefault
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: EBadge(l.advConfirmationsDefault),
                        )
                      : TextButton(
                          key: confirmationsResetKey,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(48, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => set(defaultMinimumConfirmations),
                          child: Text(l.advConfirmationsReset(defaultMinimumConfirmations)),
                        ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: confirmationsMinusKey,
                icon: const Icon(Icons.remove),
                tooltip: l.advConfirmationsFewer,
                onPressed: ready && shown > minMinimumConfirmations ? () => set(shown - 1) : null,
              ),
              valueText,
              IconButton(
                key: confirmationsPlusKey,
                icon: const Icon(Icons.add),
                tooltip: l.advConfirmationsMore,
                onPressed: ready && shown < maxMinimumConfirmations ? () => set(shown + 1) : null,
              ),
            ],
          ),
        ),
        if (ready && shown < defaultMinimumConfirmations)
          Padding(
            key: confirmationsNoteKey,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l.advConfirmationsLowNote,
              style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
            ),
          ),
      ],
    );
  }
}
