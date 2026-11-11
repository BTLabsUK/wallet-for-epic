// SPDX-License-Identifier: Apache-2.0
/// The desktop's QR scan: one dialog over the screen that asked, reading a code with the
/// computer's camera, or several parts of an animated one. Every problem shows in place with
/// Paste, so the code can always come in as text. Nothing here retries by itself or touches the
/// system's camera settings.
///
/// The API every desktop screen uses:
/// - [deskScanQr]: one code's text.
/// - [deskScanParts]: an animated code, read by a [DeskPartReader].
/// - [DeskScanButton]: Scan, greyed out while [cameraPresenceProvider] finds no camera.
/// - [DeskNoCameraLine]: the one quiet line beside paste when there is none.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../camera/camera_presence.dart';
import '../../../scan/scan_router.dart' show looksLikeRecoveryPhrase;
import '../../../ui/qr_camera.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// What a scan gave: a code the camera read, or the text pasted in its place.
sealed class DeskScanResult<T> {
  const DeskScanResult();
}

/// The camera read it: [value] is the reader's result (the text, for [deskScanQr]).
final class DeskScanned<T> extends DeskScanResult<T> {
  const DeskScanned(this.value);
  final T value;
}

/// The user pasted [text] instead; the caller opens it as any pasted text (origin paste).
final class DeskPasted<T> extends DeskScanResult<T> {
  const DeskPasted(this.text);
  final String text;
}

/// Where an animated code's reading stands.
sealed class DeskPartStep<T> {
  const DeskPartStep();
}

/// More parts to read: [received] of [total] (total 0 until the first part says it).
final class DeskPartWaiting<T> extends DeskPartStep<T> {
  const DeskPartWaiting(this.received, this.total);
  final int received;
  final int total;
}

/// The whole code is in.
final class DeskPartDone<T> extends DeskPartStep<T> {
  const DeskPartDone(this.value);
  final T value;
}

/// A text the reader does not take (another code in view): [message] says so in the dialog; the
/// scan goes on.
final class DeskPartRefused<T> extends DeskPartStep<T> {
  const DeskPartRefused(this.message);
  final String Function(AppLocalizations l) message;
}

/// Reads the texts of one scan, repeats included, into a [T]. A read may be async (a code checked
/// against the wallet): the dialog awaits each one before the next, in the order the camera read
/// them.
abstract class DeskPartReader<T> {
  FutureOr<DeskPartStep<T>> read(String text);
}

/// A reader done on the first text it takes. A recovery phrase is refused unless [phrase].
class DeskSingleReader implements DeskPartReader<String> {
  const DeskSingleReader({this.phrase = false});

  /// The restore screen reads a phrase; nowhere else does.
  final bool phrase;

  @override
  DeskPartStep<String> read(String text) {
    final t = text.trim();
    if (t.isEmpty) return const DeskPartWaiting(0, 0);
    if (!phrase && looksLikeRecoveryPhrase(t)) return DeskPartRefused((l) => l.scanPhraseFoundQr);
    return DeskPartDone(t);
  }
}

/// One code's text, or the pasted text, or null when closed.
Future<DeskScanResult<String>?> deskScanQr(BuildContext context, {required String title, String? hint, bool phrase = false}) =>
    deskScanParts(context, title: title, hint: hint, reader: DeskSingleReader(phrase: phrase));

/// An animated code read by [reader], or the pasted text, or null when closed.
Future<DeskScanResult<T>?> deskScanParts<T>(BuildContext context, {required String title, String? hint, required DeskPartReader<T> reader}) =>
    showEDialog<DeskScanResult<T>>(context, builder: (_) => DeskScanDialog<T>(title: title, hint: hint, reader: reader));

/// The desktop system the words name: the settings page of a refusal, what a system lacks.
enum DeskScanOs { windows, macos, linux, other }

/// Set by tests and the screenshot tour to show another system's words; null in the app.
DeskScanOs? deskScanOsOverride;

DeskScanOs get _os =>
    deskScanOsOverride ??
    (Platform.isWindows
        ? DeskScanOs.windows
        : Platform.isMacOS
        ? DeskScanOs.macos
        : Platform.isLinux
        ? DeskScanOs.linux
        : DeskScanOs.other);

/// What this system lacks for the camera, in its own words.
String _unsupported(AppLocalizations l) => switch (_os) {
  DeskScanOs.linux => l.deskScanUnsupportedLinux,
  DeskScanOs.windows => l.deskScanUnsupportedWindows,
  _ => l.deskScanUnsupportedOther,
};

/// Why this computer cannot scan: no camera found, or what the system lacks. Null otherwise.
String? _noCameraText(AppLocalizations l, CameraPresence presence) => switch (presence) {
  CameraPresence.none => l.deskScanNoCamera,
  CameraPresence.unsupported => _unsupported(l),
  _ => null,
};

