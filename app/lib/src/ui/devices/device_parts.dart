// SPDX-License-Identifier: Apache-2.0
/// The phone's linked devices pieces shared by its screens: the "seen" line, why a link failed,
/// the rename and confirm dialogs, the Epicbox-off line, and the quiet offer to link.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/device_model.dart';
import '../../devices/device_service.dart';
import '../../devices/invite_links_api.dart';
import '../../devices/phone_devices.dart';
import '../../l10n.dart';
import '../../providers.dart';
import '../../advanced.dart' show NetworkModeRestricted;
import '../../settings.dart' show appSettingsProvider, networkModeProvider;
import '../badge.dart';
import '../theme/tokens.dart';
import 'link_device_screen.dart';
import 'linked_devices_screen.dart' show LinkedDevicesScreen;

/// "seen 2 min ago" for [at], or "not seen yet".
String deviceSeenLine(AppLocalizations l, DateTime? at, DateTime now) {
  if (at == null) return l.devicesNotSeen;
  final d = now.difference(at);
  if (d.inMinutes < 1) return l.devicesSeenNow;
  if (d.inHours < 1) return l.devicesSeenMinutes(d.inMinutes);
  if (d.inDays < 1) return l.devicesSeenHours(d.inHours);
  return l.devicesSeenDays(d.inDays);
}

/// The hub row's state line: None, "Desktop · seen 2 min ago", or "2 devices · seen …" (the
/// device seen last).
String devicesStateLine(AppLocalizations l, List<LinkedDevice> devices, DateTime now) {
  if (devices.isEmpty) return l.devicesNone;
  final last = [...devices]..sort((a, b) => (b.lastSeen ?? b.linkedAt).compareTo(a.lastSeen ?? a.linkedAt));
  final who = devices.length == 1 ? devices.single.name : l.devicesCount(devices.length);
  return l.settingsStateJoin(who, deviceSeenLine(l, last.first.lastSeen, now));
}

/// Why a link did not complete, in a sentence ([name]: the other device, when known).
String linkFailureText(AppLocalizations l, LinkFailure f, [String? name]) => switch (f) {
  LinkFailure.invalidCode => l.linkFailInvalid,
  LinkFailure.expired => l.linkFailExpired,
  LinkFailure.notFound => l.linkFailNotFound,
  LinkFailure.ownCode => l.linkFailOwn,
  LinkFailure.otherWallet => l.linkFailOtherWallet,
  LinkFailure.otherWalletCode => l.linkFailOtherWalletCode,
  // The other device stopped: the same line as not reached, with Retry.
  LinkFailure.cancelled => l.linkFailUnreachable,
  LinkFailure.tooMany => l.linkFailTooMany,
  LinkFailure.full => l.linkFailFull(name ?? l.deskDevTheOther),
  LinkFailure.update => l.linkFailUpdate,
  LinkFailure.updateOther => l.linkFailUpdateOther(name ?? l.deskDevTheOther),
  LinkFailure.unreachable => l.linkFailUnreachable,
  LinkFailure.unsupported => l.devicesUnsupported,
};

/// The icon of a device by its kind; a generic one while its kind is not known.
IconData deviceIcon(DeviceKind? kind) => switch (kind) {
  DeviceKind.phone => Icons.smartphone,
  DeviceKind.desktop => Icons.computer_outlined,
  null => Icons.devices_outlined,
};

/// The servers a new link proposes here: the link's set, else this wallet's server and the
/// settings' next link server.
List<String> phoneLinkServers(WidgetRef ref) {
  final config = ref.read(walletConfigProvider);
  final defaults = config == null
      ? const <String>[]
      : defaultLinkServers(ownHost: config.epicboxDomain, ownPort: config.epicboxPort);
  return ref.read(deviceServiceProvider)?.linkServers(defaults) ?? defaults;
}

/// Nothing goes over Epicbox now (the Epicbox switch off, Node only, Kill switch): the devices
/// do not sync and none can be linked.
final phoneDevicesEpicboxOffProvider = Provider<bool>((ref) {
  final on = ref.watch(appSettingsProvider.select((s) => s.value?.payments.epicbox ?? true));
  return ref.watch(networkModeProvider).restricted || !on;
});

/// A name, typed in a dialog; null when cancelled.
Future<String?> askDeviceName(BuildContext context, String initial) => showDialog<String>(
  context: context,
  builder: (_) => _NameDialog(initial: initial),
);

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.devicesRename),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 48,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _done(),
        decoration: InputDecoration(labelText: l.devicesNameLabel, border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(onPressed: _done, child: Text(l.commonSave)),
      ],
    );
  }
}

/// A yes/no question whose yes is [action] (and whose no is [cancel], Cancel by default), in
/// the risk tone when [risky].
Future<bool> confirmDeviceAction(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  String? cancel,
  bool risky = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancel ?? context.l10n.commonCancel)),
          TextButton(
            style: risky ? TextButton.styleFrom(foregroundColor: context.tokens.risk) : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

/// Registers the handler of an incoming device invite (an `epiccash://device-link/…` or
/// `https://…/link#…` link the system opened): Link a device with its confirm step. A link
/// never links by itself.
void registerPhoneDeviceInviteHandler() => registerInviteHandler(
  InviteKind.deviceLink,
  (context, link) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LinkDeviceScreen(code: link.invite, confirm: true))),
);

/// Opens Link a device, with [code] answered at once when a scan or a paste brought one.
Future<void> openLinkDevice(BuildContext context, WidgetRef ref, {String? code}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LinkDeviceScreen(code: code)));

/// The quiet offer: one line and Link a device, with the Experimental badge. Shown where the
/// problem linking solves shows (the end of a restore, a payment from another device), and only
/// while Linked devices is on (it is unless the user turned it off). With a device linked
/// already, a third device holds this wallet: the line says so, with the way to Linked devices.
class LinkDeviceOffer extends ConsumerWidget {
  const LinkDeviceOffer({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    if (!ref.watch(linkedDevicesOnProvider)) return const SizedBox.shrink();
    final linked = ref.watch(phoneDevices.devices).isNotEmpty;
    return Column(
      key: const ValueKey('link-device-offer'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(linked ? l.offerLinkThird : text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.dim)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              key: const ValueKey('link-device-offer-button'),
              icon: const Icon(Icons.devices_outlined),
              label: Text(linked ? l.expLinkedDevices : l.devicesLink),
              onPressed: () => linked
                  ? Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LinkedDevicesScreen()))
                  : openLinkDevice(context, ref),
            ),
            EBadge(l.advExperimental),
          ],
        ),
      ],
    );
  }
}
