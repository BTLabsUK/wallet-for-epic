// SPDX-License-Identifier: Apache-2.0
/// Settings › Wallet › Linked devices (phone): this device, the linked one (last seen, its
/// servers under it), Link a device, the pause switch, and the coins the other device holds
/// here with Release. Removing a device stops sync; it does not protect the money.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/device_model.dart';
import '../../devices/phone_devices.dart';
import '../../help/help_content.dart' show HelpId;
import '../../l10n.dart';
import '../../settings.dart' show clockProvider;
import '../../trust_ids.dart';
import '../common.dart';
import '../help_screen.dart' show openHelp;
import '../kit/kit_button.dart';
import '../kit/kit_group.dart';
import '../kit/kit_headers.dart';
import '../kit/kit_help_sheet.dart';
import '../kit/kit_icons.dart';
import '../kit/kit_row.dart';
import '../kit/kit_settings.dart' show KitFootnote;
import '../kit/kit_tokens.dart';
import '../pairing/pairing_parts.dart';
import '../phone_frame.dart' show phoneFrameBreakpoint;
import '../theme/tokens.dart';
import '../tour/tour_target.dart';
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
    final t = context.tokens;
    final view = ref.watch(phoneDevices.view);
    final now = ref.watch(clockProvider)();
    final epicboxOff = ref.watch(phoneDevicesEpicboxOffProvider);
    final linked = view?.book.linked;
    final loaded = view != null && view.loaded;
    // Nothing linked, nothing waiting: the empty state with Link a device under it.
    final empty = loaded && linked == null && view.supported && view.book.removedBy == null && view.book.removing.isEmpty && view.held.isEmpty;
    // The button sits at the bottom edge, where the tour's card is: the tour lights the empty
    // state above it, which says what linking does.
    final Widget link = KitButton(
      key: devicesLinkKey,
      label: l.phoneSettingsLinkDevice,
      semanticsId: TrustIds.devicesLink,
      onPressed: loaded && view.supported && !epicboxOff ? () => openLinkDevice(context, ref) : null,
    );
    return SlotScaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: phoneFrameBreakpoint),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitPageHeader(
                  backLabel: l.settingsTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  title: l.expLinkedDevices,
                  tag: l.settingsExperimentTag,
                  // The empty page's 70 is measured from the title line itself (`.ptitle` has no margin).
                  bottomGap: loaded && empty ? 1 : 20,
                  backId: TrustIds.devicesBack,
                  helpId: TrustIds.devicesHelp,
                  onHelp: () => showKitHelp(
                    context,
                    title: l.expLinkedDevices,
                    lines: [l.devicesOneOnly, l.devicesPauseHint],
                    sheetId: TrustIds.settingsHelpSheet,
                    moreId: TrustIds.settingsHelpMore,
                    onMore: () => openHelp(context, HelpId.linkedDevices),
                  ),
                ),
                if (!loaded)
                  const Expanded(child: SizedBox.shrink())
                else if (empty)
                  Expanded(
                    child: PhoneTourTarget(
                      id: 'tour-devices-link',
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 70),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: t.raised, borderRadius: BorderRadius.circular(22)),
                              child: ExcludeSemantics(child: CustomPaint(size: const Size.square(34), painter: _DevicesGlyph(t.accentText))),
                            ),
                            const SizedBox(height: 24),
                            Semantics(
                              header: true,
                              child: Text(l.phoneSettingsDevicesEmpty, style: KitType.sheetTitle.copyWith(fontSize: 22, color: t.text), textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(40, 10, 40, 24),
                              child: Text(l.phoneSettingsDevicesEmptyLine, style: KitType.body.copyWith(color: t.dim), textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: Kit.gutter * 2),
                      children: [
                        if (!view.supported) Padding(
                          padding: const EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, 12),
                          child: PairEdgeNotice(tone: BadgeTone.warn, title: l.devicesUnsupported),
                        ),
                        if (view.book.removedBy case final by?) _removedBy(context, ref, by),
                        KitGroupLabel(l.devicesThisDevice),
                        KitGroup(
                          children: [
                            KitRow(
                              key: devicesThisKey,
                              leading: KitIconWell(Icons.smartphone, color: t.accent),
                              title: view.book.deviceName,
                              trailing: Icon(Icons.edit_outlined, size: 20, color: t.dim),
                              onTap: () async {
                                final name = await askDeviceName(context, view.book.deviceName);
                                if (name != null) await ref.read(deviceServiceProvider)?.renameThis(name);
                              },
                            ),
                          ],
                        ),
                        // A device removed while this one was offline, until its notice goes.
                        if (view.book.removing.isNotEmpty) ...[
                          KitGroupLabel(l.devicesRemoving),
                          KitGroup(children: [for (final d in view.book.removing) _RemovingRow(device: d)]),
                        ],
                        // One device can be linked: that device with its lines (Epicbox off, an
                        // app to update), Rename and Remove, and the money note once, under it.
                        if (linked != null) ...[
                          KitGroupLabel(l.devicesOthers),
                          PhoneTourTarget(
                            id: 'tour-devices-link',
                            child: KitGroup(
                              children: [
                                _DeviceRow(device: linked, now: now, servers: view.book.servers),
                                _DeviceActions(device: linked),
                              ],
                            ),
                          ),
                          // Nothing goes over Epicbox: the devices do not sync.
                          if (epicboxOff) KitFootnote(l.devicesEpicboxOff(linked.name), key: devicesEpicboxOffKey, color: t.warn),
                          // The other device writes another wire version: nothing from it is read
                          // until it is updated.
                          if (linked.otherVersion != null) KitFootnote(l.devicesUpdateOther(linked.name), key: devicesUpdateOtherKey, color: t.warn),
                          KitFootnote(l.devicesMoneyNote),
                        ] else if (epicboxOff)
                          // Nothing goes over Epicbox: none can be linked.
                          KitFootnote(l.devicesEpicboxOffNone, key: devicesEpicboxOffKey),
                        const SizedBox(height: Kit.groupGap),
                        KitGroup(
                          children: [
                            KitRow.toggle(
                              key: devicesPauseKey,
                              leading: KitIconWell(Icons.pause_circle_outline, color: t.accent),
                              title: l.devicesPause,
                              value: view.book.paused,
                              onChanged: (on) => ref.read(deviceServiceProvider)?.setPaused(on),
                            ),
                          ],
                        ),
                        if (view.held.isNotEmpty) ...[
                          KitGroupLabel(l.devicesHeld),
                          KitGroup(children: [for (final h in view.held) _HeldRow(hold: h, name: view.nameOf(h.deviceId))]),
                        ],
                      ],
                    ),
                  ),
                if (loaded && linked == null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(Kit.gutter, 8, Kit.gutter, math.max(MediaQuery.paddingOf(context).bottom, 34)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nothing goes over Epicbox: none can be linked.
                        if (empty && epicboxOff)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(l.devicesEpicboxOffNone, key: devicesEpicboxOffKey, textAlign: TextAlign.center, style: KitType.rowSub.copyWith(color: t.dim)),
                          ),
                        link,
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _removedBy(BuildContext context, WidgetRef ref, String name) => Padding(
    padding: const EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, 12),
    child: PairEdgeNotice(
      tone: BadgeTone.info,
      title: context.l10n.devicesRemovedBy(name),
      actions: [TextButton(onPressed: () => ref.read(deviceServiceProvider)?.clearRemovedBy(), child: Text(context.l10n.commonOk))],
    ),
  );
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, required this.now, required this.servers});

  final LinkedDevice device;
  final DateTime now;

  /// The link's servers: the caption under the device.
  final List<String> servers;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final list = metaLine(device.servers.isEmpty ? servers : device.servers, whole: true);
    return KitRow(
      key: deviceRowKey(device.deviceId),
      leading: KitIconWell(deviceIcon(device.kind), color: t.accent),
      title: device.name,
      // Its servers under it: the link's channel, as a caption.
      subtitle: list.isEmpty ? deviceSeenLine(l, device.lastSeen, now) : l.settingsStateJoin(deviceSeenLine(l, device.lastSeen, now), list),
      subtitleLines: 2,
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
    final t = context.tokens;
    final service = ref.read(deviceServiceProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KitRow(
          key: devicesRenameKey,
          leading: KitIconWell(Icons.edit_outlined, color: t.accent),
          title: l.devicesRename,
          onTap: () async {
            final name = await askDeviceName(context, device.name);
            if (name != null) await service?.renameDevice(device.deviceId, name);
          },
        ),
        KitRow(
          key: devicesRemoveKey,
          leading: KitIconWell(KitIcons.remove, color: t.risk),
          title: l.devicesRemove,
          titleColor: t.risk,
          onTap: () async {
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
        ),
      ],
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
    final t = context.tokens;
    return KitRow(
      key: ValueKey('device-removing-${device.deviceId}'),
      leading: KitIconWell(Icons.link_off, color: t.dim),
      title: device.name,
      subtitle: l.devicesRemoving,
      trailing: KitButton(
        label: l.devicesRemove,
        kind: KitButtonKind.danger,
        small: true,
        expand: false,
        onPressed: () => ref.read(deviceServiceProvider)?.removeDevice(device.deviceId),
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
    final t = context.tokens;
    final display = amountDisplay(ref);
    final amount = display.hidden ? hiddenAmount : epicText(l, hold.amount);
    return KitRow(
      key: heldRowKey(hold.slateId),
      leading: KitIconWell(Icons.lock_clock_outlined, color: t.accent),
      title: amount,
      subtitle: l.devicesHeldBy(name),
      trailing: KitButton(
        label: l.devicesRelease,
        kind: KitButtonKind.quiet,
        small: true,
        expand: false,
        onPressed: () async {
          final yes = await confirmDeviceAction(
            context,
            title: l.devicesReleaseTitle,
            body: l.devicesReleaseBody(name),
            action: l.devicesRelease,
            risky: true,
            icon: Icons.lock_open_outlined,
          );
          if (!yes || !context.mounted) return;
          await ref.read(deviceServiceProvider)?.releaseByHandOf(hold.deviceId, hold.slateId);
          ref.read(noticeProvider.notifier).show(l.devicesReleased, level: NoticeLevel.success);
        },
      ),
    );
  }
}

/// The empty page's devices mark as the frame draws it (24 grid, stroke 1.6): a screen, its
/// stand line and a phone.
class _DevicesGlyph extends CustomPainter {
  const _DevicesGlyph(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2 * k, 4 * k, 14 * k, 10 * k), Radius.circular(2 * k)), paint);
    canvas.drawLine(Offset(2 * k, 18 * k), Offset(12 * k, 18 * k), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(16 * k, 9 * k, 6 * k, 12 * k), Radius.circular(1.5 * k)), paint);
  }

  @override
  bool shouldRepaint(_DevicesGlyph old) => old.color != color;
}
