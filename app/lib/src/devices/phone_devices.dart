// SPDX-License-Identifier: Apache-2.0
/// The phone's linked devices: the open wallet's [DeviceService] while Linked devices is on
/// (Settings › Advanced › Experimental), and the runs on start, resume and unlock.
library;

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../models.dart' show InvoiceEvent, InvoiceEventKind, TxEntry, WalletError;
import '../ui/devices/device_parts.dart' show registerPhoneDeviceInviteHandler, unregisterPhoneDeviceInviteHandler;
import '../ui/notices.dart' show NoticeLevel, noticeProvider;
import '../network_gate.dart';
import '../pairing_providers.dart' show requestPassOnProvider;
import '../providers.dart';
import '../settings.dart';
import 'device_providers.dart';
import 'device_service.dart';
import 'device_store.dart';

/// Linked devices is on (off by default).
final linkedDevicesOnProvider = Provider<bool>(
  (ref) => ref.watch(appSettingsProvider.select((s) => s.value?.advanced.linkedDevicesOn)) ?? false,
);

/// The phone's strings, outside a widget.
AppLocalizations _strings() {
  try {
    return lookupAppLocalizations(PlatformDispatcher.instance.locale);
  } on FlutterError {
    return lookupAppLocalizations(const Locale('en'));
  }
}

/// This device's name until the user renames it, in the phone's language.
String phoneDeviceName() => _strings().devicesThisPhone;

/// The open wallet's devices, or null while locked or with Linked devices off.
final deviceServiceProvider = Provider<DeviceService?>((ref) {
  if (!ref.watch(linkedDevicesOnProvider)) return null;
  final session = ref.watch(sessionProvider);
  final config = ref.watch(walletConfigProvider.select((c) => c == null ? null : (chain: c.chain, walletId: c.walletId)));
  if (session == null || config == null) return null;
  final service = DeviceService(
    // In Tor only the channel waits for tor, so nothing reaches a link server directly.
    host: SessionDeviceHost(session, online: () => !NetGate.epicboxOff && NetGate.linkedDevices && !torOnlyWaiting),
    store: DeviceStore(ref.watch(secretStoreProvider), chain: config.chain, walletId: config.walletId),
    defaultName: phoneDeviceName(),
    nameWithCode: _strings().devicesNameWithCode,
  );
  ref.onDispose(service.dispose);
  // A request to pair from someone not in this phone's contacts goes to the linked device
  // before it is dismissed here.
  final passOn = ref.read(requestPassOnProvider)..run = service.passOnRequest;
  ref.onDispose(() {
    if (passOn.run == service.passOnRequest) passOn.run = null;
  });
  // Coins another device starts or stops holding change Home's balance: read it again.
  var held = session.heldOutputs;
  final sub = service.changes.listen((_) {
    final now = session.heldOutputs;
    if (now.length == held.length && now.containsAll(held)) return;
    held = now;
    if (ref.exists(homeProvider)) unawaited(ref.read(homeProvider.notifier).reload());
  });
  ref.onDispose(sub.cancel);
  // Notices that reached this device only go to the linked device; what it passed on is
  // applied here: the sender's report as if it came here, a request to pay as a notice.
  // A core without invoices has no events to pass on.
  StreamSubscription<InvoiceEvent>? events;
  try {
    events = session.invoiceEvents().listen((e) {
      final kind = switch (e.kind) {
        InvoiceEventKind.paymentPosted => ForwardKind.posted,
        InvoiceEventKind.paymentCancelled => ForwardKind.cancelled,
        InvoiceEventKind.received => ForwardKind.invoice,
        _ => null,
      };
      if (kind != null) unawaited(service.forward(kind, e.slateId, kernel: e.kernelExcess));
    }, onError: (_) {});
  } on WalletError {
    events = null;
  }
  ref.onDispose(() => events?.cancel());
  final forwarded = service.forwarded.listen((n) {
    final event = InvoiceEvent(kind: InvoiceEventKind.paymentPosted, slateId: n.slateId, kernelExcess: n.kernel);
    switch (n.kind) {
      case ForwardKind.posted:
        unawaited(ref.read(paymentPostedProvider.notifier).forwarded(event));
      case ForwardKind.cancelled:
        unawaited(ref.read(paymentCancelledProvider.notifier).forwarded(event));
      case ForwardKind.invoice:
        ref.read(noticeProvider.notifier).show(_strings().devicesForwardedInvoice(n.device), level: NoticeLevel.info);
    }
  });
  ref.onDispose(forwarded.cancel);
  // Opened or unlocked: one read, then every 5 s while on screen.
  unawaited(service.load().then((_) => service.sync(DeviceSyncTrigger.unlock)));
  service.setForeground(WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused);
  return service;
});

/// The phone's device providers ([DeviceProviders.view] and the rest).
final phoneDevices = DeviceProviders(deviceServiceProvider);

/// Keeps the devices' runs in step with the app's life: a read on resume, the 5 s timer only
/// while on screen. Holds no UI; the home shell puts it under its content.
class DeviceLifecycle extends ConsumerStatefulWidget {
  const DeviceLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeviceLifecycle> createState() => _DeviceLifecycleState();
}

class _DeviceLifecycleState extends ConsumerState<DeviceLifecycle> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A device link opens Link a device only while Linked devices is on.
    ref.listenManual<bool>(linkedDevicesOnProvider, (_, on) => on ? registerPhoneDeviceInviteHandler() : unregisterPhoneDeviceInviteHandler(), fireImmediately: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unregisterPhoneDeviceInviteHandler();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final service = ref.read(deviceServiceProvider);
    if (service == null) return;
    final on = state == AppLifecycleState.resumed;
    service.setForeground(on);
    if (on) unawaited(service.sync(DeviceSyncTrigger.resume));
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the service alive while the shell is up.
    ref.watch(deviceServiceProvider);
    return widget.child;
  }
}

/// [rows] (Home's list) with the linked devices' payments merged in, watched: for the lists and
/// the details that show history.
List<TxEntry> watchHistory(WidgetRef ref, List<TxEntry> rows) => withDeviceHistory(rows, ref.watch(phoneDevices.view));
