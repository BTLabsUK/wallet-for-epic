import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shots.dart';
import '../../widgets/kit.dart';
import 'activity_screen.dart';
import 'contacts_screen.dart';
import 'overview_screen.dart';
import 'tx_detail.dart';

Tx _tx(BuildContext context, int id) {
  final container = ProviderScope.containerOf(context);
  return container.read(deskProvider).txs!.firstWhere((t) => t.id == id);
}

/// Screenshot tour entries of this group (see app/shots.dart). Ids match the Electron
/// reference shots.
final List<DeskShot> walletShots = [
  const DeskShot(id: '10-overview', title: 'Overview', route: DeskRoute.overview),
  DeskShot(id: '10-overview-narrow', title: 'Overview at 1000x700', route: DeskRoute.overview, width: 1000, height: 700),
  const DeskShot(id: '10b-overview-empty', title: 'Overview, new wallet', route: DeskRoute.overview, arg: OverviewDemo.empty),
  const DeskShot(id: '10c-overview-node-down', title: 'Overview, node down', route: DeskRoute.overview, arg: OverviewDemo.nodeDown),
  const DeskShot(id: '10d-overview-loading', title: 'Overview, loading', route: DeskRoute.overview, arg: OverviewDemo.loading),
  const DeskShot(id: '10e-overview-starting', title: 'Overview, just unlocked', route: DeskRoute.overview, arg: OverviewDemo.starting),
  const DeskShot(id: '10f-overview-syncing', title: 'Overview, node syncing', route: DeskRoute.overview, arg: OverviewDemo.syncing),
  const DeskShot(id: '10g-overview-node-problem', title: 'Overview, node problem', route: DeskRoute.overview, arg: OverviewDemo.nodeProblem),
  const DeskShot(id: '11-activity', title: 'Activity', route: DeskRoute.activity),
  const DeskShot(id: '11b-activity-empty', title: 'Activity, empty', route: DeskRoute.activity, arg: ActivityArgs(empty: true)),
  const DeskShot(id: '11d-activity-waiting', title: 'Activity, waiting for the node', route: DeskRoute.activity, arg: ActivityArgs(waitingNode: true)),
  const DeskShot(
    id: '11e-activity-outputs-empty',
    title: 'Activity, no outputs',
    route: DeskRoute.activity,
    arg: ActivityArgs(tab: ActivityTab.outputs, empty: true),
  ),
  const DeskShot(
    id: '11f-activity-search-none',
    title: 'Activity, no match',
    route: DeskRoute.activity,
    arg: ActivityArgs(query: 'zzz'),
  ),
  const DeskShot(id: '12d-tx-detail-mining', title: 'Transaction detail, mining reward', route: DeskRoute.activity, arg: 101),
  const DeskShot(
    id: '11c-activity-outputs',
    title: 'Activity, outputs',
    route: DeskRoute.activity,
    arg: ActivityArgs(tab: ActivityTab.outputs),
  ),
  const DeskShot(id: '12-tx-detail', title: 'Transaction detail', route: DeskRoute.activity, arg: 36),
  const DeskShot(id: '12b-tx-detail-file', title: 'Transaction detail, file send', route: DeskRoute.activity, arg: 38),
  DeskShot(id: '12c-tx-detail-narrow', title: 'Transaction detail, narrow', route: DeskRoute.activity, arg: 39, width: 900, height: 760),
  DeskShot(id: '35-dlg-tx-proof', title: 'Payment proof', route: DeskRoute.activity, arg: 36, dialog: (c) => showTxProofDialog(c, _tx(c, 36))),
  DeskShot(id: '35b-dlg-cancel-tx', title: 'Cancel a send', route: DeskRoute.activity, arg: 37, dialog: (c) => showCancelTxDialog(c, _tx(c, 37))),
  const DeskShot(id: '21-contacts', title: 'Contacts', route: DeskRoute.contacts),
  const DeskShot(id: '21b-contacts-empty', title: 'Contacts, empty', route: DeskRoute.contacts, arg: ContactsArgs(empty: true)),
  const DeskShot(id: '21d-contacts-empty-add', title: 'Contacts, empty, adding the first', route: DeskRoute.contacts, arg: ContactsArgs(empty: true, adding: true)),
  const DeskShot(
    id: '21c-contacts-selected',
    title: 'Contacts, one selected',
    route: DeskRoute.contacts,
    arg: ContactsArgs(selectedId: 'c1'),
  ),
  const DeskShot(id: '21d-contacts-loading', title: 'Contacts, loading', route: DeskRoute.contacts, arg: ContactsArgs(loading: true)),
  const DeskShot(id: '37-add-contact', title: 'New contact', route: DeskRoute.contacts, arg: ContactsArgs(adding: true)),
  const DeskShot(
    id: '37b-edit-contact',
    title: 'Edit contact',
    route: DeskRoute.contacts,
    arg: ContactsArgs(selectedId: 'c2', editing: true),
  ),
  DeskShot(
    id: '37c-dlg-delete-contact',
    title: 'Delete a contact',
    route: DeskRoute.contacts,
    arg: const ContactsArgs(selectedId: 'c2'),
    dialog: (c) => showDeleteContactDialog(c, ProviderScope.containerOf(c).read(deskProvider).contacts!.firstWhere((x) => x.id == 'c2')),
  ),
];
