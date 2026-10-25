/// The relay the phone offers instead of one this network blocks ([ListenerState.blocked]),
/// and the one-tap switch to it (Receive, the Epicbox server list).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network.dart';
import 'providers.dart';
import 'public_servers.dart';
import 'relay_block.dart';
import 'relay_directory.dart';
import 'server_list_store.dart' show builtInRelaysFor;
import 'server_switch.dart';

/// The relay to switch to while this network blocks the wallet's relay ([relayInstead]: one
/// the monitor saw up, never one blocked here before); null while it is not blocked, or when
/// no other relay is left.
final relayInsteadProvider = Provider.autoDispose<EpicboxRelay?>((ref) {
  if (!ref.watch(listenerProvider.select((l) => l.blocked))) return null;
  final config = ref.watch(walletConfigProvider);
  final preset = ref.watch(networkChoiceProvider).value?.preset;
  if (config == null || preset == null) return null;
  final listed = ref.watch(relayStatusProvider(preset)).value;
  return relayInstead(
    EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort),
    mergePublicRelays(listed, builtIn: builtInRelaysFor(preset)),
    skip: ref.read(listenerProvider.notifier).blockedRelays,
  );
});

/// Moves the open wallet to [relay], with the node it uses: one tap, no question, as the
/// button's caption says the address changes.
Future<void> switchToRelayInstead(WidgetRef ref, EpicboxRelay relay) async {
  final choice = await ref.read(networkChoiceProvider.future);
  await switchServersLive(ref, nodeUrl: choice.nodeUrl, relay: relay);
}
