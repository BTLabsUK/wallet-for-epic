// SPDX-License-Identifier: Apache-2.0
/// Settings › Donate (desktop) and Settings › Donate (phone), item 4: BT Labs' donation address
/// with Copy and QR, and BT Labs' contact in this wallet's Contacts when it is there. The page
/// asks nothing on the network: the address comes from the signed btlabs.json already read, or
/// `[support] donation` of `app-config.toml`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'seed_contacts.dart' show btLabsContact;
import 'settings_file/host_settings.dart';
import 'settings_file/settings_providers.dart' show hostSettingsProvider;

/// What Donate offers: the donation address, null when `app-config.toml` names none.
class DonateLink {
  const DonateLink({this.address});

  /// [settings]' donation address.
  factory DonateLink.of(HostSettings settings) => DonateLink(
    // The signed btlabs.json's address when one verified, as the BT Labs contact shows it.
    address: (hostSettingsLoaded ? btLabsContact?.address : null) ?? settings.supportDonation,
  );

  /// The Epicbox address donations go to.
  final String? address;

  /// Anything to show: Donate's entry is hidden without it.
  bool get any => address != null;
}

/// Donate's address, following the settings files as they change.
final donateLinkProvider = Provider<DonateLink>((ref) => DonateLink.of(ref.watch(hostSettingsProvider)));

/// The contact among [contacts] that holds the donation [address] (BT Labs' seed contact, or
/// one the user saved with it); null when none does, e.g. the user deleted it.
C? donateContactIn<C>(Iterable<C> contacts, String? address, String? Function(C c) epicbox) {
  if (address == null) return null;
  for (final c in contacts) {
    if (epicbox(c) == address) return c;
  }
  return null;
}
