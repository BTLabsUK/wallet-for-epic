import 'dart:convert';

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../contact_store.dart' show ContactFields;
import '../../../contacts_file.dart' show encodeContactsFile;
import '../../app/shots.dart';
import '../../data/history_files.dart';
import '../../data/mock_wallet.dart';
import '../../widgets/kit.dart';
import '../settings/backup.dart' show historyBackupProvider;
import 'activity_screen.dart';
import 'contacts_screen.dart';
import 'contacts_transfer.dart' show deskExportContacts, deskImportContacts;
import 'outputs_dialogs.dart';
import 'outputs_screen.dart';
import 'overview_screen.dart';
import 'tx_detail.dart';
import 'tx_details_dialog.dart';
import 'tx_label.dart';

Tx _tx(BuildContext context, int id) {
  final container = ProviderScope.containerOf(context);
  return container.read(deskProvider).txs!.firstWhere((t) => t.id == id);
}

/// Adds the mock's payment whose sender reports it posted, and shows it.
Future<void> _senderPosted(ProviderContainer c, BuildContext _) async {
  mockBehind(c.read(deskApiProvider))?.addSenderPostedDemo();
  await c.read(deskProvider.notifier).refresh();
}

/// Adds the mock's incoming payment inside its Cancel hold (5 minutes after this wallet
/// signed), or past it (40 minutes), and shows it.
Future<void> _receiveHold(ProviderContainer c, BuildContext _) async {
  mockBehind(c.read(deskApiProvider))?.addReceiveCancelDemo(id: MockDeskWallet.receiveHoldDemoId, ago: const Duration(minutes: 5));
  await c.read(deskProvider.notifier).refresh();
}

Future<void> _receiveOffered(ProviderContainer c, BuildContext _) async {
  mockBehind(c.read(deskApiProvider))?.addReceiveCancelDemo(id: MockDeskWallet.receiveOfferedDemoId, ago: const Duration(minutes: 40));
  await c.read(deskProvider.notifier).refresh();
}

