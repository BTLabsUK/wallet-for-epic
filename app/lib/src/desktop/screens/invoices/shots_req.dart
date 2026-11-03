// SPDX-License-Identifier: Apache-2.0
import '../../data/mock_hosts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shots.dart';
import '../../data/invoice_state.dart';
import '../../data/mock_wallet.dart';
import '../../widgets/kit.dart';

InvoiceProto _proto(ProviderContainer c) => (c.read(deskApiProvider) as MockDeskWallet).proto;

Contact _contact(ProviderContainer c, String id) => c.read(deskProvider).contacts!.firstWhere((x) => x.id == id);

/// A shot of Requests › Sent after [act] moved the other side.
DeskShot _sent(String id, String title, void Function(InvoiceProto p) act, {double width = 1280, double height = 800}) => DeskShot(
  id: id,
  title: title,
  route: DeskRoute.invoices,
  arg: InvoicesTab.issue,
  width: width,
  height: height,
  prepare: (c, _) async => act(_proto(c)),
);

/// Screenshot tour entries of the issuer part (see shots.dart).
final List<DeskShot> invoiceReqShots = [
  const DeskShot(id: 'inv-req-01-form', title: 'Issue an invoice: the form, empty', route: DeskRoute.invoiceIssue),
  const DeskShot(id: 'inv-req-01b-form-1920', title: 'Issue an invoice at 1920', route: DeskRoute.invoiceIssue, width: 1920, height: 1080),
  const DeskShot(id: 'inv-req-01c-form-900', title: 'Issue an invoice at 900 (rail)', route: DeskRoute.invoiceIssue, width: 900, height: 900),
  DeskShot(
    id: 'inv-req-02-form-contact',
    title: 'Issue to a contact (LEPIC wallet: no hint)',
    route: DeskRoute.invoiceIssue,
    prepare: (c, _) async => c.read(deskNavProvider.notifier).reset(DeskRoute.invoiceIssue, _contact(c, 'c6')),
  ),
  DeskShot(
    id: 'inv-req-03-form-unknown',
    title: 'Issue to an address nothing is known of',
    route: DeskRoute.invoiceIssue,
    prepare: (c, _) async =>
        c.read(deskNavProvider.notifier).reset(DeskRoute.invoiceIssue, 'esTk7uLfB3hJd9gA4sXeR6pTnC1vK8xHwP2bZr8mQ2pVtW5kNcY@$mockBox'),
  ),
  DeskShot(
    id: 'inv-req-04-form-no-invoices',
    title: 'Issue to a wallet that sent one back before',
    route: DeskRoute.invoiceIssue,
    prepare: (c, _) async => c.read(deskNavProvider.notifier).reset(DeskRoute.invoiceIssue, _contact(c, 'c7')),
  ),
  const DeskShot(
    id: 'inv-req-06-form-http',
    title: 'Issue form: HTTP address refused on Epicbox',
    route: DeskRoute.invoiceIssue,
    arg: 'http://192.168.1.24:3415',
  ),
  DeskShot(
    id: 'inv-req-07-form-relay-down',
    title: 'Issue form: Epicbox down, Issue disabled',
    route: DeskRoute.invoiceIssue,
    prepare: (c, _) async {
      _proto(c).setNet(ProtoNet.relayDown);
      await c.read(deskInvoicesProvider.notifier).load();
    },
  ),
  _sent('inv-req-10-sent', 'Invoices › Issue: waiting, confirming, expired', (_) {}),
  _sent('inv-req-10b-sent-1920', 'Invoices › Issue at 1920', (_) {}, width: 1920, height: 1080),
  _sent('inv-req-10c-sent-900', 'Invoices › Issue at 900 (rail)', (_) {}, width: 900, height: 900),
  _sent('inv-req-11-paid', 'Invoices › Issue: the payer paid, finalizing', (p) => p.payerPays()),
  _sent('inv-req-12-not-posted', 'Invoices › Issue: paid, not posted (node down): Repost', (p) {
    p.setNet(ProtoNet.nodeDown);
    p.payerPays();
  }),
  _sent('inv-req-13-completed', 'Invoices › Issue: completed after 6 confirmations', (p) {
    p.payerPays();
    p.blocks(6);
  }),
  _sent('inv-req-14-declined', 'Invoices › Issue: the payer declined', (p) => p.payerDeclines()),
  _sent('inv-req-15-bounced', 'Invoices › Issue: the payer\'s wallet sent it back', (p) => p.payerBounces()),
  _sent('inv-req-17-cancelled', 'Invoices › Issue: paid, never posted, cancelled (Advanced)', (p) {
    p.setNet(ProtoNet.nodeDown);
    p.payerPays();
    p.withdraw(p.sent.first.slateId);
  }),
  _sent('inv-req-16-withdrawn-late', 'Invoices › Issue: withdrawn, a late payment refused', (p) {
    p.withdraw(p.sent.first.slateId);
    p.lateReply();
  }),
];
