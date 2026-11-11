// SPDX-License-Identifier: Apache-2.0
/// QR Payment on the desktop: a transaction file passed as an animated QR code, one more way in
/// and out of the file flows. Every place that takes a file or pasted text also scans one
/// ([deskScanSlate], [DeskQrScanButton]); every place that hands out a payment file or an
/// answer also shows it ([showDeskSlateQr], [DeskSlateQr]). The text a scan gives goes down the
/// same calls a pasted text does, so each flow refuses a code of the wrong kind in its own words.
///
/// As on the phone: the code is covered until Show QR, counts 3, 2, 1, shows for 40 seconds and
/// covers itself again, and it covers itself when the window is minimised.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../camera/camera_presence.dart';
import '../../../sealed_text.dart' show isSealedText;
import '../../../qr_slate.dart' show QrFrames, looksLikeQrSlate, partCountOf, partNumberOf, qrCountdownSeconds, qrFrameMs, qrLowSeconds, qrShowSeconds;
import '../../../wallet_service.dart' show WalletError, WalletErrorKind;
import '../../data/api.dart' show DeskWalletApi;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../scan/desk_scan.dart';

/// What a QR Payment code holds, which picks its words.
enum DeskQrKind {
  /// The sender's payment (S1): the receiver scans it and shows the reply.
  payment,

  /// The receiver's reply to a payment (S2), shown back to the sender.
  reply,

  /// An invoice (I1), shown by whoever asks for the payment.
  request,

  /// The payer's answer to an invoice (I2), shown back to whoever asked.
  paid,

  /// A payment finished under Kill switch, shown to a device that is online to post it.
  finished,
}

/// Reads the parts of one animated payment code with the wallet's decoder, as the phone's
/// reader does: each text trimmed and upper-cased, repeats skipped, and all distinct parts
/// decoded together each time.
class DeskSlateQrReader implements DeskPartReader<String> {
  DeskSlateQrReader(this._api, {required this.notSlate});

  final DeskWalletApi _api;

  /// What the dialog says of a code that is no payment code.
  final String Function(AppLocalizations l) notSlate;

  final Set<String> _parts = {};
  int received = 0;
  int count = 0;

  void reset() {
    _parts.clear();
    received = 0;
    count = 0;
  }

  @override
  Future<DeskPartStep<String>> read(String raw) async {
    final text = raw.trim().toUpperCase();
    if (!looksLikeQrSlate(text)) return DeskPartRefused(notSlate);
    if (_parts.contains(text)) return DeskPartWaiting(received, count);
    try {
      final p = await _api.decodeQrSlate([..._parts, text]);
      _parts.add(text);
      received = p.received;
      count = p.count;
      final json = p.json;
      if (p.complete && json != null) return DeskPartDone(json);
      return DeskPartWaiting(received, count);
    } on WalletError catch (e) {
      switch (e.kind) {
        case WalletErrorKind.mixedQrCodes:
          reset();
          return DeskPartRefused((l) => l.qrScanOtherPayment);
        case WalletErrorKind.notQrSlate || WalletErrorKind.foreignQrCode:
          return DeskPartRefused(notSlate);
        case WalletErrorKind.invalidQrCode || WalletErrorKind.qrCodeTooLarge:
          // The parts held cannot make a payment (one damaged, or past the limit): start over,
          // so the code in front of the camera can still be read.
          reset();
          return DeskPartRefused(notSlate);
        default:
          rethrow;
      }
    }
  }
}

/// Scans an animated payment code: its transaction text, the text pasted in its place, or
/// null when closed. [first] is a part already read (Send's To field): when it is the whole
/// code no dialog opens.
Future<DeskScanResult<String>?> deskScanSlate(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  String? hint,
  required String Function(AppLocalizations l) notSlate,
  String? first,
}) async {
  final reader = DeskSlateQrReader(ref.read(deskApiProvider), notSlate: notSlate);
  if (first != null) {
    try {
      if (await reader.read(first) case DeskPartDone<String>(:final value)) return DeskScanned(value);
    } on Object {
      // The dialog reads it again from the camera.
    }
    if (!context.mounted) return null;
  }
  return deskScanParts<String>(context, title: title, hint: hint, reader: reader);
}

