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
import '../../models.dart' show Chain;
import '../../network_gate.dart';
import '../../providers.dart' show secretStoreProvider;
import '../desk_l10n.dart';
import 'state.dart';

/// Linked devices is on (Settings › Advanced › Experimental).
final deskLinkedDevicesOnProvider = Provider<bool>((ref) => ref.watch(deskProvider.select((s) => s.settings.advanced.linkedDevicesOn)));

/// The pairing engine runs: for contacts (Pairing) or for linked devices. The device pairings
/// are private: they never show in Contacts, Pending invites, a picker or an export.
final deskPairingEngineOnProvider = Provider<bool>((ref) => ref.watch(deskProvider.select((s) => s.settings.advanced.pairingEngineOn)));

/// The open wallet's devices, or null while locked or with Linked devices off. It reads the
/// channel when the wallet opens, then every 5 s while the app runs (minimized too); the shell
/// reads it again on a window focus and on Refresh ([deskDevicesRefresh]).
final deskDeviceServiceProvider = Provider<DeviceService?>((ref) {
  if (!ref.watch(deskLinkedDevicesOnProvider)) return null;
  final account = ref.watch(deskProvider.select((s) => s.account == null ? null : (s.account!.id, s.account!.network, s.session)));
  if (account == null) return null;
  final api = ref.read(deskApiProvider);
  final host = api.deviceHost(online: () => !NetGate.epicboxOff && NetGate.linkedDevices);
  if (host == null) return null;
  final service = DeviceService(
    host: host,
    store: DeviceStore(ref.watch(secretStoreProvider), chain: account.$2 == 'floonet' ? Chain.floonet : Chain.mainnet, walletId: account.$1),
    defaultName: deskStrings.devicesThisComputer,
  );
  // What the history, the balance and the outputs show of the other devices.
  api.useDevices(() => service.loaded ? service.book : null);
  ref.onDispose(() {
    api.useDevices(null);
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
  // The app runs while it is minimized, and the channel is read the whole time.
  service.setForeground(true);
  unawaited(service.load().then((_) => service.sync(DeviceSyncTrigger.unlock)));
  return service;
});

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

/// The servers a first link proposes (D-3): this wallet's Epicbox server, then on mainnet one
/// built-in server of another operator (epiccash.com → stackwallet, stackwallet → epiccash.com,
/// any other → stackwallet). Values as the server list writes them: `host`, or `host:port` off
/// 443.
List<String> deskDefaultLinkServers({required String ownHost, int ownPort = 443, required bool mainnet}) {
  final own = ownPort == 443 ? ownHost : '$ownHost:$ownPort';
  if (!mainnet) return [own];
  final other = ownHost.endsWith('stackwallet.com') ? 'epicbox.epiccash.com' : 'epicbox.stackwallet.com';
  return other == ownHost ? [own] : [own, other];
}

/// [deskDefaultLinkServers] for the open wallet, from its Epicbox address.
final deskLinkServersProvider = Provider<List<String>>((ref) {
  final address = ref.watch(deskProvider.select((s) => s.epicboxAddress)) ?? '';
  final mainnet = ref.watch(deskProvider.select((s) => s.account?.network != 'floonet'));
  final at = address.lastIndexOf('@');
  final server = at < 0 ? 'epicbox.epiccash.com' : address.substring(at + 1);
  final colon = server.lastIndexOf(':');
  final port = colon < 0 ? null : int.tryParse(server.substring(colon + 1));
  return deskDefaultLinkServers(ownHost: port == null ? server : server.substring(0, colon), ownPort: port ?? 443, mainnet: mainnet);
});
