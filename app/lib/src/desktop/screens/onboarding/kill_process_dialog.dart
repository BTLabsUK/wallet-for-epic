// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// A wallet or node process left from an earlier run.
class EpicProcess {
  const EpicProcess(this.pid, this.name, this.cmd);

  final int pid;
  final String name;
  final String cmd;

  bool get isWallet => cmd.contains('epic-wallet');

  /// What the process is, from its command line; null when unknown.
  EpicProcessRole? get role {
    if (isWallet && RegExp('owner_api|listen|scan').hasMatch(cmd)) return EpicProcessRole.walletService;
    if (cmd.contains('server')) return EpicProcessRole.node;
    return null;
  }
}

enum EpicProcessRole { walletService, node }

/// The processes the mock finds when the unlock password is `busy`.
const mockEpicProcesses = [
  EpicProcess(48213, 'epic-wallet', 'epic-wallet --floonet owner_api'), // l10n-ok: a command line
  EpicProcess(48190, 'epic', 'epic server run'), // l10n-ok: a command line
];

/// "Epic is already running": the wallet or node processes from an earlier run, and closing
/// them to unlock here. [close] runs while "Closing…" shows. True when they were closed.
Future<bool> showKillProcessDialog(
  BuildContext context, {
  List<EpicProcess> processes = mockEpicProcesses,
  Future<void> Function()? close,
}) async =>
    await showEDialog<bool>(
      context,
      builder: (_) => _KillProcessDialog(processes, close ?? () => Future<void>.delayed(const Duration(milliseconds: 900))),
    ) ??
    false;

class _KillProcessDialog extends StatefulWidget {
  const _KillProcessDialog(this.processes, this.close);

  final List<EpicProcess> processes;
  final Future<void> Function() close;

  @override
  State<_KillProcessDialog> createState() => _KillProcessDialogState();
}

class _KillProcessDialogState extends State<_KillProcessDialog> {
  bool _closing = false;

  Future<void> _close() async {
    if (_closing) return;
    setState(() => _closing = true);
    await widget.close();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return PopScope(
      canPop: !_closing,
      child: EDialog(
        title: l.deskOnbKillTitle,
        description: l.deskOnbKillBody,
        icon: EIcons.alert,
        tone: ETone.warn,
        dismissible: !_closing,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: l.deskOnbKillProcesses,
              container: true,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(Rad.sm),
                ),
                child: Column(
                  children: [
                    for (final (i, p) in widget.processes.indexed)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
                        decoration: BoxDecoration(
                          border: i == 0 ? null : Border(top: BorderSide(color: c.line)),
                        ),
                        child: Row(
                          children: [
                            Icon(p.isWallet ? EIcons.wallet : EIcons.server, size: Ctl.iconSm, color: c.dim),
                            SizedBox(width: Sp.x2),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: p.name, style: ts.mono()),
                                    if (p.role != null)
                                      TextSpan(
                                        text: '  ${switch (p.role!) {
                                          EpicProcessRole.walletService => l.deskOnbKillRoleWallet,
                                          EpicProcessRole.node => l.deskOnbKillRoleNode,
                                        }}',
                                        style: ts.caption,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Text('PID ${p.pid}', style: ts.mono().copyWith(color: c.faint)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Sp.x3),
            Text(l.deskOnbKillNote, style: ts.small),
          ],
        ),
        actions: [
          EButton.ghost(label: l.commonCancel, onPressed: _closing ? null : () => Navigator.pop(context, false)),
          EButton(
            label: _closing ? l.deskOnbKillClosing : l.deskOnbKillClose,
            kind: EBtnKind.danger,
            busy: _closing,
            onPressed: _close,
          ),
        ],
      ),
    );
  }
}
