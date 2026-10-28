// SPDX-License-Identifier: Apache-2.0
/// The camera library behind QR scanning: the only file that imports it. The F-Droid build
/// swaps this file for scanner_backend_foss.dart, the same API on free code
/// (tools/dist-prep.sh), so keep the two in step.
library;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  ScannerController({bool everyFrame = false})
    : _controller = MobileScannerController(
        autoStart: false,
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: everyFrame
            ? DetectionSpeed.unrestricted
            : DetectionSpeed.noDuplicates,
      ) {
    _controller.addListener(notifyListeners);
  }

  final MobileScannerController _controller;

  ScannerError? get error => _errorOf(_controller.value.error);

  bool get torchAvailable =>
      _controller.value.torchState != TorchState.unavailable;

  bool get torchOn => _controller.value.torchState == TorchState.on;

  /// The trimmed text of each code read, empty ones left out.
  Stream<String> get codes => _controller.barcodes.expand(
    (capture) => [
      for (final code in capture.barcodes)
        if (code.rawValue case final text? when text.trim().isNotEmpty)
          text.trim(),
    ],
  );

  Future<void> start() async {
    try {
      await _controller.start();
    } on MobileScannerException catch (error) {
      throw ScannerException(_errorOf(error)!);
    }
  }

  Future<void> toggleTorch() => _controller.toggleTorch();

  /// 2× when [twice], else 1×.
  Future<void> setZoom({required bool twice}) =>
      _controller.setZoomScale(twice ? 0.5 : 0);

  Future<void> close() async {
    _controller.removeListener(notifyListeners);
    await _controller.dispose();
    dispose();
  }

  static ScannerError? _errorOf(MobileScannerException? error) => error == null
      ? null
      : error.errorCode == MobileScannerErrorCode.permissionDenied
      ? ScannerError.denied
      : ScannerError.failed;
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
  Widget build(BuildContext context) => MobileScanner(
    controller: controller._controller,
    errorBuilder: (context, error) =>
        errorBuilder?.call(context, ScannerController._errorOf(error)!) ??
        const SizedBox.shrink(),
  );
}
