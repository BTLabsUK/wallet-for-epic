// SPDX-License-Identifier: Apache-2.0
/// The phone tour's steps: one per screen, in order. Every target is on its screen with
/// Advanced off ([AdvancedPrefs.none]), and no step switches anything on.
library;

import '../../l10n.dart';
import '../../tor_build.dart';

/// Where a step happens: the three tabs of Home, or a screen opened over it.
enum TourPlace {
  wallet,
  send,
  receive,
  activity,
  invoices,
  devices,
  privacy,
  advanced,
  help,
}

/// One step: the [place] it opens, the [PhoneTourTarget] ids it lights (their union; the card
/// has nothing lit when none is on screen), and its words.
class PhoneTourStep {
  const PhoneTourStep({
    required this.place,
    required this.targets,
    required this.titleOf,
    required this.textOf,
  });

  final TourPlace place;
  final List<String> targets;
  final String Function(AppLocalizations l) titleOf;
  final String Function(AppLocalizations l) textOf;
}

/// The steps: what the wallet holds (Wallet, Send, Receive, Activity, Invoices when the wallet
/// [invoices] as the desktop does, Linked devices while [devices] is on), then where it is set up
/// (Network & privacy, Advanced) and Help. No Contacts step: on a new wallet its list is empty.
List<PhoneTourStep> phoneTourSteps({required bool invoices, bool devices = true}) => [
  PhoneTourStep(
    place: TourPlace.wallet,
    targets: const ['tour-balance'],
    titleOf: (l) => l.tourPhoneWalletTitle,
    textOf: (l) => torBuilt ? l.tourPhoneWalletText : l.tourPhoneWalletTextNoTor,
  ),
  PhoneTourStep(
    place: TourPlace.send,
    // Without coins the Send tab says so and offers nothing else: that is what is lit.
    targets: const ['tour-send-methods', 'tour-send-recipient', 'tour-send-empty'],
    titleOf: (l) => l.tourPhoneSendTitle,
    textOf: (l) => l.tourPhoneSendText,
  ),
  PhoneTourStep(
    place: TourPlace.receive,
    targets: const ['tour-receive-address'],
    titleOf: (l) => l.tourPhoneReceiveTitle,
    textOf: (l) => l.tourPhoneReceiveText,
  ),
  PhoneTourStep(
    place: TourPlace.activity,
    targets: const ['tour-activity-list'],
    titleOf: (l) => l.tourPhoneActivityTitle,
    textOf: (l) => l.tourPhoneActivityText,
  ),
  if (invoices)
    PhoneTourStep(
      place: TourPlace.invoices,
      targets: const ['tour-invoices-tabs'],
      titleOf: (l) => l.tourPhoneInvoicesTitle,
      textOf: (l) => l.tourPhoneInvoicesText,
    ),
  if (devices)
    PhoneTourStep(
      place: TourPlace.devices,
      targets: const ['tour-devices-link'],
      titleOf: (l) => l.expLinkedDevices,
      textOf: (l) => l.tourPhoneDevicesText,
    ),
  PhoneTourStep(
    place: TourPlace.privacy,
    targets: const ['tour-privacy-modes', 'tour-privacy-tor', 'tour-privacy-servers'],
    titleOf: (l) => l.settingsSectionNetworkPrivacy,
    textOf: (l) => torBuilt ? l.tourPhoneNetworkText : l.tourPhoneNetworkTextNoTor,
  ),
  PhoneTourStep(
    place: TourPlace.advanced,
    targets: const ['tour-advanced-top'],
    titleOf: (l) => l.tourPhoneAdvancedTitle,
    textOf: (l) => l.tourAdvancedShowsText,
  ),
  PhoneTourStep(
    place: TourPlace.help,
    targets: const ['tour-help-feedback', 'tour-help-search'],
    titleOf: (l) => l.tourPhoneHelpTitle,
    textOf: (l) => l.tourPhoneHelpText,
  ),
];
