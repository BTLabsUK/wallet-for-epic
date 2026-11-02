// SPDX-License-Identifier: Apache-2.0
/// Every Settings row, once: its id ([SetId]), its page, group, name, explanation, the other
/// words that find it and what shows it (a view, an Advanced switch). Settings search reads
/// only this list, so a row is searchable when it is listed here and its page row carries
/// `anchor: SetId.x` (`test/desktop/settings_registry_test.dart` keeps both in step).
library;

import '../../advanced.dart' show AdvancedFeature;
import '../../settings_file/status_site.dart' show statusSiteHost;
import '../desk_l10n.dart';
import '../screens/settings/search/settings_sections.dart';
import '../screens/settings/setting_ids.dart';
import '../widgets/kit.dart' show DeskRoute;
import 'features.dart' show DeskFeatures;

export '../screens/settings/setting_ids.dart';

typedef SetText = String Function(AppLocalizations l);

/// One Settings row.
class SetEntry {
  const SetEntry(
    this.id,
    this.route, {
    required this.label,
    required this.synonyms,
    this.group,
    this.hint,
    this.info,
    this.gate = SetGate.none,
    this.parent,
  });

  final String id;

  /// The page the row is on.
  final DeskRoute route;
  final SetText label;

  /// Other words that find the row, comma-separated, in the app's language.
  final SetText synonyms;

  /// The group heading over the row; null for a page's first, unnamed group.
  final SetText? group;

  /// The row's one-line explanation, and the longer one behind its ⓘ.
  final SetText? hint;
  final SetText? info;

  /// What shows the row beyond its section's gate: a view, an Advanced switch.
  final SetGate gate;

  /// The row this one sits under and only shows with (Receiving under Epicbox): a jump lands
  /// there while this one is not on the page.
  final String? parent;

  SetSection get section => setSectionOf(route)!;

  /// The row's gate with its page's (and the page's parent's).
  SetGate get fullGate => gate.and(section.fullGate);

  /// The synonyms of [l], trimmed, empty ones dropped.
  List<String> synonymList(AppLocalizations l) => [
    for (final s in synonyms(l).split(RegExp(r'[,，、]'))) if (s.trim().isNotEmpty) s.trim(),
  ];
}

/// The rows of a part this build leaves out (Link · Tor without Tor): on no page, not searched.
const Set<String> settingsNotBuilt = {if (!DeskFeatures.tor) SetId.torPay};

