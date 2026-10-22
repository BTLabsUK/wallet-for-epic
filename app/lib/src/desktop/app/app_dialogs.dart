/// App-level dialogs the wallet raises by itself: the built-in node finished syncing, and the
/// first scan of a new wallet with its output.
library;

import 'package:flutter/material.dart';

import '../widgets/kit.dart';

/// The built-in node is synced: restart now (true) or later.
Future<bool?> showNodeSyncedDialog(BuildContext context) =>
    showEDialog<bool>(context, dismissible: false, builder: (_) => const NodeSyncedDialog());

class NodeSyncedDialog extends StatelessWidget {
  const NodeSyncedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    return EDialog(
      title: 'Local node synced',
      description: 'The local node has the whole chain and can be used now. The app restarts to switch to it.',
      icon: EIcons.server,
      tone: ETone.ok,
      actions: [
        EButton(label: 'Not now', size: EBtnSize.sm, kind: EBtnKind.ghost, onPressed: () => nav.pop(false)),
        EButton.primary(label: 'Restart now', icon: EIcons.restart, size: EBtnSize.sm, onPressed: () => nav.pop(true)),
      ],
    );
  }
}

/// Sample output of a first scan, newest last.
const firstScanDemoLines = [
  'Starting UTXO scan, 0% complete',
  'Checking 1000 outputs, up to index 1000 (highest index: 2914414)',
  'Identified 6 wallet outputs as belonging to this wallet',
  'Checking 1000 outputs, up to index 2000 (highest index: 2914414)',
  'Identified 3 wallet outputs as belonging to this wallet',
  'Scanning for outputs, 64% complete',
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
    final shown = [for (final l in lines) if (l.trim().isNotEmpty) l.trim()];
    return EDialog(
      title: 'Wallet first scan',
      description: 'The wallet looks through the chain for its outputs. It stays usable; the balance updates when the scan is done.',
      icon: EIcons.scan,
      width: 520.u,
      body: Semantics(
        label: 'Scan output',
        child: Container(
          constraints: BoxConstraints(maxHeight: 260.u),
          decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
          child: shown.isEmpty
              ? Padding(padding: EdgeInsets.all(Sp.x3), child: Text('Waiting for the first output…', style: ts.small))
              : ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(Sp.x3),
                  children: [for (final l in shown) Text(l, style: ts.mono(size: Fs.xs, color: c.dim))],
                ),
        ),
      ),
      actions: [EButton(label: 'Close', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop())],
    );
  }
}
