// SPDX-License-Identifier: Apache-2.0
import '../../../mock_fixtures.dart';
import '../../../levels/level_providers.dart' show walletLevelProvider;
import '../../../levels/wallet_level.dart';
import '../../data/desk_levels.dart' show deskLevelControlProvider;
import '../../data/mock_hosts.dart';
import 'dart:async' show unawaited;
import 'dart:io' show File;

import 'package:flutter/gestures.dart' show GestureBinding, PointerDownEvent, PointerUpEvent;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trust_ids.dart' show TrustId;

import '../../desk_l10n.dart';

import '../../app/app_dialogs.dart';
import '../../app/shots.dart';
import '../../app/tour.dart';
import '../../app/update_notice.dart' show showUpdateReadyDialog;
import '../../data/desk_update.dart';
import '../../../btlabs_public.dart' show WalletDesktopFile, walletUpdateDownloads;
import '../../data/desk_node.dart';
import '../../data/mock_wallet.dart';
import '../../data/server_lists.dart' show ServerKind, deskServerListProvider;
import '../../widgets/kit.dart';
import 'backup.dart';
import 'history_conflicts.dart';
import 'dialogs.dart';
import '../onboarding/local_node_step.dart' show showLocalNodeSetupDialog;
import 'local_node_dialogs.dart';
import 'prefs.dart';
import '../wallet/overview_screen.dart' show OverviewShot;
import 'report_problem.dart';
import 'settings_node.dart';
import 'settings_phrase.dart';
import 'settings_privacy.dart' show PrivacyShot;
import 'settings_http.dart' show InternetGuide, InternetGuideChoice;
import 'settings_receiving.dart';
import '../transfer/finalize_screen.dart' show FinalizeArgs;
import '../transfer/finished_payment.dart' show showPostFinished;
import '../transfer/send_screen.dart' show SendArgs;
import '../../../wallet_service.dart' show FakeWalletSession;
import '../../../help/help_content.dart' show HelpAnchor, HelpId;
import 'help_pairing.dart' show HelpAt;
import 'settings_about.dart' show AboutShot;
import 'settings_help.dart' show HelpShot;
import 'settings_security.dart' show SecurityShot;
import 'settings_rescan.dart';
import '../../../ui/scan_start.dart' show ScanStart;
import 'search/search_slot.dart' show settingsQueryProvider;
import '../../widgets/more_options.dart' show moreOptionsRevealProvider;
import '../wallet/tx_detail.dart' show txMoreShotProvider;
import '../../../advanced.dart';
import '../../../payment_prefs.dart';
import '../../../settings_file/host_settings.dart' show appConfig;

/// A wallet that is not open, for the remove dialog's shots.
const shotOtherWallet = WalletEntry(id: '5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f', name: 'Savings', folder: '~/.epic_cash_desktop/wallets/5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f', network: 'mainnet');

/// Back to the settings the mock starts with (a shot state turned something on).
Future<void> resetSettingsShots(ProviderContainer c) async {
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
  final v = mockUpdateVersion;
  c.read(deskUpdateProvider.notifier).showShot(DeskUpdateState(
    phase,
    version: v,
    page: deskReleasesUrl,
    checkedAt: DateTime.now(),
    file: inApp ? WalletDesktopFile(url: Uri.parse('${walletUpdateDownloads ?? ''}bt-wallet-$v-linux-x86_64.AppImage'), sha256: '0' * 64, size: 1) : null,
    download: phase == DeskUpdatePhase.ready ? File('bt-wallet-$v-linux-x86_64.AppImage') : null,
  ));
}

/// Screenshot tour entries of this group (see app/shots.dart). Ids match the Electron
/// reference shots.
/// Shows the screen at [level] (the tour's wallet stands on its own, so the pick is its own).
/// The level's first build settles the store first: a pick before that is overwritten by it.
Future<void> Function(ProviderContainer) _level(WalletLevel level) => (c) async {
  await c.read(walletLevelProvider.future);
  await c.read(deskLevelControlProvider).setLevel(level);
};