/// Every row of this build, in navigation order.
final List<SetEntry> settingsRegistry = [
  SetEntry(SetId.name, DeskRoute.settingsAccount, label: (l) => l.deskSetAcctLabel, hint: (l) => l.deskSetRowNameHint, synonyms: (l) => l.deskSetSynName),
  SetEntry(SetId.exportData, DeskRoute.settingsAccount, label: (l) => l.deskSetBackupExportTitle, group: (l) => l.deskSetGrpBackup, hint: (l) => l.deskSetRowExportDataHint, info: (l) => l.deskSetRowExportDataInfo, synonyms: (l) => l.deskSetSynExportData),
  SetEntry(SetId.importData, DeskRoute.settingsAccount, label: (l) => l.deskSetBackupImportTitle, group: (l) => l.deskSetGrpBackup, hint: (l) => l.deskSetRowImportDataHint, synonyms: (l) => l.deskSetSynImportData),
  SetEntry(SetId.exportCsv, DeskRoute.settingsAccount, label: (l) => l.deskSetBackupCsvDialogTitle, group: (l) => l.deskSetGrpBackup, hint: (l) => l.deskSetRowExportCsvHint, synonyms: (l) => l.deskSetSynExportCsv),
  SetEntry(SetId.recheckGo, DeskRoute.settingsAccount, label: (l) => l.deskSetFrameRescan, group: (l) => l.deskSetGrpBalance, hint: (l) => l.deskSetRowRecheckGoHint, synonyms: (l) => l.deskSetSynRecheckGo),
  SetEntry(SetId.deleteWallet, DeskRoute.settingsAccount, label: (l) => l.deskSetDlgDeleteWallet, group: (l) => l.deskSetGrpRemove, hint: (l) => l.deskSetRowDeleteWalletHint, synonyms: (l) => l.deskSetSynDeleteWallet),
  SetEntry(SetId.recheckFrom, DeskRoute.settingsRescan, label: (l) => l.deskSetRescanStartHeading, synonyms: (l) => l.deskSetSynRecheckFrom, gate: SetGate(minLevel: 2, features: [AdvancedFeature.recheckFromHeight])),
  SetEntry(SetId.recheckMonth, DeskRoute.settingsRescan, label: (l) => l.deskSetRowRecheckMonth, synonyms: (l) => l.deskSetSynRecheckMonth, gate: SetGate(minLevel: 2, features: [AdvancedFeature.recheckFromHeight]), parent: SetId.recheckFrom),
  SetEntry(SetId.recheckHeight, DeskRoute.settingsRescan, label: (l) => l.deskSetRowRecheckHeight, synonyms: (l) => l.deskSetSynRecheckHeight, gate: SetGate(minLevel: 2, features: [AdvancedFeature.recheckFromHeight]), parent: SetId.recheckFrom),
  SetEntry(SetId.recheckDrop, DeskRoute.settingsRescan, label: (l) => l.deskSetRescanDeleteUnconfirmed, hint: (l) => l.deskSetRowRecheckDropHint, synonyms: (l) => l.deskSetSynRecheckDrop, gate: SetGate(minLevel: 2, features: [AdvancedFeature.recheckFromHeight])),
  SetEntry(SetId.phraseGo, DeskRoute.settingsSecurity, label: (l) => l.deskSetFramePhrase, hint: (l) => l.deskSetRowPhraseGoHint, synonyms: (l) => l.deskSetSynPhraseGo),
  SetEntry(SetId.password, DeskRoute.settingsSecurity, label: (l) => l.deskSetDlgPassword, hint: (l) => l.deskSetRowPasswordHint, synonyms: (l) => l.deskSetSynPassword),
  SetEntry(SetId.remembered, DeskRoute.settingsSecurity, label: (l) => l.deskSetAcctRemembered, hint: (l) => l.deskSetRowRememberedHint, synonyms: (l) => l.deskSetSynRemembered),
  SetEntry(SetId.autolock, DeskRoute.settingsSecurity, label: (l) => l.settingsAutoLock, hint: (l) => l.deskSetRowAutolockHint, synonyms: (l) => l.deskSetSynAutolock),
  SetEntry(SetId.epicbox, DeskRoute.settingsReceiving, label: (l) => l.deskSetupEpicboxTitle, group: (l) => l.deskSetGrpMethods, hint: (l) => l.deskSetRowEpicboxHint, synonyms: (l) => l.deskSetSynEpicbox),
  SetEntry(SetId.epicboxRecv, DeskRoute.settingsReceiving, label: (l) => l.deskSetRecvReceiving, group: (l) => l.deskSetGrpMethods, synonyms: (l) => l.deskSetSynEpicboxRecv, parent: SetId.epicbox),
  SetEntry(SetId.epicboxServer, DeskRoute.settingsReceiving, label: (l) => l.deskSetRecvEpicboxServer, group: (l) => l.deskSetGrpMethods, hint: (l) => l.deskSetRowEpicboxServerHint, synonyms: (l) => l.deskSetSynEpicboxServer, parent: SetId.epicbox),
  SetEntry(SetId.epicboxStart, DeskRoute.settingsReceiving, label: (l) => l.deskSetRecvAutostart, group: (l) => l.deskSetGrpMethods, synonyms: (l) => l.deskSetSynEpicboxStart, parent: SetId.epicbox),
  SetEntry(SetId.http, DeskRoute.settingsReceiving, label: (l) => l.methodDirectHttp, group: (l) => l.deskSetGrpMethods, hint: (l) => l.deskSetRowHttpHint, synonyms: (l) => l.deskSetSynHttp),
  SetEntry(SetId.httpReach, DeskRoute.settingsReceiving, label: (l) => l.deskSetHttpGuideTitle, group: (l) => l.deskSetGrpMethods, synonyms: (l) => l.deskSetSynHttpReach, parent: SetId.http),
  SetEntry(SetId.httpPort, DeskRoute.settingsReceiving, label: (l) => l.deskSetHttpPort, group: (l) => l.deskSetGrpMethods, synonyms: (l) => l.deskSetSynHttpPort, parent: SetId.http),
  if (DeskFeatures.tor) SetEntry(SetId.torPay, DeskRoute.settingsReceiving, label: (l) => l.methodDirectTor, group: (l) => l.deskSetGrpMethods, hint: (l) => l.deskSetRowTorPayHint, info: (l) => l.deskSetRowTorPayInfo, synonyms: (l) => l.deskSetSynTorPay),
  SetEntry(SetId.file, DeskRoute.settingsReceiving, label: (l) => l.deskKitMethodFiles, group: (l) => l.deskSetGrpMethods, hint: (l) => l.deskSetRowFileHint, synonyms: (l) => l.deskSetSynFile),
  SetEntry(SetId.defaultMethod, DeskRoute.settingsReceiving, label: (l) => l.deskSetTxStart, group: (l) => l.deskSetGrpSending, hint: (l) => l.deskSetRowDefaultMethodHint, synonyms: (l) => l.deskSetSynDefaultMethod),
  SetEntry(SetId.strategy, DeskRoute.settingsReceiving, label: (l) => l.deskSetRowStrategy, group: (l) => l.deskSetGrpSending, hint: (l) => l.deskSetRowStrategyHint, info: (l) => l.deskSetRowStrategyInfo, synonyms: (l) => l.deskSetSynStrategy, gate: SetGate(minLevel: 3, features: [AdvancedFeature.sendOptions])),
  SetEntry(SetId.splitChange, DeskRoute.settingsReceiving, label: (l) => l.outputsSplitChange, group: (l) => l.deskSetGrpSending, hint: (l) => l.deskSetRowSplitChangeHint, info: (l) => l.deskSetRowSplitChangeInfo, synonyms: (l) => l.deskSetSynSplitChange, gate: SetGate(minLevel: 3, features: [AdvancedFeature.sendOptions])),
  SetEntry(SetId.confirmations, DeskRoute.settingsReceiving, label: (l) => l.deskSetAdvConfirmations, group: (l) => l.deskSetGrpReceiving, hint: (l) => l.deskSetRowConfirmationsHint, synonyms: (l) => l.deskSetSynConfirmations),
  SetEntry(SetId.pairShop, DeskRoute.settingsInvoices, label: (l) => l.invSetPairShop, hint: (l) => l.deskSetRowPairShopHint, synonyms: (l) => l.deskSetSynPairShop),
  SetEntry(SetId.timeToPay, DeskRoute.settingsInvoices, label: (l) => l.invSetTimeToPay, hint: (l) => l.deskSetRowTimeToPayHint, synonyms: (l) => l.deskSetSynTimeToPay),
  SetEntry(SetId.deviceName, DeskRoute.settingsDevices, label: (l) => l.devicesThisDevice, group: (l) => l.deskSetGrpThisDevice, synonyms: (l) => l.deskSetSynDeviceName),
  SetEntry(SetId.linkDevice, DeskRoute.settingsDevices, label: (l) => l.devicesLink, group: (l) => l.deskSetGrpLinkedDevice, hint: (l) => l.deskSetRowLinkDeviceHint, info: (l) => l.deskSetRowLinkDeviceInfo, synonyms: (l) => l.deskSetSynLinkDevice),
  SetEntry(SetId.pauseSync, DeskRoute.settingsDevices, label: (l) => l.devicesPause, group: (l) => l.deskSetGrpSync, hint: (l) => l.deskSetRowPauseSyncHint, synonyms: (l) => l.deskSetSynPauseSync),
  SetEntry(SetId.theme, DeskRoute.settingsAppearance, label: (l) => l.deskSetAppearTheme, synonyms: (l) => l.deskSetSynTheme),
  SetEntry(SetId.language, DeskRoute.settingsAppearance, label: (l) => l.deskSetAppearLanguage, synonyms: (l) => l.deskSetSynLanguage),
  SetEntry(SetId.scale, DeskRoute.settingsAppearance, label: (l) => l.deskSetAppearScale, hint: (l) => l.deskSetRowScaleHint, synonyms: (l) => l.deskSetSynScale),
  SetEntry(SetId.hideAmounts, DeskRoute.settingsAppearance, label: (l) => l.deskOvHideAmounts, hint: (l) => l.deskSetRowHideAmountsHint, synonyms: (l) => l.deskSetSynHideAmounts),
  SetEntry(SetId.nodeServer, DeskRoute.settingsNode, label: (l) => l.deskSetNodeServer, group: (l) => l.deskSetGrpConnection, hint: (l) => l.deskSetRowNodeServerHint, synonyms: (l) => l.deskSetSynNodeServer),
  SetEntry(SetId.failover, DeskRoute.settingsNode, label: (l) => l.deskSetRowFailover, group: (l) => l.deskSetGrpConnection, hint: (l) => l.deskSetRowFailoverHint, synonyms: (l) => l.deskSetSynFailover),
  SetEntry(SetId.myNode, DeskRoute.settingsNode, label: (l) => l.deskOwnMine, group: (l) => l.deskSetGrpConnection, hint: (l) => l.deskSetRowMyNodeHint, synonyms: (l) => l.deskSetSynMyNode),
  SetEntry(SetId.localNode, DeskRoute.settingsNode, label: (l) => l.deskSetRowLocalNode, group: (l) => l.deskSetGrpLocalNode, hint: (l) => l.deskSetRowLocalNodeHint, synonyms: (l) => l.deskSetSynLocalNode, gate: SetGate(minLevel: 3, features: [AdvancedFeature.builtInNode])),
  SetEntry(SetId.localStart, DeskRoute.settingsNode, label: (l) => l.deskSetLnodeAutostart, group: (l) => l.deskSetGrpLocalNode, hint: (l) => l.deskSetRowLocalStartHint, synonyms: (l) => l.deskSetSynLocalStart, gate: SetGate(minLevel: 3, features: [AdvancedFeature.builtInNode]), parent: SetId.localNode),
  SetEntry(SetId.netMode, DeskRoute.settingsPrivacy, label: (l) => l.deskSetRowNetMode, group: (l) => l.deskSetGrpConnections, synonyms: (l) => DeskFeatures.tor ? l.deskSetSynNetMode : l.deskNoTorSetSynNetMode),
  SetEntry(SetId.statusSite, DeskRoute.settingsPrivacy, label: (l) => l.deskSetPrivUseStatus(statusSiteHost), group: (l) => l.deskSetGrpServerStatus, hint: (l) => l.deskSetRowStatusSiteHint, synonyms: (l) => l.deskSetSynStatusSite),
  SetEntry(SetId.view, DeskRoute.settingsAdvanced, label: (l) => l.deskSetRowView, group: (l) => l.deskSetGrpView, hint: (l) => l.deskSetRowViewHint, synonyms: (l) => l.deskSetSynView),
  SetEntry(SetId.advOutputs, DeskRoute.settingsAdvanced, label: (l) => l.deskSetAdvOutputs, group: (l) => l.deskSetGrpShowsMore, hint: (l) => l.deskSetRowAdvOutputsHint, synonyms: (l) => l.deskSetSynAdvOutputs, gate: SetGate(minLevel: 2)),
  SetEntry(SetId.advTech, DeskRoute.settingsAdvanced, label: (l) => l.deskSetAdvTechnical, group: (l) => l.deskSetGrpShowsMore, hint: (l) => l.deskSetRowAdvTechHint, synonyms: (l) => l.deskSetSynAdvTech, gate: SetGate(minLevel: 2)),
  SetEntry(SetId.advSendopts, DeskRoute.settingsAdvanced, label: (l) => l.deskSetAdvSendOptions, group: (l) => l.deskSetGrpShowsMore, hint: (l) => l.deskSetRowAdvSendoptsHint, synonyms: (l) => l.deskSetSynAdvSendopts, gate: SetGate(minLevel: 2)),
  SetEntry(SetId.advServers, DeskRoute.settingsAdvanced, label: (l) => l.deskSetAdvServerDetails, group: (l) => l.deskSetGrpShowsMore, hint: (l) => l.deskSetRowAdvServersHint, synonyms: (l) => l.deskSetSynAdvServers, gate: SetGate(minLevel: 2)),
  SetEntry(SetId.advHeight, DeskRoute.settingsAdvanced, label: (l) => l.deskSetAdvRecheck, group: (l) => l.deskSetGrpShowsMore, hint: (l) => l.deskSetRowAdvHeightHint, synonyms: (l) => l.deskSetSynAdvHeight, gate: SetGate(minLevel: 2)),
  SetEntry(SetId.advLocal, DeskRoute.settingsAdvanced, label: (l) => l.deskSetAdvBuiltInNode, group: (l) => l.deskSetGrpShowsMore, hint: (l) => l.deskSetRowAdvLocalHint, synonyms: (l) => l.deskSetSynAdvLocal, gate: SetGate(minLevel: 3)),
  SetEntry(SetId.advLogs, DeskRoute.settingsAdvanced, label: (l) => l.deskSetAdvLogs, group: (l) => l.deskSetGrpShowsMore, hint: (l) => l.deskSetRowAdvLogsHint, synonyms: (l) => l.deskSetSynAdvLogs, gate: SetGate(minLevel: 2)),
  SetEntry(SetId.xInvoices, DeskRoute.settingsAdvanced, label: (l) => l.expInvoices, group: (l) => l.deskSetGrpExperiments, hint: (l) => l.deskSetRowXInvoicesHint, synonyms: (l) => l.deskSetSynXInvoices, gate: SetGate(minLevel: 3)),
  SetEntry(SetId.walletRows, DeskRoute.settingsWallets, label: (l) => l.deskSetRowWalletRows, group: (l) => l.deskSetGrpOnComputer, hint: (l) => l.deskSetRowWalletRowsHint, synonyms: (l) => l.deskSetSynWalletRows),
  SetEntry(SetId.createWallet, DeskRoute.settingsWallets, label: (l) => l.deskSetWalletsCreate, group: (l) => l.deskSetGrpAddWallet, hint: (l) => l.deskSetRowCreateWalletHint, synonyms: (l) => l.deskSetSynCreateWallet),
  SetEntry(SetId.importWallets, DeskRoute.settingsWallets, label: (l) => l.deskSetWalletsImport, group: (l) => l.deskSetGrpAddWallet, hint: (l) => l.deskSetRowImportWalletsHint, synonyms: (l) => l.deskSetSynImportWallets),
  SetEntry(SetId.restoreWallet, DeskRoute.settingsWallets, label: (l) => l.deskSetWalletsRestore, group: (l) => l.deskSetGrpAddWallet, hint: (l) => l.deskSetRowRestoreWalletHint, synonyms: (l) => l.deskSetSynRestoreWallet),
  SetEntry(SetId.walletFolder, DeskRoute.settingsFiles, label: (l) => l.deskSetAcctWalletFolder, group: (l) => l.deskSetGrpFolders, hint: (l) => l.deskSetRowWalletFolderHint, synonyms: (l) => l.deskSetSynWalletFolder),
  SetEntry(SetId.appFiles, DeskRoute.settingsFiles, label: (l) => l.deskSetAcctAppFiles, group: (l) => l.deskSetGrpFolders, hint: (l) => l.deskSetRowAppFilesHint, synonyms: (l) => l.deskSetSynAppFiles),
  SetEntry(SetId.logLevel, DeskRoute.settingsFiles, label: (l) => l.deskSetLogsLevel, group: (l) => l.deskSetGrpLogs, hint: (l) => l.deskSetRowLogLevelHint, synonyms: (l) => l.deskSetSynLogLevel, gate: SetGate(features: [AdvancedFeature.logs])),
  SetEntry(SetId.logFiles, DeskRoute.settingsFiles, label: (l) => l.deskSetLogsFiles, group: (l) => l.deskSetGrpLogs, hint: (l) => l.deskSetRowLogFilesHint, synonyms: (l) => l.deskSetSynLogFiles, gate: SetGate(features: [AdvancedFeature.logs])),
  SetEntry(SetId.report, DeskRoute.settingsHelp, label: (l) => l.deskSetReportTitle, group: (l) => l.deskSetGrpSupport, hint: (l) => l.deskSetRowReportHint, synonyms: (l) => l.deskSetSynReport),
  SetEntry(SetId.tour, DeskRoute.settingsHelp, label: (l) => l.deskSetHelpTourAgain, group: (l) => l.deskSetGrpStartAgain, synonyms: (l) => l.deskSetSynTour),
  SetEntry(SetId.setup, DeskRoute.settingsHelp, label: (l) => l.deskSetRowSetup, group: (l) => l.deskSetGrpStartAgain, hint: (l) => l.deskSetRowSetupHint, synonyms: (l) => l.deskSetSynSetup, gate: SetGate(minLevel: 2)),
  SetEntry(SetId.updates, DeskRoute.settingsAbout, label: (l) => l.deskSetAboutUpdates, hint: (l) => l.deskSetRowUpdatesHint, synonyms: (l) => l.deskSetSynUpdates),
  SetEntry(SetId.website, DeskRoute.settingsAbout, label: (l) => l.deskSetRowWebsite, group: (l) => l.deskSetGrpLinks, synonyms: (l) => l.deskSetSynWebsite),
  SetEntry(SetId.source, DeskRoute.settingsAbout, label: (l) => l.deskSetAboutSource, group: (l) => l.deskSetGrpLinks, synonyms: (l) => l.deskSetSynSource),
  SetEntry(SetId.privacyPolicy, DeskRoute.settingsAbout, label: (l) => l.settingsPrivacyPolicy, group: (l) => l.deskSetGrpLinks, synonyms: (l) => l.deskSetSynPrivacyPolicy),
];

final Map<String, SetEntry> _byId = {for (final e in settingsRegistry) e.id: e};

/// The row [id]; null for an id the registry does not list.
SetEntry? settingsEntry(String id) => _byId[id];
