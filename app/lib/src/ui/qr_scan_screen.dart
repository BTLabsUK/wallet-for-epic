/// The camera screen that reads an animated payment QR: the receiver's scan of the payment and
/// the sender's scan of the reply. Returns what it read through [QrScanResult]; the caller
/// opens it like pasted text.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../providers.dart';
import '../qr_slate.dart';
import '../secure_screen.dart';
import '../settings.dart';
import 'common.dart';
import 'qr_camera.dart';
import 'qr_common.dart';
import 'theme/tokens.dart';

/// What the scan screen hands back.
sealed class QrScanResult {
  const QrScanResult();
}

/// Every part was read: [json] is the payment text, not yet checked as a payment. With a
/// `finish` step, [posted] says it went through.
final class QrScanned extends QrScanResult {
  const QrScanned(this.json, {this.posted = false});

  final String json;
  final bool posted;
}

/// What the sender's scan does with the reply once it is read: finishes and posts the payment.
/// True when it was posted; a false answer closes the screen so the caller can say why.
typedef QrFinish = Future<bool> Function(String json);

/// The user chose a file instead of the camera.
final class QrScanOpenFile extends QrScanResult {
  const QrScanOpenFile();
}

/// What the camera is read for.
enum QrScanKind {
  /// The receiver reads the sender's payment.
  payment,

  /// The sender reads the receiver's reply.
  reply,
}

/// How long the not-a-payment warning stays in the dock.
const Duration qrNoticeFor = Duration(milliseconds: 2500);

/// How long the corners stay amber for a code that is not a payment.
const Duration qrWarnCornersFor = Duration(milliseconds: 1500);

/// How long the red corners stay for a code of another payment, before reading starts over.
const Duration qrOtherPaymentFor = Duration(milliseconds: 1200);

/// How long the check stays on screen before the screen closes with the result.
const Duration qrCompleteFor = Duration(milliseconds: 350);

const Duration _notSlateCooldown = Duration(seconds: 2);

/// How long "Posted" stays before the screen closes.
const Duration qrPostedFor = Duration(milliseconds: 800);

/// Opens the scan screen and returns its result, or null when the user backs out. With
/// [finish] the screen runs it on the finished reply and says "Posting…" and "Posted".
Future<QrScanResult?> scanQrSlate(
  BuildContext context,
  QrScanKind kind, {
  QrFinish? finish,
}) => Navigator.of(context).push<QrScanResult>(
  MaterialPageRoute<QrScanResult>(
    builder: (_) => QrScanScreen(kind: kind, finish: finish),
  ),
);

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key, required this.kind, this.finish});

  const QrScanScreen.payment({Key? key})
    : this(key: key, kind: QrScanKind.payment);

  const QrScanScreen.reply({Key? key, QrFinish? finish})
    : this(key: key, kind: QrScanKind.reply, finish: finish);

  final QrScanKind kind;

  /// What to do with the finished reply; null hands the text back as it is.
  final QrFinish? finish;

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

