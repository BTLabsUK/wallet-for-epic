// SPDX-License-Identifier: Apache-2.0
/// The camera behind the payment QR scanner, behind an interface so widget tests can feed it
/// scanned texts and draw a placeholder where the camera view would be.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scanner_backend.dart';

/// Why the camera is not usable.
enum QrCameraProblem {
  /// The user refused the camera permission.
  denied,

  /// The camera could not start for another reason (a driver error, an unknown one).
  failed,

  /// Another app holds the camera (desktop).
  busy,

  /// No picture: no first frame, frames stopped, or the same frame over and over (desktop).
  noPicture,

  /// The picture is black, a closed cover or lens shutter most often (desktop). Not final: it
  /// clears when the picture comes back.
  dark,

  /// The camera went away during the scan (desktop).
  unplugged,

  /// The QR reader did not load or start.
  readerFailed,

  /// This system lacks what the camera needs (desktop: GStreamer, Windows media features).
  unsupported;

  /// The camera stopped and stays stopped: only Try again, Paste or Close go on.
  bool get stopsScan => this != dark;
}

@immutable
class QrCameraState {
  const QrCameraState({
    this.problem,
    this.torchAvailable = false,
    this.torchOn = false,
    this.zoomed = false,
  });

  final QrCameraProblem? problem;
  final bool torchAvailable;
  final bool torchOn;

  /// True at 2×.
  final bool zoomed;

  QrCameraState copyWith({
    QrCameraProblem? problem,
    bool clearProblem = false,
    bool? torchAvailable,
    bool? torchOn,
    bool? zoomed,
  }) => QrCameraState(
    problem: clearProblem ? null : problem ?? this.problem,
    torchAvailable: torchAvailable ?? this.torchAvailable,
    torchOn: torchOn ?? this.torchOn,
    zoomed: zoomed ?? this.zoomed,
  );

  @override
  bool operator ==(Object other) =>
      other is QrCameraState &&
      problem == other.problem &&
      torchAvailable == other.torchAvailable &&
      torchOn == other.torchOn &&
      zoomed == other.zoomed;

  @override
  int get hashCode => Object.hash(problem, torchAvailable, torchOn, zoomed);
}

/// One camera session of the scan screen: starts, hands out every code it reads (the same
/// code again and again while it is in view), and stops on [close].
abstract class QrCamera extends ValueListenable<QrCameraState> {
  /// The text of each code the camera reads, repeats included.
  Stream<String> get codes;

  /// Starts the camera. A refusal or failure ends up in [value], never thrown.
  Future<void> start();

  Future<void> toggleTorch();

  /// 2× when [twice], else 1×.
  Future<void> setZoom({required bool twice});

  /// The picture, filling its parent.
  Widget preview(BuildContext context);

  Future<void> close();
}

/// Makes the camera of one scan screen.
typedef QrCameraFactory = QrCamera Function();

final qrCameraFactoryProvider = Provider<QrCameraFactory>(
  (ref) => MobileQrCamera.new,
);

/// The phone camera, through scanner_backend.dart.
class MobileQrCamera extends ChangeNotifier implements QrCamera {
  MobileQrCamera() {
    _controller.addListener(_sync);
  }

  // Every frame: the codes change six times a second, and dropping repeats would swallow
  // repeats of a part.
  final ScannerController _controller = ScannerController(everyFrame: true);

  QrCameraState _state = const QrCameraState();
  bool _disposed = false;

  @override
  QrCameraState get value => _state;

  @override
  Stream<String> get codes => _controller.codes;

  void _set(QrCameraState next) {
    if (_disposed || next == _state) return;
    _state = next;
    notifyListeners();
  }

  static QrCameraProblem _problemOf(ScannerError error) =>
      error == ScannerError.denied
      ? QrCameraProblem.denied
      : QrCameraProblem.failed;

  void _sync() {
    final error = _controller.error;
    _set(
      _state.copyWith(
        problem: error == null ? null : _problemOf(error),
        clearProblem: error == null,
        torchAvailable: _controller.torchAvailable,
        torchOn: _controller.torchOn,
      ),
    );
  }

