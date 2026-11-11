// SPDX-License-Identifier: Apache-2.0
/// The desktop's one Scan: reads any code with the camera and opens it like a link or a paste.
/// A device-link code opens Link a device and an in-person code its dialog; everything else goes
/// to Send, whose router takes payment codes, addresses, pairing invites, epic1 links and refuses
/// a recovery phrase (the scan dialog already does).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../devices/device_link_code.dart' show isDeviceLinkText;
import '../../data/devices_state.dart' show deskLinkedDevicesOnProvider;
import '../../desk_l10n.dart';
import '../../app/routes.dart' show DeskRoute, deskNavProvider;
import '../devices/link_flow.dart' show showDeskLinkDevice;
import '../in_person/in_person_entry.dart' show openDeskInPersonText;
import '../transfer/send_screen.dart' show SendArgs;
import 'desk_scan.dart';
import 'desk_scan_text.dart';

/// Scan any code: the camera's text (origin qr) or the dialog's paste (origin paste).
Future<void> openDeskScan(BuildContext context, WidgetRef ref) async {
  final r = await deskScanQr(context, title: context.l10n.scanQrTitle, hint: context.l10n.scanQrHint);
  if (r == null || !context.mounted) return;
  final text = r.scanText;
  if (text.isEmpty) return;
  if (isDeviceLinkText(text) && ref.read(deskLinkedDevicesOnProvider)) {
    unawaited(showDeskLinkDevice(context, pasted: text));
    return;
  }
  if (await openDeskInPersonText(context, text) || !context.mounted) return;
  ref.read(deskNavProvider.notifier).go(DeskRoute.send, SendArgs(code: text, codeOrigin: r.origin));
}