enum _Notice { none, notSlate, otherPayment }

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  late final QrCamera _camera = ref.read(qrCameraFactoryProvider)();
  late final QrSlateReader _reader = QrSlateReader(
    ref.read(walletServiceProvider),
  );
  StreamSubscription<String>? _codes;

  int _received = 0;
  int _count = 0;

  /// The count the live region last spoke: at most once a second.
  int _spoken = 0;
  bool _steady = false;
  bool _complete = false;

  /// The reply is read and [QrScanScreen.finish] is running, then it posted.
  bool _posting = false;
  bool _posted = false;
  _Notice _notice = _Notice.none;
  bool _warnCorners = false;
  bool _cooling = false;

  Timer? _holdTimer;
  Timer? _noticeTimer;
  Timer? _cornerTimer;
  Timer? _coolTimer;
  Timer? _speakTimer;
  Timer? _doneTimer;

  @override
  void initState() {
    super.initState();
    PortraitLock.hold();
    _codes = _camera.codes.listen(_onCode);
    // After this frame: the hold is a provider, which a build must not change.
    Future.microtask(_retry);
  }

  @override
  void dispose() {
    _codes?.cancel();
    for (final timer in [
      _holdTimer,
      _noticeTimer,
      _cornerTimer,
      _coolTimer,
      _speakTimer,
      _doneTimer,
    ]) {
      timer?.cancel();
    }
    unawaited(_camera.close());
    PortraitLock.release();
    super.dispose();
  }

  Future<void> _onCode(String text) async {
    if (_complete) return;
    final QrRead read;
    try {
      read = await _reader.feed(text);
    } catch (_) {
      return;
    }
    if (!mounted || _complete) return;
    switch (read.kind) {
      case QrReadKind.repeat:
        return;
      case QrReadKind.notSlate:
      case QrReadKind.unreadable:
        _notSlate();
      case QrReadKind.otherPayment:
        _otherPayment();
      case QrReadKind.part:
        _part(read.received, read.count);
      case QrReadKind.complete:
        _finish(read);
    }
  }

  void _part(int received, int count) {
    final grew = received > _received;
    if (!grew && count == _count) return;
    if (_received == 0 && received > 0) {
      unawaited(tap(HapticFeedback.selectionClick));
    }
    setState(() {
      _received = received;
      _count = count;
      if (grew) _steady = false;
    });
    if (grew) {
      _holdTimer?.cancel();
      _holdTimer = Timer(const Duration(seconds: qrHoldSteadySeconds), () {
        if (mounted && !_complete) setState(() => _steady = true);
      });
    }
    _speak();
  }

  /// Hands the count to the live region, at most once a second.
  void _speak() {
    if (_speakTimer?.isActive ?? false) return;
    _spoken = _received;
    _speakTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && _spoken != _received) setState(_speak);
    });
  }

  void _notSlate() {
    if (_cooling || _notice == _Notice.otherPayment) return;
    _cooling = true;
    _coolTimer = Timer(_notSlateCooldown, () => _cooling = false);
    unawaited(tap(HapticFeedback.lightImpact));
    setState(() {
      _notice = _Notice.notSlate;
      _warnCorners = true;
    });
    _noticeTimer?.cancel();
    _noticeTimer = Timer(qrNoticeFor, () {
      if (mounted && _notice == _Notice.notSlate) {
        setState(() => _notice = _Notice.none);
      }
    });
    _cornerTimer?.cancel();
    _cornerTimer = Timer(qrWarnCornersFor, () {
      if (mounted) setState(() => _warnCorners = false);
    });
  }

  void _otherPayment() {
    unawaited(tap(HapticFeedback.heavyImpact));
    _holdTimer?.cancel();
    setState(() {
      _notice = _Notice.otherPayment;
      _steady = false;
    });
    _noticeTimer?.cancel();
    _noticeTimer = Timer(qrOtherPaymentFor, () {
      if (!mounted) return;
      // The reader began again with the next parts; the screen follows it.
      setState(() {
        _notice = _Notice.none;
        _received = _reader.received;
        _count = _reader.count;
        _spoken = _received;
      });
    });
  }

  void _finish(QrRead read) {
    _holdTimer?.cancel();
    _noticeTimer?.cancel();
    unawaited(tap(HapticFeedback.mediumImpact));
    setState(() {
      _complete = true;
      _received = read.received;
      _count = read.count;
      _spoken = read.received;
      _steady = false;
      _notice = _Notice.none;
      _warnCorners = false;
    });
    final json = read.json!;
    final finish = widget.finish;
    if (finish == null) {
      _doneTimer = Timer(qrCompleteFor, () {
        if (mounted) Navigator.of(context).pop(QrScanned(json));
      });
      return;
    }
    _doneTimer = Timer(qrCompleteFor, () => _post(json, finish));
  }

  /// Runs the caller's finish step on the reply, telling how it goes.
  Future<void> _post(String json, QrFinish finish) async {
    if (!mounted) return;
    setState(() => _posting = true);
    var posted = false;
    try {
      posted = await finish(json);
    } catch (_) {
      posted = false;
    }
    if (!mounted) return;
    if (!posted) {
      Navigator.of(context).pop(QrScanned(json));
      return;
    }
    setState(() {
      _posting = false;
      _posted = true;
    });
    _doneTimer = Timer(qrPostedFor, () {
      if (mounted) Navigator.of(context).pop(QrScanned(json, posted: true));
    });
  }

  Future<void> _retry() async {
    if (!mounted) return;
    await ref.read(autoLockHoldProvider.notifier).during(_camera.start);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _camera,
      builder: (context, _) {
        final state = _camera.value;
        if (state.problem != null) {
          return _CameraProblem(
            problem: state.problem!,
            onRetry: _retry,
            onFile: () => Navigator.of(context).pop(const QrScanOpenFile()),
          );
        }
        return _view(context, state);
      },
    );
  }

  Widget _view(BuildContext context, QrCameraState camera) {
    final l = context.l10n;
    const dark = protocolDark;
    final reply = widget.kind == QrScanKind.reply;
    final finishesHere = widget.finish != null;
    final title = reply ? l.qrScanReply : l.qrScanPayment;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final top = MediaQuery.paddingOf(context).top;

    final String dockText;
    final _DockTone tone;
    if (_posted) {
      dockText = l.qrScanPosted;
      tone = _DockTone.ok;
    } else if (_posting) {
      dockText = l.qrScanPosting;
      tone = _DockTone.info;
    } else if (_complete) {
      dockText = finishesHere ? l.qrScanReplyScanned : l.qrScanGot;
      tone = _DockTone.ok;
    } else if (_notice == _Notice.otherPayment) {
      dockText = l.qrScanOtherPayment;
      tone = _DockTone.risk;
    } else if (_notice == _Notice.notSlate) {
      dockText = reply ? l.qrScanNotReply : l.qrScanNotPayment;
      tone = _DockTone.warn;
    } else if (_steady) {
      dockText = l.qrScanSteady;
      tone = _DockTone.warn;
    } else if (_received == 0) {
      dockText = reply ? l.qrScanAimReply : l.qrScanAimPayment;
      tone = _DockTone.plain;
    } else {
      dockText = l.qrScanProgress(_received, _count);
      tone = _DockTone.plain;
    }
    final Color corners = _complete
        ? dark.ok
        : _notice == _Notice.otherPayment
        ? dark.risk
        : (_warnCorners || _steady)
        ? dark.warn
        : Colors.white;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(title),
        actions: [
          _ZoomChip(
            zoomed: camera.zoomed,
            onPressed: () => _camera.setZoom(twice: !camera.zoomed),
          ),
          if (camera.torchAvailable)
            IconButton(
              tooltip: l.qrScanTorch,
              isSelected: camera.torchOn,
              icon: const Icon(Icons.flashlight_off),
              selectedIcon: const Icon(Icons.flashlight_on),
              onPressed: _camera.toggleTorch,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final card = (size.width - 90).clamp(264.0, 312.0);
          final side = (card - 20).clamp(0.0, 280.0);
          final center = Offset(size.width / 2, size.height * 0.48);
          final finder = Rect.fromCenter(
            center: center,
            width: side,
            height: side,
          );
          final ring = finder.inflate(14);
          return Stack(
            fit: StackFit.expand,
            children: [
              _camera.preview(context),
              IgnorePointer(
                child: CustomPaint(painter: _ScrimPainter(finder: finder)),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: top + 56,
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x8C000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _FramePainter(
                    finder: finder,
                    ring: ring,
                    received: _received,
                    count: _count,
                    complete: _complete,
                    corners: corners,
                    info: dark.info,
                    ok: dark.ok,
                  ),
                ),
              ),
              if (_complete)
                Positioned.fromRect(
                  rect: finder,
                  child: Center(
                    child: _CheckTile(animate: !reduced, color: dark.ok),
                  ),
                ),
              if (_count > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: ring.bottom + 26 - 10,
                  child: Semantics(
                    liveRegion: true,
                    label:
                        '${l.qrScanCountLabel}: ${l.qrScanCount(_spoken, _count)}',
                    excludeSemantics: true,
                    child: Text(
                      l.qrScanCount(_received, _count),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: dark.monoFamily,
                        fontSize: 15,
                        color: _complete ? dark.ok : Colors.white,
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _Dock(text: dockText, tone: tone),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _DockTone { plain, info, warn, risk, ok }

/// The line at the bottom of the camera: what to do, or what went wrong. Always dark, since the
/// camera is.
class _Dock extends StatelessWidget {
  const _Dock({required this.text, required this.tone});

  final String text;
  final _DockTone tone;

  @override
  Widget build(BuildContext context) {
    const dark = protocolDark;
    final (fill, icon, color) = switch (tone) {
      _DockTone.plain => (const Color(0x9E000000), null, Colors.white),
      _DockTone.info => (const Color(0xD60F2A40), Icons.sync, dark.info),
      _DockTone.warn => (
        const Color(0xD13C260A),
        Icons.warning_amber_rounded,
        dark.warn,
      ),
      _DockTone.risk => (
        const Color(0xD6461414),
        Icons.error_outline,
        dark.risk,
      ),
      _DockTone.ok => (
        const Color(0xD6103C1C),
        Icons.check_circle_outline,
        dark.ok,
      ),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: fill,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: color),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomChip extends StatelessWidget {
  const _ZoomChip({required this.zoomed, required this.onPressed});

  final bool zoomed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final factor = zoomed ? '2' : '1';
    return Semantics(
      button: true,
      label: l.qrScanZoom(zoomed ? '1' : '2'),
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            child: Container(
              height: 36,
              constraints: const BoxConstraints(minWidth: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: zoomed ? Colors.white : const Color(0x59000000),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x59FFFFFF)),
              ),
              child: Text(
                '$factor×',
                style: TextStyle(
                  fontFamily: protocolDark.monoFamily,
                  fontSize: 13,
                  color: zoomed ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.animate, required this.color});

  final bool animate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.check, size: 40, color: Colors.black),
    );
    if (!animate) return tile;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: tile,
    );
  }
}

/// The picture dimmed everywhere but the viewfinder.
class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({required this.finder});

  final Rect finder;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(finder, const Radius.circular(18)));
    canvas.drawPath(path, Paint()..color = const Color(0x47000000));
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.finder != finder;
}

/// The corner brackets, and the ring of one segment per part around them.
class _FramePainter extends CustomPainter {
  const _FramePainter({
    required this.finder,
    required this.ring,
    required this.received,
    required this.count,
    required this.complete,
    required this.corners,
    required this.info,
    required this.ok,
  });

  final Rect finder;
  final Rect ring;
  final int received;
  final int count;
  final bool complete;
  final Color corners;
  final Color info;
  final Color ok;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0x57FFFFFF);
    final path = roundedSquarePath(ring, 24);
    final metric = path.computeMetrics().first;
    final length = metric.length;
    if (count <= 1) {
      canvas.drawPath(path, complete ? (track..color = ok) : track);
    } else {
      final gap = length * 0.006;
      final each = length / count;
      for (var i = 0; i < count; i++) {
        final read = complete || i < received;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.butt
          ..color = read ? (complete ? ok : info) : track.color;
        canvas.drawPath(
          metric.extractPath(i * each + gap / 2, (i + 1) * each - gap / 2),
          paint,
        );
      }
    }
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = corners;
    const r = 18.0;
    const len = 28.0;
    final f = finder;
    final r0 = Radius.circular(r);
    canvas
      ..drawPath(
        Path()
          ..moveTo(f.left, f.top + len)
          ..lineTo(f.left, f.top + r)
          ..arcToPoint(Offset(f.left + r, f.top), radius: r0)
          ..lineTo(f.left + len, f.top),
        bracket,
      )
      ..drawPath(
        Path()
          ..moveTo(f.right - len, f.top)
          ..lineTo(f.right - r, f.top)
          ..arcToPoint(Offset(f.right, f.top + r), radius: r0)
          ..lineTo(f.right, f.top + len),
        bracket,
      )
      ..drawPath(
        Path()
          ..moveTo(f.right, f.bottom - len)
          ..lineTo(f.right, f.bottom - r)
          ..arcToPoint(Offset(f.right - r, f.bottom), radius: r0)
          ..lineTo(f.right - len, f.bottom),
        bracket,
      )
      ..drawPath(
        Path()
          ..moveTo(f.left + len, f.bottom)
          ..lineTo(f.left + r, f.bottom)
          ..arcToPoint(Offset(f.left, f.bottom - r), radius: r0)
          ..lineTo(f.left, f.bottom - len),
        bracket,
      );
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.finder != finder ||
      old.received != received ||
      old.count != count ||
      old.complete != complete ||
      old.corners != corners;
}

/// The camera was refused or did not start: what to do instead.
class _CameraProblem extends StatelessWidget {
  const _CameraProblem({
    required this.problem,
    required this.onRetry,
    required this.onFile,
  });

  final QrCameraProblem problem;
  final Future<void> Function() onRetry;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final denied = problem == QrCameraProblem.denied;
    return SlotScaffold(
      appBar: AppBar(title: Text(l.qrScanPayment)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  denied ? Icons.no_photography : Icons.error_outline,
                  size: 48,
                  color: t.risk,
                ),
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    denied ? l.qrScanCameraDenied : l.qrScanCameraFailed,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 16),
                if (denied)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                    label: Text(l.qrScanOpenSettings),
                    onPressed: () => openAppSettings(),
                  )
                else
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: onRetry,
                    child: Text(l.scanQrTryAgain),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.file_open_outlined),
                  label: Text(l.qrScanOpenFileInstead),
                  onPressed: onFile,
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.scanQrBack),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
