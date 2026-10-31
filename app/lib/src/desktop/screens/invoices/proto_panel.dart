// SPDX-License-Identifier: Apache-2.0
/// The clickable prototype's control panel (mock wallet only): plays the other side of every
/// invoice, the network, the chain and the clock, so each state of the invoice flow can be
/// reached by hand. Not product UI: its words stay English and it never ships with LEPIC.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/invoice_state.dart';
import '../../data/mock_wallet.dart';
import '../../widgets/kit.dart';
import 'invoice_parts.dart';

/// The floating "Prototype" button, bottom right, when the wallet is the mock.
class ProtoButton extends ConsumerWidget {
  const ProtoButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(deskApiProvider) is! MockDeskWallet) return const SizedBox.shrink();
    return Positioned(
      right: Sp.x5,
      bottom: Sp.x5,
      child: ETip(
        'Play the other side: payer, service, Epicbox, node, chain, clock',
        child: InvButton(
          label: 'Prototype',
          icon: EIcons.prototype,
          kind: EBtnKind.secondary,
          width: InvW.sm,
          onPressed: () => showEDrawer<void>(context, builder: (_) => const _ProtoPanel()),
        ),
      ),
    );
  }
}

class _ProtoPanel extends ConsumerStatefulWidget {
  const _ProtoPanel();

  @override
  ConsumerState<_ProtoPanel> createState() => _ProtoPanelState();
}

class _ProtoPanelState extends ConsumerState<_ProtoPanel> {
  InvoiceProto get _p => (ref.read(deskApiProvider) as MockDeskWallet).proto;

  void _do(String done, void Function(InvoiceProto p) act) {
    act(_p);
    setState(() {});
    ref.read(deskProvider.notifier).refresh();
    ref.read(deskInvoicesProvider.notifier).load();
    showEToast(context, done, tone: ETone.neutral);
  }

  Widget _group(String title, List<(String, String, void Function(InvoiceProto))> actions) {
    final ts = context.ts;
    return Padding(
      padding: EdgeInsets.only(bottom: Sp.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: ts.label),
          SizedBox(height: Sp.x2),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [for (final (label, done, act) in actions) InvButton(label: label, width: InvW.md, onPressed: () => _do(done, act))],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final p = _p;
    final s = ref.watch(deskProvider.select((s) => s.settings));
    final n = ref.read(deskProvider.notifier);
    return EDrawer(
      title: 'Prototype',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Sp.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Plays the other side of each invoice. Mock data only; any password but "wrong" unlocks and pays.', style: ts.bodyDim),
            SizedBox(height: Sp.x5),
            Text('Network', style: ts.label),
            SizedBox(height: Sp.x2),
            ESegmented<ProtoNet>(
              value: p.net,
              onChanged: (v) => _do('Network: ${v.name}', (p) => p.setNet(v)),
              segments: const [ESegment(ProtoNet.online, 'Online'), ESegment(ProtoNet.relayDown, 'Epicbox down'), ESegment(ProtoNet.nodeDown, 'Node down')],
            ),
            SizedBox(height: Sp.x5),
            _group('Invoices you issued: the payer', [
              ('Payer pays', 'The payer paid the oldest waiting invoice.', (p) => p.payerPays()),
              ('Payer declines', 'The payer declined the oldest waiting invoice.', (p) => p.payerDeclines()),
              ('Sends it back', 'A stock wallet sent the oldest waiting invoice back.', (p) => p.payerBounces()),
              ('Late payment', 'A payment for an ended invoice arrived and was refused.', (p) => p.lateReply()),
            ]),
            _group('Invoices to pay: a service', [
              ('New invoice', 'Coffee Roasters billed you.', (p) => p.billArrives()),
              ('Same bill again', 'The last paid bill arrived again.', (p) => p.billArrives(same: true)),
              ('Service withdraws', 'The service withdrew an invoice.', (p) => p.serviceWithdraws()),
              ('Service posts', 'The service posted your payment.', (p) => p.servicePosts()),
            ]),
            _group('Chain and clock', [
              ('Mine 1 block', 'One block mined.', (p) => p.blocks(1)),
              ('Mine 3 blocks', 'Three blocks mined.', (p) => p.blocks(3)),
              ('+1 hour', 'The clock moved 1 hour.', (p) => p.advance(const Duration(hours: 1))),
              ('+25 hours', 'The clock moved 25 hours: expiries run.', (p) => p.advance(const Duration(hours: 25))),
            ]),
            _group('Restart mid-flow', [
              ('Closed after Approve', 'The app closed after Approve: the oldest invoice is signed, not delivered.', (p) => p.closedAfterApprove()),
              ('Reset everything', 'Back to the start.', (p) => p.reset()),
            ]),
            Text('Look', style: ts.label),
            SizedBox(height: Sp.x2),
            Wrap(
              spacing: Sp.x2,
              runSpacing: Sp.x2,
              children: [
                SizedBox(
                  width: InvW.md,
                  child: ESelect<ThemeChoice>(
                    semanticLabel: 'Theme',
                    value: s.theme == ThemeChoice.light ? ThemeChoice.light : ThemeChoice.dark,
                    items: const [ESelectItem(ThemeChoice.dark, 'Dark'), ESelectItem(ThemeChoice.light, 'Light')],
                    onChanged: (v) => n.saveSettings(s.copyWith(theme: v)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