/// The one line of each camera problem.
String deskScanProblemText(AppLocalizations l, QrCameraProblem p) => switch (p) {
  QrCameraProblem.denied => switch (_os) {
    DeskScanOs.windows => l.deskScanDeniedWindows,
    DeskScanOs.macos => l.deskScanDeniedMac,
    _ => l.deskScanDeniedLinux,
  },
  QrCameraProblem.unsupported => _unsupported(l),
  QrCameraProblem.busy => l.deskScanBusy,
  QrCameraProblem.failed => l.deskScanFailed,
  QrCameraProblem.noPicture => l.deskScanNoPicture,
  QrCameraProblem.dark => l.deskScanDark,
  QrCameraProblem.unplugged => l.deskScanUnplugged,
  QrCameraProblem.readerFailed => l.deskScanReaderFailed,
};

IconData _problemIcon(QrCameraProblem p) => switch (p) {
  QrCameraProblem.denied => EIcons.lock,
  QrCameraProblem.busy => EIcons.cancel,
  QrCameraProblem.noPicture || QrCameraProblem.dark => EIcons.eyeOff,
  QrCameraProblem.unplugged => EIcons.alert,
  _ => EIcons.error,
};

/// The scan dialog: the camera's picture with the aim line, the parts read so far, and every
/// camera problem in place of the picture with Paste and Close (and Try again where the camera
/// stopped). Close always works, while the camera starts too.
class DeskScanDialog<T> extends ConsumerStatefulWidget {
  const DeskScanDialog({super.key, required this.title, this.hint, required this.reader});

  final String title;
  final String? hint;
  final DeskPartReader<T> reader;

  @override
  ConsumerState<DeskScanDialog<T>> createState() => _DeskScanDialogState<T>();
}

class _DeskScanDialogState<T> extends ConsumerState<DeskScanDialog<T>> {
  late final QrCamera _camera = ref.read(qrCameraFactoryProvider)();
  StreamSubscription<String>? _sub;

  // Until the camera's start returns: the picture area says so.
  bool _starting = true;
  int _attempt = 0;

  // The last step the reader gave: progress, or the refusal of another code.
  DeskPartStep<T>? _step;

  // The texts waiting while a read runs, each once; the one being read is [_reading].
  final List<String> _queue = [];
  String? _reading;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _sub = _camera.codes.listen(_onCode);
    _start();
  }

  Future<void> _start() async {
    final attempt = ++_attempt;
    _starting = true;
    if (attempt > 1) setState(() {});
    try {
      await _camera.start();
    } catch (_) {
      // start never throws by contract; a broken camera still shows as stopped below.
    }
    if (!mounted || _done || attempt != _attempt) return;
    setState(() => _starting = false);
  }

  void _onCode(String text) {
    if (_done || !mounted || text == _reading || _queue.contains(text)) return;
    _queue.add(text);
    if (_reading == null) _drain();
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty && !_done && mounted) {
      final text = _reading = _queue.removeAt(0);
      DeskPartStep<T>? step;
      try {
        step = await widget.reader.read(text);
      } catch (_) {
        // A reader that throws refuses that text; the scan goes on.
      } finally {
        _reading = null;
      }
      if (_done || !mounted) return;
      if (step == null) continue;
      if (step case DeskPartDone<T>(:final value)) return _finish(DeskScanned<T>(value));
      // An empty read says nothing new: keep what the line shows.
      if (step case DeskPartWaiting<T>(total: 0, received: 0) when _step != null) continue;
      setState(() => _step = step);
    }
  }

  void _finish(DeskScanResult<T>? result) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(result);
  }

  // The clipboard is read on this press only.
  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || text.isEmpty) return;
    _finish(DeskPasted<T>(text));
  }

  @override
  void dispose() {
    _done = true;
    _queue.clear();
    _sub?.cancel();
    _camera.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListenableBuilder(
      listenable: _camera,
      builder: (context, _) {
        final problem = _camera.value.problem;
        final stopped = problem != null && problem.stopsScan;
        return EDialog(
          title: widget.title,
          description: widget.hint,
          icon: EIcons.camera,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Viewer(camera: _camera, starting: _starting && problem == null, problem: problem),
              if (!stopped) ...[SizedBox(height: Sp.x3), _ScanLine<T>(step: _step)],
            ],
          ),
          actions: [
            if (stopped) EButton(label: l.deskScanTryAgain, size: EBtnSize.sm, onPressed: _start),
            EButton(label: l.commonPaste, icon: EIcons.paste, size: EBtnSize.sm, onPressed: _paste),
            EButton(label: l.commonClose, size: EBtnSize.sm, onPressed: () => _finish(null)),
          ],
        );
      },
    );
  }
}

/// The picture area: 4:3 at the dialog's width, the picture mirrored as a mirror is, with the
/// frame to aim at; or the start, or a problem, in its place.
class _Viewer extends StatelessWidget {
  const _Viewer({required this.camera, required this.starting, required this.problem});

