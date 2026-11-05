// SPDX-License-Identifier: Apache-2.0
/// What the rest of the app may ask about the name services this wallet joined, without
/// knowing the name service service: the label of one it verified and this wallet's listing key
/// for it. Each app overrides [nameServiceMembershipProvider] with its open wallet's service.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class NameServiceMembership {
  /// The label of the name service [serviceKeyHex] (33 bytes, hex) when this wallet verified it, else null.
  String? labelFor(String serviceKeyHex);

  /// This wallet's listing key text for [serviceKeyHex] while it is listed there, else null.
  String? listingKeyFor(String serviceKeyHex);
}

/// No name services: the default, and what a locked wallet has.
class NoNameServiceMembership implements NameServiceMembership {
  const NoNameServiceMembership();

  @override
  String? labelFor(String serviceKeyHex) => null;

  @override
  String? listingKeyFor(String serviceKeyHex) => null;
}

final nameServiceMembershipProvider = Provider<NameServiceMembership>((ref) => const NoNameServiceMembership());
