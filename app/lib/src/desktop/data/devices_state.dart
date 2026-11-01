// SPDX-License-Identifier: Apache-2.0
/// The desktop's linked devices: the open wallet's [DeviceService] (shared with the phone,
/// `devices/`), its lifecycle and the places that read it. Linked devices is an Experimental
/// switch, on unless the user turned it off; off, there is no service and nothing of it shows.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/device_model.dart';
import '../../devices/device_providers.dart';
import '../../devices/device_service.dart';
import '../../devices/device_store.dart';
import '../../log.dart' show logWarn;
import '../../models.dart' show Chain, InvoiceEventKind;
import '../../network_gate.dart';
import '../../providers.dart' show secretStoreProvider;
import '../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../app/desk_window.dart' show deskWindowProvider;
import '../desk_l10n.dart';
import '../screens/devices/link_flow.dart' show registerDeskDeviceInviteHandler;
import 'state.dart';

/// Linked devices is on (Settings › Advanced › Experimental).
final deskLinkedDevicesOnProvider = Provider<bool>((ref) => ref.watch(deskProvider.select((s) => s.settings.advanced.linkedDevicesOn)));

/// The clock the devices' times are read against; the screenshot tour and the tests give the
/// mock's pairing clock, which the fake engine stamps its invites with.
final deskDeviceClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Where the controller finds the open wallet's service: the service provider depends on the
/// controller's state, so the controller cannot read it as a provider (a circular dependency).
class DeskDeviceHandle {
  DeviceService? service;
}

final deskDeviceHandleProvider = Provider<DeskDeviceHandle>((ref) => DeskDeviceHandle());

/// How often the desktop reads the channel with a device linked: the window has the focus, or not.
const Duration deskDevicesFocusedEvery = Duration(seconds: 15);
const Duration deskDevicesBlurredEvery = Duration(minutes: 1);

/// The open wallet's devices, or null while locked or with Linked devices off. It reads the
/// channel when the wallet opens, then every [deskDevicesFocusedEvery] while the window has the
/// focus and every [deskDevicesBlurredEvery] while it has not (minimized too); the shell
/// reads it again on a window focus and on Refresh ([deskDevicesRefresh]). One service per open
/// wallet: its host follows the session through a reopen, so a link under way is not lost.
final deskDeviceServiceProvider = Provider<DeviceService?>((ref) {
  if (!ref.watch(deskLinkedDevicesOnProvider)) return null;
  // An incoming device invite (a link the system opened) goes to the link dialog's confirm step.
  registerDeskDeviceInviteHandler();
  final account = ref.watch(deskProvider.select((s) => s.account == null ? null : (s.account!.id, s.account!.network)));
  if (account == null) return null;
  final api = ref.read(deskApiProvider);
  // In Tor only the channel waits for tor, so nothing reaches a link server directly.
  final host = api.deviceHost(online: () => !NetGate.epicboxOff && NetGate.linkedDevices && !torOnlyWaiting);
  if (host == null) return null;
  final service = DeviceService(
    host: host,
    store: DeviceStore(ref.watch(secretStoreProvider), chain: account.$2 == 'floonet' ? Chain.floonet : Chain.mainnet, walletId: account.$1),
    defaultName: deskStrings.devicesThisComputer,
    nameWithCode: deskStrings.devicesNameWithCode,
    kind: DeviceKind.desktop,
    clock: ref.read(deskDeviceClockProvider),
  );
  // What the history, the balance and the outputs show of the other devices.
  api.useDevices(() => service.loaded ? service.book : null);
  final handle = ref.read(deskDeviceHandleProvider)..service = service;
  ref.onDispose(() {
    api.useDevices(null);
    if (identical(handle.service, service)) handle.service = null;
    service.dispose();
  });
  // A change of the book (a notice read, a coin released) shows in the lists at once.
  var shown = service.book;
  final sub = service.changes.listen((_) {
    if (identical(shown, service.book)) return;
    shown = service.book;
    unawaited(ref.read(deskProvider.notifier).reloadWallet());
  });
  ref.onDispose(sub.cancel);
  // Notices that reached this device only go to the linked device; what it passed on is
  // applied here (the lists read again, a request to pay announced).
  api.noticeForwarder = (e) => unawaited(service.forward(_forwardKindOf(e.kind)!, e.slateId, kernel: e.kernelExcess));
  final forwarded = service.forwarded.listen((n) => unawaited(api.applyForwarded(n)));
  ref.onDispose(() {
    api.noticeForwarder = null;
    forwarded.cancel();
  });
  // The app runs while it is minimized, and the channel is read the whole time: every 15 s
  // while the window has the focus, every minute while it has not (behind another window,
  // minimized). Back to the front, it is read at once.
  service.setForeground(true);
  final window = ref.read(deskWindowProvider).state;
  var focused = window.value.focused;
  service.setPace(focused ? deskDevicesFocusedEvery : deskDevicesBlurredEvery);
  void onWindow() {
    if (window.value.focused == focused) return;
    focused = window.value.focused;
    service.setPace(focused ? deskDevicesFocusedEvery : deskDevicesBlurredEvery, now: focused);
  }

  window.addListener(onWindow);
  ref.onDispose(() => window.removeListener(onWindow));
  // A store that cannot be read leaves the devices unloaded; the app itself goes on.
  unawaited(
    service.load().then((_) => service.sync(DeviceSyncTrigger.unlock)).catchError((Object e) {
      logWarn('devices', 'linked devices not loaded: ${e.runtimeType}');
    }),
  );
  return service;
});

