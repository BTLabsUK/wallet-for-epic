// SPDX-License-Identifier: Apache-2.0
/// What each [WalletLevel] shows: the visibility matrix as one pure model the phone (and later
/// the desktop) binds to. Presentation only: a level never changes wallet data. The one write
/// is [levelPreset], applied when the user picks level 3.
///
/// Level 3 is today's app (effective prefs = the stored prefs, today's words); level 2 is the
/// same with casual words; level 1 is the quiet shell.
library;

import '../advanced.dart';
import '../payment_method.dart';
import 'wallet_level.dart';

/// How the words read.
enum LevelWording {
  /// Level 1: plain, no jargon.
  plain,

  /// Level 2: casual.
  casual,

  /// Level 3: today's words.
  technical,
}

/// The status icons of the Home strip.
enum StatusIcon { network, epicbox, tor, http }

/// What Settings › Advanced holds.
enum AdvancedPageKind {
  /// Only the Change level row.
  changeLevelOnly,

  /// Today's page.
  full,
}

/// How invoices are present.
enum InvoicePresence {
  /// No invoices.
  off,

  /// The engine runs and an incoming invoice notice works; no invoice screens are offered.
  quiet,

  /// Invoices show as today.
  shown,
}

/// How a payment's progress is drawn.
enum TimelineStyle { liveSentence, casualSteps, technicalSteps }

/// The buttons on a transaction.
enum TxActionSet {
  /// Cancel only.
  cancelOnly,

  /// Cancel, Broadcast again, Release funds.
  full,
}

/// The Activity filter chips.
enum ActivityChips {
  /// All, Sent, Received.
  basic,

  /// And Pending, Cancelled.
  full,
}

/// What stands under Home's balance figure: nothing but the row of icons and the fiat value
/// (level 1), or the tiles with every balance that is not spendable.
enum BalancePresentation { figure, tiles }

/// [prefs] as [level] shows them. Level 1 hides every shown feature, keeps the pairing and
/// invoices engine on (the listener runs, invoices are quiet), keeps the network mode (Tor only
/// must survive) and forces node failover on; levels 2 and 3 are the stored prefs.
AdvancedPrefs effectiveAdvanced(WalletLevel level, AdvancedPrefs prefs) {
  if (level != WalletLevel.justSendReceive) return prefs;
  return AdvancedPrefs(
    features: {
      AdvancedFeature.pairing,
      AdvancedFeature.invoices,
      AdvancedFeature.linkedDevices,
    },
    networkMode: prefs.networkMode,
    nodeFailover: true,
  );
}

/// The prefs after the user picks [to]. Level 3 turns on every non-experimental feature;
/// experimental features, the network mode and node failover are untouched. Levels 1 and 2
/// never switch off what the user turned on. Only an explicit pick calls this, never launch
/// or migration.
AdvancedPrefs levelPreset(WalletLevel to, AdvancedPrefs prefs) {
  if (to != WalletLevel.everything) return prefs;
  return AdvancedPrefs(
    features: {...prefs.features, ...AdvancedFeature.values.where((f) => !experimentalFeatures.contains(f))},
    networkMode: prefs.networkMode,
    nodeFailover: prefs.nodeFailover,
  );
}

/// The matrix row of one level.
class LevelFeatures {
  const LevelFeatures._({
    required this.level,
    required this.advanced,
    required this.wording,
    required this.sendMethods,
    required this.epicboxNamed,
    required this.qrAsQuietLink,
    required this.methodStrip,
    required this.statusIcons,
    required this.serverNames,
    required this.serverSettings,
    required this.transactionsSettings,
    required this.advancedPage,
    required this.pairingListener,
    required this.pairingSetupScreens,
    required this.incomingPairingPrompt,
    required this.invoices,
    required this.linkedDevices,
    required this.timeline,
    required this.technicalDetails,
    required this.explorerLink,
    required this.labels,
    required this.txActions,
    required this.activityChips,
    required this.balanceTiles,
    required this.welcomeServerLink,
    required this.outputs,
    required this.fileTransfer,
    required this.linkPayments,
    required this.nodeAutomatic,
    required this.undercoverOffered,
  });

