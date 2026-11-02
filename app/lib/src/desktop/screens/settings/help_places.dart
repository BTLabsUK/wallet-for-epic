// SPDX-License-Identifier: Apache-2.0
/// Where a place in Help goes on the desktop: `Settings › Network & privacy › Tor` is that page with
/// the Tor switch flashed. [deskHelpPlace] is pure, so a test can hold every link in Help to a
/// page that exists.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/desk_levels.dart' show deskLevelUiProvider;
import 'prefs.dart';
import 'settings_advanced.dart' show advancedHas, advancedOf, AdvancedFeature;

/// The page a help place opens, and the section of it to flash (null for none).
typedef DeskHelpPlace = ({DeskRoute route, SettingsJump? jump, Object? arg});

DeskHelpPlace _page(DeskRoute route, {SettingsJump? jump, Object? arg}) => (route: route, jump: jump, arg: arg);

/// Every place Help names, as written in English: the sidebar, Settings and its pages, and the
/// parts of a page.
final Map<String, DeskHelpPlace> _places = {
  'Receive': _page(DeskRoute.receive),
  'Receive › Transaction files › Sign a transaction file': _page(DeskRoute.importTx),
  'Receive › Transaction files › Finalize a response file': _page(DeskRoute.finalize),
  'Send': _page(DeskRoute.send),
  'Activity': _page(DeskRoute.activity),
  'Activity › the transaction › Cancel': _page(DeskRoute.activity),
  'Outputs': _page(DeskRoute.outputs),
  'Contacts': _page(DeskRoute.contacts),
  'Invoices': _page(DeskRoute.invoices),
  'Invoices › Pay': _page(DeskRoute.invoices, arg: InvoicesTab.pay),
  'Invoices › Issue': _page(DeskRoute.invoices, arg: InvoicesTab.issue),
  'Outputs › Manage outputs': _page(DeskRoute.outputs),
  'Settings › Node': _page(DeskRoute.settingsNode, jump: SettingsJump.node),
  // The Settings structure of 26.10.25: the wallet's pages, the app's, this computer's.
  'Settings › Wallet': _page(DeskRoute.settingsAccount),
  'Settings › Wallet › Export wallet data': _page(DeskRoute.settingsAccount),
  'Settings › Wallet › Recheck balance': _page(DeskRoute.settingsRescan),
  'Settings › Security': _page(DeskRoute.settingsSecurity),
  'Settings › Security › Recovery phrase': _page(DeskRoute.settingsPhrase),
  'Settings › Payments': _page(DeskRoute.settingsReceiving),
  'Settings › Payments › Epicbox': _page(DeskRoute.settingsReceiving, jump: SettingsJump.epicbox),
  'Settings › Payments › Confirmations': _page(DeskRoute.settingsReceiving, jump: SettingsJump.confirmations),
  'Settings › Invoices': _page(DeskRoute.settingsInvoices),
  'Settings › Linked devices': _page(DeskRoute.settingsDevices),
  // Network & privacy (B-03): the mode, Tor and the status site on one page.
  'Settings › Network & privacy': _page(DeskRoute.settingsPrivacy, jump: SettingsJump.network),
  'Settings › Network & privacy › Tor': _page(DeskRoute.settingsPrivacy, jump: SettingsJump.tor),
  'Settings › Wallets': _page(DeskRoute.settingsWallets),
  'Settings › Advanced': _page(DeskRoute.settingsAdvanced),
  'Settings › Files & logs': _page(DeskRoute.settingsFiles),
  'Settings › Files & logs › Wallet folder': _page(DeskRoute.settingsFiles),
  'Settings › Files & logs › App files': _page(DeskRoute.settingsFiles),
};

/// The page for [place] (the English place a help link carries), or null when the desktop has
/// none: such a place must not be written as a link.
DeskHelpPlace? deskHelpPlace(String place) => _places[place.split('›').map((p) => p.trim()).join(' › ')];

/// The places that belong to a part Advanced hides: the Outputs page, the pairing and the
/// invoice places (Experimental).
AdvancedFeature? _placeFeature(DeskHelpPlace to) => switch (to.route) {
  DeskRoute.outputs => AdvancedFeature.outputs,
  DeskRoute.pair => AdvancedFeature.pairing,
  DeskRoute.invoices || DeskRoute.invoiceIssue || DeskRoute.invoiceReview || DeskRoute.settingsInvoices =>
    AdvancedFeature.invoices,
  _ => null,
};

/// Whether Help may link [place]: the desktop has the page, the level shows it and Advanced
/// shows it. A place of a hidden part reads as a term instead.
bool deskHelpPlaceShown(WidgetRef ref, String place) {
  final to = deskHelpPlace(place);
  if (to == null) return false;
  final ui = ref.watch(deskLevelUiProvider);
  if (deskLevelHides(ui, to.route)) return false;
  if (to.route == DeskRoute.outputs && !ui.outputsPage) return false;
  final f = _placeFeature(to);
  return switch (f) {
    null => true,
    AdvancedFeature.invoices => advancedOf(ref).invoicesOn,
    _ => advancedHas(ref, f),
  };
}

/// Goes to [place].
void openDeskHelpPlace(WidgetRef ref, String place) {
  final to = deskHelpPlace(place);
  // A page the level hides is never opened (a link written before the level changed).
  if (to == null || deskLevelHides(ref.read(deskLevelUiProvider), to.route)) return;
  final jump = to.jump;
  if (jump != null) {
    // Goes to the page itself, scrolled to the section and flashed.
    ref.read(settingsPrefsProvider.notifier).jumpTo(jump);
  } else {
    ref.read(deskNavProvider.notifier).go(to.route, to.arg);
  }
}
