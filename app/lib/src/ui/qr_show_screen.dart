// SPDX-License-Identifier: Apache-2.0
/// Shows a payment file, or the reply to one, as an animated QR code for a phone next to this
/// one. The code stays hidden until the user shows it, then counts 3, 2, 1, shows for
/// [qrShowSeconds] with a time line, and hides again; it also hides the moment the app leaves
/// the screen. While the code shows, the screen is at full brightness ([QrBrightness]). The
/// whole route blocks screenshots where the phone can.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../amount.dart';
import '../l10n.dart';
import '../models.dart' show TxEntry;
import '../providers.dart';
import '../qr_slate.dart';
import '../screen_brightness.dart';
import '../secure_screen.dart';
import '../trust_ids.dart';
import 'common.dart';
import 'kit/kit_button.dart';
import 'kit/kit_chip.dart';
import 'kit/kit_corner_marks.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_help_sheet.dart';
import 'kit/kit_hero_amount.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_step_strip.dart';
import 'kit/kit_steps.dart';
import 'kit/kit_tokens.dart';
import 'qr_common.dart';
import 'qr_scan_screen.dart';
import 'theme/logo_qr.dart';
import 'theme/tokens.dart';
import 'tx_details_screen.dart' show TxDetailsScreen;

/// How the show screen ended.
sealed class QrShowResult {
  const QrShowResult();
}

/// The sender scanned the reply from here: [json] is its text, and [posted] says the scan's
/// finish step posted the payment.
final class QrShowScanned extends QrShowResult {
  const QrShowScanned(this.json, {this.posted = false});

  final String json;
  final bool posted;
}

/// The sender chose to open the reply as a file instead.
final class QrShowOpenFile extends QrShowResult {
  const QrShowOpenFile();
}

/// The receiver is done showing the reply.
final class QrShowDone extends QrShowResult {
  const QrShowDone();
}

/// Opens the payment QR for the sender: [json] is the payment file's text.
///
/// Without [scanEnabled] the button that scans the reply is off (the network mode stops it).
///
/// [slateId] finds the payment in the wallet's history, for the status line; [finish] is what
/// the scan of the reply does with it (finish and post).
Future<QrShowResult?> showPaymentQr(
  BuildContext context, {
  required String json,
  required BigInt amount,
  String? slateId,
  bool scanEnabled = true,
  QrFinish? finish,
}) => Navigator.of(context).push<QrShowResult>(
  MaterialPageRoute<QrShowResult>(
    builder: (_) => QrShowScreen.payment(
      json: json,
      amount: amount,
      slateId: slateId,
      scanEnabled: scanEnabled,
      finish: finish,
    ),
  ),
);

/// Opens the reply QR for the receiver: [json] is the signed reply's text.
///
/// [slateId] finds the received payment in the wallet's history, to say how it goes on.
Future<QrShowResult?> showReplyQr(
  BuildContext context, {
  required String json,
  required BigInt amount,
  String? slateId,
}) => Navigator.of(context).push<QrShowResult>(
  MaterialPageRoute<QrShowResult>(
    builder: (_) =>
        QrShowScreen.reply(json: json, amount: amount, slateId: slateId),
  ),
);

/// Opens a finished payment (Kill switch) as an animated QR for a device that is online:
/// [json] is the finished payment's text. It ends with Done; the other device posts it.
Future<QrShowResult?> showFinishedQr(
  BuildContext context, {
  required String json,
  required BigInt amount,
  String? slateId,
}) => Navigator.of(context).push<QrShowResult>(
  MaterialPageRoute<QrShowResult>(
    builder: (_) => QrShowScreen.finished(json: json, amount: amount, slateId: slateId),
  ),
);

/// Opens a payment request (I1) as a QR for the payer: [json] is the request's text, [finish]
/// what the scan of their reply does with it (finish and post).
Future<QrShowResult?> showRequestQr(
  BuildContext context, {
  required String json,
  required BigInt amount,
  required String slateId,
  bool scanEnabled = true,
  QrFinish? finish,
}) => Navigator.of(context).push<QrShowResult>(
  MaterialPageRoute<QrShowResult>(
    builder: (_) => QrShowScreen.request(
      json: json,
      amount: amount,
      slateId: slateId,
      scanEnabled: scanEnabled,
      finish: finish,
    ),
  ),
);

