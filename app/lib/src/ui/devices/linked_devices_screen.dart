// SPDX-License-Identifier: Apache-2.0
/// Settings › Wallet › Linked devices (phone): this device, the linked one (last seen, its
/// servers under it), Link a device, the pause switch, and the coins the other device holds
/// here with Release. Removing a device stops sync; it does not protect the money.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/device_model.dart';
import '../../devices/phone_devices.dart';
import '../../help/help_content.dart' show HelpId;
import '../../l10n.dart';
import '../../settings.dart' show clockProvider;
import '../common.dart';
import '../help_screen.dart' show HelpButton;
import '../info_hint.dart';
import '../pairing/pairing_parts.dart';
import '../settings_rows.dart' show SettingsHeader;
import '../theme/tokens.dart';
import 'device_parts.dart';

const Key devicesLinkKey = ValueKey('devices-link');
const Key devicesPauseKey = ValueKey('devices-pause');
const Key devicesThisKey = ValueKey('devices-this');
const Key devicesEpicboxOffKey = ValueKey('devices-epicbox-off');
const Key devicesUpdateOtherKey = ValueKey('devices-update-other');
const Key devicesAboutKey = ValueKey('devices-about');
const Key devicesRenameKey = ValueKey('devices-rename');
const Key devicesRemoveKey = ValueKey('devices-remove');
ValueKey<String> deviceRowKey(String id) => ValueKey('device-$id');
ValueKey<String> heldRowKey(String slateId) => ValueKey('held-$slateId');

class LinkedDevicesScreen extends ConsumerWidget {
  const LinkedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final view = ref.watch(phoneDevices.view);
    final now = ref.watch(clockProvider)();
    final epicboxOff = ref.watch(phoneDevicesEpicboxOffProvider);
    final linked = view?.book.linked;
    return SlotScaffold(
      appBar: AppBar(title: Text(l.expLinkedDevices), actions: [HelpButton(HelpId.linkedDevices)]),
      body: view == null || !view.loaded
          ? const SizedBox.shrink()
          : ScreenBody(
              children: [
                if (!view.supported) ...[PairEdgeNotice(tone: BadgeTone.warn, title: l.devicesUnsupported), const SizedBox(height: 12)],
                if (view.book.removedBy case final by?) _removedBy(context, ref, by),
                SettingsHeader.inBody(l.devicesThisDevice),
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
                SettingsHeader.inBody(l.devicesOthers),
                // A device removed while this one was offline, until its notice goes.
                if (view.book.removing.isNotEmpty) ...[
                  PairCard(children: [for (final d in view.book.removing) _RemovingRow(device: d)]),
                  const SizedBox(height: 8),
                ],
                // One device can be linked: Link a device until it is, then that device with
                // its lines (Epicbox off, an app to update), Rename and Remove, and the money
                // note once, under it.
                if (linked != null) ...[
                  PairCard(
                    children: [
                      _DeviceRow(device: linked, now: now, servers: view.book.servers),
                      // Nothing goes over Epicbox: the devices do not sync.
                      if (epicboxOff) _Line(key: devicesEpicboxOffKey, text: l.devicesEpicboxOff(linked.name)),
                      // The other device writes another wire version: nothing from it is read
                      // until it is updated.
                      if (linked.otherVersion != null) _Line(key: devicesUpdateOtherKey, text: l.devicesUpdateOther(linked.name)),
                      _DeviceActions(device: linked),
                    ],
                  ),
                  const SizedBox(height: 4),
                  PairSmallPrint(l.devicesMoneyNote),
                ] else ...[
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: PairSmallPrint(l.devicesEmpty)),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    key: devicesLinkKey,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    icon: const Icon(Icons.add_link),
                    label: Text(l.devicesLink),
                    onPressed: view.supported && !epicboxOff ? () => openLinkDevice(context, ref) : null,
                  ),
                  // Nothing goes over Epicbox: none can be linked.
                  if (epicboxOff) ...[const SizedBox(height: 4), PairSmallPrint(l.devicesEpicboxOffNone, key: devicesEpicboxOffKey)],
                ],
                const SizedBox(height: 12),
                PairCard(
                  children: [
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
                  SettingsHeader.inBody(l.devicesHeld),
                  PairCard(children: [for (final h in view.held) _HeldRow(hold: h, name: view.nameOf(h.deviceId))]),
                ],
              ],
            ),
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
}

