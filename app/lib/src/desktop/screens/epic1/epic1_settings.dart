// SPDX-License-Identifier: Apache-2.0
/// Settings › Payments for epic1: the epic1 row among the payment methods and the printed
/// codes under it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../epic1.dart';
import '../../../ui/theme/epic1_mark.dart' show Epic1Glyph;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../settings/setting_ids.dart';
import '../wallet/tx_display.dart' show shortDay;

/// The "epic1" row of Settings › Payments › Payment methods, right after Epicbox: the epic1
/// glyph, the name, its hint and the switch ([PaymentPrefs.epic1]). It is built like the
/// method rows and applies at once. Nothing shows when the wallet has no epic1 payments.
class Epic1MethodRow extends ConsumerWidget {
  const Epic1MethodRow({super.key, required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    if (ref.watch(deskApiProvider).epic1 == null) return const SizedBox.shrink();
    return ESetRow(
      key: const ValueKey('st-method-epic1'),
      anchor: SetId.epic1Payments,
      leadingWidget: Epic1Glyph(size: 18.u, columns: 5, color: c.dim),
      title: l.deskE1SetSwitch,
      hint: l.deskE1SetInfo,
      hintTitle: l.deskE1SetSwitch,
      control: SizedBox(
        width: 40.u,
        height: 24.u,
        child: ESwitch(
          key: const ValueKey('st-offer-epic1'),
          value: on,
          semanticLabel: l.deskE1SetSwitch,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// The printed codes row, directly under the epic1 row while epic1 is on: opens the list of
/// printed link codes with Retire.
class Epic1PrintedRow extends ConsumerStatefulWidget {
  const Epic1PrintedRow({super.key});

  @override
  ConsumerState<Epic1PrintedRow> createState() => _Epic1PrintedRowState();
}

class _Epic1PrintedRowState extends ConsumerState<Epic1PrintedRow> {
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
    if (e1 == null || !ref.watch(deskEpic1OnProvider)) return const SizedBox.shrink();
    _printed ??= _load(e1);
    return FutureBuilder<List<Epic1LinkSlot>>(
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