/// What a wallet notice is for the linked device, or null for one that is not passed on.
ForwardKind? _forwardKindOf(InvoiceEventKind kind) => switch (kind) {
  InvoiceEventKind.paymentPosted => ForwardKind.posted,
  InvoiceEventKind.paymentCancelled => ForwardKind.cancelled,
  InvoiceEventKind.received => ForwardKind.invoice,
  _ => null,
};

/// The desktop's device providers ([DeviceProviders.view] and the rest).
final deskDevices = DeviceProviders(deskDeviceServiceProvider);

/// The view of the devices; null while there is no service.
final deskDeviceViewProvider = Provider<DeviceView?>((ref) => ref.watch(deskDevices.view));

/// The devices' book; empty while there is no service.
final deskDeviceBookProvider = Provider<DeviceBook?>((ref) => ref.watch(deskDeviceViewProvider)?.book);

/// Reads the channel once for [trigger] (window focus, Refresh); nothing without a service.
void deskDevicesRefresh(Ref ref, DeviceSyncTrigger trigger) {
  final service = ref.read(deskDeviceServiceProvider);
  if (service != null) unawaited(service.sync(trigger));
}

/// The coins other devices hold, per device: id → value in nano (for "x EPIC is held by a
/// payment `<device>` is making."), from the outputs the Outputs page reads.
final deskHeldProvider = Provider<List<({String device, int value})>>((ref) {
  final view = ref.watch(deskDeviceViewProvider);
  final outputs = ref.watch(deskOutputsProvider).value;
  if (view == null || outputs == null) return const [];
  final byDevice = <String, int>{};
  for (final o in outputs) {
    final name = o.heldBy;
    if (name != null) byDevice[name] = (byDevice[name] ?? 0) + o.value;
  }
  return [for (final e in byDevice.entries) (device: e.key, value: e.value)];
});

/// The servers a link proposes ([defaultLinkServers]): this wallet's Epicbox server, then the
/// others of the first `epicbox.link_servers` of the Epicbox list.
List<String> deskDefaultLinkServers({required String ownHost, int ownPort = 443, List<String>? servers}) =>
    defaultLinkServers(ownHost: ownHost, ownPort: ownPort, servers: servers);

/// [deskDefaultLinkServers] for the open wallet, from its Epicbox address.
final deskLinkServersProvider = Provider<List<String>>((ref) {
  final address = ref.watch(deskProvider.select((s) => s.epicboxAddress)) ?? '';
  final settings = ref.watch(hostSettingsProvider);
  final at = address.lastIndexOf('@');
  final server = at < 0 ? settings.epicboxUse : address.substring(at + 1);
  final colon = server.lastIndexOf(':');
  final port = colon < 0 ? null : int.tryParse(server.substring(colon + 1));
  return deskDefaultLinkServers(ownHost: port == null ? server : server.substring(0, colon), ownPort: port ?? 443, servers: settings.deviceLinkServers);
});
