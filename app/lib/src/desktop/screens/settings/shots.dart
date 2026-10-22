import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_dialogs.dart';
import '../../app/shots.dart';
import '../../app/tour.dart';
import '../../data/mock_wallet.dart';
import '../../widgets/kit.dart';
import 'backup.dart';
import 'dialogs.dart';
import 'prefs.dart';
import 'report_problem.dart';
import 'settings_node.dart';
import 'settings_phrase.dart';
import 'settings_http.dart' show InternetGuide, InternetGuideChoice;
import 'settings_receiving.dart';
import 'settings_help.dart' show HelpDemo;
import 'settings_rescan.dart';

/// A wallet that is not open, for the remove dialog's shots.
const demoOtherWallet = WalletEntry(id: '5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f', name: 'Savings', folder: '~/.epic/main/savings', network: 'mainnet');

/// Back to the settings the mock starts with (a demo state turned something on).
Future<void> resetSettingsDemo(ProviderContainer c) async {
  c.read(settingsPrefsProvider.notifier).set(const SettingsPrefs());
  final n = c.read(deskProvider.notifier);
  await n.saveSettings(c.read(deskProvider).settings.copyWith(tor: false, publicMode: false));
  await n.setHttp(false);
}

/// Screenshot tour entries of this group (see app/shots.dart). Ids match the Electron
/// reference shots.
final List<DeskShot> settingsShots = [
  const DeskShot(id: '22-settings-node', title: 'Settings, node', route: DeskRoute.settingsNode),
  const DeskShot(id: '22-settings-node-narrow', title: 'Settings, node at 1000x700', route: DeskRoute.settingsNode, width: 1000, height: 700),
  const DeskShot(id: '22b-node-combobox-open', title: 'Node combobox open', route: DeskRoute.settingsNode, arg: NodeDemo.comboOpen),
  const DeskShot(id: '22c-node-typed', title: 'Node combobox, typed address', route: DeskRoute.settingsNode, arg: NodeDemo.typed),
  const DeskShot(id: '22d-node-pick-failed', title: 'Node pick failed', route: DeskRoute.settingsNode, arg: NodeDemo.pickFailed),
  const DeskShot(id: '22e-node-builtin', title: 'Built-in node in use', route: DeskRoute.settingsNode, arg: NodeDemo.builtin),
  const DeskShot(id: '22f-node-chain-in-use', title: 'Built-in node on older chain data', route: DeskRoute.settingsNode, arg: NodeDemo.chainInUse),
  DeskShot(id: '22i-dlg-local-node-confirm', title: 'Local node: before it starts', route: DeskRoute.settingsNode, dialog: confirmLocalNode),
  DeskShot(id: '22g-dlg-chain-offer', title: 'Existing blockchain data', route: DeskRoute.settingsNode, dialog: showChainOfferDialog),
  DeskShot(id: '22h-dlg-chain-offer-in-use', title: 'Existing blockchain data, in use', route: DeskRoute.settingsNode, dialog: (c) => showChainOfferDialog(c, inUse: true)),
  DeskShot(
    id: '23-settings-receiving',
    title: 'Settings, receiving',
    route: DeskRoute.settingsReceiving,
    prepare: (c, _) => resetSettingsDemo(c),
  ),
  const DeskShot(id: '23b-epicbox-combobox-open', title: 'Epicbox combobox open', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.comboOpen),
  DeskShot(
    id: '23c-receiving-tor-on',
    title: 'Receiving, Tor on',
    route: DeskRoute.settingsReceiving,
    arg: ReceivingDemo.torOn,
    height: 1200,
  ),
  const DeskShot(id: '23d-receiving-epicbox-down', title: 'Receiving, Epicbox down', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.epicboxDown),
  const DeskShot(id: '23e-receiving-http-on', title: 'Receiving, HTTP on', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.httpOn),
  const DeskShot(id: '23f-receiving-http-failed', title: 'Receiving, HTTP failed', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.httpFailed),
  DeskShot(
    id: '23h-receiving-tor-stopped',
    title: 'Receiving, Tor stopped',
    route: DeskRoute.settingsReceiving,
    arg: ReceivingDemo.torStopped,
    height: 1200,
  ),
  const DeskShot(id: '23i-receiving-http-public', title: 'Receiving, HTTP from the internet', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.httpPublic, height: 1000),
  DeskShot(
    id: '24-settings-appearance',
    title: 'Settings, appearance',
    route: DeskRoute.settingsAppearance,
    // The receiving demos turned Tor and HTTP on: put them back for the shots after.
    prepare: (c, _) => resetSettingsDemo(c),
  ),
  const DeskShot(id: '25-settings-account', title: 'Settings, this wallet', route: DeskRoute.settingsAccount),
  DeskShot(id: '25b-dlg-change-password', title: 'Change password', route: DeskRoute.settingsAccount, dialog: showChangePasswordDialog),
  DeskShot(
    id: '25c-settings-backup',
    title: 'Settings, this wallet: Backup, never exported',
    route: DeskRoute.settingsAccount,
    height: 1100,
    prepare: (c, _) async => _backup(c, const HistoryBackupState(unbacked: 12, payments: 48, contacts: 6)),
  ),
  const DeskShot(id: '25d-settings-backup-since', title: 'Settings, this wallet: Backup, payments since', route: DeskRoute.settingsAccount, height: 1100),
  const DeskShot(
    id: '25e-settings-backup-busy',
    title: 'Settings, this wallet: Backup, exporting',
    route: DeskRoute.settingsAccount,
    arg: BackupDemo.busy,
    height: 1100,
  ),
  DeskShot(id: '25f-dlg-export-history', title: 'Export history backup', route: DeskRoute.settingsAccount, dialog: showExportHistoryDialog),
  DeskShot(
    id: '25g-dlg-export-history-saved',
    title: 'Export history backup, saved',
    route: DeskRoute.settingsAccount,
    dialog: (c) => showEDialog<void>(c, builder: (_) => const ExportHistoryDialog(savedDemo: '~/Documents/epic-history-mainnet-20261022.wfeh')),
  ),
  DeskShot(id: '25h-dlg-import-history', title: 'Import history backup', route: DeskRoute.settingsAccount, dialog: showImportHistoryDialog),
  DeskShot(
    id: '25i-dlg-import-history-done',
    title: 'Import history backup, imported',
    route: DeskRoute.settingsAccount,
    dialog: (c) => showEDialog<void>(
      c,
      builder: (_) => const ImportHistoryDialog(
        doneDemo: (name: 'epic-history-mainnet-20261003.wfeh', result: HistoryImport(merged: 12, added: 3, skipped: 33, contactsAdded: 2)),
      ),
    ),
  ),
  DeskShot(id: '25j-dlg-export-csv', title: 'Export CSV', route: DeskRoute.settingsAccount, dialog: showExportCsvDialog),
  DeskShot(
    id: '25k-dlg-export-csv-custom',
    title: 'Export CSV, custom range',
    route: DeskRoute.settingsAccount,
    dialog: (c) => showEDialog<void>(c, builder: (_) => const ExportCsvDialog(initial: CsvRange.custom)),
  ),
  const DeskShot(id: '26-settings-wallets', title: 'Settings, all wallets', route: DeskRoute.settingsWallets),
  const DeskShot(id: '27-settings-phrase', title: 'Recovery phrase', route: DeskRoute.settingsPhrase),
  const DeskShot(id: '27b-settings-phrase-shown', title: 'Recovery phrase, shown', route: DeskRoute.settingsPhrase, arg: PhraseDemo.shown),
  const DeskShot(id: '27c-settings-phrase-qr', title: 'Recovery phrase, QR code', route: DeskRoute.settingsPhrase, arg: PhraseDemo.qr),
  const DeskShot(id: '28-settings-rescan', title: 'Recheck balance', route: DeskRoute.settingsRescan),
  const DeskShot(id: '28b-settings-rescan-running', title: 'Recheck balance, running', route: DeskRoute.settingsRescan, arg: RescanDemo.running),
  const DeskShot(id: '29-settings-about', title: 'About', route: DeskRoute.settingsAbout),
  const DeskShot(id: '30-settings-help', title: 'Help', route: DeskRoute.settingsHelp, height: 1000),
  const DeskShot(id: '30b-settings-help-search', title: 'Help, search', route: DeskRoute.settingsHelp, arg: 'file'),
  const DeskShot(id: '30d-settings-help-open', title: 'Help, a topic open', route: DeskRoute.settingsHelp, arg: HelpDemo.open),
  const DeskShot(id: '30e-settings-help-bottom', title: 'Help, the end: Tor and Logs', route: DeskRoute.settingsHelp, arg: HelpDemo.bottom),
  DeskShot(
    id: '23g-dlg-internet-guide',
    title: 'Receive from the internet: the guide',
    route: DeskRoute.settingsReceiving,
    dialog: (c) => showEDialog<InternetGuideChoice>(c, builder: (_) => const InternetGuide(port: 3415, isPublic: false)),
  ),
  DeskShot(id: '30c-dlg-report-problem', title: 'Report a problem', route: DeskRoute.settingsHelp, dialog: showReportProblemDialog),
  DeskShot(id: '31-dlg-my-node', title: 'Add to my nodes', route: DeskRoute.settingsNode, dialog: (c) => showMyNodeDialog(c, adding: true)),
  DeskShot(
    id: '31b-dlg-my-node-error',
    title: 'Add to my nodes, bad address',
    route: DeskRoute.settingsNode,
    dialog: (c) => showMyNodeDialog(c, initial: 'http://bad example', adding: true, showError: true),
  ),
  DeskShot(
    id: '31c-dlg-my-node-edit',
    title: 'Edit a node of my nodes',
    route: DeskRoute.settingsNode,
    dialog: (c) => showMyNodeDialog(c, initial: 'http://10.0.1.24:3413', label: 'Home node'),
  ),
  DeskShot(id: '32-dlg-node-directory', title: 'Node directory', route: DeskRoute.settingsNode, dialog: showNodeDirectoryDialog),
  DeskShot(id: '33-dlg-remove-wallet', title: 'Remove wallet', route: DeskRoute.settingsWallets, dialog: (c) => showRemoveWalletDialog(c, demoOtherWallet)),
  DeskShot(
    id: '33b-dlg-remove-wallet-everything',
    title: 'Remove wallet, everything',
    route: DeskRoute.settingsWallets,
    dialog: (c) => showRemoveWalletDialog(c, demoOtherWallet, mode: RemoveMode.everything),
  ),
  DeskShot(id: '38-dlg-change-password', title: 'Change password', route: DeskRoute.settingsAccount, dialog: showChangePasswordDialog),
  DeskShot(id: '39-dlg-node-synced', title: 'Built-in node synced', route: DeskRoute.overview, dialog: showNodeSyncedDialog),
  DeskShot(id: '40-dlg-first-scan', title: 'Wallet first scan', route: DeskRoute.overview, dialog: (c) => showFirstScanDialog(c)),
  DeskShot(
    id: '41-tour',
    title: 'Tour, first step',
    route: DeskRoute.overview,
    prepare: (c, _) async => c.read(deskTourProvider.notifier).open(),
  ),
  DeskShot(
    id: '41b-tour-settings',
    title: 'Tour, last step',
    route: DeskRoute.overview,
    prepare: (c, _) async => c.read(deskTourProvider.notifier).open(at: deskTourSteps.length - 1),
  ),
  DeskShot(
    id: '41c-tour-narrow',
    title: 'Tour at 1000x700',
    route: DeskRoute.overview,
    width: 1000,
    height: 700,
    prepare: (c, _) async => c.read(deskTourProvider.notifier).open(at: 1),
  ),
];

/// The mock's backup record for a shot.
void _backup(ProviderContainer c, HistoryBackupState state) {
  final api = c.read(deskApiProvider);
  if (api is MockDeskWallet) api.backup = state;
  c.invalidate(historyBackupProvider);
}
