// SPDX-License-Identifier: Apache-2.0
// The desktop QR camera on a fake camera_desktop plugin: every way a scan can go wrong ends in
// value.problem with the camera given back, a good one hands out codes about six times a
// second, and the probe never opens a camera.
import 'dart:async';

import 'package:camera_desktop/camera_desktop.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:epic_wallet/src/camera/camera_presence.dart';
import 'package:epic_wallet/src/camera/desktop_camera.dart';
import 'package:epic_wallet/src/camera/desktop_qr_camera.dart';
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:epic_wallet/src/ui/scanner_backend.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

CameraDesktopDevice device(String name, {bool denied = false, bool builtIn = false}) => CameraDesktopDevice(
  description: CameraDescription(name: name, lensDirection: CameraLensDirection.external, sensorOrientation: 0),
  denied: denied,
  builtIn: builtIn,
);

/// camera_desktop as the camera sees it: one list of devices, errors on demand, frames pushed
/// by the test.
class FakeDesktopPlugin extends CameraDesktopPlugin {
  List<CameraDesktopDevice> devices = [device('Integrated Camera (/dev/video0)')];
  Object? listError;
  Object? createError;

  /// The native code initializeCamera fails with, as the real plugin does: an error event,
  /// then a CameraException.
  String? initCode;

  final _events = StreamController<CameraEvent>.broadcast();
  StreamController<CameraImageData>? _frames;
  final opened = <String>[];
  final disposed = <int>[];
  int _ids = 0;
  int listed = 0;

  /// A camera is open and streaming.
  bool get streaming => _frames != null && !_frames!.isClosed && _frames!.hasListener;

  void frame(CameraImageData data) {
    final frames = _frames;
    if (frames != null && !frames.isClosed) frames.add(data);
  }
  void nativeError(int id, String code) => _events.add(CameraDesktopErrorEvent(id, 'native', code: code));

  @override
  Future<List<CameraDesktopDevice>> listDevices() async {
    listed++;
    if (listError != null) throw listError!;
    return devices;
  }

  @override
  Future<int> createCameraWithSettings(CameraDescription description, MediaSettings settings) async {
    if (createError != null) throw createError!;
    opened.add(description.name);
    return ++_ids;
  }

  @override
  Future<void> initializeCamera(int cameraId, {ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown}) async {
    final code = initCode;
    if (code != null) {
      _events.add(CameraDesktopErrorEvent(cameraId, 'native', code: code));
      throw CameraException(code, 'native');
    }
    _events.add(CameraInitializedEvent(cameraId, 160, 90, ExposureMode.auto, false, FocusMode.auto, false));
  }

  Stream<T> _of<T extends CameraEvent>(int id) => _events.stream.where((e) => e is T && e.cameraId == id).cast<T>();

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) => _of<CameraInitializedEvent>(cameraId);

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => _of<CameraErrorEvent>(cameraId);

  @override
  Stream<CameraClosingEvent> onCameraClosing(int cameraId) => _of<CameraClosingEvent>(cameraId);

  @override
  Stream<CameraImageData> onStreamedFrameAvailable(int cameraId, {CameraImageStreamOptions? options}) {
    final frames = _frames = StreamController<CameraImageData>();
    return frames.stream;
  }

  @override
  Future<void> dispose(int cameraId) async {
    disposed.add(cameraId);
    // Not awaited: closing a cancelled stream answers with a future of the root zone, which
    // never completes in fake time.
    unawaited(_frames?.close());
    _frames = null;
  }

  @override
  Widget buildPreview(int cameraId) => const SizedBox();
}

class FakeReader implements QrFrameReader {
  Object? startError;
  String? text;
  bool failing = false;
  int starts = 0;
  int stops = 0;
  int reads = 0;
  final frames = <CameraImageData>[];

  @override
  Future<void> start() async {
    starts++;
    if (startError != null) throw startError!;
  }

  @override
  Future<String?> read(CameraImageData frame) async {
    reads++;
    frames.add(frame);
    if (failing) throw StateError('decoder');
    return text;
  }

  @override
  void stop() => stops++;
}

const width = 160;
const height = 90;
const stride = width * 4 + 16; // padded rows, as macOS sends them

