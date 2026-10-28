import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart';
import '../l10n.dart';
import '../settings.dart';
import '../wallet_backend.dart' show hostIsPhone;
import 'common.dart';
import 'scanner_backend.dart';

/// QR scanning needs a camera plugin that exists on Android and iOS only.
bool get qrScanSupported => !kIsWeb && hostIsPhone;

/// Opens the camera and returns the text of the first QR code it reads, or null when the user
/// backs out or scanning is not supported here.
Future<String?> scanQr(BuildContext context) async {
  if (!qrScanSupported) return null;
  final text = await Navigator.of(
    context,
  ).push<String>(MaterialPageRoute<String>(builder: (_) => const ScanScreen()));
  return text;
}

/// Scanning behind an interface, so widget tests can hand out codes without a camera.
abstract interface class QrScanner {
  bool get supported;

  Future<String?> scan(BuildContext context);
}

class PlatformQrScanner implements QrScanner {
  const PlatformQrScanner();

  @override
  bool get supported => qrScanSupported;

  @override
  Future<String?> scan(BuildContext context) => scanQr(context);
}

/// Returns queued codes, for tests.
class FakeQrScanner implements QrScanner {
  FakeQrScanner({this.supported = true});

  @override
  final bool supported;

  final List<String?> codes = [];

  @override
  Future<String?> scan(BuildContext context) async =>
      codes.isEmpty ? null : codes.removeAt(0);
}

final qrScannerProvider = Provider<QrScanner>(
  (ref) => const PlatformQrScanner(),
);

/// Whether screens offer a QR scan: the scanner works here, and this is not the web demo.
bool offersQrScan(WidgetRef ref) =>
    ref.watch(qrScannerProvider).supported && !ref.watch(demoModeProvider);

/// Whether Send and Receive offer QR as a payment method (the payment's animated code, not
/// the address scan of [offersQrScan]).
bool offersQrPayment(WidgetRef ref) => qrPreviewSimulation || offersQrScan(ref);

/// Full-screen camera view that pops with the first QR code's text.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  // Started by hand, so the camera permission prompt runs under the auto-lock hold.
  final _controller = ScannerController();
  StreamSubscription<String>? _codes;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _codes = _controller.codes.listen(_onCode);
    _start();
  }

  /// Starts the camera. The first start asks for camera permission, which on some phones
  /// leaves the app; that trip must not count towards auto-lock.
  Future<void> _start() async {
    try {
      await ref.read(autoLockHoldProvider.notifier).during(_controller.start);
    } on ScannerException {
      // Also recorded in the controller's state, which the error builder shows.
    }
  }

  @override
  void dispose() {
    _codes?.cancel();
    unawaited(_controller.close());
    super.dispose();
  }

  void _onCode(String text) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SlotScaffold(
      appBar: AppBar(title: Text(l.scanQrTitle)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScannerPreview(
            controller: _controller,
            errorBuilder: (context, error) =>
                _ScanError(error: error, onRetry: _start),
          ),
          const IgnorePointer(child: _Viewfinder()),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                // A dark scrim keeps the hint readable over a bright scene.
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l.scanQrHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A square frame in the middle of the camera view, showing where to hold the code. Only a
/// guide: codes are read anywhere in the picture.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide * 0.7;
        return Center(
          // A faint dark ring outside the white frame, so it shows on white paper too.
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.35),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              width: side,
              height: side,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScanError extends StatelessWidget {
  const _ScanError({required this.error, required this.onRetry});

  final ScannerError error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final denied = error == ScannerError.denied;
    final theme = Theme.of(context);
    final l = context.l10n;
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                denied ? Icons.no_photography : Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                denied ? l.scanQrCameraDenied : l.scanQrCameraFailed,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(l.scanQrTryAgain)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.scanQrBack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
