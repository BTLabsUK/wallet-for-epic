// SPDX-License-Identifier: Apache-2.0
/// The camera screen that reads an animated payment QR: the receiver's scan of the payment and
/// the sender's scan of the reply. Returns what it read through [QrScanResult]; the caller
/// opens it like pasted text.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../l10n.dart';
import '../providers.dart';
import '../qr_slate.dart';
import '../secure_screen.dart';
import '../settings.dart';
import '../trust_ids.dart';
import '../wallet_service.dart' show FakeWalletSession;
import 'common.dart';
import 'kit/kit_button.dart';
import 'kit/kit_empty_state.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_step_strip.dart';
import 'kit/kit_tokens.dart';
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

  /// A device that is online reads a payment finished under Kill switch, to post it.
  finished,
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

/// How long the first start waits before trying a camera that failed once more.
const Duration qrCameraRetryAfter = Duration(milliseconds: 900);

/// How long "Posted" stays before the screen closes.
const Duration qrPostedFor = Duration(milliseconds: 800);

/// Opens the scan screen and returns its result, or null when the user backs out. With
/// [finish] the screen runs it on the finished reply and says "Posting…" and "Posted".
/// [first] is a part another scanner already read (Home's scan), read before the camera's.
Future<QrScanResult?> scanQrSlate(
  BuildContext context,
  QrScanKind kind, {
  QrFinish? finish,
  String? first,
  BigInt? amount,
}) => Navigator.of(context).push<QrScanResult>(
  MaterialPageRoute<QrScanResult>(
    builder: (_) => QrScanScreen(kind: kind, finish: finish, first: first, amount: amount),
  ),
);

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({
    super.key,
    required this.kind,
    this.finish,
    this.first,
    this.amount,
  });

  const QrScanScreen.payment({Key? key})
    : this(key: key, kind: QrScanKind.payment);

  const QrScanScreen.reply({Key? key, QrFinish? finish})
    : this(key: key, kind: QrScanKind.reply, finish: finish);

  final QrScanKind kind;

  /// What to do with the finished reply; null hands the text back as it is.
  final QrFinish? finish;

  /// A part read before this screen opened, fed first.
  final String? first;

  /// What the payment is for, when the caller knows it (the payer's own): said under the camera.
  final BigInt? amount;

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

