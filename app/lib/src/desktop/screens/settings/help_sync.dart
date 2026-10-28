// SPDX-License-Identifier: Apache-2.0
/// The desktop's side of Help › How linked devices work: the sync picture with the servers the
/// link uses, and the live status panel from the desktop's device view (`data/devices_state.dart`),
/// the servers' health from the Epicbox list the wallet keeps, Link a device as the Linked
/// devices page opens it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../network.dart' show EpicboxRelay;
import '../../../ui/devices/sync_help.dart';
import '../../data/devices_state.dart' show deskDeviceClockProvider, deskDeviceViewProvider;
import '../../data/server_lists.dart' show relayLabel;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../devices/link_flow.dart' show showDeskLinkDevice;

/// The picture, drawn with as many servers as the link uses (two before the first link).
class DeskSyncDiagram extends ConsumerWidget {
  const DeskSyncDiagram({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(deskDeviceViewProvider.select((v) => v?.book.servers.length ?? 0));
    return SyncDiagram(servers: servers == 0 ? 2 : servers, thisIsPhone: false);
  }
}

/// The live status: this computer, the linked devices, the servers.
class DeskSyncStatus extends ConsumerWidget {
  const DeskSyncStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final view = ref.watch(deskDeviceViewProvider);
    final boxes = ref.watch(deskProvider.select((s) => s.epicboxes)) ?? const [];
    SyncServerState state(String server) {
      final label = EpicboxRelay.parse(server)?.label ?? server;
      final known = boxes.where((b) => relayLabel(b) == label).firstOrNull;
      return switch (known?.health) {
        ServiceHealth.ok || ServiceHealth.slow => SyncServerState.answering,
        ServiceHealth.down => SyncServerState.notAnswering,
        ServiceHealth.checking || ServiceHealth.off || null => SyncServerState.unknown,
      };
    }
    return SyncStatusPanel(
      view: view,
      now: ref.watch(deskDeviceClockProvider)(),
      serverState: state,
      thisIsPhone: false,
      // Without a service (the wallet locked, Linked devices off) there is nothing to link to.
      linkAction: view == null || !view.supported ? null : EButton(label: l.devicesLink, size: EBtnSize.sm, onPressed: () => showDeskLinkDevice(context)),
    );
  }
}
