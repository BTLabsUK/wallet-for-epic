import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shots.dart';
import '../../data/invoice_state.dart';
import '../../../models.dart' show PairingState;
import '../../../pairing_api.dart' show PairingLinkKind;
import '../../../pairing_fake.dart' show fakePairingLink;
import '../../../sas_table.dart';
import '../../data/mock_wallet.dart';
import '../../data/pairing_state.dart' show deskPairingsProvider;
import '../pairing/pair_screens.dart' show DeskFinishDialog, DeskPairWaitingDialog, DeskPairWay, DeskPairedSaveDialog, DeskPairingClipDialog, showDeskCheckWordsFor;
import '../../widgets/kit.dart';
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
  _settings('inv-set-01-settings', 'Settings › Invoices (own tab): paired contacts with Allow invoices'),
  _settings('inv-set-01b-settings-1920', 'Settings › Invoices at 1920', width: 1920, height: 1080),
  _settings('inv-set-01c-settings-900', 'Settings › Invoices at 900 (rail)', width: 900, height: 900),
  const DeskShot(id: 'inv-set-03-contact-verified', title: 'Contact: verified pairing, two addresses', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c1')),
  const DeskShot(id: 'inv-set-04-contact-not-paired', title: 'Contact: not paired', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c3')),
  const DeskShot(id: 'inv-set-05-contact-edit', title: 'Contact form: one address per kind', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c6', editing: true)),
  const DeskShot(id: 'inv-set-07-contact-keys-changed', title: 'Contact: keys changed', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c9')),
  const DeskShot(id: 'inv-set-08-contact-exchange', title: 'Contact: an exchange, invoices allowed', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c8')),
  const DeskShot(id: 'pair-01-pair', title: 'Contacts › Pair: the three ways, Words open, Got words or a link?', route: DeskRoute.pair),
  DeskShot(
    id: 'pair-02-pending',
    title: 'Contacts › Pending invites: a link, unnamed words, an answer waiting with Remove',
    route: DeskRoute.pairPending,
    prepare: (c, _) async {
      final p = (c.read(deskApiProvider) as MockDeskWallet).pairing..clock = DateTime.now;
      await p.makeInvite(name: 'the owner', expiry: const Duration(hours: 24), label: 'Tom');
      await p.makeInvite(name: 'the owner', expiry: const Duration(minutes: 10), words: true);
      final preview = await p.openInvite(p.inviteLinkFrom(name: 'Ola'));
      await p.acceptInvite(token: preview.token, name: 'the owner');
      c.invalidate(deskPairingsProvider);
    },
  ),
  // A re-pair after a restore: the result offers the contact of its name first (PAIR-LNX-7).
  DeskShot(
    id: 'pair-04-result-add-to',
    title: 'The words-check result of a pairing in no contact: Add to Anna Kowalska first',
    route: DeskRoute.pair,
    prepare: (c, _) async {
      (c.read(deskApiProvider) as MockDeskWallet).pairing.seedPaired(id: 'p-anna-new', name: 'Anna Kowalska', state: PairingState.verified);
      c.invalidate(deskPairingsProvider);
    },
    dialog: (ctx) => showEDialog<void>(ctx, builder: (_) => const DeskPairedSaveDialog(pairingId: 'p-anna-new', verified: true)),
  ),
  // A contact with all three kinds of address: the list row shows their tags (PAIR-WIN-2).
  DeskShot(
    id: 'pair-05-contacts-three-addresses',
    title: 'Contacts: a contact with Epicbox, Link · HTTP and Link · Tor addresses',
    route: DeskRoute.contacts,
    prepare: (c, _) async {
      await c.read(deskProvider.notifier).saveContact(
        Contact(
          id: '',
          name: 'Floo C',
          address: 'esFc7Wq8TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtK2s@epicbox.epicnet.us',
          http: 'https://floo.example.net:3415',
          tor: 'mbkzvq3uyx7nqk2ahtr4oewl6jx5fdcpsy3givn2rw7bmkhq5ufk7uyd.onion',
        ),
      );
    },
  ),
  // The words check with the table's longest names: each one whole (acceptance F1).
  DeskShot(
    id: 'pair-03-check-words',
    title: 'The words check dialog, the longest names',
    route: DeskRoute.pair,
    prepare: (c, _) async {
      final longest = ([...sasTable]..sort((a, b) => b.name.length.compareTo(a.name.length))).take(4).toList();
      (c.read(deskApiProvider) as MockDeskWallet).pairing.seedPaired(id: 'p-long-words', name: 'Northwind', state: PairingState.paired, sas: longest);
      c.invalidate(deskPairingsProvider);
    },
    dialog: (ctx) => showDeskCheckWordsFor(ctx, 'p-long-words'),
  ),
  // Pairing UX (26.10.18): the ways as tiles, the message way's steps on both sides, the
  // clipboard offer, and Contacts while nobody is paired.
  const DeskShot(id: 'pair-06-message', title: 'Contacts › Pair: Invite by message, step 1', route: DeskRoute.pair, arg: DeskPairWay.message),
  const DeskShot(id: 'pair-07-in-person', title: 'Contacts › Pair: In person, the code for their phone', route: DeskRoute.pair, arg: DeskPairWay.inPerson),
  DeskShot(
    id: 'pair-08-finish',
    title: 'Invite by message, step 3: the finish link to copy',
    route: DeskRoute.pair,
    arg: DeskPairWay.message,
    prepare: (c, _) async {
      final p = (c.read(deskApiProvider) as MockDeskWallet).pairing..clock = DateTime.now;
      final invite = await p.makeInvite(name: 'the owner', expiry: const Duration(hours: 24), label: 'Anna');
      await p.openReply(fakePairingLink('pair-reply', {'t': invite.id, 'n': 'Anna'}));
      c.invalidate(deskPairingsProvider);
    },
    dialog: (ctx) async {
      final p = (ProviderScope.containerOf(ctx).read(deskApiProvider) as MockDeskWallet).pairing;
      final id = p.records.firstWhere((r) => r.inviter && r.state == PairingState.paired && r.label == 'Anna').id;
      final link = await p.confirmLink(id);
      if (ctx.mounted) await showEDialog<bool>(ctx, builder: (_) => DeskFinishDialog(pairingId: id, link: link));
    },
  ),
  DeskShot(
    id: 'pair-09-reply',
    title: 'The joiner by message, step 2: the reply to copy',
    route: DeskRoute.pair,
    prepare: (c, _) async {
      final p = (c.read(deskApiProvider) as MockDeskWallet).pairing..clock = DateTime.now;
      final preview = await p.openInvite(p.inviteLinkFrom(name: 'Anna'));
      await p.acceptInvite(token: preview.token, name: 'the owner');
      c.invalidate(deskPairingsProvider);
    },
    dialog: (ctx) async {
      final p = (ProviderScope.containerOf(ctx).read(deskApiProvider) as MockDeskWallet).pairing;
      final id = p.records.firstWhere((r) => r.state == PairingState.pendingReply).id;
      await showEDialog<void>(ctx, dismissible: false, builder: (_) => DeskPairWaitingDialog(pairingId: id, byMessage: true));
    },
  ),
  DeskShot(
    id: 'pair-10-clipboard',
    title: 'A pairing link found on the clipboard',
    route: DeskRoute.contacts,
    dialog: (ctx) => showEDialog<bool>(ctx, builder: (_) => const DeskPairingClipDialog(kind: PairingLinkKind.invite, name: 'Anna')),
  ),
  DeskShot(
    id: 'pair-11-contacts-hint',
    title: 'Contacts while nobody is paired: Pair in the header, the hint, Pairing… on BT Labs',
    route: DeskRoute.contacts,
    prepare: (c, _) async {
      final p = (c.read(deskApiProvider) as MockDeskWallet).pairing..clock = DateTime.now;
      p.records.clear();
      final tom = (c.read(deskProvider).contacts ?? const <Contact>[]).where((x) => x.name == 'BT Labs').firstOrNull;
      await p.makeInvite(name: 'the owner', expiry: const Duration(hours: 24), label: tom?.name, contactId: tom?.id);
      c.invalidate(deskPairingsProvider);
    },
  ),
  const DeskShot(id: 'inv-set-03b-contact-1920', title: 'Contact at 1920', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c1'), width: 1920, height: 1080),
  const DeskShot(id: 'inv-set-06-receive', title: 'Receive: Issue an invoice beside the Epicbox address', route: DeskRoute.receive),
];
