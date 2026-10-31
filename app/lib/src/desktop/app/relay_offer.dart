// SPDX-License-Identifier: Apache-2.0
/// The Epicbox server offer on the desktop (wallet levels, Shallow): the rules are the phone's
/// (`levels/relay_switch.dart`). The server in use has not answered for a while and another of
/// the list is seen healthy: a notice names it by its address ("Switch to" and the domain), the
/// Epicbox popover carries the same offer, nothing moves until the user accepts. After the move
/// "Now on" with the domain offers Show new address, and Receive shows the new address once.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../levels/relay_switch.dart' show RelaySwitchOffer;
import '../../levels/relay_switch_providers.dart' show RelaySwitchResult;

/// The offer, or null.
final deskRelayOfferProvider = Provider<RelaySwitchOffer?>((ref) => null);

/// The last move, for Receive's "Your new address" and the "Now on" notice; null when none.
final deskRelayMovedProvider = Provider<RelaySwitchResult?>((ref) => null);

/// The offer's and the move's notice, docked with the shell's notices.
class DeskRelayNotice extends ConsumerWidget {
  const DeskRelayNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}

/// The offer inside the Epicbox status popover.
class DeskRelayOfferPanel extends ConsumerWidget {
  const DeskRelayOfferPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
