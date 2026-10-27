import 'dart:io' show File;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_dialogs.dart';
import '../../app/shots.dart';
import '../../app/tour.dart';
import '../../app/update_notice.dart' show showUpdateReadyDialog;
import '../../data/desk_update.dart';
import '../../../btlabs_public.dart' show WalletDesktopFile, walletDesktopDownloads;
import '../../data/desk_node.dart';
import '../../data/mock_wallet.dart';
import '../../data/pairing_state.dart' show deskPairingRelaysProvider;
import '../../data/server_lists.dart' show ServerKind, deskServerListProvider;
import '../../widgets/kit.dart';
import 'backup.dart';
import 'history_conflicts.dart';
import 'dialogs.dart';
import '../onboarding/local_node_step.dart' show showLocalNodeSetupDialog;
import 'local_node_dialogs.dart';
import 'prefs.dart';
import 'report_problem.dart';
import 'settings_node.dart';
import 'settings_phrase.dart';
import 'settings_privacy.dart' show PrivacyDemo;
import 'settings_http.dart' show InternetGuide, InternetGuideChoice;
import 'settings_receiving.dart';
import 'settings_advanced.dart' show AdvancedDemo;
import '../../../help/help_content.dart' show HelpAnchor, HelpId;
import 'help_pairing.dart' show HelpAt;
import 'settings_help.dart' show HelpDemo;
import 'settings_account.dart' show AccountDemo;
import 'settings_rescan.dart';
import '../wallet/tx_detail.dart' show txMoreDemoProvider;
import '../transfer/send_code.dart' show showExperimentalOffDialog;
import '../../../advanced.dart';
import '../../../payment_prefs.dart';

/// A wallet that is not open, for the remove dialog's shots.
const demoOtherWallet = WalletEntry(id: '5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f', name: 'Savings', folder: '~/.epic/main/savings', network: 'mainnet');

/// Back to the settings the mock starts with (a demo state turned something on).
Future<void> resetSettingsDemo(ProviderContainer c) async {
  c.read(settingsPrefsProvider.notifier).set(const SettingsPrefs());
  final n = c.read(deskProvider.notifier);
  final now = c.read(deskProvider).settings;
  await n.saveSettings(
    now.copyWith(tor: false, publicMode: false, payments: PaymentPrefs.defaults, advanced: now.advanced.withFeature(AdvancedFeature.sendOptions, false)),
  );
  await n.setHttp(false);
  final node = c.read(deskNodeProvider);
  if (node is MockDeskNode) node.show(mockLocalNode(LocalNodePhase.stopped));
}

