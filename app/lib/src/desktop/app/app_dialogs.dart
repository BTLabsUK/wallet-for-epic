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
        EButton(label: l.deskAppNotNow, size: EBtnSize.sm, kind: EBtnKind.ghost, onPressed: () => nav.pop(false)),
        EButton.primary(label: l.deskAppRestartNow, icon: EIcons.restart, size: EBtnSize.sm, onPressed: () => nav.pop(true)),
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

class FirstScanDialog extends StatelessWidget {
  const FirstScanDialog({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final t = context.l10n;
    final shown = [for (final l in lines) if (l.trim().isNotEmpty) l.trim()];
    return EDialog(
      title: t.deskAppFirstScanTitle,
      description: t.deskAppFirstScanBody,
      icon: EIcons.scan,
      width: 520.u,
      body: Semantics(
        label: t.deskAppScanOutput,
        child: Container(
          constraints: BoxConstraints(maxHeight: 260.u),
          decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
          child: shown.isEmpty
              ? Padding(padding: EdgeInsets.all(Sp.x3), child: Text(t.deskAppWaitingOutput, style: ts.small))
              : ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(Sp.x3),
                  children: [for (final l in shown) Text(l, style: ts.mono(size: Fs.xs, color: c.dim))],
                ),
        ),
      ),
      actions: [EButton(label: t.commonClose, size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop())],
    );
  }
}
