// SPDX-License-Identifier: Apache-2.0
/// What the rest of the app may ask about the directories this wallet joined, without
/// knowing the directory service: the label of one it verified and this wallet's listing key
/// for it. Each app overrides [directoryMembershipProvider] with its open wallet's service.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class DirectoryMembership {
  /// The label of the directory [dkeyHex] (33 bytes, hex) when this wallet verified it, else null.
  String? labelFor(String dkeyHex);

  /// This wallet's listing key text for [dkeyHex] while it is listed there, else null.
  String? listingKeyFor(String dkeyHex);
}

/// No directories: the default, and what a locked wallet has.
class NoDirectoryMembership implements DirectoryMembership {
  const NoDirectoryMembership();

  @override
  String? labelFor(String dkeyHex) => null;

  @override
  String? listingKeyFor(String dkeyHex) => null;
}

final directoryMembershipProvider = Provider<DirectoryMembership>((ref) => const NoDirectoryMembership());
