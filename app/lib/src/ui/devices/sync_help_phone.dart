// SPDX-License-Identifier: Apache-2.0
/// The phone's side of Help › How linked devices work: the sync picture with the servers the
/// link uses, and the live status panel read from the phone's device providers
/// (`phone_devices.dart`), the servers' health from the monitor the server lists use.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/phone_devices.dart';
import '../../l10n.dart';
import '../../network.dart' show EpicboxRelay;
import '../../providers.dart' show networkChoiceProvider;
import '../../relay_directory.dart' show relayStatusProvider;
import '../../settings.dart' show clockProvider;
import 'device_parts.dart' show openLinkDevice;
import 'linked_devices_screen.dart';
import 'sync_help.dart';

/// The picture, drawn with as many servers as the link uses (two before the first link, as a
/// first link proposes).
class PhoneSyncDiagram extends ConsumerWidget {
  const PhoneSyncDiagram({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(phoneDevices.view.select((v) => v?.book.servers.length ?? 0));
    return SyncDiagram(servers: servers == 0 ? 2 : servers, thisIsPhone: true);
  }
}

/// The live status: this phone, the linked devices, the servers.
class PhoneSyncStatus extends ConsumerWidget {
  const PhoneSyncStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final view = ref.watch(phoneDevices.view);
    final now = ref.watch(clockProvider)();
    final preset = ref.watch(networkChoiceProvider).value?.preset;
    final relays = preset == null ? null : ref.watch(relayStatusProvider(preset)).value;
    SyncServerState state(String server) {
      final label = EpicboxRelay.parse(server)?.label ?? server;
      final known = relays?.where((r) => r.relay.label == label).firstOrNull;
      if (known == null) return SyncServerState.unknown;
      return known.healthy ? SyncServerState.answering : SyncServerState.notAnswering;
    }
    return SyncStatusPanel(
      view: view,
      now: now,
      serverState: state,
      thisIsPhone: true,
      linkAction: OutlinedButton(
        onPressed: () => view != null && view.supported
            ? openLinkDevice(context, ref)
            : Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LinkedDevicesScreen())),
        child: Text(l.devicesLink),
      ),
    );
  }
}