/// Opens the payer's answer (I2) to a payment request as a QR for whoever asked.
Future<QrShowResult?> showPaidReplyQr(
  BuildContext context, {
  required String json,
  required BigInt amount,
  String? slateId,
}) => Navigator.of(context).push<QrShowResult>(
  MaterialPageRoute<QrShowResult>(
    builder: (_) =>
        QrShowScreen.paid(json: json, amount: amount, slateId: slateId),
  ),
);

/// Whose code the show screen holds. A [payment] and a [request] are shown first, and their
/// screen scans the reply; a [reply] and a [paid] answer are shown back, and end with Done.
enum QrShowRole {
  /// The sender's payment (S1).
  payment,

  /// The receiver's reply to a payment (S2).
  reply,

  /// A payment request (I1), shown by whoever asks.
  request,

  /// The payer's answer to a request (I2), shown back to whoever asked.
  paid,

  /// A payment finished under Kill switch, shown to a device that is online to post it.
  finished;

  /// The code answers one the other phone showed (or is shown last): the screen ends with Done.
  bool get answers => this == reply || this == paid || this == finished;
}

/// What the QR card shows.
enum QrShowPhase { hidden, countdown, showing, timedOut, away }

/// The key of the status line above the card, for tests.
const Key qrStatusKey = ValueKey('qr-status');

/// How a status line is coloured: calm text, blue for a thing in progress, green for done.
enum QrStatusTone { plain, info, ok }

typedef QrStatus = ({String text, QrStatusTone tone});

/// What the show screen says about where the payment stands and what to do next. [tx] is the
/// payment in the wallet's history, when it is there: for a reply it moves from received, waiting
/// for the sender to post, through posted and confirming, to received.
///
/// [role] tells a request and its paid answer from a payment and its reply; without it, [reply]
/// picks between the payment's two.
QrStatus qrShowStatus(
  AppLocalizations l, {
  required bool reply,
  required QrShowPhase phase,
  QrShowRole? role,
  TxEntry? tx,
  BigInt? tip,
  int? target,
}) {
  final who = role ?? (reply ? QrShowRole.reply : QrShowRole.payment);
  // The payer's answer is a payment out that waits for whoever asked to post it: only the chain
  // says it was.
  if (who == QrShowRole.paid && tx != null && (txConfirmations(tx, tip) ?? 0) == 0) tx = null;
  if (tx != null) {
    switch (txPhase(tx, tip, target: target)) {
      case TxPhase.confirming:
        return (
          text: l.qrStatusPosted(
            txConfirmations(tx, tip) ?? 0,
            target ?? confirmationsTarget,
          ),
          tone: QrStatusTone.info,
        );
      case TxPhase.completed:
        return (
          text: who == QrShowRole.paid ? l.qrStatusPaid : l.qrStatusReceived,
          tone: QrStatusTone.ok,
        );
      case TxPhase.waitingSender when reply && phase == QrShowPhase.showing:
        return (text: l.qrStatusReceivedWaiting, tone: QrStatusTone.info);
      default:
        break;
    }
  }
  return switch (phase) {
    QrShowPhase.hidden || QrShowPhase.countdown => (
      text: switch (who) {
        QrShowRole.payment => l.qrStatusSendHidden,
        QrShowRole.reply => l.qrStatusReplyHidden,
        QrShowRole.request => l.qrStatusRequestHidden,
        QrShowRole.paid => l.qrStatusPaidHidden,
        QrShowRole.finished => l.qrStatusFinishedHidden,
      },
      tone: QrStatusTone.plain,
    ),
    QrShowPhase.showing => (
      text: switch (who) {
        QrShowRole.payment => l.qrStatusSendShowing,
        QrShowRole.reply => l.qrStatusReplyShowing,
        QrShowRole.request => l.qrStatusRequestShowing,
        QrShowRole.paid => l.qrStatusPaidShowing,
        QrShowRole.finished => l.qrStatusFinishedShowing,
      },
      tone: QrStatusTone.info,
    ),
    QrShowPhase.timedOut ||
    QrShowPhase.away => (text: l.qrStatusHiddenAgain, tone: QrStatusTone.plain),
  };
}