/// Anna's or the pool's contact deleted: their payments show Add to contacts.
Future<void> _forgetAnna(ProviderContainer c, BuildContext _) => c.read(deskProvider.notifier).deleteContact('c1');
Future<void> _forgetPool(ProviderContainer c, BuildContext _) => c.read(deskProvider.notifier).deleteContact('c2');

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
  DeskShot(
    id: '10h-overview-backup-reminder',
    title: 'Overview, history backup reminder',
    route: DeskRoute.overview,
    prepare: (c, _) async {
      final api = c.read(deskApiProvider);
      if (api is MockDeskWallet) api.backup = const HistoryBackupState(unbacked: 12, reminder: 12, payments: 48, contacts: 6);
      c.invalidate(historyBackupProvider);
    },
  ),
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
  const DeskShot(id: '12e-tx-detail-restored', title: 'Transaction detail, restored', route: DeskRoute.activity, arg: 102),
  const DeskShot(id: '12f-tx-detail-found-by-scan', title: 'Transaction detail, found by a balance recheck', route: DeskRoute.activity, arg: 103),
  const DeskShot(id: '12g-tx-detail-from-backup', title: 'Transaction detail, from a history backup', route: DeskRoute.activity, arg: -106),
  const DeskShot(id: '11g-activity-labels', title: 'Activity, labelled rows', route: DeskRoute.activity, arg: ActivityArgs(), height: 1000),
  const DeskShot(id: '11h-activity-labels-restored', title: 'Activity, a restored row with details', route: DeskRoute.activity, arg: ActivityArgs(txId: 103, query: 'payout')),
  DeskShot(
    id: '11i-activity-label-edit',
    title: 'Activity, editing a label in place',
    route: DeskRoute.activity,
    arg: const ActivityArgs(),
    height: 1000,
    prepare: (c, _) async => c.read(txLabelEditingProvider.notifier).open(c.read(deskProvider).txs!.firstWhere((t) => t.id == 35).key, txLabelRowPlace),
  ),
  const DeskShot(id: '12h-tx-detail-labelled', title: 'Transaction detail, with a label', route: DeskRoute.activity, arg: 35),
  DeskShot(
    id: '12i-tx-detail-label-edit',
    title: 'Transaction detail, editing the label',
    route: DeskRoute.activity,
    arg: 35,
    prepare: (c, _) async => c.read(txLabelEditingProvider.notifier).open(c.read(deskProvider).txs!.firstWhere((t) => t.id == 35).key, txLabelDetailPlace),
  ),
  const DeskShot(id: '12j-tx-detail-restored-details', title: 'Transaction detail, restored with details', route: DeskRoute.activity, arg: 103),
  DeskShot(id: '11j-activity-sender-posted', title: 'Activity, an incoming payment whose sender reports it posted', route: DeskRoute.activity, arg: const ActivityArgs(), prepare: _senderPosted),
  DeskShot(id: '12n-tx-detail-add-contact', title: 'Transaction detail, a send to an address no contact has', route: DeskRoute.activity, arg: 28, prepare: _forgetAnna),
  DeskShot(id: '12o-tx-detail-add-contact-received', title: 'Transaction detail, a receive from an address no contact has', route: DeskRoute.activity, arg: 27, prepare: _forgetPool),
  DeskShot(
    id: '37c-add-contact-from-tx',
    title: 'New contact from a payment, its address filled in',
    route: DeskRoute.contacts,
    arg: const ContactsArgs(adding: true, address: 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com', fromTx: 28),
    prepare: _forgetAnna,
  ),
  DeskShot(
    id: '12k-tx-detail-sender-posted',
    title: 'Transaction detail, the sender reports it posted',
    route: DeskRoute.activity,
    arg: MockDeskWallet.senderPostedDemoId,
    prepare: _senderPosted,
  ),
  DeskShot(
    id: '12l-tx-detail-receive-cancel-hold',
    title: 'Transaction detail, an incoming payment inside its Cancel hold',
    route: DeskRoute.activity,
    arg: MockDeskWallet.receiveHoldDemoId,
    prepare: _receiveHold,
  ),
  DeskShot(
    id: '12m-tx-detail-receive-cancel-offered',
    title: 'Transaction detail, an incoming payment whose Cancel is offered',
    route: DeskRoute.activity,
    arg: MockDeskWallet.receiveOfferedDemoId,
    prepare: _receiveOffered,
  ),
  DeskShot(
    id: '35c-dlg-cancel-receive',
    title: 'Cancel an incoming payment',
    route: DeskRoute.activity,
    arg: MockDeskWallet.receiveOfferedDemoId,
    prepare: _receiveOffered,
    dialog: (c) => showCancelTxDialog(c, _tx(c, MockDeskWallet.receiveOfferedDemoId)),
  ),
  DeskShot(id: '35d-dlg-tx-details-add', title: 'Add details to a restored payment', route: DeskRoute.activity, arg: 102, dialog: (c) => showTxDetailsDialog(c, _tx(c, 102))),
  DeskShot(id: '35e-dlg-tx-details-edit', title: 'Edit details of a restored payment', route: DeskRoute.activity, arg: 103, dialog: (c) => showTxDetailsDialog(c, _tx(c, 103))),
  const DeskShot(id: '12-tx-detail', title: 'Transaction detail', route: DeskRoute.activity, arg: 36),
  const DeskShot(id: '12b-tx-detail-file', title: 'Transaction detail, file send', route: DeskRoute.activity, arg: 38),
  // Tall, so the Cancel row with its quiet line and Help link is in the picture.
  const DeskShot(id: '12n-tx-detail-send-cancel', title: 'Transaction detail, a waiting send: Cancel with its quiet line', route: DeskRoute.activity, arg: 38, height: 1150),
  DeskShot(id: '12c-tx-detail-narrow', title: 'Transaction detail, narrow', route: DeskRoute.activity, arg: 39, width: 900, height: 760),
  DeskShot(id: '35-dlg-tx-proof', title: 'Payment proof', route: DeskRoute.activity, arg: 36, dialog: (c) => showTxProofDialog(c, _tx(c, 36))),
  DeskShot(id: '35b-dlg-cancel-tx', title: 'Cancel a send', route: DeskRoute.activity, arg: 38, dialog: (c) => showCancelTxDialog(c, _tx(c, 38))),
  DeskShot(
    id: '35c-dlg-cancel-incoming',
    title: 'Cancel an incoming payment',
    route: DeskRoute.activity,
    arg: 36,
    dialog: (c) => showCancelTxDialog(c, Tx(id: 36, slateId: '', direction: TxDirection.received, state: TxState.posted, method: TxMethod.epicbox, amount: 250000000, fee: 0, created: DateTime(2026, 10, 20), counterparty: 'esAlice@epicbox.example', cancellable: true)),
  ),
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
  DeskShot(
    id: '21e-dlg-contacts-import',
    title: 'Import contacts, what it does',
    route: DeskRoute.contacts,
    prepare: (c, _) async => _contactsFile(c),
    dialog: deskImportContacts,
  ),
  const DeskShot(id: '21f-dlg-contacts-export', title: 'Export contacts, what the file holds', route: DeskRoute.contacts, dialog: deskExportContacts),
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

/// The next Import contacts picks a file with Anna (gaining a Tor address), a new contact, one
/// already here and a floonet one.
void _contactsFile(ProviderContainer c) {
  final book = c.read(deskProvider).contacts!;
  String epicbox(String id) => book.firstWhere((x) => x.id == id).epicbox!;
  final file = encodeContactsFile(
    [
      ContactFields(name: 'Anna', epicbox: epicbox('c1'), tor: '${'q' * 55}d.onion'), // l10n-ok
      ContactFields(name: 'Exchange deposit', epicbox: epicbox('c3')), // l10n-ok
      const ContactFields(name: 'Lena Fischer', epicbox: 'esLf4Wq8TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtK2s@epicbox.epiccash.com'), // l10n-ok
      const ContactFields(name: 'Test', epicbox: 'zz1234@flooepicbox.btlabs.uk'), // l10n-ok
    ],
    network: c.read(deskApiProvider).network,
    now: DateTime(2026, 10, 25),
  );
  final files = c.read(deskHistoryFilesProvider);
  if (files is MockDeskHistoryFiles) files.picks.add((name: 'epic-cash-contacts-2026-10-25.json', bytes: Uint8List.fromList(utf8.encode(file)))); // l10n-ok
}