final List<DeskShot> settingsShots = [
  const DeskShot(id: '20-node', title: 'Settings › Node: the node card', route: DeskRoute.settingsNode),
  const DeskShot(id: '20b-node-behind', title: 'Node card, behind', route: DeskRoute.settingsNode, arg: NodeShot.behind),
  const DeskShot(id: '20c-node-old', title: 'Node card, older version', route: DeskRoute.settingsNode, arg: NodeShot.old),
  const DeskShot(id: '20d-node-limited', title: 'Node card, limited info', route: DeskRoute.settingsNode, arg: NodeShot.limited),
  const DeskShot(id: '20e-node-down', title: 'Node card, not answering', route: DeskRoute.settingsNode, arg: NodeShot.down),
  const DeskShot(id: '22-settings-node', title: 'Settings, node', route: DeskRoute.settingsNode),
  // The user's own node: home network, asked directly; owner access; big screens.
  const DeskShot(id: '20o-own-node', title: 'Own node, asked directly', route: DeskRoute.settingsNode, arg: NodeShot.own),
  const DeskShot(id: '20o-own-node-2474', title: 'Own node, asked directly, 2474x1338', route: DeskRoute.settingsNode, arg: NodeShot.own, width: 2474, height: 1338),
  const DeskShot(id: '20p-own-node-access', title: 'Own node with owner access', route: DeskRoute.settingsNode, arg: NodeShot.ownAccess),
  const DeskShot(id: '20p-own-node-access-2474', title: 'Own node with owner access, 2474x1338', route: DeskRoute.settingsNode, arg: NodeShot.ownAccess, width: 2474, height: 1338),
  const DeskShot(id: '20q-own-node-peers', title: 'Own node, Peers tab', route: DeskRoute.settingsNode, arg: NodeShot.ownPeers),
  const DeskShot(id: '20r-own-node-dialog', title: 'Own node, Owner access dialog', route: DeskRoute.settingsNode, arg: NodeShot.ownDialog),
  const DeskShot(id: '20s-own-node-syncing', title: 'Own node syncing: the public-node offer', route: DeskRoute.settingsNode, arg: NodeShot.ownSyncing),
  const DeskShot(id: '20s-own-node-syncing-2474', title: 'Own node syncing, 2474x1338', route: DeskRoute.settingsNode, arg: NodeShot.ownSyncing, width: 2474, height: 1338),
  const DeskShot(id: '20t-own-node-down', title: 'Own node not answering: a public node stands in', route: DeskRoute.settingsNode, arg: NodeShot.ownDown),
  const DeskShot(id: '20o-own-node-narrow', title: 'Own node at 1000x700', route: DeskRoute.settingsNode, arg: NodeShot.ownAccess, width: 1000, height: 700),
  const DeskShot(id: '22-settings-node-2474', title: 'Settings, node card at 2474x1338', route: DeskRoute.settingsNode, width: 2474, height: 1338),
  const DeskShot(id: '23-settings-receiving-2474', title: 'Settings, Transactions at 2474x1338', route: DeskRoute.settingsReceiving, width: 2474, height: 1338),
  const DeskShot(id: '22-settings-node-narrow', title: 'Settings, node at 1000x700', route: DeskRoute.settingsNode, width: 1000, height: 700),
  const DeskShot(id: '22b-node-combobox-open', title: 'Node list open', route: DeskRoute.settingsNode, arg: NodeShot.comboOpen),
  const DeskShot(id: '22c-node-typed', title: 'Node list, typed address: Add', route: DeskRoute.settingsNode, arg: NodeShot.typed),
  const DeskShot(id: '22e-node-bad-address', title: 'Node list, not an address', route: DeskRoute.settingsNode, arg: NodeShot.badAddress),
  const DeskShot(id: '22f-node-removed', title: 'Node list, a row removed: Undo and Restore', route: DeskRoute.settingsNode, arg: NodeShot.removed),
  const DeskShot(id: '22g-node-picked', title: 'Node list, a row picked: switched', route: DeskRoute.settingsNode, arg: NodeShot.picked),
  const DeskShot(id: '22d-node-pick-failed', title: 'Node pick failed', route: DeskRoute.settingsNode, arg: NodeShot.pickFailed),
  for (final (id, title, state, consent) in [
    ('21-local-starting', 'Local node, starting', mockLocalNode(LocalNodePhase.starting), FallbackConsent.accepted),
    ('21-local-syncing', 'Local node, syncing headers with the fallback', mockLocalNode(LocalNodePhase.syncing, overall: 0.12, done: 1480200, total: mockTip, eta: const Duration(hours: 3)), FallbackConsent.accepted),
    ('21-local-syncing-download', 'Local node, chain state download', mockLocalNode(LocalNodePhase.syncing, stage: SyncStage.chainStateDownload, overall: 0.46, done: 1900000000, total: 4100000000, eta: const Duration(minutes: 40)), FallbackConsent.accepted),
    ('21-local-syncing-kernels', 'Local node, checking kernels', mockLocalNode(LocalNodePhase.syncing, stage: SyncStage.chainStateKernels, overall: 0.7, done: 2100000, total: mockTip), FallbackConsent.accepted),
    ('21-local-syncing-nofallback', 'Local node, syncing without the fallback', mockLocalNode(LocalNodePhase.syncing, stage: SyncStage.blocks, overall: 0.96, done: 3702100, total: mockTip, eta: const Duration(minutes: 12)), FallbackConsent.declined),
    ('21-local-synced', 'Local node, synced', mockLocalNode(LocalNodePhase.synced), FallbackConsent.accepted),
    ('21-local-stalled', 'Local node, stalled', mockLocalNode(LocalNodePhase.error, stalled: true), FallbackConsent.accepted),
    ('21-local-failed-port', 'Local node, port in use', mockLocalNode(LocalNodePhase.error, failure: NodeFailure.portInUse), FallbackConsent.accepted),
    ('21-local-failed-disk', 'Local node, disk low', mockLocalNode(LocalNodePhase.error, failure: NodeFailure.diskLow), FallbackConsent.accepted),
    ('21-local-failed-binary', 'Local node, program missing', mockLocalNode(LocalNodePhase.error, failure: NodeFailure.binaryMissing), FallbackConsent.accepted),
    ('21-local-failed-exited', 'Local node, stopped by itself', mockLocalNode(LocalNodePhase.error, failure: NodeFailure.exited, reason: 'exit code 101'), FallbackConsent.accepted),
    ('21-local-stopped', 'Local node, stopped', mockLocalNode(LocalNodePhase.stopped), FallbackConsent.accepted),
    ('21-local-restart-needed', 'Local node, settings changed', mockLocalNode(LocalNodePhase.synced, restartNeeded: true, userToml: true), FallbackConsent.accepted),
  ])
    DeskShot(id: id, title: title, route: DeskRoute.settingsNode, arg: NodeShot.builtin, prepare: (c, _) => showLocalNode(c, state, consent)),
  DeskShot(id: '21-local-synced-2474', title: 'Local node, synced, 2474x1338', route: DeskRoute.settingsNode, arg: NodeShot.builtin, width: 2474, height: 1338, prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.synced), FallbackConsent.accepted)),
  // The Ports row's info popover with its "More in Help" link (WD2-063).
  DeskShot(
    id: '21-local-ports-hint',
    title: 'Local node, the Ports info popover with its Help link',
    route: DeskRoute.settingsNode,
    arg: NodeShot.builtin,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.synced), FallbackConsent.accepted),
    dialog: (c) => openInfoHint(c, title: (l) => l.deskOnbNodePortsWhy),
  ),
  DeskShot(
    id: '21-local-peers',
    title: 'Local node, Peers tab',
    route: DeskRoute.settingsNode,
    arg: NodeShot.peers,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.synced), FallbackConsent.accepted),
  ),
  DeskShot(
    id: '21b-dlg-fallback-ask',
    title: 'Use the public node until synced?',
    route: DeskRoute.settingsNode,
    arg: NodeShot.builtin,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.syncing, overall: 0.12, done: 1480200, total: mockTip), FallbackConsent.unasked),
    dialog: (ctx) => showFallbackAskDialog(ctx, host: Uri.parse(mockNodeAt(0)).host),
  ),
  DeskShot(
    id: '21c-dlg-delete-chain',
    title: 'Delete chain data',
    route: DeskRoute.settingsNode,
    arg: NodeShot.builtin,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.synced), FallbackConsent.accepted),
    dialog: (ctx) => showEDialog<void>(ctx, builder: (_) => DeleteChainDataDialog(api: MockDeskNode(), state: mockLocalNode(LocalNodePhase.synced))),
  ),
  DeskShot(
    id: '21d-dlg-reuse-chain',
    title: 'Chain data found on this computer',
    route: DeskRoute.settingsNode,
    arg: NodeShot.builtin,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.stopped), FallbackConsent.accepted),
    dialog: (ctx) => showReuseChainDataDialog(ctx, MockDeskNode()),
  ),
  DeskShot(
    id: '21e-dlg-node-log',
    title: 'Node log',
    route: DeskRoute.settingsNode,
    arg: NodeShot.builtin,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.synced), FallbackConsent.accepted),
    dialog: (ctx) => showNodeLogDialog(ctx, MockDeskNode()),
  ),
  DeskShot(
    id: '21f-dlg-fallback-picker',
    title: 'Node while syncing: the list',
    route: DeskRoute.settingsNode,
    arg: NodeShot.builtin,
    prepare: (c, _) => showLocalNode(c, mockLocalNode(LocalNodePhase.syncing, overall: 0.12), FallbackConsent.accepted),
    dialog: (ctx) => showFallbackPickerDialog(ctx, current: defaultFallbackNodeUrl),
  ),
  DeskShot(id: '22-node-local-dialog', title: 'Local node: the dialog from Settings', route: DeskRoute.settingsNode, dialog: (c) => showLocalNodeSetupDialog(c)),
  DeskShot(id: '22b-node-local-dialog-ports', title: 'Local node: the dialog with Advanced open (the ports)', route: DeskRoute.settingsNode, dialog: (c) => showLocalNodeSetupDialog(c, portsOpen: true)),
  DeskShot(
    id: '23-settings-receiving',
    title: 'Settings, transactions',
    route: DeskRoute.settingsReceiving,
    prepare: (c, _) => resetSettingsShots(c),
  ),
  const DeskShot(id: '23b-epicbox-combobox-open', title: 'Epicbox list open, the address warning', route: DeskRoute.settingsReceiving, arg: ReceivingShot.comboOpen),
  // A server the user typed in shows "Added by you" on the Epicbox page too.
  DeskShot(id: '23k-epicbox-added-by-you', title: 'Epicbox list, a server added by the user', route: DeskRoute.settingsReceiving, arg: ReceivingShot.comboOpen, prepare: (c, _) => _addedServer(c)),
  const DeskShot(id: '23j-epicbox-picked', title: 'Epicbox list, a row picked: the confirm', route: DeskRoute.settingsReceiving, arg: ReceivingShot.picked),
  DeskShot(
    id: '23c-receiving-tor-on',
    title: 'Receiving, Tor on',
    route: DeskRoute.settingsReceiving,
    arg: ReceivingShot.torOn,
    height: 1200,
  ),
  const DeskShot(id: '23d-receiving-epicbox-down', title: 'Receiving, Epicbox down', route: DeskRoute.settingsReceiving, arg: ReceivingShot.epicboxDown),
  const DeskShot(id: '23e-receiving-http-on', title: 'Receiving, HTTP on', route: DeskRoute.settingsReceiving, arg: ReceivingShot.httpOn),
  const DeskShot(id: '23f-receiving-http-failed', title: 'Receiving, HTTP failed', route: DeskRoute.settingsReceiving, arg: ReceivingShot.httpFailed),
  DeskShot(
    id: '23h-receiving-tor-stopped',
    title: 'Receiving, Tor stopped',
    route: DeskRoute.settingsReceiving,
    arg: ReceivingShot.torStopped,
    height: 1200,
  ),
  const DeskShot(id: '23i-receiving-http-public', title: 'Receiving, HTTP from the internet', route: DeskRoute.settingsReceiving, arg: ReceivingShot.httpPublic, height: 1000),
  const DeskShot(id: '23n-transactions-direct-on', title: 'Transactions, Link · HTTP on', route: DeskRoute.settingsReceiving, arg: ReceivingShot.directOn, height: 1200),
  const DeskShot(id: '23o-transactions-send-options', title: 'Transactions, Send options on', route: DeskRoute.settingsReceiving, arg: ReceivingShot.sendOptions, height: 1400),
  // Network & privacy (B-03): the mode, Tor and the servers on one page, tall enough for all three.
  const DeskShot(id: '23j-privacy', title: 'Network & privacy, Normal, Tor off', route: DeskRoute.settingsPrivacy, height: 1000),
  const DeskShot(id: '23k-privacy-tor-starting', title: 'Network & privacy, Tor starting', route: DeskRoute.settingsPrivacy, arg: PrivacyShot.torStarting, height: 1000),
  const DeskShot(id: '23l-privacy-tor-on', title: 'Network & privacy, Tor on', route: DeskRoute.settingsPrivacy, arg: PrivacyShot.torOn, height: 1000),
  const DeskShot(id: '23m-privacy-tor-failed', title: 'Network & privacy, Tor not connected', route: DeskRoute.settingsPrivacy, arg: PrivacyShot.torFailed, height: 1000),
  DeskShot(
    id: '24-settings-appearance',
    title: 'Settings, appearance',
    route: DeskRoute.settingsAppearance,
    // The receiving shots turned Tor and HTTP on: put them back for the shots after.
    prepare: (c, _) => resetSettingsShots(c),
  ),
  const DeskShot(id: '25-settings-account', title: 'Settings, this wallet', route: DeskRoute.settingsAccount),
  const DeskShot(id: '25n-settings-security', title: 'Settings, security', route: DeskRoute.settingsSecurity),
  DeskShot(id: '25b-dlg-change-password', title: 'Change password', route: DeskRoute.settingsSecurity, dialog: showChangePasswordDialog),
  DeskShot(id: '25o-dlg-delete-wallet', title: 'Delete wallet', route: DeskRoute.settingsSecurity, dialog: showDeleteWalletDialog),
  DeskShot(
    id: '25c-settings-backup',
    title: 'Settings, this wallet: Backup, never exported',
    route: DeskRoute.settingsAccount,
    height: 1100,
    prepare: (c, _) async => _backup(c, const HistoryBackupState(unbacked: 12, payments: 48, contacts: 6)),
  ),
  const DeskShot(id: '25m-settings-security-auto-lock', title: 'Settings, security: the auto-lock list, Never last', route: DeskRoute.settingsSecurity, arg: SecurityShot.autoLockOpen, height: 1000),
  const DeskShot(id: '25d-settings-backup-since', title: 'Settings, this wallet: Backup, payments since', route: DeskRoute.settingsAccount, height: 1100),
  const DeskShot(
    id: '25e-settings-backup-busy',
    title: 'Settings, this wallet: Backup, exporting',
    route: DeskRoute.settingsAccount,
    arg: BackupShot.busy,
    height: 1100,
  ),
  DeskShot(id: '25f-dlg-export-history', title: 'Export wallet data', route: DeskRoute.settingsAccount, dialog: showExportHistoryDialog),
  DeskShot(
    id: '25g-dlg-export-history-saved',
    title: 'Export wallet data, saved',
    route: DeskRoute.settingsAccount,
    dialog: (c) => showEDialog<void>(c, builder: (_) => const ExportHistoryDialog(savedShot: '~/Documents/epic-wallet-data-savings-20261022.wfeh')),
  ),
  DeskShot(id: '25h-dlg-import-history', title: 'Import history backup', route: DeskRoute.settingsAccount, dialog: showImportHistoryDialog),
  DeskShot(
    id: '25i-dlg-import-history-done',
    title: 'Import history backup, imported',
    route: DeskRoute.settingsAccount,
    dialog: (c) => showEDialog<void>(
      c,
      builder: (_) => const ImportHistoryDialog(
        doneShot: (name: 'epic-wallet-data-savings-20261003.wfeh', result: HistoryImport(merged: 12, added: 3, skipped: 33, contactsAdded: 2), settings: 4, walletName: false),
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
        doneShot: (name: 'epic-wallet-data-savings-20261003.wfeh', result: HistoryImport(merged: 2, skipped: 44, replaced: 1), settings: 0, walletName: false),
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
  const DeskShot(id: '26-settings-wallets-narrow', title: 'Settings, all wallets at 1000x750', route: DeskRoute.settingsWallets, width: 1000, height: 750),
  const DeskShot(id: '27-settings-phrase', title: 'Recovery phrase', route: DeskRoute.settingsPhrase),
  const DeskShot(id: '27b-settings-phrase-shown', title: 'Recovery phrase, shown', route: DeskRoute.settingsPhrase, arg: PhraseShot.shown),
  const DeskShot(id: '27c-settings-phrase-qr', title: 'Recovery phrase, QR code', route: DeskRoute.settingsPhrase, arg: PhraseShot.qr),
  const DeskShot(id: '28-settings-rescan', title: 'Recheck balance', route: DeskRoute.settingsRescan),
  const DeskShot(id: '28b-settings-rescan-running', title: 'Recheck balance, running', route: DeskRoute.settingsRescan, arg: RescanShot.running),
  // The check's answer is set by the shot: the tour asks no update server.
  DeskShot(
    id: '29-settings-about',
    title: 'About, up to date',
    route: DeskRoute.settingsAbout,
    prepare: (c, _) async => c.read(deskUpdateProvider.notifier).showShot(DeskUpdateState(DeskUpdatePhase.latest, checkedAt: DateTime.now().subtract(const Duration(minutes: 2)))),
  ),
  const DeskShot(id: '29g-settings-about-licences', title: 'About, Licences unfolded', route: DeskRoute.settingsAbout, arg: AboutShot.licencesOpen, height: 1000),
  const DeskShot(id: '26b-settings-files', title: 'Settings › Files & logs', route: DeskRoute.settingsFiles),
  DeskShot(id: '29b-settings-about-update', title: 'About: an update to download and install', route: DeskRoute.settingsAbout, prepare: (c, _) async => _update(c, DeskUpdatePhase.available)),
  DeskShot(
    id: '29c-settings-about-update-manual',
    title: "About: an update this copy can't install",
    route: DeskRoute.settingsAbout,
    prepare: (c, _) async => _update(c, DeskUpdatePhase.available, inApp: false),
  ),
  DeskShot(
    id: '29f-settings-about-failed',
    title: 'About: the update check failed',
    route: DeskRoute.settingsAbout,
    prepare: (c, _) async => c.read(deskUpdateProvider.notifier).showShot(DeskUpdateState(DeskUpdatePhase.failed, reason: deskStrings.deskDataUpdStatus(503), checkedAt: DateTime.now())),
  ),
  // The update strip above the page and the sidebar's slot: alone, over a problem notice, and
  // after the strip was closed for this version (the slot stays).
  DeskShot(id: '29d-slot-update', title: 'Update available: the strip and the sidebar slot', route: DeskRoute.overview, prepare: (c, _) async => _update(c, DeskUpdatePhase.available)),
  DeskShot(
    id: '29h-strip-update-stacked',
    title: 'Update available over a node problem',
    route: DeskRoute.overview,
    arg: OverviewShot.nodeDown,
    prepare: (c, _) async => _update(c, DeskUpdatePhase.available),
  ),
  DeskShot(
    id: '29i-strip-update-hidden',
    title: 'Update strip closed: only the sidebar slot',
    route: DeskRoute.overview,
    prepare: (c, _) async {
      _update(c, DeskUpdatePhase.available);
      c.read(settingsPrefsProvider.notifier).hideUpdateStrip(mockUpdateVersion);
    },
  ),
  DeskShot(
    id: '29e-dlg-update-ready',
    title: 'The update is ready: Restart now or Later',
    route: DeskRoute.overview,
    prepare: (c, _) async => _update(c, DeskUpdatePhase.ready),
    dialog: (ctx) => showUpdateReadyDialog(ProviderScope.containerOf(ctx, listen: false), ctx),
  ),
  const DeskShot(id: '30-settings-help', title: 'Help', route: DeskRoute.settingsHelp, height: 1000),
  const DeskShot(id: '30b-settings-help-search', title: 'Help, search', route: DeskRoute.settingsHelp, arg: 'file'),
  const DeskShot(id: '30d-settings-help-open', title: 'Help, a topic open', route: DeskRoute.settingsHelp, arg: HelpShot.open),
  const DeskShot(id: '30e-settings-help-bottom', title: 'Help, the end: Support and Start again', route: DeskRoute.settingsHelp, arg: HelpShot.bottom),
  const DeskShot(id: '30f-settings-help-cleanup', title: 'Help › Maintenance: clean up old wallet folders', route: DeskRoute.settingsHelp, arg: HelpAt('maintenance'), height: 1000),
  const DeskShot(id: '30g-settings-help-cancel', title: 'Help › Cancelling a payment, opened at Receiving', route: DeskRoute.settingsHelp, arg: HelpAt.topic(HelpId.cancel, anchor: HelpAnchor.receiving), height: 1000),
  DeskShot(
    id: '23g-dlg-internet-guide',
    title: 'Receive from the internet: the guide',
    route: DeskRoute.settingsReceiving,
    prepare: (c, _) => resetSettingsShots(c),
    dialog: (c) => showEDialog<InternetGuideChoice>(c, builder: (_) => InternetGuide(port: appConfig.httpListenPort, isPublic: false)),
  ),
  DeskShot(id: '30c-dlg-report-problem', title: 'Report a problem', route: DeskRoute.settingsHelp, dialog: showReportProblemDialog),
  // The dialog, then the Include full details info popover over it.
  DeskShot(
    id: '30c2-dlg-report-problem-full-details-info',
    title: 'Report a problem, the Include full details info popover',
    route: DeskRoute.settingsHelp,
    dialog: (c) async {
      unawaited(showReportProblemDialog(c));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!c.mounted) return;
      // The dialog lives in the navigator's overlay, so the search starts at the root.
      await openInfoHint(c, title: (l) => l.deskSetReportFullDetails, under: WidgetsBinding.instance.rootElement);
    },
  ),
  DeskShot(id: '33-dlg-remove-wallet', title: 'Remove wallet', route: DeskRoute.settingsWallets, dialog: (c) => showRemoveWalletDialog(c, shotOtherWallet)),
  DeskShot(
    id: '33b-dlg-remove-wallet-everything',
    title: 'Remove wallet, everything',
    route: DeskRoute.settingsWallets,
    dialog: (c) => showRemoveWalletDialog(c, shotOtherWallet, mode: RemoveMode.everything),
  ),
  DeskShot(id: '38-dlg-change-password', title: 'Change password', route: DeskRoute.settingsSecurity, dialog: showChangePasswordDialog),
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
  // Advanced mode (Settings › Advanced; the network mode is on Network & privacy) and what the
  // network modes do to the screens.
  const DeskShot(id: '43-advanced', title: 'Settings › Advanced, everything off', route: DeskRoute.settingsAdvanced),
  // Wallet levels: Advanced (its Depth group on top) at Shallow and Deeper.
  DeskShot(id: '43-advanced-l1', title: 'Settings › Advanced, Shallow', route: DeskRoute.settingsAdvanced, before: _level(WalletLevel.justSendReceive)),
  DeskShot(id: '43-advanced-l2', title: 'Settings › Advanced, Deeper', route: DeskRoute.settingsAdvanced, before: _level(WalletLevel.casual)),
  const DeskShot(id: '43-advanced-narrow', title: 'Settings › Advanced at 1000x750', route: DeskRoute.settingsAdvanced, width: 1000, height: 750),
  DeskShot(id: '43d-overview-offline', title: 'Overview, Offline', route: DeskRoute.overview, prepare: (c, _) => _networkMode(c, NetworkMode.killSwitch)),
  DeskShot(id: '43e-overview-waiting-tor', title: 'Overview, Tor only waiting for Tor', route: DeskRoute.overview, prepare: (c, _) => _networkMode(c, NetworkMode.torOnly)),
  DeskShot(id: '43f-send-offline', title: 'Send, Offline', route: DeskRoute.send, prepare: (c, _) => _networkMode(c, NetworkMode.killSwitch)),
  DeskShot(id: '43g-receive-offline', title: 'Receive, Offline', route: DeskRoute.receive, prepare: (c, _) => _networkMode(c, NetworkMode.killSwitch)),
  DeskShot(id: '43h-privacy-tor-only', title: 'Network & privacy, Tor only: the Tor switch locked on', route: DeskRoute.settingsPrivacy, height: 1000, prepare: (c, _) => _networkMode(c, NetworkMode.torOnly)),
  DeskShot(id: '43i-privacy-offline', title: 'Network & privacy, Kill switch: the Tor switch off', route: DeskRoute.settingsPrivacy, height: 1000, prepare: (c, _) => _networkMode(c, NetworkMode.killSwitch)),
  DeskShot(
    id: '43j-tx-detail-more',
    title: 'Transaction detail, More opened with Technical details off',
    route: DeskRoute.activity,
    arg: 36,
    prepare: (c, _) async => c.read(txMoreShotProvider.notifier).open(),
  ),
  // Settings › Advanced › Balance: the wallet's minimum confirmations at the default (6), set
  // to 3 (Reset and the note under the row), and Overview counting with 3 (the mock's 25 EPIC
  // payment, 4 blocks in, is spendable then).
  const DeskShot(id: '43o-advanced-confirmations', title: 'Settings › Advanced › Balance, Confirmations at the default 6', route: DeskRoute.settingsAdvanced, height: 1450),
  DeskShot(id: '43p-advanced-confirmations-3', title: 'Settings › Advanced › Balance, Confirmations set to 3', route: DeskRoute.settingsAdvanced, height: 1450, prepare: (c, _) => _minConfirmations(c, 3)),
  DeskShot(id: '43q-overview-confirmations-3', title: 'Overview counting with 3 confirmations', route: DeskRoute.overview, prepare: (c, _) => _minConfirmations(c, 3)),
  // Network modes: the section, a mode's info popover, the mark in the title bar, a blocked
  // note, and the cold-payment screens.
  const DeskShot(id: '44a-network-section', title: 'Settings › Network & privacy › Network, the four modes', route: DeskRoute.settingsPrivacy, height: 1000),
  DeskShot(id: '44b2-network-normal-hint', title: 'Settings › Network & privacy, the Normal info popover', route: DeskRoute.settingsPrivacy, height: 1000, dialog: (ctx) => openInfoHint(ctx, title: (l) => l.advModeStandard)),
  DeskShot(id: '44b3-network-tor-only-hint', title: 'Settings › Network & privacy, the Tor only info popover', route: DeskRoute.settingsPrivacy, height: 1000, dialog: (ctx) => openInfoHint(ctx, title: (l) => l.advModeTorOnly)),
  DeskShot(id: '44b4-network-node-only-hint', title: 'Settings › Network & privacy, the Node only info popover', route: DeskRoute.settingsPrivacy, height: 1000, dialog: (ctx) => openInfoHint(ctx, title: (l) => l.advModeNodeOnly)),
  DeskShot(id: '44b-network-kill-switch-hint', title: 'Settings › Network & privacy, the Kill switch info popover', route: DeskRoute.settingsPrivacy, height: 1000, dialog: (ctx) => openInfoHint(ctx, title: (l) => l.advModeKillSwitch)),
  DeskShot(id: '44c-overview-node-only', title: 'Overview in Node only: the mark, Epicbox and Link off', route: DeskRoute.overview, prepare: (c, _) => _networkMode(c, NetworkMode.nodeOnly)),
  DeskShot(id: '44d-overview-kill-switch', title: 'Overview in Kill switch: the mark, every service off, the balance last known', route: DeskRoute.overview, prepare: (c, _) => _networkMode(c, NetworkMode.killSwitch)),
  DeskShot(
    id: '44e-send-epicbox-node-only',
    title: 'Send over Epicbox in Node only: the blocked note',
    route: DeskRoute.send,
    arg: const SendArgs(recipient: 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.example.org', amount: '1'),
    prepare: (c, _) => _networkMode(c, NetworkMode.nodeOnly),
  ),
  DeskShot(
    id: '44f-finished-not-posted',
    title: 'Finalize under Kill switch: Finished, not posted',
    route: DeskRoute.finalize,
    arg: FinalizeArgs(finishedTx: _coldTx),
    prepare: (c, _) => _networkMode(c, NetworkMode.killSwitch),
  ),
  DeskShot(
    id: '44g-post-finished-summary',
    title: 'Receive › Transaction files › Post a finished payment, the summary',
    route: DeskRoute.receive,
    dialog: (ctx) => showPostFinished(ctx, text: FakeWalletSession.fakeFinishedText(5)),
  ),
  // The help popover (widgets/popover.dart) open on the Network group's info icon.
  DeskShot(id: '43r-network-help', title: 'Settings › Network & privacy › Network, the help popover open', route: DeskRoute.settingsPrivacy, dialog: (ctx) => openInfoHint(ctx, title: (l) => l.deskSetAdvNetwork)),
  // The Settings redesign (26.10.25): search, the hidden rows behind ⇕, the views' nav, the
  // month picker.
  DeskShot(id: '45a-settings-search-tor', title: 'Settings search: "tor"', route: DeskRoute.settingsAccount, prepare: (c, _) async => c.read(settingsQueryProvider.notifier).set('tor')),
  DeskShot(id: '45b-settings-search-seed', title: 'Settings search: "seed"', route: DeskRoute.settingsAccount, prepare: (c, _) async => c.read(settingsQueryProvider.notifier).set('seed')),
  DeskShot(
    id: '45c-payments-sending-revealed',
    title: 'Payments in the Deeper view, Sending with its hidden rows shown (⇕)',
    route: DeskRoute.settingsReceiving,
    before: _level(WalletLevel.casual),
    prepare: (c, _) async => c.read(moreOptionsRevealProvider.notifier).open('pay-sending'),
  ),
  DeskShot(id: '45d-settings-shallow', title: 'Settings in the Shallow view: the nav', route: DeskRoute.settingsAccount, before: _level(WalletLevel.justSendReceive)),
  DeskShot(
    id: '45e-rescan-start-open',
    title: 'Recheck balance: the scan start open (month or height, with Recheck from a height on)',
    route: DeskRoute.settingsRescan,
    prepare: (c, _) async {
      final s = c.read(deskProvider).settings;
      await c.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: s.advanced.withFeature(AdvancedFeature.recheckFromHeight, true)));
    },
    after: (_, ctx) async => tapShotKey(ctx, ScanStart.changeKey),
  ),
  DeskShot(
    id: '45f-rescan-month-open',
    title: 'Recheck balance: the month picker open',
    route: DeskRoute.settingsRescan,
    prepare: (_, ctx) async => tapShotKey(ctx, ScanStart.changeKey),
    after: (_, ctx) async => tapShotKey(ctx, EStartMonthField.fieldKey),
  ),
  DeskShot(
    id: '45g-rescan-start-info',
    title: 'Recheck balance: the scan start\u2019s info, with Scan from the start',
    route: DeskRoute.settingsRescan,
    dialog: (ctx) => openInfoHint(ctx, title: (l) => l.scanStartInfoTitle),
  ),
];