  final QrCamera camera;
  final bool starting;
  final QrCameraProblem? problem;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final p = problem;
    final live = !starting && (p == null || !p.stopsScan);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        // A third of the window at most, so the line under it and the buttons stay in view.
        final h = (w * 3 / 4).clamp(140.u, 300.u).clamp(0.0, (MediaQuery.sizeOf(context).height * 0.34).clamp(140.u, 300.u));
        return ClipRRect(
          borderRadius: BorderRadius.circular(Rad.sm),
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(color: c.s3),
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(Rad.sm),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (live) ExcludeSemantics(child: Transform.flip(flipX: true, child: camera.preview(context))),
                if (live && p == null) IgnorePointer(child: CustomPaint(painter: _FramePainter(c.text.withValues(alpha: 0.7)))),
                if (starting)
                  _Message(icon: EIcons.camera, text: context.l10n.deskScanStarting, iconColor: c.dim)
                else if (p != null)
                  _Message(icon: _problemIcon(p), text: deskScanProblemText(context.l10n, p), iconColor: c.warn, scrim: !p.stopsScan),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One centred icon and line in the picture area; over a picture ([scrim]) on a dimmed band.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, required this.iconColor, this.scrim = false});

  final IconData icon;
  final String text;
  final Color iconColor;
  final bool scrim;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final content = Padding(
      padding: EdgeInsets.all(Sp.x6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Ctl.iconLg, color: iconColor),
          SizedBox(height: Sp.x3),
          Text(text, textAlign: TextAlign.center, style: context.ts.body),
        ],
      ),
    );
    return Semantics(
      liveRegion: true,
      child: scrim ? ColoredBox(color: c.bg.withValues(alpha: 0.82), child: Center(child: content)) : Center(child: content),
    );
  }
}

/// The line under the picture: where to hold the code, how many parts are in, or why the code
/// in view is not taken.
class _ScanLine<T> extends StatelessWidget {
  const _ScanLine({required this.step});

  final DeskPartStep<T>? step;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final s = step;
    if (s case DeskPartRefused<T>(:final message)) {
      return Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: EdgeInsets.only(top: 2.u), child: Icon(EIcons.alert, size: Ctl.iconSm, color: c.warn)),
            SizedBox(width: Sp.x2),
            Expanded(child: Text(message(l), style: context.ts.small.copyWith(color: c.text))),
          ],
        ),
      );
    }
    if (s case DeskPartWaiting<T>(:final received, :final total) when total > 0) {
      return Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EProgress(value: received / total),
            SizedBox(height: Sp.x2),
            Text(l.qrScanProgress(received, total), style: context.ts.small),
          ],
        ),
      );
    }
    return Text(l.deskScanAim, style: context.ts.small);
  }
}

/// Four corners around the middle square of the picture: where the code goes.
class _FramePainter extends CustomPainter {
  _FramePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.62;
    final r = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    final arm = side * 0.16;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (corner, dx, dy) in [(r.topLeft, 1.0, 1.0), (r.topRight, -1.0, 1.0), (r.bottomLeft, 1.0, -1.0), (r.bottomRight, -1.0, -1.0)]) {
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx, corner.dy + dy * arm)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx + dx * arm, corner.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.color != color;
}

/// Scan, beside a field's paste: offered while a camera is found, greyed out otherwise. It
/// checks again when it first shows.
class DeskScanButton extends ConsumerStatefulWidget {
  const DeskScanButton({super.key, required this.onScan, this.size = EBtnSize.inline, this.label});

  final VoidCallback onScan;
  final EBtnSize size;

  /// Set: a button with this label and the camera icon (Home, beside Send and Receive); its
  /// greyed-out state carries the reason as a tip. Unset: the icon button beside a field.
  final String? label;

  @override
  ConsumerState<DeskScanButton> createState() => _DeskScanButtonState();
}

class _DeskScanButtonState extends ConsumerState<DeskScanButton> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(cameraPresenceProvider.notifier).recheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    final presence = ref.watch(cameraPresenceProvider);
    final on = presence.offersScan;
    final label = widget.label;
    if (label != null) {
      final button = EButton(label: label, icon: EIcons.camera, size: widget.size, onPressed: on ? widget.onScan : null);
      final why = _noCameraText(context.l10n, presence);
      return on || why == null ? button : ETip(why, child: button);
    }
    return EIconButton(icon: EIcons.camera, label: context.l10n.scanQrTitle, size: widget.size, onPressed: on ? widget.onScan : null);
  }
}

/// The one quiet line under a paste field when this computer has no camera to scan with:
/// nothing found, or what the system lacks. Nothing otherwise.
class DeskNoCameraLine extends ConsumerWidget {
  const DeskNoCameraLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final text = _noCameraText(l, ref.watch(cameraPresenceProvider));
    if (text == null) return const SizedBox.shrink();
    final c = context.dc;
    return Padding(
      padding: EdgeInsets.only(top: Sp.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: EdgeInsets.only(top: 2.u), child: Icon(EIcons.info, size: Ctl.iconSm, color: c.dim)),
          SizedBox(width: Sp.x2),
          Expanded(child: Text(text, style: context.ts.small)),
        ],
      ),
    );
  }
}
