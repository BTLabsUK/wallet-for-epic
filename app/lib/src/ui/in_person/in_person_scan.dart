// SPDX-License-Identifier: Apache-2.0
/// The phone's scanner for in-person codes and answers (spec P3, P5): the shared camera with
/// the finder, reading every part of an animated code before it hands the bytes back. Paste
/// takes the text instead.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../providers.dart';
import '../../settings.dart';
import '../../trust_ids.dart';
import '../qr_camera.dart';
import '../qr_common.dart';
import '../qr_scan_screen.dart' show QrFinderOverlay;
import '../theme/tokens.dart';

/// What [InPersonScanScreen] read: the [bytes] of a whole QR code, or a plain [text] (a
/// one-part code, an answer, or what was pasted).
class InPersonScanned {
  const InPersonScanned({this.bytes, this.text});

  final Uint8List? bytes;
  final String? text;
}

/// Scans a code ([answer] false) or an answer to the code on screen. [first] is a part the
/// app's scanner read already.
class InPersonScanScreen extends ConsumerStatefulWidget {
  const InPersonScanScreen({super.key, this.answer = false, this.first});

  final bool answer;
  final String? first;

  @override
  ConsumerState<InPersonScanScreen> createState() => _InPersonScanScreenState();
}

class _InPersonScanScreenState extends ConsumerState<InPersonScanScreen> {
  late final QrCamera _camera = ref.read(qrCameraFactoryProvider)();
  StreamSubscription<String>? _codes;
  final List<String> _parts = [];
  int _received = 0;
  int _count = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    PortraitLock.hold();
    _codes = _camera.codes.listen(_onCode);
    final first = widget.first;
    if (first != null) _onCode(first);
    // After this frame: the hold is a provider, which a build must not change.
    Future.microtask(_start);
  }

  @override
  void dispose() {
    _codes?.cancel();
    unawaited(_camera.close());
    PortraitLock.release();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;
    await ref.read(autoLockHoldProvider.notifier).during(_camera.start);
  }

  void _finish(InPersonScanned scanned) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(scanned);
  }

  void _onCode(String code) {
    if (_done) return;
    final text = code.trim();
    if (!text.toLowerCase().startsWith('ur:')) {
      _finish(InPersonScanned(text: text));
      return;
    }
    final wallet = ref.read(epic1Provider);
    if (wallet == null || _parts.contains(text)) return;
    try {
      final progress = wallet.qrRead([..._parts, text]);
      _parts.add(text);
      final bytes = progress.bytes;
      if (progress.complete && bytes != null) {
        _finish(InPersonScanned(bytes: bytes));
        return;
      }
      setState(() {
        _received = progress.received;
        _count = progress.total;
      });
    } on Object {
      // A part of another code, or not one: the camera goes on.
    }
  }

  /// Paste: reads the clipboard on the press only.
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) _finish(InPersonScanned(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const dark = protocolDark;
    final title = widget.answer ? l.deskIpScanAnswer : l.deskIpScanTitle;
    return ListenableBuilder(
      listenable: _camera,
      builder: (context, _) {
        final problem = _camera.value.problem;
        final String dock = switch (problem) {
          QrCameraProblem.denied => l.qrScanCameraDenied,
          QrCameraProblem() => l.qrScanCameraFailed,
          null => _count > 0 ? l.qrScanProgress(_received, _count) : l.deskIpScanAim,
        };
        return Scaffold(
          backgroundColor: dark.bg,
          appBar: AppBar(
            backgroundColor: dark.bg,
            foregroundColor: dark.text,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: Text(title),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: problem != null
                    ? const SizedBox.shrink()
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          _camera.preview(context),
                          QrFinderOverlay(received: _received, count: _count),
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          dock,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: problem == null ? dark.text : dark.warn, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (problem != null) ...[
                        FilledButton(
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          onPressed: _start,
                          child: Text(l.commonRetry),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TrustId(
                        TrustIds.txIpScanpaste,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: dark.text,
                            side: BorderSide(color: dark.line),
                          ),
                          icon: const Icon(Icons.content_paste),
                          label: Text(l.commonPaste),
                          onPressed: _paste,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
