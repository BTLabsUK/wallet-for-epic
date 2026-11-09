// SPDX-License-Identifier: Apache-2.0
/// The Settings sections in navigation order, what shows each (a view, an Advanced switch),
/// and the words for it: "Deep end view", "Advanced › Outputs". Search, the "more options"
/// control and a deep link to a hidden page all read the gates from here, so they name the
/// same reasons.
library;

import 'package:flutter/widgets.dart' show IconData;
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../advanced.dart';
import '../../../../levels/wallet_level.dart';
import '../../../../ui/levels/level_picker.dart' show levelStopName;
import '../../../data/desk_levels.dart' show deskLevelProvider;
import '../../../desk_l10n.dart';
import '../../../widgets/kit.dart';

/// The navigation's groups: this wallet, the app, this computer, then Help.
enum SetNav { wallet, app, computer, help }

/// What the user sees now: the view (1 Shallow, 2 Deeper, 3 Deep end) and the Advanced
/// switches that are on.
@immutable
class SetView {
  const SetView(this.level, this.features);

  final int level;
  final Set<AdvancedFeature> features;

  bool has(AdvancedFeature f) => features.contains(f);

  @override
  bool operator ==(Object other) =>
      other is SetView && other.level == level && other.features.length == features.length && other.features.containsAll(features);

  @override
  int get hashCode => Object.hash(level, Object.hashAllUnordered(features));
}

/// The view and the stored Advanced switches (not the level's effective ones: a switch that is
/// on still reads as on at Shallow; the view gate says Shallow hides it).
final setViewProvider = Provider<SetView>((ref) {
  final level = ref.watch(deskLevelProvider);
  final adv = ref.watch(deskProvider.select((s) => s.settings.advanced));
  return SetView(level.number, {...adv.features});
});

/// What shows a section, group or row: a view from [minLevel] up and every switch of [features].
@immutable
class SetGate {
  const SetGate({this.minLevel = 1, this.features = const []});

  static const none = SetGate();

  final int minLevel;
  final List<AdvancedFeature> features;

  /// Both gates at once (a row inside a gated group).
  SetGate and(SetGate o) => SetGate(
    minLevel: minLevel > o.minLevel ? minLevel : o.minLevel,
    features: [...features, for (final f in o.features) if (!features.contains(f)) f],
  );

  bool levelOpen(SetView v) => v.level >= minLevel;

  /// The switches still off in [v].
  List<AdvancedFeature> featuresOff(SetView v) => [for (final f in features) if (!v.has(f)) f];

  bool open(SetView v) => levelOpen(v) && featuresOff(v).isEmpty;
}

/// A view's name: Shallow, Deeper, Deep end.
String setViewName(AppLocalizations l, int level) => levelStopName(l, WalletLevel.ofNumber(level) ?? WalletLevel.everything);

/// The Advanced switch's name as Advanced › Shows more lists it.
String setFeatureName(AppLocalizations l, AdvancedFeature f) => switch (f) {
  AdvancedFeature.outputs => l.deskSetAdvOutputs,
  AdvancedFeature.technicalDetails => l.deskSetAdvTechnical,
  AdvancedFeature.sendOptions => l.deskSetAdvSendOptions,
  AdvancedFeature.serverDetails => l.deskSetAdvServerDetails,
  AdvancedFeature.recheckFromHeight => l.deskSetAdvRecheck,
  AdvancedFeature.builtInNode => l.deskSetAdvBuiltInNode,
  AdvancedFeature.logs => l.deskSetAdvLogs,
  AdvancedFeature.transactionFiles => l.advTransactionFiles,
  AdvancedFeature.pairing => l.expPairing,
  AdvancedFeature.invoices => l.invoicesTitle,
  AdvancedFeature.linkedDevices => l.expLinkedDevices,
};

/// Why [gate] is closed in [v], one entry per part: "Deep end view", "Advanced › Outputs".
/// Empty when it is open.
List<String> setGateReasons(AppLocalizations l, SetGate gate, SetView v) => [
  if (!gate.levelOpen(v)) l.deskSetSearchViewGate(setViewName(l, gate.minLevel)),
  for (final f in gate.featuresOff(v)) l.deskSetSearchFeatGate(setFeatureName(l, f)),
];

/// "a", "a and b", "a, b and c": every reason named (review 13).
String setJoinReasons(AppLocalizations l, List<String> reasons) {
  final all = reasons.toSet().toList();
  if (all.isEmpty) return '';
  if (all.length == 1) return all.first;
  return l.deskSetSearchGateJoin(all.sublist(0, all.length - 1).join(', '), all.last);
}

/// A section of Settings: its route, its navigation group and icon, what shows it, and the
/// section whose entry stays selected for a sub-page ([parent]).
@immutable
class SetSection {
  const SetSection(this.route, this.nav, this.icon, {this.gate = SetGate.none, this.parent});

  final DeskRoute route;
  final SetNav nav;
  final IconData icon;
  final SetGate gate;
  final DeskRoute? parent;

  /// The gate with the parent section's.
  SetGate get fullGate => parent == null ? gate : gate.and(setSectionOf(parent!)?.gate ?? SetGate.none);
}

