// SPDX-License-Identifier: Apache-2.0
/// The camera library behind QR scanning: the only file that imports it. Free code only, in
/// every build: the camera plugin (CameraX on Android, AVFoundation on iOS, Apache-2.0/BSD) for
/// the picture and zxing-cpp (Apache-2.0, through flutter_zxing) for the codes. No Google ML Kit
/// or Play services. Phones only (qrScanSupported in scan_screen.dart); desktops and the web have no scanner.
library;

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart' as zxing;

/// Why the camera is not usable.
enum ScannerError {
  /// The user refused the camera permission.
  denied,

  /// The camera could not start for another reason.
  failed,
}

/// What [ScannerController.start] throws. The error is also kept in
/// [ScannerController.error].
class ScannerException implements Exception {
  const ScannerException(this.error);

  final ScannerError error;

  @override
  String toString() => 'ScannerException($error)';
}

/// The camera of one scan screen, reading QR codes only. Started by hand, so the permission
/// prompt can run under the auto-lock hold.
class ScannerController extends ChangeNotifier {
  /// With [everyFrame], [codes] hands out the code of every frame, repeats included (an
  /// animated code changes six times a second); without, repeats of one code are dropped.
  ScannerController({this.everyFrame = false});

  final bool everyFrame;

  final StreamController<String> _codes = StreamController<String>.broadcast();
  CameraController? _camera;
  ScannerError? _error;
  bool _torchAvailable = false;
  bool _torchOn = false;
  bool _decoding = false;
  bool _closed = false;
  bool _starting = false;
  Future<void>? _releasing;
  String? _last;
  late final _lifecycle = ScannerLifecycle(onPause: _release, onResume: start);

  ScannerError? get error => _error;

  bool get torchAvailable => _torchAvailable;

  bool get torchOn => _torchOn;

  /// The trimmed text of each code read, empty ones left out.
  Stream<String> get codes => _codes.stream;

  void _changed() {
    if (!_closed) notifyListeners();
  }

  Future<void> start() async {
    if (_closed || _starting || (_camera?.value.isStreamingImages ?? false)) {
      return;
    }
    _lifecycle.watch();
    _starting = true;
    _error = null;
    _changed();
    try {
      // zxing's worker is shared: a release still under way must stop it before this starts it.
      await _releasing;
      if (_closed) return;
      var camera = _camera;
      if (camera == null) {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          throw CameraException('NoCamera', 'No camera on this device');
        }
        final back = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        // 720p: dense codes stay sharp, and zxing-cpp reads a frame in a few ms.
        camera = CameraController(
          back,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        _camera = camera;
      }
      if (!camera.value.isInitialized) await camera.initialize();
      if (_closed) return;
      // The camera API does not say whether there is a flash: offered on a back camera, and
      // taken away when switching it on fails.
      _torchAvailable =
          camera.description.lensDirection == CameraLensDirection.back;
      await zxing.zx.startCameraProcessing();
      if (_closed) return;
      await camera.startImageStream(_onFrame);
      _changed();
    } on CameraException catch (error) {
      // CameraAccessDenied, CameraAccessDeniedWithoutPrompt, CameraAccessRestricted.
      _error = error.code.startsWith('CameraAccess')
          ? ScannerError.denied
          : ScannerError.failed;
      final camera = _camera;
      _camera = null;
      unawaited(camera?.dispose());
      _changed();
      throw ScannerException(_error!);
    } finally {
      _starting = false;
    }
  }

  /// Gives the camera back while the app is in the background: the system takes it, and the
  /// old controller shows black from then on. [ScannerLifecycle] starts it again on return.
  /// Not while a start is under way: the permission prompt itself makes the app inactive.
  Future<void> _release() {
    final camera = _camera;
    if (_closed || _starting || camera == null) return Future.value();
    _camera = null;
    _torchOn = false;
    _changed();
    return _releasing = () async {
      try {
        if (camera.value.isStreamingImages) await camera.stopImageStream();
      } on CameraException {
        // Released anyway.
      }
      await camera.dispose();
      zxing.zx.stopCameraProcessing();
      _releasing = null;
    }();
  }

