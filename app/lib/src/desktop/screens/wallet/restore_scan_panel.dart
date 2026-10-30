// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../../l10n.dart' show localInt;
import '../../widgets/kit.dart';

/// "Restore not finished" ([ServiceStatus.restoreScan], D3; copy D1): the scan from block 0
/// runs, waits for the network, or stopped, with Try again. Overview shows it instead of the
/// empty-wallet state, in the shape of the node-sync panel.
class RestoreScanPanel extends ConsumerStatefulWidget {
  const RestoreScanPanel({super.key, required this.scan});

  final RestoreScan scan;

  @override
  ConsumerState<RestoreScanPanel> createState() => _RestoreScanPanelState();
}

class _RestoreScanPanelState extends ConsumerState<RestoreScanPanel> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await ref.read(deskProvider.notifier).syncNow();
    } on Object catch (e) {
      if (mounted) showEToast(context, context.l10n.deskOvRestoreTitle, text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scan = widget.scan;
    switch (scan.state) {
      case RestoreScanState.waiting:
        return ENotice(
          key: const ValueKey('restore-scan-waiting'),
          tone: ETone.warn,
          icon: EIcons.clock,
          title: l.deskOvRestoreTitle,
          text: scan.offline ? '${l.deskOvRestoreWaiting} ${l.netBlockKillSwitch}' : l.deskOvRestoreWaiting,
        );
      case RestoreScanState.failed:
        return ENotice(
          key: const ValueKey('restore-scan-failed'),
          tone: ETone.risk,
          title: l.deskOvRestoreTitle,
          text: l.deskOvRestoreFailed,
          actionsBelow: true,
          actions: [EButton(label: l.deskSetupTryAgain, icon: EIcons.refresh, size: EBtnSize.inline, busy: _retrying, onPressed: _retrying ? null : _retry)],
        );
      case RestoreScanState.running:
        final from = scan.fromHeight;
        return ENotice(
          key: const ValueKey('restore-scan-running'),
          icon: EIcons.scan,
          title: l.deskOvRestoreTitle,
          text: from == null ? l.deskOvRestoreRunning : l.deskOvRestoreAfterHeight(localInt(l, from)),
          below: RestoreScanProgress(percent: scan.percent),
        );
    }
  }
}

/// The restore scan's bar and its "Checking… N %" line (Overview, Recheck balance).
class RestoreScanProgress extends StatelessWidget {
  const RestoreScanProgress({super.key, required this.percent});

  final int? percent;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = percent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l.deskOvRestoreProgress,
          value: p == null ? null : '$p%', // l10n-ok: a number and the percent sign
          child: EProgress(value: p == null ? null : p / 100),
        ),
        SizedBox(height: Sp.x1),
        Semantics(
          liveRegion: true,
          child: Text(p == null ? l.deskSetFrameChecking : l.deskSetRescanChecking(p), style: context.ts.caption),
        ),
      ],
    );
  }
}
