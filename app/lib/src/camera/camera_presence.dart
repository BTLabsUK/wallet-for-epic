// SPDX-License-Identifier: Apache-2.0
/// Whether this computer has a camera for the QR scan, found without starting one (no camera
/// light): checked at app start and again when a screen that offers Scan opens. Present or
/// denied, Scan is offered; none or unsupported, Scan is greyed out with one quiet line and
/// paste stays the way.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the probe found.
enum CameraPresence {
  /// Not checked yet: Scan shows, greyed out, with no line.
  unknown,

  /// A camera the app may open.
  present,

  /// A camera is there, but the system does not let this app open it.
  denied,

  /// No camera.
  none,

  /// This system lacks what the app needs to use a camera (Linux GStreamer or its V4L2 source,
  /// the Windows media features).
  unsupported;

  /// Scan is offered: a scan that fails says why in place.
  bool get offersScan => this == present || this == denied;
}

/// Lists the cameras without opening one. Never throws: a failure is [CameraPresence.none] or
/// [CameraPresence.unsupported].
abstract class CameraProbe {
  Future<CameraPresence> probe();
}

/// A probe that answers [presence], counting its calls.
class FakeCameraProbe implements CameraProbe {
  FakeCameraProbe([this.presence = CameraPresence.present]);

  CameraPresence presence;
  int probes = 0;

  @override
  Future<CameraPresence> probe() async {
    probes++;
    return presence;
  }
}

/// A probe for hosts with no desktop camera (phones keep their own scanner, the web has none).
class NoCameraProbe implements CameraProbe {
  const NoCameraProbe();

  @override
  Future<CameraPresence> probe() async => CameraPresence.none;
}

/// The probe of this host; the desktop one comes with the desktop camera.
final cameraProbeProvider = Provider<CameraProbe>((ref) => const NoCameraProbe());

/// The last answer of the probe. [CameraPresenceNotifier.recheck] asks again; calls while one is
/// running share it.
final cameraPresenceProvider = NotifierProvider<CameraPresenceNotifier, CameraPresence>(CameraPresenceNotifier.new);

class CameraPresenceNotifier extends Notifier<CameraPresence> {
  Future<CameraPresence>? _running;

  @override
  CameraPresence build() {
    // The first check, at once: Scan is right by the time a screen shows it.
    Future.microtask(recheck);
    return CameraPresence.unknown;
  }

  Future<CameraPresence> recheck() {
    final running = _running;
    if (running != null) return running;
    final next = _probe();
    _running = next;
    return next;
  }

  Future<CameraPresence> _probe() async {
    CameraPresence found;
    try {
      found = await ref.read(cameraProbeProvider).probe();
    } on Object {
      found = CameraPresence.none;
    }
    _running = null;
    if (ref.mounted) state = found;
    return found;
  }
}