/// A grey BGRA frame of [luma]; [seed] moves the noise, so two seeds are two pictures.
CameraImageData picture(int luma, {int seed = 0, String raw = 'BGRA'}) {
  final bytes = Uint8List(stride * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final v = (luma + (x * 7 + y * 3 + seed) % 5).clamp(0, 255);
      final at = y * stride + x * 4;
      bytes[at] = v;
      bytes[at + 1] = v;
      bytes[at + 2] = v;
      bytes[at + 3] = 255;
    }
  }
  return CameraImageData(
    format: CameraImageFormat(ImageFormatGroup.bgra8888, raw: raw),
    width: width,
    height: height,
    planes: [CameraImagePlane(bytes: bytes, bytesPerRow: stride, bytesPerPixel: 4, width: width, height: height)],
  );
}

const timings = DesktopCameraTimings();
const frameEvery = Duration(milliseconds: 33);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDesktopPlugin plugin;
  late FakeReader reader;
  late bool nodeThere;

  setUp(() {
    plugin = FakeDesktopPlugin();
    reader = FakeReader();
    nodeThere = true;
  });

  DesktopQrCamera camera() => DesktopQrCamera(plugin: plugin, timings: timings, reader: reader, nodeExists: (_) => nodeThere);

  /// Runs [body] in fake time, with the camera turns and the fakes made in its zone, and closes
  /// [cam] at the end.
  void inFakeTime(void Function(FakeAsync async, DesktopQrCamera cam) body) {
    fakeAsync((async) {
      CameraTurns.reset();
      plugin = FakeDesktopPlugin();
      reader = FakeReader();
      nodeThere = true;
      final cam = camera();
      body(async, cam);
      cam.close();
      async.flushMicrotasks();
      var free = false;
      CameraTurns.free.then((_) => free = true);
      async.flushMicrotasks();
      expect(free, isTrue, reason: 'every release is done');
    });
  }

  /// Sends a frame every 33 ms for [span]: [make] gets the frame's number.
  void feed(FakeAsync async, Duration span, CameraImageData Function(int i) make) {
    for (var i = 0; i * frameEvery.inMicroseconds < span.inMicroseconds; i++) {
      plugin.frame(make(i));
      async.elapse(frameEvery);
    }
  }

  void started(FakeAsync async, DesktopQrCamera cam) {
    cam.start();
    async.flushMicrotasks();
  }

  void expectReleased(DesktopQrCamera cam, QrCameraProblem problem) {
    expect(cam.value.problem, problem);
    expect(plugin.disposed, [1], reason: 'the camera is given back once');
    expect(plugin.streaming, isFalse);
    expect(reader.stops, reader.startError == null ? reader.starts : 0, reason: 'the reader stops once per start that worked');
  }

  group('a good scan', () {
    test('hands out the code about six times a second, from frames as the camera sends them', () {
      inFakeTime((async, cam) {
        reader.text = 'epic1payment';
        final codes = <String>[];
        cam.codes.listen(codes.add);
        started(async, cam);
        expect(plugin.opened, ['Integrated Camera (/dev/video0)']);
        expect(plugin.streaming, isTrue);
        feed(async, const Duration(seconds: 3), (i) => picture(120, seed: i));
        expect(cam.value.problem, isNull);
        expect(reader.reads, inInclusiveRange(16, 20));
        expect(codes.length, reader.reads);
        expect(codes.toSet(), {'epic1payment'});
        // The frame reaches the reader as it came: padded rows, BGRA, not mirrored.
        expect(reader.frames.first.planes.single.bytesPerRow, stride);
        expect(reader.frames.first.format.raw, 'BGRA');
      });
    });

    test('close gives back the camera and the reader, and says nothing after', () {
      inFakeTime((async, cam) {
        started(async, cam);
        feed(async, const Duration(milliseconds: 500), (i) => picture(120, seed: i));
        var told = 0;
        cam.addListener(() => told++);
        cam.close();
        async.flushMicrotasks();
        expect(plugin.disposed, [1]);
        expect(reader.stops, 1);
        async.elapse(const Duration(seconds: 10));
        expect(told, 0);
      });
    });
  });

  group('the native codes', () {
    test('map to the problems, never by message', () {
      expect(problemOfCode('denied'), QrCameraProblem.denied);
      expect(problemOfCode('busy'), QrCameraProblem.busy);
      expect(problemOfCode('unplugged'), QrCameraProblem.unplugged);
      expect(problemOfCode('no_device'), QrCameraProblem.unplugged);
      expect(problemOfCode('no_picture'), QrCameraProblem.noPicture);
      expect(problemOfCode('unsupported'), QrCameraProblem.unsupported);
      expect(problemOfCode('failed'), QrCameraProblem.failed);
      expect(problemOfCode('E_SOMETHING'), QrCameraProblem.failed);
    });

    test('denied: every camera is there but refused, so none opens', () {
      inFakeTime((async, cam) {
        plugin.devices = [device('Integrated Camera (/dev/video0)', denied: true)];
        started(async, cam);
        expect(cam.value.problem, QrCameraProblem.denied);
        expect(plugin.opened, isEmpty);
        expect(reader.starts, 0);
      });
    });

    test('denied when it opens (macOS, Windows privacy): the camera is given back', () {
      inFakeTime((async, cam) {
        plugin.initCode = CameraDesktopErrorCode.denied;
        started(async, cam);
        expectReleased(cam, QrCameraProblem.denied);
        expect(reader.starts, 0);
      });
    });

    test('busy: another app holds the camera', () {
      inFakeTime((async, cam) {
        plugin.initCode = CameraDesktopErrorCode.busy;
        started(async, cam);
        expectReleased(cam, QrCameraProblem.busy);
      });
    });

    test('failed: an unknown native error, and a host without the plugin', () {
      inFakeTime((async, cam) {
        plugin.createError = CameraException('failed', 'errno 5');
        started(async, cam);
        expect(cam.value.problem, QrCameraProblem.failed);
        expect(plugin.disposed, isEmpty, reason: 'nothing opened');
      });
      inFakeTime((async, cam) {
        plugin.listError = MissingPluginException();
        started(async, cam);
        expect(cam.value.problem, QrCameraProblem.failed);
      });
    });

    test('unsupported: the system lacks the media libraries', () {
      inFakeTime((async, cam) {
        plugin.listError = CameraException(CameraDesktopErrorCode.unsupported, 'GStreamer is not installed');
        started(async, cam);
        expect(cam.value.problem, QrCameraProblem.unsupported);
        expect(plugin.opened, isEmpty);
      });
    });

    test('no camera at the start is unplugged', () {
      inFakeTime((async, cam) {
        plugin.devices = [];
        started(async, cam);
        expect(cam.value.problem, QrCameraProblem.unplugged);
      });
    });
  });

  group('no picture', () {
    test('no first frame in camera.first_frame_ms', () {
      inFakeTime((async, cam) {
        started(async, cam);
        async.elapse(timings.firstFrame - const Duration(milliseconds: 100));
        expect(cam.value.problem, isNull);
        async.elapse(const Duration(milliseconds: 200));
        expectReleased(cam, QrCameraProblem.noPicture);
      });
    });

    test('frames that stop for camera.stall_ms, the camera still there', () {
      inFakeTime((async, cam) {
        started(async, cam);
        feed(async, const Duration(seconds: 1), (i) => picture(120, seed: i));
        async.elapse(timings.stall - const Duration(milliseconds: 100));
        expect(cam.value.problem, isNull);
        async.elapse(const Duration(milliseconds: 200));
        expectReleased(cam, QrCameraProblem.noPicture);
      });
    });

    test('the same picture for camera.frozen_ms', () {
      inFakeTime((async, cam) {
        started(async, cam);
        feed(async, timings.frozen - const Duration(milliseconds: 200), (_) => picture(120));
        expect(cam.value.problem, isNull);
        feed(async, const Duration(milliseconds: 400), (_) => picture(120));
        expectReleased(cam, QrCameraProblem.noPicture);
      });
    });
  });

  group('dark', () {
    test('a black picture for camera.dark_ms is Dark, and clears when the picture comes back', () {
      inFakeTime((async, cam) {
        reader.text = 'epic1payment';
        final codes = <String>[];
        cam.codes.listen(codes.add);
        started(async, cam);
        // Black for longer than the frozen check: a covered lens is not frozen.
        feed(async, timings.frozen + const Duration(seconds: 1), (i) => picture(2, seed: i % 2));
        expect(cam.value.problem, QrCameraProblem.dark);
        expect(plugin.disposed, isEmpty, reason: 'Dark keeps the camera');
        expect(codes, isEmpty);
        feed(async, const Duration(seconds: 1), (i) => picture(120, seed: i));
        expect(cam.value.problem, isNull);
        expect(codes, isNotEmpty);
        expect(plugin.streaming, isTrue);
      });
    });

    test('a black moment shorter than camera.dark_ms says nothing', () {
      inFakeTime((async, cam) {
        started(async, cam);
        feed(async, timings.dark - const Duration(milliseconds: 300), (i) => picture(2, seed: i % 2));
        feed(async, const Duration(seconds: 2), (i) => picture(120, seed: i));
        expect(cam.value.problem, isNull);
      });
    });
  });

  group('unplugged', () {
    test('the native side says so mid-scan', () {
      inFakeTime((async, cam) {
        started(async, cam);
        feed(async, const Duration(seconds: 1), (i) => picture(120, seed: i));
        plugin.nativeError(1, CameraDesktopErrorCode.unplugged);
        async.flushMicrotasks();
        expectReleased(cam, QrCameraProblem.unplugged);
      });
    });

    test('frames stop and the Linux node is gone', () {
      inFakeTime((async, cam) {
        started(async, cam);
        feed(async, const Duration(seconds: 1), (i) => picture(120, seed: i));
        nodeThere = false;
        async.elapse(timings.stall + const Duration(milliseconds: 100));
        expectReleased(cam, QrCameraProblem.unplugged);
      });
    });

    test('the first problem wins', () {
      inFakeTime((async, cam) {
        started(async, cam);
        feed(async, const Duration(seconds: 1), (i) => picture(120, seed: i));
        plugin.nativeError(1, CameraDesktopErrorCode.unplugged);
        plugin.nativeError(1, CameraDesktopErrorCode.failed);
        async.elapse(const Duration(seconds: 10));
        expectReleased(cam, QrCameraProblem.unplugged);
      });
    });
  });

  group('the reader', () {
    test('that does not start fails the scan and gives back the camera', () {
      inFakeTime((async, cam) {
        reader.startError = StateError('isolate');
        started(async, cam);
        expect(cam.value.problem, QrCameraProblem.readerFailed);
        expect(plugin.disposed, [1]);
        expect(reader.stops, 0);
      });
    });

    test('that fails three reads in a row fails the scan; one bad read does not', () {
      inFakeTime((async, cam) {
        started(async, cam);
        reader.failing = true;
        feed(async, const Duration(milliseconds: 200), (i) => picture(120, seed: i));
        reader.failing = false;
        feed(async, const Duration(milliseconds: 500), (i) => picture(120, seed: i));
        expect(cam.value.problem, isNull);
        reader.failing = true;
        feed(async, const Duration(seconds: 1), (i) => picture(120, seed: i));
        expectReleased(cam, QrCameraProblem.readerFailed);
      });
    });
  });

  group('turns and the window', () {
    test('Try again after a problem starts a new camera, with no problem', () {
      inFakeTime((async, cam) {
        plugin.initCode = CameraDesktopErrorCode.busy;
        started(async, cam);
        expect(cam.value.problem, QrCameraProblem.busy);
        expect(plugin.listed, 1, reason: 'no retry by itself');
        async.elapse(const Duration(seconds: 30));
        expect(plugin.listed, 1);
        plugin.initCode = null;
        started(async, cam);
        expect(cam.value.problem, isNull);
        expect(plugin.opened.length, 2);
        expect(plugin.streaming, isTrue);
      });
    });

    test('a second scanner takes the camera only once the first gave it back', () {
      inFakeTime((async, first) {
        started(async, first);
        final second = camera();
        second.start();
        async.flushMicrotasks();
        expect(plugin.disposed, [1], reason: 'the first yielded');
        expect(plugin.opened.length, 2);
        expect(first.value.problem, isNull);
        second.close();
        async.flushMicrotasks();
      });
    });

    test('only a hidden window pauses; showing it again starts the camera', () {
      inFakeTime((async, cam) {
        final binding = TestWidgetsFlutterBinding.instance;
        started(async, cam);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        async.flushMicrotasks();
        expect(plugin.disposed, isEmpty, reason: 'a window without focus keeps scanning');
        binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        async.flushMicrotasks();
        expect(plugin.disposed, [1]);
        // Hidden for longer than every check: no problem while paused.
        async.elapse(const Duration(seconds: 20));
        expect(cam.value.problem, isNull);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        async.flushMicrotasks();
        expect(plugin.opened.length, 2);
        expect(plugin.streaming, isTrue);
      });
    });
  });

  group('the camera choice', () {
    test('the first built-in one, else the lowest Linux node, never a refused one', () {
      expect(chooseCamera([device('USB'), device('FaceTime HD', builtIn: true)])!.description.name, 'FaceTime HD');
      expect(chooseCamera([device('USB (/dev/video4)'), device('Integrated (/dev/video0)'), device('IR (/dev/video2)')])!.description.name, 'Integrated (/dev/video0)');
      expect(chooseCamera([device('Integrated (/dev/video0)', denied: true), device('USB (/dev/video4)')])!.description.name, 'USB (/dev/video4)');
      expect(chooseCamera([device('A'), device('B')])!.description.name, 'A');
      expect(chooseCamera([device('A', denied: true)]), isNull);
      expect(chooseCamera([]), isNull);
      expect(videoNode('HD Webcam: HD Webcam (/dev/video12)'), 12);
      expect(videoNode('FaceTime HD Camera'), isNull);
    });
  });

  group('the picture checks', () {
    test('read luma through the row padding, either byte order', () {
      final grey = FrameLook.of(picture(120));
      expect(grey.dark, isFalse);
      expect(grey.mean, inInclusiveRange(119, 125));
      expect(FrameLook.of(picture(3)).dark, isTrue);
      expect(FrameLook.of(picture(120)).same(FrameLook.of(picture(120))), isTrue);
      expect(FrameLook.of(picture(120)).same(FrameLook.of(picture(120, seed: 1))), isFalse);
      // Pure red: BGRA puts it in byte 2, RGBA in byte 0.
      final bytes = Uint8List(stride * height);
      for (var i = 2; i < bytes.length; i += 4) {
        bytes[i] = 255;
      }
      CameraImageData red(String raw) => CameraImageData(
        format: CameraImageFormat(ImageFormatGroup.bgra8888, raw: raw),
        width: width,
        height: height,
        planes: [CameraImagePlane(bytes: bytes, bytesPerRow: stride)],
      );
      expect(FrameLook.of(red('BGRA')).mean, closeTo(54, 1));
      expect(FrameLook.of(red('RGBA')).mean, closeTo(19, 1));
    });
  });

  group('the probe', () {
    Future<CameraPresence> probeWith(void Function(FakeDesktopPlugin p) setUpPlugin) {
      setUpPlugin(plugin);
      return DesktopCameraProbe(plugin).probe();
    }

    test('maps what the plugin lists, and opens nothing', () async {
      expect(await probeWith((_) {}), CameraPresence.present);
      expect(await probeWith((p) => p.devices = [device('A (/dev/video0)', denied: true), device('B (/dev/video2)')]), CameraPresence.present);
      expect(await probeWith((p) => p.devices = [device('A (/dev/video0)', denied: true)]), CameraPresence.denied);
      expect(await probeWith((p) => p.devices = []), CameraPresence.none);
      expect(await probeWith((p) => p.listError = CameraException(CameraDesktopErrorCode.unsupported, 'no GStreamer')), CameraPresence.unsupported);
      expect(await probeWith((p) => p.listError = CameraException('failed', 'errno 5')), CameraPresence.none);
      expect(await probeWith((p) => p.listError = MissingPluginException()), CameraPresence.none);
      expect(plugin.opened, isEmpty);
    });
  });
}
