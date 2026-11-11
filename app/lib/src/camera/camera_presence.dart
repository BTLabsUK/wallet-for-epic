// SPDX-License-Identifier: Apache-2.0
/// Whether this computer has a camera for the QR scan, found without starting one (no camera
/// light): checked at app start and again when a screen that offers Scan opens. Present or
/// denied, Scan is offered; none or unsupported, Scan is greyed out with one quiet line and
/// paste stays the way.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart' show logInfo;
import '../wallet_backend.dart' show hostIsPhone;
import '../ui/qr_camera.dart' show fakeCameraMode;
import 'desktop_camera.dart' show createDesktopCameraProbe;

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

/// A probe that says why its last answer is what it is, for the log: the support library that
/// did not load, a missing media feature, an error code. Never a device name or path.
abstract interface class CameraProbeReason {
  String? get lastReason;
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

/// The probe of this host: the desktops list their cameras (desktop_qr_camera.dart), the
/// phones keep their own scanner and the web has none.
final cameraProbeProvider = Provider<CameraProbe>((ref) {
  // `WFE_FAKE_CAMERA` in a debug build: `none` and `unsupported` are this probe's answer, every
  // other value is present.
  if (fakeCameraMode.isNotEmpty) {
    return FakeCameraProbe(switch (fakeCameraMode) {
      'none' => CameraPresence.none,
      'unsupported' => CameraPresence.unsupported,
      _ => CameraPresence.present,
    });
  }
  if (!kIsWeb && !hostIsPhone) return createDesktopCameraProbe();
  return const NoCameraProbe();
});

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
    String? reason;
    try {
      final probe = ref.read(cameraProbeProvider);
      found = await probe.probe();
      if (probe case final CameraProbeReason said) reason = said.lastReason;
    } on Object catch (e) {
      found = CameraPresence.none;
      reason = e.runtimeType.toString();
    }
    _running = null;
    if (ref.mounted) {
      // The first answer too: it replaces `unknown`, which no probe answers.
      if (found != state) logInfo('camera', 'presence: ${found.name}${reason == null ? '' : ' ($reason)'}');
      state = found;
    }
    return found;
  }
}
