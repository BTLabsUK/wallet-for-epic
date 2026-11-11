// SPDX-License-Identifier: Apache-2.0
/// The desktop QR camera (Linux, macOS, Windows), on the vendored camera_desktop plugin
/// (`packages/camera_desktop`): one camera, chosen without a picker, its frames read by
/// zxing-cpp on a worker isolate about six times a second, QR codes only.
///
/// Watches the picture and says why there is none, never throws: no first frame, frames that
/// stop or repeat (No picture), a black picture (Dark, which clears by itself), a camera that
/// goes away (Unplugged) and a reader that fails. The plugin's error codes give Denied, Busy,
/// Unplugged and Unsupported. Every final problem gives the camera back at once; nothing
/// retries by itself. Only a hidden or minimised window pauses the camera.
library;

import 'dart:async';
import 'dart:io' show File;

import 'package:camera/camera.dart' show CameraImage;
import 'package:camera_desktop/camera_desktop.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_zxing/flutter_zxing.dart' as zxing show zx;

import '../ui/qr_camera.dart';
import '../ui/scanner_backend.dart' show CameraHolder, CameraTurns, ScannerLifecycle, readFrame;
import 'camera_presence.dart';
import 'desktop_camera.dart';

QrCamera createDesktopQrCamera(DesktopCameraTimings timings) => DesktopQrCamera(timings: timings);

CameraProbe createDesktopCameraProbe() => DesktopCameraProbe();

/// The plugin the app registered for this desktop, else one of our own (tests, a host where
/// registration did not run).
CameraDesktopPlugin desktopCameraPlugin() {
  final registered = CameraPlatform.instance;
  return registered is CameraDesktopPlugin ? registered : _ownPlugin ??= CameraDesktopPlugin();
}

CameraDesktopPlugin? _ownPlugin;

/// The problem for one of the plugin's error codes ([CameraDesktopErrorCode]).
QrCameraProblem problemOfCode(String code) => switch (code) {
  CameraDesktopErrorCode.denied => QrCameraProblem.denied,
  CameraDesktopErrorCode.busy => QrCameraProblem.busy,
  CameraDesktopErrorCode.unplugged || CameraDesktopErrorCode.noDevice => QrCameraProblem.unplugged,
  CameraDesktopErrorCode.noPicture => QrCameraProblem.noPicture,
  CameraDesktopErrorCode.unsupported => QrCameraProblem.unsupported,
  _ => QrCameraProblem.failed,
};