/// A tap at the middle of the widget with [key] under [context], as a pointer would make it.
void tapShotKey(BuildContext context, Key key) => _tapShot(context, (w) => w.key == key);

/// The same for the control marked [TrustId] [id] (a segment of an [ESegmented], a button).
void tapShotTrustId(BuildContext context, String id) => _tapShot(context, (w) => w is TrustId && w.id == id);

void _tapShot(BuildContext context, bool Function(Widget) match) {
  Element? found;
  void visit(Element e) {
    if (found != null) return;
    if (match(e.widget)) {
      found = e;
      return;
    }
    e.visitChildren(visit);
  }

  context.visitChildElements(visit);
  final box = found?.renderObject as RenderBox?;
  if (box == null || !box.hasSize) return;
  final at = box.localToGlobal(box.size.center(Offset.zero));
  GestureBinding.instance
    ..handlePointerEvent(PointerDownEvent(position: at))
    ..handlePointerEvent(PointerUpEvent(position: at));
}

/// Opens the popover of the [EInfoHint] titled [title] under [root] (the tour's dialog hook).
Future<void> openInfoHint(BuildContext root, {required String Function(AppLocalizations) title, Element? under}) async {
  final want = title(root.l10n);
  EInfoHintState? found;
  void visit(Element e) {
    if (found != null) return;
    // By the popover's title, or by its text for a hint without one (a plain row's).
    if (e is StatefulElement && e.widget is EInfoHint && ((e.widget as EInfoHint).title == want || (e.widget as EInfoHint).text == want)) {
      found = e.state as EInfoHintState;
      return;
    }
    e.visitChildren(visit);
  }
  (under ?? root as Element).visitChildren(visit);
  await found?.open();
}

/// A send finalized under Kill switch, for the Finished, not posted shot.
final Tx _coldTx = Tx(
  id: 7,
  slateId: 'a1f9e8d7c0b64f21',
  direction: TxDirection.sent,
  state: TxState.posted,
  method: TxMethod.file,
  amount: 12500000000,
  fee: 8000000,
  created: DateTime(2026, 10, 30, 7, 12),
  notPosted: true,
);

/// Sets the open wallet's minimum confirmations for a shot (the mock starts at the default).
Future<void> _minConfirmations(ProviderContainer c, int count) => c.read(deskMinConfirmationsSettingProvider.notifier).set(count);

/// Sets the network mode for a shot (the mock starts in Standard with everything else off).
/// A server typed into the Epicbox list ("Added by you").
Future<void> _addedServer(ProviderContainer c) async {
  await c.read(deskServerListProvider(ServerKind.relay).notifier).add('relay.example.org', own: true);
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

