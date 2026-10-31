// SPDX-License-Identifier: Apache-2.0
/// What the desktop UI shows that the wallet core (LEPIC) or the app cannot do yet. Every spot
/// of a false flag is hidden, not faked: a screen, row, segment, menu item, status line or
/// onboarding path. The adapter (`lepic_desk_wallet.dart`) throws [UnsupportedError] for the
/// methods behind a false flag. Flip a flag once its adapter method is real.
///
/// The hidden spots, by flag:
///
/// dataFolder: Welcome › Advanced › App data folder.
/// testNetworks ("any network each"): Welcome › Advanced › Network. Mainnet only.
/// tor: Send › Tor (an onion pasted anywhere switches there; Turn on Tor receiving
///   while off), Receive's Tor address with Copy and QR,
///   Settings › Transactions › Tor receiving (per wallet, off by default, its state and Retry),
///   the status card's and Overview's Tor line, .onion addresses in contacts, the Help topic.
///   Needs the bundled tor (bin/tor-bundle beside the app, tools/fetch-tor.sh); without it
///   the row says "Not in this build" and its switch is disabled. The build without Tor
///   (`WFE_TOR=false`, [torBuilt]) turns the flag off.
/// nodeBackground: Settings › Node's "Sync in background" for the built-in node.
/// dandelion: Send's Dandelion++ switch and the review's Privacy line.
/// paymentProofs: Transaction details › Export proof.
///
/// App-side, not in 0.1.0 (no core change needed):
/// contactPictures: the contact form's picture and the list's photos (initials stay).
library;

import '../../tor_build.dart';
import '../../demo.dart' show devNetworksBuild;

abstract final class DeskFeatures {
  static const bool dataFolder = false;
  static const bool testNetworks = devNetworksBuild;
  /// Off in the build without Tor ([torBuilt]).
  static const bool tor = torBuilt;
  static const bool nodeBackground = false;
  static const bool dandelion = false;
  static const bool paymentProofs = false;
  static const bool contactPictures = false;
}