/// Whether the payment is posted: from there the code has done its work, and the screen shows
/// the progress instead of a hidden code to show again.
bool qrPaymentPosted(
  TxEntry? tx,
  BigInt? tip,
  int? target, {
  QrShowRole role = QrShowRole.payment,
}) =>
    tx != null &&
    // The payer's own answer reads as on its way from the moment it is signed: only a block
    // says whoever asked posted it.
    (role != QrShowRole.paid || (txConfirmations(tx, tip) ?? 0) > 0) &&
    switch (txPhase(tx, tip, target: target)) {
      TxPhase.confirming || TxPhase.completed => true,
      _ => false,
    };

/// The line that says where the payment stands, a live region.
class _StatusLine extends StatelessWidget {
  const _StatusLine({super.key, required this.status});

  final QrStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = switch (status.tone) {
      QrStatusTone.plain => t.dim,
      QrStatusTone.info => t.info,
      QrStatusTone.ok => t.ok,
    };
    final icon = switch (status.tone) {
      QrStatusTone.plain => null,
      QrStatusTone.info => Icons.sync,
      QrStatusTone.ok => Icons.check_circle_outline,
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                status.text,
                textAlign: TextAlign.center,
                style: KitType.rowSub.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The key of the Show QR / Show again button, for tests.
const Key qrShowButtonKey = ValueKey('qr-show-button');

/// The key of the card, for tests.
const Key qrCardKey = ValueKey('qr-card');

/// The key of the card that replaces the code once the payment is posted, for tests.
const Key qrDoneCardKey = ValueKey('qr-done-card');

/// The key of the Hide button, for tests.
const Key qrHideButtonKey = ValueKey('qr-hide-button');

/// The key of the button that goes on: Scan their reply (payment) or Done (reply).
const Key qrNextButtonKey = ValueKey('qr-next-button');

class QrShowScreen extends ConsumerStatefulWidget {
  const QrShowScreen.payment({
    super.key,
    required this.json,
    required this.amount,
    this.slateId,
    this.scanEnabled = true,
    this.finish,
  }) : role = QrShowRole.payment;

  const QrShowScreen.reply({
    super.key,
    required this.json,
    required this.amount,
    this.slateId,
  }) : role = QrShowRole.reply,
       scanEnabled = true,
       finish = null;

  /// A payment request (I1); scanning the payer's answer finishes it with [finish].
  const QrShowScreen.request({
    super.key,
    required this.json,
    required this.amount,
    this.slateId,
    this.scanEnabled = true,
    this.finish,
  }) : role = QrShowRole.request;

  /// A payment finished under Kill switch, for a device that is online to post.
  const QrShowScreen.finished({
    super.key,
    required this.json,
    required this.amount,
    this.slateId,
  }) : role = QrShowRole.finished,
       scanEnabled = true,
       finish = null;

  /// The payer's answer (I2) to a request.
  const QrShowScreen.paid({
    super.key,
    required this.json,
    required this.amount,
    this.slateId,
  }) : role = QrShowRole.paid,
       scanEnabled = true,
       finish = null;

  /// The payment's id, to follow it in the wallet's history.
  final String? slateId;

  /// What scanning the reply does with it: finish and post. Null hands the text back.
  final QrFinish? finish;

  /// The file's text.
  final String json;
  final BigInt amount;

  /// Whose code this is.
  final QrShowRole role;

  /// True for a code that answers one the other phone showed: the reply, or a paid answer.
  bool get reply => role.answers;

  /// Whether the payment's "Scan their reply" works: the network mode may stop it.
  final bool scanEnabled;

  @override
  ConsumerState<QrShowScreen> createState() => _QrShowScreenState();
}

class _QrShowScreenState extends ConsumerState<QrShowScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  QrShowPhase _phase = QrShowPhase.hidden;
  QrFrames? _frames;
  Object? _encodeError;

  /// The numeral on the card while counting: 3, 2, 1.
  int _numeral = qrCountdownSeconds;
  int _secondsLeft = qrShowSeconds;
  final ValueNotifier<int> _frame = ValueNotifier(0);

  /// The time line drawing itself in over the countdown.
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(seconds: qrCountdownSeconds),
  );

