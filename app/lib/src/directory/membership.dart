// SPDX-License-Identifier: Apache-2.0
/// What this wallet knows of the directories it joined: the seam between payment links (Send)
/// and directory pairing. The default knows none.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class DirectoryMembership {
  /// The directory contact's label when this wallet verified the directory whose `dkey` is
  /// [dkeyHex] (lower-case hex of the 33 bytes); null when it did not.
  String? labelFor(String dkeyHex);

  /// This wallet's listing key text for that directory (the `09 for` check); null when it has
  /// no listing there.
  String? listingKeyFor(String dkeyHex);
}

/// A wallet that joined no directory.
class NoDirectoryMembership implements DirectoryMembership {
  const NoDirectoryMembership();

  @override
  String? labelFor(String dkeyHex) => null;

  @override
  String? listingKeyFor(String dkeyHex) => null;
}

final directoryMembershipProvider = Provider<DirectoryMembership>((ref) => const NoDirectoryMembership());
