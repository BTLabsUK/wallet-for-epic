import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';

/// The scan a restore still owes ([ServiceStatus.restoreScan], D3): how far it is, that it
/// waits for the network in Offline, or that it stopped, with Try again. Overview shows it
/// instead of the empty-wallet state (R16, R35); Recheck balance instead of "A scan is already
/// running" (R24).
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
      if (mounted) showEToast(context, context.l10n.deskRsFailedTitle, text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final scan = widget.scan;
    switch (scan.state) {
      case RestoreScanState.waiting:
        return ENotice(key: const ValueKey('restore-scan-waiting'), tone: ETone.warn, icon: EIcons.clock, title: l.deskRsWaitingTitle, text: l.deskRsWaitingText);
      case RestoreScanState.failed:
        return ENotice(
          key: const ValueKey('restore-scan-failed'),
          tone: ETone.risk,
          title: l.deskRsFailedTitle,
          text: l.deskRsFailedText,
          actionsBelow: true,
          actions: [EButton(label: l.deskRsTryAgain, icon: EIcons.refresh, size: EBtnSize.inline, busy: _retrying, onPressed: _retrying ? null : _retry)],
        );
      case RestoreScanState.running:
        final percent = scan.percent;
        return EPanel(
          key: const ValueKey('restore-scan-running'),
          padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ESpinner(size: Ctl.iconSm),
                  SizedBox(width: Sp.x2),
                  Expanded(
                    child: Semantics(liveRegion: true, child: Text(percent == null ? l.deskRsRunningTitle : l.deskRsRunningPercent(percent), style: ts.strong)),
                  ),
                ],
              ),
              SizedBox(height: Sp.x3),
              EProgress(value: percent == null ? null : percent / 100),
              SizedBox(height: Sp.x3),
              Text(scan.fromHeight ? l.deskRsRunningFromHeight : l.deskRsRunningText, style: ts.small),
            ],
          ),
        );
    }
  }
}