  /// The time line draining over the time the code shows.
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: const Duration(seconds: qrShowSeconds),
  );

  /// 0 covered, 1 showing the code.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final CurvedAnimation _revealCurve = CurvedAnimation(
    parent: _reveal,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  Timer? _countTimer;
  Timer? _frameTimer;
  Timer? _secondTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PortraitLock.hold();
    unawaited(setSecureScreen(true));
    _encode();
  }

  Future<void> _encode() async {
    try {
      final texts = await ref
          .read(walletServiceProvider)
          .encodeQrSlate(
          json: widget.json,
          maxFragmentLen: qrFragmentLen,
          singleCodeMaxLen: qrSingleCodeMaxLen,
        );
      final frames = QrFrames.of(texts);
      if (mounted) setState(() => _frames = frames);
    } catch (error) {
      if (mounted) setState(() => _encodeError = error);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimers();
    _draw.dispose();
    _time.dispose();
    _revealCurve.dispose();
    _reveal.dispose();
    _frame.dispose();
    unawaited(QrBrightness.releaseBrightness());
    unawaited(setSecureScreen(false));
    PortraitLock.release();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The app switcher's picture is taken at inactive, so hide then, and stay hidden.
    if (state == AppLifecycleState.resumed) return;
    if (_phase == QrShowPhase.countdown || _phase == QrShowPhase.showing) {
      _cover(QrShowPhase.away);
    }
  }

  void _stopTimers() {
    _countTimer?.cancel();
    _frameTimer?.cancel();
    _secondTimer?.cancel();
    _countTimer = _frameTimer = _secondTimer = null;
  }

  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  /// Show QR and Show again: 3, 2, 1, then the code.
  void _start() {
    if (_frames == null) return;
    _stopTimers();
    setState(() {
      _phase = QrShowPhase.countdown;
      _numeral = qrCountdownSeconds;
      _secondsLeft = qrShowSeconds;
    });
    _time.reset();
    _draw.forward(from: 0);
    _countTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_numeral > 1) {
        setState(() => _numeral--);
      } else {
        timer.cancel();
        _countTimer = null;
        _show();
      }
    });
  }

  void _show() {
    unawaited(tap(HapticFeedback.selectionClick));
    // Full brightness while the code shows, for the camera; back when it hides.
    unawaited(QrBrightness.holdFullBrightness());
    _frame.value = 0;
    setState(() {
      _phase = QrShowPhase.showing;
      _secondsLeft = qrShowSeconds;
    });
    _draw.reset();
    if (_reduced) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
    _time.forward(from: 0);
    _frameTimer = Timer.periodic(const Duration(milliseconds: qrFrameMs), (_) {
      _frame.value++;
    });
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _cover(QrShowPhase.timedOut);
      }
    });
  }

  /// Hides the code and shows the cover for [phase].
  void _cover(QrShowPhase phase) {
    unawaited(QrBrightness.releaseBrightness());
    _stopTimers();
    _time.stop();
    _draw.reset();
    if (_reduced) {
      _reveal.value = 0;
    } else {
      _reveal.reverse();
    }
    setState(() => _phase = phase);
  }

  Future<void> _next() async {
    if (widget.reply) {
      Navigator.of(context).pop(const QrShowDone());
      return;
    }
    // The scanner goes over this screen, so the code goes away first: coming back, the user
    // shows it again if the scan did not work.
    if (_phase == QrShowPhase.countdown || _phase == QrShowPhase.showing) {
      _cover(QrShowPhase.away);
    }
    final result = await scanQrSlate(
      context,
      QrScanKind.reply,
      finish: widget.finish,
      amount: widget.amount,
    );
    if (!mounted) return;
    switch (result) {
      case QrScanned(:final json, :final posted):
        Navigator.of(context).pop(QrShowScanned(json, posted: posted));
      case QrScanOpenFile():
        Navigator.of(context).pop(const QrShowOpenFile());
      case null:
        break;
    }
  }

  /// The three steps this screen belongs to, and the one it is (HANDOFF 7.9): the payer and the
  /// asker show first and scan the answer; whoever answers scans first and shows the answer.
  (List<String>, int)? _steps(AppLocalizations l) => switch (widget.role) {
    QrShowRole.payment || QrShowRole.request => ([l.phoneStepPayShow, l.phoneStepPayScan, l.commonDone], 0),
    QrShowRole.reply || QrShowRole.paid => ([l.phoneStepRecvScan, l.phoneStepRecvShow, l.commonDone], 1),
    QrShowRole.finished => null,
  };

  /// The page once the payment is posted (Gap-3): no title, a green ring with a check, what was
  /// done, the amount, the three steps, Done and View payment.
  Widget _doneScreen(BuildContext context, {required QrShowRole role, required QrStatus status, required TxEntry tx}) {
    final l = context.l10n;
    final t = context.tokens;
    final answers = role == QrShowRole.reply || role == QrShowRole.paid;
    final received = role == QrShowRole.reply || role == QrShowRole.request;
    final finished = status.tone == QrStatusTone.ok;
    final steps = [
      KitStep(title: answers ? l.phoneQrDoneCodeRead : l.phoneQrDoneScanned, state: KitStepState.done),
      KitStep(title: answers ? l.phoneQrDoneAnswerSeen : l.phoneQrDoneAnswerRead, state: KitStepState.done),
      KitStep(
        title: status.text,
        state: finished ? KitStepState.done : KitStepState.now,
        detail: finished ? null : l.phoneQrDoneFinishes,
        network: !finished,
      ),
    ];
    return SlotScaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitFlowHeader(
                  title: '',
                  onLeading: () => Navigator.of(context).pop(const QrShowDone()),
                  leadingId: TrustIds.qrshowClose,
                  onHelp: () => showKitHelp(
                    context,
                    title: l.phoneQrHelpTitle,
                    lines: [status.text, l.qrHoldHint, l.qrHiddenBodyPayment],
                  ),
                  helpId: TrustIds.qrshowHelp,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 36, bottom: Kit.gutter),
                    child: Semantics(
                      key: qrDoneCardKey,
                      liveRegion: true,
                      container: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: t.okSoft,
                                boxShadow: [BoxShadow(color: t.ok.withValues(alpha: .05), spreadRadius: 10)],
                              ),
                              child: Icon(KitIcons.check, size: 36, color: t.ok),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            received ? l.phoneQrDoneTitleReceived : l.phoneQrDoneTitlePaid,
                            textAlign: TextAlign.center,
                            style: KitType.pageTitle.copyWith(color: t.text, fontSize: 26, letterSpacing: -0.52),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            epicFor(l, widget.amount, surface: AmountSurface.exact),
                            textAlign: TextAlign.center,
                            style: KitType.rowAmount.copyWith(color: t.dim, fontSize: 17),
                          ),
                          const SizedBox(height: 32),
                          KitSteps(steps: steps),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KitButton(
                        key: qrNextButtonKey,
                        label: l.commonDone,
                        semanticsId: TrustIds.qrshowDone,
                        onPressed: () => Navigator.of(context).pop(const QrShowDone()),
                      ),
                      const SizedBox(height: 6),
                      KitButton(
                        label: l.phoneRecvViewPayment,
                        kind: KitButtonKind.ghost,
                        semanticsId: TrustIds.qrshowViewpayment,
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: tx.key)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final reply = widget.reply;
    final role = widget.role;
    final incoming = role == QrShowRole.reply || role == QrShowRole.request;
    final ready = _frames != null;
    // The frame's card: 212 (`.qr`).
    const card = Kit.qr;

    // Where things stand, from the real payment: the code's own state, and for a reply what the
    // wallet's history says of the received payment.
    final tx = widget.slateId == null
        ? null
        : ref
              .watch(homeProvider.select((h) => h.value?.transactions))
              ?.where((x) => x.slateId == widget.slateId)
              .firstOrNull;
    final status = qrShowStatus(
      l,
      reply: reply,
      role: role,
      phase: _phase,
      tx: tx,
      tip: tipHeight(ref),
      target: confirmationsTargetOf(ref),
    );

    final done = qrPaymentPosted(tx, tipHeight(ref), confirmationsTargetOf(ref), role: role);
    final showing = _phase == QrShowPhase.showing && !done;
    final counting = _phase == QrShowPhase.countdown && !done;
    final steps = done ? null : _steps(l);
    final title = switch (role) {
      QrShowRole.payment => l.phoneQrTitlePay,
      QrShowRole.request => l.qrShowTitleRequest,
      QrShowRole.reply || QrShowRole.paid => l.phoneQrTitleReceive,
      QrShowRole.finished => l.finishedQrTitle,
    };

    final content = <Widget>[
      // The exact amount, in the data face.
      const SizedBox(height: 22),
      if (!done)
        KitHeroAmount(
          amount: epicFor(l, widget.amount, surface: AmountSurface.exact, unit: false, signed: incoming),
          unit: epicUnit,
          incoming: incoming,
        ),
      if (!done) const SizedBox(height: 22),
      if (!done)
        _CardBox(
          card: card,
          label: switch (role) {
            QrShowRole.payment => l.qrSemanticsPayment(showing ? l.qrStateShowing : l.qrStateHidden),
            QrShowRole.request => l.qrSemanticsRequest(showing ? l.qrStateShowing : l.qrStateHidden),
            QrShowRole.reply || QrShowRole.paid => l.qrSemanticsReply(showing ? l.qrStateShowing : l.qrStateHidden),
            QrShowRole.finished => l.qrSemanticsFinished(showing ? l.qrStateShowing : l.qrStateHidden),
          },
          phase: _phase,
          reply: reply,
          frames: _frames,
          frame: _frame,
          numeral: _numeral,
          secondsLeft: _secondsLeft,
          reveal: _revealCurve,
          reduced: MediaQuery.disableAnimationsOf(context),
        ),
      // One part has no sequence to show: the frame leaves the pips and the part line out.
      if (showing && _frames!.partCount > 1) ...[
        const SizedBox(height: 18),
        _Pips(frames: _frames!, frame: _frame, reduced: _reduced),
        const SizedBox(height: 8),
        _PartLine(frames: _frames!, frame: _frame),
      ],
      if (!done) ...[
        SizedBox(height: showing && _frames!.partCount > 1 ? 14 : 20),
        // What to do now, and where the payment stands.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
          child: Column(
            children: [
              if (showing || counting)
                // A plain `p`: the page's 1.3 line.
                Text(l.phoneQrHoldHint, textAlign: TextAlign.center, style: KitType.body.copyWith(color: t.text, height: 1.3)),
              // The frame draws no line while a payment code is up (the step strip and the button
              // say what comes next) and a plain one under the reply code.
              if ((showing || counting) && !(showing && status.text == l.qrStatusSendShowing))
                const SizedBox(height: 6),
              if (!(showing && status.text == l.qrStatusSendShowing))
                _StatusLine(
                  key: qrStatusKey,
                  status: showing && status.text == l.qrStatusReplyShowing
                      ? (text: l.phoneQrReplyShowing, tone: QrStatusTone.plain)
                      : status,
                ),
            ],
          ),
        ),
      ],
      if (showing) ...[
        const SizedBox(height: 12),
        _HidesChip(secondsLeft: _secondsLeft),
      ],
      if (_encodeError != null) ErrorText(describeError(l, _encodeError!)),
    ];

    final nextLabel = reply ? l.commonDone : l.phoneQrScanAnswer;
    final nextId = reply ? TrustIds.qrshowDone : TrustIds.qrshowNext;
    final Widget bottom = done
        ? const SizedBox.shrink()
        : switch (_phase) {
            QrShowPhase.hidden => KitButton(
              key: qrShowButtonKey,
              label: l.qrShow,
              icon: KitIcons.qr,
              semanticsId: TrustIds.qrshowShow,
              onPressed: ready ? _start : null,
            ),
            // Fixed slots once the code was shown (UP-023): the primary is the next step
            // (Scan their answer / Done), the one under it Hide or Show again.
            QrShowPhase.countdown || QrShowPhase.showing => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitButton(
                  key: qrNextButtonKey,
                  label: nextLabel,
                  icon: reply ? null : KitIcons.scan,
                  semanticsId: nextId,
                  onPressed: widget.scanEnabled ? _next : null,
                ),
                if (!reply) ...[
                const SizedBox(height: 6),
                KitButton(
                  key: qrHideButtonKey,
                  label: l.qrHide,
                  kind: KitButtonKind.ghost,
                  semanticsId: TrustIds.qrshowHide,
                  onPressed: () => _cover(QrShowPhase.hidden),
                ),
                ],
              ],
            ),
            QrShowPhase.timedOut || QrShowPhase.away => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitButton(
                  key: qrNextButtonKey,
                  label: nextLabel,
                  icon: reply ? null : KitIcons.scan,
                  semanticsId: nextId,
                  onPressed: widget.scanEnabled ? _next : null,
                ),
                const SizedBox(height: 6),
                KitButton(
                  key: qrShowButtonKey,
                  label: l.qrShowAgain,
                  kind: KitButtonKind.ghost,
                  semanticsId: TrustIds.qrshowAgain,
                  onPressed: ready ? _start : null,
                ),
              ],
            ),
          };

    if (done) return _doneScreen(context, role: role, status: status, tx: tx!);

    return SlotScaffold(
      breathing: showing,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitFlowHeader(
                  title: title,
                  back: true,
                  onLeading: () => Navigator.of(context).maybePop(),
                  leadingId: TrustIds.qrshowBack,
                  onHelp: () => showKitHelp(
                    context,
                    title: l.phoneQrHelpTitle,
                    lines: [status.text, l.qrHoldHint, l.qrHiddenBodyPayment, if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) l.qrSecureLine],
                  ),
                  helpId: TrustIds.qrshowHelp,
                ),
                if (steps != null) KitStepStrip(labels: steps.$1, current: steps.$2),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: content,
                      ),
                    ),
                  ),
                ),
                Padding(padding: const EdgeInsets.symmetric(horizontal: Kit.gutter), child: bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The chip under a shown code: how long until it hides. It names the last seconds to a screen
/// reader once.
class _HidesChip extends StatelessWidget {
  const _HidesChip({required this.secondsLeft});

  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final low = secondsLeft <= qrLowSeconds;
    final announce = secondsLeft == qrLowSeconds;
    return Semantics(
      liveRegion: announce,
      label: announce ? l.qrSecondsLeft(qrLowSeconds) : null,
      excludeSemantics: announce,
      child: KitChip(l.phoneQrHidesIn(secondsLeft), icon: KitIcons.clock, info: low),
    );
  }
}

