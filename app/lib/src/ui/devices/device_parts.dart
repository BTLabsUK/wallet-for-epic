/// The phone's linked devices pieces shared by its screens: the "seen" line, why a link failed,
/// the rename and confirm dialogs, the servers sheet, and the quiet offer that turns the
/// feature on.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/device_model.dart';
import '../../devices/device_service.dart';
import '../../devices/phone_devices.dart';
import '../../l10n.dart';
import '../../models.dart' show Chain;
import '../../providers.dart';
import '../../server_list.dart';
import '../badge.dart';
import '../server_list_sheet.dart';
import '../theme/tokens.dart';
import 'link_device_screen.dart';

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

String linkFailureText(AppLocalizations l, LinkFailure f) => switch (f) {
  LinkFailure.invalidCode => l.linkFailInvalid,
  LinkFailure.expired => l.linkFailExpired,
  LinkFailure.notFound => l.linkFailNotFound,
  LinkFailure.ownCode => l.linkFailOwn,
  LinkFailure.otherWallet => l.linkFailOtherWallet,
  LinkFailure.mismatch => l.linkFailMismatch,
  LinkFailure.cancelled => l.linkFailCancelled,
  LinkFailure.tooMany => l.linkFailTooMany(maxLinkedDevices - 1),
  LinkFailure.unreachable => l.linkFailUnreachable,
  LinkFailure.unsupported => l.devicesUnsupported,
};

/// The servers a new link proposes here: the link's set, else this wallet's server and one of
/// another operator.
List<String> phoneLinkServers(WidgetRef ref) {
  final config = ref.read(walletConfigProvider);
  final defaults = config == null
      ? const <String>[]
      : defaultLinkServers(ownHost: config.epicboxDomain, ownPort: config.epicboxPort, mainnet: config.chain == Chain.mainnet);
  return ref.read(deviceServiceProvider)?.linkServers(defaults) ?? defaults;
}

/// Opens the server picker in selection mode, up to [maxLinkServers]; [onChanged] gets the set
/// after every change.
Future<void> pickLinkServers(BuildContext context, WidgetRef ref, {required List<String> chosen, required void Function(List<String>) onChanged}) {
  final l = context.l10n;
  final config = ref.read(walletConfigProvider);
  final defaults = config == null
      ? chosen
      : defaultLinkServers(ownHost: config.epicboxDomain, ownPort: config.epicboxPort, mainnet: config.chain == Chain.mainnet);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      final sheet = DraggableScrollableController();
      return DraggableScrollableSheet(
        controller: sheet,
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 1,
        builder: (context, scroll) => ServerListSheet(
          kind: ServerKind.relay,
          scrollController: scroll,
          sheetController: sheet,
          selection: RelaySelection(
            limit: maxLinkServers,
            chosen: chosen,
            defaults: defaults,
            onChanged: onChanged,
            title: l.devicesServers,
            note: l.devicesServersNote,
          ),
        ),
      );
    },
  );
}

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

/// A yes/no question whose yes is [action], in the risk tone when [risky].
Future<bool> confirmDeviceAction(BuildContext context, {required String title, required String body, required String action, bool risky = false}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.commonCancel)),
          TextButton(
            style: risky ? TextButton.styleFrom(foregroundColor: context.tokens.risk) : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

/// Opens Link a device, with [code] answered at once when a scan or a paste brought one.
Future<void> openLinkDevice(BuildContext context, WidgetRef ref, {String? code}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LinkDeviceScreen(code: code)));

/// The quiet offer: one line and Link a device, with the Experimental badge. Shown where the
/// problem linking solves shows (the end of a restore, a payment from another wallet), and only
/// while Linked devices is on (it is unless the user turned it off).
class LinkDeviceOffer extends ConsumerWidget {
  const LinkDeviceOffer({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    if (!ref.watch(linkedDevicesOnProvider)) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('link-device-offer'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.dim)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              key: const ValueKey('link-device-offer-button'),
              icon: const Icon(Icons.devices_outlined),
              label: Text(l.devicesLink),
              onPressed: () => openLinkDevice(context, ref),
            ),
            EBadge(l.advExperimental),
          ],
        ),
      ],
    );
  }
}
