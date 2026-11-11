// SPDX-License-Identifier: Apache-2.0
// Report 2026-11-11 (Android): after Home's scan read a QR Payment part, or a wrong code
// and Scan again, the next scanner stayed black and read nothing, and leaving it logged
// "releaseFlutterSurfaceTexture() cannot be called ...". The camera plugin keeps one camera
// for the app; the screen before closed its camera after the next one had opened, and so
// closed the new one. A start now waits for the camera before it to be given back.
import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:epic_wallet/src/ui/scanner_backend.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// CameraX on Android as the app sees it: one preview and one frame reader for the whole
/// app. A new camera replaces them; dispose ignores which camera it is given and releases
/// the current preview, which fails when it is released already; a frame stream cancelled
/// stops the current reader.
class OneCamera extends CameraPlatform {
  int _ids = 0;
  int? preview;
  final producers = <int>{};
  bool reading = false;

  bool get live => preview != null && producers.contains(preview) && reading;

  @override
  Future<List<CameraDescription>> availableCameras() async => const [
    CameraDescription(name: '0', lensDirection: CameraLensDirection.back, sensorOrientation: 90),
  ];

  @override
  Future<int> createCameraWithSettings(CameraDescription description, MediaSettings? settings) async {
    final id = ++_ids;
    preview = id;
    producers.add(id);
    reading = false;
    return id;
  }

  @override
  Future<void> initializeCamera(int cameraId, {ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown}) async {}

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.value(CameraInitializedEvent(cameraId, 1280, 720, ExposureMode.auto, true, FocusMode.auto, true));

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => StreamController<CameraErrorEvent>().stream;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() => const Stream.empty();

  @override
  bool supportsImageStreaming() => true;

  @override
  Stream<CameraImageData> onStreamedFrameAvailable(int cameraId, {CameraImageStreamOptions? options}) {
    reading = true;
    return StreamController<CameraImageData>(onCancel: () => reading = false).stream;
  }

  @override
  Future<void> dispose(int cameraId) async {
    reading = false;
    if (!producers.remove(preview)) {
      throw PlatformException(
        code: 'IllegalStateException',
        message: 'releaseFlutterSurfaceTexture() cannot be called if the flutterSurfaceProducer '
            'for the camera preview has not yet been initialized.',
      );
    }
  }
}

void main() {
  // The scanner watches the app going to the background; these tests run in real time.
  TestWidgetsFlutterBinding.ensureInitialized();
  late OneCamera platform;
  late int readers;

  setUp(() {
    platform = OneCamera();
    CameraPlatform.instance = platform;
    readers = 0;
    ScannerController.startReading = () async => readers++;
    ScannerController.stopReading = () {
      expect(readers, greaterThan(0), reason: 'zxing stopped more often than started');
      readers--;
    };
  });

  test('a scanner opened before the last one closed keeps the camera', () async {
    final home = ScannerController();
    await home.start();
    expect(platform.live, isTrue);

    // The next scanner starts while the screen before is still in its exit transition;
    // that screen closes its scanner only afterwards.
    final next = ScannerController(everyFrame: true);
    await next.start();
    expect(next.error, isNull);
    await home.close();

    expect(platform.live, isTrue, reason: 'the open scanner lost its picture or its frames');
    expect(readers, 1);

    // Leaving it releases the camera without an error.
    await next.close();
    expect(platform.producers, isEmpty);
    expect(readers, 0);
  });

  test('a scanner closed while the next one starts', () async {
    final home = ScannerController();
    await home.start();
    final next = ScannerController();
    final started = next.start();
    final closed = home.close();
    await started;
    await closed;
    expect(platform.live, isTrue);
    expect(readers, 1);
    await next.close();
    expect(readers, 0);
  });

  test('Scan again, three times over, reads each time', () async {
    ScannerController? before;
    for (var i = 0; i < 3; i++) {
      final scanner = ScannerController();
      await scanner.start();
      await before?.close();
      expect(platform.live, isTrue, reason: 'scan $i');
      before = scanner;
    }
    await before!.close();
    expect(platform.producers, isEmpty);
    expect(readers, 0);
  });
}