/// Every section in navigation order, each sub-page after its parent.
const List<SetSection> settingsSections = [
  SetSection(DeskRoute.settingsAccount, SetNav.wallet, EIcons.wallet),
  SetSection(DeskRoute.settingsRescan, SetNav.wallet, EIcons.scan, parent: DeskRoute.settingsAccount),
  SetSection(DeskRoute.settingsSecurity, SetNav.wallet, EIcons.shield),
  SetSection(DeskRoute.settingsPhrase, SetNav.wallet, EIcons.key, parent: DeskRoute.settingsSecurity),
  SetSection(DeskRoute.settingsReceiving, SetNav.wallet, EIcons.antenna),
  SetSection(DeskRoute.settingsInvoices, SetNav.wallet, EIcons.invoice, gate: SetGate(minLevel: 3)),
  SetSection(DeskRoute.settingsDevices, SetNav.wallet, EIcons.devices),
  SetSection(DeskRoute.settingsAppearance, SetNav.app, EIcons.palette),
  SetSection(DeskRoute.settingsNode, SetNav.app, EIcons.node, gate: SetGate(minLevel: 2)),
  SetSection(DeskRoute.settingsPrivacy, SetNav.app, EIcons.network, gate: SetGate(minLevel: 2)),
  SetSection(DeskRoute.settingsAdvanced, SetNav.app, EIcons.tune),
  SetSection(DeskRoute.settingsWallets, SetNav.computer, EIcons.coins, gate: SetGate(minLevel: 2)),
  SetSection(DeskRoute.settingsFiles, SetNav.computer, EIcons.folderOpen, gate: SetGate(minLevel: 2)),
  SetSection(DeskRoute.settingsHelp, SetNav.help, EIcons.help),
  SetSection(DeskRoute.settingsAbout, SetNav.help, EIcons.info),
];

/// The section of [route]; null for a route that is no section (Change view, a non-Settings place).
SetSection? setSectionOf(DeskRoute route) {
  for (final s in settingsSections) {
    if (s.route == route) return s;
  }
  return null;
}

/// The entry the navigation keeps selected on [route]: the parent of a sub-page.
DeskRoute setNavRouteOf(DeskRoute route) => setSectionOf(route)?.parent ?? route;

/// A section's name, as its navigation entry and its page title say it.
String settingsSectionLabel(AppLocalizations l, DeskRoute route) => switch (route) {
  DeskRoute.settingsAccount => l.deskSetSecWallet,
  DeskRoute.settingsRescan => l.deskSetFrameRescan,
  DeskRoute.settingsSecurity => l.settingsSectionSecurity,
  DeskRoute.settingsPhrase => l.deskSetFramePhrase,
  DeskRoute.settingsReceiving => l.deskSetFrameTransactions,
  DeskRoute.settingsInvoices => l.deskInvSetTitle,
  DeskRoute.settingsDevices => l.deskSetSecDevices,
  DeskRoute.settingsAppearance => l.deskSetFrameAppearance,
  DeskRoute.settingsNode => l.deskSetFrameNode,
  DeskRoute.settingsPrivacy => l.settingsSectionNetworkPrivacy,
  DeskRoute.settingsAdvanced => l.deskSetFrameAdvanced,
  DeskRoute.settingsWallets => l.deskSetSecWallets,
  DeskRoute.settingsFiles => l.deskSetSecFiles,
  DeskRoute.settingsHelp => l.deskSetFrameHelp,
  DeskRoute.settingsAbout => l.deskSetFrameAbout,
  _ => l.deskSetFrameTitle,
};

/// A navigation group's heading; the wallet's group is headed by the open wallet's name.
String settingsNavLabel(AppLocalizations l, SetNav nav, {String? walletName}) => switch (nav) {
  SetNav.wallet => walletName ?? l.deskSetSecWallet,
  SetNav.app => l.deskSetNavApp,
  SetNav.computer => l.deskSetNavComputer,
  SetNav.help => l.deskSetFrameHelp,
};

/// Where a jump to [route] lands in [v] (review 14). A section the view or a switch hides falls
/// back to the first shown entry of its navigation group (else Wallet), with a [notice] that
/// says what shows it: "Payments shows in the Deeper view." A shown section, or a route that is
/// no section, comes back as it is with no notice.
({DeskRoute route, String? notice}) settingsFallback(AppLocalizations l, SetView v, DeskRoute route) {
  final s = setSectionOf(route);
  if (s == null || s.fullGate.open(v)) return (route: route, notice: null);
  final top = setSectionOf(s.parent ?? route)!;
  var to = DeskRoute.settingsAccount;
  for (final o in settingsSections) {
    if (o.nav == top.nav && o.parent == null && o.gate.open(v)) {
      to = o.route;
      break;
    }
  }
  final page = settingsSectionLabel(l, top.route);
  final gate = s.fullGate;
  final notice = !gate.levelOpen(v)
      ? l.deskSetSearchFallbackView(page, setViewName(l, gate.minLevel))
      : l.deskSetSearchFallbackFeat(page, setFeatureName(l, gate.featuresOff(v).first));
  return (route: to, notice: notice);
}
