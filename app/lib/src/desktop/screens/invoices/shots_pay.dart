// SPDX-License-Identifier: Apache-2.0
import '../../data/mock_hosts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/shots.dart';
import '../../data/invoice_state.dart';
import '../../data/mock_wallet.dart';
import '../../data/state.dart';
import 'pay_dialogs.dart';

/// Screenshot tour entries of the invoice screens' pay part (see shots.dart beside this file):
/// the payer's inbox, Review, the dialogs, and the states after paying.

MockDeskWallet _mock(ProviderContainer c) => c.read(deskApiProvider) as MockDeskWallet;
InvoiceProto _proto(ProviderContainer c) => _mock(c).proto;

/// Reads the book and the wallet again after the prototype moved, so the screens show it.
Future<void> _reload(ProviderContainer c) async {
  await c.read(deskInvoicesProvider.notifier).load();
  await c.read(deskProvider.notifier).refresh();
}

Future<InvoiceBook> _book(ProviderContainer c) => _mock(c).invoices();

/// The waiting invoice from [label], or the newest waiting one.
Future<IncomingInvoice> _waiting(ProviderContainer c, {String? label}) async {
  final w = (await _book(c)).waiting;
  return label == null ? w.last : w.firstWhere((i) => i.label == label);
}

Future<void> _pay(ProviderContainer c, IncomingInvoice i) => _mock(c).payInvoice(i.slateId, amount: i.amount, password: 'x');

Future<void> _review(ProviderContainer c, IncomingInvoice i) async {
  await _reload(c);
  c.read(deskNavProvider.notifier).go(DeskRoute.invoiceReview, i.slateId);
}

Future<void> _coffee(ProviderContainer c) async => _review(c, await _waiting(c, label: 'Merchant: Coffee'));
Future<void> _openCoffee(ProviderContainer c, BuildContext _) => _coffee(c);

/// Both waiting invoices paid, so a payment can be withdrawn or run past its time.
Future<void> _payBoth(ProviderContainer c) async {
  for (final i in (await _book(c)).waiting) {
    await _pay(c, i);
  }
}

/// The book the screens show (loaded by then): dialogs read it without an async gap.
IncomingInvoice _shown(BuildContext ctx, bool Function(IncomingInvoice) test) =>
    ProviderScope.containerOf(ctx, listen: false).read(deskInvoicesProvider)!.toPay.firstWhere(test);

bool _coffeeWaiting(IncomingInvoice i) => i.label == 'Merchant: Coffee' && i.state == PayState.waiting;

/// Paid Coffee 12.5, run past its time (25 h): Not on chain, offered for cancel.
Future<void> _pastTtl(ProviderContainer c) async {
  await _pay(c, await _waiting(c, label: 'Merchant: Coffee'));
  _proto(c).advance(const Duration(hours: 25));
  await _reload(c);
}

Future<void> _withRoute(ProviderContainer c, Future<void> Function() f) async {
  await f();
  await _reload(c);
  c.read(deskNavProvider.notifier).go(DeskRoute.invoices, InvoicesTab.pay);
}

DeskShot _inbox(String id, double w, double h) => DeskShot(id: id, title: 'Invoices › Pay: 2 waiting, ignored senders', route: DeskRoute.invoices, arg: InvoicesTab.pay, width: w, height: h);

DeskShot _reviewShot(String id, double w, double h) => DeskShot(id: id, title: 'Review invoice', route: DeskRoute.invoices, prepare: _openCoffee, width: w, height: h);

