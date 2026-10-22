import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shots.dart';
import '../../widgets/kit.dart';
import 'activity_screen.dart';
import 'contacts_screen.dart';
import 'outputs_dialogs.dart';
import 'outputs_screen.dart';
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
    id: '11f-activity-search-none',
    title: 'Activity, no match',
    route: DeskRoute.activity,
    arg: ActivityArgs(query: 'zzz'),
  ),
  const DeskShot(id: '12d-tx-detail-mining', title: 'Transaction detail, mining reward', route: DeskRoute.activity, arg: 101),
  const DeskShot(id: '12-tx-detail', title: 'Transaction detail', route: DeskRoute.activity, arg: 36),
  const DeskShot(id: '12b-tx-detail-file', title: 'Transaction detail, file send', route: DeskRoute.activity, arg: 38),
  DeskShot(id: '12c-tx-detail-narrow', title: 'Transaction detail, narrow', route: DeskRoute.activity, arg: 39, width: 900, height: 760),
  DeskShot(id: '35-dlg-tx-proof', title: 'Payment proof', route: DeskRoute.activity, arg: 36, dialog: (c) => showTxProofDialog(c, _tx(c, 36))),
  DeskShot(id: '35b-dlg-cancel-tx', title: 'Cancel a send', route: DeskRoute.activity, arg: 37, dialog: (c) => showCancelTxDialog(c, _tx(c, 37))),
  DeskShot(id: '19a-outputs', title: 'Outputs', route: DeskRoute.outputs, arg: _outputsSix, height: 1000),
  DeskShot(
    id: '19b-outputs-filter',
    title: 'Outputs, spendable only',
    route: DeskRoute.outputs,
    arg: OutputsArgs(outputs: _six, balance: _sixBalance, filter: OutputsFilter.spendable),
    height: 1000,
  ),
  DeskShot(id: '19c-outputs-spent', title: 'Outputs, spent shown', route: DeskRoute.outputs, arg: OutputsArgs(outputs: _six, balance: _sixBalance, showSpent: true), height: 1000),
  DeskShot(id: '19d-outputs-locked', title: 'Outputs, after a split', route: DeskRoute.outputs, arg: OutputsArgs(outputs: _afterSplit, balance: _afterSplitBalance), height: 1000),
  DeskShot(id: '19e-outputs-one', title: 'Outputs, one output', route: DeskRoute.outputs, arg: OutputsArgs(outputs: [_out(1, 100, OutputStatus.unspent, 2913020, 1394, 30)], balance: _bal(100)), height: 1000),
  DeskShot(id: '19f-outputs-empty', title: 'Outputs, none yet', route: DeskRoute.outputs, arg: OutputsArgs(outputs: const [], balance: _bal(0))),
  const DeskShot(id: '19g-outputs-loading', title: 'Outputs, loading', route: DeskRoute.outputs, arg: OutputsArgs(waiting: true)),
  DeskShot(id: '19h-outputs-narrow', title: 'Outputs at 980 wide', route: DeskRoute.outputs, arg: _outputsSix, width: 980, height: 1000),
  DeskShot(id: '19i-dlg-split', title: 'Split outputs', route: DeskRoute.outputs, arg: _outputsSix, dialog: (c) => showSplitDialog(c)),
  DeskShot(id: '19j-dlg-split-posting', title: 'Split, posting', route: DeskRoute.outputs, arg: _outputsSix, dialog: (c) => showSplitDialog(c, demo: const SelfSendDemo(SelfSendPhase.posting))),
  DeskShot(id: '19k-dlg-split-done', title: 'Split, done', route: DeskRoute.outputs, arg: _outputsSix, dialog: (c) => showSplitDialog(c, demo: const SelfSendDemo(SelfSendPhase.done))),
  DeskShot(id: '19l-dlg-split-not-posted', title: 'Split, not posted', route: DeskRoute.outputs, arg: _outputsSix, dialog: (c) => showSplitDialog(c, demo: const SelfSendDemo(SelfSendPhase.notPosted))),
  DeskShot(id: '19m-dlg-consolidate', title: 'Consolidate outputs', route: DeskRoute.outputs, arg: _outputsSix, dialog: (c) => showConsolidateDialog(c, spendableCount: 4)),
  DeskShot(
    id: '19n-dlg-consolidate-done',
    title: 'Consolidate, done',
    route: DeskRoute.outputs,
    arg: _outputsSix,
    dialog: (c) => showConsolidateDialog(c, spendableCount: 4, demo: const SelfSendDemo(SelfSendPhase.done)),
  ),
  DeskShot(id: '19o-dlg-consolidate-one', title: 'Consolidate, one output', route: DeskRoute.outputs, arg: _outputsSix, dialog: (c) => showConsolidateDialog(c, spendableCount: 1)),
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

String _cmt(int i) => '08${List.generate(64, (k) => '0123456789abcdef'[(i * 7 + k * 13 + k * k) % 16]).join()}';

int _nano(double epic) => (epic * nanoPerEpic).round();

Output _out(int i, double epic, OutputStatus status, int height, int confirmations, int? txId, {bool finalizing = false}) => Output(
  commitment: _cmt(i),
  value: _nano(epic),
  status: status,
  height: height == 0 ? null : height,
  confirmations: confirmations,
  awaitingFinalization: finalizing,
  txId: txId,
);

Balance _bal(double spendable, {double confirming = 0, double locked = 0, double finalizing = 0}) =>
    Balance(spendable: _nano(spendable), awaitingConfirmation: _nano(confirming), locked: _nano(locked), awaitingFinalization: _nano(finalizing));

/// Six outputs (and a spent one): four spendable, one confirming, one awaiting finalization.
final List<Output> _six = [
  _out(1, 25, OutputStatus.confirming, 2914410, 2, 36),
  _out(2, 12.5, OutputStatus.unconfirmed, 0, 0, 38, finalizing: true),
  _out(5, 148.73215, OutputStatus.unspent, 2913020, 1394, 30),
  _out(6, 7.5, OutputStatus.unspent, 2913500, 914, 31),
  _out(7, 0.5, OutputStatus.unspent, 2908700, 5714, 33),
  _out(8, 1000, OutputStatus.unspent, 2902900, 11514, 34),
  _out(9, 40.008, OutputStatus.spent, 2900100, 14314, 35),
];
final Balance _sixBalance = _bal(1156.73215, confirming: 25, finalizing: 12.5);
final OutputsArgs _outputsSix = OutputsArgs(outputs: _six, balance: _sixBalance);

/// Right after a split into four: the spent outputs locked, the new ones on their way.
final List<Output> _afterSplit = [
  for (final o in _six)
    o.status == OutputStatus.unspent ? Output(commitment: o.commitment, value: o.value, status: OutputStatus.locked, height: o.height, confirmations: o.confirmations, txId: 44) : o,
  for (var i = 0; i < 4; i++) _out(20 + i, 289.1805375, OutputStatus.unconfirmed, 0, 0, i == 0 ? 45 : 44, finalizing: true),
];
final Balance _afterSplitBalance = _bal(0, confirming: 25, locked: 1156.73215, finalizing: 1169.22215);