/// The code's card with the brand's corner marks around it (HANDOFF 5.5).
class _CardBox extends StatelessWidget {
  const _CardBox({
    required this.card,
    required this.label,
    required this.phase,
    required this.reply,
    required this.frames,
    required this.frame,
    required this.numeral,
    required this.secondsLeft,
    required this.reveal,
    required this.reduced,
  });

  final double card;
  final String label;
  final QrShowPhase phase;
  final bool reply;
  final QrFrames? frames;
  final ValueListenable<int> frame;
  final int numeral;
  final int secondsLeft;
  final Animation<double> reveal;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: KitCornerMarks(
          inset: 14,
          arm: 22,
          child: _Card(
            key: qrCardKey,
            side: card,
            phase: phase,
            reply: reply,
            frames: frames,
            frame: frame,
            numeral: numeral,
            secondsLeft: secondsLeft,
            reveal: reveal,
            reduced: reduced,
          ),
        ),
      ),
    );
  }
}

/// The square card: a cover with words, or the white QR.
class _Card extends StatelessWidget {
  const _Card({
    super.key,
    required this.side,
    required this.phase,
    required this.reply,
    required this.frames,
    required this.frame,
    required this.numeral,
    required this.secondsLeft,
    required this.reveal,
    required this.reduced,
  });

