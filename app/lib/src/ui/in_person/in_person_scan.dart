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
import '../kit/kit_button.dart';
import '../kit/kit_ground.dart' show KitGround;
import '../kit/kit_headers.dart';
import '../kit/kit_icons.dart';
import '../kit/kit_step_strip.dart';
import '../kit/kit_tokens.dart';
import '../qr_scan_screen.dart' show QrFinderOverlay;
import '../theme/tokens.dart';

/// What [InPersonScanScreen] read: the [bytes] of a whole QR code, or a plain [text] (a
/// one-part code, an answer, or what was pasted). [classic] says the animated code was a
/// classic payment's, which shares the in-person code's type and is told apart only once whole.
class InPersonScanned {
  const InPersonScanned({this.bytes, this.text, this.classic = false});

  final Uint8List? bytes;
  final String? text;
  final bool classic;
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
      // A part of another code, or not one: the camera goes on. A whole classic payment
      // ends the scan, so the caller can say it is one.
      unawaited(_classic([..._parts, text]));
    }
  }

  Future<void> _classic(List<String> parts) async {
    final service = ref.read(walletServiceProvider);
    try {
      final read = await service.decodeQrSlate(parts: parts);
      if (read.complete && read.json != null) _finish(const InPersonScanned(classic: true));
    } on Object {
      return;
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
    final steps = widget.answer
        ? [l.phoneStepPayShow, l.phoneStepPayScan, l.commonDone]
        : [l.phoneStepRecvScan, l.phoneStepRecvShow, l.commonDone];
    return Theme(
      data: _scannerTheme,
      child: KitGround(child: ListenableBuilder(
        listenable: _camera,
        builder: (context, _) {
          final problem = _camera.value.problem;
          final String dock = switch (problem) {
            QrCameraProblem.denied => l.qrScanCameraDenied,
            QrCameraProblem() => l.qrScanCameraFailed,
            null => _count > 0 ? l.qrScanProgress(_received, _count) : l.deskIpScanAim,
          };
          return Scaffold(
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KitFlowHeader(
                    title: title,
                    back: widget.answer,
                    onLeading: () => Navigator.of(context).maybePop(),
                    leadingId: TrustIds.qrscanBack,
                  ),
                  KitStepStrip(labels: steps, current: widget.answer ? 1 : 0),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(Kit.gutter, 18, Kit.gutter, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Kit.rSheetTop),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: dark.hair),
                            borderRadius: BorderRadius.circular(Kit.rSheetTop),
                          ),
                          child: problem != null
                              ? const SizedBox.expand()
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _camera.preview(context),
                                    QrFinderOverlay(received: _received, count: _count),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Kit.gutter, 16, Kit.gutter, Kit.gutter),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            dock,
                            textAlign: TextAlign.center,
                            style: KitType.body.copyWith(color: problem == null ? dark.text : dark.warn),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (problem != null) ...[
                          KitButton(label: l.commonRetry, onPressed: _start),
                          const SizedBox(height: 8),
                        ],
                        KitButton(
                          kind: problem != null ? KitButtonKind.quiet : KitButtonKind.gold,
                          icon: KitIcons.paste,
                          label: l.commonPaste,
                          onPressed: _paste,
                          semanticsId: TrustIds.txIpScanpaste,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      )),
    );
  }
}

/// The scanner's theme: Protocol dark whatever the app's.
final ThemeData _scannerTheme = buildWalletTheme(protocolDark, Brightness.dark);