  /// The row for [level] with the user's stored [prefs]; [torBuilt] is whether this build has Tor.
  factory LevelFeatures.of(WalletLevel level, AdvancedPrefs prefs, {required bool torBuilt}) {
    final one = level == WalletLevel.justSendReceive;
    final eff = effectiveAdvanced(level, prefs);
    return LevelFeatures._(
      level: level,
      advanced: eff,
      wording: switch (level) {
        WalletLevel.justSendReceive => LevelWording.plain,
        WalletLevel.casual => LevelWording.casual,
        WalletLevel.everything => LevelWording.technical,
      },
      sendMethods: one ? const {MethodKind.epicbox, MethodKind.directQr} : MethodKind.values.toSet(),
      epicboxNamed: !one,
      qrAsQuietLink: one,
      methodStrip: !one,
      statusIcons: one ? const {StatusIcon.network, StatusIcon.epicbox} : StatusIcon.values.toSet(),
      serverNames: !one,
      serverSettings: !one,
      transactionsSettings: !one,
      advancedPage: one ? AdvancedPageKind.changeLevelOnly : AdvancedPageKind.full,
      pairingListener: true,
      pairingSetupScreens: !one,
      incomingPairingPrompt: true,
      invoices: one
          ? InvoicePresence.quiet
          : prefs.invoicesOn
              ? InvoicePresence.shown
              : InvoicePresence.off,
      // Every level (item 10): an experiment, shown to all.
      linkedDevices: true,
      timeline: switch (level) {
        WalletLevel.justSendReceive => TimelineStyle.liveSentence,
        WalletLevel.casual => TimelineStyle.casualSteps,
        WalletLevel.everything => TimelineStyle.technicalSteps,
      },
      technicalDetails: !one && prefs.has(AdvancedFeature.technicalDetails),
      explorerLink: !one,
      labels: !one,
      txActions: one ? TxActionSet.cancelOnly : TxActionSet.full,
      activityChips: one ? ActivityChips.basic : ActivityChips.full,
      balanceTiles: one ? BalancePresentation.figure : BalancePresentation.tiles,
      welcomeServerLink: !one,
      outputs: !one && prefs.has(AdvancedFeature.outputs),
      fileTransfer: !one,
      linkPayments: !one,
      nodeAutomatic: one,
      undercoverOffered: torBuilt,
    );
  }

  final WalletLevel level;

  /// The Advanced prefs this level shows ([effectiveAdvanced]).
  final AdvancedPrefs advanced;

  /// How the words read.
  final LevelWording wording;

  /// The methods the level may offer; the payment switches still apply on top.
  final Set<MethodKind> sendMethods;

  /// Epicbox is named in the UI.
  final bool epicboxNamed;

  /// QR Payment is a quiet link under Send / Receive, not a method chip.
  final bool qrAsQuietLink;

  /// Send's step-1 method strip and Receive's method tabs.
  final bool methodStrip;

  /// The status icons on Home.
  final Set<StatusIcon> statusIcons;

  /// The status tooltip reads "Network · OK".
  final bool statusTooltipNameState = true;

  /// Tapping a status icon opens its details.
  final bool statusTapOpensDetails = true;

  /// Host names are shown anywhere.
  final bool serverNames;

  /// Settings › Privacy & network (node, Epicbox, Tor, modes, kill switch).
  final bool serverSettings;

  /// Settings › Transactions (method switches, default method, confirmations).
  final bool transactionsSettings;

  /// What Settings › Advanced holds.
  final AdvancedPageKind advancedPage;

  /// The pairing mailbox is collected while a wallet is open, even with Experimental off.
  final bool pairingListener;

  /// Pair flows and paired-contact management.
  final bool pairingSetupScreens;

