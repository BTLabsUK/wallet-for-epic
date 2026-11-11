// SPDX-License-Identifier: Apache-2.0
/// Screenshot tour entries for the desktop QR scan: each state of the scan dialog on a camera
/// that holds it, and Scan greyed out with its quiet line under a paste field.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../camera/camera_presence.dart';
import '../../../ui/qr_camera.dart';
import '../../app/shots.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'desk_scan.dart';

/// A camera for the tour: [starting] never finishes its start, [problem] is its state after the
/// start, [code] is read once it runs. The picture is a code held in front of the camera.
class _ShotCamera extends ChangeNotifier implements QrCamera {
  _ShotCamera({this.starting = false, this.problem, this.code});

  final bool starting;
  final QrCameraProblem? problem;
  final String? code;
  final StreamController<String> _codes = StreamController<String>.broadcast();
  QrCameraState _state = const QrCameraState();

  @override
  QrCameraState get value => _state;

  @override
  Stream<String> get codes => _codes.stream;

  @override
  Future<void> start() async {
    if (starting) return Completer<void>().future;
    _state = QrCameraState(problem: problem);
    notifyListeners();
    final text = code;
    if (text != null) scheduleMicrotask(() => _codes.isClosed ? null : _codes.add(text));
  }

  @override
  Future<void> toggleTorch() async {}

  @override
  Future<void> setZoom({required bool twice}) async {}

  @override
  Widget preview(BuildContext context) {
    final black = problem == QrCameraProblem.dark;
    final c = context.dc;
    return ColoredBox(
      color: black ? c.bg : c.s4,
      child: black ? null : Center(child: Transform.rotate(angle: -0.05, child: EQr('epic:shot-scan-picture', size: 104.u))),
    );
  }

  @override
  Future<void> close() async {
    await _codes.close();
    dispose();
  }
}

/// Reads every text as part [received] of [total].
class _PartsAt implements DeskPartReader<String> {
  const _PartsAt(this.received, this.total);
  final int received, total;

  @override
  DeskPartStep<String> read(String text) => DeskPartWaiting(received, total);
}

/// The scan dialog on [camera], on [os]'s words.
Future<void> Function(BuildContext) _scan(_ShotCamera Function() camera, {DeskScanOs os = DeskScanOs.windows, DeskPartReader<String>? reader}) =>
    (ctx) {
      deskScanOsOverride = os;
      final l = ctx.l10n;
      return showEDialog<void>(
        ctx,
        builder: (_) => ProviderScope(
          overrides: [qrCameraFactoryProvider.overrideWithValue(camera)],
          child: DeskScanDialog<String>(title: l.scanQrTitle, hint: l.deskSendToHelp, reader: reader ?? const DeskSingleReader()),
        ),
      );
    };

/// A presence fixed at [value].
class _FixedPresence extends CameraPresenceNotifier {
  _FixedPresence(this.value);
  final CameraPresence value;

  @override
  CameraPresence build() => value;

  @override
  Future<CameraPresence> recheck() async => value;
}

/// A paste field as a screen has it, with Scan beside Paste and the quiet line under it.
Future<void> Function(BuildContext) _host(CameraPresence presence, {DeskScanOs os = DeskScanOs.linux}) => (ctx) {
  deskScanOsOverride = os;
  return showEDialog<void>(
    ctx,
    builder: (_) => ProviderScope(
      overrides: [cameraPresenceProvider.overrideWith(() => _FixedPresence(presence))],
      child: Builder(
        builder: (context) {
          final l = context.l10n;
          return EDialog(
            title: l.deskSendTitle,
            icon: EIcons.send,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EField(
                  label: l.deskSendTo,
                  child: EInput(
                    hint: l.deskSendToHint,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EIconButton(icon: EIcons.paste, label: l.commonPaste, size: EBtnSize.inline, onPressed: () {}),
                        DeskScanButton(onScan: () {}),
                      ],
                    ),
                  ),
                ),
                const DeskNoCameraLine(),
              ],
            ),
            actions: [EButton(label: l.commonClose, onPressed: () => Navigator.of(context).pop())],
          );
        },
      ),
    ),
  );
};

DeskShot _shot(String id, String title, Future<void> Function(BuildContext) dialog) => DeskShot(id: id, title: title, route: DeskRoute.send, dialog: dialog);

/// Screenshot tour entries for the desktop QR scan (see app/shots.dart).
final List<DeskShot> scanShots = [
  _shot('70-scan-starting', 'Scan: the camera starting', _scan(() => _ShotCamera(starting: true))),
  _shot('70b-scan-live', 'Scan: the live picture and the aim line', _scan(_ShotCamera.new)),
  _shot('70c-scan-progress', 'Scan: an animated code, 3 of 8 parts in', _scan(() => _ShotCamera(code: 'part'), reader: const _PartsAt(3, 8))),
  _shot('70d-scan-refused', 'Scan: a recovery phrase in view, refused', _scan(() => _ShotCamera(code: List.filled(12, 'abandon').join(' ')))),
  _shot('70e-scan-dark', 'Scan: the picture black (cover closed), over the live picture', _scan(() => _ShotCamera(problem: QrCameraProblem.dark))),
  _shot('71-scan-denied-windows', 'Scan problem: camera access off (Windows)', _scan(() => _ShotCamera(problem: QrCameraProblem.denied))),
  _shot('71b-scan-denied-macos', 'Scan problem: camera access off (macOS)', _scan(() => _ShotCamera(problem: QrCameraProblem.denied), os: DeskScanOs.macos)),
  _shot('71c-scan-denied-linux', 'Scan problem: camera not allowed (Linux)', _scan(() => _ShotCamera(problem: QrCameraProblem.denied), os: DeskScanOs.linux)),
  _shot('71d-scan-unsupported-linux', 'Scan problem: GStreamer missing (Linux)', _scan(() => _ShotCamera(problem: QrCameraProblem.unsupported), os: DeskScanOs.linux)),
  _shot('71e-scan-unsupported-windows', 'Scan problem: media features missing (Windows)', _scan(() => _ShotCamera(problem: QrCameraProblem.unsupported))),
  _shot('71f-scan-busy', 'Scan problem: another app has the camera', _scan(() => _ShotCamera(problem: QrCameraProblem.busy))),
  _shot('71g-scan-failed', 'Scan problem: the camera did not start', _scan(() => _ShotCamera(problem: QrCameraProblem.failed))),
  _shot('71h-scan-no-picture', 'Scan problem: no picture', _scan(() => _ShotCamera(problem: QrCameraProblem.noPicture))),
  _shot('71i-scan-unplugged', 'Scan problem: the camera disconnected', _scan(() => _ShotCamera(problem: QrCameraProblem.unplugged))),
  _shot('71j-scan-reader-failed', 'Scan problem: the QR reader did not start', _scan(() => _ShotCamera(problem: QrCameraProblem.readerFailed))),
  _shot('72-scan-no-camera', 'Paste field: Scan greyed out, no camera found', _host(CameraPresence.none)),
  _shot('72b-scan-unsupported', 'Paste field: Scan greyed out, camera support missing (Linux)', _host(CameraPresence.unsupported)),
  _shot('72c-scan-present', 'Paste field: Scan offered, a camera found', _host(CameraPresence.present)),
];
