// SPDX-License-Identifier: Apache-2.0
/// Settings › Linked devices (This wallet group, Experimental): the devices that hold this
/// wallet (the link's servers under the linked one), how to link one, a pause switch and the
/// coins another device's payment holds here. Removing a device stops the sync; it does not
/// protect the money.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../devices/device_model.dart';
import '../../../devices/device_providers.dart' show DeviceView;
import '../../../devices/device_service.dart';
import '../../data/devices_state.dart';
import '../../data/pairing_state.dart' show DeskPairNet, deskPairNetProvider;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'setting_ids.dart';
import '../devices/link_flow.dart';
import 'settings_frame.dart' show SettingsFrame;

const Key devicesLinkKey = ValueKey('dev-link');
const Key devicesPauseKey = ValueKey('dev-pause');
const Key devicesRemovedByKey = ValueKey('dev-removed-by');
const Key devicesEpicboxOffKey = ValueKey('dev-epicbox-off');
const Key devicesUpdateOtherKey = ValueKey('dev-update-other');
const Key devicesHeldKey = ValueKey('dev-held');
const Key devicesRenameFieldKey = ValueKey('dev-rename-field');
const Key devicesRenameSaveKey = ValueKey('dev-rename-save');
const Key devicesRemoveConfirmKey = ValueKey('dev-remove-confirm');
const Key devicesReleaseConfirmKey = ValueKey('dev-release-confirm');

class SettingsDevicesScreen extends StatelessWidget {
  const SettingsDevicesScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context) => const SettingsFrame(route: DeskRoute.settingsDevices, child: DevicesSettingsBlock());
}

/// When [t] was seen, as a short phrase against [now] ("seen 2 min ago"); "not seen yet" for none.
String deviceSeen(AppLocalizations l, DateTime? t, DateTime now) {
  if (t == null) return l.devicesNotSeen;
  final d = now.difference(t);
  return d.inMinutes < 1
      ? l.devicesSeenNow
      : d.inMinutes < 60
      ? l.devicesSeenMinutes(d.inMinutes)
      : d.inHours < 24
      ? l.devicesSeenHours(d.inHours)
      : l.devicesSeenDays(d.inDays);
}

class DevicesSettingsBlock extends ConsumerWidget {
  const DevicesSettingsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final view = ref.watch(deskDeviceViewProvider);
    final service = ref.watch(deskDeviceServiceProvider);
    final net = ref.watch(deskPairNetProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (view == null || service == null)
          const SettingsLoadingBlock()
        else ...[
          if (view.book.removedBy != null) ...[
            ENotice(
              key: devicesRemovedByKey,
              title: l.devicesRemovedBy(view.book.removedBy!),
              tone: ETone.info,
              icon: EIcons.info,
              actions: [EButton(label: l.commonOk, size: EBtnSize.inline, onPressed: () => unawaited(service.clearRemovedBy()))],
            ),
            SizedBox(height: Sp.x4),
          ],
          if (!view.supported) ...[
            ENotice(title: l.devicesUnsupported, tone: ETone.info, icon: EIcons.info),
            SizedBox(height: Sp.x4),
          ],
          _DevicesGroup(view: view, service: service, epicboxOff: net == DeskPairNet.epicboxOff),
          _SyncGroup(view: view, service: service, net: net),
          if (view.held.isNotEmpty) _HeldGroup(view: view, service: service),
        ],
      ],
    );
  }
}

/// A short stand-in while the book loads.
class SettingsLoadingBlock extends StatelessWidget {
  const SettingsLoadingBlock({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: Sp.x8),
    child: Center(child: ESpinner(size: 24.u)),
  );
}

class _DevicesGroup extends ConsumerWidget {
  const _DevicesGroup({required this.view, required this.service, required this.epicboxOff});

  final DeviceView view;
  final DeviceService service;

