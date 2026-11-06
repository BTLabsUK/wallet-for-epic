// SPDX-License-Identifier: Apache-2.0
import '../../data/mock_hosts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shots.dart';
import '../../data/invoice_state.dart';
import '../../../models.dart' show PairingState;
import '../../../sas_table.dart';
import '../../data/mock_wallet.dart';
import '../../data/pairing_state.dart' show deskPairRequestsProvider, deskPairingsProvider;
import '../pairing/pair_screens.dart' show DeskPairedSaveDialog, showDeskCheckWordsFor;
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
  // The other side removed the pairing: Removed by Anna in the header, Pair again beside Send.
  DeskShot(
    id: 'inv-set-07b-contact-removed',
    title: 'Contact: the other side removed the pairing',
    route: DeskRoute.contacts,
    arg: const ContactsArgs(selectedId: 'c1'),
    prepare: (c, _) async {
      (c.read(deskApiProvider) as MockDeskWallet).pairing.removedByPeer(mockAnnaPairing);
      c.invalidate(deskPairingsProvider);
    },
  ),
  const DeskShot(id: 'inv-set-07-contact-keys-changed', title: 'Contact: keys changed', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c9')),
  const DeskShot(id: 'inv-set-08-contact-exchange', title: 'Contact: an exchange, invoices allowed', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c8')),
  const DeskShot(id: 'pair-01-pair', title: 'Contacts › Pair: Your invite and Have their invite?', route: DeskRoute.pair),
  DeskShot(
    id: 'pair-02-contact-waiting',
    title: 'Contact: a request sent, waiting',
    route: DeskRoute.contacts,
    prepare: (c, _) async {
      final p = (c.read(deskApiProvider) as MockDeskWallet).pairing..clock = DateTime.now;
      final tom = (c.read(deskProvider).contacts ?? const <Contact>[]).where((x) => x.name == 'BT Labs').firstOrNull;
      if (tom?.epicbox case final a?) {
        p.provenPeers.add(a);
        await p.requestPairing(toAddress: a, name: 'Alex', contactId: tom!.id);
      }
      c.invalidate(deskPairingsProvider);
    },
    arg: const ContactsArgs(selectedId: 'c2'),
  ),
  DeskShot(
    id: 'pair-06-contact-ended',
    title: 'Contact: the pairing ended, the other side reported the words do not match',
    route: DeskRoute.contacts,
    arg: const ContactsArgs(selectedId: 'c1'),
    prepare: (c, _) async {
      (c.read(deskApiProvider) as MockDeskWallet).pairing.peerMismatch(mockAnnaPairing);
      c.invalidate(deskPairingsProvider);
    },
  ),
  DeskShot(
    id: 'pair-07-requests',
    title: 'Contacts › Pair requests: a request from a contact',
    route: DeskRoute.contacts,
    prepare: (c, _) async {
      final p = (c.read(deskApiProvider) as MockDeskWallet).pairing..clock = DateTime.now;
      final piotr = (c.read(deskProvider).contacts ?? const <Contact>[]).where((x) => x.name.startsWith('Piotr')).firstOrNull;
      if (piotr?.epicbox case final a?) p.receiveRequest(from: a, name: 'Piotr');
      c.invalidate(deskPairRequestsProvider);
    },
    dialog: (ctx) => showEDialog<void>(ctx, builder: (_) => const SizedBox.shrink()),
  ),
  // A re-pair after a restore: the result offers the contact of its name first.
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
  // The same result for an automated peer that takes no payments (profile 3).
  DeskShot(
    id: 'pair-04b-result-service',
    title: 'The words-check result of a pairing with a service: No payments, service wording',
    route: DeskRoute.pair,
    prepare: (c, _) async {
      (c.read(deskApiProvider) as MockDeskWallet).pairing.seedPaired(id: 'p-service-new', name: 'Northwind', state: PairingState.verified, peerProfile: 3);
      c.invalidate(deskPairingsProvider);
    },
    dialog: (ctx) => showEDialog<void>(ctx, builder: (_) => const DeskPairedSaveDialog(pairingId: 'p-service-new', verified: true)),
  ),
  // A contact with all three kinds of address: the list row shows their tags.
  DeskShot(
    id: 'pair-05-contacts-three-addresses',
    title: 'Contacts: a contact with Epicbox, Link · HTTP and Link · Tor addresses',
    route: DeskRoute.contacts,
    prepare: (c, _) async {
      await c.read(deskProvider.notifier).saveContact(
        Contact(
          id: '',
          name: 'Floo C',
          address: 'esFc7Wq8TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtK2s@${mockBoxAt(2)}',
          http: 'https://floo.example.net:3415',
          tor: mockOnion('mbkzvq3uyx7nqk2ahtr4oewl6jx5fdcpsy3givn2rw7bmkhq5ufk7uyd'),
        ),
      );
    },
  ),
  // The words check with the table's longest names: each one whole.
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
  const DeskShot(id: 'inv-set-03b-contact-1920', title: 'Contact at 1920', route: DeskRoute.contacts, arg: ContactsArgs(selectedId: 'c1'), width: 1920, height: 1080),
  const DeskShot(id: 'inv-set-06-receive', title: 'Receive: Issue an invoice beside the Epicbox address', route: DeskRoute.receive),
];