  /// An incoming pairing notice offers the Accept / Not now sheet.
  final bool incomingPairingPrompt;

  /// How invoices are present.
  final InvoicePresence invoices;

  /// Linked devices show at every level (item 10).
  final bool linkedDevices;

  /// How a payment's progress is drawn.
  final TimelineStyle timeline;

  /// Live payment steps on Send and Receive.
  final bool liveSendTimeline = true;

  /// Technical rows on transactions.
  final bool technicalDetails;

  /// The explorer link on a transaction.
  final bool explorerLink;

  /// Transaction labels (level 1 only has "Add a note", which the UI keeps by itself).
  final bool labels;

  /// The buttons on a transaction.
  final TxActionSet txActions;

  /// The Activity filter chips.
  final ActivityChips activityChips;

  /// The figure alone or the balance tiles under it.
  final BalancePresentation balanceTiles;

  /// Welcome's "Node and Epicbox" link.
  final bool welcomeServerLink;

  /// The Outputs page.
  final bool outputs;

  /// File transfer may be offered; PaymentPrefs and Advanced decide on top.
  final bool fileTransfer;

  /// Link · HTTP / Link · Tor.
  final bool linkPayments;

  /// The node is never shown and failover is forced on.
  final bool nodeAutomatic;

  /// A relay down for [relaySwitchAfter] is offered a one-tap switch to the next healthy one, at
  /// every level, never switched silently: a move changes the wallet's Epicbox address
  /// (`relay_switch_providers.dart`, desktop `desk_relay_switch.dart`).
  bool get relaySwitchPrompt => true;

  /// The Tor-only row on the first-start step and Change level.
  final bool undercoverOffered;

  @override
  bool operator ==(Object other) =>
      other is LevelFeatures &&
      other.level == level &&
      other.advanced == advanced &&
      other.wording == wording &&
      other.sendMethods.length == sendMethods.length &&
      other.sendMethods.containsAll(sendMethods) &&
      other.epicboxNamed == epicboxNamed &&
      other.qrAsQuietLink == qrAsQuietLink &&
      other.methodStrip == methodStrip &&
      other.statusIcons.length == statusIcons.length &&
      other.statusIcons.containsAll(statusIcons) &&
      other.serverNames == serverNames &&
      other.serverSettings == serverSettings &&
      other.transactionsSettings == transactionsSettings &&
      other.advancedPage == advancedPage &&
      other.pairingListener == pairingListener &&
      other.pairingSetupScreens == pairingSetupScreens &&
      other.incomingPairingPrompt == incomingPairingPrompt &&
      other.invoices == invoices &&
      other.linkedDevices == linkedDevices &&
      other.timeline == timeline &&
      other.technicalDetails == technicalDetails &&
      other.explorerLink == explorerLink &&
      other.labels == labels &&
      other.txActions == txActions &&
      other.activityChips == activityChips &&
      other.balanceTiles == balanceTiles &&
      other.welcomeServerLink == welcomeServerLink &&
      other.outputs == outputs &&
      other.fileTransfer == fileTransfer &&
      other.linkPayments == linkPayments &&
      other.nodeAutomatic == nodeAutomatic &&
      other.undercoverOffered == undercoverOffered;

  @override
  int get hashCode => Object.hashAll([
    level,
    advanced,
    wording,
    Object.hashAllUnordered(sendMethods),
    Object.hashAllUnordered(statusIcons),
    epicboxNamed,
    qrAsQuietLink,
    methodStrip,
    serverNames,
    serverSettings,
    transactionsSettings,
    advancedPage,
    pairingListener,
    pairingSetupScreens,
    incomingPairingPrompt,
    invoices,
    linkedDevices,
    timeline,
    technicalDetails,
    explorerLink,
    labels,
    txActions,
    activityChips,
    balanceTiles,
    welcomeServerLink,
    outputs,
    fileTransfer,
    linkPayments,
    nodeAutomatic,
    undercoverOffered,
  ]);
}
