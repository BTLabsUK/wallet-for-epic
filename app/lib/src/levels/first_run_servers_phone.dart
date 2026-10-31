// SPDX-License-Identifier: Apache-2.0
/// First run's server pick on the phone (`first_run_servers.dart` has the rules): the nodes are
/// asked their tip directly (no wallet is open yet), the Epicbox servers a WebSocket handshake
/// ([relayProbeProvider]); what is picked is written to the settings file, which the network
/// choice and so the wallet created next follow.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../first_run_servers.dart';
import '../net/tor_switch.dart';
import '../net/ws_probe.dart' show probeTimeout;
import '../providers.dart';
import '../send_preflight.dart' show relayProbeProvider;
import '../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../wallet_service.dart' show WalletConfig;

Future<void> phoneFirstRunServers(Ref ref) async {
  // The Tor switch carries the probes and the wallet through Tor: this network's name lookups
  // do not decide, and a slow circuit is not a server that does not answer.
  if (TorSwitch.on) return;
  final choice = await ref.read(networkChoiceProvider.future);
  final service = ref.read(walletServiceProvider);
  final relays = ref.read(relayProbeProvider);
  await moveToAnsweringServers(
    ref.read(hostSettingsProvider),
    nodeAnswers: (url) async {
      final config = choice.preset.config(dataDir: '', nodeUrl: url, relay: choice.relay);
      await askNodeTip(service, null, config).timeout(probeTimeout);
      return true;
    },
    relayAnswers: relays.reachable,
    save: ref.read(hostSettingsProvider.notifier).setAll,
  );
}


/// The config of the wallet about to be created, once first run's server pick is done: the
/// selected config moved to the node and Epicbox server picked, if it moved any. Null when
/// none is selected.
Future<WalletConfig?> configAfterFirstRunServers(WidgetRef ref) async {
  await firstRunServersSettled();
  final current = ref.read(walletConfigProvider);
  if (current == null) return null;
  final choice = await ref.read(networkChoiceProvider.future);
  if (choice.preset.chain != current.chain) return current;
  final next = choice.config(current.dataDir);
  if (next.nodeUrl == current.nodeUrl &&
      next.epicboxDomain == current.epicboxDomain &&
      next.epicboxPort == current.epicboxPort) {
    return current;
  }
  ref.read(walletConfigProvider.notifier).select(next);
  return next;
}
