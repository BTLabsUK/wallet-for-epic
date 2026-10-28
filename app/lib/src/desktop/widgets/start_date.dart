// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../../l10n.dart' show localDay, localInt;
import '../../ui/restore_screen.dart' show mainnetFirstDay, mainnetHeightForDate;
import '../desk_l10n.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart';

export '../../ui/restore_screen.dart' show mainnetHeightForDate;

/// The phone's date start (restore, Recheck balance): a button that opens the date picker and,
/// under it, the block a chosen date starts from. Dates map to heights on mainnet only.
class EStartDate extends StatelessWidget {
  const EStartDate({super.key, required this.date, required this.onChanged, this.label, this.hint});

  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  /// The button before a date is chosen ("Pick a date").
  final String? label;

  /// The line under the button before a date is chosen; none when null.
  final String? hint;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: mainnetFirstDay,
      lastDate: now,
      helpText: context.l10n.restoreDatePickerTitle,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final chosen = date;
    final line = chosen == null ? hint : l.restoreDateStart(localInt(l, mainnetHeightForDate(chosen)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EButton(
          key: const ValueKey('start-date-pick'),
          label: chosen == null ? (label ?? l.restorePickDate) : l.restoreFromDate(localDay(l, chosen)),
          icon: EIcons.calendar,
          size: EBtnSize.sm,
          onPressed: () => _pick(context),
        ),
        if (line != null) ...[
          SizedBox(height: Sp.x1),
          Text(line, style: context.ts.small),
        ],
      ],
    );
  }
}