  /// Nothing goes over Epicbox: the devices do not sync, and none can be linked.
  final bool epicboxOff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final book = view.book;
    final now = ref.watch(deskDeviceClockProvider)();
    // This device, then the linked one: Link a device until one is, then that device with
    // Remove (one device can be linked).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ESetGroup(
          title: l.devicesThisDevice,
          rows: [
            ESetRow(
              key: const ValueKey('dev-this'),
              anchor: SetId.deviceName,
              leading: EIcons.computer,
              title: book.deviceName,
              control: EButton(
                label: l.devicesRename,
                size: EBtnSize.sm,
                onPressed: () => unawaited(_rename(context, ref, service, book.deviceName, thisDevice: true)),
              ),
            ),
          ],
        ),
        ESetGroup(
          title: l.devicesOthers,
          trailing: book.linked != null
              ? null
              : SetAnchor(id: SetId.linkDevice, child: EButton.primary(
                  key: devicesLinkKey,
                  label: l.devicesLink,
                  icon: EIcons.link,
                  size: EBtnSize.sm,
                  onPressed: view.supported && !epicboxOff ? () => unawaited(showDeskLinkDevice(context)) : null,
                ),
                ),
          rows: [
            // A device removed while this one was offline, until its notice goes; Remove again
            // forgets it here at once.
            for (final d in book.removing)
              ESetRow(
                key: ValueKey('dev-removing-${d.deviceId}'),
                leading: deskDeviceIcon(d.kind),
                title: d.name,
                text: l.devicesRemoving,
                control: EButton(
                  key: ValueKey('dev-remove-${d.deviceId}'),
                  label: l.devicesRemove,
                  kind: EBtnKind.danger,
                  size: EBtnSize.sm,
                  onPressed: () => unawaited(service.removeDevice(d.deviceId)),
                ),
              ),
            if (book.linked case final d?)
              ESetRow(
                key: ValueKey('dev-${d.deviceId}'),
                leading: deskDeviceIcon(d.kind),
                title: d.name,
                text: deviceSeen(l, d.lastSeen, now),
                // The one-device rule and the servers live behind ⓘ.
                hint: '${l.devicesOneOnly}\n\n${l.devicesServers}: ${metaLine(d.servers.isEmpty ? book.servers : d.servers)}',
                hintTitle: l.devicesAbout,
                hintIcon: EIcons.devices,
                // Its servers under it: the link's channel, as a caption.
                below: d.servers.isEmpty
                    ? null
                    : Text(metaLine(d.servers), style: ts.mono(size: Fs.xs).copyWith(color: context.dc.faint), overflow: TextOverflow.ellipsis),
                control: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EButton(label: l.devicesRename, size: EBtnSize.sm, onPressed: () => unawaited(_rename(context, ref, service, d.name, id: d.deviceId))),
                    SizedBox(width: Sp.x2),
                    EButton(
                      key: ValueKey('dev-remove-${d.deviceId}'),
                      label: l.devicesRemove,
                      kind: EBtnKind.danger,
                      size: EBtnSize.sm,
                      onPressed: () => unawaited(removeLinkedDevice(context, service, d)),
                    ),
                  ],
                ),
              ),
            // Under the linked device: Epicbox off, an app to update, then the money note once.
            if (book.linked case final d?) ...[
              if (epicboxOff) ESetRow(key: devicesEpicboxOffKey, leading: EIcons.alert, text: l.devicesEpicboxOff(d.name)),
              if (d.otherVersion != null) ESetRow(key: devicesUpdateOtherKey, leading: EIcons.alert, text: l.devicesUpdateOther(d.name)),
              ESetRow(key: const ValueKey('dev-money-note'), text: l.devicesMoneyNote),
            ] else ...[
              ESetRow(key: const ValueKey('dev-none'), text: l.devicesEmpty),
              if (epicboxOff) ESetRow(key: devicesEpicboxOffKey, text: l.devicesEpicboxOffNone),
            ],
          ],
        ),
      ],
    );
  }
}

Future<void> _rename(BuildContext context, WidgetRef ref, DeviceService service, String name, {String? id, bool thisDevice = false}) async {
  final l = context.l10n;
  final text = TextEditingController(text: name);
  final saved = await showEDialog<String>(
    context,
    builder: (ctx) => EDialog(
      title: thisDevice ? l.deskDevRenameThis : l.deskDevRenameDevice(name),
      icon: EIcons.pencil,
      body: EField(
        label: l.devicesNameLabel,
        child: EInput(
          key: devicesRenameFieldKey,
          controller: text,
          autofocus: true,
          semanticLabel: l.devicesNameLabel,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.pop(ctx)),
        EButton.primary(key: devicesRenameSaveKey, label: l.commonSave, onPressed: () => Navigator.pop(ctx, text.text)),
      ],
    ),
  );
  text.dispose();
  if (saved == null || saved.trim().isEmpty) return;
  if (thisDevice) {
    await service.renameThis(saved);
  } else if (id != null) {
    await service.renameDevice(id, saved);
  }
}