  @override
  Future<void> start() async {
    try {
      await _controller.start();
    } on ScannerException catch (error) {
      _set(_state.copyWith(problem: _problemOf(error.error)));
    }
  }

  @override
  Future<void> toggleTorch() => _controller.toggleTorch();

  @override
  Future<void> setZoom({required bool twice}) async {
    await _controller.setZoom(twice: twice);
    _set(_state.copyWith(zoomed: twice));
  }

  @override
  Widget preview(BuildContext context) =>
      ScannerPreview(controller: _controller);

  @override
  Future<void> close() async {
    if (_disposed) return;
    _disposed = true;
    _controller.removeListener(_sync);
    await _controller.close();
    super.dispose();
  }
}

/// A camera for tests: [emit] hands out a code, [problem] makes [start] fail, and the
/// picture is a plain placeholder.
class FakeQrCamera extends ChangeNotifier implements QrCamera {
  FakeQrCamera({this.problem, bool torchAvailable = true})
    : _state = QrCameraState(torchAvailable: torchAvailable);

  /// What [start] fails with, if anything.
  QrCameraProblem? problem;

  final StreamController<String> _codes = StreamController<String>.broadcast(
    sync: true,
  );
  QrCameraState _state;

  bool started = false;
  bool disposed = false;
  int starts = 0;

  @override
  QrCameraState get value => _state;

  @override
  Stream<String> get codes => _codes.stream;

  void emit(String text) => _codes.add(text);

  @override
  Future<void> start() async {
    starts++;
    started = problem == null;
    _state = _state.copyWith(problem: problem, clearProblem: problem == null);
    notifyListeners();
  }

  @override
  Future<void> toggleTorch() async {
    _state = _state.copyWith(torchOn: !_state.torchOn);
    notifyListeners();
  }

  @override
  Future<void> setZoom({required bool twice}) async {
    _state = _state.copyWith(zoomed: twice);
    notifyListeners();
  }

  @override
  Widget preview(BuildContext context) => const ColoredBox(
    color: Color(0xFF202020),
    child: Center(child: Text('camera')),
  );

  @override
  Future<void> close() async {
    if (disposed) return;
    disposed = true;
    await _codes.close();
    super.dispose();
  }
}

/// The camera of the web preview (`WFE_WEB_FAKE`): no picture, only a placeholder, and the
/// texts of [source] handed out in a loop at the speed the show screen cycles them, one every
/// [interval]. That is what the phone next to this one would show, so "Scanned n of N" counts
/// up and finishes.
class SimulatedQrCamera extends ChangeNotifier implements QrCamera {
  SimulatedQrCamera({
    required this.source,
    this.warmUp = const Duration(milliseconds: 900),
    this.interval = const Duration(milliseconds: 1000 ~/ 6),
  });

  /// The texts the other phone shows, in the order it cycles them.
  final Future<List<String>> Function() source;

  /// How long the camera takes to see a code once it started.
  final Duration warmUp;
  final Duration interval;

  final StreamController<String> _codes = StreamController<String>.broadcast();
  QrCameraState _state = const QrCameraState();
  Timer? _timer;
  bool _disposed = false;

  @override
  QrCameraState get value => _state;

  @override
  Stream<String> get codes => _codes.stream;

  @override
  Future<void> start() async {
    final texts = await source();
    if (_disposed || texts.isEmpty) return;
    var next = 0;
    _timer?.cancel();
    _timer = Timer(warmUp, () {
      _timer = Timer.periodic(interval, (_) {
        if (_codes.isClosed) return;
        _codes.add(texts[next++ % texts.length]);
      });
    });
  }

  @override
  Future<void> toggleTorch() async {}

  @override
  Future<void> setZoom({required bool twice}) async {
    _state = _state.copyWith(zoomed: twice);
    notifyListeners();
  }

  @override
  Widget preview(BuildContext context) => const ColoredBox(
    color: Color(0xFF14181C),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_outlined, size: 48, color: Colors.white38),
          SizedBox(height: 8),
          Text(
            'Simulated camera', // l10n-ok: the web preview only
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    ),
  );

  @override
  Future<void> close() async {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    await _codes.close();
    super.dispose();
  }
}
