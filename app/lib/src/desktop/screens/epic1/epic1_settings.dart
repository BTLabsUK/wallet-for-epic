// SPDX-License-Identifier: Apache-2.0
/// Settings › Transactions for epic1 payments (spec D1): the "Experimental" group with the
/// switch, shown in both modes, and in epic1 mode the "epic1" group with the Epicbox server and
/// the printed codes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../epic1.dart';
import '../../app/shell.dart' show lockWallet;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../settings/setting_ids.dart';
import '../wallet/tx_display.dart' show shortDay;

/// The confirm before epic1 payments are turned on. True: turn on.
Future<bool> askTurnOnEpic1(BuildContext context) async {
  final l = context.l10n;
  final sure = await showEDialog<bool>(
    context,
    builder: (ctx) => EDialog(
      key: const ValueKey('e1-turn-on-dialog'),
      title: l.deskE1TurnOnTitle,
      description: l.deskE1TurnOnBody,
      icon: EIcons.sealed,
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.pop(ctx, false)),
        EButton.primary(key: const ValueKey('e1-turn-on'), label: l.deskE1TurnOn, autofocus: true, onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  return sure == true;
}

/// The last group of Settings › Transactions: the epic1 payments switch. The stored value
/// applies at the next unlock; until then the row says so and offers Lock now. Nothing shows
/// when the wallet has no epic1 payments.
class Epic1ExperimentalGroup extends ConsumerStatefulWidget {
  const Epic1ExperimentalGroup({super.key});

  @override
  ConsumerState<Epic1ExperimentalGroup> createState() => _Epic1ExperimentalGroupState();
}

class _Epic1ExperimentalGroupState extends ConsumerState<Epic1ExperimentalGroup> {
  bool _busy = false;

  Future<void> _set(Epic1Wallet e1, bool on) async {
    if (on && !await askTurnOnEpic1(context)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await e1.setStoredOn(on);
    } on Object catch (e) {
      if (mounted) showEToast(context, deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final e1 = ref.watch(deskApiProvider).epic1;
    if (e1 == null) return const SizedBox.shrink();
    // The mode in use changes at unlock; the row rebuilds with it.
    ref.watch(deskPaymentModeProvider);
    final pending = e1.storedOn != e1.inUse;
    return ESetGroup(
      key: const ValueKey('e1-experimental'),
      title: l.advExperimental,
      rows: [
        ESetRow(
          key: const ValueKey('e1-row'),
          anchor: SetId.epic1Payments,
          title: l.deskE1SetSwitch,
          hint: l.deskE1SetInfo,
          hintTitle: l.deskE1SetSwitch,
          control: SizedBox(
            width: 40.u,
            height: 24.u,
            child: _busy
                ? Center(child: ESpinner(size: 18.u))
                : ESwitch(
                    key: const ValueKey('e1-switch'),
                    value: e1.storedOn,
                    semanticLabel: l.deskE1SetSwitch,
                    onChanged: (v) => _set(e1, v),
                  ),
          ),
          below: !pending
              ? null
              : Row(
                  key: const ValueKey('e1-applies'),
                  children: [
                    Icon(EIcons.clock, size: 16.u, color: c.dim),
                    SizedBox(width: Sp.x2),
                    Expanded(child: Text(l.deskE1AppliesNext, style: context.ts.small.copyWith(color: c.dim))),
                    SizedBox(width: Sp.x3),
                    EButton(
                      key: const ValueKey('e1-lock-now'),
                      label: l.deskE1LockNow,
                      icon: EIcons.lock,
                      size: EBtnSize.inline,
                      onPressed: () => lockWallet(ref),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// The "epic1" group (epic1 mode): the Epicbox server ([server]: today's picker with its state
/// line, the server named in this wallet's links) and the printed codes.
class Epic1SettingsGroup extends ConsumerStatefulWidget {
  const Epic1SettingsGroup({super.key, required this.server, required this.serverHint});

  final Widget server;
  final String serverHint;

  @override
  ConsumerState<Epic1SettingsGroup> createState() => _Epic1SettingsGroupState();
}

class _Epic1SettingsGroupState extends ConsumerState<Epic1SettingsGroup> {
  Future<List<Epic1LinkSlot>>? _printed;

  Future<List<Epic1LinkSlot>> _load(Epic1Wallet e1) async => [
    for (final s in await e1.links())
      if (s.kind == Epic1LinkKind.printed) s,
  ];

  Future<void> _open(Epic1Wallet e1) async {
    await showEDrawer<void>(context, builder: (_) => PrintedCodesPanel(epic1: e1));
    if (mounted) setState(() => _printed = _load(e1));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e1 = ref.watch(deskApiProvider).epic1;
    if (e1 == null) return const SizedBox.shrink();
    _printed ??= _load(e1);
    return ESetGroup(
      key: const ValueKey('e1-group'),
      title: l.deskE1SetGroup,
      rows: [
        ESetRow(
          anchor: SetId.epicboxServer,
          title: l.deskSetRecvEpicboxServer,
          hint: widget.serverHint,
          hintTitle: l.deskSetRecvEpicboxServer,
          below: widget.server,
        ),
        FutureBuilder<List<Epic1LinkSlot>>(
          future: _printed,
          builder: (context, snap) => ESetRow(
            key: const ValueKey('e1-printed'),
            title: l.deskE1PrintedCodes,
            hint: l.deskE1PrintedHint,
            hintTitle: l.deskE1PrintedCodes,
            wrap: true,
            control: EButton(
              key: const ValueKey('e1-printed-open'),
              label: snap.hasData ? l.deskE1PrintedCount(snap.data!.length) : l.deskE1PrintedCodes,
              icon: EIcons.chevronRight,
              kind: EBtnKind.ghost,
              size: EBtnSize.sm,
              busy: !snap.hasData && !snap.hasError,
              onPressed: () => _open(e1),
            ),
          ),
        ),
      ],
    );
  }
}

/// The printed link codes in use, each with Retire (asked first).
class PrintedCodesPanel extends StatefulWidget {
  const PrintedCodesPanel({super.key, required this.epic1});

  final Epic1Wallet epic1;

  @override
  State<PrintedCodesPanel> createState() => _PrintedCodesPanelState();
}

class _PrintedCodesPanelState extends State<PrintedCodesPanel> {
  late Future<List<Epic1LinkSlot>> _codes = _load();
  int? _retiring;

  Future<List<Epic1LinkSlot>> _load() async => [
    for (final s in await widget.epic1.links())
      if (s.kind == Epic1LinkKind.printed) s,
  ];

  Future<void> _retire(Epic1LinkSlot s) async {
    final l = context.l10n;
    final shown = s.n + 1;
    final sure = await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        key: const ValueKey('e1-retire-dialog'),
        title: l.deskE1RetireAsk(shown),
        icon: EIcons.alert,
        tone: ETone.warn,
        actions: [
          EButton(label: l.deskE1Keep, onPressed: () => Navigator.pop(ctx, false)),
          EButton(key: const ValueKey('e1-retire-yes'), kind: EBtnKind.danger, label: l.deskE1Retire, onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _retiring = s.n);
    try {
      await widget.epic1.retireLink(s.n);
    } on Object catch (e) {
      if (mounted) showEToast(context, deskErrorText(e, l), tone: ETone.risk);
    }
    if (mounted) {
      setState(() {
        _retiring = null;
        _codes = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    return EDrawer(
      key: const ValueKey('e1-printed-panel'),
      title: l.deskE1PrintedCodes,
      body: FutureBuilder<List<Epic1LinkSlot>>(
        future: _codes,
        builder: (context, snap) {
          if (snap.hasError) return EEmpty(icon: EIcons.alert, title: deskErrorText(snap.error!, l));
          final codes = snap.data;
          if (codes == null) return Center(child: ESpinner(size: 24.u));
          if (codes.isEmpty) return EEmpty(icon: EIcons.qr, title: l.deskE1PrintedNone);
          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: Sp.x3),
            itemCount: codes.length,
            separatorBuilder: (_, _) => Divider(height: 1, thickness: 1, color: c.line),
            itemBuilder: (context, i) {
              final s = codes[i];
              return Padding(
                key: ValueKey('e1-code-${s.n}'),
                padding: EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x3),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.deskE1CodeN(s.n + 1), style: ts.strong),
                          Text(
                            s.usedAt == null ? l.deskE1CodeIssued(shortDay(l, s.issuedAt)) : l.deskE1CodeUsed(shortDay(l, s.usedAt!)),
                            style: ts.small.copyWith(color: c.dim),
                          ),
                        ],
                      ),
                    ),
                    EButton(
                      key: ValueKey('e1-retire-${s.n}'),
                      label: l.deskE1Retire,
                      size: EBtnSize.sm,
                      busy: _retiring == s.n,
                      onPressed: _retiring != null ? null : () => _retire(s),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