enum _Notice { none, notSlate, otherPayment }

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  late final QrCamera _camera = qrPreviewSimulation
      ? SimulatedQrCamera(source: _otherPhone)
      : ref.read(qrCameraFactoryProvider)();
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
    final first = widget.first;
    if (first != null) unawaited(_onCode(first));
    // After this frame: the hold is a provider, which a build must not change.
    Future.microtask(_firstStart);
  }

  /// The first start. Home's scan hands a payment code over the moment it reads one; this
  /// camera waits for Home's to be given back (scanner_backend.dart). A camera that fails to
  /// start all the same is tried once more after [qrCameraRetryAfter] before the screen says so.
  Future<void> _firstStart() async {
    await _retry();
    if (!mounted || _camera.value.problem != QrCameraProblem.failed) return;
    await Future<void>.delayed(qrCameraRetryAfter);
    await _retry();
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

  /// The web preview's other phone: what the fake wallet's sender shows (the payment) or its
  /// receiver shows (the reply).
  Future<List<String>> _otherPhone() async {
    final session = ref.read(sessionProvider);
    final slate = session is FakeWalletSession
        ? (widget.kind == QrScanKind.payment
              ? session.sendSlate
              : session.responseSlate)
        : null;
    if (slate == null) return const [];
    return ref
        .read(walletServiceProvider)
        .encodeQrSlate(
          json: slate.json,
          maxFragmentLen: qrFragmentLen,
          singleCodeMaxLen: qrSingleCodeMaxLen,
        );
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
        // The camera view is dark in either theme, so it takes the whole dark theme: the title,
        // icons and tips then read on the feed (a light theme's title was dark on black).
        return Theme(data: _scannerTheme, child: _view(context, state));
      },
    );
  }

  Widget _view(BuildContext context, QrCameraState camera) {
    final l = context.l10n;
    const dark = protocolDark;
    final reply = widget.kind == QrScanKind.reply;
    final finished = widget.kind == QrScanKind.finished;
    final finishesHere = widget.finish != null;
    final title = finished ? l.qrScanFinished : (reply ? l.qrScanReply : l.qrScanPayment);
    final reduced = MediaQuery.disableAnimationsOf(context);

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
      dockText = finished ? l.qrScanNotFinished : (reply ? l.qrScanNotReply : l.qrScanNotPayment);
      tone = _DockTone.warn;
    } else if (_steady) {
      dockText = l.qrScanSteady;
      tone = _DockTone.warn;
    } else if (_received == 0) {
      dockText = finished ? l.qrScanAimFinished : (reply ? l.phoneQrAimAnswer : l.qrScanAimPayment);
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
        : dark.accent;

    final t = dark;
    final steps = finished
        ? null
        : reply
        ? [l.phoneStepPayShow, l.phoneStepPayScan, l.commonDone]
        : [l.phoneStepRecvScan, l.phoneStepRecvShow, l.commonDone];

    return Scaffold(
      backgroundColor: dark.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitFlowHeader(
              title: finished ? title : (reply ? l.phoneQrTitlePay : title),
              back: reply,
              onLeading: () => Navigator.of(context).maybePop(),
              leadingId: TrustIds.qrscanBack,
            ),
            if (steps != null) KitStepStrip(labels: steps, current: reply ? 1 : 0),
            // The camera card is as tall as the frame draws it (420) and shorter on a small
            // screen; the line about what to do sits right under it.
            Expanded(
              child: Column(
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 442),
                      child:
                          Padding(
                            padding: const EdgeInsets.fromLTRB(Kit.gutter, 22, Kit.gutter, 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Kit.rSheetTop),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  border: Border.all(color: t.hair),
                                  borderRadius: BorderRadius.circular(Kit.rSheetTop),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final size = constraints.biggest;
                                    final side = math.min(size.width - 64, size.height - 90).clamp(0.0, 190.0);
                                    final center = Offset(size.width / 2, size.height / 2);
                                    final finder = Rect.fromCenter(center: center, width: side, height: side);
                                    final ring = finder.inflate(14);
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        _camera.preview(context),
                                        IgnorePointer(child: CustomPaint(painter: _ScrimPainter(finder: finder))),
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
                                            child: Center(child: _CheckTile(animate: !reduced, color: dark.ok)),
                                          ),
                                        if (_count > 0)
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            top: ring.bottom + 12,
                                            child: Semantics(
                                              liveRegion: true,
                                              label: '${l.qrScanCountLabel}: ${l.qrScanCount(_spoken, _count)}',
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
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
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
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Kit.gutter, 22, Kit.gutter, 0),
                      child: _Dock(
                        text: dockText,
                        tone: tone,
                        sub: reply && widget.amount != null && tone == _DockTone.plain
                            ? l.phoneQrPaidWhen(epicFor(l, widget.amount!, surface: AmountSurface.exact))
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Kit.gutter, 12, Kit.gutter, Kit.gutter),
              child: reply
                  ? KitButton(
                      label: l.phoneQrShowMine,
                      kind: KitButtonKind.quiet,
                      semanticsId: TrustIds.qrscanAgain,
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : const SizedBox(height: Kit.button),
            ),
          ],
        ),
      ),
    );
  }
}

/// The scanner's theme: Protocol dark whatever the app's.
final ThemeData _scannerTheme = buildWalletTheme(protocolDark, Brightness.dark);

enum _DockTone { plain, info, warn, risk, ok }

/// The line under the camera: what to do, or what went wrong, with a dim line of what happens
/// next when there is one. Always dark, since the camera is.
class _Dock extends StatelessWidget {
  const _Dock({required this.text, required this.tone, this.sub});

