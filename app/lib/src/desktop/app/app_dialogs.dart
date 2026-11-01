// SPDX-License-Identifier: Apache-2.0
/// App-level dialogs the wallet raises by itself: the built-in node finished syncing, and the
/// first scan of a new wallet with its output.
library;

import 'package:flutter/material.dart';

import '../desk_l10n.dart';
import '../widgets/kit.dart';

/// The built-in node is synced: restart now (true) or later.
Future<bool?> showNodeSyncedDialog(BuildContext context) =>
    showEDialog<bool>(context, dismissible: false, builder: (_) => const NodeSyncedDialog());

class NodeSyncedDialog extends StatelessWidget {
  const NodeSyncedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    final l = context.l10n;
    return EDialog(
      title: l.deskAppNodeSyncedTitle,
      description: l.deskAppNodeSyncedBody,
      icon: EIcons.server,
      tone: ETone.ok,
      actions: [
        EButton(label: l.deskAppNotNow, onPressed: () => nav.pop(false)),
        EButton.primary(label: l.deskAppRestartNow, icon: EIcons.restart, onPressed: () => nav.pop(true)),
      ],
    );
  }
}

/// Sample output of a first scan, newest last.
const firstScanDemoLines = [
  'Starting UTXO scan, 0% complete', // l10n-ok: sample of the core's own English output
  'Checking 1000 outputs, up to index 1000 (highest index: 2914414)', // l10n-ok
  'Identified 6 wallet outputs as belonging to this wallet', // l10n-ok
  'Checking 1000 outputs, up to index 2000 (highest index: 2914414)', // l10n-ok
  'Identified 3 wallet outputs as belonging to this wallet', // l10n-ok
  'Scanning for outputs, 64% complete', // l10n-ok
];

/// The first scan of a wallet and its output; it runs on when closed.
Future<void> showFirstScanDialog(BuildContext context, {List<String> lines = firstScanDemoLines}) =>
    showEDialog(context, builder: (_) => FirstScanDialog(lines: lines));

/// The latest percentage and the outputs found so far, read from the core's English lines
/// ("…, 64% complete", "Identified 6 wallet outputs …").
({int? percent, int found}) firstScanSummary(List<String> lines) {
  int? percent;
  var found = 0;
  for (final line in lines) {
    final p = RegExp(r'(\d+)% complete').firstMatch(line);
    if (p != null) percent = int.parse(p.group(1)!);
    final f = RegExp(r'Identified (\d+) wallet outputs').firstMatch(line);
    if (f != null) found += int.parse(f.group(1)!);
  }
  return (percent: percent, found: found);
}

class FirstScanDialog extends StatefulWidget {
  const FirstScanDialog({super.key, required this.lines});

  final List<String> lines;

  @override
  State<FirstScanDialog> createState() => _FirstScanDialogState();
}

class _FirstScanDialogState extends State<FirstScanDialog> {
  bool _log = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final t = context.l10n;
    final shown = [for (final l in widget.lines) if (l.trim().isNotEmpty) l.trim()];
    final sum = firstScanSummary(shown);
    return EDialog(
      title: t.deskAppFirstScanTitle,
      description: t.deskAppFirstScanBody,
      icon: EIcons.scan,
      size: DialogWidth.standard,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shown.isEmpty)
            Text(t.deskAppWaitingOutput, style: ts.small)
          else ...[
            Text(t.deskAppFirstScanProgress(sum.percent ?? 0), style: ts.body),
            SizedBox(height: Sp.x1),
            Text(t.deskAppFirstScanFound(sum.found), style: ts.small.copyWith(color: c.dim)),
          ],
          if (_log && shown.isNotEmpty) ...[
            SizedBox(height: Sp.x3),
            Semantics(
              label: t.deskAppScanOutput,
              child: Container(
                constraints: BoxConstraints(maxHeight: 200.u),
                decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(Sp.x3),
                  children: [for (final l in shown) Text(l, style: ts.mono(size: Fs.xs, color: c.dim))],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (shown.isNotEmpty)
          EButton(label: _log ? t.deskAppFirstScanHideLog : t.deskAppFirstScanShowLog, onPressed: () => setState(() => _log = !_log)),
        EButton(label: t.commonClose, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