  /// Reads the frames one at a time: those that come while one is read are dropped.
  Future<void> _onFrame(CameraImage image) async {
    if (_decoding || _closed) return;
    _decoding = true;
    try {
      final text = await readFrame(image);
      if (_closed || text == null) return;
      if (!everyFrame && text == _last) return;
      _last = text;
      _codes.add(text);
    } catch (_) {
      // A frame that fails to read is like one without a code.
    } finally {
      _decoding = false;
    }
  }

  Future<void> toggleTorch() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || !_torchAvailable) {
      return;
    }
    try {
      await camera.setFlashMode(_torchOn ? FlashMode.off : FlashMode.torch);
      _torchOn = !_torchOn;
    } on CameraException {
      _torchAvailable = false;
      _torchOn = false;
    }
    _changed();
  }

  /// 2× when [twice], else 1×.
  Future<void> setZoom({required bool twice}) async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      final min = await camera.getMinZoomLevel();
      final max = await camera.getMaxZoomLevel();
      await camera.setZoomLevel((twice ? 2.0 : 1.0).clamp(min, max));
    } on CameraException {
      // Zoom is a help, not a must.
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _lifecycle.stop();
    final camera = _camera;
    _camera = null;
    try {
      if (camera?.value.isStreamingImages ?? false) {
        await camera!.stopImageStream();
      }
    } on CameraException {
      // Closing anyway.
    }
    await camera?.dispose();
    zxing.zx.stopCameraProcessing();
    await _codes.close();
    dispose();
  }
}

/// Calls [onPause] when the app leaves the foreground and [onResume] when it is back, once
/// each, from [watch] until [stop]. [onResume] comes only after an [onPause], so a screen
/// that came back from the system settings tries the camera again.
class ScannerLifecycle with WidgetsBindingObserver {
  ScannerLifecycle({required this.onPause, required this.onResume});

  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  bool _watching = false;
  bool _paused = false;

  void watch() {
    if (_watching) return;
    _watching = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    if (!_watching) return;
    _watching = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive ||
          AppLifecycleState.hidden ||
          AppLifecycleState.paused:
        if (_paused) return;
        _paused = true;
        unawaited(onPause());
      case AppLifecycleState.resumed:
        if (!_paused) return;
        _paused = false;
        unawaited(
          onResume().catchError((Object _) {
            // A failed restart is kept in the controller's error, which the screen shows.
          }),
        );
      case AppLifecycleState.detached:
        break;
    }
  }
}

/// The trimmed text of the QR code in one camera frame, or null. Decodes on zxing's worker
/// isolate, which [ScannerController.start] starts.
Future<String?> readFrame(CameraImage image) async {
  final format = zxing.cameraImageFormat(image);
  if (format == zxing.ImageFormat.none) return null;
  final code = await zxing.zx.processCameraImage(
    image,
    zxing.DecodeParams(
      imageFormat: format,
      format: zxing.Format.qrCode,
      width: image.width,
      height: image.height,
    ),
  );
  final text = code.isValid ? code.text?.trim() : null;
  return text == null || text.isEmpty ? null : text;
}

/// The camera picture of [controller], filling its parent; [errorBuilder] draws what shows
/// instead while the camera is not usable (nothing by default).
class ScannerPreview extends StatelessWidget {
  const ScannerPreview({
    super.key,
    required this.controller,
    this.errorBuilder,
  });

  final ScannerController controller;
  final Widget Function(BuildContext context, ScannerError error)? errorBuilder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.error case final error?) {
        return errorBuilder?.call(context, error) ?? const SizedBox.shrink();
      }
      final camera = controller._camera;
      final size = camera?.value.previewSize;
      if (camera == null || !camera.value.isInitialized || size == null) {
        return const ColoredBox(color: Colors.black);
      }
      // The preview size is landscape; the phone holds it upright. Cover the frame.
      return ColoredBox(
        color: Colors.black,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.height,
              height: size.width,
              child: CameraPreview(camera),
            ),
          ),
        ),
      );
    },
  );
}
