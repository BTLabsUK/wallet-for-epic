// SPDX-License-Identifier: Apache-2.0
/// Where a restore or a Recheck balance starts scanning: one block for every place that picks
/// it (phone and desktop restore, phone and desktop Recheck balance), so they look and behave
/// the same (the owner, 2026-11-03). One line says the start ("Scanning from January 2025"), a
/// calendar button beside it opens the month or block choice under the line, and an info
/// button explains the start and holds Scan from the start. The kit follows the tree: the
/// desktop's widgets under its theme, the phone's otherwise; the words, icons, order and
/// behaviour are the same.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

import '../desktop/desk_l10n.dart';
import '../desktop/widgets/kit.dart' as desk;
import '../l10n.dart' hide L10nContext;
import '../start_month.dart';
import '../trust_ids.dart';
import 'info_hint.dart';
import 'month_picker.dart' show StartMonthChoice;

/// By month (mainnet) or by block height.
enum ScanStartBy { month, height }

/// The start the block shows and edits. [dates]: months map to heights (mainnet only); a
/// test network picks a height or scans from the start.
class ScanStartController extends ChangeNotifier {
  ScanStartController({required this.dates}) : _by = dates ? ScanStartBy.month : ScanStartBy.height;

  final bool dates;

  ScanStartBy _by;
  ScanStartBy get by => _by;

  StartMonth _month = defaultStartMonth;
  StartMonth get month => _month;

  /// The typed block height; empty is the start.
  final TextEditingController height = TextEditingController();

  /// Scan from the start was chosen: block 0 instead of the month or height.
  bool _fromStart = false;

  /// The scan starts at block 0: chosen, or nothing else picked (no months, empty height).
  bool get fromStart => start == null;

  /// The month or block choice shows under the line.
  bool _open = false;
  bool get open => _open;

  /// The block the scan starts from; null is the start (block 0).
  BigInt? get start {
    if (_fromStart) return null;
    if (_by == ScanStartBy.month && dates) return _month.height;
    final h = BigInt.tryParse(height.text.trim());
    return h == null || h == BigInt.zero ? null : h;
  }

  /// Opens or closes the choice. Opening returns to the month or height: the choice is what
  /// the line then says.
  void toggle() {
    _open = !_open;
    if (_open) _fromStart = false;
    notifyListeners();
  }

  void pickBy(ScanStartBy by) {
    _by = by;
    _fromStart = false;
    notifyListeners();
  }

  void pickMonth(StartMonth month) {
    _month = month;
    _fromStart = false;
    notifyListeners();
  }

  void heightChanged() {
    _fromStart = false;
    notifyListeners();
  }

  /// Scan from the start (block 0): closes the choice; the line says so.
  void scanFromStart() {
    _fromStart = true;
    _open = false;
    notifyListeners();
  }

  @override
  void dispose() {
    height.dispose();
    super.dispose();
  }
}

/// The test drivers' names for the block's controls (`TrustIds`): the restore screens give
/// theirs; Recheck balance has none.
class ScanStartIds {
  const ScanStartIds({this.start, this.info, this.byMonth, this.byHeight, this.month, this.height, this.fromStart});

  final String? start, info, byMonth, byHeight, month, height, fromStart;

  static const restore = ScanStartIds(
    start: TrustIds.restoreStart,
    info: TrustIds.restoreInfo,
    byMonth: TrustIds.restoreByMonth,
    byHeight: TrustIds.restoreByHeight,
    month: TrustIds.restoreMonth,
    height: TrustIds.restoreHeight,
    fromStart: TrustIds.restoreFromStart,
  );
}

/// The start line with its calendar and info buttons, and the choice under it while open.
/// [heights] false offers months only (Recheck balance without Advanced › Recheck from a
/// height); with neither months nor heights the calendar button is left out.
class ScanStart extends StatelessWidget {
  const ScanStart({super.key, required this.controller, this.heights = true, this.ids = const ScanStartIds()});

  final ScanStartController controller;
  final bool heights;
  final ScanStartIds ids;

  /// Keys for tests.
  static const Key lineKey = ValueKey('scan-start-line');
  static const Key changeKey = ValueKey('scan-start-change');
  static const Key infoKey = ValueKey('scan-start-info');
  static const Key fromStartKey = ValueKey('scan-start-from-start');
  static const Key byKey = ValueKey('scan-start-by');
  static const Key heightKey = ValueKey('scan-start-height');

  /// The line: the month, the block or the start.
  static String line(AppLocalizations l, ScanStartController c) {
    final start = c.start;
    if (start == null) return l.restoreScanningFromStart;
    if (c.by == ScanStartBy.month && c.dates) return l.restoreScanningFrom(localMonthYear(l, c.month.firstDay));
    return l.restoreScanningFromBlock(localInt(l, start));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Theme.of(context).extension<desk.DeskColors>() != null ? _desk(context) : _phone(context),
  );

