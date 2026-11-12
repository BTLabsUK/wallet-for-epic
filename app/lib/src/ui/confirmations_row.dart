// SPDX-License-Identifier: Apache-2.0
/// Settings › Advanced › Confirmations: the open wallet's minimum confirmations as a kit row
/// with a stepper (−, the count, +), 1–30. The default (6) carries a Default tag; any other count offers
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
import '../trust_ids.dart';
import 'inline_button.dart';
import 'kit/kit_group.dart';
import 'kit/kit_row.dart';
import 'kit/kit_settings.dart';
import 'kit/kit_tokens.dart';
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
  const ConfirmationsRow({super.key, this.subtitle, this.showDefaultTag = true});

  /// A phone line in place of the hint with the range.
  final String? subtitle;

  /// The "Default" tag under the row at the default count; the phone's Advanced page leaves it out.
  final bool showDefaultTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitGroup(
          dividerInset: Kit.dividerInsetPlain,
          children: [
            KitRow(
              key: confirmationsRowKey,
              title: l.advConfirmations,
              // The count's meaning; the default shows as a tag, any other count offers Reset.
              subtitle: subtitle ?? l.advConfirmationsHint(defaultMinimumConfirmations, minMinimumConfirmations, maxMinimumConfirmations),
              subtitleLines: 3,
              size: subtitle == null ? KitRowSize.settings : KitRowSize.list,
              trailing: KitStepper(
                value: shown,
                valueKey: confirmationsValueKey,
                minusKey: confirmationsMinusKey,
                plusKey: confirmationsPlusKey,
                minusId: TrustIds.confirmationsFewer,
                plusId: TrustIds.confirmationsMore,
                minusLabel: l.advConfirmationsFewer,
                plusLabel: l.advConfirmationsMore,
                valueLabel: l.advConfirmationsCount(shown),
                onMinus: ready && shown > minMinimumConfirmations ? () => set(shown - 1) : null,
                onPlus: ready && shown < maxMinimumConfirmations ? () => set(shown + 1) : null,
              ),
            ),
          ],
        ),
        if (ready && !(atDefault && !showDefaultTag))
          Padding(
            padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 10, Kit.gutter + 4, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: atDefault
                  ? KitTag(l.advConfirmationsDefault)
                  : InlineTextButton(
                      key: confirmationsResetKey,
                      onPressed: () => set(defaultMinimumConfirmations),
                      child: Text(l.advConfirmationsReset(defaultMinimumConfirmations)),
                    ),
            ),
          ),
        if (ready && shown < defaultMinimumConfirmations) KitFootnote(l.advConfirmationsLowNote, key: confirmationsNoteKey, color: t.dim),
      ],
    );
  }
}
