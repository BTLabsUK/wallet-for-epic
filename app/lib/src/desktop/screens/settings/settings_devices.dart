/// Settings › Linked devices (This wallet group, Experimental): the devices that hold this
/// wallet, how to link one, the servers they use, a pause switch and the coins another device's
/// payment holds here. Removing a device stops the sync; it does not protect the money.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../devices/device_model.dart';
import '../../../devices/device_providers.dart' show DeviceView;
import '../../../devices/device_service.dart';
import '../../../net/probe_not_run.dart' show ProbeNotRun;
import '../../../network.dart' show EpicboxRelay;
import '../../../relay_directory.dart' show NodeHealthState;
import '../../../send_preflight.dart' show relayProbeProvider;
import '../../../tor_build.dart' show torBuilt;
import '../../data/devices_state.dart';
import '../../data/pairing_state.dart' show DeskPairNet, deskPairNetProvider;
import '../../data/server_lists.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../../widgets/server_list_panel.dart';
import '../devices/link_flow.dart';
import 'settings_frame.dart' show SettingsFrame;

const Key devicesLinkKey = ValueKey('dev-link');
const Key devicesPauseKey = ValueKey('dev-pause');
const Key devicesServersKey = ValueKey('dev-servers');
const Key devicesServersLineKey = ValueKey('dev-servers-line');
const Key devicesProposalKey = ValueKey('dev-proposal');
const Key devicesProposalCancelKey = ValueKey('dev-proposal-cancel');
const Key devicesProposalAcceptKey = ValueKey('dev-proposal-accept');
const Key devicesProposalDeclineKey = ValueKey('dev-proposal-decline');
const Key devicesRemovedByKey = ValueKey('dev-removed-by');
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
    final ts = context.ts;
    final c = context.dc;
    final view = ref.watch(deskDeviceViewProvider);
    final service = ref.watch(deskDeviceServiceProvider);
    final net = ref.watch(deskPairNetProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(EIcons.devices, size: Ctl.icon, color: c.dim),
            SizedBox(width: Sp.x2),
            Flexible(child: Text(l.expLinkedDevices, style: ts.h3)),
            SizedBox(width: Sp.x2),
            EBadge(l.advExperimental),
            SizedBox(width: Sp.x1),
            EInfoHint(l.expLinkedDevicesHint, title: l.expLinkedDevices, icon: EIcons.devices),
          ],
        ),
        SizedBox(height: Sp.x2),
        Text(l.devicesMoneyNote, style: ts.bodyDim),
        SizedBox(height: Sp.x5),
        if (view == null || service == null)
          const SettingsLoadingBlock()
        else ...[
          if (view.book.removedBy != null) ...[
            ENotice(
              key: devicesRemovedByKey,
              title: l.devicesRemovedBy(view.book.removedBy!),
              tone: ETone.warn,
              icon: EIcons.alert,
              actions: [EButton(label: l.commonClose, size: EBtnSize.inline, onPressed: () => unawaited(service.clearRemovedBy()))],
            ),
            SizedBox(height: Sp.x4),
          ],
          if (!view.supported) ...[
            ENotice(title: l.devicesUnsupported, tone: ETone.info, icon: EIcons.info),
            SizedBox(height: Sp.x4),
          ],
          _DevicesGroup(view: view, service: service),
          _ServersGroup(view: view, service: service),
          _SyncGroup(view: view, service: service, net: net),
          _HeldGroup(view: view, service: service),
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
  const _DevicesGroup({required this.view, required this.service});

  final DeviceView view;
  final DeviceService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final book = view.book;
    final now = DateTime.now();
    final canLink = view.supported && service.canLinkMore;
    return ESetGroup(
      title: l.devicesOthers,
      trailing: EButton.primary(
        key: devicesLinkKey,
        label: l.devicesLink,
        icon: EIcons.link,
        size: EBtnSize.sm,
        onPressed: canLink ? () => unawaited(showDeskLinkDevice(context)) : null,
      ),
      rows: [
        ESetRow(
          key: const ValueKey('dev-this'),
          leading: EIcons.computer,
          title: book.deviceName,
          text: l.devicesThisDevice,
          control: EButton(
            label: l.devicesRename,
            size: EBtnSize.sm,
            onPressed: () => unawaited(_rename(context, ref, service, book.deviceName, thisDevice: true)),
          ),
        ),
        if (book.devices.isEmpty)
          ESetRow(key: const ValueKey('dev-none'), text: l.devicesEmpty)
        else
          for (final d in book.devices)
            ESetRow(
              key: ValueKey('dev-${d.deviceId}'),
              leading: EIcons.phone,
              title: d.name,
              text: deviceSeen(l, d.lastSeen, now),
              below: d.servers.isEmpty
                  ? null
                  : Text(d.servers.join(' · '), style: ts.mono(size: Fs.xs).copyWith(color: context.dc.faint), overflow: TextOverflow.ellipsis),
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
                    onPressed: () => unawaited(_remove(context, service, d)),
                  ),
                ],
              ),
            ),
        if (!canLink && book.devices.isNotEmpty && !service.canLinkMore) ESetRow(text: l.linkFailTooMany(maxLinkedDevices)),
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
        EButton(label: l.commonCancel, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx)),
        EButton.primary(key: devicesRenameSaveKey, label: l.commonSave, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx, text.text)),
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