/// Asks, then ends the link with [d] on both devices.
Future<void> removeLinkedDevice(BuildContext context, DeviceService service, LinkedDevice d) async {
  final l = context.l10n;
  final ok = await showEDialog<bool>(
    context,
    builder: (ctx) => EDialog(
      title: l.devicesRemoveTitle(d.name),
      icon: EIcons.alert,
      tone: ETone.warn,
      description: l.devicesRemoveBody(d.name),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.pop(ctx, false)),
        EButton(key: devicesRemoveConfirmKey, label: l.devicesRemove, kind: EBtnKind.danger, onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  if (ok != true) return;
  await service.removeDevice(d.deviceId);
  if (context.mounted) showEToast(context, l.devicesRemoved(d.name), tone: ETone.neutral);
}

/// The pause switch, and why the channel rests when Offline or Epicbox is off.
class _SyncGroup extends StatelessWidget {
  const _SyncGroup({required this.view, required this.service, required this.net});

  final DeviceView view;
  final DeviceService service;
  final DeskPairNet net;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rests = switch (net) {
      DeskPairNet.offline => l.deskDevPausedOffline,
      DeskPairNet.epicboxOff => l.deskDevPausedEpicboxOff,
      DeskPairNet.online => null,
    };
    return ESetGroup(
      rows: [
        ESetRow(
          key: devicesPauseKey,
          anchor: SetId.pauseSync,
          title: l.devicesPause,
          text: rests ?? l.devicesPauseHint,
          control: ESwitch(value: view.book.paused, semanticLabel: l.devicesPause, onChanged: (v) => unawaited(service.setPaused(v))),
        ),
      ],
    );
  }
}

/// The icon of a linked device by its kind; a generic one while its kind is not known.
IconData deskDeviceIcon(DeviceKind? kind) => switch (kind) {
  DeviceKind.phone => EIcons.phone,
  DeviceKind.desktop => EIcons.computer,
  null => EIcons.devices,
};

/// Coins another device's payment holds here, each with Release. Shown only with coins held.
class _HeldGroup extends ConsumerWidget {
  const _HeldGroup({required this.view, required this.service});

  final DeviceView view;
  final DeviceService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final hidden = ref.watch(deskProvider.select((s) => s.settings.hideAmounts));
    final held = view.held;
    return ESetGroup(
      key: devicesHeldKey,
      title: l.devicesHeld,
      rows: [
        for (final h in held)
            ESetRow(
              key: ValueKey('dev-held-${h.deviceId}-${h.slateId}'),
              leading: EIcons.lock,
              title: hidden ? '••••••' : l.deskDevHeldAmount(formatEpicL(l, h.amount.toInt())),
              text: l.devicesHeldBy(view.nameOf(h.deviceId)),
              control: EButton(label: l.devicesRelease, size: EBtnSize.sm, onPressed: () => unawaited(_release(context, service, h, view.nameOf(h.deviceId)))),
            ),
      ],
    );
  }
}

Future<void> _release(BuildContext context, DeviceService service, HeldPayment h, String device) async {
  final l = context.l10n;
  final ok = await showEDialog<bool>(
    context,
    builder: (ctx) => EDialog(
      title: l.devicesReleaseTitle,
      icon: EIcons.lockOpen,
      description: l.devicesReleaseBody(device),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.pop(ctx, false)),
        EButton.primary(key: devicesReleaseConfirmKey, label: l.devicesRelease, onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  if (ok == true) await service.releaseByHandOf(h.deviceId, h.slateId);
}

/// Releases the held payment [h] of [device] after the plan's confirm; for Outputs and Send.
Future<void> deskReleaseHeld(BuildContext context, WidgetRef ref, HeldPayment h) {
  final service = ref.read(deskDeviceServiceProvider);
  final view = ref.read(deskDeviceViewProvider);
  if (service == null || view == null) return Future.value();
  return _release(context, service, h, view.nameOf(h.deviceId));
}
