/// Settings › Wallet › Linked devices (phone): this device, the linked ones (last seen, servers),
/// Link a device, the link's servers, the pause switch, and the coins other devices hold here
/// with Release. Removing a device stops sync; it does not protect the money.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/device_model.dart';
import '../../devices/device_providers.dart';
import '../../devices/device_service.dart';
import '../../devices/phone_devices.dart';
import '../../help/help_content.dart' show HelpId;
import '../../l10n.dart';
import '../../settings.dart' show clockProvider;
import '../badge.dart';
import '../common.dart';
import '../help_screen.dart' show HelpButton;
import '../info_hint.dart';
import '../notices.dart';
import '../pairing/pairing_parts.dart';
import '../theme/tokens.dart';
import 'device_parts.dart';

const Key devicesLinkKey = ValueKey('devices-link');
const Key devicesServersKey = ValueKey('devices-servers');
const Key devicesPauseKey = ValueKey('devices-pause');
const Key devicesThisKey = ValueKey('devices-this');
ValueKey<String> deviceRowKey(String id) => ValueKey('device-$id');
ValueKey<String> heldRowKey(String slateId) => ValueKey('held-$slateId');

class LinkedDevicesScreen extends ConsumerWidget {
  const LinkedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final view = ref.watch(phoneDevices.view);
    final now = ref.watch(clockProvider)();
    return SlotScaffold(
      appBar: AppBar(title: Text(l.expLinkedDevices), actions: [HelpButton(HelpId.linkedDevices)]),
      body: view == null || !view.loaded
          ? const SizedBox.shrink()
          : ScreenBody(
              children: [
                if (!view.supported) ...[PairEdgeNotice(tone: BadgeTone.warn, title: l.devicesUnsupported), const SizedBox(height: 12)],
                if (view.book.removedBy case final by?) _removedBy(context, ref, by),
                if (view.book.proposal case final p? when !p.fromHere) _proposal(context, ref, view, p),
                PairSection(l.devicesThisDevice),
                PairCard(
                  children: [
                    ListTile(
                      key: devicesThisKey,
                      leading: const Icon(Icons.smartphone),
                      title: Text(view.book.deviceName),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () async {
                        final name = await askDeviceName(context, view.book.deviceName);
                        if (name != null) await ref.read(deviceServiceProvider)?.renameThis(name);
                      },
                    ),
                  ],
                ),
                PairSection(l.devicesOthers),
                if (view.devices.isEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: PairSmallPrint(l.devicesEmpty))
                else
                  PairCard(children: [for (final d in view.devices) _DeviceRow(device: d, now: now)]),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: devicesLinkKey,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.add_link),
                  label: Text(l.devicesLink),
                  onPressed: view.supported && ref.read(deviceServiceProvider)!.canLinkMore ? () => openLinkDevice(context, ref) : null,
                ),
                if (view.devices.length >= maxLinkedDevices - 1) ...[
                  const SizedBox(height: 4),
                  PairSmallPrint(l.linkFailTooMany(maxLinkedDevices - 1)),
                ],
                const SizedBox(height: 12),
                PairCard(
                  children: [
                    _servers(context, ref, view),
                    HintSwitchTile(
                      key: devicesPauseKey,
                      icon: Icons.pause_circle_outline,
                      title: l.devicesPause,
                      hint: l.devicesPauseHint,
                      value: view.book.paused,
                      onChanged: (on) => ref.read(deviceServiceProvider)?.setPaused(on),
                    ),
                  ],
                ),
                if (view.held.isNotEmpty) ...[
                  PairSection(l.devicesHeld),
                  PairCard(children: [for (final h in view.held) _HeldRow(hold: h, name: view.nameOf(h.deviceId))]),
                ],
                const SizedBox(height: 16),
                PairSmallPrint(l.devicesMoneyNote),
              ],
            ),
    );
  }

  Widget _servers(BuildContext context, WidgetRef ref, DeviceView view) {
    final l = context.l10n;
    final mine = view.book.proposal;
    final waiting = mine != null && mine.fromHere
        ? [for (final d in view.devices) if (!mine.accepted.contains(d.deviceId)) d.name]
        : const <String>[];
    final servers = view.book.servers.isEmpty ? phoneLinkServers(ref) : view.book.servers;
    return ListTile(
      key: devicesServersKey,
      leading: const Icon(Icons.dns_outlined),
      title: Text(l.devicesServers),
      subtitle: Text(waiting.isEmpty ? servers.join(', ') : l.devicesServersWaiting(waiting.join(', '))),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        var chosen = servers;
        pickLinkServers(context, ref, chosen: servers, onChanged: (next) => chosen = next).then((_) {
          if (chosen.join(',') != servers.join(',')) ref.read(deviceServiceProvider)?.proposeServers(chosen);
        });
      },
    );
  }

  Widget _removedBy(BuildContext context, WidgetRef ref, String name) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: PairEdgeNotice(
      tone: BadgeTone.info,
      title: context.l10n.devicesRemovedBy(name),
      actions: [TextButton(onPressed: () => ref.read(deviceServiceProvider)?.clearRemovedBy(), child: Text(context.l10n.commonOk))],
    ),
  );

  Widget _proposal(BuildContext context, WidgetRef ref, DeviceView view, ServerProposal p) {
    final l = context.l10n;
    final from = p.accepted.map(view.nameOf).where((n) => n.isNotEmpty).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PairCard(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(l.devicesProposal(from, p.servers.join(', '))),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => ref.read(deviceServiceProvider)?.declineProposal(), child: Text(l.devicesNotNow)),
              TextButton(onPressed: () => ref.read(deviceServiceProvider)?.acceptProposal(), child: Text(l.devicesAccept)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends ConsumerWidget {
  const _DeviceRow({required this.device, required this.now});

  final LinkedDevice device;
  final DateTime now;

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l.devicesRename), onTap: () => Navigator.pop(context, 'rename')),
            ListTile(
              leading: Icon(Icons.link_off, color: context.tokens.risk),
              title: Text(l.devicesRemove, style: TextStyle(color: context.tokens.risk)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    final service = ref.read(deviceServiceProvider);
    if (choice == 'rename') {
      final name = await askDeviceName(context, device.name);
      if (name != null) await service?.renameDevice(device.deviceId, name);
    } else if (choice == 'remove') {
      final yes = await confirmDeviceAction(
        context,
        title: l.devicesRemoveTitle(device.name),
        body: l.devicesRemoveBody(device.name),
        action: l.devicesRemove,
        risky: true,
      );
      if (!yes || !context.mounted) return;
      await service?.removeDevice(device.deviceId);
      ref.read(noticeProvider.notifier).show(l.devicesRemoved(device.name), level: NoticeLevel.success);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return ListTile(
      key: deviceRowKey(device.deviceId),
      leading: const Icon(Icons.devices_outlined),
      title: Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(l.settingsStateJoin(deviceSeenLine(l, device.lastSeen, now), l.devicesServerCount(device.pairings.length))),
      trailing: const Icon(Icons.more_vert),
      onTap: () => _menu(context, ref),
    );
  }
}

class _HeldRow extends ConsumerWidget {
  const _HeldRow({required this.hold, required this.name});

  final HeldPayment hold;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final display = amountDisplay(ref);
    final amount = display.hidden ? hiddenAmount : epicText(l, hold.amount);
    return ListTile(
      key: heldRowKey(hold.slateId),
      leading: const Icon(Icons.lock_clock_outlined),
      title: Text(amount),
      subtitle: Text(l.devicesHeldBy(name)),
      trailing: TextButton(
        onPressed: () async {
          final yes = await confirmDeviceAction(context, title: l.devicesReleaseTitle, body: l.devicesReleaseBody(name), action: l.devicesRelease, risky: true);
          if (!yes || !context.mounted) return;
          await ref.read(deviceServiceProvider)?.releaseByHandOf(hold.deviceId, hold.slateId);
          ref.read(noticeProvider.notifier).show(l.devicesReleased, level: NoticeLevel.success);
        },
        child: Text(l.devicesRelease),
      ),
    );
  }
}

/// [DeviceSyncTrigger] kept reachable for callers that import only this screen.
typedef PhoneDeviceTrigger = DeviceSyncTrigger;