class _DeviceRow extends ConsumerWidget {
  const _DeviceRow({required this.device, required this.now, required this.servers});

  final LinkedDevice device;
  final DateTime now;

  /// The link's servers: the caption under the device, and the ⓘ sheet's.
  final List<String> servers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final list = metaLine(device.servers.isEmpty ? servers : device.servers, whole: true);
    return ListTile(
      key: deviceRowKey(device.deviceId),
      leading: Icon(deviceIcon(device.kind)),
      title: Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      // Its servers under it: the link's channel, as a caption.
      subtitle: Text(
        list.isEmpty ? deviceSeenLine(l, device.lastSeen, now) : l.settingsStateJoin(deviceSeenLine(l, device.lastSeen, now), list),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: t.dim),
      ),
      // The one-device rule and the servers live behind ⓘ.
      trailing: IconButton(
        key: devicesAboutKey,
        icon: const Icon(Icons.info_outline),
        tooltip: l.devicesAbout,
        onPressed: () => showInfoSheet(context, title: l.devicesAbout, text: '${l.devicesOneOnly}\n\n${l.devicesServers}: $list', icon: Icons.devices_outlined),
      ),
    );
  }
}

/// A line under the device: Epicbox off, an app to update.
class _Line extends StatelessWidget {
  const _Line({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, size: 16, color: t.warn),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.warn))),
        ],
      ),
    );
  }
}

/// Rename and Remove, under the device.
class _DeviceActions extends ConsumerWidget {
  const _DeviceActions({required this.device});

  final LinkedDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final service = ref.read(deviceServiceProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Row(
        children: [
          TextButton(
            key: devicesRenameKey,
            onPressed: () async {
              final name = await askDeviceName(context, device.name);
              if (name != null) await service?.renameDevice(device.deviceId, name);
            },
            child: Text(l.devicesRename),
          ),
          TextButton(
            key: devicesRemoveKey,
            style: TextButton.styleFrom(foregroundColor: context.tokens.risk),
            onPressed: () async {
              final yes = await confirmDeviceAction(
                context,
                title: l.devicesRemoveTitle(device.name),
                body: l.devicesRemoveBody(device.name),
                action: l.devicesRemove,
                risky: true,
                icon: Icons.link_off,
              );
              if (!yes || !context.mounted) return;
              await service?.removeDevice(device.deviceId);
              ref.read(noticeProvider.notifier).show(l.devicesRemoved(device.name), level: NoticeLevel.success);
            },
            child: Text(l.devicesRemove),
          ),
        ],
      ),
    );
  }
}

/// A device removed here while offline: Removing… until the notice goes; Remove again forgets
/// it here at once.
class _RemovingRow extends ConsumerWidget {
  const _RemovingRow({required this.device});

  final LinkedDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return ListTile(
      key: ValueKey('device-removing-${device.deviceId}'),
      leading: const Icon(Icons.link_off),
      title: Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(l.devicesRemoving),
      trailing: TextButton(
        onPressed: () => ref.read(deviceServiceProvider)?.removeDevice(device.deviceId),
        child: Text(l.devicesRemove, style: TextStyle(color: context.tokens.risk)),
      ),
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
          final yes = await confirmDeviceAction(context, title: l.devicesReleaseTitle, body: l.devicesReleaseBody(name), action: l.devicesRelease, risky: true, icon: Icons.lock_open_outlined);
          if (!yes || !context.mounted) return;
          await ref.read(deviceServiceProvider)?.releaseByHandOf(hold.deviceId, hold.slateId);
          ref.read(noticeProvider.notifier).show(l.devicesReleased, level: NoticeLevel.success);
        },
        child: Text(l.devicesRelease),
      ),
    );
  }
}
