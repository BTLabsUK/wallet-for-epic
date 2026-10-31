// SPDX-License-Identifier: Apache-2.0
/// First run's server pick on the desktop (`first_run_servers.dart` has the rules): the nodes
/// are asked through [DeskWalletApi.checkNode], the Epicbox servers a WebSocket handshake
/// ([relayProbeProvider]); what
/// is picked is written to the settings file, which the wallet created next reads
/// (`lepic_desk_wallet.dart` waits for the pick).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../first_run_servers.dart';
import '../../net/tor_switch.dart';
import '../../send_preflight.dart' show relayProbeProvider;
import '../../settings_file/host_settings.dart' show hostSettings;
import '../../settings_file/settings_providers.dart' show writeHostSettings;
import 'models.dart' show ServiceHealth;
import 'state.dart' show deskApiProvider;

Future<void> deskFirstRunServers(Ref ref) async {
  // The Tor switch carries the probes and the wallet through Tor: this network's name lookups
  // do not decide, and a slow circuit is not a server that does not answer.
  if (TorSwitch.on) return;
  final api = ref.read(deskApiProvider);
  await moveToAnsweringServers(
    hostSettings,
    nodeAnswers: (url) async => (await api.checkNode(url)).health == ServiceHealth.ok,
    relayAnswers: ref.read(relayProbeProvider).reachable,
    save: writeHostSettings,
  );
}