final List<DeskShot> invoicePayShots = [
  _inbox('inv-pay-01-inbox', 1280, 800),
  _inbox('inv-pay-01-inbox-1920', 1920, 1080),
  _inbox('inv-pay-01-inbox-900', 900, 760),
  DeskShot(
    id: 'inv-pay-02-inbox-empty',
    title: 'Invoices › Pay: nothing waiting',
    route: DeskRoute.invoices,
    arg: InvoicesTab.pay,
    prepare: (c, _) => _withRoute(c, () async {
      for (final i in (await _book(c)).waiting) {
        await _mock(c).declineInvoice(i.slateId);
      }
    }),
  ),
  _reviewShot('inv-pay-03-review', 1280, 800),
  _reviewShot('inv-pay-03-review-1920', 1920, 1080),
  _reviewShot('inv-pay-03-review-900', 900, 760),
  DeskShot(
    id: 'inv-pay-04-review-same-bill',
    title: 'Review: the same bill again',
    route: DeskRoute.invoices,
    prepare: (c, _) async {
      _proto(c).billArrives(same: true);
      await _review(c, await _waiting(c));
    },
  ),
  // Not enough spendable funds: the prototype has no way to lower the balance below an
  // invoice's total (no proto action), so that state has no shot.
  DeskShot(
    id: 'inv-pay-06-review-node-down',
    title: 'Review: node not answering',
    route: DeskRoute.invoices,
    prepare: (c, ctx) async {
      _proto(c).setNet(ProtoNet.nodeDown);
      // The mock's status reads the chosen node's health; a node that is down stands in for it.
      await _mock(c).useNode(mockNodeAt(0));
      await _coffee(c);
    },
  ),
  DeskShot(
    id: 'inv-pay-07-review-expired',
    title: 'Review: expired while open',
    route: DeskRoute.invoices,
    prepare: (c, ctx) async {
      final i = await _waiting(c, label: 'Merchant: Coffee');
      _proto(c).advance(const Duration(hours: 4));
      await _review(c, i);
    },
  ),
  DeskShot(
    id: 'inv-pay-08-review-withdrawn',
    title: 'Review: read-only, the service withdrew it',
    route: DeskRoute.invoices,
    prepare: (c, ctx) async {
      final i = await _waiting(c, label: 'Northwind Exchange');
      _proto(c).serviceWithdraws();
      await _review(c, i);
    },
  ),
  DeskShot(
    id: 'inv-pay-09-approve',
    title: 'Approve: amount, fee, password',
    route: DeskRoute.invoices,
    prepare: _openCoffee,
    dialog: (ctx) => showApproveInvoice(ctx, _shown(ctx, _coffeeWaiting)),
  ),
  DeskShot(
    id: 'inv-pay-10-approve-wrong-password',
    title: 'Approve: wrong password',
    route: DeskRoute.invoices,
    prepare: _openCoffee,
    dialog: (ctx) => showApproveInvoice(ctx, _shown(ctx, _coffeeWaiting), shotPassword: 'wrong'),
  ),
  DeskShot(
    id: 'inv-pay-11-not-delivered',
    title: 'Not delivered: Retry, no second approval',
    route: DeskRoute.invoices,
    arg: InvoicesTab.pay,
    prepare: (c, _) => _withRoute(c, () async => _proto(c).closedAfterApprove()),
  ),

  DeskShot(
    id: 'inv-pay-13-withdrawn-after-pay',
    title: 'Withdrawn after paying: Cancel payment offered',
    route: DeskRoute.invoices,
    arg: InvoicesTab.pay,
    prepare: (c, _) => _withRoute(c, () async {
      await _payBoth(c);
      _proto(c).serviceWithdraws();
    }),
  ),
  DeskShot(
    id: 'inv-pay-14-past-ttl',
    title: 'Not on chain after its time: Cancel payment offered',
    route: DeskRoute.invoices,
    arg: InvoicesTab.pay,
    prepare: (c, _) => _withRoute(c, () => _pastTtl(c)),
  ),
  DeskShot(
    id: 'inv-pay-15-cancel-dialog',
    title: 'Cancel payment: what cancelling does',
    route: DeskRoute.invoices,
    arg: InvoicesTab.pay,
    prepare: (c, _) => _withRoute(c, () => _pastTtl(c)),
    dialog: (ctx) => showCancelPaymentDialog(ctx, _shown(ctx, (i) => i.state == PayState.pastTtl)),
  ),
  DeskShot(
    id: 'inv-pay-16-cancel-cannot-check',
    title: 'Cancel payment: node not answering',
    route: DeskRoute.invoices,
    arg: InvoicesTab.pay,
    prepare: (c, _) => _withRoute(c, () async {
      await _pastTtl(c);
      _proto(c).setNet(ProtoNet.nodeDown);
    }),
    dialog: (ctx) => showCancelPaymentDialog(ctx, _shown(ctx, (i) => i.state == PayState.pastTtl), shotConfirm: true),
  ),

];
