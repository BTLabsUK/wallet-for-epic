// SPDX-License-Identifier: Apache-2.0
/// Riverpod glue for linked devices, shared by the phone and the desktop: each app makes a
/// [DeviceProviders] over its own provider of the open wallet's [DeviceService] (null while
/// locked or with Linked devices off) and reads [DeviceProviders.view].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import 'device_history.dart';
import 'device_model.dart';
import 'device_service.dart';

/// What the screens show of the service: its book and the link being made.
class DeviceView {
  const DeviceView({required this.book, required this.link, required this.supported, required this.loaded});

  factory DeviceView.of(DeviceService s) => DeviceView(book: s.book, link: s.link, supported: s.supported, loaded: s.loaded);

  final DeviceBook book;
  final LinkFlow? link;

  /// The wallet's core links devices.
  final bool supported;
  final bool loaded;

  List<LinkedDevice> get devices => book.devices;

  /// The holds still in force, newest first.
  List<HeldPayment> get held => [
    for (final h in book.holds.reversed)
      if (h.state.holds) h,
  ];

  /// The name of [deviceId], or of a removed device as its holds remember it.
  String nameOf(String deviceId) =>
      book.device(deviceId)?.name ?? book.holds.where((h) => h.deviceId == deviceId).firstOrNull?.deviceName ?? '';
}

class DeviceProviders {
  DeviceProviders(this.service);

  /// The app's provider of the open wallet's service.
  final Provider<DeviceService?> service;

  /// The view, rebuilt on every change; null while there is no service.
  late final NotifierProvider<DeviceViewNotifier, DeviceView?> view = NotifierProvider<DeviceViewNotifier, DeviceView?>(
    () => DeviceViewNotifier(service),
  );

  /// The linked devices, empty without a service.
  late final Provider<List<LinkedDevice>> devices = Provider<List<LinkedDevice>>((ref) => ref.watch(view)?.devices ?? const []);
}

class DeviceViewNotifier extends Notifier<DeviceView?> {
  DeviceViewNotifier(this._service);

  final Provider<DeviceService?> _service;

  @override
  DeviceView? build() {
    final s = ref.watch(_service);
    if (s == null) return null;
    final sub = s.changes.listen((_) => state = DeviceView.of(s));
    ref.onDispose(sub.cancel);
    return DeviceView.of(s);
  }
}

/// [rows] with the linked devices' payments of [view] merged in ([mergeDeviceHistory]).
List<TxEntry> withDeviceHistory(List<TxEntry> rows, DeviceView? view) => view == null ? rows : mergeDeviceHistory(rows, view.book);

/// The value of the coins each device holds here: device id → sum of the held outputs' values
/// among [outputs] (for "x EPIC is held by a payment `<device>` is making.").
Map<String, BigInt> heldValueByDevice(DeviceBook book, List<WalletOutput> outputs) {
  final value = {for (final o in outputs) o.commitment: o.value};
  final out = <String, BigInt>{};
  for (final h in book.holds) {
    if (!h.state.holds) continue;
    for (final c in h.commitments) {
      out[h.deviceId] = (out[h.deviceId] ?? BigInt.zero) + (value[c] ?? BigInt.zero);
    }
  }
  return out;
}

/// The device holding the output [commitment] here, or null.
HeldPayment? holdOf(DeviceBook book, String commitment) =>
    book.holds.where((h) => h.state.holds && h.commitments.contains(commitment)).firstOrNull;