  final String text;
  final _DockTone tone;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (icon, color) = switch (tone) {
      _DockTone.plain => (null, t.text),
      _DockTone.info => (Icons.sync, t.info),
      _DockTone.warn => (Icons.warning_amber_rounded, t.warn),
      _DockTone.risk => (Icons.error_outline, t.risk),
      _DockTone.ok => (Icons.check_circle_outline, t.ok),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 22, color: color), const SizedBox(width: 10)],
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: KitType.body.copyWith(color: tone == _DockTone.plain ? t.text : color),
                ),
              ),
            ],
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!, textAlign: TextAlign.center, style: KitType.rowSub.copyWith(color: t.dim)),
          ],
        ],
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

/// The payment scanner's viewfinder for any camera view (UP-018): the picture dimmed around
/// the [finder], its rounded corner brackets in white and the ring's track; with [count] parts
/// the ring fills a segment per part [received]. Sized by its parent; the finder is the largest
/// square that leaves [margin] around it.
class QrFinderOverlay extends StatelessWidget {
  const QrFinderOverlay({super.key, this.received = 0, this.count = 0, this.complete = false, this.margin = 36});

  final int received;
  final int count;
  final bool complete;
  final double margin;

  @override
  Widget build(BuildContext context) {
    const dark = protocolDark;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final side = (math.min(size.width, size.height) - 2 * margin).clamp(0.0, double.infinity);
          final finder = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
          return CustomPaint(
            painter: _ScrimPainter(finder: finder),
            foregroundPainter: _FramePainter(
              finder: finder,
              ring: finder.inflate(14),
              received: received,
              count: count,
              complete: complete,
              corners: complete ? dark.ok : Colors.white,
              info: dark.info,
              ok: dark.ok,
            ),
          );
        },
      ),
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
      // One part has nothing to count: the frame draws no ring until the read is done.
      if (complete) canvas.drawPath(path, track..color = ok);
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
    // Square corner marks, as the frame draws them: arms of 26, 2.5 thick, inside the box.
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter
      ..color = corners;
    const len = 26.0;
    final f = finder.deflate(1.25);
    canvas
      ..drawPath(
        Path()
          ..moveTo(f.left, f.top + len)
          ..lineTo(f.left, f.top)
          ..lineTo(f.left + len, f.top),
        bracket,
      )
      ..drawPath(
        Path()
          ..moveTo(f.right - len, f.top)
          ..lineTo(f.right, f.top)
          ..lineTo(f.right, f.top + len),
        bracket,
      )
      ..drawPath(
        Path()
          ..moveTo(f.right, f.bottom - len)
          ..lineTo(f.right, f.bottom)
          ..lineTo(f.right - len, f.bottom),
        bracket,
      )
      ..drawPath(
        Path()
          ..moveTo(f.left + len, f.bottom)
          ..lineTo(f.left, f.bottom)
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
  const _CameraProblem({required this.problem, required this.onRetry, required this.onFile});

  final QrCameraProblem problem;
  final Future<void> Function() onRetry;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final denied = problem == QrCameraProblem.denied;
    return SlotScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitFlowHeader(
              title: l.qrScanPayment,
              onLeading: () => Navigator.of(context).maybePop(),
              leadingId: TrustIds.qrscanBack,
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: KitEmptyState(
                  icon: denied ? Icons.no_photography_outlined : KitIcons.scan,
                  title: denied ? l.qrScanCameraDenied : l.qrScanCameraFailed,
                  actionLabel: denied ? l.qrScanOpenSettings : l.scanQrTryAgain,
                  actionKind: KitButtonKind.gold,
                  actionId: denied ? TrustIds.qrscanSettings : TrustIds.qrscanRetry,
                  onAction: denied ? () => openAppSettings() : onRetry,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, Kit.gutter),
              child: KitButton(
                label: l.qrScanOpenFileInstead,
                kind: KitButtonKind.quiet,
                icon: Icons.file_open_outlined,
                semanticsId: TrustIds.qrscanFile,
                onPressed: onFile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
