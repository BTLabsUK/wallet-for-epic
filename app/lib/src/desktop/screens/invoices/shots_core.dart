import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shots.dart';
import '../../data/invoice_state.dart';
import '../../data/mock_wallet.dart';
import '../../widgets/kit.dart';
import '../settings/settings_invoices.dart' show TrustSenderDialog;
import '../wallet/contacts_screen.dart' show ContactsArgs;

InvoiceProto _proto(ProviderContainer c) => (c.read(deskApiProvider) as MockDeskWallet).proto;

/// Settings › Invoices, its own tab.
DeskShot _settings(String id, String title, {double width = 1280, double height = 900, Future<void> Function(BuildContext)? dialog}) => DeskShot(
  id: id,
  title: title,
  route: DeskRoute.settingsInvoices,
  width: width,
  height: height,
  dialog: dialog,
);

/// Screenshot tour entries of the Invoices page's frame, Activity, Overview and the edge states.
final List<DeskShot> invoiceCoreShots = [
  // The Invoices page: Epicbox is down, the lists stay.
  DeskShot(
    id: 'inv-core-01-relay-down',
    title: 'Invoices: Epicbox not answering, lists kept',
    route: DeskRoute.invoices,
    prepare: (c, _) async {
      _proto(c).setNet(ProtoNet.relayDown);
      await c.read(deskInvoicesProvider.notifier).check(quiet: true);
    },
  ),
  DeskShot(
    id: 'inv-core-02-restart-mid-flow',
    title: 'Invoices › Pay after a restart mid-pay: Not delivered, Retry',
    route: DeskRoute.invoices,
    arg: InvoicesTab.pay,
    prepare: (c, _) async {
      _proto(c).closedAfterApprove();
      await c.read(deskInvoicesProvider.notifier).load();
    },
  ),
  // Double pay prevented: a paid invoice opens read-only, with nothing to approve.
  const DeskShot(
    id: 'inv-core-03-double-pay',
    title: 'Review of an invoice already paid: read-only, no second payment',
    route: DeskRoute.invoiceReview,
    arg: 'c3d4e5f6-0718-4293-a4b5-c6d7e8f90a1b',
  ),
];

/// Activity and Overview.
final List<DeskShot> invoiceActShotsCore = [
  const DeskShot(id: 'inv-act-01-activity', title: 'Activity with issued and paid invoice rows', route: DeskRoute.activity),
  const DeskShot(id: 'inv-act-01b-activity-1920', title: 'Activity at 1920', route: DeskRoute.activity, width: 1920, height: 1080),
  const DeskShot(id: 'inv-act-02-detail-request-waiting', title: 'Activity detail: an issued invoice, unpaid (neutral amount)', route: DeskRoute.activity, arg: 141),
  const DeskShot(id: 'inv-act-03-detail-request-confirming', title: 'Activity detail: an issued invoice paid, confirming', route: DeskRoute.activity, arg: 39),
  const DeskShot(id: 'inv-act-04-detail-invoice-posted', title: 'Activity detail: a paid invoice, posted by the service', route: DeskRoute.activity, arg: 37),
  const DeskShot(id: 'inv-act-05-detail-request-expired', title: 'Activity detail: an issued invoice that ended unpaid', route: DeskRoute.activity, arg: 142),
  const DeskShot(id: 'inv-act-05b-detail-narrow', title: 'Activity detail at 900 (rail)', route: DeskRoute.activity, arg: 141, width: 900, height: 760),
  const DeskShot(id: 'inv-act-06-overview', title: 'Overview with the Invoices card', route: DeskRoute.overview),
  DeskShot(
    id: 'inv-act-07-overview-attention',
    title: 'Overview: a payment needs Retry',
    route: DeskRoute.overview,
    prepare: (c, _) async {
      _proto(c).closedAfterApprove();
      await c.read(deskInvoicesProvider.notifier).load();
    },
  ),
  const DeskShot(id: 'inv-act-07b-overview-1920', title: 'Overview at 1920', route: DeskRoute.overview, width: 1920, height: 1080),
];

/// Settings › Invoices, Contacts and Receive.
final List<DeskShot> invoiceSetShotsCore = [
  _settings('inv-set-01-settings', 'Settings › Invoices (own tab): invoice address, trusted senders'),
  _settings('inv-set-01b-settings-1920', 'Settings › Invoices at 1920', width: 1920, height: 1080),
  _settings('inv-set-01c-settings-900', 'Settings › Invoices at 900 (rail)', width: 900, height: 900),
  _settings(
    'inv-set-02-trust-dialog-error',
    'Trust a sender: address refused',
    dialog: (ctx) => showEDialog<void>(ctx, builder: (_) => const TrustSenderDialog(name: 'Bike shop', address: 'http://shop.example', submitted: true)),
  ),
  const DeskShot(id: 'inv-set-03-contact-trusted', title: 'Contact: trusted for invoices, with invoice address', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c1')),
  const DeskShot(id: 'inv-set-04-contact-no-invoice', title: 'Contact without invoice address: Issue an invoice disabled', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c3')),
  const DeskShot(id: 'inv-set-05-contact-edit', title: 'Contact form with their invoice address', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c6', editing: true)),
  const DeskShot(id: 'inv-set-03b-contact-1920', title: 'Contact at 1920', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c1'), width: 1920, height: 1080),
  const DeskShot(id: 'inv-set-06-receive', title: 'Receive: Issue an invoice beside the Epicbox address', route: DeskRoute.receive),
];