/// The local node panel in [state] with the fallback [consent], through the mock node layer.
Future<void> showLocalNode(ProviderContainer c, LocalNodeState state, FallbackConsent consent) async {
  final node = c.read(deskNodeProvider);
  if (node is MockDeskNode) node.show(state);
  await c.read(deskFallbackProvider.notifier).set(FallbackChoice(consent, nodeUrl: defaultFallbackNodeUrl, at: consent == FallbackConsent.unasked ? null : DateTime(2026, 10, 22, 13)));
  fallbackAskedThisSession = true; // the question is its own shot
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

/// An update to [phase] for the tour: the next version, from the download folder.
void _update(ProviderContainer c, DeskUpdatePhase phase, {bool inApp = true}) {
  const v = '26.10.19';
  c.read(deskUpdateProvider.notifier).showDemo(DeskUpdateState(
    phase,
    version: v,
    page: deskReleasesUrl,
    checkedAt: DateTime.now(),
    file: inApp ? WalletDesktopFile(url: Uri.parse('${walletDesktopDownloads}EpicCashDesktop-$v-x86_64.AppImage'), sha256: '0' * 64, size: 1) : null,
    download: phase == DeskUpdatePhase.ready ? File('EpicCashDesktop-$v-x86_64.AppImage') : null,
  ));
}

/// Screenshot tour entries of this group (see app/shots.dart). Ids match the Electron
/// reference shots.
final List<DeskShot> settingsShots = [
  const DeskShot(id: '20-node', title: 'Settings › Node: the node card', route: DeskRoute.settingsNode),
  const DeskShot(id: '20b-node-behind', title: 'Node card, behind', route: DeskRoute.settingsNode, arg: NodeDemo.behind),
  const DeskShot(id: '20c-node-old', title: 'Node card, older version', route: DeskRoute.settingsNode, arg: NodeDemo.old),
  const DeskShot(id: '20d-node-limited', title: 'Node card, limited info', route: DeskRoute.settingsNode, arg: NodeDemo.limited),
  const DeskShot(id: '20e-node-down', title: 'Node card, not answering', route: DeskRoute.settingsNode, arg: NodeDemo.down),
  const DeskShot(id: '22-settings-node', title: 'Settings, node', route: DeskRoute.settingsNode),
  // The user's own node (own-node spec): home network, asked directly; owner access; big screens.
  const DeskShot(id: '20o-own-node', title: 'Own node, asked directly', route: DeskRoute.settingsNode, arg: NodeDemo.own),
  const DeskShot(id: '20o-own-node-2474', title: 'Own node, asked directly, 2474x1338', route: DeskRoute.settingsNode, arg: NodeDemo.own, width: 2474, height: 1338),
  const DeskShot(id: '20p-own-node-access', title: 'Own node with owner access', route: DeskRoute.settingsNode, arg: NodeDemo.ownAccess),
  const DeskShot(id: '20p-own-node-access-2474', title: 'Own node with owner access, 2474x1338', route: DeskRoute.settingsNode, arg: NodeDemo.ownAccess, width: 2474, height: 1338),
  const DeskShot(id: '20q-own-node-peers', title: 'Own node, Peers tab', route: DeskRoute.settingsNode, arg: NodeDemo.ownPeers),
  const DeskShot(id: '20r-own-node-dialog', title: 'Own node, Owner access dialog', route: DeskRoute.settingsNode, arg: NodeDemo.ownDialog),
  const DeskShot(id: '20s-own-node-syncing', title: 'Own node syncing: the public-node offer', route: DeskRoute.settingsNode, arg: NodeDemo.ownSyncing),
  const DeskShot(id: '20s-own-node-syncing-2474', title: 'Own node syncing, 2474x1338', route: DeskRoute.settingsNode, arg: NodeDemo.ownSyncing, width: 2474, height: 1338),
  const DeskShot(id: '20t-own-node-down', title: 'Own node not answering: a public node stands in', route: DeskRoute.settingsNode, arg: NodeDemo.ownDown),
  const DeskShot(id: '20o-own-node-narrow', title: 'Own node at 1000x700', route: DeskRoute.settingsNode, arg: NodeDemo.ownAccess, width: 1000, height: 700),
  const DeskShot(id: '22-settings-node-2474', title: 'Settings, node card at 2474x1338', route: DeskRoute.settingsNode, width: 2474, height: 1338),
  const DeskShot(id: '23-settings-receiving-2474', title: 'Settings, Transactions at 2474x1338', route: DeskRoute.settingsReceiving, width: 2474, height: 1338),
  const DeskShot(id: '22-settings-node-narrow', title: 'Settings, node at 1000x700', route: DeskRoute.settingsNode, width: 1000, height: 700),
  const DeskShot(id: '22b-node-combobox-open', title: 'Node list open', route: DeskRoute.settingsNode, arg: NodeDemo.comboOpen),
  const DeskShot(id: '22c-node-typed', title: 'Node list, typed address: Add', route: DeskRoute.settingsNode, arg: NodeDemo.typed),
  const DeskShot(id: '22e-node-bad-address', title: 'Node list, not an address', route: DeskRoute.settingsNode, arg: NodeDemo.badAddress),
  const DeskShot(id: '22f-node-removed', title: 'Node list, a row removed: Undo and Restore', route: DeskRoute.settingsNode, arg: NodeDemo.removed),
  const DeskShot(id: '22g-node-picked', title: 'Node list, a row picked: switched', route: DeskRoute.settingsNode, arg: NodeDemo.picked),
  const DeskShot(id: '22d-node-pick-failed', title: 'Node pick failed', route: DeskRoute.settingsNode, arg: NodeDemo.pickFailed),
  for (final (id, title, state, consent) in [
    ('21-local-starting', 'Local node, starting', mockLocalNode(LocalNodePhase.starting), FallbackConsent.accepted),
    ('21-local-syncing', 'Local node, syncing headers with the fallback', mockLocalNode(LocalNodePhase.syncing, overall: 0.12, done: 1480200, total: 3764975, eta: const Duration(hours: 3)), FallbackConsent.accepted),
    ('21-local-syncing-download', 'Local node, chain state download', mockLocalNode(LocalNodePhase.syncing, stage: SyncStage.chainStateDownload, overall: 0.46, done: 1900000000, total: 4100000000, eta: const Duration(minutes: 40)), FallbackConsent.accepted),
    ('21-local-syncing-kernels', 'Local node, checking kernels', mockLocalNode(LocalNodePhase.syncing, stage: SyncStage.chainStateKernels, overall: 0.7, done: 2100000, total: 3400000), FallbackConsent.accepted),
    ('21-local-syncing-nofallback', 'Local node, syncing without the fallback', mockLocalNode(LocalNodePhase.syncing, stage: SyncStage.blocks, overall: 0.96, done: 3702100, total: 3764975, eta: const Duration(minutes: 12)), FallbackConsent.declined),
    ('21-local-synced', 'Local node, synced', mockLocalNode(LocalNodePhase.synced), FallbackConsent.accepted),
    ('21-local-stalled', 'Local node, stalled', mockLocalNode(LocalNodePhase.error, stalled: true), FallbackConsent.accepted),
    ('21-local-failed-port', 'Local node, port in use', mockLocalNode(LocalNodePhase.error, failure: NodeFailure.portInUse), FallbackConsent.accepted),
    ('21-local-failed-disk', 'Local node, disk low', mockLocalNode(LocalNodePhase.error, failure: NodeFailure.diskLow), FallbackConsent.accepted),
    ('21-local-failed-binary', 'Local node, program missing', mockLocalNode(LocalNodePhase.error, failure: NodeFailure.binaryMissing), FallbackConsent.accepted),
    ('21-local-failed-exited', 'Local node, stopped by itself', mockLocalNode(LocalNodePhase.error, failure: NodeFailure.exited, reason: 'exit code 101'), FallbackConsent.accepted),
    ('21-local-stopped', 'Local node, stopped', mockLocalNode(LocalNodePhase.stopped), FallbackConsent.accepted),
    ('21-local-restart-needed', 'Local node, settings changed', mockLocalNode(LocalNodePhase.synced, restartNeeded: true, userToml: true), FallbackConsent.accepted),
  ])
    DeskShot(id: id, title: title, route: DeskRoute.settingsNode, arg: NodeDemo.builtin, prepare: (c, _) => showLocalNode(c, state, consent)),
  DeskShot(id: '21-local-synced-2474', title: 'Local node, synced, 2474x1338', route: DeskRoute.settingsNode, arg: NodeDemo.builtin, width: 2474, height: 1338, prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.synced), FallbackConsent.accepted)),
  DeskShot(
    id: '21-local-peers',
    title: 'Local node, Peers tab',
    route: DeskRoute.settingsNode,
    arg: NodeDemo.peers,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.synced), FallbackConsent.accepted),
  ),
  DeskShot(
    id: '21b-dlg-fallback-ask',
    title: 'Use the public node until synced? (D-7)',
    route: DeskRoute.settingsNode,
    arg: NodeDemo.builtin,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.syncing, overall: 0.12, done: 1480200, total: 3764975), FallbackConsent.unasked),
    dialog: (ctx) => showFallbackAskDialog(ctx, host: 'node.epiccash.com'),
  ),
  DeskShot(
    id: '21c-dlg-delete-chain',
    title: 'Delete chain data',
    route: DeskRoute.settingsNode,
    arg: NodeDemo.builtin,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.synced), FallbackConsent.accepted),
    dialog: (ctx) => showEDialog<void>(ctx, builder: (_) => DeleteChainDataDialog(api: MockDeskNode(), state: mockLocalNode(LocalNodePhase.synced))),
  ),
  DeskShot(
    id: '21d-dlg-reuse-chain',
    title: 'Chain data found on this computer',
    route: DeskRoute.settingsNode,
    arg: NodeDemo.builtin,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.stopped), FallbackConsent.accepted),
    dialog: (ctx) => showReuseChainDataDialog(ctx, MockDeskNode()),
  ),
  DeskShot(
    id: '21e-dlg-node-log',
    title: 'Node log',
    route: DeskRoute.settingsNode,
    arg: NodeDemo.builtin,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.synced), FallbackConsent.accepted),
    dialog: (ctx) => showNodeLogDialog(ctx, MockDeskNode()),
  ),
  DeskShot(
    id: '21f-dlg-fallback-picker',
    title: 'Node while syncing: the list',
    route: DeskRoute.settingsNode,
    arg: NodeDemo.builtin,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.syncing, overall: 0.12), FallbackConsent.accepted),
    dialog: (ctx) => showFallbackPickerDialog(ctx, current: defaultFallbackNodeUrl),
  ),
  DeskShot(id: '22-node-local-dialog', title: 'Local node: the dialog from Settings', route: DeskRoute.settingsNode, dialog: (c) => showLocalNodeSetupDialog(c)),
  DeskShot(id: '22g-dlg-chain-offer', title: 'Existing blockchain data', route: DeskRoute.settingsNode, dialog: showChainOfferDialog),
  DeskShot(id: '22h-dlg-chain-offer-in-use', title: 'Existing blockchain data, in use', route: DeskRoute.settingsNode, dialog: (c) => showChainOfferDialog(c, inUse: true)),
  DeskShot(
    id: '23-settings-receiving',
    title: 'Settings, transactions',
    route: DeskRoute.settingsReceiving,
    prepare: (c, _) => resetSettingsDemo(c),
  ),
  const DeskShot(id: '23b-epicbox-combobox-open', title: 'Epicbox list open, the address warning', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.comboOpen),
  // A server the user typed in shows "Added by you" on the Epicbox page too.
  DeskShot(id: '23k-epicbox-added-by-you', title: 'Epicbox list, a server added by the user', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.comboOpen, prepare: (c, _) => _addedServer(c)),
  const DeskShot(id: '23j-epicbox-picked', title: 'Epicbox list, a row picked: the confirm', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.picked),
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
  const DeskShot(id: '23n-transactions-direct-on', title: 'Transactions, Link · HTTP on', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.directOn, height: 1200),
  const DeskShot(id: '23o-transactions-send-options', title: 'Transactions, Send options on', route: DeskRoute.settingsReceiving, arg: ReceivingDemo.sendOptions, height: 1400),
  const DeskShot(id: '23j-privacy', title: 'Privacy, Tor off', route: DeskRoute.settingsPrivacy),
  const DeskShot(id: '23k-privacy-tor-starting', title: 'Privacy, Tor starting', route: DeskRoute.settingsPrivacy, arg: PrivacyDemo.torStarting),
  const DeskShot(id: '23l-privacy-tor-on', title: 'Privacy, Tor on', route: DeskRoute.settingsPrivacy, arg: PrivacyDemo.torOn),
  const DeskShot(id: '23m-privacy-tor-failed', title: 'Privacy, Tor not connected', route: DeskRoute.settingsPrivacy, arg: PrivacyDemo.torFailed),
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
  const DeskShot(id: '25m-settings-account-auto-lock', title: 'Settings, this wallet: the auto-lock list, Never last', route: DeskRoute.settingsAccount, arg: AccountDemo.autoLockOpen, height: 1700),
  const DeskShot(id: '25d-settings-backup-since', title: 'Settings, this wallet: Backup, payments since', route: DeskRoute.settingsAccount, height: 1100),
  const DeskShot(
    id: '25e-settings-backup-busy',
    title: 'Settings, this wallet: Backup, exporting',
    route: DeskRoute.settingsAccount,
    arg: BackupDemo.busy,
    height: 1100,
  ),
  DeskShot(id: '25f-dlg-export-history', title: 'Export wallet data', route: DeskRoute.settingsAccount, dialog: showExportHistoryDialog),
  DeskShot(
    id: '25g-dlg-export-history-saved',
    title: 'Export wallet data, saved',
    route: DeskRoute.settingsAccount,
    dialog: (c) => showEDialog<void>(c, builder: (_) => const ExportHistoryDialog(savedDemo: '~/Documents/epic-wallet-data-savings-mainnet-20261022.wfeh')),
  ),
  DeskShot(id: '25h-dlg-import-history', title: 'Import history backup', route: DeskRoute.settingsAccount, dialog: showImportHistoryDialog),
  DeskShot(
    id: '25i-dlg-import-history-done',
    title: 'Import history backup, imported',
    route: DeskRoute.settingsAccount,
    dialog: (c) => showEDialog<void>(
      c,
      builder: (_) => const ImportHistoryDialog(
        doneDemo: (name: 'epic-wallet-data-savings-mainnet-20261003.wfeh', result: HistoryImport(merged: 12, added: 3, skipped: 33, contactsAdded: 2), settings: 4, walletName: false),
      ),
    ),
  ),
  DeskShot(
    id: '25l-dlg-history-conflicts',
    title: 'Import history backup, details differ',
    route: DeskRoute.settingsAccount,
    height: 1000,
    dialog: (c) => showHistoryConflicts(c, _conflicts),
  ),
  DeskShot(
    id: '25m-dlg-import-history-replaced',
    title: 'Import history backup, some details replaced',
    route: DeskRoute.settingsAccount,
    dialog: (c) => showEDialog<void>(
      c,
      builder: (_) => const ImportHistoryDialog(
        doneDemo: (name: 'epic-wallet-data-savings-mainnet-20261003.wfeh', result: HistoryImport(merged: 2, skipped: 44, replaced: 1), settings: 0, walletName: false),
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
  DeskShot(id: '29b-settings-about-update', title: 'About: an update to download and install, the download page', route: DeskRoute.settingsAbout, height: 960, prepare: (c, _) async => _update(c, DeskUpdatePhase.available)),
  DeskShot(
    id: '29c-settings-about-update-manual',
    title: "About: an update this copy can't install, the download page",
    route: DeskRoute.settingsAbout,
    height: 960,
    prepare: (c, _) async => _update(c, DeskUpdatePhase.available, inApp: false),
  ),
  DeskShot(id: '29d-slot-update', title: 'Sidebar: Update available', route: DeskRoute.overview, prepare: (c, _) async => _update(c, DeskUpdatePhase.available)),
  DeskShot(
    id: '29e-dlg-update-ready',
    title: 'The update is ready: Restart now or Later',
    route: DeskRoute.overview,
    prepare: (c, _) async => _update(c, DeskUpdatePhase.ready),
    dialog: (ctx) => showUpdateReadyDialog(ProviderScope.containerOf(ctx, listen: false), ctx),
  ),
  const DeskShot(id: '30-settings-help', title: 'Help', route: DeskRoute.settingsHelp, height: 1000),
  const DeskShot(id: '30b-settings-help-search', title: 'Help, search', route: DeskRoute.settingsHelp, arg: 'file'),
  const DeskShot(id: '30d-settings-help-open', title: 'Help, a topic open', route: DeskRoute.settingsHelp, arg: HelpDemo.open),
  const DeskShot(id: '30e-settings-help-bottom', title: 'Help, the end: Tor and Logs', route: DeskRoute.settingsHelp, arg: HelpDemo.bottom),
  const DeskShot(id: '30f-settings-help-cleanup', title: 'Help › Maintenance: clean up old wallet folders', route: DeskRoute.settingsHelp, arg: HelpAt('maintenance'), height: 1000),
  const DeskShot(id: '30g-settings-help-cancel', title: 'Help › Cancelling a payment, opened at Receiving', route: DeskRoute.settingsHelp, arg: HelpAt.topic(HelpId.cancel, anchor: HelpAnchor.receiving), height: 1000),
  DeskShot(
    id: '23g-dlg-internet-guide',
    title: 'Receive from the internet: the guide',
    route: DeskRoute.settingsReceiving,
    prepare: (c, _) => resetSettingsDemo(c),
    dialog: (c) => showEDialog<InternetGuideChoice>(c, builder: (_) => const InternetGuide(port: 3415, isPublic: false)),
  ),
  DeskShot(id: '30c-dlg-report-problem', title: 'Report a problem', route: DeskRoute.settingsHelp, dialog: showReportProblemDialog),
  DeskShot(id: '33-dlg-remove-wallet', title: 'Remove wallet', route: DeskRoute.settingsWallets, dialog: (c) => showRemoveWalletDialog(c, demoOtherWallet)),
  DeskShot(
    id: '33b-dlg-remove-wallet-everything',
    title: 'Remove wallet, everything',
    route: DeskRoute.settingsWallets,
    dialog: (c) => showRemoveWalletDialog(c, demoOtherWallet, mode: RemoveMode.everything),
  ),
  DeskShot(id: '38-dlg-change-password', title: 'Change password', route: DeskRoute.settingsAccount, dialog: showChangePasswordDialog),
  DeskShot(id: '39-dlg-node-synced', title: 'Local node synced', route: DeskRoute.overview, dialog: showNodeSyncedDialog),
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
  DeskShot(
    id: '41d-tour-advanced',
    title: 'Tour, the Advanced step',
    route: DeskRoute.overview,
    prepare: (c, _) async => c.read(deskTourProvider.notifier).open(at: deskTourSteps.length - 2),
  ),
  // Settings › Advanced › Experimental: Pairing and Invoices on, then off (the default), and
  // what off leaves: Contacts without Pair, a pairing link that says where to turn it on.
  const DeskShot(id: '43k-advanced-experimental', title: 'Settings › Advanced › Experimental, Pairing and Invoices on', route: DeskRoute.settingsAdvanced, height: 1450),
  // Connection servers: the row, the list as a set to tick (the defaults at the limit, two chosen,
  // a server the user added chosen). The window width at 2474 shows the field on one line.
  const DeskShot(id: '43o-connection-servers', title: 'Settings › Advanced › Connection servers', route: DeskRoute.settingsAdvanced, height: 1450),
  const DeskShot(id: '43p-connection-servers-open', title: 'Connection servers list, the defaults chosen (at the limit)', route: DeskRoute.settingsAdvanced, arg: AdvancedDemo.connectionServersOpen, height: 1900),
  DeskShot(id: '43q-connection-servers-two', title: 'Connection servers list, two chosen', route: DeskRoute.settingsAdvanced, arg: AdvancedDemo.connectionServersOpen, height: 1900, prepare: (c, _) => _chooseServers(c, ['epicbox.epiccash.com', 'epicbox.stackwallet.com'])),
  DeskShot(id: '43r-connection-servers-added', title: 'Connection servers list, a server the user added chosen', route: DeskRoute.settingsAdvanced, arg: AdvancedDemo.connectionServersOpen, height: 1900, prepare: (c, _) => _chooseServers(c, ['epicbox.epiccash.com', 'relay.example.org'], added: 'relay.example.org')),
  DeskShot(id: '43s-connection-servers-2474', title: 'Connection servers, 2474x1338', route: DeskRoute.settingsAdvanced, width: 2474, height: 1338),
  const DeskShot(id: '43l-advanced-experimental-off', title: 'Settings › Advanced › Experimental, both off', route: DeskRoute.settingsAdvanced, height: 1450),
  const DeskShot(id: '43m-contacts-pairing-off', title: 'Contacts with Pairing off: no Pair, no paired marks', route: DeskRoute.contacts),
  DeskShot(id: '43n-pairing-link-off', title: 'A pairing link with Pairing off', route: DeskRoute.send, dialog: (context) async => showExperimentalOffDialog(context)),
  // Advanced mode (Settings › Advanced) and what the network modes do to the screens.
  const DeskShot(id: '43-advanced', title: 'Settings › Advanced, everything off', route: DeskRoute.settingsAdvanced),
  DeskShot(id: '43b-advanced-tor-only', title: 'Settings, network mode Tor only', route: DeskRoute.settingsAdvanced, prepare: (c, _) => _networkMode(c, NetworkMode.torOnly)),
  DeskShot(id: '43c-advanced-offline', title: 'Settings › Advanced, Offline', route: DeskRoute.settingsAdvanced, prepare: (c, _) => _networkMode(c, NetworkMode.offline)),
  DeskShot(id: '43d-overview-offline', title: 'Overview, Offline', route: DeskRoute.overview, prepare: (c, _) => _networkMode(c, NetworkMode.offline)),
  DeskShot(id: '43e-overview-waiting-tor', title: 'Overview, Tor only waiting for Tor', route: DeskRoute.overview, prepare: (c, _) => _networkMode(c, NetworkMode.torOnly)),
  DeskShot(id: '43f-send-offline', title: 'Send, Offline', route: DeskRoute.send, prepare: (c, _) => _networkMode(c, NetworkMode.offline)),
  DeskShot(id: '43g-receive-offline', title: 'Receive, Offline', route: DeskRoute.receive, prepare: (c, _) => _networkMode(c, NetworkMode.offline)),
  DeskShot(id: '43h-privacy-tor-only', title: 'Privacy, the Tor switch locked by Tor only', route: DeskRoute.settingsPrivacy, prepare: (c, _) => _networkMode(c, NetworkMode.torOnly)),
  DeskShot(id: '43i-privacy-offline', title: 'Privacy, the Tor switch disabled by Offline', route: DeskRoute.settingsPrivacy, prepare: (c, _) => _networkMode(c, NetworkMode.offline)),
  DeskShot(
    id: '43j-tx-detail-more',
    title: 'Transaction detail, More opened with Technical details off',
    route: DeskRoute.activity,
    arg: 36,
    prepare: (c, _) async => c.read(txMoreDemoProvider.notifier).open(),
  ),
];

/// Sets the network mode for a shot (the mock starts in Standard with everything else off).
/// A server typed into the Epicbox list ("Added by you").
Future<void> _addedServer(ProviderContainer c) async {
  await c.read(deskServerListProvider(ServerKind.relay).notifier).add('relay.example.org', own: true);
}

/// Connection servers set to [hosts]; [added] is a server of them the user typed in.
Future<void> _chooseServers(ProviderContainer c, List<String> hosts, {String? added}) async {
  if (added != null) await c.read(deskServerListProvider(ServerKind.relay).notifier).add(added, own: true);
  await c.read(deskPairingRelaysProvider.notifier).set(hosts);
}

Future<void> _networkMode(ProviderContainer c, NetworkMode mode) async {
  final n = c.read(deskProvider.notifier);
  final s = c.read(deskProvider).settings;
  await n.saveSettings(s.copyWith(advanced: s.advanced.withMode(mode)));
}

/// The mock's backup record for a shot.
void _backup(ProviderContainer c, HistoryBackupState state) {
  final api = c.read(deskApiProvider);
  if (api is MockDeskWallet) api.backup = state;
  c.invalidate(historyBackupProvider);
}

/// What a backup says against what was typed here: two payments, three fields.
final List<ImportConflict> _conflicts = [
  ImportConflict(key: 'l:103', field: ManualField.label, mine: 'Pool payout, March', theirs: 'March payout', timeUnix: DateTime(2026, 10, 15, 9, 30).millisecondsSinceEpoch ~/ 1000, amount: BigInt.from(425000000)),
  ImportConflict(key: 'l:103', field: ManualField.transport, mine: 'epicbox', theirs: 'tor', timeUnix: DateTime(2026, 10, 15, 9, 30).millisecondsSinceEpoch ~/ 1000, amount: BigInt.from(425000000)),
  ImportConflict(key: 's:e5f60718-2a3b-44c5-d6e7-f8091a2b3c4d', field: ManualField.label, mine: 'Rent, October', theirs: 'Tom, rent', timeUnix: DateTime(2026, 10, 19, 8, 30).millisecondsSinceEpoch ~/ 1000, amount: BigInt.from(-4000000000)),
];

/// Shots taken with Pairing and Invoices on (Settings › Advanced › Experimental); every other
/// shot runs as a new install, with both off. The invoice shots are all in the invoice shots (invoices/shots.dart).
const deskExperimentalShots = {
  '43k-advanced-experimental',
  '43o-connection-servers',
  '43p-connection-servers-open',
  '43q-connection-servers-two',
  '43r-connection-servers-added',
  '43s-connection-servers-2474',
};