/// The node number of a Linux camera, from the name the plugin gives it ("Name (/dev/video2)").
int? videoNode(String name) {
  final match = RegExp(r'\(/dev/video(\d+)\)$').firstMatch(name);
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// The camera to scan with, of those the app may open: the first built-in one (macOS,
/// Windows), else the lowest Linux node (the laptop's own camera comes first), else the first.
CameraDesktopDevice? chooseCamera(List<CameraDesktopDevice> devices) {
  final allowed = [for (final d in devices) if (!d.denied) d];
  if (allowed.isEmpty) return null;
  for (final d in allowed) {
    if (d.builtIn) return d;
  }
  CameraDesktopDevice? lowest;
  int? lowestNode;
  for (final d in allowed) {
    final node = videoNode(d.description.name);
    if (node != null && (lowestNode == null || node < lowestNode)) {
      lowest = d;
      lowestNode = node;
    }
  }
  return lowest ?? allowed.first;
}

/// What the picture checks need of one frame: its brightness and a coarse grid of it.
@immutable
class FrameLook {
  const FrameLook({required this.mean, required this.max, required this.grid});

  /// Reads a 16 × 9 grid of the frame's luma. BGRA, or RGBA when the format's raw says so.
  factory FrameLook.of(CameraImageData frame) {
    final grid = Uint8List(columns * rows);
    if (frame.planes.isEmpty || frame.width <= 0 || frame.height <= 0) return FrameLook(mean: 0, max: 0, grid: grid);
    final plane = frame.planes.first;
    final bytes = plane.bytes;
    final stride = plane.bytesPerRow;
    final rgba = frame.format.raw == 'RGBA';
    final r = rgba ? 0 : 2;
    final b = rgba ? 2 : 0;
    var sum = 0;
    var max = 0;
    for (var row = 0; row < rows; row++) {
      final y = (row * 2 + 1) * frame.height ~/ (rows * 2);
      for (var column = 0; column < columns; column++) {
        final x = (column * 2 + 1) * frame.width ~/ (columns * 2);
        final at = y * stride + x * 4;
        if (at + 3 >= bytes.length) continue;
        final luma = (54 * bytes[at + r] + 183 * bytes[at + 1] + 19 * bytes[at + b]) >> 8;
        grid[row * columns + column] = luma;
        sum += luma;
        if (luma > max) max = luma;
      }
    }
    return FrameLook(mean: sum / grid.length, max: max, grid: grid);
  }

  static const columns = 16;
  static const rows = 9;

  /// The grid's luma, 0 to 255.
  final double mean;
  final int max;
  final Uint8List grid;

  /// A closed cover or lens shutter: black, with only sensor noise.
  bool get dark => mean <= 12 && max <= 40;

  /// The same picture: a live camera's noise changes the grid from frame to frame.
  bool same(FrameLook other) => listEquals(grid, other.grid);
}

/// Reads the QR code in a frame, off the UI thread.
abstract class QrFrameReader {
  Future<void> start();

  /// The code's trimmed text, or null.
  Future<String?> read(CameraImageData frame);

  /// Once for each [start] that succeeded.
  void stop();
}

/// zxing-cpp on its worker isolate, shared with the phone scanner.
class ZxingFrameReader implements QrFrameReader {
  const ZxingFrameReader();

  @override
  Future<void> start() => zxing.zx.startCameraProcessing();

  @override
  Future<String?> read(CameraImageData frame) => readFrame(CameraImage.fromPlatformInterface(frame));

  @override
  void stop() => zxing.zx.stopCameraProcessing();
}

/// The resources and checks of one run, from [DesktopQrCamera.start] to its release.
class _Run {
  bool over = false;
  int? cameraId;
  bool reading = false;
  int? node;
  final subscriptions = <StreamSubscription<Object?>>[];
  Timer? firstFrame;
  Timer? stall;
  Timer? frozen;
  Timer? dark;
  Timer? decodeTicks;
  bool decodeDue = true;
  bool decoding = false;
  int readerErrors = 0;
  FrameLook? last;

  void stopChecks() {
    for (final t in [firstFrame, stall, frozen, dark, decodeTicks]) {
      t?.cancel();
    }
  }
}

/// The picture of a run, for [DesktopQrCamera.preview].
@immutable
class _Picture {
  const _Picture(this.cameraId, this.size);
  final int cameraId;
  final Size? size;
}

class DesktopQrCamera extends ChangeNotifier implements QrCamera, CameraHolder {
  DesktopQrCamera({
    CameraDesktopPlugin? plugin,
    this.timings = const DesktopCameraTimings(),
    this.reader = const ZxingFrameReader(),
    @visibleForTesting bool Function(String path)? nodeExists,
  }) : _plugin = plugin ?? desktopCameraPlugin(),
       _nodeExists = nodeExists ?? ((path) => File(path).existsSync()) {
    _lifecycle = ScannerLifecycle(onPause: _pause, onResume: _resume, pauseWhenInactive: false);
  }

  final CameraDesktopPlugin _plugin;
  final DesktopCameraTimings timings;
  final QrFrameReader reader;
  final bool Function(String path) _nodeExists;
  late final ScannerLifecycle _lifecycle;

  /// About six reads a second, as on the phones.
  static const decodeEvery = Duration(milliseconds: 1000 ~/ 6);

  final StreamController<String> _codes = StreamController<String>.broadcast();
  final ValueNotifier<_Picture?> _picture = ValueNotifier<_Picture?>(null);
  QrCameraState _state = const QrCameraState();
  _Run? _run;
  bool _closed = false;

  /// A hidden window let the camera go; showing it starts the camera again.
  bool _paused = false;

  @override
  QrCameraState get value => _state;

  @override
  Stream<String> get codes => _codes.stream;

  void _set(QrCameraState next) {
    if (_closed || next == _state) return;
    _state = next;
    notifyListeners();
  }

  bool get _running => _run != null && !_run!.over;

  @override
  Future<void> start() async {
    if (_closed || _running) return;
    final run = _run = _Run();
    _paused = false;
    CameraTurns.take(this);
    _lifecycle.watch();
    _set(_state.copyWith(clearProblem: true));
    run.firstFrame = Timer(timings.firstFrame, () => _fail(run, QrCameraProblem.noPicture));
    await CameraTurns.free;
    if (run.over) return;
    try {
      final devices = await _plugin.listDevices();
      if (run.over) return;
      if (devices.isEmpty) return _fail(run, QrCameraProblem.unplugged);
      final device = chooseCamera(devices);
      if (device == null) return _fail(run, QrCameraProblem.denied);
      run.node = videoNode(device.description.name);
      final id = await _plugin.createCameraWithSettings(
        device.description,
        const MediaSettings(resolutionPreset: ResolutionPreset.high, fps: 30),
      );
      run.cameraId = id;
      if (run.over) return _releaseLate(run);
      run.subscriptions
        ..add(
          _plugin.onCameraError(id).listen((e) => _fail(run, e is CameraDesktopErrorEvent ? problemOfCode(e.code) : QrCameraProblem.failed)),
        )
        // The plugin sends this when the native side lets the camera go by itself.
        ..add(_plugin.onCameraClosing(id).listen((_) => _fail(run, QrCameraProblem.unplugged)))
        ..add(
          _plugin.onCameraInitialized(id).listen((e) {
            if (!run.over) _picture.value = _Picture(id, Size(e.previewWidth, e.previewHeight));
          }),
        );
      await _plugin.initializeCamera(id);
      if (run.over) return;
      _picture.value ??= _Picture(id, null);
    } on CameraException catch (e) {
      return _fail(run, problemOfCode(e.code));
    } on Object {
      // No plugin on this host (MissingPluginException), or a reply it should not give.
      return _fail(run, QrCameraProblem.failed);
    }
    try {
      await reader.start();
    } on Object {
      return _fail(run, QrCameraProblem.readerFailed);
    }
    run.reading = true;
    if (run.over) return _releaseLate(run);
    run.decodeTicks = Timer.periodic(decodeEvery, (_) => run.decodeDue = true);
    run.subscriptions.add(
      _plugin
          .onStreamedFrameAvailable(run.cameraId!)
          .listen(
            (frame) => _onFrame(run, frame),
            onError: (Object e) => _fail(run, e is CameraException ? problemOfCode(e.code) : QrCameraProblem.failed),
          ),
    );
  }

  void _onFrame(_Run run, CameraImageData frame) {
    if (run.over) return;
    run.firstFrame?.cancel();
    run.stall?.cancel();
    run.stall = Timer(timings.stall, () => _onStall(run));
    final look = FrameLook.of(frame);
    if (look.dark) {
      // A covered lens is black, not frozen: the frozen check starts again on the next picture.
      run.frozen?.cancel();
      run.frozen = null;
      run.last = null;
      run.dark ??= Timer(timings.dark, () {
        if (!run.over && _state.problem == null) _set(_state.copyWith(problem: QrCameraProblem.dark));
      });
      return;
    }
    run.dark?.cancel();
    run.dark = null;
    if (_state.problem == QrCameraProblem.dark) _set(_state.copyWith(clearProblem: true));
    final last = run.last;
    if (last == null || !look.same(last)) {
      run.last = look;
      run.frozen?.cancel();
      run.frozen = Timer(timings.frozen, () => _fail(run, QrCameraProblem.noPicture));
    }
    if (run.decodeDue && !run.decoding) _decode(run, frame);
  }

  void _decode(_Run run, CameraImageData frame) {
    run.decodeDue = false;
    run.decoding = true;
    reader.read(frame).then(
      (text) {
        run.decoding = false;
        if (run.over) return;
        run.readerErrors = 0;
        if (text != null && !_codes.isClosed) _codes.add(text);
      },
      onError: (Object _) {
        run.decoding = false;
        if (run.over) return;
        // One bad frame is not a broken reader; three in a row are.
        if (++run.readerErrors >= 3) _fail(run, QrCameraProblem.readerFailed);
      },
    );
  }

  /// Frames stopped: a Linux camera whose node went away was unplugged.
  void _onStall(_Run run) {
    final node = run.node;
    final gone = node != null && !_nodeExists('/dev/video$node');
    _fail(run, gone ? QrCameraProblem.unplugged : QrCameraProblem.noPicture);
  }

  /// The first final problem of [run] wins: the camera is given back and stays off.
  void _fail(_Run run, QrCameraProblem problem) {
    if (run.over || _closed) return;
    unawaited(_release(run));
    _lifecycle.stop();
    _set(_state.copyWith(problem: problem));
  }

  /// Ends [run] and gives the camera back, after every release before it.
  Future<void> _release(_Run run) {
    run.over = true;
    run.stopChecks();
    for (final s in run.subscriptions) {
      unawaited(s.cancel());
    }
    run.subscriptions.clear();
    if (identical(_run, run)) _picture.value = null;
    final release = _takeResources(run);
    if (identical(_run, run)) return CameraTurns.giveBack(this, release);
    return release == null ? Future.value() : CameraTurns.release(release);
  }

  /// What [run] opened after it ended, given back without touching who holds the camera now.
  void _releaseLate(_Run run) {
    final release = _takeResources(run);
    if (release != null) unawaited(CameraTurns.release(release));
  }

  Future<void> Function()? _takeResources(_Run run) {
    final id = run.cameraId;
    final reading = run.reading;
    run.cameraId = null;
    run.reading = false;
    if (id == null && !reading) return null;
    return () async {
      if (reading) reader.stop();
      if (id != null) await _plugin.dispose(id);
    };
  }

  @override
  void yieldCamera() {
    final run = _run;
    _lifecycle.stop();
    if (run != null && !run.over) unawaited(_release(run));
  }

  Future<void> _pause() async {
    final run = _run;
    if (_closed || run == null || run.over) return;
    _paused = true;
    await _release(run);
  }

  Future<void> _resume() async {
    if (_closed || !_paused) return;
    await start();
  }

  /// Desktop cameras have no torch.
  @override
  Future<void> toggleTorch() async {}

  /// Kept for the screen's 2× switch; the desktop picture is not zoomed.
  @override
  Future<void> setZoom({required bool twice}) async => _set(_state.copyWith(zoomed: twice));

  /// The picture, mirrored like a mirror (the frames read are not), cropped to fill; black
  /// until the camera shows one.
  @override
  Widget preview(BuildContext context) => ValueListenableBuilder<_Picture?>(
    valueListenable: _picture,
    builder: (context, picture, _) {
      Widget? texture;
      if (picture != null) {
        try {
          texture = _plugin.buildPreview(picture.cameraId);
        } on Object {
          texture = null;
        }
      }
      final size = picture?.size;
      return ColoredBox(
        color: const Color(0xFF000000),
        child: texture == null
            ? const SizedBox.expand()
            : ClipRect(
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: size?.width ?? 1280,
                      height: size?.height ?? 720,
                      child: Transform.flip(flipX: true, child: texture),
                    ),
                  ),
                ),
              ),
      );
    },
  );

  @override
  Future<void> close() async {
    if (_closed) return;
    final run = _run;
    final release = run != null && !run.over ? _release(run) : Future<void>.value();
    _closed = true;
    _lifecycle.stop();
    await release;
    await _codes.close();
    _picture.dispose();
    super.dispose();
  }
}

/// Lists the cameras, never opens one: no camera light.
class DesktopCameraProbe implements CameraProbe {
  DesktopCameraProbe([CameraDesktopPlugin? plugin]) : _plugin = plugin;

  final CameraDesktopPlugin? _plugin;

  @override
  Future<CameraPresence> probe() async {
    try {
      final devices = await (_plugin ?? desktopCameraPlugin()).listDevices();
      if (devices.isEmpty) return CameraPresence.none;
      return devices.any((d) => !d.denied) ? CameraPresence.present : CameraPresence.denied;
    } on CameraException catch (e) {
      return e.code == CameraDesktopErrorCode.unsupported ? CameraPresence.unsupported : CameraPresence.none;
    } on Object {
      return CameraPresence.none;
    }
  }
}