Future<void> _remove(BuildContext context, DeviceService service, LinkedDevice d) async {
  final l = context.l10n;
  final ok = await showEDialog<bool>(
    context,
    builder: (ctx) => EDialog(
      title: l.devicesRemoveTitle(d.name),
      icon: EIcons.alert,
      tone: ETone.warn,
      description: l.devicesRemoveBody(d.name),
      actions: [
        EButton(label: l.commonCancel, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx, false)),
        EButton(key: devicesRemoveConfirmKey, label: l.devicesRemove, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  if (ok != true) return;
  await service.removeDevice(d.deviceId);
  if (context.mounted) showEToast(context, l.devicesRemoved(d.name), tone: ETone.neutral);
}

/// Servers: the set the devices use, a proposal under way, one from another device waiting for
/// the user here, and what the monitor says of the chosen servers.
class _ServersGroup extends ConsumerWidget {
  const _ServersGroup({required this.view, required this.service});

  final DeviceView view;
  final DeviceService service;

  static Future<String?> _test(WidgetRef ref, BuildContext context, String value) async {
    final l = context.l10n;
    final relay = EpicboxRelay.parse(value);
    if (relay == null) return l.slNotAnAddress;
    try {
      return await ref.read(relayProbeProvider).reachable(relay) ? null : l.slRelayNoAnswer;
    } on ProbeNotRun {
      return torBuilt ? l.deskSlTorWait : l.slRelayNoAnswer;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final book = view.book;
    final boxes = ref.watch(deskProvider.select((s) => s.epicboxes)) ?? const [];
    final defaults = ref.watch(deskLinkServersProvider);
    final chosen = book.servers.isNotEmpty ? book.servers : defaults;
    final proposal = book.proposal;
    final health = {
      for (final b in boxes)
        serverKeyOf(ServerKind.relay, relayLabel(b)): switch (b.health) {
          ServiceHealth.down => NodeHealthState.down,
          ServiceHealth.ok || ServiceHealth.slow => NodeHealthState.healthy,
          ServiceHealth.checking || ServiceHealth.off => null,
        },
    };
    final down = chosen.where((s) => health[serverKeyOf(ServerKind.relay, s)] == NodeHealthState.down).length;
    final (line, lineColor) = switch (down) {
      0 => (null, c.dim),
      _ when down >= chosen.length => (l.deskDevServersAllDown, c.risk),
      _ => (l.deskDevServersDown(down, chosen.length), c.warn),
    };
    final listed = {for (final b in boxes) serverKeyOf(ServerKind.relay, relayLabel(b))};
    final extra = [
      for (final v in {...chosen, ...?proposal?.servers})
        if (!listed.contains(serverKeyOf(ServerKind.relay, v))) v,
    ];
    final waiting = proposal != null && proposal.fromHere;
    final incoming = proposal != null && !proposal.fromHere;
    final from = incoming ? view.nameOf(proposal.accepted.firstOrNull ?? '') : '';
    return ESetGroup(
      title: l.devicesServers,
      rows: [
        ESetRow(
          key: devicesServersKey,
          title: l.devicesServers,
          hint: '${l.deskDevServersInfo1}\n\n${l.deskDevServersInfo2}\n\n${l.deskDevServersInfo3}',
          hintTitle: l.devicesServers,
          hintIcon: EIcons.epicbox,
          text: l.devicesServersNote,
          stacked: true,
          control: ServerListPanel(
            kind: ServerKind.relay,
            label: l.devicesServers,
            value: '',
            fieldText: chosen.join(', '),
            tone: down == 0 ? ETone.ok : (down >= chosen.length ? ETone.risk : ETone.warn),
            servers: [
              ...relayPanelRows(boxes),
              for (final v in extra) PanelServer.bare(ServerKind.relay, v),
            ],
            source: DeskServerSource(
              public: [
                for (final b in boxes) relayLabel(b),
                for (final v in [...defaults, ...chosen])
                  if (!listed.contains(serverKeyOf(ServerKind.relay, v))) v,
              ],
            ),
            onChoose: (_) async {},
            onTest: (v) => _test(ref, context, v),
            selection: RelaySelection(
              limit: maxLinkServers,
              chosen: chosen,
              defaults: defaults,
              onChanged: (set) => unawaited(service.proposeServers(set)),
              title: l.devicesServers,
              note: l.deskDevServersNote,
            ),
          ),
          below: line == null
              ? null
              : Semantics(
                  liveRegion: true,
                  child: Text(line, key: devicesServersLineKey, style: ts.small.copyWith(color: lineColor)),
                ),
        ),
        if (waiting)
          ESetRow(
            key: devicesProposalKey,
            title: l.devicesServersWaiting(_waitingFor(view, proposal)),
            text: proposal.servers.join(', '),
            control: EButton(key: devicesProposalCancelKey, label: l.deskDevServersCancel, size: EBtnSize.sm, onPressed: () => unawaited(service.cancelProposal())),
          ),
        if (incoming)
          ESetRow(
            key: devicesProposalKey,
            title: l.devicesProposal(from, proposal.servers.join(', ')),
            control: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EButton(key: devicesProposalDeclineKey, label: l.devicesNotNow, size: EBtnSize.sm, onPressed: () => unawaited(service.declineProposal())),
                SizedBox(width: Sp.x2),
                EButton.primary(key: devicesProposalAcceptKey, label: l.devicesAccept, size: EBtnSize.sm, onPressed: () => unawaited(service.acceptProposal())),
              ],
            ),
          ),
      ],
    );
  }

  /// The devices that have not accepted yet, by name.
  static String _waitingFor(DeviceView view, ServerProposal p) =>
      [for (final d in view.devices) if (!p.accepted.contains(d.deviceId)) d.name].join(', ');
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
          title: l.devicesPause,
          text: rests ?? l.devicesPauseHint,
          control: ESwitch(value: view.book.paused, semanticLabel: l.devicesPause, onChanged: (v) => unawaited(service.setPaused(v))),
        ),
      ],
    );
  }
}

/// Coins another device's payment holds here, each with Release.
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
        if (held.isEmpty)
          ESetRow(text: l.deskDevHeldNone)
        else
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
        EButton(label: l.commonCancel, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx, false)),
        EButton.primary(key: devicesReleaseConfirmKey, label: l.devicesRelease, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx, true)),
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
