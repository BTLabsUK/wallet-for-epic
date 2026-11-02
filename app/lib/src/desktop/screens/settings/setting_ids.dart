// SPDX-License-Identifier: Apache-2.0
/// The ids of the Settings rows: one per row, the same as the redesign's prototype
/// (`data.js`). A page's row carries its id as `ESetRow(anchor: SetId.x)`; the settings
/// registry (`data/settings_registry.dart`) lists every id once, so search finds the row and
/// jumps to it. `test/desktop/settings_registry_test.dart` fails when a page's anchor is missing
/// from the registry or the registry names a row no page has.
library;

abstract final class SetId {
  // Wallet
  static const name = 'name';
  static const exportData = 'exportData';
  static const importData = 'importData';
  static const exportCsv = 'exportCsv';
  static const recheckGo = 'recheckGo';
  static const deleteWallet = 'deleteWallet';

  // Wallet › Recheck balance
  static const recheckFrom = 'recheckFrom';
  static const recheckMonth = 'recheckMonth';
  static const recheckHeight = 'recheckHeight';
  static const recheckDrop = 'recheckDrop';

  // Security
  static const phraseGo = 'phraseGo';
  static const password = 'password';
  static const remembered = 'remembered';
  static const autolock = 'autolock';

  // Payments
  static const epicbox = 'epicbox';
  static const epicboxRecv = 'epicboxRecv';
  static const epicboxServer = 'epicboxServer';
  static const epicboxStart = 'epicboxStart';
  static const http = 'http';
  static const httpReach = 'httpReach';
  static const httpPort = 'httpPort';
  static const torPay = 'torPay';
  static const file = 'file';
  static const defaultMethod = 'defaultMethod';
  static const strategy = 'strategy';
  static const splitChange = 'splitChange';
  static const confirmations = 'confirmations';

  // Invoices
  static const pairShop = 'pairShop';
  static const timeToPay = 'timeToPay';

  // Linked devices
  static const deviceName = 'deviceName';
  static const linkDevice = 'linkDevice';
  static const pauseSync = 'pauseSync';

  // Appearance
  static const theme = 'theme';
  static const language = 'language';
  static const scale = 'scale';
  static const hideAmounts = 'hideAmounts';

  // Node
  static const nodeServer = 'nodeServer';
  static const failover = 'failover';
  static const myNode = 'myNode';
  static const localNode = 'localNode';
  static const localStart = 'localStart';

  // Network & privacy
  static const netMode = 'netMode';

  /// The old "Tor for all connections" row, gone (Tor only is the one whole-wallet Tor control);
  /// in no page, search or [all].
  static const torAll = 'torAll';
  static const statusSite = 'statusSite';

  // Advanced
  static const view = 'view';
  static const advOutputs = 'adv_outputs';
  static const advTech = 'adv_tech';
  static const advSendopts = 'adv_sendopts';
  static const advServers = 'adv_servers';
  static const advHeight = 'adv_height';
  static const advLocal = 'adv_local';
  static const advLogs = 'adv_logs';
  static const xInvoices = 'x_invoices';

  // Wallets
  static const walletRows = 'walletRows';
  static const createWallet = 'createWallet';
  static const importWallets = 'importWallets';
  static const restoreWallet = 'restoreWallet';

  // Files & logs
  static const walletFolder = 'walletFolder';
  static const appFiles = 'appFiles';
  static const logLevel = 'logLevel';
  static const logFiles = 'logFiles';

  // Help
  static const report = 'report';
  static const tour = 'tour';
  static const setup = 'setup';

  // About
  static const updates = 'updates';
  static const website = 'website';
  static const source = 'source';
  static const privacyPolicy = 'privacyPolicy';
  static const contact = 'contact';

  /// Every id, in the order of the Settings navigation.
  static const all = [name, exportData, importData, exportCsv, recheckGo, deleteWallet, recheckFrom, recheckMonth, recheckHeight, recheckDrop, phraseGo, password, remembered, autolock, epicbox, epicboxRecv, epicboxServer, epicboxStart, http, httpReach, httpPort, torPay, file, defaultMethod, strategy, splitChange, confirmations, pairShop, timeToPay, deviceName, linkDevice, pauseSync, theme, language, scale, hideAmounts, nodeServer, failover, myNode, localNode, localStart, netMode, statusSite, view, advOutputs, advTech, advSendopts, advServers, advHeight, advLocal, advLogs, xInvoices, walletRows, createWallet, importWallets, restoreWallet, walletFolder, appFiles, logLevel, logFiles, report, tour, setup, updates, website, source, privacyPolicy, contact];
}
