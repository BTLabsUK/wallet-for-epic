// SPDX-License-Identifier: Apache-2.0
/// The phone's start-month picker (restore, Recheck balance): a year and a month, no day
/// (the owner, 2026-11-01). The logic is shared with the desktop's ([StartMonth] in
/// `start_month.dart`); this is the phone's look on its tokens.
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../start_month.dart';
import 'phone_sheet.dart';
import 'theme/tokens.dart';

/// The start-month button, the line under it and, once a month is chosen, the warning for a
/// recent one and [onClear]'s button. [date] is the chosen month's first day, null for none.
class StartMonthChoice extends StatelessWidget {
  const StartMonthChoice({
    super.key,
    required this.date,
    required this.onChanged,
    this.label,
    this.hint,
    this.clearLabel,
  });

  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  /// The button before a month is chosen; [AppLocalizations.restorePickMonth] when null.
  final String? label;

  /// The line under the button before a month is chosen; none when null.
  final String? hint;

  /// A button under a chosen month that clears it ("Scan the whole chain instead"); none when
  /// null.
  final String? clearLabel;

  /// The key of the button, for tests.
  static const Key buttonKey = ValueKey('start-month-pick');

  /// The key of the recent-month warning, for tests.
  static const Key recentKey = ValueKey('start-month-recent');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final chosen = date == null ? null : StartMonth.of(date!);
    final small = theme.textTheme.bodySmall;
    final line = chosen == null ? hint : l.restoreMonthStart(localInt(l, chosen.height));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          key: buttonKey,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(chosen == null ? (label ?? l.restorePickMonth) : localMonthYear(l, chosen.firstDay)),
          onPressed: () async {
            final picked = await showStartMonthPicker(context, initial: chosen);
            if (picked != null) onChanged(picked.firstDay);
          },
        ),
        if (line != null) ...[const SizedBox(height: 4), Text(line, style: small?.copyWith(color: t.dim))],
        if (chosen != null && startMonthRecent(chosen, DateTime.now()))
          Semantics(
            key: recentKey,
            liveRegion: true,
            container: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(Icons.warning_amber_rounded, size: 16, color: t.warn),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l.restoreMonthRecent, style: small?.copyWith(color: t.warn)),
                  ),
                ],
              ),
            ),
          ),
        if (chosen != null && clearLabel != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: () => onChanged(null), child: Text(clearLabel!)),
          ),
      ],
    );
  }
}

/// Opens the month picker as a sheet: the year with its arrows, the twelve months under it.
/// It opens on [initial]'s year, else on the first year a wallet can be from (never today).
/// Returns the month tapped, or null when dismissed.
Future<StartMonth?> showStartMonthPicker(BuildContext context, {StartMonth? initial}) => showPhoneSheet<StartMonth>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => StartMonthPicker(initial: initial, now: DateTime.now()),
);

/// The sheet's body. [now] bounds the months offered.
class StartMonthPicker extends StatefulWidget {
  const StartMonthPicker({super.key, this.initial, required this.now});

  final StartMonth? initial;
  final DateTime now;

  /// The key of a month's cell, for tests: `start-month-2021-07`.
  static Key monthKey(StartMonth m) => ValueKey('start-month-$m');

  static const Key earlierKey = ValueKey('start-month-earlier');
  static const Key laterKey = ValueKey('start-month-later');

  @override
  State<StartMonthPicker> createState() => _StartMonthPickerState();
}

class _StartMonthPickerState extends State<StartMonthPicker> {
  late int _year = startPickerYear(widget.initial);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final years = startYears(widget.now);
    final yearStyle = theme.textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l.restoreDatePickerTitle, style: theme.textTheme.titleMedium)),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                key: StartMonthPicker.earlierKey,
                tooltip: l.restoreMonthEarlierYear,
                icon: const Icon(Icons.chevron_left),
                onPressed: _year > years.first ? () => setState(() => _year--) : null,
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(localYear(l, DateTime(_year)), textAlign: TextAlign.center, style: yearStyle),
                ),
              ),
              IconButton(
                key: StartMonthPicker.laterKey,
                tooltip: l.restoreMonthLaterYear,
                icon: const Icon(Icons.chevron_right),
                onPressed: _year < years.last ? () => setState(() => _year++) : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Three rows of four; a cell is at least 48 dp tall and grows with the text size.
          for (var row = 0; row < 3; row++) ...[
            if (row > 0) const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var col = 0; col < 4; col++) ...[
                    if (col > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _MonthCell(
                        month: StartMonth(_year, row * 4 + col + 1),
                        selected: widget.initial == StartMonth(_year, row * 4 + col + 1),
                        enabled: startMonthOffered(StartMonth(_year, row * 4 + col + 1), widget.now),
                        tokens: t,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({required this.month, required this.selected, required this.enabled, required this.tokens});

  final StartMonth month;
  final bool selected;
  final bool enabled;
  final WalletTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = tokens;
    final radius = BorderRadius.circular(t.radiusSmall);
    // Selected is neutral (the selected fill and line), never the gold: a choice, not an action.
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: localMonthYear(l, month.firstDay),
      excludeSemantics: true,
      child: Material(
        color: selected ? t.selected : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected
                ? t.selectedLine
                : enabled
                ? t.line
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          key: StartMonthPicker.monthKey(month),
          borderRadius: radius,
          onTap: enabled ? () => Navigator.pop(context, month) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  localMonthShort(l, month.firstDay),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: enabled ? t.text : t.faint,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