/// Scan QR beside a flow's Choose file or Paste: offered while a camera is found, greyed out
/// otherwise. It asks for the camera again when it first shows.
class DeskQrScanButton extends ConsumerStatefulWidget {
  const DeskQrScanButton({super.key, required this.onScan, this.size = EBtnSize.sm, this.enabled = true});

  final VoidCallback onScan;
  final EBtnSize size;

  /// False while the flow is busy.
  final bool enabled;

  @override
  ConsumerState<DeskQrScanButton> createState() => _DeskQrScanButtonState();
}

class _DeskQrScanButtonState extends ConsumerState<DeskQrScanButton> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(cameraPresenceProvider.notifier).recheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    final on = ref.watch(cameraPresenceProvider).offersScan && widget.enabled;
    return EButton(label: context.l10n.postFinishedScanQr, icon: EIcons.camera, size: widget.size, onPressed: on ? widget.onScan : null);
  }
}

/// Whether the file at [path] can be shown as a QR code: a plain transaction file. A sealed
/// file is for one paired wallet, which takes it as a file or text.
bool deskQrShowsFile(String path) {
  final p = path.toLowerCase();
  return !p.endsWith('.epicsealed') && !p.endsWith('.epictx');
}

/// The line under a drop zone that offers Scan QR in place of the file.
class DeskScanRow extends StatelessWidget {
  const DeskScanRow({super.key, required this.text, required this.button});

  final String text;
  final Widget button;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: Sp.x3,
    runSpacing: Sp.x2,
    children: [Text(text, style: context.ts.bodyDim), button],
  );
}

/// The dialog's title for a code of [kind].
String deskQrTitle(AppLocalizations l, DeskQrKind kind) => switch (kind) {
  DeskQrKind.payment => l.qrShowTitlePayment,
  DeskQrKind.reply || DeskQrKind.paid => l.qrShowTitleReply,
  DeskQrKind.request => l.qrShowTitleRequest,
  DeskQrKind.finished => l.finishedQrTitle,
};

/// Shows the transaction text [json], or the file this wallet wrote at [path], as an animated
/// QR code in a dialog. [onScanReply]: the code waits for an answer (a payment, an invoice),
/// and the dialog offers Scan their reply, which closes it and calls this.
Future<void> showDeskSlateQr(BuildContext context, {required DeskQrKind kind, String? json, String? path, VoidCallback? onScanReply}) =>
    showEDialog<void>(
      context,
      builder: (ctx) {
        final l = ctx.l10n;
        return EDialog(
          key: const ValueKey('desk-qr-dialog'),
          title: deskQrTitle(l, kind),
          icon: EIcons.qr,
          body: Center(child: DeskSlateQr(kind: kind, json: json, path: path)),
          actions: [
            EButton(key: const ValueKey('desk-qr-close'), label: l.commonClose, onPressed: () => Navigator.of(ctx).pop()),
            if (onScanReply != null)
              EButton.primary(
                key: const ValueKey('desk-qr-scan-reply'),
                label: l.qrScanReply,
                icon: EIcons.camera,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onScanReply();
                },
              ),
          ],
        );
      },
    );

/// Show QR next to a file's Save and Copy: opens [showDeskSlateQr].
class DeskShowQrButton extends StatelessWidget {
  const DeskShowQrButton({super.key, required this.kind, this.json, this.path, this.onScanReply, this.size = EBtnSize.md, this.enabled = true});

  final DeskQrKind kind;
  final String? json;
  final String? path;
  final VoidCallback? onScanReply;
  final EBtnSize size;
  final bool enabled;

  @override
  Widget build(BuildContext context) => EButton(
    label: context.l10n.qrShow,
    icon: EIcons.qr,
    size: size,
    onPressed: enabled ? () => showDeskSlateQr(context, kind: kind, json: json, path: path, onScanReply: onScanReply) : null,
  );
}

enum _Phase { hidden, loading, countdown, showing, timedOut, away }

/// The animated QR code of one transaction text, covered until Show QR. Its text is read
/// ([path]) and cut into parts on the first Show QR; a load or encode problem shows in place.
/// A new text covers it again.
class DeskSlateQr extends ConsumerStatefulWidget {
  const DeskSlateQr({super.key, required this.kind, this.json, this.path}) : assert(json != null || path != null);

  final DeskQrKind kind;

  /// The transaction text; or null and [path].
  final String? json;

  /// The file this wallet wrote, read when first shown.
  final String? path;

