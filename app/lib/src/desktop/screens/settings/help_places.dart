/// Where a place in Help goes on the desktop: `Settings › Privacy › Tor` is the Privacy page with
/// the Tor switch flashed. [deskHelpPlace] is pure, so a test can hold every link in Help to a
/// page that exists.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
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
  'Settings › Transactions': _page(DeskRoute.settingsReceiving),
  'Settings › Transactions › Epicbox receiving': _page(DeskRoute.settingsReceiving, jump: SettingsJump.epicbox),
  'Settings › Privacy': _page(DeskRoute.settingsPrivacy),
  'Settings › Privacy › Tor': _page(DeskRoute.settingsPrivacy, jump: SettingsJump.tor),
  'Settings › Invoices': _page(DeskRoute.settingsInvoices),
  'Settings › This wallet': _page(DeskRoute.settingsAccount),
  'Settings › This wallet › Export history backup': _page(DeskRoute.settingsAccount),
  'Settings › This wallet › Wallet folder': _page(DeskRoute.settingsAccount),
  'Settings › This wallet › App files': _page(DeskRoute.settingsAccount),
  'Settings › All wallets': _page(DeskRoute.settingsWallets),
  'Settings › Recovery phrase': _page(DeskRoute.settingsPhrase),
  'Settings › Recheck balance': _page(DeskRoute.settingsRescan),
};

/// The page for [place] (the English place a help link carries), or null when the desktop has
/// none: such a place must not be written as a link.
DeskHelpPlace? deskHelpPlace(String place) => _places[place.split('›').map((p) => p.trim()).join(' › ')];

/// The places that belong to a part Advanced hides: the Outputs page, the pairing and the
/// invoice places (Experimental).
AdvancedFeature? _placeFeature(DeskHelpPlace to) => switch (to.route) {
  DeskRoute.outputs => AdvancedFeature.outputs,
  DeskRoute.pair || DeskRoute.pairPending => AdvancedFeature.pairing,
  DeskRoute.invoices || DeskRoute.invoiceIssue || DeskRoute.invoiceReview || DeskRoute.settingsInvoices =>
    AdvancedFeature.invoices,
  _ => null,
};

/// Whether Help may link [place]: the desktop has the page and Advanced shows it. A place of a
/// hidden part reads as a term instead.
bool deskHelpPlaceShown(WidgetRef ref, String place) {
  final to = deskHelpPlace(place);
  if (to == null) return false;
  final f = _placeFeature(to);
  return switch (f) {
    null => true,
    AdvancedFeature.pairing => advancedOf(ref).pairingOn,
    AdvancedFeature.invoices => advancedOf(ref).invoicesOn,
    _ => advancedHas(ref, f),
  };
}

/// Goes to [place].
void openDeskHelpPlace(WidgetRef ref, String place) {
  final to = deskHelpPlace(place);
  if (to == null) return;
  final jump = to.jump;
  if (jump != null) {
    // Goes to the page itself, scrolled to the section and flashed.
    ref.read(settingsPrefsProvider.notifier).jumpTo(jump);
  } else {
    ref.read(deskNavProvider.notifier).go(to.route, to.arg);
  }
}