  bool get _picks => controller.dates || heights;
  bool get _byMonth => controller.dates && controller.by == ScanStartBy.month;
  bool get _both => controller.dates && heights;

  InfoAction? _fromStartAction(AppLocalizations l) => controller.fromStart
      ? null
      : InfoAction(l.restoreScanFromStart, controller.scanFromStart, key: fromStartKey, semanticsId: ids.fromStart);

  /// The calendar button: one node that says whether the choice is open.
  Widget _change(bool open, Widget button) => MergeSemantics(child: Semantics(expanded: open, child: button));

  Widget _phone(BuildContext context) {
    final l = context.l10n;
    final c = controller;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text(line(l, c), key: lineKey, style: theme.textTheme.bodyMedium)),
            if (_picks)
              _change(
                c.open,
                IconButton(
                  key: changeKey,
                  tooltip: l.scanStartChange,
                  isSelected: c.open,
                  icon: TrustId(ids.start, child: const Icon(Icons.calendar_month_outlined)),
                  onPressed: c.toggle,
                ),
              ),
            TrustId(
              ids.info,
              child: InfoHint(l.scanStartInfo, key: infoKey, title: l.scanStartInfoTitle, action: _fromStartAction(l)),
            ),
          ],
        ),
        if (_picks)
          desk.ExpandFade(
            open: c.open,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_both) ...[
                    SegmentedButton<ScanStartBy>(
                      key: byKey,
                      segments: [
                        ButtonSegment(value: ScanStartBy.month, label: TrustId(ids.byMonth, child: Text(l.restoreStartByMonth))),
                        ButtonSegment(value: ScanStartBy.height, label: TrustId(ids.byHeight, child: Text(l.restoreStartByHeight))),
                      ],
                      selected: {c.by},
                      showSelectedIcon: false,
                      style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 44))),
                      onSelectionChanged: (s) => c.pickBy(s.first),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_byMonth)
                    StartMonthChoice(
                      date: c.month.firstDay,
                      semanticsId: ids.month,
                      onChanged: (d) => c.pickMonth(d == null ? defaultStartMonth : StartMonth.of(d)),
                    )
                  else
                    TrustId(
                      ids.height,
                      child: TextField(
                        key: heightKey,
                        controller: c.height,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => c.heightChanged(),
                        decoration: InputDecoration(labelText: l.restoreStartHeightLabel, helperText: l.restoreStartHeightHelper),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _desk(BuildContext context) {
    final l = context.l10n;
    final c = controller;
    final ts = context.ts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(line(l, c), key: lineKey, style: ts.body)),
            SizedBox(width: desk.Sp.x1),
            if (_picks)
              _change(
                c.open,
                desk.EIconButton(
                  key: changeKey,
                  icon: desk.EIcons.calendar,
                  label: l.scanStartChange,
                  selected: c.open,
                  semanticsId: ids.start,
                  onPressed: c.toggle,
                ),
              ),
            TrustId(
              ids.info,
              child: desk.EInfoHint(
                l.scanStartInfo,
                key: infoKey,
                title: l.scanStartInfoTitle,
                size: desk.Ctl.sm,
                action: _fromStartAction(l),
              ),
            ),
          ],
        ),
        if (_picks)
          desk.ExpandFade(
            open: c.open,
            child: Padding(
              padding: EdgeInsets.only(top: desk.Sp.x2, bottom: desk.Sp.x1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_both) ...[
                    desk.ESegmented<ScanStartBy>(
                      key: byKey,
                      segments: [
                        desk.ESegment(ScanStartBy.month, l.restoreStartByMonth, semanticsId: ids.byMonth),
                        desk.ESegment(ScanStartBy.height, l.restoreStartByHeight, semanticsId: ids.byHeight),
                      ],
                      value: c.by,
                      onChanged: c.pickBy,
                    ),
                    SizedBox(height: desk.Sp.x3),
                  ],
                  if (_byMonth)
                    desk.EStartDate(
                      date: c.month.firstDay,
                      semanticsId: ids.month,
                      onChanged: (d) => c.pickMonth(d == null ? defaultStartMonth : StartMonth.of(d)),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: desk.Ctl.rowWide),
                      child: desk.EField(
                        label: l.restoreStartHeightLabel,
                        help: l.restoreStartHeightHelper,
                        child: desk.EInput(
                          key: heightKey,
                          controller: c.height,
                          mono: true,
                          semanticLabel: l.restoreStartHeightLabel,
                          semanticsId: ids.height,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => c.heightChanged(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