  @override
  ConsumerState<DeskSlateQr> createState() => _DeskSlateQrState();
}

class _DeskSlateQrState extends ConsumerState<DeskSlateQr> with WidgetsBindingObserver {
  _Phase _phase = _Phase.hidden;
  List<String>? _parts;

  /// [_parts] drawn once, at level H with the mark.
  QrFrames? _frames;
  String? _error;
  int _numeral = qrCountdownSeconds;
  int _secondsLeft = qrShowSeconds;
  int _frame = 0;
  Timer? _countTimer;
  Timer? _frameTimer;
  Timer? _secondTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(DeskSlateQr old) {
    super.didUpdateWidget(old);
    if (old.json != widget.json || old.path != widget.path || old.kind != widget.kind) {
      _stopTimers();
      _phase = _Phase.hidden;
      _parts = null;
      _frames = null;
      _error = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Minimised or hidden: covered, and it stays covered. A window that only lost focus keeps
    // the code, which the other device may be scanning.
    if (state != AppLifecycleState.hidden && state != AppLifecycleState.paused) return;
    if (_phase == _Phase.countdown || _phase == _Phase.showing) _cover(_Phase.away);
  }

  void _stopTimers() {
    _countTimer?.cancel();
    _frameTimer?.cancel();
    _secondTimer?.cancel();
    _countTimer = _frameTimer = _secondTimer = null;
  }

  void _cover(_Phase phase) {
    _stopTimers();
    if (mounted) setState(() => _phase = phase);
  }

  /// Show QR and Show again: the parts (read once), 3, 2, 1, then the code.
  Future<void> _start() async {
    if (_phase == _Phase.loading) return;
    if (_parts == null) {
      setState(() {
        _phase = _Phase.loading;
        _error = null;
      });
      try {
        final api = ref.read(deskApiProvider);
        final json = widget.json ?? await api.slateFileText(widget.path!);
        if (isSealedText(json)) throw StateError('sealed');
        final parts = await api.encodeQrSlate(json);
        if (parts.isEmpty) throw StateError('no parts');
        _parts = parts;
        _frames = QrFrames.of(parts);
      } on Object catch (e) {
        if (mounted) {
          final l = context.l10n;
          setState(() {
            _phase = _Phase.hidden;
            _error = e is DeskError ? deskErrorText(e, l) : l.deskQrCannotShow;
          });
        }
        return;
      }
      if (!mounted) return;
    }
    _stopTimers();
    setState(() {
      _phase = _Phase.countdown;
      _numeral = qrCountdownSeconds;
      _error = null;
    });
    _countTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_numeral > 1) {
        setState(() => _numeral--);
      } else {
        t.cancel();
        _countTimer = null;
        _show();
      }
    });
  }

  void _show() {
    final parts = _parts!;
    setState(() {
      _phase = _Phase.showing;
      _secondsLeft = qrShowSeconds;
      _frame = 0;
    });
    if (parts.length > 1) {
      _frameTimer = Timer.periodic(const Duration(milliseconds: qrFrameMs), (_) {
        if (mounted) setState(() => _frame = (_frame + 1) % parts.length);
      });
    }
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _cover(_Phase.timedOut);
      }
    });
  }

  /// "Part 2 of 5" for the frame on screen; the extra parts after the plain ones count as the
  /// plain part they sit on.
  (int, int) _partOf(List<String> parts) {
    final count = partCountOf(parts.first) ?? parts.length;
    final seq = partNumberOf(parts[_frame % parts.length]);
    return (seq == null ? _frame % count + 1 : (seq - 1) % count + 1, count);
  }

  String _status(AppLocalizations l) {
    final showing = _phase == _Phase.countdown || _phase == _Phase.showing;
    if (_phase == _Phase.away) return l.qrStatusHiddenAgain;
    return switch (widget.kind) {
      DeskQrKind.payment => showing ? l.qrStatusSendShowing : l.qrStatusSendHidden,
      DeskQrKind.reply => showing ? l.qrStatusReplyShowing : l.qrStatusReplyHidden,
      DeskQrKind.request => showing ? l.qrStatusRequestShowing : l.qrStatusRequestHidden,
      DeskQrKind.paid => showing ? l.qrStatusPaidShowing : l.qrStatusPaidHidden,
      DeskQrKind.finished => showing ? l.qrStatusFinishedShowing : l.qrStatusFinishedHidden,
    };
  }

  String _hiddenBody(AppLocalizations l) => switch (widget.kind) {
    DeskQrKind.payment => l.qrHiddenBodyPayment,
    DeskQrKind.reply => l.deskQrHiddenReply,
    DeskQrKind.request => l.qrHiddenBodyRequest,
    DeskQrKind.paid => l.deskQrHiddenPaid,
    DeskQrKind.finished => l.qrHiddenBodyFinished,
  };

  String _semantics(AppLocalizations l) {
    final state = _phase == _Phase.showing ? l.qrStateShowing : l.qrStateHidden;
    return switch (widget.kind) {
      DeskQrKind.payment => l.qrSemanticsPayment(state),
      DeskQrKind.request => l.qrSemanticsRequest(state),
      DeskQrKind.reply || DeskQrKind.paid => l.qrSemanticsReply(state),
      DeskQrKind.finished => l.qrSemanticsFinished(state),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final size = 264.u;
    final parts = _parts;
    final covered = _phase == _Phase.hidden || _phase == _Phase.loading || _phase == _Phase.away;
    Widget box(Widget child) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
      alignment: Alignment.center,
      padding: EdgeInsets.all(Sp.x4),
      child: child,
    );
    final Widget code = switch (_phase) {
      _Phase.showing when parts != null => ExcludeSemantics(child: EQr.frame(_frames!.images[_frame % parts.length], key: const ValueKey('desk-qr-image'), size: size)),
      _Phase.countdown => box(
        Semantics(
          liveRegion: true,
          label: l.qrCountdownLabel(_numeral),
          child: ExcludeSemantics(child: Text('$_numeral', key: const ValueKey('desk-qr-countdown'), style: ts.display.copyWith(color: c.text))),
        ),
      ),
      _Phase.timedOut => box(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.qrTimedOutTitle(qrShowSeconds), key: const ValueKey('desk-qr-timed-out'), style: ts.strong, textAlign: TextAlign.center),
            SizedBox(height: Sp.x2),
            Text(l.deskQrTimedOutBody, style: ts.small, textAlign: TextAlign.center),
            SizedBox(height: Sp.x3),
            EButton(key: const ValueKey('desk-qr-show'), label: l.qrShowAgain, icon: EIcons.eye, size: EBtnSize.sm, onPressed: _start),
          ],
        ),
      ),
      _ => box(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(EIcons.qr, size: 48.u, color: c.faint),
            SizedBox(height: Sp.x3),
            EButton(
              key: const ValueKey('desk-qr-show'),
              label: l.qrShow,
              icon: EIcons.eye,
              size: EBtnSize.sm,
              busy: _phase == _Phase.loading,
              onPressed: _phase == _Phase.loading ? null : _start,
            ),
          ],
        ),
      ),
    };
    final (part, count) = parts == null ? (0, 0) : _partOf(parts);
    final low = _secondsLeft <= qrLowSeconds;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 360.u),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_status(l), key: const ValueKey('desk-qr-status'), style: ts.body, textAlign: TextAlign.center),
          SizedBox(height: Sp.x3),
          Semantics(container: true, image: true, label: _semantics(l), child: code),
          SizedBox(height: Sp.x3),
          if (_phase == _Phase.showing && parts != null) ...[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Sp.x3,
              runSpacing: Sp.x1,
              children: [
                if (count > 1) Text(l.qrPartOf(part, count), key: const ValueKey('desk-qr-part'), style: ts.small),
                Semantics(
                  liveRegion: _secondsLeft == qrLowSeconds,
                  child: Text(l.qrSecondsLeft(_secondsLeft), key: const ValueKey('desk-qr-left'), style: ts.small.copyWith(color: low ? c.warn : c.dim)),
                ),
              ],
            ),
            SizedBox(height: Sp.x2),
            EButton.ghost(key: const ValueKey('desk-qr-hide'), label: l.qrHide, icon: EIcons.eyeOff, size: EBtnSize.sm, onPressed: () => _cover(_Phase.hidden)),
          ] else if (covered)
            Text(_hiddenBody(l), style: ts.small, textAlign: TextAlign.center),
          if (_error != null) ...[
            SizedBox(height: Sp.x2),
            Text(_error!, key: const ValueKey('desk-qr-error'), style: ts.small.copyWith(color: c.risk), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