  final double side;
  final QrShowPhase phase;
  final bool reply;
  final QrFrames? frames;
  final ValueListenable<int> frame;
  final int numeral;
  final int secondsLeft;
  final Animation<double> reveal;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, _) {
        final r = reveal.value;
        final code = frames == null || r == 0
            ? null
            : RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(side),
                  painter: _QrPainter(frames: frames!, frame: frame, dpr: dpr),
                ),
              );
        return DecoratedBox(
          decoration: BoxDecoration(
            // The one literal pair in the app: a code must be black on white for every reader.
            color: Color.lerp(t.surfaceHi, const Color(0xFFFFFFFF), r),
            border: Border.all(
              color: Color.lerp(t.lineStrong, const Color(0xFFFFFFFF), r)!,
            ),
            borderRadius: BorderRadius.circular(Kit.rQr),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Kit.rQr - 1),
            child: SizedBox(
              width: side,
              height: side,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (r < 1)
                  Opacity(
                    opacity: 1 - r,
                    child: _Cover(
                      phase: phase,
                      reply: reply,
                      numeral: numeral,
                      reduced: reduced,
                    ),
                  ),
                  if (code != null)
                    r < 1 ? Opacity(opacity: r, child: code) : code,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// What the card says while it hides the code.
class _Cover extends StatelessWidget {
  const _Cover({
    required this.phase,
    required this.reply,
    required this.numeral,
    required this.reduced,
  });

  final QrShowPhase phase;
  final bool reply;
  final int numeral;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final String? title;
    final String? body;
    final IconData icon;
    switch (phase) {
      case QrShowPhase.timedOut:
        icon = Icons.hourglass_empty;
        title = l.qrTimedOutTitle(qrShowSeconds);
        body = l.qrTimedOutBody;
      case QrShowPhase.away:
        icon = Icons.visibility_off_outlined;
        title = l.qrAwayTitle;
        body = l.qrAwayBody;
      case QrShowPhase.hidden:
      case QrShowPhase.showing:
        icon = Icons.qr_code_2;
        title = l.qrHiddenTitle;
        body = switch (context
            .findAncestorStateOfType<_QrShowScreenState>()!
            .widget
            .role) {
          QrShowRole.payment => l.qrHiddenBodyPayment,
          QrShowRole.reply => l.qrHiddenBodyReply,
          QrShowRole.request => l.qrHiddenBodyRequest,
          QrShowRole.paid => l.qrHiddenBodyPaid,
          QrShowRole.finished => l.qrHiddenBodyFinished,
        };
      case QrShowPhase.countdown:
        return Center(
          child: Semantics(
            liveRegion: true,
            label: l.qrCountdownLabel(numeral),
            excludeSemantics: true,
            child: _Numeral(
              key: ValueKey(numeral),
              numeral: numeral,
              reduced: reduced,
            ),
          ),
        );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SingleChildScrollView(
          child: Semantics(
            liveRegion: true,
            container: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 72, color: t.faint),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A countdown numeral: scales in from 1.18 to 1 with a fade, unless motion is reduced.
class _Numeral extends StatelessWidget {
  const _Numeral({super.key, required this.numeral, required this.reduced});

  final int numeral;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Text(
      '$numeral',
      style: TextStyle(
        fontFamily: t.headFamily,
        fontWeight: FontWeight.w600,
        fontSize: 112,
        height: 1,
        color: t.text,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    if (reduced) return text;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.scale(scale: 1.18 - 0.18 * v, child: child),
      ),
      child: text,
    );
  }
}

/// Paints one frame in the [LogoQr] look with the BT Wallet mark, on white, at a whole number
/// of device pixels a module, so every frame keeps the same crisp grid.
class _QrPainter extends CustomPainter {
  _QrPainter({required this.frames, required this.frame, required this.dpr})
    : super(repaint: frame);

  final QrFrames frames;
  final ValueListenable<int> frame;
  final double dpr;

  @override
  void paint(Canvas canvas, Size size) {
    final image = frames.images[frame.value % frames.length];
    final n = frames.moduleCount;
    const quiet = qrQuietModules;
    final pixels = size.width * dpr;
    final module = (pixels / (n + 2 * quiet)).floorToDouble().clamp(1.0, 1e6);
    final offset = ((pixels - module * n) / 2).floorToDouble();
    canvas
      ..save()
      ..scale(1 / dpr)
      ..drawRect(
        Offset.zero & Size(pixels, size.height * dpr),
        Paint()
          ..color = protocolLight.surface
          ..isAntiAlias = false,
      );
    paintLogoQr(canvas, image, logo: QrLogo.bt, origin: Offset(offset, offset), module: module);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.frames != frames || old.dpr != dpr;
}

/// One pip for each part: the one on screen light, the one before it a little less.
class _Pips extends StatelessWidget {
  const _Pips({
    required this.frames,
    required this.frame,
    required this.reduced,
  });

  final QrFrames frames;
  final ValueListenable<int> frame;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ExcludeSemantics(
      child: ValueListenableBuilder<int>(
        valueListenable: frame,
        builder: (context, value, _) {
          final now = frames.partOf(value);
          final before = value == 0 ? -1 : frames.partOf(value - 1);
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 5,
            children: [
              for (var i = 0; i < frames.partCount; i++)
                AnimatedContainer(
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 120),
                  curve: Curves.linear,
                  width: 16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i == now
                        ? t.text
                        : i == before
                        ? t.lineStrong
                        : t.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// `Part 3 of 7 · 38 s`.
class _PartLine extends StatelessWidget {
  const _PartLine({required this.frames, required this.frame});

  final QrFrames frames;
  final ValueListenable<int> frame;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final style = TextStyle(fontFamily: t.monoFamily, fontSize: 13, color: t.dim);
    return SizedBox(
      height: 22,
      child: ValueListenableBuilder<int>(
        valueListenable: frame,
        builder: (context, value, _) =>
            Text(l.qrPartOf(frames.partOf(value) + 1, frames.partCount), style: style),
      ),
    );
  }
}
