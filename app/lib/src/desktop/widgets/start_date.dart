// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../../l10n.dart' show localInt, localMonthShort, localMonthYear, localYear;
import '../../start_month.dart';
import '../desk_l10n.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'dialogs.dart';
import 'selectable.dart';

export '../../start_month.dart' show mainnetHeightForDate;

/// The start of a restore or a Recheck balance as a month (the owner, 2026-11-01: a year and a
/// month, no day; the scan starts from the first): a button that opens the month picker and,
/// under it, the block the chosen month starts from, with a warning when the month is this one
/// or the one before. The phone's twin is `StartMonthChoice` (`ui/month_picker.dart`); both
/// share `start_month.dart`. Months map to heights on mainnet only.
class EStartDate extends StatelessWidget {
  const EStartDate({super.key, required this.date, required this.onChanged, this.label, this.hint});

  /// The chosen month's first day; null for none.
  final DateTime? date;

  /// Called with the first day of the month picked.
  final ValueChanged<DateTime?> onChanged;

  /// The button before a month is chosen ("Pick a month").
  final String? label;

  /// The line under the button before a month is chosen; none when null.
  final String? hint;

  /// The key of the recent-month warning, for tests.
  static const Key recentKey = ValueKey('start-date-recent');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final chosen = date == null ? null : StartMonth.of(date!);
    final line = chosen == null ? hint : l.restoreMonthStart(localInt(l, chosen.height));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EButton(
          key: const ValueKey('start-date-pick'),
          label: chosen == null ? (label ?? l.restorePickMonth) : localMonthYear(l, chosen.firstDay),
          icon: EIcons.calendar,
          size: EBtnSize.sm,
          onPressed: () async {
            final picked = await showEStartMonthPicker(context, initial: chosen);
            if (picked != null) onChanged(picked.firstDay);
          },
        ),
        if (line != null) ...[SizedBox(height: Sp.x1), Text(line, style: ts.small)],
        if (chosen != null && startMonthRecent(chosen, DateTime.now()))
          Semantics(
            key: recentKey,
            liveRegion: true,
            container: true,
            child: Padding(
              padding: EdgeInsets.only(top: Sp.x1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.u),
                    child: Icon(EIcons.alert, size: Ctl.iconSm, color: c.warn),
                  ),
                  SizedBox(width: 6.u),
                  Flexible(child: Text(l.restoreMonthRecent, style: ts.small.copyWith(color: c.warn))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Opens the month picker: the year between its arrows and the twelve months under it. It
/// opens on [initial]'s year, else on the first year a wallet can be from (never today).
/// Returns the month clicked, or null when closed.
Future<StartMonth?> showEStartMonthPicker(BuildContext context, {StartMonth? initial}) => showEDialog<StartMonth>(
  context,
  builder: (_) => EStartMonthPicker(initial: initial, now: DateTime.now()),
);

/// The picker dialog. [now] bounds the months offered.
class EStartMonthPicker extends StatefulWidget {
  const EStartMonthPicker({super.key, this.initial, required this.now});

  final StartMonth? initial;
  final DateTime now;

  /// The key of a month's cell, for tests: `start-month-2021-07`.
  static Key monthKey(StartMonth m) => ValueKey('start-month-$m');

  static const Key earlierKey = ValueKey('start-month-earlier');
  static const Key laterKey = ValueKey('start-month-later');

  @override
  State<EStartMonthPicker> createState() => _EStartMonthPickerState();
}

class _EStartMonthPickerState extends State<EStartMonthPicker> {
  late int _year = startPickerYear(widget.initial);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final years = startYears(widget.now);
    return EDialog(
      title: l.restoreDatePickerTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EIconButton(
                key: EStartMonthPicker.earlierKey,
                icon: EIcons.chevronLeft,
                label: l.restoreMonthEarlierYear,
                onPressed: _year > years.first ? () => setState(() => _year--) : null,
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    localYear(l, DateTime(_year)),
                    textAlign: TextAlign.center,
                    style: ts.h3.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ),
              ),
              EIconButton(
                key: EStartMonthPicker.laterKey,
                icon: EIcons.chevronRight,
                label: l.restoreMonthLaterYear,
                onPressed: _year < years.last ? () => setState(() => _year++) : null,
              ),
            ],
          ),
          SizedBox(height: Sp.x3),
          for (var row = 0; row < 3; row++) ...[
            if (row > 0) SizedBox(height: Sp.x2),
            Row(
              children: [
                for (var col = 0; col < 4; col++) ...[
                  if (col > 0) SizedBox(width: Sp.x2),
                  Expanded(child: _cell(StartMonth(_year, row * 4 + col + 1))),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(StartMonth m) => _MonthCell(
    month: m,
    selected: widget.initial == m,
    enabled: startMonthOffered(m, widget.now),
    autofocus: widget.initial == null ? m == firstStartMonth : widget.initial == m,
  );
}

/// One month: neutral when selected (the raised s4 fill and its hairline, as [ESegmented]),
/// never the gold. Focusable; Enter or Space picks it.
class _MonthCell extends StatefulWidget {
  const _MonthCell({required this.month, required this.selected, required this.enabled, required this.autofocus});

  final StartMonth month;
  final bool selected;
  final bool enabled;
  final bool autofocus;

  @override
  State<_MonthCell> createState() => _MonthCellState();
}

class _MonthCellState extends State<_MonthCell> {
  bool _hover = false;

  void _pick() => Navigator.of(context).pop(widget.month);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final sel = widget.selected;
    final on = widget.enabled;
    final fg = !on ? c.faint : (sel || _hover ? c.text : c.dim);
    return Semantics(
      button: true,
      selected: sel,
      enabled: on,
      label: localMonthYear(l, widget.month.firstDay),
      excludeSemantics: true,
      onTap: on ? _pick : null,
      child: FocusableActionDetector(
        key: EStartMonthPicker.monthKey(widget.month),
        enabled: on,
        autofocus: on && widget.autofocus,
        mouseCursor: on ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hover = v && on),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => on ? _pick() : null)},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: on ? _pick : null,
            child: FocusRing(
              focused: Focus.of(context).hasFocus,
              child: AnimatedContainer(
                duration: Dur.fast,
                height: Ctl.md,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? c.s4 : (_hover ? c.hover : Colors.transparent),
                  borderRadius: BorderRadius.circular(Rad.sm),
                  border: Border.all(color: sel ? c.lineStrong : (on ? c.line : Colors.transparent)),
                ),
                child: NoSelect(
                  child: Text(
                    localMonthShort(l, widget.month.firstDay),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: Fs.md, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: fg),
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
